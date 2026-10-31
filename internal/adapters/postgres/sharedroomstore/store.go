// Package sharedroomstore owns shared_rooms and shared_room_seats. A command
// locks the room row at rank 607 (D365) and reads or writes its seats under
// that lock.
package sharedroomstore

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	gen "gxb.local/backend/v2/internal/application/generation"
	appwakeup "gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

const (
	roomColumns     = `room_id,logical_server_id,family,slot,owner_player,status,capacity,expires_at,state_version,notice_version,payload::text,created_at,updated_at,closed_at`
	prefixedColumns = `r.room_id,r.logical_server_id,r.family,r.slot,r.owner_player,r.status,r.capacity,r.expires_at,r.state_version,r.notice_version,r.payload::text,r.created_at,r.updated_at,r.closed_at`
)

func (Store) ReadRoomTx(ctx context.Context, q tx.Queryer, roomID int64) (d.Room, bool, error) {
	room, found, err := readRoom(q.QueryRow(ctx, `SELECT `+roomColumns+` FROM shared_rooms WHERE room_id=$1`, roomID))
	if err != nil || !found {
		return room, found, err
	}
	seats, err := readSeats(ctx, q, roomID)
	if err != nil {
		return d.Room{}, false, err
	}
	room.Seats = seats
	return room, true, room.Validate()
}

func (Store) LockRoomTx(ctx context.Context, t tx.Tx, roomID int64) (d.Room, bool, error) {
	room, found, err := readRoom(t.QueryRow(ctx, `SELECT `+roomColumns+` FROM shared_rooms WHERE room_id=$1 FOR UPDATE`, roomID))
	if err != nil || !found {
		return room, found, err
	}
	seats, err := readSeats(ctx, t, roomID)
	if err != nil {
		return d.Room{}, false, err
	}
	room.Seats = seats
	return room, true, room.Validate()
}

// ReadPlayerRoomTx finds the player's open seat in one family slot; the partial
// unique index makes that room unique.
func (Store) ReadPlayerRoomTx(ctx context.Context, q tx.Queryer, player identity.PlayerID, family string, slot int64) (d.Room, bool, error) {
	room, found, err := readRoom(q.QueryRow(ctx, `SELECT `+prefixedColumns+` FROM shared_rooms r JOIN shared_room_seats s ON s.room_id=r.room_id
WHERE s.player_id=$1 AND s.family=$2 AND s.slot=$3 AND s.stage='SEATED' AND r.status='OPEN'`, int64(player), family, slot))
	if err != nil || !found {
		return room, found, err
	}
	seats, err := readSeats(ctx, q, room.ID)
	if err != nil {
		return d.Room{}, false, err
	}
	room.Seats = seats
	return room, true, room.Validate()
}

func (Store) OpenRoomTx(ctx context.Context, t tx.Tx, room d.Room) (d.Room, error) {
	if t == nil || room.ID != 0 {
		return d.Room{}, d.ErrInvalid
	}
	if err := room.Validate(); err != nil {
		return d.Room{}, err
	}
	var roomID int64
	err := t.QueryRow(ctx, `INSERT INTO shared_rooms(logical_server_id,family,slot,owner_player,status,capacity,expires_at,state_version,notice_version,payload,created_at,updated_at)
VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10::jsonb,$11,$12) RETURNING room_id`,
		int32(room.LogicalServerID), room.Family, room.Slot, int64(room.Owner), string(room.Status), room.Capacity,
		room.ExpiresAt, room.StateVersion, room.NoticeVersion, string(room.Payload), room.CreatedAt, room.UpdatedAt).Scan(&roomID)
	if err != nil {
		return d.Room{}, err
	}
	room.ID = roomID
	if err = writeSeats(ctx, t, room); err != nil {
		return d.Room{}, err
	}
	return room, nil
}

func (Store) SaveRoomTx(ctx context.Context, t tx.Tx, room d.Room) error {
	if t == nil {
		return d.ErrInvalid
	}
	if err := room.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `UPDATE shared_rooms SET status=$2,state_version=$3,notice_version=$4,payload=$5::jsonb,updated_at=$6,closed_at=$7,expires_at=$8 WHERE room_id=$1`,
		room.ID, string(room.Status), room.StateVersion, room.NoticeVersion, string(room.Payload), room.UpdatedAt, room.ClosedAt, room.ExpiresAt)
	if err == nil && tag.RowsAffected() != 1 {
		return d.ErrNotFound
	}
	if err != nil {
		return err
	}
	return writeSeats(ctx, t, room)
}

