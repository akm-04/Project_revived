package gmquestionstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	domain "gxb.local/backend/v2/internal/domain/gmquestion"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

func (Store) InsertQuestionTx(ctx context.Context, transaction tx.Tx, question domain.Question) error {
	if transaction == nil || question.Validate() != nil {
		return domain.ErrQuestion
	}
	effect, err := transaction.Exec(ctx, "INSERT INTO player_gm_questions(operation_id,player_id,logical_server_id,message,asked_at) VALUES($1,$2,$3,$4,$5) ON CONFLICT(operation_id) DO NOTHING", question.Operation.String(), int64(question.Player), int32(question.Server), question.Message, question.AskedAt.UTC())
	if err != nil {
		return err
	}
	if effect == nil || effect.RowsAffected() != 1 {
		return errors.New("gm question: operation already exists without recovered receipt")
	}
	return nil
}
func (Store) ListQuestionsTx(ctx context.Context, query tx.Queryer, player identity.PlayerID, server identity.LogicalServerID, at time.Time) ([]domain.Question, error) {
	if query == nil || !player.Valid() || !server.Valid() || logicalserver.PlayerRegion(player) != server || at.IsZero() {
		return nil, domain.ErrQuestion
	}
	var raw string
	err := query.QueryRow(ctx, "SELECT COALESCE(jsonb_agg(jsonb_build_object('Operation',operation_id::text,'Message',message,'AskedAt',asked_at) ORDER BY asked_at,operation_id),'[]'::jsonb)::text FROM (SELECT operation_id,message,asked_at FROM player_gm_questions WHERE player_id=$1 AND logical_server_id=$2 AND asked_at<=$3 ORDER BY asked_at DESC,operation_id DESC LIMIT $4) history", int64(player), int32(server), at.UTC(), domain.HistoryLimit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var records []struct {
		Operation string
		Message   string
		AskedAt   time.Time
	}
	if err := json.Unmarshal([]byte(raw), &records); err != nil {
		return nil, err
	}
	if len(records) > domain.HistoryLimit {
		return nil, domain.ErrQuestion
	}
	questions := make([]domain.Question, 0, len(records))
	seen := map[ids.UUID]bool{}
	for _, record := range records {
		identifier, err := ids.ParseUUID(record.Operation)
		if err != nil {
			return nil, err
		}
		question := domain.Question{Operation: identifier, Player: player, Server: server, Message: record.Message, AskedAt: record.AskedAt.UTC()}
		if question.Validate() != nil || question.AskedAt.After(at) || seen[identifier] {
			return nil, domain.ErrQuestion
		}
		seen[identifier] = true
		questions = append(questions, question)
	}
	return questions, nil
}
