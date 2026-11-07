package stockruntime

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"

	"gxb.local/backend/v2/internal/protocol/limits"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

const (
	HTTPPollPath               = "/realtime/poll"
	DefaultHTTPPollIdleTimeout = 30 * time.Second
	DefaultHTTPPollHoldTimeout = 20 * time.Second

	maxPollSocketsPerSession = 8
	maxPollSocketTagBytes    = 64
	maxPollClientSequences   = 256
)

var (
	ErrHTTPPollSessionFull  = errors.New("realtime HTTP poll session limit reached")
	ErrHTTPPollUnknown      = errors.New("unknown realtime HTTP poll session")
	ErrHTTPPollBadSequence  = errors.New("realtime HTTP poll client sequence required")
	ErrHTTPPollSocketLimit  = errors.New("realtime HTTP poll socket limit reached")
	errHTTPPollUnknownFrame = errors.New("realtime HTTP poll unknown socket")
)

type pollBatch struct {
	frames []wireRT.Frame
	done   chan struct{}
}

type pollTimeoutError struct{}

func (pollTimeoutError) Error() string   { return "realtime HTTP poll idle timeout" }
func (pollTimeoutError) Timeout() bool   { return true }
func (pollTimeoutError) Temporary() bool { return true }

type pollFrameSource struct {
	incoming    chan *pollBatch
	idleTimeout time.Duration
	mutex       sync.Mutex
	deadline    time.Time
	activity    time.Time
	pending     *pollBatch
	holds       int
}

func newPollFrameSource(idleTimeout time.Duration) *pollFrameSource {
	return &pollFrameSource{incoming: make(chan *pollBatch), idleTimeout: idleTimeout, activity: time.Now()}
}

func (s *pollFrameSource) SetReadDeadline(deadline time.Time) error {
	s.mutex.Lock()
	s.deadline = deadline
	s.mutex.Unlock()
	return nil
}

// ActivityTime reports a held poll as continuous client activity so a poll that
// outlives the idle limit keeps its session.
func (s *pollFrameSource) ActivityTime() time.Time {
	s.mutex.Lock()
	defer s.mutex.Unlock()
	if s.holds > 0 {
		return time.Now()
	}
	return s.activity
}

func (s *pollFrameSource) ClientIdleTimeout() time.Duration { return s.idleTimeout }

func (s *pollFrameSource) touch(at time.Time) {
	s.mutex.Lock()
	s.activity = at
	s.mutex.Unlock()
}

func (s *pollFrameSource) hold() {
	s.mutex.Lock()
	s.holds++
	s.mutex.Unlock()
}

func (s *pollFrameSource) release(at time.Time) {
	s.mutex.Lock()
	if s.holds > 0 {
		s.holds--
	}
	s.activity = at
	s.mutex.Unlock()
}

// close releases a batch the session loop never read, so a waiting send cannot
// block after its logical socket stopped.
func (s *pollFrameSource) close() {
	s.mutex.Lock()
	pending := s.pending
	s.pending = nil
	s.mutex.Unlock()
	if pending != nil {
		close(pending.done)
	}
}

func (s *pollFrameSource) ReadFrames(ctx context.Context) ([]wireRT.Frame, error) {
	s.mutex.Lock()
	if s.pending != nil {
		close(s.pending.done)
		s.pending = nil
	}
	deadline := s.deadline
	s.mutex.Unlock()

	var timer *time.Timer
	var timeout <-chan time.Time
	if !deadline.IsZero() {
		timer = time.NewTimer(time.Until(deadline))
		timeout = timer.C
		defer timer.Stop()
	}
	select {
	case batch := <-s.incoming:
		s.mutex.Lock()
		s.pending = batch
		s.mutex.Unlock()
		return batch.frames, nil
	case <-ctx.Done():
		return nil, ctx.Err()
	case <-timeout:
		return nil, pollTimeoutError{}
	}
}

type pollOutbound struct {
	socket   string
	sequence uint64
	frame    []byte
	closed   bool
}

type pollWaiter struct {
	replaced chan struct{}
}

type pollSocketState struct {
	tag    string
	source *pollFrameSource
	cancel context.CancelFunc
	done   chan struct{}
}

type httpPollSession struct {
	id     string
	ctx    context.Context
	cancel context.CancelFunc
	done   chan struct{}
	server *HTTPPollServer

	mutex         sync.Mutex
	closed        bool
	sockets       map[string]*pollSocketState
	socketWait    sync.WaitGroup
	outbound      []pollOutbound
	outboundBytes int
	nextSequence  uint64
	acked         uint64
	wake          chan struct{}
	waiter        *pollWaiter
	lastRequest   time.Time
	expiry        *time.Timer

	sendMutex    sync.Mutex
	applied      map[uint64]struct{}
	appliedOrder []uint64
}

