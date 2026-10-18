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
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store interface {
	LockGirlsRootTx(context.Context, tx.Tx, identity.LogicalServerID, time.Time) (d.GirlsRoot, error)
	SaveGirlsRootTx(context.Context, tx.Tx, d.GirlsRoot, int64) error
	InsertGirlsSnapshotTx(context.Context, tx.Tx, d.GirlsSnapshot) error
	ReadGirlsSnapshotTx(context.Context, tx.Queryer, identity.LogicalServerID, int64) (d.GirlsSnapshot, bool, error)
	FindGirlsSnapshotByOperationTx(context.Context, tx.Queryer, ids.UUID) (d.GirlsSnapshot, bool, error)
	BindGirlsPeriodTx(context.Context, tx.Tx, d.GirlsSnapshot) error
	PendingGirlsPeriodsTx(context.Context, tx.Queryer, identity.LogicalServerID) ([]d.GirlsPeriod, error)
	ReadGirlsPeriodTx(context.Context, tx.Queryer, identity.LogicalServerID, time.Time) (d.GirlsPeriod, bool, error)
	SettleGirlsPeriodTx(context.Context, tx.Tx, d.GirlsSnapshot, d.GirlsPeriod, time.Time) error
	GirlsAwardEvidenceTx(context.Context, tx.Queryer, identity.PlayerID) ([]d.GirlsAwardEvidence, error)
	GirlsTrackingTx(context.Context, tx.Queryer, identity.PlayerID, identity.LogicalServerID, time.Time) (bool, error)
}
type Cohort interface {
	ListPlayerRootsTx(context.Context, tx.Queryer) ([]playerroot.Root, error)
}
type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
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
type Service struct {
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Store       Store
	Cohort      Cohort
	Directory   Directory
	Metrics     publicprofile.ScopedMetricReader
	Content     Content
	Fence       Fence
	Players     playerroot.TxLocker
	Recipient   Recipient
	Ledger      RecipientLedger
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
}
