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
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"gxb.local/backend/v2/internal/protocol/limits"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

const (
	HTTPPollPath               = "/realtime/poll"
	DefaultHTTPPollIdleTimeout = 30 * time.Second
)

var (
	ErrHTTPPollSessionFull = errors.New("realtime HTTP poll session limit reached")
	ErrHTTPPollUnknown     = errors.New("unknown realtime HTTP poll session")
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

func (s *pollFrameSource) ActivityTime() time.Time {
	s.mutex.Lock()
	defer s.mutex.Unlock()
	return s.activity
}

func (s *pollFrameSource) ClientIdleTimeout() time.Duration { return s.idleTimeout }

func (s *pollFrameSource) touch(at time.Time) {
	s.mutex.Lock()
	s.activity = at
	s.mutex.Unlock()
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

type pollResponseQueue struct {
	mutex     sync.Mutex
	frames    [][]byte
	bytes     int
	maxFrames int
	maxBytes  int
	closed    bool
}

func newPollResponseQueue(configuration limits.Config) *pollResponseQueue {
	return &pollResponseQueue{maxFrames: configuration.WriterFrames, maxBytes: configuration.WriterBytes}
}

func (q *pollResponseQueue) enqueue(frame []byte) error {
	q.mutex.Lock()
	defer q.mutex.Unlock()
	if q.closed {
		return ErrRealtimeWriterClosed
	}
	if len(q.frames) >= q.maxFrames || len(frame) > q.maxBytes-q.bytes {
		return wireRT.ErrQueueFull
	}
	q.frames = append(q.frames, append([]byte(nil), frame...))
	q.bytes += len(frame)
	return nil
}

func (q *pollResponseQueue) drain() [][]byte {
	q.mutex.Lock()
	defer q.mutex.Unlock()
	frames := q.frames
	q.frames = nil
	q.bytes = 0
	return frames
}

func (q *pollResponseQueue) close() {
	q.mutex.Lock()
	q.closed = true
	q.mutex.Unlock()
}

type httpPollSession struct {
	id        string
	ctx       context.Context
	cancel    context.CancelFunc
	source    *pollFrameSource
	responses *pollResponseQueue
	done      chan struct{}
	polling   atomic.Bool
}

type HTTPPollServer struct {
	server      RealtimeServer
	config      limits.Config
	policy      RealtimePolicy
	idleTimeout time.Duration
	context     context.Context
	cancel      context.CancelFunc
	mutex       sync.Mutex
	sessions    map[string]*httpPollSession
}

func NewHTTPPollServer(parent context.Context, server RealtimeServer, idleTimeout time.Duration) (*HTTPPollServer, error) {
	if parent == nil {
		return nil, errors.New("nil realtime HTTP poll context")
	}
	if idleTimeout <= 0 {
		idleTimeout = DefaultHTTPPollIdleTimeout
	}
	configuration, policy, err := server.runtimeConfig()
	if err != nil {
		return nil, err
	}
	ctx, cancel := context.WithCancel(parent)
	return &HTTPPollServer{
		server: server, config: configuration, policy: policy, idleTimeout: idleTimeout, context: ctx, cancel: cancel,
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

type pollRequest struct {
	SessionID string            `json:"session_id"`
	Frames    []json.RawMessage `json:"frames"`
}

type pollReply struct {
	SessionID string            `json:"session_id"`
	Frames    []json.RawMessage `json:"frames"`
}

func (s *HTTPPollServer) handlePoll(w http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodPost {
		w.Header().Set("Allow", http.MethodPost)
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	poll, frames, status := s.decodeRequest(w, request)
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
	if !session.polling.CompareAndSwap(false, true) {
		writePollConflict(w)
		return
	}
	defer session.polling.Store(false)
	if session.ctx.Err() != nil {
		writePollConflict(w)
		return
	}
	session.source.touch(time.Now())
	batch := &pollBatch{frames: frames, done: make(chan struct{})}
	select {
	case session.source.incoming <- batch:
	case <-session.done:
		writePollConflict(w)
		return
	case <-request.Context().Done():
		return
	case <-s.context.Done():
		return
	}
	select {
	case <-batch.done:
	case <-session.done:
		writePollConflict(w)
		return
	case <-request.Context().Done():
		return
	case <-s.context.Done():
		return
	}
	if session.ctx.Err() != nil {
		writePollConflict(w)
		return
	}
	queued := session.responses.drain()
	replyFrames := make([]json.RawMessage, len(queued))
	for index, frame := range queued {
		replyFrames[index] = json.RawMessage(frame)
	}
	writePollReply(w, pollReply{SessionID: session.id, Frames: replyFrames})
}

func (s *HTTPPollServer) decodeRequest(w http.ResponseWriter, request *http.Request) (pollRequest, []wireRT.Frame, int) {
	body, err := io.ReadAll(http.MaxBytesReader(w, request.Body, int64(s.config.RealtimeBufferedBytes)))
	if err != nil {
		var maxBytesError *http.MaxBytesError
		if errors.As(err, &maxBytesError) {
			return pollRequest{}, nil, http.StatusRequestEntityTooLarge
		}
		return pollRequest{}, nil, http.StatusBadRequest
	}
	if strings.HasPrefix(strings.ToLower(request.Header.Get("Content-Type")), "application/x-www-form-urlencoded") {
		values, err := url.ParseQuery(string(body))
		if err != nil || len(values["payload"]) != 1 {
			return pollRequest{}, nil, http.StatusBadRequest
		}
		body = []byte(values.Get("payload"))
	}
	decoder := json.NewDecoder(strings.NewReader(string(body)))
	decoder.DisallowUnknownFields()
	var poll pollRequest
	if err := decoder.Decode(&poll); err != nil {
		return pollRequest{}, nil, http.StatusBadRequest
	}
	if err := decoder.Decode(new(any)); !errors.Is(err, io.EOF) {
		return pollRequest{}, nil, http.StatusBadRequest
	}
	if len(poll.Frames) > s.config.WriterFrames {
		return pollRequest{}, nil, http.StatusRequestEntityTooLarge
	}
	frames := make([]wireRT.Frame, len(poll.Frames))
	for index, encoded := range poll.Frames {
		frame, err := wireRT.DecodeJSONFrame(encoded, s.config)
		if err != nil {
			return pollRequest{}, nil, http.StatusBadRequest
		}
		frames[index] = frame
	}
	return poll, frames, 0
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
		id: base64.RawURLEncoding.EncodeToString(idBytes), ctx: ctx, cancel: cancel,
		source: newPollFrameSource(s.idleTimeout), responses: newPollResponseQueue(s.config), done: make(chan struct{}),
	}
	s.sessions[session.id] = session
	go s.runSession(session)
	return session, 0
}

func (s *HTTPPollServer) runSession(session *httpPollSession) {
	defer close(session.done)
	policy := s.policy
	policy.ClientIdleTimeout = session.source.ClientIdleTimeout()
	if err := s.server.serve(session.ctx, s.config, policy, session.source, func() (*connWriter, error) {
		return newFrameWriter(session.ctx, s.config, policy.WriteTimeout, wireRT.EncodeJSONFrame,
			func(_ context.Context, frame []byte) error { return session.responses.enqueue(frame) },
			session.responses.close)
	}); err != nil {
		session.responses.close()
	}
	session.responses.close()
	session.cancel()
	s.mutex.Lock()
	if s.sessions[session.id] == session {
		delete(s.sessions, session.id)
	}
	s.mutex.Unlock()
}

func writePollConflict(w http.ResponseWriter) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusConflict)
	_, _ = io.WriteString(w, `{"error_code":409}`)
}

func writePollReply(w http.ResponseWriter, reply pollReply) {
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(reply); err != nil {
		return
	}
}

var _ net.Error = pollTimeoutError{}
var _ frameSource = (*pollFrameSource)(nil)
