package characterasset

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/ids"
)

const maxSyntheticLocalKeyBytes = 256

var (
	ErrInvalidSyntheticIdentity   = errors.New("character asset: invalid synthetic actor identity")
	ErrInvalidSyntheticProvenance = errors.New("character asset: invalid synthetic profile provenance")
	ErrSyntheticScopeMismatch     = errors.New("character asset: synthetic profile scope mismatch")
	ErrInvalidSyntheticHeroBase   = errors.New("character asset: invalid synthetic Hero base")
	ErrInvalidSyntheticPetBase    = errors.New("character asset: invalid synthetic Pet base")
	ErrInvalidSyntheticPayload    = errors.New("character asset: invalid synthetic feature payload")
	ErrInvalidSyntheticLineage    = errors.New("character asset: invalid synthetic source lineage")
)

// SyntheticActorIdentity is operation-scoped Character identity for actors
// that have no durable Character owner. LocalKey is opaque caller-qualified
// data: CA8-5 preserves it byte-for-byte and never derives it from TableID,
// owner identity, or stock-client runtime IDs.
type SyntheticActorIdentity struct {
	Origin      ActorOrigin
	OperationID ids.UUID
	LocalKey    string
}

func (i SyntheticActorIdentity) Validate() error {
	if (i.Origin != ActorOriginTrial && i.Origin != ActorOriginNPCTemplate) || i.OperationID.IsZero() {
		return ErrInvalidSyntheticIdentity
	}
	if strings.TrimSpace(i.LocalKey) == "" || len(i.LocalKey) > maxSyntheticLocalKeyBytes {
		return ErrInvalidSyntheticIdentity
	}
	return nil
}

// SyntheticProfileProvenance is opaque qualification evidence from the
// feature/content owner. CA8-5 validates that the qualification is bound to the
// exact caller operation/content/time scope but does not interpret provider or
// profile revision semantics.
type SyntheticProfileProvenance struct {
	ProviderID           string
	ProfileID            string
	ProfileRevision      string
	ContentRevision      string
	QualifiedOperationID ids.UUID
	QualifiedAt          time.Time
}

func (p SyntheticProfileProvenance) Validate() error {
	for _, v := range []string{p.ProviderID, p.ProfileID, p.ProfileRevision} {
		if strings.TrimSpace(v) == "" {
			return ErrInvalidSyntheticProvenance
		}
	}
	if ValidateExactRevisionID(p.ContentRevision) != nil || p.QualifiedOperationID.IsZero() || p.QualifiedAt.IsZero() || p.QualifiedAt.Location() != time.UTC {
		return ErrInvalidSyntheticProvenance
	}
	return nil
}

func (p SyntheticProfileProvenance) validateScope(scope CoherentReadScope) error {
	if err := p.Validate(); err != nil {
		return err
	}
	if p.ContentRevision != scope.ContentRevision || p.QualifiedOperationID != scope.Operation.ID || !p.QualifiedAt.Equal(scope.ObservedAt) {
		return ErrSyntheticScopeMismatch
	}
	return nil
}

// SyntheticHeroBase contains already-qualified Character base facts. It has no
// owner reference, durable StateVersion, equipment/practice owner state, or
// final battle-stat authority.
type SyntheticHeroBase struct {
	TableID       int64
	OriginTableID int64
	Kind          character.HeroKind
	Star          int64
	Level         int64
	Exp           int64
	Color         int64
}

func (b SyntheticHeroBase) Validate() error {
	if b.TableID <= 0 || b.OriginTableID <= 0 || (b.Kind != character.NormalHero && b.Kind != character.SuperHero) || b.Star < 1 || b.Star > character.MaxHeroStar || b.Level < 1 || b.Exp < 0 || b.Color < 1 || b.Color > 16 {
		return ErrInvalidSyntheticHeroBase
	}
	return nil
}

// SyntheticPetBase is the Pet counterpart. A zero Skills value means the
// qualified profile has no typed Pet base-skill contribution; otherwise every
// level must satisfy the accepted Pet raw-skill contract.
type SyntheticPetBase struct {
	TableID       int64
	OriginTableID int64
	Star          int64
	Level         int64
	Exp           int64
	Color         int64
	Skills        character.PetSkillLevels
}

func (b SyntheticPetBase) Validate() error {
	if b.TableID <= 0 || b.OriginTableID <= 0 || b.Star < 1 || b.Star > character.MaxPetStar || b.Level < 1 || b.Exp < 0 || b.Color < 1 || b.Color > 16 {
		return ErrInvalidSyntheticPetBase
	}
	if b.Skills != (character.PetSkillLevels{}) {
		if err := b.Skills.Validate(); err != nil {
			return ErrInvalidSyntheticPetBase
		}
	}
	return nil
}

