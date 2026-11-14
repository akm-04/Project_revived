package httpedge

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
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

type Handler struct {
	Limits     limits.Config
	Admission  *Admission
	Operations operation.Factory
	Policies   policy.Set
	Router     *Router
	Observer   observe.Sink
	// Journal, when set, receives one record per request (I85_REQUEST_JOURNAL_V1).
	Journal observability.RequestJournal
}

// rawCaptureBytes bounds the request prefix kept for unknown or undecodable
// requests (I85_REQUEST_JOURNAL_V1 R3).
const rawCaptureBytes = 16 << 10

func (h Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	var record observability.RequestRecord
	if h.Journal == nil {
		h.serve(w, r, &record)
		return
	}
	started := time.Now()
	ctx, note := observability.WithRequestNote(r.Context())
	body := &bodyCapture{reader: r.Body}
	r = r.WithContext(ctx)
	r.Body = body
	recorder := &responseRecorder{ResponseWriter: w}
	record = observability.RequestRecord{ReceivedAt: started, Disposition: observability.RequestRejectedAtEdge}
	h.serve(recorder, r, &record)
	record.Latency = time.Since(started)
	record.HTTPStatus = recorder.status
	record.ResponseBytes = recorder.bytes
	record.RequestBytes = body.count
	record.Actor = note.Actor()
	keepsRaw := record.Disposition == observability.RequestUnknownMID || record.Disposition == observability.RequestUndecodable
	if keepsRaw && !strings.HasPrefix(strings.ToLower(r.Header.Get("Content-Type")), "multipart/") {
		record.Raw = body.prefix
	}
	h.Journal.Record(record)
}

func (h Handler) serve(w http.ResponseWriter, r *http.Request, record *observability.RequestRecord) {
	if r.Method != http.MethodPost {
		record.Disposition = observability.RequestUndecodable
		edgeFailure(w, wire.ErrMalformed, "method_not_allowed")
		return
	}
	if h.Admission == nil || !h.Admission.TryAcquire() {
		w.Header().Set("Retry-After", "1")
		edgeFailure(w, wire.ErrSaturated, "edge_saturated")
		return
	}
	defer h.Admission.Release()

	op, err := h.Operations.New(h.Policies)
	if err != nil {
		record.Cause = err
		edgeFailure(w, wire.ErrInternal, "operation_context")
		return
	}
	decoded, edgeErr := Decode(r, h.Limits)
	if edgeErr != nil {
		record.Disposition = observability.RequestUndecodable
		record.Cause = edgeErr
		edgeFailure(w, edgeErr.Class, edgeErr.PublicCode)
		return
	}
	defer decoded.Cleanup()
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
	resp := dispatcher.Dispatch(r.Context(), DispatchRequest{Envelope: env, Upload: decoded.Upload})
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
	for k, v := range resp.Headers {
		w.Header().Set(k, v)
	}
	payload := any(resp.Body)
	if resp.JSON != nil {
		payload = resp.JSON
	}
	writeJSONValue(w, status, payload)
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
	writeJSONValue(w, status, body)
}

func writeJSONValue(w http.ResponseWriter, status int, body any) {
	if body == nil {
		body = map[string]any{}
	}
	// R6 D12: encode before committing success headers. A serialization
	// failure must not leave an already-committed 2xx response, and it must
	// never cause the dispatcher/gameplay operation to be executed again.
	payload, err := json.Marshal(body)
	if err != nil {
		status = http.StatusInternalServerError
		payload = []byte(`{"error_code":35028,"error_msg":"","error":"response_encoding"}`)
	}
	payload = append(payload, '\n')
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_, _ = w.Write(payload)
}
