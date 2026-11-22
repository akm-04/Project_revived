package stockruntime

import (
	"context"
	"net/http"

	app "gxb.local/backend/v2/internal/application/oneonone"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/oneonone"
	"gxb.local/backend/v2/internal/foundation/operation"
	projection "gxb.local/backend/v2/internal/projection/oneonone"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// 1 on 1 stock MIDs (src_64 mid.lua PEAK family); old Peak 560-571 stay unregistered.
var OneOnOneMIDs = []uint16{2480, 2481, 2482, 2483, 2484, 2485, 2486, 2487, 2488, 2489}

type OneOnOnePort interface {
	Load(context.Context, identity.ActorContext, operation.Context) (d.ArenaView, error)
	ChangeTeams(context.Context, identity.ActorContext, []d.Team, operation.Context) error
	Match(context.Context, identity.ActorContext, operation.Context) ([]d.Entry, error)
	EnemyTeam(context.Context, identity.PlayerID) ([]d.TeamView, error)
	Start(context.Context, identity.ActorContext, app.StartCommand, operation.Context) (d.MatchView, error)
	Report(context.Context, string, operation.Context) ([]byte, error)
	DefenseReportKeys(context.Context, identity.ActorContext, operation.Context) ([]string, error)
	BuyTimes(context.Context, identity.ActorContext, operation.Context) (d.Player, error)
	Records(context.Context, identity.ActorContext, operation.Context) ([]d.RecordView, error)
	ResetTime(context.Context, identity.ActorContext, operation.Context) (d.Player, error)
	RecordDetail(context.Context, int64) (d.RecordDetail, error)
}

type OneOnOneDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   OneOnOnePort
}

func oneOnOneFormations(raw any) ([]d.Team, bool) {
	list, ok := raw.([]any)
	if !ok {
		return nil, false
	}
	texts := []string{}
	for _, x := range list {
		text, ok := x.(string)
		if !ok {
			return nil, false
		}
		texts = append(texts, text)
	}
	return projection.ParseFormations(texts)
}

func (o OneOnOneDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failureReply(defect(nil))
	}
	p, op := req.Envelope.Params, req.Envelope.Operation
	switch req.Envelope.MID {
	case 2480:
		if !onlyStockGameplayParams(p) {
			return badHero("invalid_one_on_one_parameter")
		}
		v, err := o.Service.Load(ctx, a, op)
		if err != nil {
			return failOneOnOne(err)
		}
		return okI5(projection.Load(v))
	case 2481:
		teams, ok := oneOnOneFormations(p["formations"])
		if !onlyStockGameplayParams(p, "formations") || !ok {
			return badHero("invalid_one_on_one_parameter")
		}
		if err := o.Service.ChangeTeams(ctx, a, teams, op); err != nil {
			return failOneOnOne(err)
		}
		return okI5(map[string]any{})
	case 2482:
		if !onlyStockGameplayParams(p) {
			return badHero("invalid_one_on_one_parameter")
		}
		rows, err := o.Service.Match(ctx, a, op)
		if err != nil {
			return failOneOnOne(err)
		}
		return okI5(projection.Matches(rows))
	case 2483:
		enemy, ok := topFloorInteger(p, "enemy_id", true)
		if !onlyStockGameplayParams(p, "enemy_id") || !ok {
			return badHero("invalid_one_on_one_parameter")
		}
		teams, err := o.Service.EnemyTeam(ctx, identity.PlayerID(enemy))
		if err != nil {
			return failOneOnOne(err)
		}
		return okI5(map[string]any{"defense": projection.Teams(teams)})
	case 2484:
		teams, teamsOK := oneOnOneFormations(p["formations"])
		enemy, enemyOK := topFloorInteger(p, "enemy_id", true)
		if !onlyStockGameplayParams(p, "formations", "enemy_id") || !teamsOK || !enemyOK {
			return badHero("invalid_one_on_one_parameter")
		}
		v, err := o.Service.Start(ctx, a, app.StartCommand{Formations: teams, Enemy: identity.PlayerID(enemy)}, op)
		if err != nil {
			return failOneOnOne(err)
		}
		return okI5(projection.Start(v))
	case 2485:
		key, keyed := p["report_key"].(string)
		if !onlyStockGameplayParams(p, "report_key") || !keyed && p["report_key"] != nil {
			return badHero("invalid_one_on_one_parameter")
		}
		if !keyed {
			keys, err := o.Service.DefenseReportKeys(ctx, a, op)
			if err != nil {
				return failOneOnOne(err)
			}
			return httpedge.Response{HTTPStatus: http.StatusOK, JSON: projection.ReportKeys(keys)}
		}
		report, err := o.Service.Report(ctx, key, op)
		if err != nil {
			return failOneOnOne(err)
		}
		return okI5(projection.Report(report))
	case 2486, 2488:
		if !onlyStockGameplayParams(p) {
			return badHero("invalid_one_on_one_parameter")
		}
		change := o.Service.BuyTimes
		if req.Envelope.MID == 2488 {
			change = o.Service.ResetTime
		}
		player, err := change(ctx, a, op)
		if err != nil {
			return failOneOnOne(err)
		}
		return okI5(map[string]any{"left_times": player.TriesLeft, "buy_times": player.Purchases})
	case 2487:
		if !onlyStockGameplayParams(p) {
			return badHero("invalid_one_on_one_parameter")
		}
		records, err := o.Service.Records(ctx, a, op)
		if err != nil {
			return failOneOnOne(err)
		}
		return okI5(projection.Records(records))
	case 2489:
		id, ok := topFloorInteger(p, "record_id", true)
		_, sharerOK := topFloorInteger(p, "player_id", false)
		if !onlyStockGameplayParams(p, "record_id", "player_id") || !ok || !sharerOK {
			return badHero("invalid_one_on_one_parameter")
		}
		v, err := o.Service.RecordDetail(ctx, id)
		if err != nil {
			return failOneOnOne(err)
		}
		return okI5(projection.RecordDetail(v))
	}
	return badHero("unsupported_one_on_one_mid")
}

// oneOnOneRankChangedError is stock message 35026 ("The ranking has changed,
// please refresh and challenge again"), shown by the shared Backend error toast.
const oneOnOneRankChangedError = 35026

// Stock message codes for the closed-hours and low-point refusals, shown by the
// shared Backend error toast like 35026.
const (
	oneOnOneClosedHoursError = 30002
	oneOnOneLowPointsError   = 30003
)

var oneOnOneFailureRows = []failureRow{
	{match: d.ErrOfferStale, class: failureRefusal, code: oneOnOneRankChangedError},
	{match: d.ErrClosedHours, class: failureRefusal, code: oneOnOneClosedHoursError},
	{match: d.ErrOpponentLowPoints, class: failureRefusal, code: oneOnOneLowPointsError},
	{match: d.ErrRefused, class: failureRefusal, code: unprovenRefusalCode},
	{match: d.ErrInvalid, class: failureMalformed, detail: "one_on_one_request_refused"},
	{match: app.ErrUnresolved, class: failureUnavailable},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
}

func failOneOnOne(err error) httpedge.Response {
	return failureFromRows(oneOnOneFailureRows, err)
}