// SyntheticFeaturePayload is a feature-owned, schema-qualified in-memory
// Character contribution envelope. CA8-5 clones these canonical bytes and does
// not interpret them as a universal formula, durable record, stock wire shape,
// or final combat-stat blob.
type SyntheticFeaturePayload struct {
	SchemaID       string
	SchemaRevision string
	Bytes          []byte
}

func (p SyntheticFeaturePayload) Validate() error {
	if strings.TrimSpace(p.SchemaID) == "" || strings.TrimSpace(p.SchemaRevision) == "" || len(p.Bytes) == 0 {
		return ErrInvalidSyntheticPayload
	}
	return nil
}

func cloneSyntheticFeaturePayload(p *SyntheticFeaturePayload) *SyntheticFeaturePayload {
	if p == nil {
		return nil
	}
	out := *p
	out.Bytes = append([]byte(nil), p.Bytes...)
	return &out
}

// SyntheticHeroSourceLineage is provenance only. Exactly one lineage shape is
// valid: an exact owned source reference + StateVersion, or a template-only
// source. CA8-5 never dereferences either form.
type SyntheticHeroSourceLineage struct {
	OwnedRef     *character.HeroRef
	StateVersion int64
	TemplateID   int64
}

func (l SyntheticHeroSourceLineage) Validate() error {
	if l.OwnedRef != nil {
		if l.OwnedRef.Validate() != nil || l.StateVersion <= 0 || l.TemplateID != 0 {
			return ErrInvalidSyntheticLineage
		}
		return nil
	}
	if l.StateVersion != 0 || l.TemplateID <= 0 {
		return ErrInvalidSyntheticLineage
	}
	return nil
}

func cloneSyntheticHeroLineage(l *SyntheticHeroSourceLineage) *SyntheticHeroSourceLineage {
	if l == nil {
		return nil
	}
	out := *l
	if l.OwnedRef != nil {
		ref := *l.OwnedRef
		out.OwnedRef = &ref
	}
	return &out
}

// SyntheticPetSourceLineage is the Pet counterpart of
// SyntheticHeroSourceLineage.
type SyntheticPetSourceLineage struct {
	OwnedRef     *character.PetRef
	StateVersion int64
	TemplateID   int64
}

func (l SyntheticPetSourceLineage) Validate() error {
	if l.OwnedRef != nil {
		if l.OwnedRef.Validate() != nil || l.StateVersion <= 0 || l.TemplateID != 0 {
			return ErrInvalidSyntheticLineage
		}
		return nil
	}
	if l.StateVersion != 0 || l.TemplateID <= 0 {
		return ErrInvalidSyntheticLineage
	}
	return nil
}

func cloneSyntheticPetLineage(l *SyntheticPetSourceLineage) *SyntheticPetSourceLineage {
	if l == nil {
		return nil
	}
	out := *l
	if l.OwnedRef != nil {
		ref := *l.OwnedRef
		out.OwnedRef = &ref
	}
	return &out
}

// QualifiedSyntheticHeroSpec is the complete Character-side profile already
// qualified by the owning feature/content domain. Origin and LocalKey are
// bound to the caller operation by MaterializeSyntheticHero.
type QualifiedSyntheticHeroSpec struct {
	Origin         ActorOrigin
	LocalKey       string
	Provenance     SyntheticProfileProvenance
	Base           SyntheticHeroBase
	FeaturePayload *SyntheticFeaturePayload
	SourceLineage  *SyntheticHeroSourceLineage
}

// QualifiedSyntheticPetSpec is the Pet counterpart.
type QualifiedSyntheticPetSpec struct {
	Origin         ActorOrigin
	LocalKey       string
	Provenance     SyntheticProfileProvenance
	Base           SyntheticPetBase
	FeaturePayload *SyntheticFeaturePayload
	SourceLineage  *SyntheticPetSourceLineage
}

// SyntheticHeroProjection is an immutable-by-copy operation-scoped Character
// projection. It is not a durable Hero instance and carries no owner authority.
type SyntheticHeroProjection struct {
	Identity       SyntheticActorIdentity
	Provenance     SyntheticProfileProvenance
	Base           SyntheticHeroBase
	FeaturePayload *SyntheticFeaturePayload
	SourceLineage  *SyntheticHeroSourceLineage
}

func (p SyntheticHeroProjection) Validate() error {
	if err := p.Identity.Validate(); err != nil {
		return err
	}
	if err := p.Provenance.Validate(); err != nil {
		return err
	}
	if p.Identity.OperationID != p.Provenance.QualifiedOperationID {
		return ErrSyntheticScopeMismatch
	}
	if err := p.Base.Validate(); err != nil {
		return err
	}
	if p.FeaturePayload != nil {
		if err := p.FeaturePayload.Validate(); err != nil {
			return err
		}
	}
	if p.SourceLineage != nil {
		if err := p.SourceLineage.Validate(); err != nil {
			return err
		}
	}
	return nil
}

