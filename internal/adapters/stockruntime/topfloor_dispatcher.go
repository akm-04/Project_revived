package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"strconv"
	"strings"

	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	app "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/operation"
	projection "gxb.local/backend/v2/internal/projection/topfloor"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// Top Floor stock MIDs (src_64 mid.lua); 274/275/277/276/279 and ARENA_MODE stay unregistered.
var TopFloorMIDs = []uint16{272, 273, 278, 280, 281, 288, 289, 290, 291, 292, 293, 294}

type TopFloorPort interface {
	Load(context.Context, identity.ActorContext, operation.Context) (app.ArenaView, error)
	Refresh(context.Context, identity.ActorContext, operation.Context) (app.ArenaView, error)
	SaveDefense(context.Context, identity.ActorContext, []int64, int64, operation.Context) error
	PreFight(context.Context, identity.ActorContext, int64) error
	Start(context.Context, identity.ActorContext, app.StartCommand, operation.Context) (app.FightView, error)
	BuyTicket(context.Context, identity.ActorContext, operation.Context) (d.Player, error)
	ResetTimer(context.Context, identity.ActorContext, operation.Context) (d.Player, error)
	Records(context.Context, identity.ActorContext) ([]app.RecordView, error)
	Report(context.Context, string) ([]byte, error)
	RecordInfo(context.Context, identity.ActorContext, int64) (app.RecordInfo, d.Record, error)
	Formation(context.Context, identity.ActorContext, int64) (d.Display, error)
}

type TopFloorDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   TopFloorPort
}

func topFloorInteger(p map[string]any, key string, required bool) (int64, bool) {
	raw, present := p[key]
	if !present || raw == nil {
		return 0, !required
	}
	n, err := feedbackInteger(raw, 0, 9007199254740991)
	return n, err == nil
}

// topFloorFormation reads getFormationStr's "id|id|..." (a single hero may arrive as a number).
func topFloorFormation(raw any) ([]int64, bool) {
	text, ok := raw.(string)
	if !ok {
		n, err := feedbackInteger(raw, 1, 9007199254740991)
		return []int64{n}, err == nil
	}
	out := []int64{}
	for _, part := range strings.Split(text, "|") {
		n, err := strconv.ParseInt(part, 10, 64)
		if err != nil {
			return nil, false
		}
		out = append(out, n)
	}
	return out, true
}

