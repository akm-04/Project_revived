// Package commerceprivilegestore alone queries canonical Commerce privilege rows.
package commerceprivilegestore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

func (Store) ReadPrivilegeTx(c context.Context, q tx.Queryer, pid identity.PlayerID, lock bool) (d.State, bool, error) {
	var s d.State
	if q == nil || !pid.Valid() {
		return s, false, d.ErrUnavailable
	}
	sql := `SELECT player_id,logical_server_id,qualifying_charge,vip_level,monthly_state,content_revision,policy_version,origin_class,issuer,reason,state_version,created_at,updated_at FROM commerce_privilege_roots WHERE player_id=$1`
	if lock {
		sql += " FOR UPDATE"
	}
	e := q.QueryRow(c, sql, int64(pid)).Scan(&s.PlayerID, &s.LogicalServerID, &s.Charge, &s.VIPLevel, &s.MonthlyState, &s.ContentRevision, &s.PolicyVersion, &s.OriginClass, &s.Issuer, &s.Reason, &s.StateVersion, &s.CreatedAt, &s.UpdatedAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return d.State{}, false, nil
	}
	if e != nil {
		return d.State{}, false, e
	}
	return s, true, s.Validate()
}
func (Store) SavePrivilegeTx(c context.Context, t tx.Tx, oldVersion int64, s d.State) error {
	if t == nil || s.Validate() != nil || oldVersion < 0 || s.StateVersion != oldVersion+1 {
		return d.ErrConflict
	}
	if oldVersion == 0 {
		tag, e := t.Exec(c, `INSERT INTO commerce_privilege_roots(player_id,logical_server_id,qualifying_charge,vip_level,monthly_state,content_revision,policy_version,origin_class,issuer,reason,state_version,created_at,updated_at)VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13) ON CONFLICT(player_id)DO NOTHING`, int64(s.PlayerID), int64(s.LogicalServerID), s.Charge, s.VIPLevel, s.MonthlyState, s.ContentRevision, s.PolicyVersion, s.OriginClass, s.Issuer, s.Reason, s.StateVersion, s.CreatedAt, s.UpdatedAt)
		if e != nil {
			return e
		}
		if tag.RowsAffected() != 1 {
			return d.ErrConflict
		}
		return nil
	}
	tag, e := t.Exec(c, `UPDATE commerce_privilege_roots SET qualifying_charge=$3,vip_level=$4,content_revision=$5,issuer=$6,reason=$7,state_version=$8,updated_at=$9 WHERE player_id=$1 AND logical_server_id=$2 AND state_version=$10`, int64(s.PlayerID), int64(s.LogicalServerID), s.Charge, s.VIPLevel, s.ContentRevision, s.Issuer, s.Reason, s.StateVersion, s.UpdatedAt, oldVersion)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrConflict
	}
	return nil
}
