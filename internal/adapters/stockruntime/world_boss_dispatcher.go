package stockruntime

import (
	"context"
	"errors"
	"fmt"
	"math"
	"net/http"
	"strconv"

	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	app "gxb.local/backend/v2/internal/application/worldboss"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// WorldBossMIDs are the src_64 World Boss model MIDs (mid.lua 323-327).
var WorldBossMIDs = []uint16{624, 625, 626, 627, 628}

const worldBossFightExist = 30005

type WorldBossPort interface {
	Info(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Buy(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Start(context.Context, identity.ActorContext, app.StartRequest, operation.Context) (map[string]any, error)
	Settle(context.Context, identity.ActorContext, app.ResultRequest, operation.Context) (app.Response, error)
	Sweep(context.Context, identity.ActorContext, int64, operation.Context) (app.Response, error)
}

type WorldBossDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   WorldBossPort
}

func (o WorldBossDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failWorldBoss(d.ErrUnavailable)
	}
	params, op := req.Envelope.Params, req.Envelope.Operation
	bad := badHero("world_boss_invalid_parameter")
	switch req.Envelope.MID {
	case 624:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		body, err := o.Service.Info(ctx, a, op)
		if err != nil {
			return failWorldBoss(err)
		}
		return okI5(body)
	case 625:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		body, err := o.Service.Buy(ctx, a, op)
		if err != nil {
			return failWorldBoss(err)
		}
		return okI5(body)
	case 626:
		request, ok := worldBossStart(params)
		if !ok {
			return bad
		}
		body, err := o.Service.Start(ctx, a, request, op)
		if err != nil {
			return failWorldBoss(err)
		}
		return okI5(body)
	case 627:
		request, ok := worldBossResult(params)
		if !ok {
			return bad
		}
		response, err := o.Service.Settle(ctx, a, request, op)
		if err != nil {
			return failWorldBoss(err)
		}
		return worldBossTerminal(response)
	case 628:
		campaign, ok := topFloorInteger(params, "campaign_id", true)
		if !ok || campaign < d.FirstBossID || campaign > d.LastBossID || !onlyStockGameplayParams(params, "campaign_id") || worldBossRented(params) {
			return bad
		}
		response, err := o.Service.Sweep(ctx, a, campaign, op)
		if err != nil {
			return failWorldBoss(err)
		}
		return worldBossTerminal(response)
	}
	return bad
}

// worldBossStart reads SelectTeamNewWindow's 626. A borrowed hero is frozen as
// a BORROWED participant and admitted by Combat's lending capability.
func worldBossStart(params map[string]any) (app.StartRequest, bool) {
	campaign, campaignOK := topFloorInteger(params, "campaign_id", true)
	formation, formationOK := topFloorFormation(params["formation"])
	rentPlayer, rentPlayerOK := topFloorInteger(params, "rent_player_id", false)
	rentUnit, rentUnitOK := topFloorIdentifier(params["rent_formation"], false)
	allowed := onlyStockGameplayParams(params, "campaign_id", "formation", "rent_player_id", "rent_formation", "tutor_rent_hero", "rent_hero_player", "rent_hero_id")
	if !allowed || !campaignOK || !formationOK || !rentPlayerOK || !rentUnitOK || campaign < d.FirstBossID || campaign > d.LastBossID ||
		(rentPlayer == 0) != (rentUnit == 0) {
		return app.StartRequest{}, false
	}
	return app.StartRequest{CampaignID: campaign, Formation: formation, RentPlayer: rentPlayer, RentUnit: rentUnit}, true
}

// worldBossResult reads BattleCreate.elementResult's 627.
func worldBossResult(params map[string]any) (app.ResultRequest, bool) {
	campaign, campaignOK := topFloorInteger(params, "campaign_id", true)
	kind, kindOK := topFloorInteger(params, "campaign_type", true)
	formation, formationOK := topFloorFormation(params["formation"])
	damage, damageOK := worldBossDamage(params["total_damage"])
	allowed := onlyStockGameplayParams(params, "campaign_id", "campaign_type", "total_damage", "formation", "rent_formation", "rent_player_id")
	if !allowed || !campaignOK || !kindOK || !formationOK || !damageOK || campaign < d.FirstBossID || campaign > d.LastBossID || kind != 8 {
		return app.ResultRequest{}, false
	}
	return app.ResultRequest{CampaignID: campaign, Damage: damage, Formation: formation}, true
}

func worldBossRented(params map[string]any) bool {
	for _, key := range []string{"rent_player_id", "rent_formation", "tutor_rent_hero", "rent_hero_player", "rent_hero_id"} {
		raw, present := params[key]
		if !present || raw == nil {
			continue
		}
		text := fmt.Sprint(raw)
		if text != "" && text != "0" {
			return true
		}
	}
	return false
}

func worldBossDamage(raw any) (int64, bool) {
	value, err := strconv.ParseFloat(fmt.Sprint(raw), 64)
	if err != nil || math.IsNaN(value) || math.IsInf(value, 0) || value < 0 {
		return 0, false
	}
	if value > float64(d.DamageCap) {
		value = float64(d.DamageCap)
	}
	return int64(value), true
}

func worldBossTerminal(response app.Response) httpedge.Response {
	if response.Body == nil {
		response.Body = map[string]any{}
	}
	if response.Duplicate {
		response.Body["error_code"] = int64(worldBossFightExist)
	}
	return okI5(response.Body)
}

func failWorldBoss(err error) httpedge.Response {
	var conflict *receipt.ConflictError
	if errors.Is(err, d.ErrInvalid) || errors.As(err, &conflict) {
		return badHero("world_boss_invalid_parameter")
	}
	if errors.Is(err, d.ErrRefused) || errors.Is(err, economy.ErrInsufficientBalance) {
		return okI5(map[string]any{"error_code": int64(1)})
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "world_boss_unavailable"}}
}
