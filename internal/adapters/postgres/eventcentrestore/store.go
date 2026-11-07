package eventcentrestore

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	eventcentre "gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{ Queryer tx.Queryer }

const columns = `player_id,state_version,creation_revision,facts::text,created_at,updated_at`

func scan(row tx.Row) (eventcentre.Root, bool, error) {
	var root eventcentre.Root
	var playerID int64
	var raw string
	err := row.Scan(&playerID, &root.Version, &root.Revision, &raw, &root.CreatedAt, &root.UpdatedAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return eventcentre.Root{}, false, nil
	}
	if err != nil {
		return eventcentre.Root{}, false, err
	}
	root.Player = identity.PlayerID(playerID)
	if err := json.Unmarshal([]byte(raw), &root.Facts); err != nil {
		return eventcentre.Root{}, false, err
	}
	if root.Facts.Admin == nil {
		root.Facts.Admin = map[string]int64{}
	}
	if root.Facts.Board.NextReportID < 1 {
		root.Facts.Board.NextReportID = 1
	}
	if err := root.Validate(); err != nil {
		return eventcentre.Root{}, false, err
	}
	return root, true, nil
}

func (Store) ReadRootTx(ctx context.Context, q tx.Queryer, player identity.PlayerID) (eventcentre.Root, bool, error) {
	return scan(q.QueryRow(ctx, `SELECT `+columns+` FROM player_event_centre_roots WHERE player_id=$1`, int64(player)))
}

func (Store) LockRootTx(ctx context.Context, t tx.Tx, player identity.PlayerID) (eventcentre.Root, bool, error) {
	return scan(t.QueryRow(ctx, `SELECT `+columns+` FROM player_event_centre_roots WHERE player_id=$1 FOR UPDATE`, int64(player)))
}

func (Store) EnsureRootTx(ctx context.Context, t tx.Tx, player identity.PlayerID, revision string, at time.Time) error {
	if !player.Valid() || len(revision) != 64 || at.IsZero() {
		return eventcentre.ErrUnqualified
	}
	raw, err := json.Marshal(eventcentre.Seed())
	if err != nil {
		return err
	}
	_, err = t.Exec(ctx, `INSERT INTO player_event_centre_roots(player_id,state_version,creation_revision,facts,created_at,updated_at)VALUES($1,1,$2,$3::jsonb,$4,$4)ON CONFLICT(player_id)DO NOTHING`, int64(player), revision, string(raw), at)
	return err
}

func (Store) InsertBoardReportTx(ctx context.Context, t tx.Tx, player identity.PlayerID, reportID int64, content string, at time.Time) error {
	if !player.Valid() || reportID <= 0 || content == "" || at.IsZero() {
		return eventcentre.ErrUnqualified
	}
	_, err := t.Exec(ctx, `INSERT INTO player_event_centre_board_reports(player_id,report_id,content,created_at)VALUES($1,$2,$3,$4)`, int64(player), reportID, content, at)
	return err
}

func (Store) ReadBoardReportTx(ctx context.Context, q tx.Queryer, player identity.PlayerID, reportID int64) (string, bool, error) {
	if !player.Valid() || reportID <= 0 {
		return "", false, eventcentre.ErrUnqualified
	}
	var content string
	err := q.QueryRow(ctx, `SELECT content FROM player_event_centre_board_reports WHERE player_id=$1 AND report_id=$2`, int64(player), reportID).Scan(&content)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return "", false, nil
	}
	if err != nil {
		return "", false, err
	}
	return content, true, nil
}

func (Store) DeleteBoardReportsExceptTx(ctx context.Context, t tx.Tx, player identity.PlayerID, keep []int64) error {
	if !player.Valid() {
		return eventcentre.ErrUnqualified
	}
	_, err := t.Exec(ctx, `DELETE FROM player_event_centre_board_reports WHERE player_id=$1 AND report_id <> ALL($2)`, int64(player), keep)
	return err
}

func (Store) SaveRootTx(ctx context.Context, t tx.Tx, root eventcentre.Root, previousVersion int64) error {
	if root.Version != previousVersion+1 {
		return eventcentre.ErrUnqualified
	}
	raw, err := json.Marshal(root.Facts)
	if err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `UPDATE player_event_centre_roots SET facts=$2::jsonb,state_version=$3,updated_at=$4 WHERE player_id=$1 AND state_version=$5`, int64(root.Player), string(raw), root.Version, root.UpdatedAt, previousVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("event centre: stale root write")
	}
	return nil
}
