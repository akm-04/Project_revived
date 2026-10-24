package activitydirectory

import (
	"context"
	"errors"
	"reflect"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/activity"
	"gxb.local/backend/v2/internal/domain/identity"
)

var (
	ErrInvalidRegistration = errors.New("activity directory: invalid provider registration")
	ErrInvalidContext      = errors.New("activity directory: invalid projection context")
	ErrProviderMismatch    = errors.New("activity directory: provider projection table mismatch")
	ErrUnsupportedDetails  = errors.New("activity directory: unsupported details value")
)

type ProjectionContext struct {
	Actor      identity.ActorContext
	DecisionAt time.Time
}

func validateActor(actor identity.ActorContext) error {
	if !actor.AccountUID.Valid() || actor.AccountID.UUID().IsZero() || actor.SessionID.UUID().IsZero() || actor.ContextID.UUID().IsZero() ||
		!actor.LogicalServerID.Valid() || !actor.PlayerID.Valid() || actor.ContextGeneration <= 0 || actor.SessionLivenessVersion <= 0 || actor.ContextLivenessVersion <= 0 {
		return ErrInvalidContext
	}
	return nil
}

func (c ProjectionContext) Validate() error {
	if err := validateActor(c.Actor); err != nil || c.DecisionAt.IsZero() {
		return ErrInvalidContext
	}
	return nil
}

type Provider interface {
	Project(context.Context, ProjectionContext) (activity.Projection, bool, error)
}

type Registration struct {
	Name              string
	TableID           int64
	RuntimeCapability string
	ContentCapability string
	Provider          Provider
}

type ContentCapabilities interface {
	SupportsContentCapability(string) bool
}

type StaticContentCapabilities struct{ names map[string]struct{} }

func NewStaticContentCapabilities(names []string) (StaticContentCapabilities, error) {
	out := StaticContentCapabilities{names: make(map[string]struct{}, len(names))}
	for _, raw := range names {
		n := strings.TrimSpace(raw)
		if n == "" || n != raw {
			return StaticContentCapabilities{}, errors.New("activity directory: invalid content capability")
		}
		if _, ok := out.names[n]; ok {
			return StaticContentCapabilities{}, errors.New("activity directory: duplicate content capability")
		}
		out.names[n] = struct{}{}
	}
	return out, nil
}

func (s StaticContentCapabilities) SupportsContentCapability(name string) bool {
	_, ok := s.names[name]
	return ok
}

func nilProvider(p Provider) bool {
	if p == nil {
		return true
	}
	v := reflect.ValueOf(p)
	switch v.Kind() {
	case reflect.Chan, reflect.Func, reflect.Interface, reflect.Map, reflect.Pointer, reflect.Slice:
		return v.IsNil()
	default:
		return false
	}
}
