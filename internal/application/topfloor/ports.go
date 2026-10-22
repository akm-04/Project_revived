// Package topfloor composes the Top Floor owner (C5B_TOP_FLOOR_MODE_V1): ladder
// entry, opponents, tickets, START through the Combat foundation, terminal rank
// settlement, daily mail settlement and history facts. Combat, I5, Achievement,
// Character, PlayerDisplay and Guild keep their ownership behind these ports.
package topfloor

import (
	"context"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/player"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store interface {
	ReadLadderTx(context.Context, tx.Queryer, identity.LogicalServerID, bool) (d.Ladder, bool, error)
	CreateLadderTx(context.Context, tx.Tx, d.Ladder) error
	SaveLadderTx(context.Context, tx.Tx, d.Ladder, int64) error
	RangeTx(context.Context, tx.Queryer, identity.LogicalServerID, int64, int64) ([]d.Ranked, error)
	RankedPlayersTx(context.Context, tx.Queryer, identity.LogicalServerID) ([]d.Ranked, error)
	RankOfTx(context.Context, tx.Queryer, identity.LogicalServerID, d.Occupant) (int64, bool, error)
	AppendPlayerTx(context.Context, tx.Tx, identity.LogicalServerID, int64, identity.PlayerID) error
	SwapTx(context.Context, tx.Tx, identity.LogicalServerID, d.Ranked, d.Ranked) error
	ReadPlayerTx(context.Context, tx.Queryer, identity.PlayerID, bool) (d.Player, bool, error)
	DefendedTx(context.Context, tx.Queryer, []identity.PlayerID) (map[identity.PlayerID]bool, error)
	InsertPlayerTx(context.Context, tx.Tx, d.Player) error
	SavePlayerTx(context.Context, tx.Tx, d.Player, int64) error
	ReadFightTx(context.Context, tx.Queryer, ids.UUID, bool) (d.Fight, bool, error)
	LatestFightTx(context.Context, tx.Queryer, identity.PlayerID) (d.Fight, bool, error)
	OpenFightsTx(context.Context, tx.Queryer, time.Time, int) ([]d.Fight, error)
	InsertFightTx(context.Context, tx.Tx, d.Fight) error
	FinishFightTx(context.Context, tx.Tx, d.Fight, int64) error
	InsertRecordTx(context.Context, tx.Tx, d.Record, int64) error
	RecordsTx(context.Context, tx.Queryer, identity.PlayerID) ([]d.Record, error)
	RecordTx(context.Context, tx.Queryer, int64) (d.Record, bool, error)
	RetainedTx(context.Context, tx.Queryer, ids.UUID) (bool, error)
	LostDefenseTx(context.Context, tx.Queryer, identity.PlayerID, identity.PlayerID) (bool, error)
	AddUsageTx(context.Context, tx.Tx, identity.PlayerID, []cd.PartnerUse) error
	UsageTx(context.Context, tx.Queryer, identity.PlayerID) ([]cd.PartnerTotals, error)
	InsertDaySettlementTx(context.Context, tx.Tx, d.DaySettlement) error
	DueServersTx(context.Context, tx.Queryer, int64) ([]identity.LogicalServerID, error)
}

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	TopFloorCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Functions interface {
	ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error)
}

type Mail interface {
	DeliverTx(context.Context, tx.Tx, i5.SettlementMailRequest) (mail.Record, bool, error)
}

type Achievements interface {
	ObserveTopFloorDayTx(context.Context, tx.Tx, identity.LogicalServerID, int64, string, []identity.PlayerID, time.Time) error
}

type Combat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, combat.StartRequest) (combat.Started, error)
	StartEvidenceTx(context.Context, tx.Queryer, cd.Locator, string) (cd.Attempt, bool, error)
	Resolve(context.Context, operation.Context, ids.UUID) (combat.Resolved, error)
	TerminalTx(context.Context, tx.Tx, combat.TerminalRequest) (combat.Settled, error)
	CloseTx(context.Context, tx.Tx, combat.TerminalRequest) (combat.Closed, error)
	ResultTx(context.Context, tx.Queryer, ids.UUID) (combat.Resolved, error)
	ReplayTx(context.Context, tx.Queryer, ids.UUID, cd.Retention, time.Time) (combat.Resolved, bool, error)
	AttemptTx(context.Context, tx.Queryer, ids.UUID) (cd.Attempt, bool, error)
}

// Roster is the existing stock roster composer (MID1 key 49 Heroes, 780 Pets).
type Roster interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

type Guilds interface {
	ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error)
	ReadGuildTx(context.Context, tx.Queryer, guild.ID) (guild.Guild, bool, error)
}

type Service struct {
	Timed        gen.TimedRunner
	Fresh        tx.Queryer
	Store        Store
	Content      Content
	Fence        Fence
	Functions    Functions
	Privileges   i5.PrivilegeSnapshotProvider
	Costs        i5.TxMaterialCostDebiter
	Mail         Mail
	Achievements Achievements
	Combat       Combat
	Heroes       Roster
	Pets         Roster
	Directory    Directory
	Guilds       Guilds
	Receipts     receipt.Store
	ReceiptRead  receipt.Reader
}

func (s Service) ready() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Fresh != nil && s.Store != nil && s.Content != nil && s.Fence != nil && s.Functions != nil && s.Privileges != nil && s.Costs != nil &&
		s.Mail != nil && s.Achievements != nil && s.Combat != nil && s.Heroes != nil && s.Pets != nil && s.Directory != nil && s.Guilds != nil && s.Receipts != nil && s.ReceiptRead != nil
}

type ArenaView struct {
	Player     d.Player
	Rank       int64
	Enemies    []d.Display
	ServerTime time.Time
}

type FightView struct {
	Formation    []map[string]any
	Report       []byte
	Win          bool
	AwardCrystal int64
	Enemy        d.Display
}

type RecordView struct {
	Record   d.Record
	Self     d.Display
	Opponent d.Display
}

type RecordInfo struct {
	Opponent   d.Display
	AvengeType int64
	CanAvenge  bool
}

type RankList struct {
	Rows   []d.Display
	MyRank int64
}