type HTTPPollServer struct {
	server      RealtimeServer
	config      limits.Config
	policy      RealtimePolicy
	idleTimeout time.Duration
	holdTimeout time.Duration
	context     context.Context
	cancel      context.CancelFunc
	mutex       sync.Mutex
	sessions    map[string]*httpPollSession
}

func NewHTTPPollServer(parent context.Context, server RealtimeServer, idleTimeout, holdTimeout time.Duration) (*HTTPPollServer, error) {
	if parent == nil {
		return nil, errors.New("nil realtime HTTP poll context")
	}
	if idleTimeout <= 0 {
		idleTimeout = DefaultHTTPPollIdleTimeout
	}
	if holdTimeout <= 0 {
		holdTimeout = DefaultHTTPPollHoldTimeout
	}
	configuration, policy, err := server.runtimeConfig()
	if err != nil {
		return nil, err
	}
	ctx, cancel := context.WithCancel(parent)
	return &HTTPPollServer{
		server: server, config: configuration, policy: policy, idleTimeout: idleTimeout, holdTimeout: holdTimeout, context: ctx, cancel: cancel,
		sessions: make(map[string]*httpPollSession),
	}, nil
}

func (s *HTTPPollServer) Close() {
	if s == nil {
		return
	}
	s.cancel()
	s.mutex.Lock()
	sessions := make([]*httpPollSession, 0, len(s.sessions))
	for _, session := range s.sessions {
		sessions = append(sessions, session)
	}
	s.mutex.Unlock()
	for _, session := range sessions {
		session.cancel()
	}
	for _, session := range sessions {
		<-session.done
	}
}

func (s *HTTPPollServer) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc(HTTPPollPath, s.handlePoll)
	return mux
}

type pollRequestFrame struct {
	Socket string          `json:"socket"`
	Frame  json.RawMessage `json:"frame"`
}

type pollRequest struct {
	SessionID      string             `json:"session_id"`
	Ack            uint64             `json:"ack"`
	ClientSequence uint64             `json:"client_sequence"`
	Hold           bool               `json:"hold"`
	Frames         []pollRequestFrame `json:"frames"`
}

type pollOutboundFrame struct {
	Socket   string          `json:"socket"`
	Sequence uint64          `json:"sequence"`
	Frame    json.RawMessage `json:"frame,omitempty"`
	Closed   bool            `json:"closed,omitempty"`
}

type pollReply struct {
	SessionID string              `json:"session_id"`
	Frames    []pollOutboundFrame `json:"frames"`
}

func (s *HTTPPollServer) handlePoll(w http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodPost {
		w.Header().Set("Allow", http.MethodPost)
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	poll, status := s.decodeRequest(w, request)
	if status != 0 {
		if status == http.StatusConflict {
			writePollConflict(w)
			return
		}
		http.Error(w, http.StatusText(status), status)
		return
	}
	session, status := s.sessionFor(poll.SessionID)
	if status != 0 {
		if status == http.StatusConflict {
			writePollConflict(w)
			return
		}
		http.Error(w, http.StatusText(status), status)
		return
	}
	now := time.Now()
	session.touchRequest(now)
	defer session.touchRequest(time.Now())
	session.acknowledge(poll.Ack)
	if len(poll.Frames) > 0 {
		if err := session.deliver(request.Context(), poll.ClientSequence, poll.Frames); err != nil {
			if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
				return
			}
			http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
			return
		}
	}
	if !poll.Hold {
		session.touchSources(now)
		writePollReply(w, session.id, nil)
		return
	}
	session.holdSources()
	defer session.releaseSources(time.Now())

	waiter, ready := session.beginPoll()
	defer session.endPoll(waiter)
	if ready {
		writePollReply(w, session.id, session.outboundFrames())
		return
	}
	timer := time.NewTimer(s.holdTimeout)
	defer timer.Stop()
	for {
		select {
		case <-session.wake:
		case <-timer.C:
			writePollReply(w, session.id, nil)
			return
		case <-waiter.replaced:
			writePollReply(w, session.id, nil)
			return
		case <-request.Context().Done():
			return
		case <-session.ctx.Done():
			writePollConflict(w)
			return
		}
		if frames := session.outboundFrames(); len(frames) > 0 {
			writePollReply(w, session.id, frames)
			return
		}
	}
}

