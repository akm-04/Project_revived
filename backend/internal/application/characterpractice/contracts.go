package characterpractice

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	ContentCapability   = "PRACTICE_CA6"
	DailyEpochPolicyV1  = "ALCHEMY_DAILY_EPOCH_V1"
	DailyEpochPolicyRef = "practice.daily_epoch"
)

var (
	ErrRootMissing       = errors.New("character practice: root missing")
	ErrStaleVersion      = errors.New("character practice: stale root version")
	ErrCandidateMissing  = errors.New("character practice: pending proposal missing")
	ErrContentInactive   = errors.New("character practice: immutable content capability inactive")
	ErrActorMissing      = errors.New("character practice: actor missing")
	ErrActorStaleVersion = errors.New("character practice: stale actor version")
)

type Root struct {
	PlayerID                       identity.PlayerID
	FreeLastConsumedAt             *time.Time
	DailyEpochStartAt              *time.Time
	DailyEpochPolicyVersion        string
	BlessRemaining                 int64
	BlessCapacityAtEpoch           int64
	BlessVIPLevelAtEpoch           *int64
	BlessPrivilegeProviderRevision string
	BlessContentRevision           string
	BaseMana                       int64
	BaseCrystal                    int64
	StateVersion                   int64
	CreatedAt                      time.Time
	UpdatedAt                      time.Time
}

func (r Root) Validate() error {
	if !r.PlayerID.Valid() || r.BlessRemaining < 0 || r.BlessCapacityAtEpoch < 0 || r.BlessRemaining > r.BlessCapacityAtEpoch || r.BaseMana < 0 || r.BaseCrystal < 0 || r.StateVersion <= 0 || r.CreatedAt.IsZero() || r.UpdatedAt.IsZero() {
		return errors.New("character practice: invalid root")
	}
	provenanceFields := 0
	if r.DailyEpochStartAt != nil {
		provenanceFields++
	}
	if r.DailyEpochPolicyVersion != "" {
		provenanceFields++
	}
	if r.BlessVIPLevelAtEpoch != nil {
		provenanceFields++
	}
	if r.BlessPrivilegeProviderRevision != "" {
		provenanceFields++
	}
	if r.BlessContentRevision != "" {
		provenanceFields++
	}
	if provenanceFields != 0 && provenanceFields != 5 {
		return errors.New("character practice: incomplete daily-generation provenance")
	}
	if r.FreeLastConsumedAt != nil && r.FreeLastConsumedAt.IsZero() {
		return errors.New("character practice: invalid free timestamp")
	}
	if r.DailyEpochStartAt != nil && r.DailyEpochStartAt.IsZero() {
		return errors.New("character practice: invalid epoch timestamp")
	}
	return nil
}

type PendingKind string

const (
	PendingManual PendingKind = "MANUAL"
	PendingTicket PendingKind = "TICKET"
)

func (k PendingKind) Valid() bool { return k == PendingManual || k == PendingTicket }

type Proposal struct {
	PlayerID                  identity.PlayerID
	SessionID                 identity.SessionID
	ActorID                   int64
	ActorStateVersion         int64
	Proposed                  character.PracticeAttrs
	GenerationOperationID     ids.UUID
	GenerationContextID       identity.ContextID
	GenerationKind            PendingKind
	GenerationContentRevision string
	GenerationPolicyRefs      policy.Set
	CreatedAt                 time.Time
	UpdatedAt                 time.Time
}

func (p Proposal) Validate() error {
	if !p.PlayerID.Valid() || p.SessionID.UUID().IsZero() || p.ActorID <= 0 || p.ActorStateVersion <= 0 || p.Proposed.Validate() != nil || p.GenerationOperationID.IsZero() || p.GenerationContextID.UUID().IsZero() || !p.GenerationKind.Valid() || len(p.GenerationContentRevision) != 64 || p.CreatedAt.IsZero() || p.UpdatedAt.IsZero() {
		return errors.New("character practice: invalid pending proposal")
	}
	if _, err := policy.MarshalCanonicalJSON(p.GenerationPolicyRefs); err != nil {
		return err
	}
	return nil
}

