package socialinboxstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (Store) DismissNoticeTx(ctx context.Context, t tx.Tx, n socialinbox.Notice, at time.Time) error {
	if t == nil || !n.Active || socialinbox.ValidateRelationLifecycle(n) != nil || at.Before(n.UpdatedAt) || at.Before(n.NoticeTime) {
		return socialinbox.ErrInvalidNotice
	}
	tag, e := t.Exec(ctx, `UPDATE social_notices SET active=false,dismissed_at=$4,updated_at=$4,state_version=state_version+1 WHERE recipient_player_id=$1 AND notice_id=$2 AND state_version=$3 AND active`, int64(n.RecipientPlayerID), int64(n.NoticeID), n.StateVersion, at.UTC())
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return socialinbox.ErrRelationNoticeConflict
	}
	return nil
}
func (Store) ReadNoticeSourceTx(ctx context.Context, t tx.Tx, p identity.PlayerID, s socialinbox.SourceKey) (socialinbox.Notice, bool, error) {
	if t == nil || !p.Valid() || s.Validate() != nil {
		return socialinbox.Notice{}, false, socialinbox.ErrInvalidNotice
	}
	var n socialinbox.Notice
	var pid, id int64
	var related *int64
	e := t.QueryRow(ctx, `SELECT recipient_player_id,notice_id,notice_type,source_kind,source_key,related_player_id,active,notice_time,dismissed_at,state_version,created_at,updated_at FROM social_notices WHERE recipient_player_id=$1 AND source_kind=$2 AND source_key=$3`, int64(p), s.Kind, s.Key).Scan(&pid, &id, &n.NoticeType, &n.Source.Kind, &n.Source.Key, &related, &n.Active, &n.NoticeTime, &n.DismissedAt, &n.StateVersion, &n.CreatedAt, &n.UpdatedAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return socialinbox.Notice{}, false, nil
	}
	if e != nil {
		return socialinbox.Notice{}, false, e
	}
	n.RecipientPlayerID = identity.PlayerID(pid)
	n.NoticeID = socialinbox.NoticeID(id)
	n.RelatedPlayerDeleted = related == nil
	if related != nil {
		n.RelatedPlayerID = identity.PlayerID(*related)
	}
	n.NoticeTime = n.NoticeTime.UTC()
	n.CreatedAt = n.CreatedAt.UTC()
	n.UpdatedAt = n.UpdatedAt.UTC()
	n.DismissedAt = utcPtr(n.DismissedAt)
	if e := n.Validate(); e != nil {
		return socialinbox.Notice{}, false, e
	}
	return n, true, nil
}

var _ socialinbox.DismissStore = Store{}
var _ socialinbox.SourceReader = Store{}
