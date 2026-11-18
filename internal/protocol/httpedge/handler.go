package httpedge

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"log"
	"mime"
	"mime/multipart"
	"net/http"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/foundation/undelivered"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	"gxb.local/backend/v2/internal/protocol/observe"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type Response struct {
	HTTPStatus int
	Body       map[string]any
	// JSON permits a source-proven non-object JSON response (for example MID2864).
	// When non-nil it takes precedence over Body. Existing object responses remain unchanged.
	JSON    any
	Headers map[string]string
	// Cause is the server-side error behind a failure response. It is never
	// written to the client; the request journal keeps it (I85_REQUEST_JOURNAL_V1 R2).
	Cause error
	// Inactive marks the shared inactive mode answer (I9_MODE_FRAMEWORK_V1 F5); the journal records INACTIVE_MODE.
	Inactive bool
	// Raw is an exact encoded reply body (R6 replay). When non-nil it is written
	// instead of encoding Body/JSON, so the bytes that were committed come back.
	Raw []byte
}

type DispatchRequest struct {
	Envelope wire.RequestEnvelope
	Upload   *Upload
}

type Dispatcher interface {
	Dispatch(context.Context, DispatchRequest) Response
}

type DispatcherFunc func(context.Context, DispatchRequest) Response

func (f DispatcherFunc) Dispatch(ctx context.Context, req DispatchRequest) Response {
	return f(ctx, req)
}

type Router struct {
	handlers map[uint16]Dispatcher
	// Wrap, when set, wraps every dispatcher registered after it was set.
	Wrap func(Dispatcher) Dispatcher
}

func NewRouter() *Router { return &Router{handlers: make(map[uint16]Dispatcher)} }
func (r *Router) Register(mid uint16, h Dispatcher) error {
	if h == nil {
		return wire.NewError(wire.ErrInternal, 500, "nil_handler", "nil dispatcher")
	}
	if _, exists := r.handlers[mid]; exists {
		return wire.NewError(wire.ErrInternal, 500, "duplicate_handler", "duplicate numeric MID binding")
	}
	if r.Wrap != nil {
		h = r.Wrap(h)
	}
	r.handlers[mid] = h
	return nil
}
func (r *Router) Lookup(mid uint16) (Dispatcher, bool) {
	if r == nil {
		return nil, false
	}
	h, ok := r.handlers[mid]
	return h, ok
}

// QueueWaitEstimate is the rolling queue-to-commit measurement the edge consults before admitting a request
// (C1-5). *tx.Semaphore implements it.
type QueueWaitEstimate interface{ ExpectedWait() time.Duration }

type Handler struct {
	Limits    limits.Config
	Admission *Admission
	// Decoding bounds the request bodies read at once; Admission is taken only after the body is read (A-047), so a
	// stalled body never holds a dispatch slot. Nil means no bound.
	Decoding   *Admission
	Operations operation.Factory
	Policies   policy.Set
	Router     *Router
	Observer   observe.Sink
	// Journal, when set, receives one record per request (I85_REQUEST_JOURNAL_V1).
	Journal observability.RequestJournal
	// QueueBudget bounds how long a request may queue for a database connection (C1-1); zero means
	// DefaultQueueBudget.
	QueueBudget time.Duration
	// QueueWait, when set, refuses before dispatch when a transaction joining the queue now would take longer
	// than the request's remaining budget (C1-5). Nil leaves only the in-flight cap in force.
	QueueWait QueueWaitEstimate
	// Undelivered, when set, keeps the reply of a state-changing success whose write or flush failed (R6).
	Undelivered undelivered.Marker
	// Metrics receives the R6 mark counters; nil disables them.
	Metrics observability.Metrics
	// Conformance, when set, checks every successful Body/JSON reply against the
	// stock client's REQUIRED paths. It reports violations only, never a change.
	Conformance interface {
		Check(mid uint16, reply any) []string
	}
}

const replyConformanceViolations = "reply_conformance_violations_total"

// undeliveredMarkWriteTimeout bounds the separate autocommit mark write, which
// must not be cancelled with the client connection it is recording.
const undeliveredMarkWriteTimeout = 2 * time.Second

// supersededMarkLabels marks a mark dropped because a later state request took
// the claim; the counter stays under the shared mark-failure name.
var supersededMarkLabels, _ = observability.NewLabels(observability.Pair{Key: "outcome", Value: "superseded"})