// SyntheticPetProjection is the Pet counterpart.
type SyntheticPetProjection struct {
	Identity       SyntheticActorIdentity
	Provenance     SyntheticProfileProvenance
	Base           SyntheticPetBase
	FeaturePayload *SyntheticFeaturePayload
	SourceLineage  *SyntheticPetSourceLineage
}

func (p SyntheticPetProjection) Validate() error {
	if err := p.Identity.Validate(); err != nil {
		return err
	}
	if err := p.Provenance.Validate(); err != nil {
		return err
	}
	if p.Identity.OperationID != p.Provenance.QualifiedOperationID {
		return ErrSyntheticScopeMismatch
	}
	if err := p.Base.Validate(); err != nil {
		return err
	}
	if p.FeaturePayload != nil {
		if err := p.FeaturePayload.Validate(); err != nil {
			return err
		}
	}
	if p.SourceLineage != nil {
		if err := p.SourceLineage.Validate(); err != nil {
			return err
		}
	}
	return nil
}

func validateSyntheticOriginAndKey(origin ActorOrigin, localKey string, operationID ids.UUID) (SyntheticActorIdentity, error) {
	identity := SyntheticActorIdentity{Origin: origin, OperationID: operationID, LocalKey: localKey}
	if err := identity.Validate(); err != nil {
		return SyntheticActorIdentity{}, err
	}
	return identity, nil
}

// MaterializeSyntheticHero freezes one already-qualified synthetic Hero profile
// under the caller-owned coherent scope. It performs no live owner/content
// lookup and has no persistence, transaction, receipt, or battle-stat side
// effects.
func MaterializeSyntheticHero(scope CoherentReadScope, spec QualifiedSyntheticHeroSpec) (SyntheticHeroProjection, error) {
	if err := scope.Validate(); err != nil {
		return SyntheticHeroProjection{}, err
	}
	identity, err := validateSyntheticOriginAndKey(spec.Origin, spec.LocalKey, scope.Operation.ID)
	if err != nil {
		return SyntheticHeroProjection{}, err
	}
	if err := spec.Provenance.validateScope(scope); err != nil {
		return SyntheticHeroProjection{}, err
	}
	if err := spec.Base.Validate(); err != nil {
		return SyntheticHeroProjection{}, err
	}
	if spec.FeaturePayload != nil {
		if err := spec.FeaturePayload.Validate(); err != nil {
			return SyntheticHeroProjection{}, err
		}
	}
	if spec.SourceLineage != nil {
		if err := spec.SourceLineage.Validate(); err != nil {
			return SyntheticHeroProjection{}, err
		}
	}
	out := SyntheticHeroProjection{
		Identity:       identity,
		Provenance:     spec.Provenance,
		Base:           spec.Base,
		FeaturePayload: cloneSyntheticFeaturePayload(spec.FeaturePayload),
		SourceLineage:  cloneSyntheticHeroLineage(spec.SourceLineage),
	}
	if err := out.Validate(); err != nil {
		return SyntheticHeroProjection{}, fmt.Errorf("character asset: materialized synthetic Hero invalid: %w", err)
	}
	return out, nil
}

// MaterializeSyntheticPet freezes one already-qualified synthetic Pet profile
// under the caller-owned coherent scope.
func MaterializeSyntheticPet(scope CoherentReadScope, spec QualifiedSyntheticPetSpec) (SyntheticPetProjection, error) {
	if err := scope.Validate(); err != nil {
		return SyntheticPetProjection{}, err
	}
	identity, err := validateSyntheticOriginAndKey(spec.Origin, spec.LocalKey, scope.Operation.ID)
	if err != nil {
		return SyntheticPetProjection{}, err
	}
	if err := spec.Provenance.validateScope(scope); err != nil {
		return SyntheticPetProjection{}, err
	}
	if err := spec.Base.Validate(); err != nil {
		return SyntheticPetProjection{}, err
	}
	if spec.FeaturePayload != nil {
		if err := spec.FeaturePayload.Validate(); err != nil {
			return SyntheticPetProjection{}, err
		}
	}
	if spec.SourceLineage != nil {
		if err := spec.SourceLineage.Validate(); err != nil {
			return SyntheticPetProjection{}, err
		}
	}
	out := SyntheticPetProjection{
		Identity:       identity,
		Provenance:     spec.Provenance,
		Base:           spec.Base,
		FeaturePayload: cloneSyntheticFeaturePayload(spec.FeaturePayload),
		SourceLineage:  cloneSyntheticPetLineage(spec.SourceLineage),
	}
	if err := out.Validate(); err != nil {
		return SyntheticPetProjection{}, fmt.Errorf("character asset: materialized synthetic Pet invalid: %w", err)
	}
	return out, nil
}
