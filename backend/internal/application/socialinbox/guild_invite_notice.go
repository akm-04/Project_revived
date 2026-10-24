package socialinbox

import (
	"context"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
	"strings"
	"time"
)

func InviteFamily(s SourceKey) bool { return s.Kind == gi.SourceKind }

func InviteTuple(n Notice) (gi.Tuple, error) {
	var tuple gi.Tuple
	if !InviteFamily(n.Source) || n.NoticeType != gi.NoticeType {
		return tuple, ErrInvalidNotice
	}
	p := strings.Split(n.Source.Key, ":")
	if len(p) != 3 {
		return tuple, ErrInvalidNotice
	}
	values := make([]int64, 3)
	for i, raw := range p {
		v, e := strconv.ParseInt(raw, 10, 64)
		if e != nil || v < 1 || strconv.FormatInt(v, 10) != raw {
			return tuple, ErrInvalidNotice
		}
		values[i] = v
	}
	tuple = gi.Tuple{GuildID: guild.ID(values[0]), Recipient: identity.PlayerID(values[1]), Generation: values[2]}
	if tuple.Validate() != nil || tuple.Recipient != n.RecipientPlayerID {
		return tuple, ErrInvalidNotice
	}
	return tuple, nil
}
func ValidateInviteLifecycle(n Notice) error {
	if n.Validate() != nil || !n.NoticeID.WireSafe() {
		return ErrInvalidNotice
	}
	if _, e := InviteTuple(n); e != nil {
		return e
	}
	if !n.RelatedPlayerID.Valid() && !n.RelatedPlayerDeleted {
		return ErrInvalidNotice
	}
	return nil
}
func MatchInvite(n Notice, s gi.Issue) error {
	key, e := s.Tuple.SourceKey()
	if e != nil || ValidateInviteLifecycle(n) != nil || n.RecipientPlayerID != s.Tuple.Recipient || n.Source != (SourceKey{Kind: gi.SourceKind, Key: key}) || n.NoticeTime.UnixMicro() != s.DecisionAt.UnixMicro() || !n.RelatedPlayerDeleted && n.RelatedPlayerID != s.Inviter {
		return ErrInvalidNotice
	}
	return nil
}

// GuildInviteStore owns only SocialInbox Notice and retained target proof.
// Guild and Foundation SQL stay behind separately supplied typed ports.
type GuildInviteStore interface {
	ReadNoticeEvidenceTx(context.Context, tx.Queryer, identity.PlayerID, NoticeID) (Notice, bool, error)
	ReadInviteNoticeSourceTx(context.Context, tx.Queryer, identity.PlayerID, SourceKey) (Notice, bool, error)
	LockNoticeSourceTx(context.Context, tx.Tx, identity.PlayerID, SourceKey) (Notice, bool, error)
	InsertInviteNoticeTx(context.Context, tx.Tx, gi.Issue, time.Time) (Notice, error)
	ConsumeInviteNoticeTx(context.Context, tx.Tx, Notice, time.Time) error
	ReadInviteMaterializationTx(context.Context, tx.Queryer, ids.UUID) (gi.TargetProof, bool, error)
	InsertInviteMaterializationTx(context.Context, tx.Tx, gi.TargetProof) error
	ReadInviteInvalidationTx(context.Context, tx.Queryer, ids.UUID, ids.UUID) (gi.InvalidationProof, bool, error)
	InsertInviteInvalidationTx(context.Context, tx.Tx, gi.InvalidationProof) error
	ReadInviteInvalidationSetTx(context.Context, tx.Queryer, gi.Marker, int64) (gi.SetWitness, []identity.PlayerID, error)
	ReadCoveredInvitePayloadsTx(context.Context, tx.Queryer, gi.Marker, int64) (gi.OwnerPayloadSet, error)
}

// InviteNoticeReader qualifies only the recognized type10 family. Immutable
// replay evidence and current read eligibility are separate typed operations.
type InviteNoticeReader interface {
	ReadImmutableInviteNoticeTx(context.Context, tx.Queryer, Notice) (gi.Issue, error)
	ReadCurrentInviteNoticeTx(context.Context, tx.Queryer, Notice) (gi.Snapshot, error)
}

// The mixed notice consumer holds its complete Notice370 plan before any Gift
// settlement. This owner operation updates the prepared row without new locks.
type InviteConsumptionStore interface {
	ConsumeInviteNoticeTx(context.Context, tx.Tx, Notice, time.Time) error
}