func (h Handler) counter(name string, delta uint64) {
	h.counterWith(name, observability.Labels{}, delta)
}

func (h Handler) counterWith(name string, labels observability.Labels, delta uint64) {
	if h.Metrics == nil {
		return
	}
	h.Metrics.Counter(name, labels, delta)
}

func (h Handler) queueBudget() time.Duration {
	if h.QueueBudget > 0 {
		return h.QueueBudget
	}
	return DefaultQueueBudget
}

// DefaultQueueBudget is the stock client's 20 s HTTP timeout (Backend.lua:645-647) less a 2 s margin for the
// reply: a request still queued after it is answered to nobody (C1_PRIVATE_CLIENT_BUDGET_V1, tunable).
const DefaultQueueBudget = 18 * time.Second

// rawCaptureBytes bounds the request prefix kept for unknown or undecodable
// requests (I85_REQUEST_JOURNAL_V1 R3).
const rawCaptureBytes = 16 << 10

func (h Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	ctx, note := observability.WithRequestNote(r.Context())
	r = r.WithContext(ctx)
	var record observability.RequestRecord
	if h.Journal == nil {
		h.serve(w, r, &record, note)
		return
	}
	started := time.Now()
	body := &bodyCapture{reader: r.Body}
	r.Body = body
	recorder := &responseRecorder{ResponseWriter: w}
	record = observability.RequestRecord{ReceivedAt: started, Disposition: observability.RequestRejectedAtEdge}
	h.serve(recorder, r, &record, note)
	record.Latency = time.Since(started)
	record.HTTPStatus = recorder.status
	record.ResponseBytes = recorder.bytes
	record.RequestBytes = body.count
	record.Actor = note.Actor()
	record.Replay = note.Replayed()
	keepsRaw := record.Disposition == observability.RequestUnknownMID || record.Disposition == observability.RequestUndecodable
	if keepsRaw {
		record.Raw = rawEnvelope(r.Header.Get("Content-Type"), body.prefix)
	}
	h.Journal.Record(record)
}

func (h Handler) decode(r *http.Request) (*Decoded, *wire.EdgeError, bool) {
	if h.Decoding != nil {
		if !h.Decoding.TryAcquire() {
			return nil, nil, true
		}
		defer h.Decoding.Release()
	}
	decoded, edgeErr := Decode(r, h.Limits)
	return decoded, edgeErr, false
}

// writeSaturated answers an admission refusal and keeps its cause in the journal row (I85_REQUEST_JOURNAL_V1 R2).
func writeSaturated(w http.ResponseWriter, record *observability.RequestRecord, detail string) {
	record.Cause = wire.NewError(wire.ErrSaturated, http.StatusServiceUnavailable, "edge_saturated", detail)
	w.Header().Set("Retry-After", "1")
	edgeFailure(w, wire.ErrSaturated, "edge_saturated")
}

