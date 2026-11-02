package i5store

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// LockMissionRootTx must precede mission children and the I5 value-lock suffix.
func (Store) LockMissionRootTx(ctx context.Context, t tx.Tx, player identity.PlayerID, at time.Time) (objective.MissionRoot, error) {
	initial, err := objective.NewMissionRoot(player, at)
	if err != nil || t == nil {
		return objective.MissionRoot{}, errors.New("invalid mission root lock input")
	}
	if _, err := t.Exec(ctx, `INSERT INTO player_mission_roots(player_id,day,week) VALUES($1,$2,$3) ON CONFLICT(player_id) DO NOTHING`, int64(player), initial.Day, initial.Week); err != nil {
		return objective.MissionRoot{}, err
	}
	return readMissionRoot(ctx, t, player, true)
}

func (Store) ReadMissionRootTx(ctx context.Context, q tx.Queryer, player identity.PlayerID) (objective.MissionRoot, error) {
	return readMissionRoot(ctx, q, player, false)
}

func readMissionRoot(ctx context.Context, q tx.Queryer, player identity.PlayerID, lock bool) (objective.MissionRoot, error) {
	if q == nil || !player.Valid() {
		return objective.MissionRoot{}, errors.New("invalid mission root read input")
	}
	query := `SELECT day,week,day_huoyue,week_huoyue,day_award,week_award,battlepass_score,state_version FROM player_mission_roots WHERE player_id=$1`
	if lock {
		query += " FOR UPDATE"
	}
	root := objective.MissionRoot{PlayerID: player}
	err := q.QueryRow(ctx, query, int64(player)).Scan(&root.Day, &root.Week, &root.DayHuoyue, &root.WeekHuoyue, &root.DayAward, &root.WeekAward, &root.BattlepassScore, &root.StateVersion)
	if err != nil {
		return objective.MissionRoot{}, err
	}
	return root, root.Validate()
}

func (Store) SaveMissionRootTx(ctx context.Context, t tx.Tx, root objective.MissionRoot, old int64) error {
	if err := root.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `UPDATE player_mission_roots SET day=$2,week=$3,day_huoyue=$4,week_huoyue=$5,day_award=$6,week_award=$7,battlepass_score=$8,state_version=$9 WHERE player_id=$1 AND state_version=$10`,
		int64(root.PlayerID), root.Day, root.Week, root.DayHuoyue, root.WeekHuoyue, root.DayAward, root.WeekAward, root.BattlepassScore, root.StateVersion, old)
	if err != nil {
		return err
	}
	return rowsOne(tag, "mission root")
}

func (Store) DeletePreviousDailyMissionsTx(ctx context.Context, t tx.Tx, player identity.PlayerID, generation string) error {
	if !player.Valid() || generation == "" {
		return errors.New("daily mission occurrence required")
	}
	_, err := t.Exec(ctx, `DELETE FROM player_mission_instances WHERE player_id=$1 AND program_id='mission:1' AND generation_id<>$2`, int64(player), generation)
	return err
}

func (Store) InsertMissionInstanceTx(ctx context.Context, t tx.Tx, instance objective.Instance) error {
	if err := instance.Validate(); err != nil {
		return err
	}
	if len(instance.ContentRevision) != 64 || instance.ClaimState != objective.Unclaimed {
		return errors.New("new mission requires pinned content and unclaimed state")
	}
	tag, err := t.Exec(ctx, `INSERT INTO player_mission_instances(player_id,program_id,objective_id,generation_id,definition_revision,content_revision,progress,completed_at,claim_state,claimed_at,state_version)
VALUES($1,$2,$3,$4,$5,$6,$7,$8,'UNCLAIMED',NULL,$9)`, int64(instance.PlayerID), instance.ProgramID, instance.ObjectiveID, instance.GenerationID, instance.DefinitionRevision, instance.ContentRevision, instance.Progress, instance.CompletedAt, instance.StateVersion)
	if err != nil {
		return err
	}
	return rowsOne(tag, "new mission")
}

func (Store) ListMissionInstancesTx(ctx context.Context, q tx.Queryer, player identity.PlayerID) ([]objective.Instance, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'program_id',program_id,'objective_id',objective_id,'generation_id',generation_id,'definition_revision',definition_revision,'content_revision',content_revision,'progress',progress,'completed_at',completed_at,'claim_state',claim_state,'claimed_at',claimed_at,'state_version',state_version) ORDER BY objective_id,generation_id),'[]'::jsonb)::text FROM player_mission_instances WHERE player_id=$1 AND definition_revision='I9_MISSIONS_V1'`, int64(player)).Scan(&raw)
	if err != nil {
		return nil, err
	}
	instances, _, err := decodeObjectiveRows([]byte(raw))
	return instances, err
}
