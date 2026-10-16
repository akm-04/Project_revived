package characterstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/heroevolution"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

func (EvolutionStore) LockAdmissionTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, family string) (heroevolution.Admission, bool, error) {
	var d heroevolution.Admission
	var raw string
	var state, opID, revision, fp string
	e := t.QueryRow(ctx, `SELECT operation_context::text,admission_state,operation_id::text,content_revision,request_fingerprint FROM player_hero_evolution_admissions WHERE player_id=$1 AND family=$2 FOR UPDATE`, int64(pid), family).Scan(&raw, &state, &opID, &revision, &fp)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return d, false, nil
	}
	if e != nil {
		return d, false, e
	}
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&d); e != nil {
		return d, true, e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return d, true, heroevolution.ErrProof
	}
	if d.State != state || d.Operation.ID.String() != opID || d.ContentRevision != revision || commandHash(d.Command) != fp || d.DecisionAt.IsZero() {
		return d, true, heroevolution.ErrProof
	}
	content, ok := d.Operation.Policies.Get("content")
	lp, ok2 := d.Operation.Policies.Get("heroevolution")
	if !ok || !ok2 || content != revision || lp != heroevolution.LifecyclePolicy {
		return d, true, heroevolution.ErrProof
	}
	d.State = state
	if d.Actor.Player != int64(pid) || family != "EVOLUTION" || d.Command.Validate() != nil || d.Operation.ID.IsZero() {
		return d, true, heroevolution.ErrProof
	}
	return d, true, nil
}
func (EvolutionStore) SaveAdmissionTx(ctx context.Context, t tx.Tx, d heroevolution.Admission) error {
	raw, e := json.Marshal(d)
	if e != nil {
		return e
	}
	_, e = t.Exec(ctx, `INSERT INTO player_hero_evolution_admissions(player_id,family,operation_id,request_fingerprint,operation_context,content_revision,admission_state,created_at,updated_at)VALUES($1,$2,$3::uuid,$4,$5::jsonb,$6,$7,$8,$8)ON CONFLICT(player_id,family)DO UPDATE SET operation_id=EXCLUDED.operation_id,request_fingerprint=EXCLUDED.request_fingerprint,operation_context=EXCLUDED.operation_context,content_revision=EXCLUDED.content_revision,admission_state=EXCLUDED.admission_state,updated_at=EXCLUDED.updated_at`, d.Actor.Player, "EVOLUTION", d.Operation.ID.String(), commandHash(d.Command), string(raw), d.ContentRevision, d.State, d.DecisionAt)
	return e
}

func commandHash(c heroevolution.Command) string {
	raw, _ := json.Marshal(c)
	h := sha256.Sum256(raw)
	return hex.EncodeToString(h[:])
}
