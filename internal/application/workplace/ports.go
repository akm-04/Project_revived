package workplace

import (
	"context"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	d "gxb.local/backend/v2/internal/domain/workplace"
	"gxb.local/backend/v2/internal/foundation/ids"
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
	HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error)
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	WorkplaceCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
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
type Campaigns interface {
	ReadTx(context.Context, tx.Queryer, identity.PlayerID) (campaign.Record, error)
}
type Heroes interface {
	LockStoryRosterTx(context.Context, tx.Tx, identity.PlayerID) error
}
type HeroLocks interface {
	LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error)
}
type Opponents interface {
	WorkplaceOpponentTx(context.Context, tx.Queryer, int64) ([]cb.Participant, error)
}
type Combat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, cb.StartRequest) (cb.Started, error)
	Resolve(context.Context, operation.Context, ids.UUID) (cb.Resolved, error)
	TerminalTx(context.Context, tx.Tx, cb.TerminalRequest) (cb.Settled, error)
}
type Values interface {
	WorkplaceSPTx(context.Context, tx.Tx, identity.PlayerID, operation.Context) (economy.MaterializedTemporal, error)
	DebitTemporalTx(context.Context, tx.Tx, identity.PlayerID, string, int64, operation.Context) (economy.TemporalState, error)
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}
type Facts interface {
	PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error)
	RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error
}
type Mode struct {
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Store       Store
	Content     Content
	Fence       Fence
	Functions   Functions
	Directory   Directory
	Campaigns   Campaigns
	Heroes      Heroes
	HeroLocks   HeroLocks
	HeroWire    func(character.Hero) (map[string]any, error)
	Opponents   Opponents
	Combat      Combat
	Stats       cb.Stats
	Values      Values
	Privileges  i5.PrivilegeSnapshotProvider
	Facts       Facts
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
}
