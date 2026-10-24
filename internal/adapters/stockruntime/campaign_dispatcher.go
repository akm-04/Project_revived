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
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// CampaignMIDs are the I9-3A campaign MIDs (mid.lua 112 LOAD_WORLD_MAP, 113 FIGHT, 114 FIGHT_RESULT).
var CampaignMIDs = []uint16{112, 113, 114}

// fightExist is battleConst.errorIdFightExist, which BattleCreate.campaignResult accepts with a full body (F4e).
const fightExist = 30005

type CampaignPort interface {
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
	case 112:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		body, err := o.Service.Load(ctx, a, op)
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
	rentHero, rentHeroOK := topFloorInteger(p, "rent_player_id", false)
	rentPet, rentPetOK := topFloorInteger(p, "rent_pet_player_id", false)
	allowed := onlyStockGameplayParams(p, "campaign_id", "campaign_type", "formation", "pet_id", "rent_player_id", "rent_formation", "rent_pet_player_id", "rent_pet_id")
	// shortcut: borrowed heroes and pets (I8-6A) are refused as malformed; route them through Combat Borrowed when friend rent lands.
	rented := rentHero != 0 || rentPet != 0
	if !allowed || !idOK || !kindOK || !petOK || !formationOK || !rentHeroOK || !rentPetOK || rented {
		return app.Fight{}, false
	}
	return app.Fight{CampaignID: id, Type: kind, Formation: formation, Pet: pet}, true
}

// campaignResult reads BattleCreate.campaignResult's 114.
func campaignResult(p map[string]any) (app.Result, bool) {
	id, idOK := topFloorInteger(p, "campaign_id", true)
	kind, kindOK := topFloorInteger(p, "campaign_type", true)
	star, starOK := topFloorInteger(p, "star", true)
	pet, petOK := topFloorInteger(p, "pet_id", false)
	formation, formationOK := topFloorFormation(p["formation"])
	// shortcut: awake_mission, pet_awaken_mission and assist_partner are accepted and ignored until the I9-4 awakening owner reads them.
	allowed := onlyStockGameplayParams(p, "campaign_id", "campaign_type", "star", "formation", "pet_id", "awake_mission", "pet_awaken_mission", "assist_partner")
	if !allowed || !idOK || !kindOK || !starOK || !petOK || !formationOK {
		return app.Result{}, false
	}
	return app.Result{CampaignID: id, Type: kind, Star: star, Formation: formation, Pet: pet}, true
}

func failCampaign(err error) httpedge.Response {
	if errors.Is(err, d.ErrInvalid) {
		return badHero("campaign_invalid_parameter")
	}
	if errors.Is(err, d.ErrRefused) {
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"error_code": int64(1)}}
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "campaign_unavailable"}}
}
