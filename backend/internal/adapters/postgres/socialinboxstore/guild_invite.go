package socialinboxstore

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/socialinbox"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (s Store) ReadInviteNoticeSourceTx(c context.Context, q tx.Queryer, pid identity.PlayerID, key socialinbox.SourceKey) (socialinbox.Notice, bool, error) {
	if q == nil {
		return socialinbox.Notice{}, false, gi.ErrEvidence
	}
	if _, e := socialinbox.InviteTuple(socialinbox.Notice{RecipientPlayerID: pid, NoticeType: gi.NoticeType, Source: key}); e != nil {
		return socialinbox.Notice{}, false, e
	}
	var id int64
	e := q.QueryRow(c, `SELECT notice_id FROM social_notices WHERE recipient_player_id=$1 AND source_kind=$2 AND source_key=$3`, int64(pid), key.Kind, key.Key).Scan(&id)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return socialinbox.Notice{}, false, nil
	}
	if e != nil {
		return socialinbox.Notice{}, false, e
	}
	return readNoticeEvidence(c, q, pid, socialinbox.NoticeID(id))
}

func (s Store) InsertInviteNoticeTx(c context.Context, t tx.Tx, v gi.Issue, at time.Time) (socialinbox.Notice, error) {
	key, e := v.Tuple.SourceKey()
	if e != nil || t == nil || v.Validate() != nil || at.Before(v.DecisionAt) {
		return socialinbox.Notice{}, gi.ErrEvidence
	}
	id, e := s.NextNoticeIDTx(c, t)
	if e != nil {
		return socialinbox.Notice{}, e
	}
	if !id.WireSafe() {
		return socialinbox.Notice{}, gi.ErrEvidence
	}
	n := socialinbox.Notice{RecipientPlayerID: v.Tuple.Recipient, NoticeID: id, NoticeType: gi.NoticeType, Source: socialinbox.SourceKey{Kind: gi.SourceKind, Key: key}, RelatedPlayerID: v.Inviter, Active: true, NoticeTime: v.DecisionAt, StateVersion: 1, CreatedAt: at.UTC(), UpdatedAt: at.UTC()}
	if socialinbox.MatchInvite(n, v) != nil {
		return n, gi.ErrEvidence
	}
	tag, e := t.Exec(c, `INSERT INTO social_notices(recipient_player_id,notice_id,notice_type,source_kind,source_key,related_player_id,active,notice_time,state_version,created_at,updated_at)VALUES($1,$2,10,$3,$4,$5,true,$6,1,$7,$7)`, int64(n.RecipientPlayerID), int64(n.NoticeID), n.Source.Kind, n.Source.Key, int64(n.RelatedPlayerID), n.NoticeTime, n.CreatedAt)
	if e != nil {
		return n, e
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return n, gi.ErrEvidence
	}
	return n, nil
}

func (Store) ConsumeInviteNoticeTx(c context.Context, t tx.Tx, n socialinbox.Notice, at time.Time) error {
	if t == nil || socialinbox.ValidateInviteLifecycle(n) != nil || socialinbox.PreflightConsumption(n, at) != nil {
		return gi.ErrEvidence
	}
	tag, e := t.Exec(c, `UPDATE social_notices SET active=false,dismissed_at=$4,updated_at=$4,state_version=state_version+1 WHERE recipient_player_id=$1 AND notice_id=$2 AND state_version=$3 AND active AND notice_type=10 AND source_kind=$5 AND source_key=$6`, int64(n.RecipientPlayerID), int64(n.NoticeID), n.StateVersion, at.UTC(), n.Source.Kind, n.Source.Key)
	if e != nil {
		return e
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return gi.ErrEvidence
	}
	return nil
}

func (Store) InsertInviteMaterializationTx(c context.Context, t tx.Tx, p gi.TargetProof) error {
	if t == nil || p.Validate() != nil {
		return gi.ErrEvidence
	}
	raw, e := json.Marshal(p)
	if e != nil {
		return e
	}
	var notice any
	if p.NoticeID != 0 {
		notice = p.NoticeID
	}
	tag, e := t.Exec(c, `INSERT INTO social_guild_invite_materializations(source_id,recipient_player_id,source_fingerprint,receipt_id,state,notice_id,root_version,target_payload,decision_at)VALUES($1::uuid,$2,$3,$4::uuid,$5,$6,$7,$8::jsonb,$9)`, p.SourceID.String(), int64(p.Recipient), hex.EncodeToString(p.SourceFingerprint[:]), p.ReceiptID.String(), string(p.State), notice, p.RootVersion, string(raw), p.DecisionAt)
	if e != nil {
		return e
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return gi.ErrEvidence
	}
	return nil
}

