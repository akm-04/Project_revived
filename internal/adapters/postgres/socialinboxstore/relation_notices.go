package socialinboxstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const lockSourceSQL = `SELECT recipient_player_id,notice_id,notice_type,source_kind,source_key,related_player_id,active,notice_time,dismissed_at,state_version,created_at,updated_at FROM social_notices WHERE recipient_player_id=$1 AND source_kind=$2 AND source_key=$3 FOR UPDATE`

func (Store) LockNoticeSourceTx(ctx context.Context, t tx.Tx, recipient identity.PlayerID, source socialinbox.SourceKey) (socialinbox.Notice, bool, error) {
	if t == nil || !recipient.Valid() || source.Validate() != nil {
		return socialinbox.Notice{}, false, socialinbox.ErrInvalidNotice
	}
	var n socialinbox.Notice
	var pid, id int64
	var related *int64
	err := t.QueryRow(ctx, lockSourceSQL, int64(recipient), source.Kind, source.Key).Scan(&pid, &id, &n.NoticeType, &n.Source.Kind, &n.Source.Key, &related, &n.Active, &n.NoticeTime, &n.DismissedAt, &n.StateVersion, &n.CreatedAt, &n.UpdatedAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return n, false, nil
	}
	if err != nil {
		return n, false, err
	}
	n.RecipientPlayerID = identity.PlayerID(pid)
	n.NoticeID = socialinbox.NoticeID(id)
	if related != nil {
		n.RelatedPlayerID = identity.PlayerID(*related)
	}
	if n.RecipientPlayerID != recipient || n.Source != source {
		return n, false, socialinbox.ErrRelationNoticeConflict
	}
	if err := n.Validate(); err != nil {
		return n, false, err
	}
	return n, true, nil
}

const insertRelationSQL = `INSERT INTO social_notices(recipient_player_id,notice_type,source_kind,source_key,related_player_id,active,notice_time,dismissed_at,state_version,created_at,updated_at) VALUES($1,$2,$3,$4,$5,TRUE,$6,NULL,1,$6,$6) ON CONFLICT(recipient_player_id,source_kind,source_key) DO NOTHING RETURNING notice_id`

func (Store) InsertRelationNoticeTx(ctx context.Context, t tx.Tx, n socialinbox.Notice) (socialinbox.Notice, error) {
	if t == nil {
		return socialinbox.Notice{}, socialinbox.ErrInvalidNotice
	}
	if err := socialinbox.ValidateRelationDescriptor(n); err != nil {
		return socialinbox.Notice{}, err
	}
	var id int64
	err := t.QueryRow(ctx, insertRelationSQL, int64(n.RecipientPlayerID), n.NoticeType, n.Source.Kind, n.Source.Key, int64(n.RelatedPlayerID), n.NoticeTime.UTC()).Scan(&id)
	if errors.Is(err, kernelstore.ErrNoRows) {
		// Parent fence is already held; no new source/row lock is acquired after effects.
		var existing socialinbox.Notice
		var pid, nid int64
		var related *int64
		e := t.QueryRow(ctx, `SELECT recipient_player_id,notice_id,notice_type,source_kind,source_key,related_player_id,active,notice_time,dismissed_at,state_version,created_at,updated_at FROM social_notices WHERE recipient_player_id=$1 AND source_kind=$2 AND source_key=$3`, int64(n.RecipientPlayerID), n.Source.Kind, n.Source.Key).Scan(&pid, &nid, &existing.NoticeType, &existing.Source.Kind, &existing.Source.Key, &related, &existing.Active, &existing.NoticeTime, &existing.DismissedAt, &existing.StateVersion, &existing.CreatedAt, &existing.UpdatedAt)
		if e != nil {
			return socialinbox.Notice{}, e
		}
		existing.RecipientPlayerID = identity.PlayerID(pid)
		existing.NoticeID = socialinbox.NoticeID(nid)
		if related != nil {
			existing.RelatedPlayerID = identity.PlayerID(*related)
		}
		return existing, existing.Validate()
	}
	if err != nil {
		return socialinbox.Notice{}, err
	}
	n.NoticeID = socialinbox.NoticeID(id)
	n.Active = true
	n.StateVersion = 1
	n.CreatedAt = n.NoticeTime.UTC()
	n.UpdatedAt = n.CreatedAt
	n.DismissedAt = nil
	return n, n.Validate()
}

var _ socialinbox.RelationNoticeStore = Store{}
