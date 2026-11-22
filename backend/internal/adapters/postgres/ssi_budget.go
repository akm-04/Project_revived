package postgres

import (
	"context"
	"fmt"

	ftx "gxb.local/backend/v2/internal/foundation/tx"
)

// SerializableLockBudget is C1 Tier 0 (C1_CAPACITY_DESIGN.md F3): below it, roster-sized SERIALIZABLE reads escalate
// predicate locks to whole relations and unrelated players abort each other with 40001.
// ops/testing/ssi_escalation_probe.py measures the effect on a cluster.
var SerializableLockBudget = struct{ PerTransaction, PerRelation, PerPage int }{1024, 512, 8}

// SerializableLockShortfall names each SSI setting of the connected cluster that is below SerializableLockBudget.
func SerializableLockShortfall(ctx context.Context, q ftx.Queryer) ([]string, error) {
	var perTransaction, perRelation, perPage int
	err := q.QueryRow(ctx, `SELECT current_setting('max_pred_locks_per_transaction')::int,
	current_setting('max_pred_locks_per_relation')::int, current_setting('max_pred_locks_per_page')::int`).
		Scan(&perTransaction, &perRelation, &perPage)
	if err != nil {
		return nil, err
	}
	// A negative per-relation value means max_pred_locks_per_transaction divided by its absolute value.
	if perRelation < 0 {
		perRelation = perTransaction / -perRelation
	}
	var short []string
	for _, setting := range []struct {
		name        string
		have, floor int
	}{
		{"max_pred_locks_per_transaction", perTransaction, SerializableLockBudget.PerTransaction},
		{"max_pred_locks_per_relation", perRelation, SerializableLockBudget.PerRelation},
		{"max_pred_locks_per_page", perPage, SerializableLockBudget.PerPage},
	} {
		if setting.have < setting.floor {
			short = append(short, fmt.Sprintf("%s=%d (want >= %d)", setting.name, setting.have, setting.floor))
		}
	}
	return short, nil
}
