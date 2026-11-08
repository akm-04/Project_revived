package broadcaststore

import (
	"context"
	"encoding/json"
	"errors"

	"github.com/jackc/pgx/v5"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/broadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store owns the broadcast outbox. Producers insert one row in their gameplay
// transaction; the realtime listener takes and deletes it once.
type Store struct{}

func (Store) InsertTx(ctx context.Context, t tx.Tx, m app.Message) (int64, error) {
	fields, err := json.Marshal(m.Fields)
	if err != nil {
		return 0, err
	}
	var id int64
	err = t.QueryRow(ctx, `INSERT INTO broadcast_outbox(logical_server_id,mid,msg_type,player_id,enemy_player_id,fields,created_at)VALUES($1,$2,$3,$4,NULLIF($5,0),$6::jsonb,clock_timestamp()) RETURNING broadcast_id`,
		int64(m.Server), int64(m.MID), m.MsgType, int64(m.Player), int64(m.Enemy), string(fields)).Scan(&id)
	return id, err
}

// TakeTx removes one queued announcement and returns its canonical content.
// The delete makes redelivery at most once and bounds the outbox.
func (Store) TakeTx(ctx context.Context, t tx.Tx, id int64) (app.Message, bool, error) {
	var server int32
	var mid, msgType, player, enemy int64
	var raw []byte
	err := t.QueryRow(ctx, `DELETE FROM broadcast_outbox WHERE broadcast_id=$1 RETURNING logical_server_id,mid,msg_type,player_id,COALESCE(enemy_player_id,0),fields`, id).
		Scan(&server, &mid, &msgType, &player, &enemy, &raw)
	if errors.Is(err, pgx.ErrNoRows) || errors.Is(err, kernelstore.ErrNoRows) {
		return app.Message{}, false, nil
	}
	if err != nil {
		return app.Message{}, false, err
	}
	var fields app.Fields
	if err = json.Unmarshal(raw, &fields); err != nil {
		return app.Message{}, false, err
	}
	return app.Message{MID: uint16(mid), MsgType: msgType, Server: identity.LogicalServerID(server), Player: identity.PlayerID(player), Enemy: identity.PlayerID(enemy), Fields: fields}, true, nil
}
