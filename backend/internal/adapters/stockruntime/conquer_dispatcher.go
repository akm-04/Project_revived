package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/http"
	"strconv"

	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	d "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	projection "gxb.local/backend/v2/internal/projection/conquerschool"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// ConquerMIDs are the src_64 Conquer School model MIDs (mid.lua 1568-1573, 2790).
var ConquerMIDs = []uint16{1568, 1569, 1570, 1571, 1572, 1573, 2790}

type ConquerPort interface {
	Info(context.Context, identity.ActorContext, operation.Context) (d.InfoView, error)
	Start(context.Context, identity.ActorContext, []int64, int64, operation.Context) (d.InfoView, error)
	Result(context.Context, identity.ActorContext, d.Result, json.RawMessage, operation.Context) (d.ResultView, error)
	Reports(context.Context, int64, int64, int64, operation.Context) ([]d.Report, error)
	Report(context.Context, identity.ActorContext, string, operation.Context) (d.Report, error)
	Reset(context.Context, identity.ActorContext, operation.Context) (d.InfoView, error)
	Buy(context.Context, identity.ActorContext, operation.Context) (d.InfoView, error)
}

type ConquerDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   ConquerPort
}

func (o ConquerDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failConquer(d.ErrUnavailable)
	}
	p, op := req.Envelope.Params, req.Envelope.Operation
	bad := badHero("invalid_conquer_parameter")
	switch req.Envelope.MID {
	case 1568, 1573, 2790:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		change := map[uint16]func(context.Context, identity.ActorContext, operation.Context) (d.InfoView, error){1568: o.Service.Info, 1573: o.Service.Reset, 2790: o.Service.Buy}[req.Envelope.MID]
		v, err := change(ctx, a, op)
		if err != nil {
			return failConquer(err)
		}
		return okI5(projection.InfoBody(v))
	case 1569:
		formation, formationOK := topFloorFormation(p["formation"])
		pet, petOK := topFloorInteger(p, "pet_id", false)
		if !onlyStockGameplayParams(p, "formation", "pet_id") || !formationOK || !petOK {
			return bad
		}
		v, err := o.Service.Start(ctx, a, formation, pet, op)
		if err != nil {
			return failConquer(err)
		}
		return okI5(projection.InfoBody(v))
	case 1570:
		result, report, ok := conquerResult(p)
		if !ok {
			return bad
		}
		v, err := o.Service.Result(ctx, a, result, report, op)
		if err != nil {
			return failConquer(err)
		}
		return okI5(projection.Result(v))
	case 1571:
		loop, loopOK := topFloorInteger(p, "conquer_loop_id", true)
		campaign, campaignOK := topFloorInteger(p, "campaign_id", true)
		team, teamOK := topFloorInteger(p, "team_id", true)
		if !onlyStockGameplayParams(p, "conquer_loop_id", "campaign_id", "team_id") || !loopOK || !campaignOK || !teamOK {
			return bad
		}
		reports, err := o.Service.Reports(ctx, loop, campaign, team, op)
		if err != nil {
			return failConquer(err)
		}
		return okI5(projection.Reports(reports))
	case 1572:
		key, keyed := p["report_key"].(string)
		if !onlyStockGameplayParams(p, "report_key") || !keyed {
			return bad
		}
		report, err := o.Service.Report(ctx, a, key, op)
		if err != nil {
			return failConquer(err)
		}
		return okI5(projection.Report(report))
	}
	return badHero("unsupported_conquer_mid")
}

// conquerResult reads BattleCreate.conquerSchoolResult: total_damage is a sum
// of client harms (possibly fractional, truncated) and report is JSON text.
func conquerResult(p map[string]any) (d.Result, json.RawMessage, bool) {
	campaign, campaignOK := topFloorInteger(p, "campaign_id", true)
	team, teamOK := topFloorInteger(p, "team_id", true)
	pet, petOK := topFloorInteger(p, "pet_id", false)
	alive, aliveOK := topFloorInteger(p, "alive_num", true)
	invalid, invalidOK := topFloorInteger(p, "report_invalid", false)
	formation, formationOK := topFloorFormation(p["formation"])
	win, winOK := conquerFlag(p["is_win"])
	damage, damageOK := conquerDamage(p["total_damage"])
	text, textOK := p["report"].(string)
	allowed := onlyStockGameplayParams(p, "campaign_id", "team_id", "is_win", "formation", "pet_id", "report", "report_invalid", "total_damage", "alive_num")
	if !allowed || !campaignOK || !teamOK || !petOK || !aliveOK || !invalidOK || invalid > 1 || !formationOK || !winOK || !damageOK || !textOK || !json.Valid([]byte(text)) {
		return d.Result{}, nil, false
	}
	return d.Result{CampaignID: campaign, TeamID: team, Win: win, Formation: formation, Pet: pet, Damage: damage, Alive: alive, ReportInvalid: invalid == 1}, json.RawMessage(text), true
}

func conquerFlag(raw any) (bool, bool) {
	if flag, ok := raw.(bool); ok {
		return flag, true
	}
	n, err := feedbackInteger(raw, 0, 1)
	return n == 1, err == nil
}

func conquerDamage(raw any) (int64, bool) {
	value, err := strconv.ParseFloat(fmt.Sprint(raw), 64)
	if err != nil || math.IsNaN(value) || value < 0 || value > float64(d.MaxDamage) {
		return 0, false
	}
	return int64(value), true
}

func failConquer(err error) httpedge.Response {
	if errors.Is(err, d.ErrRefused) || errors.Is(err, d.ErrInvalid) || errors.Is(err, economy.ErrInsufficientBalance) {
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "conquer_request_refused"}}
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "conquer_unavailable"}}
}
