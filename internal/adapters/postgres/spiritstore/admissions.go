package spiritstore

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/spirit"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) LockAdmissionTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, family string) (spirit.Admission, bool, error) {
	var d spirit.Admission
	var raw string
	var version int16
	var state, opID, revision, fp string
	e := t.QueryRow(ctx, `SELECT operation_context::text,payload_version,admission_state,operation_id::text,content_revision,request_fingerprint FROM player_spirit_admissions WHERE player_id=$1 AND family=$2 FOR UPDATE`, int64(pid), family).Scan(&raw, &version, &state, &opID, &revision, &fp)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return d, false, nil
	}
	if e != nil {
		return d, false, e
	}
	if e = payload.Decode("player_spirit_admissions", version, []byte(raw), &d); e != nil {
		return d, true, e
	}
	if d.State != state || d.Operation.ID.String() != opID || d.ContentRevision != revision || commandHash(d.Command) != fp || d.DecisionAt.IsZero() {
		return d, true, spirit.ErrProof
	}
	content, ok := d.Operation.Policies.Get("content")
	lp, ok2 := d.Operation.Policies.Get("spirit")
	roll, ok3 := d.Operation.Policies.Get("spirit_roll")
	if !ok || !ok2 || !ok3 || roll == "" || content != revision || lp != spirit.LifecyclePolicy {
		return d, true, spirit.ErrProof
	}
	d.State = state
	if d.Actor.Player != int64(pid) || family != "SPIRIT" || d.Command.Validate() != nil || d.Operation.ID.IsZero() {
		return d, true, spirit.ErrProof
	}
	return d, true, nil
}
func (Store) ReadAdmissionTx(ctx context.Context, t tx.Queryer, pid identity.PlayerID, family string) (spirit.Admission, bool, error) {
	var d spirit.Admission
	var raw string
	var version int16
	var state, opID, revision, fp string
	e := t.QueryRow(ctx, `SELECT operation_context::text,payload_version,admission_state,operation_id::text,content_revision,request_fingerprint FROM player_spirit_admissions WHERE player_id=$1 AND family=$2`, int64(pid), family).Scan(&raw, &version, &state, &opID, &revision, &fp)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return d, false, nil
	}
	if e != nil {
		return d, false, e
	}
	if e = payload.Decode("player_spirit_admissions", version, []byte(raw), &d); e != nil {
		return d, true, e
	}
	if d.State != state || d.Operation.ID.String() != opID || d.ContentRevision != revision || commandHash(d.Command) != fp || d.DecisionAt.IsZero() {
		return d, true, spirit.ErrProof
	}
	content, ok := d.Operation.Policies.Get("content")
	lp, ok2 := d.Operation.Policies.Get("spirit")
	roll, ok3 := d.Operation.Policies.Get("spirit_roll")
	if !ok || !ok2 || !ok3 || roll == "" || content != revision || lp != spirit.LifecyclePolicy {
		return d, true, spirit.ErrProof
	}
	d.State = state
	if d.Actor.Player != int64(pid) || family != "SPIRIT" || d.Command.Validate() != nil || d.Operation.ID.IsZero() {
		return d, true, spirit.ErrProof
	}
	return d, true, nil
}
func (Store) SaveAdmissionTx(ctx context.Context, t tx.Tx, d spirit.Admission) error {
	raw, version, e := payload.Encode(d)
	if e != nil {
		return e
	}
	_, e = t.Exec(ctx, `INSERT INTO player_spirit_admissions(player_id,family,operation_id,request_fingerprint,operation_context,payload_version,content_revision,admission_state,created_at,updated_at)VALUES($1,$2,$3::uuid,$4,$5::jsonb,$6,$7,$8,$9,$9)ON CONFLICT(player_id,family)DO UPDATE SET operation_id=EXCLUDED.operation_id,request_fingerprint=EXCLUDED.request_fingerprint,operation_context=EXCLUDED.operation_context,payload_version=EXCLUDED.payload_version,content_revision=EXCLUDED.content_revision,admission_state=EXCLUDED.admission_state,updated_at=EXCLUDED.updated_at`, d.Actor.Player, "SPIRIT", d.Operation.ID.String(), commandHash(d.Command), string(raw), version, d.ContentRevision, d.State, d.DecisionAt)
	return e
}

func commandHash(c spirit.Command) string {
	raw, _ := json.Marshal(c)
	h := sha256.Sum256(raw)
	return hex.EncodeToString(h[:])
}
