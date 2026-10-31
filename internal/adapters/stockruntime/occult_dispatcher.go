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
	room "gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// OccultMIDs are the src_64 Occult model MIDs (mid.lua 755-778) of the solo
// flow and the team room. 2381 has no sender in the stock UI and stays inactive
// (C1); 2374-2378, 2382 and 2383 are the co-op fight.
var OccultMIDs = []uint16{2362, 2363, 2364, 2365, 2366, 2367, 2368, 2369, 2370, 2371, 2372, 2373, 2374, 2375, 2376, 2377, 2378, 2379, 2380, 2382, 2383, 2384, 2385}

// occultFightExist is the stock duplicate-terminal code a repeated 2372 answers.
const occultFightExist = 30005

type OccultPort interface {
	Info(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	CampaignInfo(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	MemberStat(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error)
	Logs(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	CreateSolo(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	CreateTeam(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	JoinRoom(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	Invite(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error)
	Kick(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error)
	StartChallenge(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	ExitRoom(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	Prepare(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
	StartFight(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
	QuitFight(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	ChangePosition(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	Settle(context.Context, identity.ActorContext, app.SettleRequest, operation.Context) (app.SettleResponse, error)
	Sweep(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	TeamInvite(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
	TeamAccept(context.Context, identity.ActorContext, int64, int64, bool, operation.Context) (map[string]any, error)
	TeamQuit(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
	TeamPrepare(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
	StartTeamFight(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
	TeamSelect(context.Context, identity.ActorContext, app.FormationRequest, operation.Context) (map[string]any, error)
	TeamReport(context.Context, identity.ActorContext, string, operation.Context) (map[string]any, error)
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
	case 2362, 2363, 2380:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		body, err = o.noArgument(ctx, req.Envelope.MID, a, op)
	case 2367:
		room, ok := topFloorInteger(params, "room_id", true)
		if !ok || room <= 0 || !onlyStockGameplayParams(params, "room_id") {
			return bad
		}
		body, err = o.Service.JoinRoom(ctx, a, room, op)
	case 2369, 2370:
		member, ok := topFloorInteger(params, "player_id", true)
		if !ok || member <= 0 || !onlyStockGameplayParams(params, "player_id") {
			return bad
		}
		body, err = o.memberCommand(ctx, req.Envelope.MID, a, identity.PlayerID(member), op)
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
	case 2375:
		campaign, sub, ok := occultStage(params)
		accept, acceptOK := topFloorInteger(params, "is_accept", true)
		if !ok || !acceptOK || accept > 1 || !onlyStockGameplayParams(params, "campaign_id", "sub_id", "is_accept") {
			return bad
		}
		body, err = o.Service.TeamAccept(ctx, a, campaign, sub, accept == 1, op)
	case 2383:
		request, ok := occultFormation(params)
		if !ok {
			return bad
		}
		body, err = o.Service.TeamSelect(ctx, a, request, op)
	case 2382:
		campaign, _, ok := occultStage(params)
		key, keyOK := params["report_key"].(string)
		if !ok || !keyOK || key == "" || campaign <= 0 || !onlyStockGameplayParams(params, "campaign_id", "sub_id", "report_key") {
			return bad
		}
		body, err = o.Service.TeamReport(ctx, a, key, op)
	case 2371, 2379, 2373, 2374, 2376, 2377, 2378:
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
		settled, err := o.Service.Settle(ctx, a, request, op)
		if err != nil {
			return failOccult(err)
		}
		if settled.Duplicate {
			settled.Body["error_code"] = int64(occultFightExist)
		}
		return okI5(settled.Body)
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
	switch mid {
	case 2362:
		return o.Service.Info(ctx, a, op)
	case 2363:
		return o.Service.StartChallenge(ctx, a, op)
	}
	return o.Service.Logs(ctx, a, op)
}

func (o OccultDispatcher) memberCommand(ctx context.Context, mid uint16, a identity.ActorContext, member identity.PlayerID, op operation.Context) (map[string]any, error) {
	if mid == 2369 {
		return o.Service.Invite(ctx, a, member, op)
	}
	return o.Service.Kick(ctx, a, member, op)
}

func (o OccultDispatcher) stageCommand(ctx context.Context, mid uint16, a identity.ActorContext, campaign, sub int64, op operation.Context) (map[string]any, error) {
	switch mid {
	case 2371:
		return o.Service.Prepare(ctx, a, campaign, sub, op)
	case 2379:
		return o.Service.StartFight(ctx, a, campaign, sub, op)
	case 2374:
		return o.Service.TeamInvite(ctx, a, campaign, sub, op)
	case 2376:
		return o.Service.TeamQuit(ctx, a, campaign, sub, op)
	case 2377:
		return o.Service.StartTeamFight(ctx, a, campaign, sub, op)
	case 2378:
		return o.Service.TeamPrepare(ctx, a, campaign, sub, op)
	}
	return o.Service.QuitFight(ctx, a, op)
}

// create reads 2366: campaign_type 1 opens a team room, 2 a solo room.
func (o OccultDispatcher) create(ctx context.Context, a identity.ActorContext, params map[string]any, op operation.Context) httpedge.Response {
	chapter, chapterOK := topFloorInteger(params, "chapter_id", true)
	campaignType, typeOK := topFloorInteger(params, "campaign_type", true)
	if !chapterOK || !typeOK || chapter <= 0 || campaignType < d.MultiCampaignType || campaignType > d.SingleCampaignType || !onlyStockGameplayParams(params, "chapter_id", "campaign_type") {
		return badHero("occult_invalid_parameter")
	}
	create := o.Service.CreateTeam
	if campaignType == d.SingleCampaignType {
		create = o.Service.CreateSolo
	}
	body, err := create(ctx, a, chapter, op)
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

// occultFormation reads OccultSelectHeroWindow's 2383: a hero at a position, or a pet.
func occultFormation(params map[string]any) (app.FormationRequest, bool) {
	campaign, sub, stageOK := occultStage(params)
	partner, partnerOK := topFloorInteger(params, "partner_id", false)
	position, positionOK := topFloorInteger(params, "pos", false)
	pet, petOK := topFloorInteger(params, "pet_id", false)
	allowed := onlyStockGameplayParams(params, "campaign_id", "sub_id", "partner_id", "pos", "pet_id")
	request := app.FormationRequest{CampaignID: campaign, SubID: sub, PartnerID: partner, Position: position, PetID: pet}
	return request, allowed && stageOK && partnerOK && positionOK && petOK
}

// occultSettle reads BattleCreate:occultResult's 2372. Monster HP is the
// absolute value the client posts; the server bounds it by the catalog maximum.
func occultSettle(params map[string]any) (app.SettleRequest, bool) {
	campaign, sub, stageOK := occultStage(params)
	star, starOK := topFloorInteger(params, "star", true)
	pet, petOK := topFloorInteger(params, "pet_id", false)
	formation, formationOK := topFloorFormation(params["formation"])
	heroes, heroesOK := occultHeroStatus(params["hero_status"])
	monsters, monstersOK := occultMonsterStatus(params["monster_status"])
	allowed := onlyStockGameplayParams(params, "campaign_id", "sub_id", "star", "pet_id", "formation", "hero_status", "monster_status")
	if !allowed || !stageOK || !starOK || !petOK || !formationOK || !heroesOK || !monstersOK || star > d.MaxStar || len(formation) > 6 {
		return app.SettleRequest{}, false
	}
	return app.SettleRequest{CampaignID: campaign, SubID: sub, Star: star, PetID: pet, Formation: formation, Heroes: heroes, Monsters: monsters}, true
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

func occultMonsterStatus(raw any) (map[int64]int64, bool) {
	// A client that carries no monster row is treated as reporting none; the
	// stage keeps the HP it had.
	if raw == nil {
		return map[int64]int64{}, true
	}
	rows, ok := raw.(map[string]any)
	if !ok {
		return nil, false
	}
	monsters := make(map[int64]int64, len(rows))
	for key, row := range rows {
		monsterID, err := strconv.ParseInt(key, 10, 64)
		fields, isMap := row.(map[string]any)
		if err != nil || monsterID <= 0 || !isMap {
			return nil, false
		}
		hp, hpOK := topFloorInteger(fields, "hp", true)
		if !hpOK {
			return nil, false
		}
		monsters[monsterID] = hp
	}
	return monsters, true
}

func failOccult(err error) httpedge.Response {
	var conflict *receipt.ConflictError
	if errors.Is(err, d.ErrInvalid) || errors.As(err, &conflict) {
		return badHero("occult_invalid_parameter")
	}
	for _, refusal := range occultRefusals {
		if errors.Is(err, refusal) {
			return okI5(map[string]any{"error_code": int64(1)})
		}
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "occult_unavailable"}}
}

var occultRefusals = []error{d.ErrRefused, economy.ErrInsufficientBalance, sr.ErrNotInRoom, sr.ErrAlreadyInRoom, sr.ErrNotFound,
	room.ErrFull, room.ErrKicked, room.ErrExpired, room.ErrClosed, room.ErrNotOwner, room.ErrNotSeated}