func (s *HTTPPollServer) decodeRequest(w http.ResponseWriter, request *http.Request) (pollRequest, int) {
	body, err := io.ReadAll(http.MaxBytesReader(w, request.Body, int64(s.config.RealtimeBufferedBytes)))
	if err != nil {
		var maxBytesError *http.MaxBytesError
		if errors.As(err, &maxBytesError) {
			return pollRequest{}, http.StatusRequestEntityTooLarge
		}
		return pollRequest{}, http.StatusBadRequest
	}
	if strings.HasPrefix(strings.ToLower(request.Header.Get("Content-Type")), "application/x-www-form-urlencoded") {
		values, err := url.ParseQuery(string(body))
		if err != nil || len(values["payload"]) != 1 {
			return pollRequest{}, http.StatusBadRequest
		}
		body = []byte(values.Get("payload"))
	}
	decoder := json.NewDecoder(strings.NewReader(string(body)))
	decoder.DisallowUnknownFields()
	var poll pollRequest
	if err := decoder.Decode(&poll); err != nil {
		return pollRequest{}, http.StatusBadRequest
	}
	if err := decoder.Decode(new(any)); !errors.Is(err, io.EOF) {
		return pollRequest{}, http.StatusBadRequest
	}
	if len(poll.Frames) > s.config.WriterFrames {
		return pollRequest{}, http.StatusRequestEntityTooLarge
	}
	if len(poll.Frames) > 0 && poll.ClientSequence == 0 {
		return pollRequest{}, http.StatusBadRequest
	}
	for _, encoded := range poll.Frames {
		if len(encoded.Socket) == 0 || len(encoded.Socket) > maxPollSocketTagBytes {
			return pollRequest{}, http.StatusBadRequest
		}
		if _, err := wireRT.DecodeJSONFrame(encoded.Frame, s.config); err != nil {
			return pollRequest{}, http.StatusBadRequest
		}
	}
	return poll, 0
}

func (s *HTTPPollServer) sessionFor(id string) (*httpPollSession, int) {
	if id == "" {
		return s.newSession()
	}
	s.mutex.Lock()
	session := s.sessions[id]
	s.mutex.Unlock()
	if session == nil || session.ctx.Err() != nil {
		return nil, http.StatusConflict
	}
	return session, 0
}

func (s *HTTPPollServer) newSession() (*httpPollSession, int) {
	s.mutex.Lock()
	defer s.mutex.Unlock()
	if s.context.Err() != nil {
		return nil, http.StatusServiceUnavailable
	}
	if len(s.sessions) >= s.policy.MaxConnections {
		return nil, http.StatusConflict
	}
	idBytes := make([]byte, 32)
	if _, err := rand.Read(idBytes); err != nil {
		return nil, http.StatusServiceUnavailable
	}
	ctx, cancel := context.WithCancel(s.context)
	session := &httpPollSession{
		id: base64.RawURLEncoding.EncodeToString(idBytes), ctx: ctx, cancel: cancel, server: s,
		done: make(chan struct{}), sockets: make(map[string]*pollSocketState), wake: make(chan struct{}, 1),
		applied: make(map[uint64]struct{}), lastRequest: time.Now(), nextSequence: 1,
	}
	session.expiry = time.AfterFunc(s.idleTimeout, session.expire)
	s.sessions[session.id] = session
	go s.runSession(session)
	return session, 0
}

func (s *HTTPPollServer) runSession(session *httpPollSession) {
	<-session.ctx.Done()
	session.mutex.Lock()
	session.closed = true
	if session.expiry != nil {
		session.expiry.Stop()
	}
	sockets := make([]*pollSocketState, 0, len(session.sockets))
	for _, socket := range session.sockets {
		sockets = append(sockets, socket)
	}
	session.mutex.Unlock()
	for _, socket := range sockets {
		socket.cancel()
	}
	session.socketWait.Wait()
	close(session.done)
	s.mutex.Lock()
	if s.sessions[session.id] == session {
		delete(s.sessions, session.id)
	}
	s.mutex.Unlock()
}

func (session *httpPollSession) expire() {
	session.mutex.Lock()
	if session.closed || session.waiter != nil {
		session.mutex.Unlock()
		return
	}
	remaining := session.server.idleTimeout - time.Since(session.lastRequest)
	if remaining > 0 {
		session.expiry.Reset(remaining)
		session.mutex.Unlock()
		return
	}
	session.mutex.Unlock()
	session.cancel()
}

