package socialinboxstore

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) InsertRoomInviteNoticeTx(c context.Context, t tx.Tx, n socialinbox.Notice) (socialinbox.Notice, error) {
	if t == nil || socialinbox.ValidateRoomInviteLifecycle(n) != nil {
		return socialinbox.Notice{}, socialinbox.ErrInvalidNotice
	}
	tag, err := t.Exec(c, `INSERT INTO social_notices(recipient_player_id,notice_id,notice_type,source_kind,source_key,related_player_id,active,notice_time,state_version,created_at,updated_at)VALUES($1,$2,$3,$4,$5,$6,true,$7,1,$7,$7)`,
		int64(n.RecipientPlayerID), int64(n.NoticeID), n.NoticeType, n.Source.Kind, n.Source.Key, int64(n.RelatedPlayerID), n.NoticeTime.UTC())
	if err != nil {
		return socialinbox.Notice{}, err
	}
	if tag.RowsAffected() != 1 {
		return socialinbox.Notice{}, socialinbox.ErrInvalidNotice
	}
	n.Active = true
	n.DismissedAt = nil
	n.StateVersion = 1
	n.CreatedAt = n.NoticeTime.UTC()
	n.UpdatedAt = n.NoticeTime.UTC()
	return n, nil
}

func (Store) UpdateRoomInviteNoticeTx(c context.Context, t tx.Tx, n socialinbox.Notice, at time.Time) (socialinbox.Notice, error) {
	if t == nil || socialinbox.ValidateRoomInviteLifecycle(n) != nil || at.IsZero() || at.Before(n.UpdatedAt) {
		return socialinbox.Notice{}, socialinbox.ErrInvalidNotice
	}
	tag, err := t.Exec(c, `UPDATE social_notices SET active=true,dismissed_at=NULL,notice_time=$4,updated_at=$4,related_player_id=$5,state_version=state_version+1 WHERE recipient_player_id=$1 AND notice_id=$2 AND state_version=$3`,
		int64(n.RecipientPlayerID), int64(n.NoticeID), n.StateVersion, at.UTC(), int64(n.RelatedPlayerID))
	if err != nil {
		return socialinbox.Notice{}, err
	}
	if tag.RowsAffected() != 1 {
		return socialinbox.Notice{}, socialinbox.ErrInvalidNotice
	}
	n.Active = true
	n.DismissedAt = nil
	n.NoticeTime = at.UTC()
	n.UpdatedAt = at.UTC()
	n.StateVersion++
	return n, nil
}

// DeleteAgedRoomInviteNoticesTx bounds the row count PRIVATE_POLICY keeps.
func (Store) DeleteAgedRoomInviteNoticesTx(c context.Context, t tx.Tx, recipient identity.PlayerID, at time.Time) (int64, error) {
	if t == nil || !recipient.Valid() || at.IsZero() {
		return 0, socialinbox.ErrInvalidNotice
	}
	tag, err := t.Exec(c, `DELETE FROM social_notices WHERE recipient_player_id=$1 AND source_kind=$2 AND notice_time < $3`,
		int64(recipient), socialinbox.RoomInviteSourceKind, at.UTC().Add(-socialinbox.RoomInviteRetention))
	if err != nil {
		return 0, err
	}
	return tag.RowsAffected(), nil
}
