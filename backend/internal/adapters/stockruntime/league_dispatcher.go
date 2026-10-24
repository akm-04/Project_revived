package stockruntime

import (
	"context"
	"errors"
	app "gxb.local/backend/v2/internal/application/championsleague"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	d "gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	projection "gxb.local/backend/v2/internal/projection/championsleague"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
	"strconv"
	"strings"
)

var LeagueMIDs = []uint16{2800, 2801, 2802, 2803, 2804, 2805, 2806, 2807}

type LeaguePort interface {
	Execute(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Reply, error)
}
type LeagueDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   LeaguePort
}

func leagueFormation(raw any, empty bool) (d.Lineup, error) {
	s, ok := raw.(string)
	if !ok {
		return d.Lineup{}, d.ErrInvalid
	}
	l := d.Lineup{Heroes: []int64{}}
	if s != "" {
		for _, x := range strings.Split(s, "|") {
			id, e := strconv.ParseInt(x, 10, 64)
			if e != nil || id <= 0 || id > 9007199254740991 {
				return l, d.ErrInvalid
			}
			l.Heroes = append(l.Heroes, id)
		}
	}
	if !l.Valid(empty) {
		return l, d.ErrInvalid
	}
	return l, nil
}
func (o LeagueDispatcher) Dispatch(c context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(c, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failLeague(d.ErrUnavailable)
	}
	p, mid := req.Envelope.Params, req.Envelope.MID
	cmd := app.Command{}
	bad := badHero("invalid_league_parameter")
	switch mid {
	case 2800:
		cmd.Kind = "INFO"
		if !onlyStockGameplayParams(p) {
			return bad
		}
	case 2801:
		cmd.Kind = "ENEMY"
		n, ok := topFloorInteger(p, "enemy_id", true)
		if !onlyStockGameplayParams(p, "enemy_id") || !ok {
			return bad
		}
		cmd.Enemy = identity.PlayerID(n)
	case 2802, 2805:
		cmd.Kind = "DEFENSE"
		if mid == 2802 {
			cmd.Kind = "FIGHT"
		}
		l, e := leagueFormation(p["formation"], mid == 2805)
		pet, ok := topFloorInteger(p, "pet_id", false)
		if e != nil || !ok {
			return bad
		}
		l.Pet = pet
		cmd.Lineup = l
		if mid == 2802 {
			enemy, ok := topFloorInteger(p, "enemy_id", true)
			if !ok || !onlyStockGameplayParams(p, "formation", "enemy_id", "pet_id") {
				return bad
			}
			cmd.Enemy = identity.PlayerID(enemy)
		} else if !onlyStockGameplayParams(p, "formation", "pet_id") {
			return bad
		}
	case 2803:
		cmd.Kind = "RECORDS"
		n, ok := topFloorInteger(p, "id", false)
		if !onlyStockGameplayParams(p, "id") || !ok {
			return bad
		}
		cmd.RecordID = n
	case 2804:
		cmd.Kind = "CLAIM"
		if !onlyStockGameplayParams(p) {
			return bad
		}
	case 2806:
		cmd.Kind = "CHOOSE"
		n, ok := topFloorInteger(p, "use_ori_rank", false)
		if _, exists := p["use_ori_rank"]; !exists || !onlyStockGameplayParams(p, "use_ori_rank") || !ok || n > 1 {
			return bad
		}
		cmd.UseOriginal = n == 1
	case 2807:
		cmd.Kind = "HONOR"
		if !onlyStockGameplayParams(p) {
			return bad
		}
	default:
		return bad
	}
	v, e := o.Service.Execute(c, a, cmd, req.Envelope.Operation)
	if e != nil {
		return failLeague(e)
	}
	switch mid {
	case 2800:
		return okI5(projection.Info(v.Info))
	case 2801:
		return okI5(projection.Enemy(v.Enemy))
	case 2802:
		return okI5(projection.Fight(v))
	case 2803:
		if cmd.RecordID > 0 {
			return okI5(projection.Report(v.Report))
		}
		return okI5(projection.RecordRows(v.Records, a.PlayerID))
	case 2804:
		awards := v.Awards
		if awards == nil {
			awards = []app.Item{}
		}
		return okI5(map[string]any{"awards": awards})
	case 2807:
		return httpedge.Response{HTTPStatus: http.StatusOK, JSON: projection.Honor(v.Honor)}
	default:
		return okI5(map[string]any{})
	}
}
func failLeague(e error) httpedge.Response {
	if errors.Is(e, d.ErrRefused) || errors.Is(e, d.ErrInvalid) {
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "league_request_refused"}}
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: e, Body: map[string]any{"error": "league_unavailable"}}
}