func (h Handler) serve(w http.ResponseWriter, r *http.Request, record *observability.RequestRecord, note *observability.RequestNote) {
	if r.Method != http.MethodPost {
		record.Disposition = observability.RequestUndecodable
		edgeFailure(w, wire.ErrMalformed, "method_not_allowed")
		return
	}
	arrived := time.Now()
	budget := h.queueBudget()
	decoded, edgeErr, saturated := h.decode(r)
	if saturated {
		writeSaturated(w, record, "decoding limit saturated")
		return
	}
	if edgeErr != nil {
		record.Disposition = observability.RequestUndecodable
		record.Cause = edgeErr
		edgeFailure(w, edgeErr.Class, edgeErr.PublicCode)
		return
	}
	defer decoded.Cleanup()
	if h.QueueWait != nil && h.QueueWait.ExpectedWait() > budget-time.Since(arrived) {
		writeSaturated(w, record, "queue budget exhausted")
		return
	}
	if h.Admission == nil || !h.Admission.TryAcquire() {
		writeSaturated(w, record, "in-flight limit saturated")
		return
	}
	defer h.Admission.Release()

	op, err := h.Operations.New(h.Policies)
	if err != nil {
		record.Cause = err
		edgeFailure(w, wire.ErrInternal, "operation_context")
		return
	}
	record.MID, record.HasMID = int(decoded.MID), true
	record.RequestSHA256 = decoded.RawSHA256[:]

	desc, known := mids.Lookup(decoded.MID)
	if !known {
		record.Disposition = observability.RequestUnknownMID
		h.recordObservation(decoded, op.StartedAt)
		edgeFailure(w, wire.ErrUnknownMID, "unknown_mid")
		return
	}
	if desc.Transport != mids.HTTP {
		record.Disposition = observability.RequestUndecodable
		edgeFailure(w, wire.ErrMalformed, "wrong_transport")
		return
	}
	dispatcher, implemented := h.Router.Lookup(decoded.MID)
	if !implemented {
		record.Disposition = observability.RequestUnknownMID
		h.recordObservation(decoded, op.StartedAt)
		edgeFailure(w, wire.ErrUnimplemented, "unimplemented_mid")
		return
	}
	record.Disposition = observability.RequestDispatched
	claims := credentialClaims(decoded.Params)
	env := wire.RequestEnvelope{
		Operation:       op,
		MID:             decoded.MID,
		Transport:       wire.TransportHTTP,
		Direction:       wire.DirectionC2S,
		Encoding:        decoded.Encoding,
		ReceivedAt:      op.StartedAt,
		RawBytes:        decoded.RawBytes,
		RawSHA256:       decoded.RawSHA256,
		Params:          decoded.Params,
		Claims:          claims,
		CatalogRevision: mids.CatalogRevision(),
		RemoteLabel:     remoteLabel(r.RemoteAddr),
	}
	resp := dispatcher.Dispatch(tx.WithAdmissionDeadline(r.Context(), op.StartedAt.Add(budget)), DispatchRequest{Envelope: env, Upload: decoded.Upload})
	record.ErrorCode = stockErrorCode(resp.Body)
	status := resp.HTTPStatus
	if status == 0 {
		status = http.StatusOK
	}
	record.Cause = resp.Cause
	if resp.Inactive {
		record.Disposition = observability.RequestInactiveMode
	}
	publicCode, hasPublicCode := resp.Body["error"].(string)
	if record.Cause == nil && status >= http.StatusInternalServerError && hasPublicCode {
		record.Cause = errors.New(publicCode)
	}
	h.checkReplyConformance(decoded.MID, status, resp)
	for k, v := range resp.Headers {
		w.Header().Set(k, v)
	}
	var encoded []byte
	var writeErr error
	encodable := true
	if resp.Raw != nil {
		encoded = resp.Raw
		writeErr = writeRaw(w, status, encoded)
	} else {
		payload := any(resp.Body)
		if resp.JSON != nil {
			payload = resp.JSON
		}
		encoded, encodable, writeErr = writeJSONValue(w, status, payload)
	}
	flushErr := http.NewResponseController(w).Flush()
	if errors.Is(flushErr, http.ErrNotSupported) {
		flushErr = nil
	}
	notDelivered := writeErr != nil || flushErr != nil || r.Context().Err() != nil
	if notDelivered && encodable {
		h.markUndelivered(r.Context(), note, int64(decoded.MID), status, resp, op.StartedAt, encoded)
	}
}

// checkReplyConformance reports, but never changes, a successful Body/JSON reply
// that omits a REQUIRED client path (A-079). A Raw reply was checked when its
// committed bytes were produced, and failures carry no client reply obligation.
func (h Handler) checkReplyConformance(mid uint16, status int, response Response) {
	if h.Conformance == nil || response.Raw != nil || !successReply(status, response) {
		return
	}
	reply := any(response.Body)
	if response.JSON != nil {
		reply = response.JSON
	}
	for _, path := range h.Conformance.Check(mid, reply) {
		log.Printf("reply_conformance_violation mid=%d path=%s", mid, path)
		h.counter(replyConformanceViolations, 1)
	}
}

