package memoir

import (
	"context"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store interface {
	ReadTx(context.Context, tx.Queryer, identity.PlayerID) (memoir.State, bool, error)
	LockTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (memoir.State, error)
	SaveTx(context.Context, tx.Tx, identity.PlayerID, memoir.State, time.Time) error
}
type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	MemoirCatalogTx(context.Context, tx.Queryer, string) (memoir.Catalog, error)
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
type Roster interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}
type Opponents interface {
	MarchCandidatesTx(context.Context, tx.Queryer, identity.ActorContext, time.Time, int) ([]march.Enemy, error)
}
type Combat interface {
	StartTx(context.Context, tx.Tx, characterasset.CoherentReadScope, combat.StartRequest) (combat.Started, error)
	AttestReportTx(context.Context, tx.Tx, combat.ReportRequest) (combat.SummaryAttested, error)
	CloseTx(context.Context, tx.Tx, combat.TerminalRequest) (combat.Closed, error)
	Resolve(context.Context, operation.Context, ids.UUID) (combat.Resolved, error)
	TerminalTx(context.Context, tx.Tx, combat.TerminalRequest) (combat.Settled, error)
}
type Grants interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}
type Mode struct {
	Timed       generation.TimedRunner
	Fresh       tx.Queryer
	Store       Store
	Content     Content
	Fence       Fence
	Functions   Functions
	Heroes      Heroes
	HeroLocks   HeroLocks
	Roster      Roster
	Pets        Roster
	Opponents   Opponents
	Combat      Combat
	Grants      Grants
	Costs       i5.TxMaterialCostDebiter
	Energy      i5.TxTemporalDebiter
	Exchange    i5.TxMaterialExchange
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
}
