package godstrial

import (
	"context"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/godstrial"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store interface {
	ReadTx(context.Context, tx.Queryer, identity.PlayerID) (d.State, bool, error)
	LockTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (d.State, error)
	SaveTx(context.Context, tx.Tx, identity.PlayerID, d.State, time.Time) error
}
type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	GodsTrialCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}
type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type Functions interface {
	ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error)
}
type Heroes interface {
	LockStoryRosterTx(context.Context, tx.Tx, identity.PlayerID) error
}
type HeroLocks interface {
	LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error)
}
type Pets interface {
	LockCampaignPetTx(context.Context, tx.Tx, identity.PlayerID, int64) error
}
type Combat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, cb.StartRequest) (cb.Started, error)
	AttestSummaryTx(context.Context, tx.Tx, cb.SummaryRequest) (cb.SummaryAttested, error)
}
type Values interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}
type Facts interface {
	PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error)
	RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error
}
type Spirit interface {
	LockTrialInventoryTx(context.Context, tx.Tx, identity.PlayerID) (int64, error)
	ProviderRevision() string
}
type Progression interface {
	ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error)
}
type MailPrefix interface {
	LockMailNamespaceCounterTx(context.Context, tx.Tx, identity.PlayerID, mail.Namespace) error
}
type Mode struct {
	Spirit      Spirit
	Progression Progression
	Mail        MailPrefix
	Energy      i5.TxTemporalDebiter
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Store       Store
	Content     Content
	Fence       Fence
	Functions   Functions
	Heroes      Heroes
	HeroLocks   HeroLocks
	Pets        Pets
	Combat      Combat
	Rules       cb.Rules
	Values      Values
	Facts       Facts
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
}
type Fight struct {
	Campaign      int64
	Formation     []int64
	Pet           int64
	RentPlayer    int64
	RentUnit      int64
	RentPetPlayer int64
	RentPetUnit   int64
}
type Result struct {
	Campaign, Star, Pet int64
	Formation           []int64
}
