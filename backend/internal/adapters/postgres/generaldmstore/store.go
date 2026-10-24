package generaldmstore

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5/pgconn"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	dm "gxb.local/backend/v2/internal/application/generaldm"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{}

func one(c context.Context, t tx.Tx, sql string, args ...any) error {
	tag, e := t.Exec(c, sql, args...)
	if e != nil {
		return e
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return dm.ErrChanged
	}
	return nil
}
func (Store) InsertTx(c context.Context, t tx.Tx, i dm.Intent) error {
	if t == nil || i.Validate() != nil {
		return dm.ErrInvalid
	}
	raw, e := json.Marshal(i)
	if e != nil {
		return e
	}
	h := sha256.Sum256(raw)
	payloadDigest := hex.EncodeToString(h[:])
	e = one(c, t, `INSERT INTO personal_dm_intents(operation_id,operation_digest,sender_id,recipient_id,accepted_at,expires_at,block_version,policy_id,payload_binding_digest)VALUES($1::uuid,$2,$3,$4,$5,$6,$7,$8,$9)`, i.ID, i.Digest, i.Sender, i.Recipient, i.AcceptedAt, i.ExpiresAt, i.BlockVersion, dm.PolicyID, payloadDigest)
	if e != nil {
		var pg *pgconn.PgError
		if errors.As(e, &pg) && pg.Code == "23505" && pg.ConstraintName == "personal_dm_intents_pkey" {
			return tx.MarkDefiniteAbort(e)
		}
		return e
	}
	if e = one(c, t, `INSERT INTO personal_dm_payloads(operation_id,payload)VALUES($1::uuid,$2::jsonb)`, i.ID, string(raw)); e != nil {
		return e
	}
	return one(c, t, `INSERT INTO personal_dm_delivery(operation_id,status,state_version,claim_generation,owner_fence,last_observed_at,updated_at)VALUES($1::uuid,'PENDING',1,0,0,$2,$2)`, i.ID, i.LastObservedAt)
}
func (Store) UpdateTx(c context.Context, t tx.Tx, i dm.Intent, before int64, at time.Time) error {
	if t == nil || i.Validate() != nil || i.StateVersion != before+1 || at.IsZero() {
		return dm.ErrInvalid
	}
	var receipt any
	if i.Status.Terminal() {
		r, _ := json.Marshal(map[string]any{"operation_id": i.ID, "digest": i.Digest, "status": i.Status, "expires_at": i.ExpiresAt, "completion_upper": i.CompletionUpper})
		receipt = string(r)
	}
	if e := one(c, t, `UPDATE personal_dm_delivery SET status=$3,state_version=$4,claim_generation=$5,owner_fence=$6,lease_expires_at=$7,attempt_committed_at=$8,completion_upper_at=$9,last_observed_at=$10,updated_at=$10,terminal_receipt=$11::jsonb WHERE operation_id=$1::uuid AND state_version=$2 AND status NOT IN('WRITTEN_BEFORE_DEADLINE','UNDELIVERED','EXPIRED','PRIVACY_SUPPRESSED','ADMISSION_RETIRED','TIME_INVALID','UNKNOWN')`, i.ID, before, string(i.Status), i.StateVersion, i.ClaimGeneration, i.OwnerFence, i.LeaseExpiresAt, i.AttemptCommittedAt, i.CompletionUpper, at, receipt); e != nil {
		return e
	}
	if i.Status.Terminal() {
		_, e := t.Exec(c, `DELETE FROM personal_dm_payloads WHERE operation_id=$1::uuid`, i.ID)
		return e
	}
	return nil
}
func find(c context.Context, q tx.Queryer, id string, lock bool) (dm.Intent, bool, error) {
	var i dm.Intent
	var raw []byte
	var status string
	if q == nil || id == "" {
		return i, false, dm.ErrInvalid
	}
	sql := `SELECT i.operation_id::text,i.operation_digest,i.sender_id,i.recipient_id,i.accepted_at,i.expires_at,i.block_version,i.payload_binding_digest,p.payload,d.status,d.state_version,d.claim_generation,d.owner_fence,d.lease_expires_at,d.last_observed_at,d.attempt_committed_at,d.completion_upper_at FROM personal_dm_intents i JOIN personal_dm_delivery d USING(operation_id) LEFT JOIN personal_dm_payloads p USING(operation_id) WHERE i.operation_id=$1::uuid`
	if lock {
		sql += " FOR UPDATE OF d"
	}
	var id0, digest, payloadDigest string
	var sender, recipient, block int64
	var accepted, expires, last time.Time
	var version, claim, fence int64
	var lease, attempt, upper *time.Time
	e := q.QueryRow(c, sql, id).Scan(&id0, &digest, &sender, &recipient, &accepted, &expires, &block, &payloadDigest, &raw, &status, &version, &claim, &fence, &lease, &last, &attempt, &upper)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return i, false, nil
	}
	if e != nil {
		return i, false, e
	}
	if len(raw) > 0 {
		if e = json.Unmarshal(raw, &i); e != nil {
			return i, false, e
		}
		canonical, e := json.Marshal(i)
		if e != nil {
			return i, false, e
		}
		h := sha256.Sum256(canonical)
		if hex.EncodeToString(h[:]) != payloadDigest {
			return dm.Intent{}, false, dm.ErrInvalid
		}
	}
	i.ID = id0
	i.Digest = digest
	i.Sender = sender
	i.Recipient = recipient
	i.BlockVersion = block
	i.AcceptedAt = accepted.UTC()
	i.ExpiresAt = expires.UTC()
	i.Status = dm.Status(status)
	i.StateVersion = version
	i.ClaimGeneration = claim
	i.OwnerFence = fence
	i.LeaseExpiresAt = lease
	i.LastObservedAt = last.UTC()
	i.AttemptCommittedAt = attempt
	i.CompletionUpper = upper
	return i, true, i.Validate()
}
func (Store) Find(c context.Context, q tx.Queryer, id string) (dm.Intent, bool, error) {
	return find(c, q, id, false)
}
func (Store) Lock(c context.Context, t tx.Tx, id string) (dm.Intent, bool, error) {
	return find(c, t, id, true)
}

