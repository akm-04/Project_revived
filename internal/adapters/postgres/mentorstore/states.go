package mentorstore

import (
	"context"
	"encoding/json"
	"time"

	"gxb.local/backend/v2/internal/application/mentor"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) LockStateTx(ctx context.Context, t tx.Tx, player identity.PlayerID, server identity.LogicalServerID, at time.Time) (mentor.State, error) {
	if t == nil || !player.Valid() || !server.Valid() || logicalserver.PlayerRegion(player) != server || at.IsZero() {
		return mentor.State{}, domain.ErrInvalid
	}
	day := at.UTC().Format("2006-01-02")
	if _, err := t.Exec(ctx, `INSERT INTO mentor_states(player_id,logical_server_id,apply_day,apply_count_mentor,apply_count_student,state_version)VALUES($1,$2,$3,0,0,1) ON CONFLICT(player_id) DO NOTHING`, int64(player), int32(server), day); err != nil {
		return mentor.State{}, err
	}
	return scanState(t.QueryRow(ctx, `SELECT apply_day,apply_count_mentor,apply_count_student,broke_at,state_version FROM mentor_states WHERE player_id=$1 FOR UPDATE`, int64(player)), player, server)
}

func (Store) ReadStateTx(ctx context.Context, q tx.Queryer, player identity.PlayerID, server identity.LogicalServerID) (mentor.State, bool, error) {
	if q == nil || !player.Valid() || !server.Valid() || logicalserver.PlayerRegion(player) != server {
		return mentor.State{}, false, domain.ErrInvalid
	}
	var day time.Time
	var mentorCount, studentCount, version int64
	var brokeAt *time.Time
	err := q.QueryRow(ctx, `SELECT apply_day,apply_count_mentor,apply_count_student,broke_at,state_version FROM mentor_states WHERE player_id=$1 AND logical_server_id=$2`, int64(player), int32(server)).Scan(&day, &mentorCount, &studentCount, &brokeAt, &version)
	if err != nil {
		if isNoRows(err) {
			return mentor.State{}, false, nil
		}
		return mentor.State{}, false, err
	}
	return mentor.State{PlayerID: player, Server: server, ApplyDay: day.UTC(), CountMentor: mentorCount, CountStudent: studentCount, BrokeAt: brokeAt, Version: version}, true, nil
}

func scanState(row interface{ Scan(...any) error }, player identity.PlayerID, server identity.LogicalServerID) (mentor.State, error) {
	var day time.Time
	var mentorCount, studentCount, version int64
	var brokeAt *time.Time
	if err := row.Scan(&day, &mentorCount, &studentCount, &brokeAt, &version); err != nil {
		return mentor.State{}, err
	}
	return mentor.State{PlayerID: player, Server: server, ApplyDay: day.UTC(), CountMentor: mentorCount, CountStudent: studentCount, BrokeAt: brokeAt, Version: version}, nil
}

func (Store) WriteStateTx(ctx context.Context, t tx.Tx, previous, next mentor.State) error {
	if err := requireWritableTx(ctx, t); err != nil {
		return err
	}
	if !previous.PlayerID.Valid() || previous.PlayerID != next.PlayerID || previous.Server != next.Server || previous.Version < 1 || next.Version != previous.Version+1 {
		return domain.ErrInvalid
	}
	if next.CountMentor < 0 || next.CountStudent < 0 {
		return domain.ErrInvalid
	}
	result, err := t.Exec(ctx, `UPDATE mentor_states SET apply_day=$2,apply_count_mentor=$3,apply_count_student=$4,broke_at=$5,state_version=$6 WHERE player_id=$1 AND state_version=$7`, int64(previous.PlayerID), next.ApplyDay.UTC().Format("2006-01-02"), next.CountMentor, next.CountStudent, next.BrokeAt, next.Version, previous.Version)
	if err != nil {
		return err
	}
	if result.RowsAffected() != 1 {
		return domain.ErrRelationshipConflict
	}
	return nil
}

type candidateRelationJSON struct {
	MentorID  int64 `json:"mentor_id"`
	StudentID int64 `json:"student_id"`
}

// CandidateStatesTx returns the slot occupancy and break cooldown of a bounded
// candidate set in one logical server.
func (Store) CandidateStatesTx(ctx context.Context, q tx.Queryer, server identity.LogicalServerID, players []identity.PlayerID) (map[identity.PlayerID]mentor.CandidateState, error) {
	out := make(map[identity.PlayerID]mentor.CandidateState, len(players))
	if q == nil || !server.Valid() || len(players) == 0 || len(players) > 256 {
		return out, domain.ErrInvalid
	}
	ids := make([]int64, len(players))
	for index, player := range players {
		if !player.Valid() || logicalserver.PlayerRegion(player) != server {
			return map[identity.PlayerID]mentor.CandidateState{}, domain.ErrInvalid
		}
		ids[index] = int64(player)
		out[player] = mentor.CandidateState{}
	}
	var raw string
	if err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(to_jsonb(r)),'[]'::jsonb)::text FROM mentor_relations r WHERE logical_server_id=$1 AND ended_at IS NULL AND (mentor_id=ANY($2) OR student_id=ANY($2))`, int32(server), ids).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []candidateRelationJSON
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, domain.ErrRelationship
	}
	if len(rows) > 2*len(players) {
		return nil, domain.ErrRelationship
	}
	for _, row := range rows {
		if state, ok := out[identity.PlayerID(row.MentorID)]; ok {
			if state.HasStudent {
				return nil, domain.ErrRelationship
			}
			state.HasStudent = true
			state.StudentID = identity.PlayerID(row.StudentID)
			out[identity.PlayerID(row.MentorID)] = state
		}
		if state, ok := out[identity.PlayerID(row.StudentID)]; ok {
			if state.HasMentor {
				return nil, domain.ErrRelationship
			}
			state.HasMentor = true
			state.MentorID = identity.PlayerID(row.MentorID)
			out[identity.PlayerID(row.StudentID)] = state
		}
	}
	return out, nil
}

var _ = json.Marshal
