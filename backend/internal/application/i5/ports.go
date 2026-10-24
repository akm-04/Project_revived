// Package i5 implements Wave-E transactional orchestration. Domain packages own
// state rules; this package owns composition, semantic replay and transaction
// boundaries. Mechanism-specific PostgreSQL code lives under adapters.
package i5

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/redeem"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type TemporalDescriptor struct {
	Revision                          string
	ResourceKey                       string
	RegenEvery                        time.Duration
	RegenAmount                       int64
	CapRule                           string
	StaticCap                         int64
	AllowExplicitGrantAboveNaturalCap bool
}

func (d TemporalDescriptor) FixedPolicy(cap int64) economy.TemporalPolicy {
	return economy.TemporalPolicy{Version: d.Revision, RegenEvery: d.RegenEvery, RegenAmount: d.RegenAmount, NaturalCap: cap, AllowExplicitGrantAboveNaturalCap: d.AllowExplicitGrantAboveNaturalCap}
}

type ResourcePolicy struct {
	Kind          grant.LineKind
	WireTableID   int64
	Stack         *economy.StackDefinition
	Temporal      *economy.TemporalPolicy // legacy exact-version rows only
	Descriptor    *TemporalDescriptor     // immutable R5 temporal rows
	PolicyVersion string
}

type FunctionGate struct {
	FunctionID             int64
	GateKind               string
	RequiredLevel          int64
	RawOpenValue           string
	SourceFactKey          string
	AnnouncementCapability string
}

type FunctionGatePolicy struct {
	Revision string
	Gates    []FunctionGate
}

type PetStarterPolicy struct {
	StarterEggItemID int64
}

// ContentRuntime is the typed R4D/R5 consumption seam into content-registry-owned
// immutable revisions. ActiveRevision is consulted only at owning-command
// admission; every semantic read after binding is exact-revision.
type ContentRuntime interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	ResolveResourceTx(context.Context, tx.Queryer, string, grant.Line) (ResourcePolicy, error)
	ResolveProgressionPolicyTx(context.Context, tx.Queryer, string) (player.ProgressionPolicy, error)
	ResolveFunctionGatePolicyTx(context.Context, tx.Queryer, string) (FunctionGatePolicy, error)
	ResolvePetStarterPolicyTx(context.Context, tx.Queryer, string) (PetStarterPolicy, error)
	ResolveObjective(context.Context, string, string, int64, string) (ObjectiveDefinition, error)
	ResolveObjectiveTx(context.Context, tx.Queryer, string, string, int64, string) (ObjectiveDefinition, error)
}

type PrivilegeSnapshot struct {
	ProviderRevision       string
	VIPLevel               int64
	MonthlyPrivilegeActive bool
	SkillPointNaturalCap   int64
}

type PrivilegeSnapshotProvider interface {
	SnapshotTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (PrivilegeSnapshot, error)
}

// Announce receives newly inserted eligibility facts for this transition.
// Existing eligibility is durable and is not a new announcement on a later grant.
type FunctionAnnouncementProvider interface {
	ProviderRevision() string
	Announce(context.Context, identity.PlayerID, FunctionGatePolicy, []player.FunctionEligibility) ([]int64, error)
}

// BackpackReader is the read-only owner seam used by R6 stock inventory projection.
// It exposes canonical ordinary stacks only; Spirit-equipment ownership remains deferred.
type BackpackReader interface {
	ListStacks(context.Context, identity.PlayerID) ([]economy.StackState, error)
}

type DirectoryLevelProjection struct {
	Level        int64
	StateVersion int64
}

type DirectoryLevelProjectionPort interface {
	LockTx(context.Context, tx.Tx, identity.PlayerID) (DirectoryLevelProjection, error)
	SetLevelTx(context.Context, tx.Tx, identity.PlayerID, int64, int64, operation.Context) error
}

// ObjectiveDefinition joins the pure reducer definition with stock family and
// immutable reward-plan content. Generation ownership remains I6.
type ObjectiveDefinition struct {
	Family       objective.StockFamily
	Definition   objective.Definition
	GenerationID string
	Reward       grant.Plan
	Huoyue       int64
}

type RedeemCode struct {
	CodeID         string
	CampaignID     string
	CodeKind       string
	GlobalUseLimit *int64
	UseCount       int64
	Status         string
	StateVersion   int64
}

type RedeemCampaign struct {
	CampaignID             string
	Campaign               redeem.Campaign
	RewardBundleRevisionID string
	TotalCap               *int64
	PerSubjectCap          int64
}

