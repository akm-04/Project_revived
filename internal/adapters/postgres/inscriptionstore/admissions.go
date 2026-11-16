package inscriptionstore

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/inscription"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) LockAdmissionTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, family string) (inscription.Admission, bool, error) {
	var d inscription.Admission
	var raw string
	var version int16
	var state, opID, revision, fp string
	e := t.QueryRow(ctx, `SELECT operation_context::text,payload_version,admission_state,operation_id::text,content_revision,request_fingerprint FROM player_inscription_admissions WHERE player_id=$1 AND family=$2 FOR UPDATE`, int64(pid), family).Scan(&raw, &version, &state, &opID, &revision, &fp)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return d, false, nil
	}
	if e != nil {
		return d, false, e
	}
	if e = payload.Decode("player_inscription_admissions", version, []byte(raw), &d); e != nil {
		return d, true, e
	}
	if d.State != state || d.Operation.ID.String() != opID || d.ContentRevision != revision || commandHash(d.Command) != fp || d.DecisionAt.IsZero() {
		return d, true, inscription.ErrProof
	}
	content, ok := d.Operation.Policies.Get("content")
	lp, ok2 := d.Operation.Policies.Get("inscription")
	if !ok || !ok2 || content != revision || lp != inscription.LifecyclePolicy {
		return d, true, inscription.ErrProof
	}
	d.State = state
	if d.Actor.Player != int64(pid) || family != "INSCRIPTION" || d.Command.Validate() != nil || d.Operation.ID.IsZero() {
		return d, true, inscription.ErrProof
	}
	return d, true, nil
}
func (Store) SaveAdmissionTx(ctx context.Context, t tx.Tx, d inscription.Admission) error {
	raw, version, e := payload.Encode(d)
	if e != nil {
		return e
	}
	_, e = t.Exec(ctx, `INSERT INTO player_inscription_admissions(player_id,family,operation_id,request_fingerprint,operation_context,payload_version,content_revision,admission_state,created_at,updated_at)VALUES($1,$2,$3::uuid,$4,$5::jsonb,$6,$7,$8,$9,$9)ON CONFLICT(player_id,family)DO UPDATE SET operation_id=EXCLUDED.operation_id,request_fingerprint=EXCLUDED.request_fingerprint,operation_context=EXCLUDED.operation_context,payload_version=EXCLUDED.payload_version,content_revision=EXCLUDED.content_revision,admission_state=EXCLUDED.admission_state,updated_at=EXCLUDED.updated_at`, d.Actor.Player, "INSCRIPTION", d.Operation.ID.String(), commandHash(d.Command), string(raw), version, d.ContentRevision, d.State, d.DecisionAt)
	return e
}

func commandHash(c inscription.Command) string {
	raw, _ := json.Marshal(c)
	h := sha256.Sum256(raw)
	return hex.EncodeToString(h[:])
}
