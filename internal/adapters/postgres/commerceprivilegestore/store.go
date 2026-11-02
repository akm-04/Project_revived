// Package commerceprivilegestore alone queries canonical Commerce privilege rows.
package commerceprivilegestore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
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
	tag, e := t.Exec(c, `UPDATE commerce_privilege_roots SET qualifying_charge=$3,vip_level=$4,content_revision=$5,issuer=$6,reason=$7,state_version=$8,updated_at=$9,policy_version=$11,origin_class=$12 WHERE player_id=$1 AND logical_server_id=$2 AND state_version=$10`, int64(s.PlayerID), int64(s.LogicalServerID), s.Charge, s.VIPLevel, s.ContentRevision, s.Issuer, s.Reason, s.StateVersion, s.UpdatedAt, oldVersion, s.PolicyVersion, s.OriginClass)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrConflict
	}
	return nil
}

// ReadPurchaseCountTx locks the product row; absence is a first purchase.
func (Store) ReadPurchaseCountTx(c context.Context, q tx.Queryer, pid identity.PlayerID, chargeID int64) (int64, error) {
	var count int64
	e := q.QueryRow(c, `SELECT charge_count FROM commerce_charge_purchases WHERE player_id=$1 AND charge_id=$2 FOR UPDATE`, int64(pid), chargeID).Scan(&count)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return 0, nil
	}
	return count, e
}

func (Store) SavePurchaseTx(c context.Context, t tx.Tx, pid identity.PlayerID, chargeID, buyTime int64) error {
	tag, e := t.Exec(c, `INSERT INTO commerce_charge_purchases(player_id,charge_id,charge_count,first_buy_time,last_buy_time)VALUES($1,$2,1,$3,$3)
ON CONFLICT(player_id,charge_id) DO UPDATE SET charge_count=commerce_charge_purchases.charge_count+1,last_buy_time=$3`, int64(pid), chargeID, buyTime)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrConflict
	}
	return nil
}

func readCards(c context.Context, q tx.Queryer, pid identity.PlayerID, suffix string) (d.Cards, error) {
	var out d.Cards
	e := q.QueryRow(c, `SELECT month_card_start,month_card_end,privilege_card_end FROM commerce_charge_cards WHERE player_id=$1`+suffix, int64(pid)).Scan(&out.MonthCardStart, &out.MonthCardEnd, &out.PrivilegeCardEnd)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return d.Cards{}, nil
	}
	return out, e
}

func (Store) ReadCardsTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (d.Cards, error) {
	return readCards(c, q, pid, "")
}

func (Store) LockCardsTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (d.Cards, error) {
	return readCards(c, q, pid, " FOR UPDATE")
}

func (Store) SaveCardsTx(c context.Context, t tx.Tx, pid identity.PlayerID, cards d.Cards, at time.Time) error {
	tag, e := t.Exec(c, `INSERT INTO commerce_charge_cards(player_id,month_card_start,month_card_end,privilege_card_end,updated_at)VALUES($1,$2,$3,$4,$5)
ON CONFLICT(player_id) DO UPDATE SET month_card_start=$2,month_card_end=$3,privilege_card_end=$4,updated_at=$5`, int64(pid), cards.MonthCardStart, cards.MonthCardEnd, cards.PrivilegeCardEnd, at)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrConflict
	}
	return nil
}

// ChargeTuningTx reads the operator overlay; found=false keeps the source policy.
func (Store) ChargeTuningTx(c context.Context, q tx.Queryer) (d.ChargeTuning, bool, error) {
	var raw string
	e := q.QueryRow(c, `SELECT payload::text FROM commerce_recharge_tuning`).Scan(&raw)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return d.ChargeTuning{}, false, nil
	}
	if e != nil {
		return d.ChargeTuning{}, false, e
	}
	var out d.ChargeTuning
	if json.Unmarshal([]byte(raw), &out) != nil || out.Validate() != nil {
		return d.ChargeTuning{}, false, nil
	}
	return out, true, nil
}
