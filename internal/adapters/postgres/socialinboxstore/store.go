package socialinboxstore

import (
	"context"
	"errors"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

const nextNoticeIDSQL = `SELECT nextval('social_notice_id_seq')`

const lockNoticeSQL = `
SELECT recipient_player_id,notice_id,notice_type,source_kind,source_key,related_player_id,active,notice_time,dismissed_at,state_version,created_at,updated_at
FROM social_notices
WHERE recipient_player_id=$1 AND notice_id=$2
FOR UPDATE`

func (Store) NextNoticeIDTx(ctx context.Context, q tx.Queryer) (socialinbox.NoticeID, error) {
	if q == nil {
		return 0, errors.New("social inbox store: nil queryer")
	}
	var raw int64
	if err := q.QueryRow(ctx, nextNoticeIDSQL).Scan(&raw); err != nil {
		return 0, err
	}
	id := socialinbox.NoticeID(raw)
	if !id.Valid() {
		return 0, errors.New("social inbox store: invalid notice id")
	}
	return id, nil
}

func (Store) LockNoticeTx(ctx context.Context, t tx.Tx, recipient identity.PlayerID, id socialinbox.NoticeID) (socialinbox.Notice, bool, error) {
	if t == nil || !recipient.Valid() || !id.Valid() {
		return socialinbox.Notice{}, false, errors.New("social inbox store: invalid notice lock")
	}
	var out socialinbox.Notice
	var rawRecipient, rawID int64
	var sourceKind, sourceKey string
	var related *int64
	if err := t.QueryRow(ctx, lockNoticeSQL, int64(recipient), int64(id)).Scan(
		&rawRecipient, &rawID, &out.NoticeType, &sourceKind, &sourceKey, &related, &out.Active, &out.NoticeTime, &out.DismissedAt, &out.StateVersion, &out.CreatedAt, &out.UpdatedAt,
	); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return socialinbox.Notice{}, false, nil
		}
		return socialinbox.Notice{}, false, err
	}
	out.RecipientPlayerID = identity.PlayerID(rawRecipient)
	out.NoticeID = socialinbox.NoticeID(rawID)
	out.Source = socialinbox.SourceKey{Kind: sourceKind, Key: sourceKey}
	out.RelatedPlayerDeleted = related == nil
	if related != nil {
		out.RelatedPlayerID = identity.PlayerID(*related)
	}
	out.NoticeTime, out.CreatedAt, out.UpdatedAt = out.NoticeTime.UTC(), out.CreatedAt.UTC(), out.UpdatedAt.UTC()
	out.DismissedAt = utcPtr(out.DismissedAt)
	if err := out.Validate(); err != nil {
		return socialinbox.Notice{}, false, err
	}
	return out, true, nil
}

func readNoticeEvidence(ctx context.Context, t tx.Queryer, recipient identity.PlayerID, id socialinbox.NoticeID) (socialinbox.Notice, bool, error) {
	if t == nil || !recipient.Valid() || !id.Valid() {
		return socialinbox.Notice{}, false, errors.New("social inbox store: invalid notice lock")
	}
	var out socialinbox.Notice
	var rawRecipient, rawID int64
	var sourceKind, sourceKey string
	var related *int64
	if err := t.QueryRow(ctx, strings.Replace(lockNoticeSQL, "FOR UPDATE", "", 1), int64(recipient), int64(id)).Scan(
		&rawRecipient, &rawID, &out.NoticeType, &sourceKind, &sourceKey, &related, &out.Active, &out.NoticeTime, &out.DismissedAt, &out.StateVersion, &out.CreatedAt, &out.UpdatedAt,
	); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return socialinbox.Notice{}, false, nil
		}
		return socialinbox.Notice{}, false, err
	}
	out.RecipientPlayerID = identity.PlayerID(rawRecipient)
	out.NoticeID = socialinbox.NoticeID(rawID)
	out.Source = socialinbox.SourceKey{Kind: sourceKind, Key: sourceKey}
	out.RelatedPlayerDeleted = related == nil
	if related != nil {
		out.RelatedPlayerID = identity.PlayerID(*related)
	}
	out.NoticeTime, out.CreatedAt, out.UpdatedAt = out.NoticeTime.UTC(), out.CreatedAt.UTC(), out.UpdatedAt.UTC()
	out.DismissedAt = utcPtr(out.DismissedAt)
	if err := out.Validate(); err != nil {
		return socialinbox.Notice{}, false, err
	}
	return out, true, nil
}

func utcPtr(v *time.Time) *time.Time {
	if v == nil {
		return nil
	}
	x := v.UTC()
	return &x
}

var _ socialinbox.Store = Store{}
