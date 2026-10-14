package i5store

import (
	"context"
	"errors"
	app "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (Store) ReadCoursePlayerStateTx(ctx context.Context, q tx.Queryer, p identity.PlayerID, at time.Time) (app.CoursePlayerState, error) {
	out := app.CoursePlayerState{Player: p}
	if q == nil || !p.Valid() || at.IsZero() {
		return out, errors.New("i5: invalid Course scope")
	}
	if e := q.QueryRow(ctx, `SELECT level,state_version,updated_at FROM player_progression WHERE player_id=$1`, int64(p)).Scan(&out.Level, &out.LevelVersion, &out.UpdatedAt); e != nil {
		return out, e
	}
	if out.Level < 1 || out.LevelVersion < 1 || at.Before(out.UpdatedAt) {
		return out, errors.New("i5: unqualified Course progression")
	}
	var id, ver *int64
	var key *string
	var opened *time.Time
	e := q.QueryRow(ctx, `SELECT function_id,state_version,source_fact_key,opened_at FROM (SELECT 1)singleton LEFT JOIN player_function_unlocks ON player_id=$1 AND function_id=51`, int64(p)).Scan(&id, &ver, &key, &opened)
	if e != nil {
		return out, e
	}
	if id != nil {
		if ver == nil || key == nil || opened == nil || *id != 51 || *ver < 1 || *key == "" || opened.IsZero() || at.Before(*opened) {
			return out, errors.New("i5: unqualified Course function")
		}
		out.Function = &app.DormFunctionFact{FunctionID: *id, StateVersion: *ver, SourceFactKey: *key, OpenedAt: *opened}
	}
	return out, nil
}
func (s Store) LockCoursePlayerStateTx(ctx context.Context, t tx.Tx, p identity.PlayerID, at time.Time) (app.CoursePlayerState, error) {
	if e := s.LockEconomyOwnerTx(ctx, t, p); e != nil {
		return app.CoursePlayerState{}, e
	}
	if _, e := s.LockProgressionTx(ctx, t, p); e != nil {
		return app.CoursePlayerState{}, e
	}
	return s.ReadCoursePlayerStateTx(ctx, t, p, at)
}
