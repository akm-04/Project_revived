package worldboss

import (
	"context"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	d "gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store owns the occurrence (rank 606) and player/total/attempt rows.
type Store interface {
	ReadOccurrenceTx(context.Context, tx.Queryer, int64) (d.Occurrence, bool, error)
	LockOccurrenceTx(context.Context, tx.Tx, int64, time.Time) (d.Occurrence, error)
	SaveOccurrenceTx(context.Context, tx.Tx, d.Occurrence, time.Time) error
	ListOccurrencesTx(context.Context, tx.Queryer, int64) ([]d.Occurrence, error)
	ReadPlayerTx(context.Context, tx.Queryer, identity.PlayerID) (d.Player, bool, error)
	LockPlayerTx(context.Context, tx.Tx, int64, identity.PlayerID, time.Time) (d.Player, error)
	SavePlayerTx(context.Context, tx.Tx, d.Player, time.Time) error
	LockTotalTx(context.Context, tx.Tx, d.Board, identity.PlayerID, time.Time) (d.Total, error)
	ReadTotalTx(context.Context, tx.Queryer, d.Board, identity.PlayerID) (d.Total, bool, error)
	SaveTotalTx(context.Context, tx.Tx, d.Total, time.Time) error
	ReadRankTx(context.Context, tx.Queryer, d.Board, int64) ([]d.RankEntry, error)
	InsertAttemptTx(context.Context, tx.Tx, d.Attempt) error
	FindAttemptTx(context.Context, tx.Queryer, identity.PlayerID, int64, int64) (d.Attempt, bool, error)
	SaveAttemptTx(context.Context, tx.Tx, d.Attempt) error
	CountChallengersTx(context.Context, tx.Queryer, int64, int64) (int64, error)
}

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	WorldBossCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

// Players is the I4 player root lock, rank 315 then the root below it.
type Players interface {
	LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error)
}

type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

// Population supplies the per-server level-90 count of the 22:00 courage increment.
type Population interface {
	LevelAtLeastCountTx(context.Context, tx.Queryer, int64, int64) (int64, error)
}

// Heroes is the stock roster composer (MID1 key 49) used for purple+ checks.
type Heroes interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

type Combat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, cb.StartRequest) (cb.Started, error)
	AttestSummaryTx(context.Context, tx.Tx, cb.SummaryRequest) (cb.SummaryAttested, error)
}

type Costs interface {
	DebitMaterialCostTx(context.Context, tx.Tx, identity.PlayerID, i5.MaterialCost, operation.Context) (i5.MaterialDebitResult, error)
}

type Mail interface {
	DeliverTx(context.Context, tx.Tx, i5.SettlementMailRequest) (mail.Record, bool, error)
}

type Mode struct {
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Store       Store
	Content     Content
	Fence       Fence
	Players     Players
	Directory   Directory
	Population  Population
	Heroes      Heroes
	Combat      Combat
	Privileges  i5.PrivilegeSnapshotProvider
	Costs       Costs
	Mail        Mail
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
}

func (s Mode) ready() bool {
	return s.Fresh != nil && s.Store != nil && s.Content != nil && s.Fence != nil && s.Players != nil && s.Directory != nil && s.Population != nil &&
		s.Heroes != nil && s.Combat != nil && s.Privileges != nil && s.Costs != nil && s.Mail != nil && s.Receipts != nil && s.ReceiptRead != nil
}

// StartRequest is the stock 626 request.
type StartRequest struct {
	CampaignID int64
	Formation  []int64
}

// ResultRequest is the stock 627 request; damage was already bounded by the wire.
type ResultRequest struct {
	CampaignID int64
	Damage     int64
	Formation  []int64
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