func (session *httpPollSession) touchRequest(at time.Time) {
	session.mutex.Lock()
	session.lastRequest = at
	if session.expiry != nil && !session.closed {
		session.expiry.Reset(session.server.idleTimeout)
	}
	session.mutex.Unlock()
}

func (session *httpPollSession) touchSources(at time.Time) {
	session.mutex.Lock()
	sockets := make([]*pollSocketState, 0, len(session.sockets))
	for _, socket := range session.sockets {
		sockets = append(sockets, socket)
	}
	session.mutex.Unlock()
	for _, socket := range sockets {
		socket.source.touch(at)
	}
}

func (session *httpPollSession) holdSources() {
	session.mutex.Lock()
	sockets := make([]*pollSocketState, 0, len(session.sockets))
	for _, socket := range session.sockets {
		sockets = append(sockets, socket)
	}
	session.mutex.Unlock()
	for _, socket := range sockets {
		socket.source.hold()
	}
}

func (session *httpPollSession) releaseSources(at time.Time) {
	session.mutex.Lock()
	sockets := make([]*pollSocketState, 0, len(session.sockets))
	for _, socket := range session.sockets {
		sockets = append(sockets, socket)
	}
	session.mutex.Unlock()
	for _, socket := range sockets {
		socket.source.release(at)
	}
}

func (session *httpPollSession) acknowledge(ack uint64) {
	session.mutex.Lock()
	defer session.mutex.Unlock()
	if ack > session.acked {
		session.acked = ack
	}
	index := 0
	for index < len(session.outbound) && session.outbound[index].sequence <= session.acked {
		session.outboundBytes -= len(session.outbound[index].frame)
		index++
	}
	session.outbound = session.outbound[index:]
}

func (session *httpPollSession) outboundFrames() []pollOutboundFrame {
	session.mutex.Lock()
	defer session.mutex.Unlock()
	frames := make([]pollOutboundFrame, len(session.outbound))
	for index, outbound := range session.outbound {
		frames[index] = pollOutboundFrame{Socket: outbound.socket, Sequence: outbound.sequence, Frame: outbound.frame, Closed: outbound.closed}
	}
	return frames
}

func (session *httpPollSession) beginPoll() (*pollWaiter, bool) {
	session.mutex.Lock()
	defer session.mutex.Unlock()
	if session.waiter != nil {
		close(session.waiter.replaced)
	}
	waiter := &pollWaiter{replaced: make(chan struct{})}
	session.waiter = waiter
	return waiter, len(session.outbound) > 0
}

func (session *httpPollSession) endPoll(waiter *pollWaiter) {
	session.mutex.Lock()
	if session.waiter == waiter {
		session.waiter = nil
	}
	session.mutex.Unlock()
}

func (session *httpPollSession) signal() {
	select {
	case session.wake <- struct{}{}:
	default:
	}
}

func (session *httpPollSession) enqueue(socket string, frame []byte) error {
	session.mutex.Lock()
	defer session.mutex.Unlock()
	return session.enqueueLocked(pollOutbound{socket: socket, frame: frame})
}

func (session *httpPollSession) enqueueClosed(socket string) error {
	session.mutex.Lock()
	defer session.mutex.Unlock()
	return session.enqueueLocked(pollOutbound{socket: socket, closed: true})
}

func (session *httpPollSession) enqueueLocked(outbound pollOutbound) error {
	if session.closed {
		return ErrRealtimeWriterClosed
	}
	if len(session.outbound) >= session.server.config.WriterFrames {
		return wireRT.ErrQueueFull
	}
	if !outbound.closed && len(outbound.frame) > session.server.config.WriterBytes-session.outboundBytes {
		return wireRT.ErrQueueFull
	}
	outbound.sequence = session.nextSequence
	session.nextSequence++
	session.outbound = append(session.outbound, outbound)
	if !outbound.closed {
		session.outboundBytes += len(outbound.frame)
	}
	session.signal()
	return nil
}

