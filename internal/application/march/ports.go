// Package march composes the Champion owner through existing owner ports.
package march

import (
	"context"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	combat "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	summon "gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store interface {
	ReadTx(context.Context, tx.Queryer, identity.PlayerID) (d.Run, bool, error)
	LockTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (d.Run, error)
	SaveTx(context.Context, tx.Tx, identity.PlayerID, d.Run, time.Time) error
}
type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	MarchCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
	SummonCatalogTx(context.Context, tx.Queryer, string) (summon.Catalog, error)
}
type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type Functions interface {
	ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error)
}
type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}
type HeroLocks interface {
	LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error)
}
type Heroes interface {
	LockStoryRosterTx(context.Context, tx.Tx, identity.PlayerID) error
	AwardStoryPartnerTx(context.Context, tx.Tx, identity.PlayerID, int64, string, operation.Context) (character.Hero, *character.CollectionAdmissionProof, error)
}
type Roster interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

// Opponents is a nonmutating projection from the canonical Top Floor owner.
type Opponents interface {
	MarchCandidatesTx(context.Context, tx.Queryer, identity.ActorContext, time.Time, int) ([]d.Enemy, error)
}
type Combat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, combat.StartRequest) (combat.Started, error)
	AttestReportTx(context.Context, tx.Tx, combat.ReportRequest) (combat.SummaryAttested, error)
}
type Facts interface {
	PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error)
	RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error
}
type Grants interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}
type Mode struct {
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Store       Store
	Content     Content
	Fence       Fence
	Functions   Functions
	Directory   Directory
	HeroLocks   HeroLocks
	Heroes      Heroes
	Roster      Roster
	HeroWire    func(character.Hero) (map[string]any, error)
	Opponents   Opponents
	Combat      Combat
	Facts       Facts
	Grants      Grants
	Costs       i5.TxMaterialCostDebiter
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
}
