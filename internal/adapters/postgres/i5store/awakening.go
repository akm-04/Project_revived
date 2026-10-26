package i5store

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadAwakeningTx(c context.Context, q tx.Queryer, p identity.PlayerID) (objective.AwakeRoot, error) {
	return readAwakening(c, q, p, false)
}

func (Store) LockAwakeningTx(c context.Context, t tx.Tx, p identity.PlayerID) (objective.AwakeRoot, error) {
	if t == nil || !p.Valid() {
		return objective.AwakeRoot{}, errors.New("invalid awakening root lock")
	}
	initial := objective.NewAwakeRoot()
	raw, e := json.Marshal(initial)
	if e != nil {
		return initial, e
	}
	if _, e = t.Exec(c, `INSERT INTO player_awakening_roots(player_id,state_version,payload)VALUES($1,1,$2::jsonb) ON CONFLICT(player_id)DO NOTHING`, int64(p), string(raw)); e != nil {
		return initial, e
	}
	return readAwakening(c, t, p, true)
}

func readAwakening(c context.Context, q tx.Queryer, p identity.PlayerID, lock bool) (objective.AwakeRoot, error) {
	if q == nil || !p.Valid() {
		return objective.AwakeRoot{}, errors.New("invalid awakening root read")
	}
	query := `SELECT state_version,payload::text FROM player_awakening_roots WHERE player_id=$1`
	if lock {
		query += " FOR UPDATE"
	}
	var version int64
	var raw string
	e := q.QueryRow(c, query, int64(p)).Scan(&version, &raw)
	if errors.Is(e, kernelstore.ErrNoRows) && !lock {
		return objective.NewAwakeRoot(), nil
	}
	if e != nil {
		return objective.AwakeRoot{}, e
	}
	var root objective.AwakeRoot
	if e = json.Unmarshal([]byte(raw), &root); e != nil {
		return root, e
	}
	if root.Version != version {
		return root, errors.New("awakening root version mismatch")
	}
	return root, root.Validate()
}

func (Store) SaveAwakeningTx(c context.Context, t tx.Tx, p identity.PlayerID, root objective.AwakeRoot, old int64) error {
	if t == nil || !p.Valid() || root.Validate() != nil || root.Version != old+1 {
		return errors.New("invalid awakening root CAS")
	}
	raw, e := json.Marshal(root)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `UPDATE player_awakening_roots SET state_version=$2,payload=$3::jsonb WHERE player_id=$1 AND state_version=$4`, int64(p), root.Version, string(raw), old)
	if e != nil {
		return e
	}
	return rowsOne(tag, "awakening root")
}