func (Store) HighWater(c context.Context, q tx.Queryer) (string, error) {
	var v string
	e := q.QueryRow(c, `SELECT COALESCE(max(to_char(i.accepted_at AT TIME ZONE 'UTC','YYYYMMDDHH24MISSUS')||':'||d.operation_id::text),'') FROM personal_dm_delivery d JOIN personal_dm_intents i USING(operation_id) WHERE d.status IN('PENDING','CLAIMED','ATTEMPTING')`).Scan(&v)
	return v, e
}
func (Store) Page(c context.Context, q tx.Queryer, after, high string, limit int) ([]string, error) {
	if limit < 1 || limit > 64 {
		return nil, dm.ErrInvalid
	}
	var raw []byte
	e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(operation_id::text ORDER BY accepted_at,operation_id),'[]'::jsonb) FROM(SELECT d.operation_id,i.accepted_at FROM personal_dm_delivery d JOIN personal_dm_intents i USING(operation_id) WHERE d.status IN('PENDING','CLAIMED','ATTEMPTING') AND (to_char(i.accepted_at AT TIME ZONE 'UTC','YYYYMMDDHH24MISSUS')||':'||d.operation_id::text)>$1 AND (to_char(i.accepted_at AT TIME ZONE 'UTC','YYYYMMDDHH24MISSUS')||':'||d.operation_id::text)<=$2 ORDER BY i.accepted_at,d.operation_id LIMIT $3)p`, after, high, limit).Scan(&raw)
	var out []string
	if e == nil {
		e = json.Unmarshal(raw, &out)
	}
	return out, e
}

var _ dm.Store = Store{}