// ExpiredRoomIDsTx lists expired open rooms, oldest first. A zero server scans
// every logical server; only a reconciler that explicitly opted into the
// cross-server batch passes one.
func (Store) ExpiredRoomIDsTx(ctx context.Context, q tx.Queryer, server identity.LogicalServerID, at time.Time, limit int) ([]int64, error) {
	if limit < 1 || limit > gen.MaxReconcileBatch {
		return nil, d.ErrInvalid
	}
	if server.Valid() {
		return expiredRoomIDs(ctx, q, `SELECT COALESCE(jsonb_agg(room_id),'[]'::jsonb)::text FROM (SELECT room_id FROM shared_rooms WHERE logical_server_id=$1 AND status='OPEN' AND expires_at<=$2 ORDER BY expires_at,room_id LIMIT $3) due`, int32(server), at, limit)
	}
	return expiredRoomIDs(ctx, q, `SELECT COALESCE(jsonb_agg(room_id),'[]'::jsonb)::text FROM (SELECT room_id FROM shared_rooms WHERE status='OPEN' AND expires_at<=$1 ORDER BY expires_at,room_id LIMIT $2) due`, at, limit)
}

func expiredRoomIDs(ctx context.Context, q tx.Queryer, query string, args ...any) ([]int64, error) {
	var raw string
	err := q.QueryRow(ctx, query, args...).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var roomIDs []int64
	if err = json.Unmarshal([]byte(raw), &roomIDs); err != nil {
		return nil, err
	}
	return roomIDs, nil
}

func (Store) WakeRoomTx(ctx context.Context, t tx.Tx, roomID int64, route string) error {
	if roomID <= 0 || t == nil {
		return d.ErrInvalid
	}
	return postgres.EmitRealtimeWakeup(ctx, t, appwakeup.Envelope{Version: appwakeup.EnvelopeVersion, Route: route, Ref: strconv.FormatInt(roomID, 10)})
}

func writeSeats(ctx context.Context, t tx.Tx, room d.Room) error {
	for _, seat := range room.Seats {
		_, err := t.Exec(ctx, `INSERT INTO shared_room_seats(room_id,seat_index,player_id,family,slot,stage,ready,joined_at,updated_at)
VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT(room_id,player_id)DO UPDATE SET seat_index=EXCLUDED.seat_index,family=EXCLUDED.family,slot=EXCLUDED.slot,stage=EXCLUDED.stage,ready=EXCLUDED.ready,joined_at=EXCLUDED.joined_at,updated_at=EXCLUDED.updated_at`,
			room.ID, seat.Index, int64(seat.Player), room.Family, room.Slot, string(seat.Stage), seat.Ready, seat.JoinedAt, room.UpdatedAt)
		if err != nil {
			return err
		}
	}
	return nil
}

func readSeats(ctx context.Context, q tx.Queryer, roomID int64) ([]d.Seat, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('seat_index',seat_index,'player_id',player_id,'stage',stage,'ready',ready,'joined_at',joined_at) ORDER BY seat_index,player_id),'[]'::jsonb)::text FROM shared_room_seats WHERE room_id=$1`, roomID).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		Index    int    `json:"seat_index"`
		Player   int64  `json:"player_id"`
		Stage    string `json:"stage"`
		Ready    bool   `json:"ready"`
		JoinedAt string `json:"joined_at"`
	}
	if err = json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	seats := make([]d.Seat, 0, len(rows))
	for _, row := range rows {
		joined, err := time.Parse(time.RFC3339Nano, row.JoinedAt)
		if err != nil {
			return nil, err
		}
		seats = append(seats, d.Seat{Index: row.Index, Player: identity.PlayerID(row.Player), Stage: d.SeatStage(row.Stage), Ready: row.Ready, JoinedAt: joined})
	}
	return seats, nil
}

func readRoom(row tx.Row) (d.Room, bool, error) {
	var room d.Room
	var roomID, owner int64
	var server int32
	var status, payload string
	var closedAt *time.Time
	err := row.Scan(&roomID, &server, &room.Family, &room.Slot, &owner, &status, &room.Capacity, &room.ExpiresAt,
		&room.StateVersion, &room.NoticeVersion, &payload, &room.CreatedAt, &room.UpdatedAt, &closedAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Room{}, false, nil
	}
	if err != nil {
		return d.Room{}, false, err
	}
	room.ID = roomID
	room.LogicalServerID = identity.LogicalServerID(server)
	room.Owner = identity.PlayerID(owner)
	room.Status = d.Status(status)
	room.Payload = json.RawMessage(payload)
	room.ClosedAt = closedAt
	return room, true, nil
}