// markUndelivered records the committed success reply only when the edge can
// see that it did not reach the client (R6 decision 5). A failed mark write is
// logged and counted; behaviour then stays as today.
func (h Handler) markUndelivered(ctx context.Context, note *observability.RequestNote, mid int64, status int, resp Response, at time.Time, reply []byte) {
	if h.Undelivered == nil || note.Replayed() || !successReply(status, resp) {
		return
	}
	fingerprint, hasFingerprint := note.ParamsFingerprint()
	claim, hasClaim := note.Claim()
	actor := note.Actor()
	if !hasFingerprint || !hasClaim || actor.PlayerID <= 0 || actor.SessionID == "" || len(reply) == 0 {
		return
	}
	markContext, cancel := context.WithTimeout(context.WithoutCancel(ctx), undeliveredMarkWriteTimeout)
	defer cancel()
	err := h.Undelivered.Mark(markContext, undelivered.Mark{
		PlayerID: actor.PlayerID, Claim: claim, SessionID: actor.SessionID, MID: mid, Fingerprint: fingerprint, Reply: reply, MarkedAt: at.UTC(),
	})
	if errors.Is(err, undelivered.ErrSuperseded) {
		h.counterWith(undelivered.MarkFailuresTotal, supersededMarkLabels, 1)
		log.Printf("undelivered mark: superseded by a later state request")
		return
	}
	if err != nil {
		h.counter(undelivered.MarkFailuresTotal, 1)
		log.Printf("undelivered mark: %v", err)
		return
	}
	h.counter(undelivered.MarksTotal, 1)
}

func successReply(status int, resp Response) bool {
	if status != http.StatusOK && resp.HTTPStatus != 0 {
		return false
	}
	return stockErrorCode(resp.Body) == 0
}

// D5 PRIVATE_POLICY tunables; both are message.lua rows (35028 "Not Available",
// 35033 "The server is busy, please try again later.").
const (
	edgeRefusalCode   int64 = 35028
	edgeTransientCode int64 = 35033
)

// edgeFailure is the only place the edge writes a non-200 reply. Backend.lua
// :428-447 toasts the message.lua row for an empty error_msg; no edge failure
// restarts the game.
func edgeFailure(w http.ResponseWriter, class wire.ErrorClass, publicCode string) {
	status, code := edgeFailureStatus(class)
	writeJSON(w, status, map[string]any{"error_code": code, "error_msg": "", "error": publicCode})
}

func edgeFailureStatus(class wire.ErrorClass) (int, int64) {
	switch class {
	case wire.ErrSaturated:
		return http.StatusServiceUnavailable, edgeTransientCode
	case wire.ErrUnknownMID, wire.ErrUnimplemented, wire.ErrForbidden:
		return http.StatusConflict, edgeRefusalCode
	case wire.ErrTooLarge:
		return http.StatusRequestEntityTooLarge, edgeRefusalCode
	case wire.ErrInternal:
		return http.StatusInternalServerError, edgeRefusalCode
	default:
		return http.StatusBadRequest, edgeRefusalCode
	}
}

func (h Handler) recordObservation(decoded *Decoded, now time.Time) {
	if h.Observer == nil || decoded == nil {
		return
	}
	prefix := wire.HashHex(decoded.RawSHA256)
	if len(prefix) > 16 {
		prefix = prefix[:16]
	}
	h.Observer.Record(observe.Observation{MID: decoded.MID, Transport: wire.TransportHTTP, Direction: wire.DirectionC2S, RawBytes: decoded.RawBytes, HashPrefix: prefix, FirstSeen: now, LastSeen: now, Count: 1})
}

func stockErrorCode(body map[string]any) int64 {
	switch code := body["error_code"].(type) {
	case int64:
		return code
	case int:
		return int64(code)
	case float64:
		return int64(code)
	case json.Number:
		parsed, _ := code.Int64()
		return parsed
	default:
		return 0
	}
}