type Redemption struct {
	RedemptionID           string
	CodeID                 string
	SubjectType            string
	SubjectID              string
	Slot                   int64
	PlayerID               identity.PlayerID
	AccountID              identity.AccountID
	LogicalServerID        identity.LogicalServerID
	RewardBundleRevisionID string
	GrantReceiptID         string
	RedeemedAt             time.Time
	Platform               string
	PolicyVersion          string
}

// TxGrantSettler is the narrow cross-domain composition seam for entitlement
// settlement inside a caller-owned transaction. Later domains depend on this
// interface rather than the concrete I5 Service or I5 storage tables.
type TxGrantSettler interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, GrantTxOptions) (GrantResult, error)
}

// Store is deliberately owner-shaped. It exposes no generic table mutation and
// all write methods require the caller's Wave-A transaction.
type Store interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error

	LockStoryTx(context.Context, tx.Tx, identity.PlayerID) (player.StoryCursor, error)
	SaveStoryTx(context.Context, tx.Tx, player.StoryCursor, int64) error
	ClearFirstEntryPendingTx(context.Context, tx.Tx, identity.PlayerID) error

	ReadScalarTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.ScalarBalance, bool, error)
	ReadTemporalTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.TemporalState, bool, error)
	ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error)
	ResolveLegacyTemporalPolicyTx(context.Context, tx.Queryer, string, string) (ResourcePolicy, error)
	LockEconomyOwnerTx(context.Context, tx.Tx, identity.PlayerID) error
	LockMailNamespaceCounterTx(context.Context, tx.Tx, identity.PlayerID, mail.Namespace) error
	LockScalarTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time) (economy.ScalarBalance, bool, error)
	SaveScalarTx(context.Context, tx.Tx, economy.ScalarBalance, bool) error
	LockTemporalTx(context.Context, tx.Tx, identity.PlayerID, string) (economy.TemporalState, bool, error)
	SaveTemporalTx(context.Context, tx.Tx, economy.TemporalState) error
	RebindTemporalTx(context.Context, tx.Tx, economy.TemporalState, int64) error
	LockStackTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time) (economy.StackState, bool, error)
	SaveStackTx(context.Context, tx.Tx, economy.StackState, bool) error
	DeleteStackTx(context.Context, tx.Tx, economy.StackState) error
	LockProgressionTx(context.Context, tx.Tx, identity.PlayerID) (player.Progression, error)
	SaveProgressionTx(context.Context, tx.Tx, player.Progression, int64) error
	LockFunctionStateTx(context.Context, tx.Tx, identity.PlayerID) (int64, error)
	InsertFunctionEligibilityTx(context.Context, tx.Tx, player.FunctionEligibility) (bool, error)
	InsertFunctionUnlockTx(context.Context, tx.Tx, player.FunctionUnlock) (bool, error)
	AdvanceFunctionStateTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time) error

	AllocateMailWireIDTx(context.Context, tx.Tx, identity.PlayerID, mail.Namespace) (int64, error)
	InsertMailTx(context.Context, tx.Tx, mail.Record) error
	ListMail(context.Context, identity.PlayerID, time.Time, int) ([]mail.Record, int64, int64, error)
	ListMailTx(context.Context, tx.Queryer, identity.PlayerID, time.Time, int) ([]mail.Record, int64, int64, error)
	LockMailTx(context.Context, tx.Tx, identity.PlayerID, mail.Address) (mail.Record, error)
	SaveMailStateTx(context.Context, tx.Tx, mail.Record, int64) error

	ListObjectives(context.Context, identity.PlayerID, objective.StockFamily, time.Time) ([]objective.Instance, []ObjectiveDefinition, error)
	LockObjectiveTx(context.Context, tx.Tx, identity.PlayerID, objective.StockFamily, int64, string) (objective.Instance, ObjectiveDefinition, error)
	LockObjectiveForClaimTx(context.Context, tx.Tx, identity.PlayerID, int64, string) (objective.Instance, ObjectiveDefinition, error)
	SaveObjectiveTx(context.Context, tx.Tx, objective.Instance, int64) error

	LockRedeemByDigestTx(context.Context, tx.Tx, [32]byte) (RedeemCode, RedeemCampaign, grant.Plan, error)
	FindRedemptionTx(context.Context, tx.Tx, string, string, string, int64) (Redemption, bool, error)
	CountCampaignRedemptionsTx(context.Context, tx.Tx, string) (int64, error)
	AdvanceRedeemCodeTx(context.Context, tx.Tx, RedeemCode) error
	InsertRedemptionTx(context.Context, tx.Tx, Redemption) error
}