func (t TopFloorDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: t.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if t.Service == nil {
		return failTopFloor(d.ErrUnavailable)
	}
	p, op := req.Envelope.Params, req.Envelope.Operation
	switch req.Envelope.MID {
	case 272, 273:
		if !onlyStockGameplayParams(p) {
			return badHero("invalid_top_floor_parameter")
		}
		load := t.Service.Load
		if req.Envelope.MID == 273 {
			load = t.Service.Refresh
		}
		v, err := load(ctx, a, op)
		if err != nil {
			return failTopFloor(err)
		}
		if req.Envelope.MID == 273 {
			return okI5(projection.Enemies(v.Enemies))
		}
		return okI5(projection.Arena(v.Player, v.Rank, v.Enemies, v.ServerTime))
	case 278:
		raw, ok := p["heroIDs"].([]any)
		pet, petOK := topFloorInteger(p, "pet_id", false)
		if !onlyStockGameplayParams(p, "heroIDs", "pet_id") || !ok || !petOK {
			return badHero("invalid_top_floor_parameter")
		}
		heroes := []int64{}
		for _, x := range raw {
			n, err := feedbackInteger(x, 1, 9007199254740991)
			if err != nil {
				return badHero("invalid_top_floor_parameter")
			}
			heroes = append(heroes, n)
		}
		if err := t.Service.SaveDefense(ctx, a, heroes, pet, op); err != nil {
			return failTopFloor(err)
		}
		return okI5(map[string]any{})
	case 280:
		return t.start(ctx, a, p, op)
	case 281, 288:
		if !onlyStockGameplayParams(p) {
			return badHero("invalid_top_floor_parameter")
		}
		if req.Envelope.MID == 281 {
			player, err := t.Service.BuyTicket(ctx, a, op)
			if err != nil {
				return failTopFloor(err)
			}
			return okI5(projection.Ticket(player))
		}
		player, err := t.Service.ResetTimer(ctx, a, op)
		if err != nil {
			return failTopFloor(err)
		}
		return okI5(projection.ResetTimer(player))
	case 289:
		records, err := t.Service.Records(ctx, a)
		if err != nil {
			return failTopFloor(err)
		}
		rows := []projection.Record{}
		for _, r := range records {
			rows = append(rows, projection.Record{ID: r.Record.ID, Key: r.Record.AttemptID.String(), At: r.Record.At, Attack: r.Record.Attack, Win: r.Record.Win, Self: r.Self, Opponent: r.Opponent})
		}
		return okI5(projection.Records(rows))
	case 290:
		key, ok := p["report_key"].(string)
		if !onlyStockGameplayParams(p, "player_id", "report_key") || !ok {
			return badHero("invalid_top_floor_parameter")
		}
		report, err := t.Service.Report(ctx, key)
		if err != nil {
			return failTopFloor(err)
		}
		return okI5(projection.Report(report))
	case 291:
		id, ok := topFloorInteger(p, "other_player_id", true)
		if !onlyStockGameplayParams(p, "other_player_id") || !ok {
			return badHero("invalid_top_floor_parameter")
		}
		v, err := t.Service.Formation(ctx, a, id)
		if err != nil {
			return failTopFloor(err)
		}
		return okI5(projection.Formation(v))
	case 293:
		id, ok := topFloorInteger(p, "id", true)
		if !onlyStockGameplayParams(p, "id") || !ok {
			return badHero("invalid_top_floor_parameter")
		}
		info, _, err := t.Service.RecordInfo(ctx, a, id)
		if err != nil {
			return failTopFloor(err)
		}
		return okI5(projection.RecordInfo(info.Opponent, info.CanAvenge, info.AvengeType))
	case 294:
		enemy, ok := topFloorInteger(p, "enemy_id", false)
		if !onlyStockGameplayParams(p, "enemy_id") || !ok {
			return badHero("invalid_top_floor_parameter")
		}
		if err := t.Service.PreFight(ctx, a, enemy); err != nil {
			return failTopFloor(err)
		}
		return okI5(map[string]any{})
	case 292:
		// Private policy: the seal-hero feature is closed (is_ban_open 0).
		return failTopFloor(d.ErrRefused)
	}
	return badHero("unsupported_top_floor_mid")
}

func (t TopFloorDispatcher) start(ctx context.Context, a identity.ActorContext, p map[string]any, op operation.Context) httpedge.Response {
	formation, formationOK := topFloorFormation(p["formation"])
	pet, petOK := topFloorInteger(p, "pet_id", false)
	enemy, enemyOK := topFloorInteger(p, "enemy_id", true)
	avenge, avengeOK := topFloorInteger(p, "is_avenge", false)
	campaign, campaignOK := topFloorInteger(p, "campaign_type", false)
	valid := formationOK && petOK && enemyOK && avengeOK && avenge <= 1 && campaignOK && (campaign == 0 || campaign == d.CampaignType)
	if !onlyStockGameplayParams(p, "pet_id", "campaign_id", "campaign_type", "formation", "enemy_id", "is_avenge") || !valid {
		return badHero("invalid_top_floor_parameter")
	}
	v, err := t.Service.Start(ctx, a, app.StartCommand{Formation: formation, PetID: pet, Enemy: enemy, Avenge: avenge == 1}, op)
	if err != nil {
		return failTopFloor(err)
	}
	return okI5(projection.Fight(v.Formation, v.Report, v.Win, v.AwardCrystal, v.Enemy))
}

func failTopFloor(err error) httpedge.Response {
	if errors.Is(err, d.ErrRefused) || errors.Is(err, d.ErrInvalid) || errors.Is(err, economy.ErrInsufficientBalance) {
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "top_floor_request_refused"}}
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "top_floor_unavailable_or_unresolved"}}
}
