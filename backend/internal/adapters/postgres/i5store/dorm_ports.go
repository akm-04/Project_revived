package i5store

import (
	"context"
	"encoding/json"
	"errors"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (Store) ReadDormPlayerStateTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, observed time.Time) (appi5.DormPlayerState, error) {
	out := appi5.DormPlayerState{Player: pid, Functions: map[int64]appi5.DormFunctionFact{}}
	if q == nil || !pid.Valid() || observed.IsZero() {
		return out, errors.New("i5: invalid Dorm prerequisite scope")
	}
	if e := q.QueryRow(ctx, `SELECT level,state_version,updated_at FROM player_progression WHERE player_id=$1`, int64(pid)).Scan(&out.Level, &out.LevelVersion, &out.UpdatedAt); e != nil {
		return out, e
	}
	if out.Level <= 0 || out.LevelVersion <= 0 || observed.Before(out.UpdatedAt) {
		return out, errors.New("i5: unqualified Dorm progression")
	}
	var raw string
	if e := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('function_id',function_id,'state_version',state_version,'source_fact_key',source_fact_key,'opened_at',opened_at) ORDER BY function_id),'[]'::jsonb)::text FROM player_function_unlocks WHERE player_id=$1 AND function_id IN (71,72,73,74)`, int64(pid)).Scan(&raw); e != nil {
		return out, e
	}
	var facts []appi5.DormFunctionFact
	if e := json.Unmarshal([]byte(raw), &facts); e != nil {
		return out, e
	}
	for _, f := range facts {
		if f.FunctionID < 71 || f.FunctionID > 74 || f.StateVersion < 1 || f.SourceFactKey == "" || f.OpenedAt.IsZero() || observed.Before(f.OpenedAt) {
			return out, errors.New("i5: unqualified Dorm function")
		}
		out.Functions[f.FunctionID] = f
	}
	return out, nil
}

// Called before every physical I5 stack update/delete. Dorm-enabled production
// supplies StackUsage; nil is the inherited standalone composition with no Dorm
// capability. Activation wiring must not accept a nil usage provider.
func (s Store) requireRetainedStackTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, item, after int64) error {
	if s.StackUsage == nil {
		return nil
	}
	minimum, e := s.StackUsage.MinimumRetainedStackTx(ctx, t, pid, item)
	if e != nil {
		return e
	}
	if minimum < 0 || after < minimum {
		return errors.New("i5: stack is referenced by placed furniture")
	}
	return nil
}

// Canonical I5 suffix700/710 precedes any planned scalar720/stack722 locks.
// Functions are monotonic caller-snapshot observations; no lower owner locks
// are acquired here and no function or progression mutation is performed.
func (s Store) LockDormPlayerStateTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, at time.Time) (appi5.DormPlayerState, error) {
	if e := s.LockEconomyOwnerTx(ctx, t, pid); e != nil {
		return appi5.DormPlayerState{}, e
	}
	if _, e := s.LockProgressionTx(ctx, t, pid); e != nil {
		return appi5.DormPlayerState{}, e
	}
	return s.ReadDormPlayerStateTx(ctx, t, pid, at)
}
