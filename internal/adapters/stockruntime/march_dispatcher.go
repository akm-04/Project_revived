package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	app "gxb.local/backend/v2/internal/application/march"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"math"
	"net/http"
	"strconv"
)

var MarchMIDs = []uint16{336, 337, 338, 339, 340, 341, 342}

type MarchPort interface {
	Load(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Reset(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Start(context.Context, identity.ActorContext, app.Fight, operation.Context) (map[string]any, error)
	Result(context.Context, identity.ActorContext, app.Result, operation.Context) (map[string]any, error)
	Chest(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	Extra(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Advance(context.Context, identity.ActorContext, app.Fight, operation.Context) (map[string]any, error)
}
type MarchDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   MarchPort
}

func (m MarchDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	actor, fail := (HeroDispatcher{Authority: m.Authority}).actor(c, r)
	if fail != nil {
		return *fail
	}
	if m.Service == nil {
		return marchFailure(d.ErrUnavailable)
	}
	p, op := r.Envelope.Params, r.Envelope.Operation
	bad := badHero("march_invalid_parameter")
	var body map[string]any
	var err error
	switch r.Envelope.MID {
	case 336, 337, 341:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		if r.Envelope.MID == 336 {
			body, err = m.Service.Load(c, actor, op)
		} else if r.Envelope.MID == 337 {
			body, err = m.Service.Reset(c, actor, op)
		} else {
			body, err = m.Service.Extra(c, actor, op)
		}
	case 339:
		stage, ok := topFloorInteger(p, "stage", true)
		if !ok || stage < 1 || stage > 15 || !onlyStockGameplayParams(p, "stage") {
			return bad
		}
		body, err = m.Service.Chest(c, actor, stage, op)
	case 340, 342:
		if !onlyStockGameplayParams(p, "campaign_type", "formation", "force", "rent_formation", "rent_player_id") {
			return bad
		}
		kind, ok := topFloorInteger(p, "campaign_type", true)
		if !ok || kind != 5 {
			return bad
		}
		formation, ok := topFloorFormation(p["formation"])
		if !ok || !marchFormation(formation) {
			return bad
		}
		force, ok := topFloorInteger(p, "force", r.Envelope.MID == 342)
		if !ok {
			return bad
		}
		rentPlayer, rentPlayerOK := topFloorInteger(p, "rent_player_id", false)
		rentUnit, rentUnitOK := topFloorIdentifier(p["rent_formation"], false)
		if !rentPlayerOK || !rentUnitOK || (rentPlayer == 0) != (rentUnit == 0) {
			return bad
		}
		q := app.Fight{Formation: formation, Force: force, RentPlayer: rentPlayer, RentUnit: rentUnit}
		if r.Envelope.MID == 340 {
			body, err = m.Service.Start(c, actor, q, op)
		} else {
			body, err = m.Service.Advance(c, actor, q, op)
		}
	case 338:
		q, ok := marchResult(p)
		if !ok {
			return bad
		}
		body, err = m.Service.Result(c, actor, q, op)
	default:
		return bad
	}
	if err != nil {
		return marchFailure(err)
	}
	return okI5(body)
}
func marchFormation(ids []int64) bool {
	if len(ids) < 1 || len(ids) > 5 {
		return false
	}
	seen := map[int64]bool{}
	n := 0
	for _, id := range ids {
		if id < 0 || id > 9007199254740991 || id > 0 && seen[id] {
			return false
		}
		if id > 0 {
			seen[id] = true
			n++
		}
	}
	return n > 0
}
func marchResult(p map[string]any) (app.Result, bool) {
	var q app.Result
	if !onlyStockGameplayParams(p, "win", "is_reborn", "formation", "hero_status", "enemy_status", "cost_drink") {
		return q, false
	}
	win, ok := p["win"].(bool)
	if !ok {
		return q, false
	}
	q.Report.Win = win
	reborn, ok := topFloorInteger(p, "is_reborn", true)
	if !ok || reborn != 0 {
		return q, false
	}
	if raw, present := p["formation"]; present {
		q.Report.Formation, ok = topFloorFormation(raw)
		if !ok || !marchFormation(q.Report.Formation) {
			return q, false
		}
	}
	q.CostDrink, ok = topFloorInteger(p, "cost_drink", false)
	if !ok {
		return q, false
	}
	q.Report.Allies, ok = marchStatuses(p["hero_status"], true)
	if !ok {
		return q, false
	}
	q.Report.Enemies, ok = marchStatuses(p["enemy_status"], false)
	return q, ok
}
func marchStatuses(raw any, allies bool) ([]cd.ActorStatus, bool) {
	rows, ok := raw.([]any)
	if !ok || len(rows) == 0 || len(rows) > 5 {
		return nil, false
	}
	out := make([]cd.ActorStatus, 0, len(rows))
	for _, raw := range rows {
		row, ok := raw.(map[string]any)
		if !ok || !marchStatusKeys(row) {
			return nil, false
		}
		id, a := topFloorInteger(row, "hero_id", true)
		player, b := topFloorInteger(row, "player_id", allies)
		reborn, e := topFloorInteger(row, "is_reborn", true)
		hp, h := marchNumber(row["hp"])
		mp, m := marchNumber(row["mp"])
		if !a || !b || !e || !h || !m || id <= 0 || allies && player <= 0 || !allies && player != 0 || reborn > 1 {
			return nil, false
		}
		out = append(out, cd.ActorStatus{Player: player, Identity: id, HP: hp, MP: mp, Reborn: reborn})
	}
	return out, true
}
func marchNumber(raw any) (float64, bool) {
	// Reject strings and booleans at the stock JSON numeric boundary.
	switch raw.(type) {
	case float64, float32, int, int64, json.Number:
	default:
		return 0, false
	}
	value, err := strconv.ParseFloat(fmt.Sprint(raw), 64)
	return value, err == nil && !math.IsNaN(value) && !math.IsInf(value, 0) && value >= 0
}
func marchFailure(err error) httpedge.Response {
	var conflict *receipt.ConflictError
	if errors.Is(err, d.ErrInvalid) || errors.As(err, &conflict) {
		return badHero("march_invalid_parameter")
	}
	if errors.Is(err, cd.ErrLoanRefused) {
		return conflictRefusal(1)
	}
	if errors.Is(err, d.ErrRefused) || errors.Is(err, cd.ErrStartConflict) {
		return conflictRefusal(1)
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "march_operation_failed"}}
}

func marchStatusKeys(row map[string]any) bool {
	for key := range row {
		switch key {
		case "player_id", "hero_id", "hp", "mp", "is_reborn":
		default:
			return false
		}
	}
	return true
}
