package mentorstore

import (
	"context"
	"encoding/json"
	"time"

	"gxb.local/backend/v2/internal/application/mentor"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type progressJSON struct {
	MissionID   int64      `json:"mission_id"`
	Progress    int64      `json:"progress"`
	CompletedAt *time.Time `json:"completed_at"`
	AwardedAt   *time.Time `json:"awarded_at"`
	Version     int64      `json:"state_version"`
}

func (Store) ReadMissionProgressTx(ctx context.Context, q tx.Queryer, player identity.PlayerID) ([]mentor.MissionProgress, error) {
	if q == nil || !player.Valid() {
		return nil, domain.ErrMission
	}
	var raw string
	if err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(to_jsonb(p) ORDER BY mission_id),'[]'::jsonb)::text FROM mentor_mission_progress p WHERE player_id=$1`, int64(player)).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []progressJSON
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, domain.ErrMission
	}
	out := make([]mentor.MissionProgress, 0, len(rows))
	for _, row := range rows {
		if row.MissionID <= 0 || row.Progress < 0 || row.Version < 1 {
			return nil, domain.ErrMission
		}
		out = append(out, mentor.MissionProgress{PlayerID: player, MissionID: row.MissionID, Progress: row.Progress, CompletedAt: utcPointer(row.CompletedAt), AwardedAt: utcPointer(row.AwardedAt), Version: row.Version})
	}
	return out, nil
}

func (Store) LockMissionProgressTx(ctx context.Context, t tx.Tx, player identity.PlayerID, mission int64) (mentor.MissionProgress, bool, error) {
	if t == nil || !player.Valid() || mission <= 0 {
		return mentor.MissionProgress{}, false, domain.ErrMission
	}
	var raw string
	err := t.QueryRow(ctx, `SELECT to_jsonb(p)::text FROM mentor_mission_progress p WHERE player_id=$1 AND mission_id=$2 FOR UPDATE`, int64(player), mission).Scan(&raw)
	if err != nil {
		if isNoRows(err) {
			return mentor.MissionProgress{PlayerID: player, MissionID: mission}, false, nil
		}
		return mentor.MissionProgress{}, false, err
	}
	var row progressJSON
	if err := json.Unmarshal([]byte(raw), &row); err != nil {
		return mentor.MissionProgress{}, false, domain.ErrMission
	}
	if row.MissionID != mission || row.Progress < 0 || row.Version < 1 {
		return mentor.MissionProgress{}, false, domain.ErrMission
	}
	return mentor.MissionProgress{PlayerID: player, MissionID: mission, Progress: row.Progress, CompletedAt: utcPointer(row.CompletedAt), AwardedAt: utcPointer(row.AwardedAt), Version: row.Version}, true, nil
}

func (Store) PutMissionProgressTx(ctx context.Context, t tx.Tx, previous *mentor.MissionProgress, next mentor.MissionProgress) error {
	if err := requireWritableTx(ctx, t); err != nil {
		return err
	}
	if !next.PlayerID.Valid() || next.MissionID <= 0 || next.Progress < 0 || next.Version < 1 {
		return domain.ErrMission
	}
	if previous == nil {
		result, err := t.Exec(ctx, `INSERT INTO mentor_mission_progress(player_id,mission_id,progress,completed_at,awarded_at,state_version)VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT(player_id,mission_id) DO NOTHING`, int64(next.PlayerID), next.MissionID, next.Progress, next.CompletedAt, next.AwardedAt, next.Version)
		if err != nil {
			return err
		}
		if result.RowsAffected() != 1 {
			return domain.ErrRelationshipConflict
		}
		return nil
	}
	result, err := t.Exec(ctx, `UPDATE mentor_mission_progress SET progress=$3,completed_at=$4,awarded_at=$5,state_version=$6 WHERE player_id=$1 AND mission_id=$2 AND state_version=$7`, int64(next.PlayerID), next.MissionID, next.Progress, next.CompletedAt, next.AwardedAt, next.Version, previous.Version)
	if err != nil {
		return err
	}
	if result.RowsAffected() != 1 {
		return domain.ErrRelationshipConflict
	}
	return nil
}

func decodeExam(student identity.PlayerID, mission int64, relationID string, wonAt time.Time, version int64, payloadVersion int16, itemsRaw string) (mentor.ExamReceipt, error) {
	relation, err := ids.ParseUUID(relationID)
	if err != nil || version < 1 || wonAt.IsZero() {
		return mentor.ExamReceipt{}, domain.ErrRelationship
	}
	var items []mentor.ExamItem
	if err = payload.Decode("mentor_exam_receipts", payloadVersion, []byte(itemsRaw), &items); err != nil {
		return mentor.ExamReceipt{}, domain.ErrRelationship
	}
	return mentor.ExamReceipt{StudentID: student, MissionID: mission, RelationID: relation, WonAt: wonAt.UTC(), Items: items, Version: version}, nil
}

func (Store) ReadExamReceiptTx(ctx context.Context, q tx.Queryer, student identity.PlayerID, mission int64) (mentor.ExamReceipt, bool, error) {
	if q == nil || !student.Valid() || mission <= 0 {
		return mentor.ExamReceipt{}, false, domain.ErrRelationship
	}
	var relationID, itemsRaw string
	var wonAt time.Time
	var version int64
	var payloadVersion int16
	err := q.QueryRow(ctx, `SELECT relation_id::text,won_at,items::text,state_version,payload_version FROM mentor_exam_receipts WHERE student_id=$1 AND mission_id=$2`, int64(student), mission).Scan(&relationID, &wonAt, &itemsRaw, &version, &payloadVersion)
	if err != nil {
		if isNoRows(err) {
			return mentor.ExamReceipt{}, false, nil
		}
		return mentor.ExamReceipt{}, false, err
	}
	receipt, err := decodeExam(student, mission, relationID, wonAt, version, payloadVersion, itemsRaw)
	return receipt, err == nil, err
}

func (Store) LockExamReceiptTx(ctx context.Context, t tx.Tx, student identity.PlayerID, mission int64) (mentor.ExamReceipt, bool, error) {
	if t == nil || !student.Valid() || mission <= 0 {
		return mentor.ExamReceipt{}, false, domain.ErrRelationship
	}
	var relationID, itemsRaw string
	var wonAt time.Time
	var version int64
	var payloadVersion int16
	err := t.QueryRow(ctx, `SELECT relation_id::text,won_at,items::text,state_version,payload_version FROM mentor_exam_receipts WHERE student_id=$1 AND mission_id=$2 FOR UPDATE`, int64(student), mission).Scan(&relationID, &wonAt, &itemsRaw, &version, &payloadVersion)
	if err != nil {
		if isNoRows(err) {
			return mentor.ExamReceipt{}, false, nil
		}
		return mentor.ExamReceipt{}, false, err
	}
	receipt, err := decodeExam(student, mission, relationID, wonAt, version, payloadVersion, itemsRaw)
	return receipt, err == nil, err
}

func (Store) InsertExamReceiptTx(ctx context.Context, t tx.Tx, receipt mentor.ExamReceipt) error {
	if err := requireWritableTx(ctx, t); err != nil {
		return err
	}
	if !receipt.StudentID.Valid() || receipt.MissionID <= 0 || receipt.RelationID.IsZero() || receipt.WonAt.IsZero() || len(receipt.Items) == 0 || receipt.Version != 1 {
		return domain.ErrRelationship
	}
	raw, version, err := payload.Encode(receipt.Items)
	if err != nil {
		return err
	}
	result, err := t.Exec(ctx, `INSERT INTO mentor_exam_receipts(student_id,mission_id,relation_id,won_at,items,payload_version,state_version)VALUES($1,$2,$3,$4,$5::jsonb,$6,1) ON CONFLICT(student_id,mission_id) DO NOTHING`, int64(receipt.StudentID), receipt.MissionID, receipt.RelationID.String(), receipt.WonAt.UTC(), string(raw), version)
	if err != nil {
		return err
	}
	if result.RowsAffected() != 1 {
		return domain.ErrRelationshipConflict
	}
	return nil
}

func utcPointer(value *time.Time) *time.Time {
	if value == nil {
		return nil
	}
	utc := value.UTC()
	return &utc
}