func (session *httpPollSession) deliver(ctx context.Context, sequence uint64, requestFrames []pollRequestFrame) error {
	if sequence == 0 {
		return ErrHTTPPollBadSequence
	}
	session.sendMutex.Lock()
	defer session.sendMutex.Unlock()
	if session.wasApplied(sequence) {
		return nil
	}
	tags, grouped := groupPollFrames(requestFrames, session.server.config)
	batches := make([]*pollBatch, 0, len(tags))
	for _, tag := range tags {
		socket, ok := session.socketFor(tag)
		if !ok {
			return ErrHTTPPollSocketLimit
		}
		batch := &pollBatch{frames: grouped[tag], done: make(chan struct{})}
		select {
		case socket.source.incoming <- batch:
		case <-socket.done:
			return errHTTPPollUnknownFrame
		case <-ctx.Done():
			return ctx.Err()
		case <-session.ctx.Done():
			return session.ctx.Err()
		}
		batches = append(batches, batch)
	}
	for _, batch := range batches {
		select {
		case <-batch.done:
		case <-ctx.Done():
			return ctx.Err()
		case <-session.ctx.Done():
			return session.ctx.Err()
		}
	}
	session.markApplied(sequence)
	return nil
}

func groupPollFrames(requestFrames []pollRequestFrame, configuration limits.Config) ([]string, map[string][]wireRT.Frame) {
	tags := make([]string, 0, len(requestFrames))
	grouped := make(map[string][]wireRT.Frame)
	for _, requestFrame := range requestFrames {
		frame, err := wireRT.DecodeJSONFrame(requestFrame.Frame, configuration)
		if err != nil {
			continue
		}
		if _, seen := grouped[requestFrame.Socket]; !seen {
			tags = append(tags, requestFrame.Socket)
		}
		grouped[requestFrame.Socket] = append(grouped[requestFrame.Socket], frame)
	}
	return tags, grouped
}

func (session *httpPollSession) wasApplied(sequence uint64) bool {
	_, ok := session.applied[sequence]
	return ok
}

func (session *httpPollSession) markApplied(sequence uint64) {
	session.applied[sequence] = struct{}{}
	session.appliedOrder = append(session.appliedOrder, sequence)
	if len(session.appliedOrder) <= maxPollClientSequences {
		return
	}
	delete(session.applied, session.appliedOrder[0])
	session.appliedOrder = session.appliedOrder[1:]
}

func (session *httpPollSession) socketFor(tag string) (*pollSocketState, bool) {
	session.mutex.Lock()
	if session.closed {
		session.mutex.Unlock()
		return nil, false
	}
	if socket := session.sockets[tag]; socket != nil {
		session.mutex.Unlock()
		return socket, true
	}
	if len(session.sockets) >= maxPollSocketsPerSession {
		session.mutex.Unlock()
		return nil, false
	}
	ctx, cancel := context.WithCancel(session.ctx)
	socket := &pollSocketState{tag: tag, source: newPollFrameSource(session.server.idleTimeout), cancel: cancel, done: make(chan struct{})}
	session.sockets[tag] = socket
	session.socketWait.Add(1)
	session.mutex.Unlock()
	go session.runSocket(ctx, socket)
	return socket, true
}

func (session *httpPollSession) runSocket(ctx context.Context, socket *pollSocketState) {
	defer session.socketWait.Done()
	defer close(socket.done)
	defer socket.source.close()
	policy := session.server.policy
	policy.ClientIdleTimeout = socket.source.ClientIdleTimeout()
	err := session.server.server.serve(ctx, session.server.config, policy, socket.source, func() (*connWriter, error) {
		return newFrameWriter(ctx, session.server.config, policy.WriteTimeout, wireRT.EncodeJSONFrame,
			func(_ context.Context, frame []byte) error { return session.enqueue(socket.tag, frame) },
			func() {})
	})
	session.removeSocket(socket, err)
}

func (session *httpPollSession) removeSocket(socket *pollSocketState, runError error) {
	session.mutex.Lock()
	if session.sockets[socket.tag] == socket {
		delete(session.sockets, socket.tag)
	}
	closed := session.closed
	session.mutex.Unlock()
	if closed || session.ctx.Err() != nil {
		return
	}
	_ = session.enqueueClosed(socket.tag)
}

func writePollConflict(w http.ResponseWriter) {
	body := []byte(`{"error_code":409}`)
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Content-Length", strconv.Itoa(len(body)))
	w.WriteHeader(http.StatusConflict)
	_, _ = w.Write(body)
}

func writePollReply(w http.ResponseWriter, sessionID string, frames []pollOutboundFrame) {
	if frames == nil {
		frames = make([]pollOutboundFrame, 0)
	}
	body, err := json.Marshal(pollReply{SessionID: sessionID, Frames: frames})
	if err != nil {
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Content-Length", strconv.Itoa(len(body)))
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(body)
}

var _ net.Error = pollTimeoutError{}
var _ frameSource = (*pollFrameSource)(nil)