// rawEnvelope keeps the request prefix for R3. A multipart prefix is reduced to
// its part headers and redacted text fields, so an upload file body is never
// stored while the field names and diagnostic values stay.
func rawEnvelope(contentType string, prefix []byte) []byte {
	if !strings.HasPrefix(strings.ToLower(contentType), "multipart/") {
		return prefix
	}
	_, parameters, err := mime.ParseMediaType(contentType)
	boundary := parameters["boundary"]
	if err != nil || boundary == "" || len(prefix) == 0 {
		return nil
	}
	reader := multipart.NewReader(bytes.NewReader(prefix), boundary)
	var envelope bytes.Buffer
	for envelope.Len() < rawCaptureBytes {
		part, err := reader.NextPart()
		if err != nil {
			break
		}
		envelope.WriteString("--" + boundary + "\r\n")
		if disposition := part.Header.Get("Content-Disposition"); disposition != "" {
			envelope.WriteString("Content-Disposition: " + disposition + "\r\n")
		}
		if partType := part.Header.Get("Content-Type"); partType != "" {
			envelope.WriteString("Content-Type: " + partType + "\r\n")
		}
		envelope.WriteString("\r\n")
		if part.FileName() != "" {
			envelope.WriteString("[file body omitted]\r\n")
			continue
		}
		value, _ := io.ReadAll(io.LimitReader(part, int64(rawCaptureBytes-envelope.Len())))
		envelope.Write(redactedFieldValue(part.FormName(), value))
		envelope.WriteString("\r\n")
	}
	if envelope.Len() > rawCaptureBytes {
		envelope.Truncate(rawCaptureBytes)
	}
	return envelope.Bytes()
}

// redactedFieldValue masks a text field whose name carries a secret.
func redactedFieldValue(name string, value []byte) []byte {
	redacted, _ := observability.RedactFields(map[string]any{name: string(value)})[name].(string)
	return []byte(redacted)
}

// bodyCapture counts request bytes and keeps the first rawCaptureBytes.
type bodyCapture struct {
	reader io.ReadCloser
	count  int64
	prefix []byte
}

func (b *bodyCapture) Read(p []byte) (int, error) {
	n, err := b.reader.Read(p)
	b.count += int64(n)
	room := rawCaptureBytes - len(b.prefix)
	if room > 0 {
		b.prefix = append(b.prefix, p[:min(n, room)]...)
	}
	return n, err
}

func (b *bodyCapture) Close() error { return b.reader.Close() }

type responseRecorder struct {
	http.ResponseWriter
	status int
	bytes  int64
}

func (r *responseRecorder) WriteHeader(status int) {
	r.status = status
	r.ResponseWriter.WriteHeader(status)
}

func (r *responseRecorder) Write(p []byte) (int, error) {
	if r.status == 0 {
		r.status = http.StatusOK
	}
	n, err := r.ResponseWriter.Write(p)
	r.bytes += int64(n)
	return n, err
}

// Unwrap lets http.NewResponseController reach the real writer's Flush.
func (r *responseRecorder) Unwrap() http.ResponseWriter { return r.ResponseWriter }

func credentialClaims(params map[string]any) wire.CredentialClaims {
	var out wire.CredentialClaims
	if s, ok := params["token"].(string); ok {
		out.Token = s
	}
	switch v := params["region"].(type) {
	case json.Number:
		out.Region, _ = v.Int64()
	case string:
		out.Region, _ = strconv.ParseInt(v, 10, 64)
	case float64:
		out.Region = int64(v)
	}
	return out
}

func remoteLabel(addr string) string {
	// Keep only a bounded class-like prefix. Raw remote metadata is transport
	// telemetry, not identity or authorization authority.
	if len(addr) > 96 {
		addr = addr[:96]
	}
	return strings.TrimSpace(addr)
}

func writeJSON(w http.ResponseWriter, status int, body map[string]any) {
	_, _, _ = writeJSONValue(w, status, body)
}

// writeJSONValue returns the exact bytes it attempted to write, whether they
// are the dispatcher's reply (false on an encoding failure), and the write
// error. The R6 edge keeps only a committed success reply whose delivery failed.
func writeJSONValue(w http.ResponseWriter, status int, body any) ([]byte, bool, error) {
	if body == nil {
		body = map[string]any{}
	}
	// R6 D12: encode before committing success headers. A serialization
	// failure must not leave an already-committed 2xx response, and it must
	// never cause the dispatcher/gameplay operation to be executed again.
	payload, err := json.Marshal(body)
	encodable := true
	if err != nil {
		// U8: the action may have committed, so the client relogs and reloads
		// (message.lua 20003, the same text as stockruntime sessionFailureMessage).
		status = http.StatusUnauthorized
		payload = []byte(`{"error_code":20003,"error_msg":"Unstable network,try to relog in!","error":"response_encoding"}`)
		encodable = false
	}
	payload = append(payload, '\n')
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_, writeErr := w.Write(payload)
	return payload, encodable, writeErr
}

func writeRaw(w http.ResponseWriter, status int, payload []byte) error {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_, err := w.Write(payload)
	return err
}
