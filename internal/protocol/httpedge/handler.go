package httpedge

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

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

type Router struct{ handlers map[uint16]Dispatcher }

func NewRouter() *Router { return &Router{handlers: make(map[uint16]Dispatcher)} }
func (r *Router) Register(mid uint16, h Dispatcher) error {
	if h == nil {
		return wire.NewError(wire.ErrInternal, 500, "nil_handler", "nil dispatcher")
	}
	if _, exists := r.handlers[mid]; exists {
		return wire.NewError(wire.ErrInternal, 500, "duplicate_handler", "duplicate numeric MID binding")
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
}

func (h Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "method_not_allowed"})
		return
	}
	if h.Admission == nil || !h.Admission.TryAcquire() {
		w.Header().Set("Retry-After", "1")
		writeJSON(w, http.StatusServiceUnavailable, map[string]any{"error": "edge_saturated"})
		return
	}
	defer h.Admission.Release()

	op, err := h.Operations.New(h.Policies)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "operation_context"})
		return
	}
	decoded, edgeErr := Decode(r, h.Limits)
	if edgeErr != nil {
		writeJSON(w, edgeErr.HTTPStatus, map[string]any{"error": edgeErr.PublicCode})
		return
	}
	defer decoded.Cleanup()

	desc, known := mids.Lookup(decoded.MID)
	if !known {
		h.recordObservation(decoded, op.StartedAt)
		writeJSON(w, http.StatusNotFound, map[string]any{"error": "unknown_mid", "mid": decoded.MID})
		return
	}
	if desc.Transport != mids.HTTP {
		writeJSON(w, http.StatusBadRequest, map[string]any{"error": "wrong_transport", "mid": decoded.MID})
		return
	}
	dispatcher, implemented := h.Router.Lookup(decoded.MID)
	if !implemented {
		h.recordObservation(decoded, op.StartedAt)
		writeJSON(w, http.StatusNotImplemented, map[string]any{"error": "unimplemented_mid", "mid": decoded.MID})
		return
	}
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
	status := resp.HTTPStatus
	if status == 0 {
		status = http.StatusOK
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
		payload = []byte(`{"error":"response_encoding"}`)
	}
	payload = append(payload, '\n')
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_, _ = w.Write(payload)
}
