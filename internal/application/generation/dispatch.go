package generation

import (
	"context"
	"errors"
	"fmt"
	"reflect"
	"strings"

	"gxb.local/backend/v2/internal/foundation/obligation"
)

var (
	ErrInvalidDispatchRegistration = errors.New("invalid obligation dispatch registration")
	ErrUnknownObligationRoute      = errors.New("unknown obligation route")
)

// ObligationHandler owns semantic reload/fencing for one application obligation
// route. A handler must reload canonical owner state; the delivered obligation
// is immutable routing evidence, not gameplay authority.
type ObligationHandler interface {
	HandleObligation(context.Context, obligation.Obligation) error
}

type ObligationHandlerFunc func(context.Context, obligation.Obligation) error

func (f ObligationHandlerFunc) HandleObligation(ctx context.Context, o obligation.Obligation) error {
	if f == nil {
		return errors.New("nil obligation handler")
	}
	return f(ctx, o)
}

type DispatchRegistration struct {
	Kind    string
	Profile string
	Handler ObligationHandler
}

type dispatchRoute struct {
	kind    string
	profile string
}

// UnknownObligationRouteError is deliberately rich enough for River logs and
// operator telemetry to identify an unsupported semantic route without treating
// it as successful work.
type UnknownObligationRouteError struct {
	Kind        string
	Profile     string
	SemanticKey string
}

func (e *UnknownObligationRouteError) Error() string {
	return fmt.Sprintf("%v: kind=%q profile=%q semantic_key=%q", ErrUnknownObligationRoute, e.Kind, e.Profile, e.SemanticKey)
}
func (e *UnknownObligationRouteError) Unwrap() error { return ErrUnknownObligationRoute }

// DispatchRegistry is immutable after construction and contains only explicit
// semantic routes. Unknown kind/profile combinations fail closed.
type DispatchRegistry struct {
	handlers map[dispatchRoute]ObligationHandler
}

func NewDispatchRegistry(in ...DispatchRegistration) (DispatchRegistry, error) {
	m := make(map[dispatchRoute]ObligationHandler, len(in))
	for _, reg := range in {
		kind := strings.TrimSpace(reg.Kind)
		profile := strings.TrimSpace(reg.Profile)
		if kind == "" || nilInterface(reg.Handler) {
			return DispatchRegistry{}, ErrInvalidDispatchRegistration
		}
		route := dispatchRoute{kind: kind, profile: profile}
		if _, exists := m[route]; exists {
			return DispatchRegistry{}, ErrInvalidDispatchRegistration
		}
		m[route] = reg.Handler
	}
	return DispatchRegistry{handlers: m}, nil
}

func (r DispatchRegistry) Dispatch(ctx context.Context, o obligation.Obligation) error {
	if err := o.Validate(); err != nil {
		return err
	}
	route := dispatchRoute{kind: strings.TrimSpace(o.Kind), profile: strings.TrimSpace(o.Profile)}
	h, ok := r.handlers[route]
	if !ok {
		return &UnknownObligationRouteError{Kind: o.Kind, Profile: o.Profile, SemanticKey: o.SemanticKey}
	}
	// Clone the only reference-typed field so a mechanism adapter or handler
	// cannot mutate evidence shared with another retry attempt.
	cloned := o
	cloned.Args = append([]byte(nil), o.Args...)
	return h.HandleObligation(ctx, cloned)
}

func nilInterface(v any) bool {
	if v == nil {
		return true
	}
	rv := reflect.ValueOf(v)
	switch rv.Kind() {
	case reflect.Chan, reflect.Func, reflect.Interface, reflect.Map, reflect.Pointer, reflect.Slice:
		return rv.IsNil()
	default:
		return false
	}
}

// ObligationDispatcher is the narrow application seam used by mechanism
// adapters such as River.
type ObligationDispatcher interface {
	Dispatch(context.Context, obligation.Obligation) error
}

var _ ObligationDispatcher = DispatchRegistry{}
