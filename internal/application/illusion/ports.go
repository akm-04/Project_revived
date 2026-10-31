package illusion

import (
	"context"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store owns the illusion occurrence (rank 606) and the rank-605 player row.
type Store interface {
	ReadOccurrenceTx(context.Context, tx.Queryer, int64) (d.Occurrence, bool, error)
	LockOccurrenceTx(context.Context, tx.Tx, int64, time.Time) (d.Occurrence, error)
	SaveOccurrenceTx(context.Context, tx.Tx, d.Occurrence, time.Time) error
	ReadPlayerTx(context.Context, tx.Queryer, identity.PlayerID) (d.Player, bool, error)
	LockPlayerTx(context.Context, tx.Tx, int64, identity.PlayerID, time.Time) (d.Player, error)
	SavePlayerTx(context.Context, tx.Tx, d.Player, time.Time) error
	ReadResultTx(context.Context, tx.Queryer, int64, int64, int64, identity.PlayerID) (d.Result, bool, error)
	LockResultTx(context.Context, tx.Tx, int64, int64, int64, identity.PlayerID, time.Time) (d.Result, error)
	SaveResultTx(context.Context, tx.Tx, int64, int64, int64, d.Result, time.Time) error
	ReadRankTx(context.Context, tx.Queryer, int64, int64, int64) ([]d.Result, error)
	InsertAttemptTx(context.Context, tx.Tx, d.Attempt) error
	FindLatestAttemptTx(context.Context, tx.Queryer, identity.PlayerID) (d.Attempt, bool, error)
	SaveAttemptTx(context.Context, tx.Tx, d.Attempt) error
	InsertReportTx(context.Context, tx.Tx, string, int64, int64, int64, string, time.Time) error
	ReadReportTx(context.Context, tx.Queryer, string, time.Time) (string, bool, error)
}

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	IllusionCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

// Players is the I4 player root lock, rank 315 then the root below it.
type Players interface {
	LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error)
}

// Functions is the F6 function gate; function 43 opens at level 65.
type Functions interface {
	ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error)
}

type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

// Heroes is the stock roster composer (MID1 key 49) used to check ownership.
type Heroes interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

type Combat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, cb.StartRequest) (cb.Started, error)
	AttestSummaryTx(context.Context, tx.Tx, cb.SummaryRequest) (cb.SummaryAttested, error)
	Resolve(context.Context, operation.Context, ids.UUID) (cb.Resolved, error)
	TerminalTx(context.Context, tx.Tx, cb.TerminalRequest) (cb.Settled, error)
	SettleMemberTx(context.Context, tx.Tx, cb.MemberSettleRequest) (cb.MemberSettled, error)
	MonsterWaves(int64) ([][]cb.Participant, error)
}

// Stats exposes the qualified public force the team window displays and the
// per-hero power floor uses.
type Stats interface {
	HeroTx(context.Context, ca.CoherentReadScope, character.HeroRef, publicstats.View) (publicstats.Result, error)
}

type Costs interface {
	DebitMaterialCostTx(context.Context, tx.Tx, identity.PlayerID, i5.MaterialCost, operation.Context) (i5.MaterialDebitResult, error)
}

// Facts is the objective fact port; a finished Fantasy fight is FANTASY.
type Facts interface {
	PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error)
	RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error
}

// GuildSummary is the read-only guild identity and current roster the guild
// board aggregates.
type GuildSummary struct {
	ID            int64
	Name          string
	Icon          int64
	Description   string
	MinAllowLevel int64
	Members       []identity.PlayerID
}

type Guilds interface {
	GuildSummaries(context.Context, identity.LogicalServerID) ([]GuildSummary, error)
}

type Mode struct {
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Store       Store
	Content     Content
	Fence       Fence
	Players     Players
	Functions   Functions
	Directory   Directory
	Heroes      Heroes
	Pets        Heroes
	Stats       Stats
	Rooms       sharedroom.Service
	RoomStore   sharedroom.Store
	Combat      Combat
	Privileges  i5.PrivilegeSnapshotProvider
	Costs       Costs
	Facts       Facts
	Guilds      Guilds
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
}

func (s Mode) ready() bool {
	return s.Timed.Binder.Time != nil && s.Fresh != nil && s.Store != nil && s.Content != nil && s.Fence != nil && s.Players != nil &&
		s.Functions != nil && s.Directory != nil && s.Heroes != nil && s.Combat != nil && s.Privileges != nil && s.Costs != nil &&
		s.Facts != nil && s.Receipts != nil && s.ReceiptRead != nil
}

// StartRequest is the stock 1346 request; a mate's pet is never sent by stock.
type StartRequest struct {
	Formation []int64
	PetID     int64
}

// ResultRequest is the stock 1347 client summary.
type ResultRequest struct {
	Star      int64
	Damage    int64
	CostTime  int64
	PetID     int64
	Formation []int64
}

// Response carries a stock body and whether it answers a duplicate terminal.
type Response struct {
	Body      map[string]any
	Duplicate bool
}

type session struct {
	occurrence d.Occurrence
	player     d.Player
	day        int64
}
