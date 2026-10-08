package socialgift

import (
	"context"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store interface {
	SentRecipients(context.Context, tx.Queryer, identity.PlayerID, string) ([]identity.PlayerID, error)
	ReadEpoch(context.Context, tx.Queryer, identity.PlayerID, string) (Epoch, bool, error)
	ReadSend(context.Context, tx.Queryer, ids.UUID) (Transfer, bool, error)
	ReadTransfer(context.Context, tx.Queryer, ids.UUID) (Transfer, bool, error)
	ReadClaim(context.Context, tx.Queryer, ids.UUID) (ClaimOperation, bool, error)
	ClaimTransfers(context.Context, tx.Queryer, ids.UUID) ([]Transfer, error)
	LockEpoch(context.Context, tx.Tx, identity.PlayerID, string) (Epoch, bool, Epoch, bool, error)
	LockTransfer(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID, string) (Transfer, bool, error)
	Counts(context.Context, tx.Queryer, identity.PlayerID, string) (int64, int64, error)
	PutEpoch(context.Context, tx.Tx, Epoch, bool, time.Time) error
	InsertTransfer(context.Context, tx.Tx, Transfer) error
	ClaimTransfer(context.Context, tx.Tx, Transfer, int64) error
	InsertClaim(context.Context, tx.Tx, ClaimOperation) error
}
type ContentReader interface {
	ReadGiftContent(context.Context, tx.Queryer, string) (Content, error)
	ActiveRevision(context.Context, tx.Queryer) (string, error)
}
type GrantOwner interface {
	VerifyGiftBalanceTx(context.Context, tx.Queryer, identity.PlayerID) error
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
	ReadGrantEvidenceTx(context.Context, tx.Queryer, grant.Plan) (i5.GrantResult, bool, error)
	GiftGrantIdentityExistsTx(context.Context, tx.Queryer, identity.PlayerID, ids.UUID) (bool, error)
}
type ActorAdmission interface {
	ValidateActor(context.Context, identity.ActorContext, time.Time) error
}
type ActorFence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type NoticeEvidence interface {
	ReadNoticeEvidenceTx(context.Context, tx.Queryer, identity.PlayerID, socialinbox.NoticeID) (socialinbox.Notice, bool, error)
}

type RelationOwner interface {
	socialrelation.CommandStore
	ReadRootsTx(context.Context, tx.Queryer, []identity.PlayerID) (map[identity.PlayerID]socialrelation.Root, error)
}
