package generation

import (
	"errors"
	"strings"

	"gxb.local/backend/v2/internal/foundation/ids"
)

var ErrInvalidReference = errors.New("invalid generation reference")

// GenerationID is an internal server-owned generation identity. It is
// intentionally distinct from template, instance, occurrence, entitlement,
// selection and borrowed-reference identities even when the stock wire omits it.
type GenerationID struct{ v ids.UUID }

// OccurrenceID identifies one concrete owner occurrence within a generation.
// It is never interchangeable with GenerationID.
type OccurrenceID struct{ v ids.UUID }

func GenerationIDFrom(v ids.UUID) (GenerationID, error) {
	if v.IsZero() {
		return GenerationID{}, ErrInvalidReference
	}
	return GenerationID{v: v}, nil
}

func OccurrenceIDFrom(v ids.UUID) (OccurrenceID, error) {
	if v.IsZero() {
		return OccurrenceID{}, ErrInvalidReference
	}
	return OccurrenceID{v: v}, nil
}

func (id GenerationID) UUID() ids.UUID { return id.v }
func (id OccurrenceID) UUID() ids.UUID { return id.v }
func (id GenerationID) Valid() bool    { return !id.v.IsZero() }
func (id OccurrenceID) Valid() bool    { return !id.v.IsZero() }

// AuthorityScope names the canonical owner namespace and owner key that fence a
// generation. Kind is deliberately not a universal enum: each owning domain
// defines the vocabulary it accepts (server, guild, player, etc.).
type AuthorityScope struct {
	kind string
	key  string
}

func NewAuthorityScope(kind, key string) (AuthorityScope, error) {
	kind = strings.TrimSpace(kind)
	key = strings.TrimSpace(key)
	if kind == "" || key == "" {
		return AuthorityScope{}, ErrInvalidReference
	}
	return AuthorityScope{kind: kind, key: key}, nil
}

func (s AuthorityScope) Kind() string { return s.kind }
func (s AuthorityScope) Key() string  { return s.key }
func (s AuthorityScope) Valid() bool  { return s.kind != "" && s.key != "" }

// GenerationRef is the narrow shared reference passed across domain seams. The
// domain string owns interpretation; I6A does not define a universal phase or
// gameplay aggregate.
type GenerationRef struct {
	domain string
	scope  AuthorityScope
	id     GenerationID
}

func NewGenerationRef(domain string, scope AuthorityScope, id GenerationID) (GenerationRef, error) {
	domain = strings.TrimSpace(domain)
	if domain == "" || !scope.Valid() || !id.Valid() {
		return GenerationRef{}, ErrInvalidReference
	}
	return GenerationRef{domain: domain, scope: scope, id: id}, nil
}

func (r GenerationRef) Domain() string        { return r.domain }
func (r GenerationRef) Scope() AuthorityScope { return r.scope }
func (r GenerationRef) ID() GenerationID      { return r.id }
func (r GenerationRef) Valid() bool           { return r.domain != "" && r.scope.Valid() && r.id.Valid() }

// OccurrenceRef adds one concrete occurrence identity without aliasing the
// parent generation identity.
type OccurrenceRef struct {
	generation GenerationRef
	id         OccurrenceID
}

func NewOccurrenceRef(g GenerationRef, id OccurrenceID) (OccurrenceRef, error) {
	if !g.Valid() || !id.Valid() {
		return OccurrenceRef{}, ErrInvalidReference
	}
	return OccurrenceRef{generation: g, id: id}, nil
}

func (r OccurrenceRef) Generation() GenerationRef { return r.generation }
func (r OccurrenceRef) ID() OccurrenceID          { return r.id }
func (r OccurrenceRef) Valid() bool               { return r.generation.Valid() && r.id.Valid() }

// TransitionRef is the shared semantic transition identity. Target is an
// owner-defined epoch/target-state token, not a universal phase enum.
type TransitionRef struct {
	generation GenerationRef
	kind       string
	target     string
}

func NewTransitionRef(g GenerationRef, kind, target string) (TransitionRef, error) {
	kind = strings.TrimSpace(kind)
	target = strings.TrimSpace(target)
	if !g.Valid() || kind == "" || target == "" {
		return TransitionRef{}, ErrInvalidReference
	}
	return TransitionRef{generation: g, kind: kind, target: target}, nil
}

func (r TransitionRef) Generation() GenerationRef { return r.generation }
func (r TransitionRef) Kind() string              { return r.kind }
func (r TransitionRef) Target() string            { return r.target }
func (r TransitionRef) Valid() bool {
	return r.generation.Valid() && r.kind != "" && r.target != ""
}
