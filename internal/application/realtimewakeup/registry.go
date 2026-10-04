package realtimewakeup

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"reflect"
	"strings"
	"unicode/utf8"
)

const (
	EnvelopeVersion   = 1
	MaxRouteBytes     = 64
	MaxReferenceBytes = 256
	MaxEnvelopeBytes  = 512
)

var (
	ErrInvalidEnvelope    = errors.New("invalid realtime wakeup envelope")
	ErrInvalidRoute       = errors.New("invalid realtime wakeup route")
	ErrDuplicateRoute     = errors.New("duplicate realtime wakeup route")
	ErrUnknownRoute       = errors.New("unknown realtime wakeup route")
	ErrInvalidRouteHandle = errors.New("invalid realtime wakeup route handler")
)

// Envelope is deliberately reference-only. It carries no gameplay value,
// reward payload or occurrence count; the selected route must reload canonical
// owner/feature delivery intent before deciding whether anything is published.
type Envelope struct {
	Version int    `json:"v"`
	Route   string `json:"route"`
	Ref     string `json:"ref"`
}

func (e Envelope) Validate() error {
	if e.Version != EnvelopeVersion || !validToken(e.Route, MaxRouteBytes) || !validReference(e.Ref) {
		return ErrInvalidEnvelope
	}
	return nil
}

func (e Envelope) Encode() ([]byte, error) {
	if err := e.Validate(); err != nil {
		return nil, err
	}
	b, err := json.Marshal(e)
	if err != nil {
		return nil, err
	}
	if len(b) > MaxEnvelopeBytes {
		return nil, ErrInvalidEnvelope
	}
	return b, nil
}

func Decode(b []byte) (Envelope, error) {
	if len(b) == 0 || len(b) > MaxEnvelopeBytes {
		return Envelope{}, ErrInvalidEnvelope
	}
	dec := json.NewDecoder(bytes.NewReader(b))
	dec.DisallowUnknownFields()
	var e Envelope
	if err := dec.Decode(&e); err != nil {
		return Envelope{}, fmt.Errorf("%w: %v", ErrInvalidEnvelope, err)
	}
	var extra any
	if err := dec.Decode(&extra); !errors.Is(err, io.EOF) {
		return Envelope{}, ErrInvalidEnvelope
	}
	if err := e.Validate(); err != nil {
		return Envelope{}, err
	}
	return e, nil
}

// RouteHandler owns canonical reload and delivery-intent fencing for one exact
// route. The wakeup reference is never permission to apply gameplay state.
type RouteHandler interface {
	ReloadAndDeliver(context.Context, string) error
}

type RouteHandlerFunc func(context.Context, string) error

func (f RouteHandlerFunc) ReloadAndDeliver(ctx context.Context, ref string) error {
	if f == nil {
		return ErrInvalidRouteHandle
	}
	return f(ctx, ref)
}

type Registration struct {
	Route   string
	Handler RouteHandler
}

type Registry struct{ handlers map[string]RouteHandler }

// NewRegistry freezes the finite route set. Passing no registrations is valid
// and is the I7A-2 production state until an owning feature explicitly activates
// a route with its canonical reload semantics.
func NewRegistry(in ...Registration) (Registry, error) {
	m := make(map[string]RouteHandler, len(in))
	for _, reg := range in {
		if !validToken(reg.Route, MaxRouteBytes) || nilHandler(reg.Handler) {
			return Registry{}, ErrInvalidRoute
		}
		if _, exists := m[reg.Route]; exists {
			return Registry{}, fmt.Errorf("%w: %s", ErrDuplicateRoute, reg.Route)
		}
		m[reg.Route] = reg.Handler
	}
	return Registry{handlers: m}, nil
}

func (r Registry) Dispatch(ctx context.Context, e Envelope) error {
	if err := e.Validate(); err != nil {
		return err
	}
	h, ok := r.handlers[e.Route]
	if !ok {
		return fmt.Errorf("%w: %s", ErrUnknownRoute, e.Route)
	}
	return h.ReloadAndDeliver(ctx, e.Ref)
}

func validToken(s string, max int) bool {
	if s == "" || s != strings.TrimSpace(s) || len(s) > max || !utf8.ValidString(s) {
		return false
	}
	for _, r := range s {
		if !((r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') || r == '.' || r == '_' || r == '-') {
			return false
		}
	}
	return true
}

func validReference(s string) bool {
	if s == "" || s != strings.TrimSpace(s) || len(s) > MaxReferenceBytes || !utf8.ValidString(s) {
		return false
	}
	for _, r := range s {
		if r < 0x20 || r == 0x7f {
			return false
		}
	}
	return true
}

func nilHandler(h RouteHandler) bool {
	if h == nil {
		return true
	}
	v := reflect.ValueOf(h)
	switch v.Kind() {
	case reflect.Chan, reflect.Func, reflect.Interface, reflect.Map, reflect.Ptr, reflect.Slice:
		return v.IsNil()
	default:
		return false
	}
}
