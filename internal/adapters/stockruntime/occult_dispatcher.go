package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"strconv"

	app "gxb.local/backend/v2/internal/application/occult"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// OccultMIDs are the src_64 Occult model MIDs (mid.lua 755-778) of the solo
// flow. 2381 has no sender in the stock UI and stays inactive (C1); the team
// room MIDs belong to the Occult team dispatcher.
var OccultMIDs = []uint16{2362, 2364, 2365, 2366, 2368, 2371, 2372, 2373, 2379, 2380, 2384, 2385}

const occultSoloCampaignType = 2

type OccultPort interface {
	Info(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	CampaignInfo(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	MemberStat(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error)
	Logs(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	CreateSolo(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	ExitRoom(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	Prepare(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
	StartFight(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
	QuitFight(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	ChangePosition(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	Settle(context.Context, identity.ActorContext, app.SettleRequest, operation.Context) (map[string]any, error)
	Sweep(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
}

type OccultDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   OccultPort
}

func (o OccultDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failOccult(d.ErrUnavailable)
	}
	bad := badHero("occult_invalid_parameter")
	params, op := req.Envelope.Params, req.Envelope.Operation
	var body map[string]any
	var err error
	switch req.Envelope.MID {
	case 2362, 2380:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		body, err = o.noArgument(ctx, req.Envelope.MID, a, op)
	case 2364:
		campaign, ok := topFloorInteger(params, "campaign_id", true)
		_, stayOK := topFloorInteger(params, "stay_pos", true)
		if !ok || !stayOK || campaign <= 0 || !onlyStockGameplayParams(params, "campaign_id", "stay_pos") {
			return bad
		}
		body, err = o.Service.CampaignInfo(ctx, a, campaign, op)
	case 2365:
		member, ok := topFloorInteger(params, "player_id", true)
		if !ok || member <= 0 || !onlyStockGameplayParams(params, "player_id") {
			return bad
		}
		body, err = o.Service.MemberStat(ctx, a, identity.PlayerID(member), op)
	case 2366:
		return o.create(ctx, a, params, op)
	case 2368:
		room, ok := topFloorInteger(params, "room_id", true)
		if !ok || room <= 0 || !onlyStockGameplayParams(params, "room_id") {
			return bad
		}
		body, err = o.Service.ExitRoom(ctx, a, room, op)
	case 2371, 2379, 2373:
		campaign, sub, ok := occultStage(params)
		if !ok || !onlyStockGameplayParams(params, "campaign_id", "sub_id") {
			return bad
		}
		body, err = o.stageCommand(ctx, req.Envelope.MID, a, campaign, sub, op)
	case 2372:
		request, ok := occultSettle(params)
		if !ok {
			return bad
		}
		body, err = o.Service.Settle(ctx, a, request, op)
	case 2384:
		position, ok := topFloorInteger(params, "stay_pos", true)
		if !ok || position <= 0 || !onlyStockGameplayParams(params, "stay_pos") {
			return bad
		}
		body, err = o.Service.ChangePosition(ctx, a, position, op)
	case 2385:
		chapter, ok := topFloorInteger(params, "chapter_id", true)
		if !ok || chapter <= 0 || !onlyStockGameplayParams(params, "chapter_id") {
			return bad
		}
		body, err = o.Service.Sweep(ctx, a, chapter, op)
	default:
		return bad
	}
	if err != nil {
		return failOccult(err)
	}
	return okI5(body)
}

func (o OccultDispatcher) noArgument(ctx context.Context, mid uint16, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	if mid == 2362 {
		return o.Service.Info(ctx, a, op)
	}
	return o.Service.Logs(ctx, a, op)
}

func (o OccultDispatcher) stageCommand(ctx context.Context, mid uint16, a identity.ActorContext, campaign, sub int64, op operation.Context) (map[string]any, error) {
	switch mid {
	case 2371:
		return o.Service.Prepare(ctx, a, campaign, sub, op)
	case 2379:
		return o.Service.StartFight(ctx, a, campaign, sub, op)
	}
	return o.Service.QuitFight(ctx, a, op)
}

// create reads 2366. Co-op rooms (campaign_type 1) arrive with the team flow, so
// until then the stock UI gets its ordinary refusal.
func (o OccultDispatcher) create(ctx context.Context, a identity.ActorContext, params map[string]any, op operation.Context) httpedge.Response {
	chapter, chapterOK := topFloorInteger(params, "chapter_id", true)
	campaignType, typeOK := topFloorInteger(params, "campaign_type", true)
	if !chapterOK || !typeOK || chapter <= 0 || campaignType < d.MultiCampaignType || campaignType > d.SingleCampaignType || !onlyStockGameplayParams(params, "chapter_id", "campaign_type") {
		return badHero("occult_invalid_parameter")
	}
	if campaignType != occultSoloCampaignType {
		return okI5(map[string]any{"error_code": int64(1)})
	}
	body, err := o.Service.CreateSolo(ctx, a, chapter, op)
	if err != nil {
		return failOccult(err)
	}
	return okI5(body)
}

func occultStage(params map[string]any) (int64, int64, bool) {
	campaign, campaignOK := topFloorInteger(params, "campaign_id", true)
	sub, subOK := topFloorInteger(params, "sub_id", true)
	return campaign, sub, campaignOK && subOK && campaign > 0 && sub > 0
}

// occultSettle reads BattleCreate:occultResult's 2372. monster_status is
// accepted and ignored: the room owns monster HP.
func occultSettle(params map[string]any) (app.SettleRequest, bool) {
	campaign, sub, stageOK := occultStage(params)
	star, starOK := topFloorInteger(params, "star", true)
	pet, petOK := topFloorInteger(params, "pet_id", false)
	formation, formationOK := topFloorFormation(params["formation"])
	heroes, heroesOK := occultHeroStatus(params["hero_status"])
	allowed := onlyStockGameplayParams(params, "campaign_id", "sub_id", "star", "pet_id", "formation", "hero_status", "monster_status")
	if !allowed || !stageOK || !starOK || !petOK || !formationOK || !heroesOK || star > d.MaxStar || len(formation) > 6 {
		return app.SettleRequest{}, false
	}
	return app.SettleRequest{CampaignID: campaign, SubID: sub, Star: star, PetID: pet, Formation: formation, Heroes: heroes}, true
}

func occultHeroStatus(raw any) (map[int64]d.HeroStatus, bool) {
	rows, ok := raw.(map[string]any)
	if !ok {
		return nil, false
	}
	heroes := make(map[int64]d.HeroStatus, len(rows))
	for key, row := range rows {
		heroID, err := strconv.ParseInt(key, 10, 64)
		fields, isMap := row.(map[string]any)
		if err != nil || heroID <= 0 || !isMap {
			return nil, false
		}
		hp, hpOK := topFloorInteger(fields, "hp", true)
		mp, mpOK := topFloorInteger(fields, "mp", true)
		if !hpOK || !mpOK {
			return nil, false
		}
		heroes[heroID] = d.HeroStatus{HP: hp, MP: mp}
	}
	return heroes, true
}

func failOccult(err error) httpedge.Response {
	var conflict *receipt.ConflictError
	if errors.Is(err, d.ErrInvalid) || errors.As(err, &conflict) {
		return badHero("occult_invalid_parameter")
	}
	refused := errors.Is(err, d.ErrRefused) || errors.Is(err, economy.ErrInsufficientBalance) || errors.Is(err, sr.ErrNotInRoom) || errors.Is(err, sr.ErrAlreadyInRoom)
	if refused {
		return okI5(map[string]any{"error_code": int64(1)})
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "occult_unavailable"}}
}
