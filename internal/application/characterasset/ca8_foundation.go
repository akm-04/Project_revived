package characterasset

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrInvalidCoherentReadScope  = errors.New("character asset: invalid coherent read scope")
	ErrInsufficientReadIsolation = errors.New("character asset: coherent read requires repeatable-read or serializable isolation")
)

// ActorOrigin is provenance, not ownership authority. The four values are kept
// distinct because owned/borrowed persistent actors and operation-scoped
// synthetic actors have materially different identity and recovery semantics.
type ActorOrigin string

const (
	ActorOriginOwned       ActorOrigin = "OWNED"
	ActorOriginBorrowed    ActorOrigin = "BORROWED"
	ActorOriginTrial       ActorOrigin = "TRIAL"
	ActorOriginNPCTemplate ActorOrigin = "NPC_TEMPLATE"
)

func (o ActorOrigin) Validate() error {
	switch o {
	case ActorOriginOwned, ActorOriginBorrowed, ActorOriginTrial, ActorOriginNPCTemplate:
		return nil
	default:
		return errors.New("character asset: invalid actor origin")
	}
}

// ProviderDisposition records local CA8 materialization readiness. It does not
// replace I6/content capability authority and carries no activation power.
type ProviderDisposition string

const (
	ProviderQualifiedActive            ProviderDisposition = "QUALIFIED_ACTIVE"
	ProviderExplicitlyInactiveOrAbsent ProviderDisposition = "EXPLICITLY_INACTIVE_OR_LEGITIMATELY_ABSENT"
	ProviderUnavailableUnqualified     ProviderDisposition = "UNAVAILABLE_UNQUALIFIED"
	ProviderRequiredButUnavailable     ProviderDisposition = "REQUIRED_BUT_UNAVAILABLE"
)

func (d ProviderDisposition) Validate() error {
	switch d {
	case ProviderQualifiedActive, ProviderExplicitlyInactiveOrAbsent, ProviderUnavailableUnqualified, ProviderRequiredButUnavailable:
		return nil
	default:
		return errors.New("character asset: invalid provider disposition")
	}
}

func (d ProviderDisposition) Available() bool { return d == ProviderQualifiedActive }
func (d ProviderDisposition) Unavailable() bool {
	return d == ProviderUnavailableUnqualified || d == ProviderRequiredButUnavailable
}

func (d ProviderDisposition) BlocksConsumer() bool { return d == ProviderRequiredButUnavailable }

// CoherentReadScope is the CA8 read-only capability handed to observation
// providers. The underlying transaction remains caller-owned. The options are
// witnessed by tx.Runner itself, allowing CA8 to reject ReadCommitted without
// opening a nested transaction or trusting an arbitrary Queryer assertion.
type CoherentReadScope struct {
	queryer             tx.Queryer
	Operation           operation.Context
	Attempt             int
	Isolation           tx.Isolation
	TransactionReadOnly bool
	ContentRevision     string
	ObservedAt          time.Time
}

func NewCoherentReadScope(scope tx.Scope, revision string, observedAt time.Time) (CoherentReadScope, error) {
	out := CoherentReadScope{
		queryer: scope.Tx, Operation: scope.Operation, Attempt: scope.Attempt,
		Isolation: scope.Options.Isolation, TransactionReadOnly: scope.Options.ReadOnly,
		ContentRevision: revision, ObservedAt: observedAt.UTC(),
	}
	if err := out.Validate(); err != nil {
		return CoherentReadScope{}, err
	}
	return out, nil
}

func (s CoherentReadScope) Validate() error {
	if s.queryer == nil || s.Operation.ID.IsZero() || s.Operation.StartedAt.IsZero() || s.Attempt <= 0 || s.ObservedAt.IsZero() || ValidateExactRevisionID(s.ContentRevision) != nil {
		return ErrInvalidCoherentReadScope
	}
	if s.Isolation != tx.RepeatableRead && s.Isolation != tx.Serializable {
		return ErrInsufficientReadIsolation
	}
	return nil
}

func (s CoherentReadScope) Queryer() tx.Queryer { return s.queryer }

// HeroBaseObservation is the narrow immutable CA2-owned actor state needed by
// later CA8 composition. Equipment/Fumo, Practice and appearance are excluded
// because CA4/CA6/CA7 expose their own qualified contribution contracts.
type HeroBaseObservation struct {
	Ref                     character.HeroRef
	TableID                 int64
	OriginTableID           int64
	Kind                    character.HeroKind
	Star                    int64
	Level                   int64
	Exp                     int64
	Color                   int64
	CreationContentRevision string
	StateVersion            int64
}

func (o HeroBaseObservation) Validate() error {
	if o.Ref.Validate() != nil || o.TableID <= 0 || o.OriginTableID <= 0 || (o.Kind != character.NormalHero && o.Kind != character.SuperHero) || o.Star < 1 || o.Star > character.MaxHeroStar || o.Level < 1 || o.Exp < 0 || o.Color < 1 || o.Color > 16 || ValidateExactRevisionID(o.CreationContentRevision) != nil || o.StateVersion <= 0 {
		return errors.New("character asset: invalid Hero base observation")
	}
	return nil
}

// PetBaseObservation retains Birthday/IsShow because CA3 made them canonical
// Pet-core lifecycle/reload facts and current client behavior uses them for
// incubation/born/participation decisions. CA4/CA6/CA7 state is excluded.
type PetBaseObservation struct {
	Ref                     character.PetRef
	TableID                 int64
	OriginTableID           int64
	Star                    int64
	Level                   int64
	Exp                     int64
	Color                   int64
	Skills                  character.PetSkillLevels
	Birthday                int64
	IsShow                  bool
	CreationContentRevision string
	StateVersion            int64
}

func (o PetBaseObservation) Validate() error {
	if o.Ref.Validate() != nil || o.TableID <= 0 || o.OriginTableID <= 0 || o.Star < 1 || o.Star > character.MaxPetStar || o.Level < 1 || o.Exp < 0 || o.Color < 1 || o.Color > 16 || o.Skills.Validate() != nil || o.Birthday < 0 || ValidateExactRevisionID(o.CreationContentRevision) != nil || o.StateVersion <= 0 {
		return errors.New("character asset: invalid Pet base observation")
	}
	return nil
}

// Base observation providers deliberately receive the caller's Queryer. They
// may not discover ActiveRevision, open a transaction, or mutate owner state.
type HeroBaseObservationProvider interface {
	HeroBaseObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64) (HeroBaseObservation, error)
}

type PetBaseObservationProvider interface {
	PetBaseObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64) (PetBaseObservation, error)
}
