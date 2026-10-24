package socialinboxstore

import (
	"context"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (Store) InsertGiftNoticeTx(c context.Context, t tx.Tx, n socialinbox.Notice) (socialinbox.Notice, error) {
	u, e := ids.ParseUUID(n.Source.Key)
	d := socialinbox.GiftDescriptor{TransferID: u, Sender: n.RelatedPlayerID, Recipient: n.RecipientPlayerID, IssuedAt: n.NoticeTime}
	w, err := d.Notice()
	if e != nil || err != nil || n.Source != w.Source || n.NoticeType != 4 || t == nil {
		return socialinbox.Notice{}, socialinbox.ErrInvalidNotice
	}
	var id int64
	e = t.QueryRow(c, `INSERT INTO social_notices(recipient_player_id,notice_type,source_kind,source_key,related_player_id,active,notice_time,state_version,created_at,updated_at) VALUES($1,4,$2,$3,$4,true,$5,1,$5,$5) RETURNING notice_id`, int64(n.RecipientPlayerID), n.Source.Kind, n.Source.Key, int64(n.RelatedPlayerID), n.NoticeTime).Scan(&id)
	if e != nil {
		return socialinbox.Notice{}, e
	}
	n.NoticeID = socialinbox.NoticeID(id)
	n.Active = true
	n.StateVersion = 1
	n.CreatedAt = n.NoticeTime
	n.UpdatedAt = n.NoticeTime
	return n, socialinbox.ValidateGiftLifecycle(n)
}
func (Store) ConsumeGiftNoticeTx(c context.Context, t tx.Tx, n socialinbox.Notice, at time.Time) error {
	if socialinbox.ValidateGiftLifecycle(n) != nil || socialinbox.PreflightConsumption(n, at) != nil || t == nil {
		return socialinbox.ErrInvalidNotice
	}
	tag, e := t.Exec(c, `UPDATE social_notices SET active=false,dismissed_at=$4,updated_at=$4,state_version=state_version+1 WHERE recipient_player_id=$1 AND notice_id=$2 AND state_version=$3 AND active`, int64(n.RecipientPlayerID), int64(n.NoticeID), n.StateVersion, at)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return socialinbox.ErrInvalidNotice
	}
	return nil
}

// ReadNoticeEvidenceTx is a pure owner read used by complete source reconciliation.
func (Store) ReadNoticeEvidenceTx(c context.Context, q tx.Queryer, p identity.PlayerID, id socialinbox.NoticeID) (socialinbox.Notice, bool, error) {
	return readNoticeEvidence(c, q, p, id)
}
