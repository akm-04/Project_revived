package arena

import (
	"context"
	"errors"
	"strconv"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const TournamentNoticeRoute = "arena.playoffs.notice.v1"
const TournamentReadyLead = 30 * time.Second

func (service Service) describeSelection(requestContext context.Context, scope gen.TimedScope, room *d.TournamentRoom) error {
	room.SelectionHeroes = [2]map[string]map[string]any{{}, {}}
	room.SelectionPets = [2]map[string]map[string]any{{}, {}}
	for side, player := range room.Selection.Players {
		if room.Faces[side].Player == 0 {
			face, err := service.face(requestContext, scope.Tx, player)
			if err != nil {
				return err
			}
			room.Faces[side] = face
		}
		rows, err := service.heroRows(requestContext, scope.Tx, player, scope.Operation.DecisionAt())
		if err != nil {
			return err
		}
		selected := room.Selection.Teams[side][room.Selection.Team-1]
		for _, identifier := range selected.Heroes {
			key := strconv.FormatInt(identifier, 10)
			if row, valid := rows[key].(map[string]any); valid {
				room.SelectionHeroes[side][key] = row
			}
		}
		if selected.Pet == 0 {
			continue
		}
		pets, err := service.petRows(requestContext, scope.Tx, player, scope.Operation.DecisionAt())
		if err != nil {
			return err
		}
		key := strconv.FormatInt(selected.Pet, 10)
		if row, found := pets[key]; found {
			room.SelectionPets[side][key] = row
		}
	}
	return nil
}

type TournamentNoticeReader struct {
	Store interface {
		ReadTournamentRoomTx(context.Context, tx.Queryer, ids.UUID, bool) (d.TournamentRoom, bool, error)
	}
	Queryer tx.Queryer
	Time    gen.TimeAuthority
}

func (reader TournamentNoticeReader) ReadNotice(requestContext context.Context, raw string) (d.TournamentRoomView, bool, error) {
	identifier, err := ids.ParseUUID(raw)
	if err != nil || identifier.IsZero() {
		return d.TournamentRoomView{}, false, d.ErrInvalid
	}
	if reader.Store == nil || reader.Queryer == nil || reader.Time == nil {
		return d.TournamentRoomView{}, false, d.ErrUnavailable
	}
	room, found, err := reader.Store.ReadTournamentRoomTx(requestContext, reader.Queryer, identifier, false)
	if err != nil || !found {
		return d.TournamentRoomView{}, false, errors.Join(err, d.ErrRefused)
	}
	at, err := reader.Time.Now(requestContext)
	if err != nil {
		return d.TournamentRoomView{}, false, err
	}
	if room.Status == d.RoomSettled || at.Before(room.StartsAt.Add(-TournamentReadyLead)) {
		return d.TournamentRoomView{}, false, nil
	}
	return d.TournamentRoomView{Room: room, Heroes: room.SelectionHeroes, Pets: room.SelectionPets, At: at}, true, nil
}
