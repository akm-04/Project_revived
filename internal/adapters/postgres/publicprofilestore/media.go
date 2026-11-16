package publicprofilestore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

var _ app.MediaStore = Store{}

const mediaTable = "player_public_profile_media_history"

const mediaColumns = `h.operation_id::text,h.player_id,h.logical_server_id,h.reference::text,h.payload_version,h.root_version,h.decision_at`

const mediaInventoryHistory = `jsonb_build_object('operation',h.operation_id::text,'player_id',h.player_id,'server',h.logical_server_id,'reference',h.reference::text,'payload_version',h.payload_version,'root_version',h.root_version,'decision_at',h.decision_at)`

type mediaHistoryRow struct {
	Operation      string                   `json:"operation"`
	PlayerID       identity.PlayerID        `json:"player_id"`
	Server         identity.LogicalServerID `json:"server"`
	Reference      string                   `json:"reference"`
	PayloadVersion int16                    `json:"payload_version"`
	RootVersion    int64                    `json:"root_version"`
	DecisionAt     time.Time                `json:"decision_at"`
}

func decodeMediaHistory(h *app.MediaHistory, operation, reference string, version int16) error {
	parsed, e := ids.ParseUUID(operation)
	if e != nil {
		return e
	}
	h.Operation = parsed
	return payload.Decode(mediaTable, version, []byte(reference), &h.Reference)
}

func readMedia(c context.Context, q tx.Queryer, sql string, arg any) (app.MediaHistory, bool, error) {
	if q == nil {
		return app.MediaHistory{}, false, app.ErrInvalidState
	}
	var operation, reference string
	var version int16
	var h app.MediaHistory
	e := q.QueryRow(c, sql, arg).Scan(&operation, &h.PlayerID, &h.Server, &reference, &version, &h.RootVersion, &h.DecisionAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return app.MediaHistory{}, false, nil
	}
	if e != nil {
		return app.MediaHistory{}, false, e
	}
	if e = decodeMediaHistory(&h, operation, reference, version); e != nil {
		return h, false, e
	}
	h.DecisionAt = h.DecisionAt.UTC()
	return h, true, h.Validate()
}
func (Store) ReadCurrentMediaTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (app.MediaHistory, bool, error) {
	if !pid.Valid() {
		return app.MediaHistory{}, false, app.ErrInvalidState
	}
	h, ok, e := readMedia(c, q, `SELECT `+mediaColumns+` FROM player_public_profile_media_current v JOIN player_public_profile_media_history h ON h.player_id=v.player_id AND h.operation_id=v.operation_id WHERE v.player_id=$1`, int64(pid))
	if ok && h.PlayerID != pid {
		return h, false, app.ErrInvalidState
	}
	return h, ok, e
}
func (Store) ReadMediaHistoryTx(c context.Context, q tx.Queryer, op ids.UUID) (app.MediaHistory, bool, error) {
	if op.IsZero() {
		return app.MediaHistory{}, false, app.ErrInvalidState
	}
	h, ok, e := readMedia(c, q, `SELECT `+mediaColumns+` FROM player_public_profile_media_history h WHERE h.operation_id=$1::uuid`, op.String())
	if ok && h.Operation != op {
		return h, false, app.ErrInvalidState
	}
	return h, ok, e
}
func (Store) InsertMediaHistoryTx(c context.Context, t tx.Tx, h app.MediaHistory) error {
	if t == nil || h.Validate() != nil {
		return app.ErrInvalidState
	}
	b, version, e := payload.Encode(h.Reference)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `INSERT INTO player_public_profile_media_history(operation_id,player_id,logical_server_id,reference,payload_version,root_version,decision_at)VALUES($1::uuid,$2,$3,$4::jsonb,$5,$6,$7)`, h.Operation.String(), int64(h.PlayerID), int32(h.Server), string(b), version, h.RootVersion, h.DecisionAt.UTC())
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrConflict
	}
	return e
}
func (Store) SetCurrentMediaTx(c context.Context, t tx.Tx, pid identity.PlayerID, op ids.UUID) error {
	if t == nil || !pid.Valid() || op.IsZero() {
		return app.ErrInvalidState
	}
	tag, e := t.Exec(c, `INSERT INTO player_public_profile_media_current(player_id,operation_id)VALUES($1,$2::uuid) ON CONFLICT(player_id) DO UPDATE SET operation_id=EXCLUDED.operation_id`, int64(pid), op.String())
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrConflict
	}
	return e
}
func (Store) InventoryMediaTx(c context.Context, q tx.Queryer) (app.MediaInventory, error) {
	var out app.MediaInventory
	if q == nil {
		return out, app.ErrInvalidState
	}
	var raw string
	e := q.QueryRow(c, `SELECT jsonb_build_object('current',(SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'operation',operation_id)ORDER BY player_id),'[]'::jsonb) FROM player_public_profile_media_current),'history',(SELECT COALESCE(jsonb_agg(`+mediaInventoryHistory+` ORDER BY h.operation_id),'[]'::jsonb) FROM player_public_profile_media_history h))`).Scan(&raw)
	if e != nil {
		return out, e
	}
	var stored struct {
		Current []app.MediaCurrent `json:"current"`
		History []mediaHistoryRow  `json:"history"`
	}
	if e = json.Unmarshal([]byte(raw), &stored); e != nil {
		return out, e
	}
	out.Current = stored.Current
	for _, row := range stored.History {
		h := app.MediaHistory{PlayerID: row.PlayerID, Server: row.Server, RootVersion: row.RootVersion, DecisionAt: row.DecisionAt}
		if e = decodeMediaHistory(&h, row.Operation, row.Reference, row.PayloadVersion); e != nil {
			return out, e
		}
		h.DecisionAt = h.DecisionAt.UTC()
		if e = h.Validate(); e != nil {
			return out, e
		}
		out.History = append(out.History, h)
	}
	return out, nil
}