func (Store) ReadInviteMaterializationTx(c context.Context, q tx.Queryer, id ids.UUID) (gi.TargetProof, bool, error) {
	if q == nil || id.IsZero() {
		return gi.TargetProof{}, false, gi.ErrEvidence
	}
	var raw, fp, rr, state string
	var pid, notice, root int64
	var at time.Time
	e := q.QueryRow(c, `SELECT recipient_player_id,source_fingerprint,receipt_id::text,state,COALESCE(notice_id,0),root_version,target_payload::text,decision_at FROM social_guild_invite_materializations WHERE source_id=$1::uuid`, id.String()).Scan(&pid, &fp, &rr, &state, &notice, &root, &raw, &at)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return gi.TargetProof{}, false, nil
	}
	if e != nil {
		return gi.TargetProof{}, false, e
	}
	p, e := gi.DecodeTargetProof([]byte(raw))
	if e != nil || p.SourceID != id || int64(p.Recipient) != pid || hex.EncodeToString(p.SourceFingerprint[:]) != fp || p.ReceiptID.String() != rr || string(p.State) != state || p.NoticeID != notice || p.RootVersion != root || p.DecisionAt.UnixMicro() != at.UnixMicro() {
		return gi.TargetProof{}, false, gi.ErrEvidence
	}
	return p, true, nil
}

func (Store) InsertInviteInvalidationTx(c context.Context, t tx.Tx, p gi.InvalidationProof) error {
	if t == nil || p.Validate() != nil {
		return gi.ErrEvidence
	}
	raw, e := json.Marshal(p)
	if e != nil {
		return e
	}
	var notice any
	if p.NoticeID != 0 {
		notice = p.NoticeID
	}
	tag, e := t.Exec(c, `INSERT INTO social_guild_invite_invalidations(marker_id,source_id,source_serial,source_key,recipient_player_id,marker_fingerprint,source_fingerprint,receipt_id,notice_id,root_version,consumed,target_payload,decision_at)VALUES($1::uuid,$2::uuid,$12,$13,$3,$4,$5,$6::uuid,$7,$8,$9,$10::jsonb,$11)`, p.MarkerID.String(), p.SourceID.String(), int64(p.Recipient), hex.EncodeToString(p.MarkerFingerprint[:]), hex.EncodeToString(p.SourceFingerprint[:]), p.ReceiptID.String(), notice, p.RootVersion, p.Consumed, string(raw), p.DecisionAt, p.SourceSerial, p.SourceKey)
	if e != nil {
		return e
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return gi.ErrEvidence
	}
	return nil
}

func (Store) ReadInviteInvalidationTx(c context.Context, q tx.Queryer, marker, source ids.UUID) (gi.InvalidationProof, bool, error) {
	if q == nil || marker.IsZero() || source.IsZero() {
		return gi.InvalidationProof{}, false, gi.ErrEvidence
	}
	var raw, mfp, sfp, rr, sourceKey string
	var serial int64
	var pid, notice, root int64
	var consumed bool
	var at time.Time
	e := q.QueryRow(c, `SELECT recipient_player_id,marker_fingerprint,source_fingerprint,receipt_id::text,COALESCE(notice_id,0),root_version,consumed,target_payload::text,decision_at,source_serial,source_key FROM social_guild_invite_invalidations WHERE marker_id=$1::uuid AND source_id=$2::uuid`, marker.String(), source.String()).Scan(&pid, &mfp, &sfp, &rr, &notice, &root, &consumed, &raw, &at, &serial, &sourceKey)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return gi.InvalidationProof{}, false, nil
	}
	if e != nil {
		return gi.InvalidationProof{}, false, e
	}
	p, e := gi.DecodeInvalidationProof([]byte(raw))
	if e != nil || p.MarkerID != marker || p.SourceID != source || int64(p.Recipient) != pid || hex.EncodeToString(p.MarkerFingerprint[:]) != mfp || hex.EncodeToString(p.SourceFingerprint[:]) != sfp || p.ReceiptID.String() != rr || p.NoticeID != notice || p.RootVersion != root || p.Consumed != consumed || p.SourceSerial != serial || p.SourceKey != sourceKey || p.DecisionAt.UnixMicro() != at.UnixMicro() {
		return gi.InvalidationProof{}, false, gi.ErrEvidence
	}
	return p, true, nil
}

var _ socialinbox.GuildInviteStore = Store{}
