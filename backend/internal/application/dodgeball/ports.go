package dodgeball

import (
	"context"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/dodgeball"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store interface {
	ReadTx(context.Context, tx.Queryer, identity.PlayerID) (dodgeball.State, bool, error)
	LockTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (dodgeball.State, error)
	SaveTx(context.Context, tx.Tx, identity.PlayerID, dodgeball.State, time.Time) error
}
type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	DodgeballCatalogTx(context.Context, tx.Queryer, string) (dodgeball.Catalog, error)
}
type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type Functions interface {
	ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error)
}
type Combat interface {
	StartTx(context.Context, tx.Tx, characterasset.CoherentReadScope, combat.StartRequest) (combat.Started, error)
	AttestDerivedTx(context.Context, tx.Tx, combat.DerivedRequest) (combat.SummaryAttested, error)
}
type Values interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}
type Mail interface {
	LockMailNamespaceCounterTx(context.Context, tx.Tx, identity.PlayerID, mail.Namespace) error
}
type Delivery interface {
	DeliverTx(context.Context, tx.Tx, i5.SettlementMailRequest) (mail.Record, bool, error)
}
type Friends interface {
	ActiveFriendsTx(context.Context, tx.Tx, identity.PlayerID) ([]identity.PlayerID, error)
}

type Mode struct {
	Timed        generation.TimedRunner
	Fresh        tx.Queryer
	Store        Store
	Content      Content
	Fence        Fence
	Functions    Functions
	Players      playerroot.TxLocker
	Privacy      socialrelation.FriendDMPrivacyReader
	Friends      Friends
	Presentation playerpresentation.TxReaderAt
	Combat       Combat
	Values       Values
	Costs        i5.TxMaterialCostDebiter
	Mail         Mail
	Delivery     Delivery
	Receipts     receipt.Store
	ReceiptRead  receipt.Reader
}