type Store interface {
	ReadPracticeRootTx(context.Context, tx.Queryer, identity.PlayerID) (Root, error)
	LockPracticeRootTx(context.Context, tx.Tx, identity.PlayerID) (Root, error)
	SaveGenerationTx(context.Context, tx.Tx, Root, int64) error
	SaveAccountingTx(context.Context, tx.Tx, Root, int64) error
	EnsureRootTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (bool, error)
	ReadHeroProposalTx(context.Context, tx.Queryer, identity.PlayerID, identity.SessionID, int64) (Proposal, error)
	LockHeroProposalTx(context.Context, tx.Tx, identity.PlayerID, identity.SessionID, int64) (Proposal, error)
	UpsertHeroProposalTx(context.Context, tx.Tx, Proposal) error
	DeleteHeroProposalTx(context.Context, tx.Tx, identity.PlayerID, identity.SessionID, int64) error
	ReadPetProposalTx(context.Context, tx.Queryer, identity.PlayerID, identity.SessionID, int64) (Proposal, error)
	LockPetProposalTx(context.Context, tx.Tx, identity.PlayerID, identity.SessionID, int64) (Proposal, error)
	UpsertPetProposalTx(context.Context, tx.Tx, Proposal) error
	DeletePetProposalTx(context.Context, tx.Tx, identity.PlayerID, identity.SessionID, int64) error
}

// HeroPracticeSnapshot is the immutable owner-qualified Hero view Practice may
// retain after acquiring Hero410. It deliberately excludes unrelated mutable
// Hero state so CA6 cannot become a parallel CharacterHero owner.
type HeroPracticeSnapshot struct {
	Ref          character.HeroRef
	TableID      int64
	Practice     character.PracticeAttrs
	StateVersion int64
}

func (s HeroPracticeSnapshot) Validate() error {
	if s.Ref.Validate() != nil || s.TableID <= 0 || s.Practice.Validate() != nil || s.StateVersion <= 0 {
		return errors.New("character practice: invalid Hero owner snapshot")
	}
	return nil
}

// PetPracticeSnapshot is the Pet430 equivalent of HeroPracticeSnapshot.
type PetPracticeSnapshot struct {
	Ref          character.PetRef
	TableID      int64
	Practice     character.PracticeAttrs
	StateVersion int64
}

func (s PetPracticeSnapshot) Validate() error {
	if s.Ref.Validate() != nil || s.TableID <= 0 || s.Practice.Validate() != nil || s.StateVersion <= 0 {
		return errors.New("character practice: invalid Pet owner snapshot")
	}
	return nil
}

// HeroPracticeOwner is the narrow CharacterHero-owned CA6 seam. The CAS writes
// only the absolute Practice tuple and advances the Hero aggregate version.
// Callers never receive or mutate the wider Hero record through this port.
type HeroPracticeOwner interface {
	LockHeroPracticeTx(context.Context, tx.Tx, character.HeroRef) (HeroPracticeSnapshot, error)
	CompareAndSwapHeroPracticeTx(context.Context, tx.Tx, character.HeroRef, int64, character.PracticeAttrs, time.Time) error
}

// PetPracticeOwner is the narrow CharacterPet-owned CA6 seam.
type PetPracticeOwner interface {
	LockPetPracticeTx(context.Context, tx.Tx, character.PetRef) (PetPracticeSnapshot, error)
	CompareAndSwapPetPracticeTx(context.Context, tx.Tx, character.PetRef, int64, character.PracticeAttrs, time.Time) error
}

type Method struct{ ID, CurrencyType, BaseCost, VIPMin int64 }
type LockCost struct{ Count, ManaStep, CrystalStep, BlessCost, SourceUpLimit int64 }
type Threshold struct{ Ordinal, NeedValue, TargetAttrType, BonusValue int64 }
type PolicyFacts struct {
	UnlockLevel, AttrCap, FreeIntervalSeconds, LegendaryVIPMin, TicketItemID int64
	TicketAdd                                                                character.PracticeAttrs
}

func (p PolicyFacts) Validate() error {
	if p.UnlockLevel <= 0 || p.AttrCap != character.MaxPracticeAttr || p.FreeIntervalSeconds <= 0 || p.LegendaryVIPMin < 0 || p.TicketItemID <= 0 || p.TicketAdd.Validate() != nil {
		return errors.New("character practice: invalid policy facts")
	}
	return nil
}

type Content interface {
	PracticeActive(context.Context) (string, bool, error)
	PracticeRevision(context.Context, string) (bool, error)
	PracticeMethodTx(context.Context, tx.Queryer, string, int64) (Method, error)
	PracticeLockTx(context.Context, tx.Queryer, string, int64) (LockCost, error)
	PracticeVIPBlessTx(context.Context, tx.Queryer, string, int64) (int64, error)
	PracticePolicyFactsTx(context.Context, tx.Queryer, string) (PolicyFacts, error)
	HeroPracticeThresholdsTx(context.Context, tx.Queryer, string, int64) ([]Threshold, error)
	PetPracticeThresholdsTx(context.Context, tx.Queryer, string, int64) ([]Threshold, error)
	HeroTemplateAwakenedTx(context.Context, tx.Queryer, string, int64) (bool, error)
	PetTemplateAwakenedTx(context.Context, tx.Queryer, string, int64) (bool, error)
}
