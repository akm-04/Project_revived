package stockruntime

import (
	"context"
	"errors"
	"net/http"

	app "gxb.local/backend/v2/internal/application/campaign"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// CampaignMIDs are the I9-3A/B world, fight/result, Super reset and sweep MIDs.
var CampaignMIDs = []uint16{28, 29, 112, 113, 114, 115, 123, 116, 117, 118, 122, 2064, 2576}

// fightExist is battleConst.errorIdFightExist, which BattleCreate.campaignResult accepts with a full body (F4e).
const fightExist = 30005

type CampaignPort interface {
	TrialLoad(context.Context, identity.ActorContext, uint16, operation.Context) (map[string]any, error)
	BuyTrial(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	Bonus(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	ChapterAward(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	StoryAward(context.Context, identity.ActorContext, app.StoryChoice, operation.Context) (map[string]any, error)
	Caps(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Sweep(context.Context, identity.ActorContext, app.Sweep, operation.Context) (map[string]any, error)
	Reset(context.Context, identity.ActorContext, app.Reset, operation.Context) (map[string]any, error)
	Load(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Fight(context.Context, identity.ActorContext, app.Fight, operation.Context) (map[string]any, error)
	Result(context.Context, identity.ActorContext, app.Result, operation.Context) (app.Settled, error)
}

// CampaignDispatcher answers by I9_MODE_FRAMEWORK_V1 F4.
type CampaignDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   CampaignPort
}

func (o CampaignDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failCampaign(d.ErrUnavailable)
	}
	p, op := req.Envelope.Params, req.Envelope.Operation
	bad := badHero("campaign_invalid_parameter")
	switch req.Envelope.MID {
	case 28, 115, 123:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		body, err := o.Service.TrialLoad(ctx, a, req.Envelope.MID, op)
		if err != nil {
			return failCampaign(err)
		}
		return okI5(body)
	case 29:
		id, valid := topFloorInteger(p, "consume_id", true)
		if !valid || id < 1 || id > 10 || !onlyStockGameplayParams(p, "consume_id", "partner_id", "equip_index") {
			return bad
		}
		body, err := o.Service.BuyTrial(ctx, a, id, op)
		if err != nil {
			return failCampaign(err)
		}
		return okI5(body)
	case 112:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		body, err := o.Service.Load(ctx, a, op)
		if err != nil {
			return failCampaign(err)
		}
		return okI5(body)
	case 118:
		kind, valid := topFloorInteger(p, "bonus_type", true)
		if !valid || (kind != d.Normal && kind != d.Super) || !onlyStockGameplayParams(p, "bonus_type") {
			return bad
		}
		body, err := o.Service.Bonus(ctx, a, kind, op)
		if err != nil {
			return failCampaign(err)
		}
		return okI5(body)
	case 122:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		body, err := o.Service.Caps(ctx, a, op)
		if err != nil {
			return failCampaign(err)
		}
		return okI5(body)
	case 2576:
		chapter, valid := topFloorInteger(p, "chapter_id", true)
		if !valid || chapter <= 0 || !onlyStockGameplayParams(p, "chapter_id") {
			return bad
		}
		body, err := o.Service.ChapterAward(ctx, a, chapter, op)
		if err != nil {
			return failCampaign(err)
		}
		return okI5(body)
	case 2064:
		id, x := topFloorInteger(p, "campaign_id", true)
		kind, y := topFloorInteger(p, "campaign_type", true)
		partner, z := topFloorInteger(p, "story_drop_partner", true)
		if !x || !y || !z || id <= 0 || partner <= 0 || kind != d.Normal || !onlyStockGameplayParams(p, "campaign_id", "campaign_type", "story_drop_partner") {
			return bad
		}
		body, err := o.Service.StoryAward(ctx, a, app.StoryChoice{CampaignID: id, Type: kind, Partner: partner}, op)
		if err != nil {
			return failCampaign(err)
		}
		return okI5(body)
	case 113:
		request, ok := campaignFight(p)
		if !ok {
			return bad
		}
		body, err := o.Service.Fight(ctx, a, request, op)
		if err != nil {
			return failCampaign(err)
		}
		return okI5(body)
	case 116:
		id, idOK := topFloorInteger(p, "campaign_id", true)
		kind, kindOK := topFloorInteger(p, "campaign_type", true)
		if !idOK || !kindOK || kind != d.Super || !onlyStockGameplayParams(p, "campaign_id", "campaign_type") {
			return bad
		}
		body, err := o.Service.Reset(ctx, a, app.Reset{CampaignID: id, Type: kind}, op)
		if err != nil {
			return failCampaign(err)
		}
		return okI5(body)
	case 117:
		request, valid := campaignSweep(p)
		if !valid {
			return bad
		}
		body, err := o.Service.Sweep(ctx, a, request, op)
		if err != nil {
			return failCampaign(err)
		}
		return okI5(body)
	case 114:
		request, ok := campaignResult(p)
		if !ok {
			return bad
		}
		settled, err := o.Service.Result(ctx, a, request, op)
		if err != nil {
			return failCampaign(err)
		}
		if settled.Duplicate {
			settled.Body["error_code"] = int64(fightExist)
		}
		return okI5(settled.Body)
	}
	return bad
}

// campaignFight reads SelectTeamWindow's 113.
func campaignFight(p map[string]any) (app.Fight, bool) {
	id, idOK := topFloorInteger(p, "campaign_id", true)
	kind, kindOK := topFloorInteger(p, "campaign_type", true)
	pet, petOK := topFloorInteger(p, "pet_id", false)
	formation, formationOK := topFloorFormation(p["formation"])
	pets := []int64{}
	if d.Cloud(kind) {
		formationOK = p["formation"] == "" && pet == 0
		pets, petOK = topFloorFormation(p["pet_formation"])
	}
	rentHero, rentHeroOK := topFloorInteger(p, "rent_player_id", false)
	rentHeroID, rentHeroIDOK := topFloorIdentifier(p["rent_formation"], false)
	rentPet, rentPetOK := topFloorInteger(p, "rent_pet_player_id", false)
	rentPetID, rentPetIDOK := topFloorIdentifier(p["rent_pet_id"], false)
	allowed := onlyStockGameplayParams(p, "campaign_id", "campaign_type", "formation", "pet_id", "rent_player_id", "rent_formation", "rent_pet_player_id", "rent_pet_id", "pet_formation")
	if !allowed || !idOK || !kindOK || !petOK || !formationOK || !rentHeroOK || !rentHeroIDOK || !rentPetOK || !rentPetIDOK {
		return app.Fight{}, false
	}
	// The client sends each borrowed unit as a player and a formation id pair.
	if (rentHero == 0) != (rentHeroID == 0) || (rentPet == 0) != (rentPetID == 0) {
		return app.Fight{}, false
	}
	if d.Cloud(kind) {
		formation = nil
	} else if _, present := p["pet_formation"]; present {
		return app.Fight{}, false
	}
	return app.Fight{CampaignID: id, Type: kind, Formation: formation, Pet: pet, PetFormation: pets,
		RentPlayer: rentHero, RentFormation: rentHeroID, RentPetPlayer: rentPet, RentPetID: rentPetID}, true
}

// campaignResult reads BattleCreate.campaignResult's 114.
func campaignResult(p map[string]any) (app.Result, bool) {
	id, idOK := topFloorInteger(p, "campaign_id", true)
	kind, kindOK := topFloorInteger(p, "campaign_type", true)
	star, starOK := topFloorInteger(p, "star", true)
	pet, petOK := topFloorInteger(p, "pet_id", false)
	formation, formationOK := topFloorFormation(p["formation"])
	if d.Cloud(kind) {
		formation = nil
		formationOK = (p["formation"] == nil || p["formation"] == "") && pet == 0
	}
	// assist_partner remains the existing unsupported rental input; awakening markers are validated by their owner.
	awake, awakeOK := topFloorInteger(p, "awake_mission", false)
	petAwake, petAwakeOK := topFloorInteger(p, "pet_awaken_mission", false)
	allowed := onlyStockGameplayParams(p, "campaign_id", "campaign_type", "star", "formation", "pet_id", "awake_mission", "pet_awaken_mission", "assist_partner")
	if !allowed || !idOK || !kindOK || !starOK || !petOK || !formationOK || !awakeOK || !petAwakeOK || awake < 0 || petAwake < 0 {
		return app.Result{}, false
	}
	return app.Result{AwakeMission: awake, PetAwakeMission: petAwake, CampaignID: id, Type: kind, Star: star, Formation: formation, Pet: pet}, true
}

func failCampaign(err error) httpedge.Response {
	var conflict *receipt.ConflictError
	if errors.Is(err, d.ErrInvalid) || errors.As(err, &conflict) {
		return badHero("campaign_invalid_parameter")
	}
	if errors.Is(err, d.ErrRefused) {
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"error_code": int64(1)}}
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "campaign_unavailable"}}
}

// campaignSweep reads SweepWindow's forwarded stock params; UI-only compose keys do not affect awards.
func campaignSweep(p map[string]any) (app.Sweep, bool) {
	id, a := topFloorInteger(p, "campaign_id", true)
	kind, b := topFloorInteger(p, "campaign_type", true)
	count, c := topFloorInteger(p, "sweep_num", true)
	method, e := topFloorInteger(p, "sweep_type", true)
	_, awake := topFloorInteger(p, "awake_mission", false)
	_, compose := topFloorInteger(p, "itemComposeID", false)
	_, need := topFloorInteger(p, "needItemComposeNum", false)
	allowed := onlyStockGameplayParams(p, "campaign_id", "campaign_type", "sweep_num", "sweep_type", "awake_mission", "itemComposeID", "needItemComposeNum")
	return app.Sweep{CampaignID: id, Type: kind, Count: count, Kind: method}, a && b && c && e && awake && compose && need && allowed && (kind == d.Normal || kind == d.Super) && count >= 1 && count <= 10 && (method == 1 || method == 2)
}
