package frienddmstore

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5/pgconn"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	dm "gxb.local/backend/v2/internal/application/frienddm"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{}

const occurrenceJSON = `jsonb_build_object('id',o.occurrence_id::text,'digest',o.operation_digest,'sender',o.sender_id,'recipient',o.recipient_id,'sequence',o.recipient_sequence,'accepted_at',o.accepted_at,'message',o.message,'friendship_generation',o.friendship_generation,'recipient_block_version',o.recipient_block_version,'content_revision',o.content_revision,'emoticon_id',o.emoticon_id,'entitlement_version',o.entitlement_version)`

func (Store) Snapshot(c context.Context, q tx.Queryer, id identity.PlayerID, lock bool) (dm.Manifest, error) {
	m := dm.Manifest{Recipient: id, Rows: []dm.Delivery{}}
	if q == nil || !id.Valid() {
		return m, dm.ErrInvalid
	}
	sql := `SELECT state_version,next_sequence,last_decision_at FROM friend_dm_roots WHERE recipient_id=$1`
	if lock {
		sql += ` FOR UPDATE`
	}
	e := q.QueryRow(c, sql, int64(id)).Scan(&m.Version, &m.NextSequence, &m.LastDecisionAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return m, nil
	}
	if e != nil {
		return m, e
	}
	var raw []byte
	e = q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('occurrence',`+occurrenceJSON+`,'status',d.status,'version',d.state_version,'claim_generation',d.claim_generation,'owner_fence',d.owner_fence,'expires_at',d.expires_at,'updated_at',d.updated_at) ORDER BY o.recipient_sequence),'[]'::jsonb) FROM friend_dm_occurrences o JOIN friend_dm_delivery d USING(occurrence_id) WHERE d.recipient_id=$1 AND d.status='PENDING'`, int64(id)).Scan(&raw)
	if e != nil {
		return m, e
	}
	if e = json.Unmarshal(raw, &m.Rows); e != nil {
		return m, e
	}
	m.LastDecisionAt = m.LastDecisionAt.UTC()
	for i := range m.Rows {
		d := &m.Rows[i]
		d.Occurrence.AcceptedAt = d.Occurrence.AcceptedAt.UTC()
		d.UpdatedAt = d.UpdatedAt.UTC()
		if d.ExpiresAt != nil {
			at := d.ExpiresAt.UTC()
			d.ExpiresAt = &at
		}
	}
	return m, m.Validate()
}
func (Store) FindOccurrence(c context.Context, q tx.Queryer, id string) (dm.Occurrence, bool, error) {
	var raw []byte
	var o dm.Occurrence
	e := q.QueryRow(c, `SELECT `+occurrenceJSON+` FROM friend_dm_occurrences o WHERE occurrence_id=$1::uuid`, id).Scan(&raw)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return o, false, nil
	}
	if e != nil {
		return o, false, e
	}
	if e = json.Unmarshal(raw, &o); e != nil {
		return o, false, e
	}
	o.AcceptedAt = o.AcceptedAt.UTC()
	return o, true, o.Validate()
}
func (Store) FindProjection(c context.Context, q tx.Queryer, id string) (dm.ProjectionReceipt, bool, error) {
	r := dm.ProjectionReceipt{OperationID: id}
	var pid int64
	var raw []byte
	e := q.QueryRow(c, `SELECT recipient_id,manifest_digest,projected_at,messages FROM friend_dm_projection_receipts WHERE operation_id=$1::uuid`, id).Scan(&pid, &r.ManifestDigest, &r.ObservedAt, &raw)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return r, false, nil
	}
	if e != nil {
		return r, false, e
	}
	r.Recipient = identity.PlayerID(pid)
	e = json.Unmarshal(raw, &r.Messages)
	if e != nil {
		return r, false, e
	}
	if r.Messages == nil || len(r.Messages) > 50 {
		return r, false, dm.ErrInvalid
	}
	if !r.Recipient.Valid() || len(r.ManifestDigest) != 64 || r.ObservedAt.IsZero() {
		return r, false, dm.ErrInvalid
	}
	for _, m := range r.Messages {
		if m.Validate() != nil {
			return r, false, dm.ErrInvalid
		}
	}
	r.ObservedAt = r.ObservedAt.UTC()
	return r, true, nil
}
func one(c context.Context, t tx.Tx, sql string, args ...any) error {
	tag, e := t.Exec(c, sql, args...)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return dm.ErrManifestChanged
	}
	return nil
}
func (Store) InsertTx(c context.Context, t tx.Tx, m dm.Manifest, o dm.Occurrence) error {
	if m.Validate() != nil || o.Validate() != nil || o.Recipient != m.Recipient || o.AcceptedAt.Before(m.LastDecisionAt) {
		return dm.ErrInvalid
	}
	if m.Version == 0 {
		if o.Sequence != 1 {
			return dm.ErrInvalid
		}
		if e := one(c, t, `INSERT INTO friend_dm_roots(recipient_id,state_version,next_sequence,last_decision_at)VALUES($1,1,2,$2)`, int64(o.Recipient), o.AcceptedAt); e != nil {
			var pg *pgconn.PgError
			if errors.As(e, &pg) && pg.Code == "23505" && pg.ConstraintName == "friend_dm_roots_pkey" {
				return tx.MarkDefiniteAbort(e)
			}
			return e
		}
	} else {
		if o.Sequence != m.NextSequence {
			return dm.ErrInvalid
		}
		if e := one(c, t, `UPDATE friend_dm_roots SET state_version=state_version+1,next_sequence=next_sequence+1,last_decision_at=$3 WHERE recipient_id=$1 AND state_version=$2`, int64(o.Recipient), m.Version, o.AcceptedAt); e != nil {
			return e
		}
	}
	if e := one(c, t, `INSERT INTO friend_dm_occurrences(occurrence_id,operation_digest,sender_id,recipient_id,recipient_sequence,accepted_at,message,friendship_generation,recipient_block_version,content_revision,emoticon_id,entitlement_version,policy_id)VALUES($1::uuid,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,'FRIEND_DM_PENDING_V1')`, o.ID, o.Digest, int64(o.Sender), int64(o.Recipient), o.Sequence, o.AcceptedAt, o.Message, o.FriendshipGeneration, o.RecipientBlockVersion, o.ContentRevision, o.EmoticonID, o.EntitlementVersion); e != nil {
		return e
	}
	if e := one(c, t, `INSERT INTO friend_dm_delivery(occurrence_id,recipient_id,status,state_version,claim_generation,owner_fence,updated_at)VALUES($1::uuid,$2,'PENDING',1,0,0,$3)`, o.ID, int64(o.Recipient), o.AcceptedAt); e != nil {
		return e
	}
	// Current manifest <=50. The accepted 51st suppresses exactly its oldest,
	// including a claimed oldest. No immutable occurrence is deleted.
	if len(m.Rows) == dm.PendingLimit {
		d := m.Rows[0]
		return one(c, t, `UPDATE friend_dm_delivery SET status='RETENTION_SUPPRESSED',state_version=state_version+1,claim_generation=claim_generation+1,owner_fence=0,expires_at=NULL,updated_at=$3 WHERE occurrence_id=$1::uuid AND status='PENDING' AND state_version=$2`, d.Occurrence.ID, d.Version, o.AcceptedAt)
	}
	return nil
}
func (Store) ApplyTx(c context.Context, t tx.Tx, m dm.Manifest, changes []dm.Change, at time.Time) error {
	if m.Validate() != nil || at.IsZero() || at.Before(m.LastDecisionAt) {
		return dm.ErrInvalid
	}
	if len(changes) == 0 {
		return nil
	}
	if m.Version == 0 {
		return dm.ErrInvalid
	}
	allowed := map[string]dm.Delivery{}
	for _, d := range m.Rows {
		allowed[d.Occurrence.ID] = d
	}
	seen := map[string]bool{}
	for _, v := range changes {
		before, ok := allowed[v.Before.Occurrence.ID]
		if !ok || seen[before.Occurrence.ID] || before.Version != v.Before.Version || before.Status != dm.Pending || !v.Status.Valid() || !v.At.Equal(at) || v.ClaimGeneration < before.ClaimGeneration || at.Before(before.UpdatedAt) {
			return dm.ErrInvalid
		}
		seen[before.Occurrence.ID] = true
		after := before
		after.Status = v.Status
		after.ClaimGeneration = v.ClaimGeneration
		after.OwnerFence = v.OwnerFence
		after.ExpiresAt = v.ExpiresAt
		after.UpdatedAt = at
		after.Version++
		if after.Validate() != nil {
			return dm.ErrInvalid
		}
	}
	// Entire transition preflight occurs before the first mutation.
	if e := one(c, t, `UPDATE friend_dm_roots SET state_version=state_version+1,last_decision_at=$3 WHERE recipient_id=$1 AND state_version=$2`, int64(m.Recipient), m.Version, at); e != nil {
		return e
	}
	for _, v := range changes {
		if e := one(c, t, `UPDATE friend_dm_delivery SET status=$3,state_version=state_version+1,claim_generation=$4,owner_fence=$5,expires_at=$6,updated_at=$7 WHERE occurrence_id=$1::uuid AND state_version=$2 AND status='PENDING'`, v.Before.Occurrence.ID, v.Before.Version, string(v.Status), v.ClaimGeneration, v.OwnerFence, v.ExpiresAt, at); e != nil {
			return e
		}
	}
	return nil
}
func (Store) InsertProjectionTx(c context.Context, t tx.Tx, r dm.ProjectionReceipt) error {
	if r.OperationID == "" || !r.Recipient.Valid() || len(r.ManifestDigest) != 64 || r.ObservedAt.IsZero() || r.Messages == nil || len(r.Messages) > 50 {
		return dm.ErrInvalid
	}
	raw, e := json.Marshal(r.Messages)
	if e != nil {
		return e
	}
	return one(c, t, `INSERT INTO friend_dm_projection_receipts(operation_id,recipient_id,manifest_digest,projected_at,messages)VALUES($1::uuid,$2,$3,$4,$5::jsonb)`, r.OperationID, int64(r.Recipient), r.ManifestDigest, r.ObservedAt, string(raw))
}
func (Store) PendingRecipients(c context.Context, q tx.Queryer, after, high identity.PlayerID, limit int) ([]identity.PlayerID, error) {
	if after < 0 || high < 0 || limit < 1 || limit > 64 {
		return nil, dm.ErrInvalid
	}
	var raw []byte
	e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(recipient_id ORDER BY recipient_id),'[]'::jsonb) FROM (SELECT DISTINCT recipient_id FROM friend_dm_delivery WHERE status='PENDING' AND recipient_id>$1 AND recipient_id<=$2 ORDER BY recipient_id LIMIT $3) s`, int64(after), int64(high), limit).Scan(&raw)
	if e != nil {
		return nil, e
	}
	ids := []identity.PlayerID{}
	e = json.Unmarshal(raw, &ids)
	return ids, e
}
func (Store) PendingHighWater(c context.Context, q tx.Queryer) (identity.PlayerID, error) {
	var high int64
	e := q.QueryRow(c, `SELECT COALESCE(max(recipient_id),0) FROM friend_dm_delivery WHERE status='PENDING'`).Scan(&high)
	return identity.PlayerID(high), e
}

var _ dm.Store = Store{}

func (Store) ReferencePending(c context.Context, q tx.Queryer, r dm.Reference) (bool, error) {
	if _, e := r.Encode(); e != nil {
		return false, e
	}
	var ok bool
	e := q.QueryRow(c, `SELECT EXISTS(SELECT 1 FROM friend_dm_delivery d JOIN friend_dm_occurrences o USING(occurrence_id) WHERE o.occurrence_id=$1::uuid AND o.recipient_id=$2 AND d.recipient_id=$2 AND d.state_version=$3 AND d.status='PENDING')`, r.OccurrenceID, int64(r.Recipient), r.Version).Scan(&ok)
	return ok, e
}
