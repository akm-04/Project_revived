package stockruntime

import (
	"context"
	"errors"
	"net/http"

	app "gxb.local/backend/v2/internal/application/arena"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	projection "gxb.local/backend/v2/internal/projection/arena"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// Arena stock MIDs (src_64 mid.lua REARENA family plus the mission and
// exchange MIDs RegionArena.lua sends). 774/778 serve only the client-resolved
// battle path and 775 has no window caller; they are refused.
var ArenaMIDs = []uint16{666, 768, 769, 770, 771, 772, 773, 774, 775, 776, 777, 778, 779, 848, 849}

type ArenaPort interface {
	Info(context.Context, identity.ActorContext, operation.Context) (d.InfoView, error)
	Partners(context.Context, identity.ActorContext) (d.PartnersView, error)
	ModifyDefence(context.Context, identity.ActorContext, []int64, int64, operation.Context) (d.Player, error)
	Match(context.Context, identity.ActorContext, bool, operation.Context) (d.EnemyView, error)
	Start(context.Context, identity.ActorContext, operation.Context) error
	Fight(context.Context, identity.ActorContext, app.FightCommand, operation.Context) (d.FightView, error)
	Stop(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (d.Player, error)
	Records(context.Context, identity.ActorContext) ([]d.RecordView, error)
	Report(context.Context, string) ([]byte, bool, error)
	GiveUpMission(context.Context, identity.ActorContext, int64, operation.Context) (d.MissionsView, error)
	ClaimMission(context.Context, identity.ActorContext, int64, operation.Context) (d.MissionsView, error)
	Exchange(context.Context, identity.ActorContext, int64, int64, operation.Context) (d.MissionsView, error)
}

type ArenaDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   ArenaPort
}

func (o ArenaDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failArena(d.ErrUnavailable)
	}
	p, op := req.Envelope.Params, req.Envelope.Operation
	bad := badHero("invalid_arena_parameter")
	switch req.Envelope.MID {
	case 768:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		v, err := o.Service.Info(ctx, a, op)
		if err != nil {
			return failArena(err)
		}
		return okI5(projection.Info(v))
	case 769:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		v, err := o.Service.Partners(ctx, a)
		if err != nil {
			return failArena(err)
		}
		return okI5(projection.Partners(v))
	case 770:
		heroes, err := arenaTableIDs(p["heros"])
		pet, petOK := topFloorInteger(p, "pet_id", false)
		if !onlyStockGameplayParams(p, "heros", "pet_id") || err != nil || !petOK {
			return bad
		}
		player, err := o.Service.ModifyDefence(ctx, a, heroes, pet, op)
		if err != nil {
			return failArena(err)
		}
		return okI5(map[string]any{"defence_formation": player.Defense.Heroes, "pet_id": player.Defense.Pet})
	case 771:
		practice, ok := topFloorInteger(p, "is_practice", false)
		if !onlyStockGameplayParams(p, "is_practice") || !ok || practice > 1 {
			return bad
		}
		v, err := o.Service.Match(ctx, a, practice == 1, op)
		if err != nil {
			return failArena(err)
		}
		return okI5(projection.Enemy(v))
	case 772:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		if err := o.Service.Start(ctx, a, op); err != nil {
			return failArena(err)
		}
		// The server always resolves the battle (SERVER_REPORT_AUTHORITATIVE).
		return okI5(map[string]any{"is_back_battle": int64(1)})
	case 773:
		enemy, enemyOK := topFloorInteger(p, "enemy_id", true)
		practice, practiceOK := topFloorInteger(p, "is_test", false)
		pet, petOK := topFloorInteger(p, "pet_id", false)
		_, campaignOK := topFloorInteger(p, "campaign_id", false)
		formation, err := arenaTableIDs(p["formation"])
		if !onlyStockGameplayParams(p, "enemy_id", "is_test", "pet_id", "campaign_id", "formation") || !enemyOK || !practiceOK || practice > 1 || !petOK || !campaignOK || err != nil {
			return bad
		}
		v, err := o.Service.Fight(ctx, a, app.FightCommand{Enemy: identity.PlayerID(enemy), Practice: practice == 1, Formation: formation, Pet: pet}, op)
		if errors.Is(err, app.ErrUnresolved) {
			return okI5(projection.Fight(d.FightView{Unresolved: true}))
		}
		if err != nil {
			return failArena(err)
		}
		return okI5(projection.Fight(v))
	case 776:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		records, err := o.Service.Records(ctx, a)
		if err != nil {
			return failArena(err)
		}
		return okI5(projection.Records(records))
	case 777:
		key, keyed := p["report_key"].(string)
		if !onlyStockGameplayParams(p, "report_key") || !keyed {
			return bad
		}
		report, found, err := o.Service.Report(ctx, key)
		if err != nil && !errors.Is(err, d.ErrInvalid) {
			return failArena(err)
		}
		if !found {
			// An expired record answers empty (ARENA_RECORD_OUT_OF_DATE toast).
			return okI5(map[string]any{})
		}
		return okI5(projection.Report(report))
	case 779:
		enemy, ok := topFloorInteger(p, "enemy_id", true)
		if !onlyStockGameplayParams(p, "enemy_id") || !ok {
			return bad
		}
		player, err := o.Service.Stop(ctx, a, identity.PlayerID(enemy), op)
		if err != nil {
			return failArena(err)
		}
		return okI5(map[string]any{"star": player.Star})
	case 666, 849:
		mission, ok := topFloorInteger(p, "mission_id", true)
		if !onlyStockGameplayParams(p, "mission_id") || !ok {
			return bad
		}
		change := o.Service.GiveUpMission
		if req.Envelope.MID == 849 {
			change = o.Service.ClaimMission
		}
		v, err := change(ctx, a, mission, op)
		if err != nil {
			return failArena(err)
		}
		return okI5(projection.Missions(v))
	case 848:
		exchange, exchangeOK := topFloorInteger(p, "exchange_type", true)
		table, tableOK := topFloorInteger(p, "table_id", true)
		if !onlyStockGameplayParams(p, "exchange_type", "table_id") || !exchangeOK || !tableOK {
			return bad
		}
		v, err := o.Service.Exchange(ctx, a, exchange, table, op)
		if err != nil {
			return failArena(err)
		}
		return okI5(projection.Missions(v))
	}
	return badHero("unsupported_arena_mid")
}

// arenaTableIDs reads a JSON list of up to five positive table ids.
func arenaTableIDs(raw any) ([]int64, error) {
	list, ok := raw.([]any)
	if !ok || len(list) > d.TeamSize {
		return nil, d.ErrInvalid
	}
	out := make([]int64, 0, len(list))
	for _, x := range list {
		n, err := feedbackInteger(x, 1, 9007199254740991)
		if err != nil {
			return nil, err
		}
		out = append(out, n)
	}
	return out, nil
}

func failArena(err error) httpedge.Response {
	if errors.Is(err, d.ErrRefused) || errors.Is(err, d.ErrInvalid) || errors.Is(err, d.ErrClosed) || errors.Is(err, economy.ErrInsufficientBalance) {
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "arena_request_refused"}}
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "arena_unavailable"}}
}
