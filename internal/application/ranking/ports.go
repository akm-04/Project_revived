// Package ranking owns canonical Ranking snapshots and their title settlements.
// Scores and canonical player identities remain with their existing owners.
package ranking

import (
	"context"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/publicprofile"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store interface {
	LockBoardRootTx(context.Context, tx.Tx, d.Board, identity.LogicalServerID, time.Time) (d.BoardRoot, error)
	SaveBoardRootTx(context.Context, tx.Tx, d.BoardRoot, int64) error
	InsertBoardSnapshotTx(context.Context, tx.Tx, d.BoardSnapshot) error
	ReadBoardSnapshotTx(context.Context, tx.Queryer, d.Board, identity.LogicalServerID, int64) (d.BoardSnapshot, bool, error)
	FindBoardSnapshotByOperationTx(context.Context, tx.Queryer, ids.UUID) (d.BoardSnapshot, bool, error)
	BindBoardPeriodTx(context.Context, tx.Tx, d.BoardSnapshot) error
	PendingBoardPeriodsTx(context.Context, tx.Queryer, d.Board, identity.LogicalServerID) ([]d.BoardPeriod, error)
	ReadBoardPeriodTx(context.Context, tx.Queryer, d.Board, identity.LogicalServerID, time.Time) (d.BoardPeriod, bool, error)
	SettleBoardPeriodTx(context.Context, tx.Tx, d.BoardSnapshot, d.BoardPeriod, time.Time) error
	BoardAwardEvidenceTx(context.Context, tx.Queryer, d.Board, identity.PlayerID) ([]d.BoardAwardEvidence, error)
	BoardTrackingTx(context.Context, tx.Queryer, d.Board, identity.PlayerID, identity.LogicalServerID, time.Time) (bool, error)
	UpsertScoreRowTx(context.Context, tx.Tx, d.ScoreRow) error
	DeleteScoreRowTx(context.Context, tx.Tx, string, identity.PlayerID) error
	ReadScoreRowTx(context.Context, tx.Queryer, string, identity.PlayerID) (d.ScoreRow, bool, error)
	TopScoreRowsTx(context.Context, tx.Queryer, string, identity.LogicalServerID, int64) ([]d.ScoreRow, error)
	AllScoreRowsTx(context.Context, tx.Queryer, string, identity.LogicalServerID) ([]d.ScoreRow, error)
	ScoreRankTx(context.Context, tx.Queryer, string, identity.LogicalServerID, d.ScoreRow) (int64, error)
}
type Cohort interface {
	ListPlayerRootsTx(context.Context, tx.Queryer) ([]playerroot.Root, error)
}
type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
	ProfilesTx(context.Context, tx.Queryer, []identity.PlayerID) (map[identity.PlayerID]playerdirectory.Profile, error)
}
type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	ReadPlayerDisplayCatalogTx(context.Context, tx.Queryer, string) (player.DisplayCatalog, error)
}
type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type Recipient interface {
	ReceiveOriginTx(context.Context, tx.Tx, playerroot.Root, playerdisplay.Origin) error
}
type RecipientLedger interface {
	ReadDisplayEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, string) ([]playerdisplay.Origin, error)
}

// ComfortFacts is DormHouse's typed score supply for the comfort board.
type ComfortFacts interface {
	ComfortFactTx(context.Context, tx.Queryer, identity.PlayerID, string, time.Time) (dorm.ComfortFact, bool, error)
}

// TopForceFacts is CharacterHero's top-five public-force read port for the
// subtype 9 board.
type TopForceFacts interface {
	ReadTopForceMetricScopeTx(context.Context, tx.Scope, publicprofile.MetricRequest) (publicprofile.MetricObservation, error)
}

type Service struct {
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Store       Store
	Cohort      Cohort
	Directory   Directory
	Metrics     publicprofile.ScopedMetricReader
	Comfort     ComfortFacts
	TopForce    TopForceFacts
	Content     Content
	Fence       Fence
	Players     playerroot.TxLocker
	Recipient   Recipient
	Ledger      RecipientLedger
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
	// ListSize overrides R7_PRIVATE_RANK_LIST_SIZE_V1; zero uses the policy fallback.
	ListSize int64
}
