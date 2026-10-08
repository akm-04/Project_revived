package socialinboxstore

import (
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

const relationWindowSQL = `SELECT COALESCE(jsonb_agg(to_jsonb(n) ORDER BY notice_time DESC,notice_id DESC),'[]'::jsonb)::text FROM (SELECT * FROM social_notices WHERE recipient_player_id=$1 AND active AND source_kind IN ('social-relation.request.v1','social-relation.friendship.v1') AND related_player_id IS NOT NULL ORDER BY notice_time DESC,notice_id DESC LIMIT 50) n`

type noticeRow struct {
	Recipient int64      `json:"recipient_player_id"`
	ID        int64      `json:"notice_id"`
	Type      int16      `json:"notice_type"`
	Kind      string     `json:"source_kind"`
	Key       string     `json:"source_key"`
	Related   int64      `json:"related_player_id"`
	Active    bool       `json:"active"`
	At        time.Time  `json:"notice_time"`
	Dismissed *time.Time `json:"dismissed_at"`
	Version   int64      `json:"state_version"`
	Created   time.Time  `json:"created_at"`
	Updated   time.Time  `json:"updated_at"`
}

func (Store) RelationWindowTx(c context.Context, t tx.Tx, p identity.PlayerID) ([]socialinbox.Notice, error) {
	if t == nil || !p.Valid() {
		return nil, socialinbox.ErrInvalidNotice
	}
	var raw string
	if e := t.QueryRow(c, relationWindowSQL, int64(p)).Scan(&raw); e != nil {
		return nil, e
	}
	var rows []noticeRow
	if e := json.Unmarshal([]byte(raw), &rows); e != nil {
		return nil, e
	}
	out := make([]socialinbox.Notice, 0, len(rows))
	for _, r := range rows {
		n := socialinbox.Notice{RecipientPlayerID: identity.PlayerID(r.Recipient), NoticeID: socialinbox.NoticeID(r.ID), NoticeType: r.Type, Source: socialinbox.SourceKey{Kind: r.Kind, Key: r.Key}, RelatedPlayerID: identity.PlayerID(r.Related), Active: r.Active, NoticeTime: r.At.UTC(), DismissedAt: r.Dismissed, StateVersion: r.Version, CreatedAt: r.Created.UTC(), UpdatedAt: r.Updated.UTC()}
		if n.Validate() != nil || n.RecipientPlayerID != p || !n.Active || n.RelatedPlayerID == 0 {
			return nil, socialinbox.ErrInvalidNotice
		}
		if e := socialinbox.ValidateRelationDescriptor(n); e != nil {
			return nil, e
		}
		out = append(out, n)
	}
	return out, nil
}

var _ socialinbox.RelationWindowReader = Store{}

const noticePageSQL = `SELECT COALESCE(jsonb_agg(to_jsonb(n) ORDER BY notice_time DESC,notice_id DESC),'[]'::jsonb)::text FROM (SELECT * FROM social_notices WHERE recipient_player_id=$1 AND ($2::timestamptz IS NULL OR (notice_time,notice_id)<($2,$3)) ORDER BY notice_time DESC,notice_id DESC LIMIT $4) n`

func (Store) NoticePageTx(c context.Context, t tx.Tx, p identity.PlayerID, after socialinbox.NoticeCursor, limit int) ([]socialinbox.Notice, error) {
	if t == nil || !p.Valid() || limit < 1 || limit > 128 || after.At.IsZero() != (after.ID == 0) {
		return nil, socialinbox.ErrInvalidNotice
	}
	var at any
	if !after.At.IsZero() {
		at = after.At.UTC()
	}
	var raw string
	if e := t.QueryRow(c, noticePageSQL, int64(p), at, int64(after.ID), limit).Scan(&raw); e != nil {
		return nil, e
	}
	var rows []noticeRow
	if e := json.Unmarshal([]byte(raw), &rows); e != nil {
		return nil, e
	}
	out := make([]socialinbox.Notice, 0, len(rows))
	for _, r := range rows {
		out = append(out, socialinbox.Notice{RecipientPlayerID: identity.PlayerID(r.Recipient), NoticeID: socialinbox.NoticeID(r.ID), NoticeType: r.Type, Source: socialinbox.SourceKey{Kind: r.Kind, Key: r.Key}, RelatedPlayerID: identity.PlayerID(r.Related), RelatedPlayerDeleted: r.Related == 0, Active: r.Active, NoticeTime: r.At.UTC(), DismissedAt: r.Dismissed, StateVersion: r.Version, CreatedAt: r.Created.UTC(), UpdatedAt: r.Updated.UTC()})
	}
	return out, nil
}

var _ socialinbox.NoticePageReader = Store{}
