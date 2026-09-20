package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"strconv"
	"time"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	heroproj "gxb.local/backend/v2/internal/projection/hero"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type HeroServicePort interface {
	RosterView(context.Context, identity.ActorContext, time.Time) (character.HeroRoot, []apphero.HeroRosterView, error)
	SaveSortType(context.Context, identity.ActorContext, int64, operation.Context) error
	UseExpItem(context.Context, identity.ActorContext, int64, int64, int64, operation.Context) (apphero.ExpResult, error)
	UseExpItems(context.Context, identity.ActorContext, int64, []appi5.HeroExpItemDebit, operation.Context) (apphero.ExpResult, error)
	EquipItem(context.Context, identity.ActorContext, int64, int64, operation.Context) (apphero.EquipItemResult, error)
	OneKeyEquip(context.Context, identity.ActorContext, int64, operation.Context) (apphero.OneKeyEquipResult, error)
	EnhanceSuperEquipment(context.Context, identity.ActorContext, int64, int64, int64, operation.Context) (apphero.EnhanceSuperEquipmentResult, error)
	FeedFumo(context.Context, identity.ActorContext, int64, int64, []int64, operation.Context) (apphero.FumoResult, error)
	PowerUpHero(context.Context, identity.ActorContext, int64, operation.Context) (apphero.HeroPromotionResult, error)
	OneClickJinjie(context.Context, identity.ActorContext, int64, operation.Context) (apphero.HeroPromotionResult, error)
	Evolve(context.Context, identity.ActorContext, int64, operation.Context) error
	HeroPieces(context.Context, identity.ActorContext) (map[int64]int64, error)
	SummonNormal(context.Context, identity.ActorContext, int64, int64, int64, operation.Context) (character.Hero, error)
	CreateVows(context.Context, identity.ActorContext, int64, operation.Context) (character.Hero, error)
}

type HeroEconomyProjectionPort interface {
	CurrentScalar(context.Context, identity.PlayerID, string, operation.Context) (int64, error)
}

type HeroDispatcher struct {
	Authority apprealtime.GameplayAuthorityPort
	Service   HeroServicePort
	Economy   HeroEconomyProjectionPort
}

func (d HeroDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	actor, fail := d.actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "hero_unavailable"}}
	}
	switch req.Envelope.MID {
	case 49:
		if raw, ok := req.Envelope.Params["player_id"]; ok && raw != nil {
			pid, err := requiredInt64(req.Envelope.Params, "player_id")
			if err != nil || pid != int64(actor.PlayerID) {
				return httpedge.Response{HTTPStatus: http.StatusForbidden, Body: map[string]any{"error": "private_hero_roster"}}
			}
		}
		root, heroes, err := d.Service.RosterView(ctx, actor, req.Envelope.Operation.StartedAt)
		if err != nil {
			return failHero(err)
		}
		views := make([]heroproj.RosterHeroView, 0, len(heroes))
		for _, hero := range heroes {
			views = append(views, heroproj.RosterHeroView{Hero: hero.Hero, FumoLevels: hero.FumoLevels, Appearance: heroproj.AppearanceView{OwnerStateVersion: hero.Appearance.OwnerStateVersion, CurrentSkinID: hero.Appearance.CurrentSkinID, IllusionSkinID: hero.Appearance.IllusionSkinID, Skins: func() []heroproj.QualifiedSkinView {
				out := make([]heroproj.QualifiedSkinView, 0, len(hero.Appearance.Skins))
				for _, x := range hero.Appearance.Skins {
					out = append(out, heroproj.QualifiedSkinView{ModelID: x.ModelID, ExpiresAt: x.ExpiresAt})
				}
				return out
			}(), LIVE: func() []heroproj.QualifiedLIVEView {
				out := make([]heroproj.QualifiedLIVEView, 0, len(hero.Appearance.LIVE))
				for _, x := range hero.Appearance.LIVE {
					out = append(out, heroproj.QualifiedLIVEView{ModelID: x.ModelID, IsShow: x.IsShow})
				}
				return out
			}()}})
		}
		body, err := heroproj.StockRosterView(root.SortType, views)
		if err != nil {
			return failHero(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
	case 51: // POWERUP_HERO / Normal-Hero promotion (CA4-3B)
		if !onlyStockGameplayParams(req.Envelope.Params, "partner_id") {
			return badHero("invalid_hero_promotion")
		}
		partnerID, err := requiredInt64(req.Envelope.Params, "partner_id")
		if err != nil || partnerID <= 0 {
			return badHero("invalid_hero_promotion")
		}
		got, err := d.Service.PowerUpHero(ctx, actor, partnerID, req.Envelope.Operation)
		if err != nil {
			return failHero(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: heroPromotionResponse(got)}
	case 57: // ONE_CLICK_JINJIE / one-click promotion-or-collect (CA4-3B)
		if !onlyStockGameplayParams(req.Envelope.Params, "partner_id") {
			return badHero("invalid_hero_one_click_jinjie")
		}
		partnerID, err := requiredInt64(req.Envelope.Params, "partner_id")
		if err != nil || partnerID <= 0 {
			return badHero("invalid_hero_one_click_jinjie")
		}
		got, err := d.Service.OneClickJinjie(ctx, actor, partnerID, req.Envelope.Operation)
		if err != nil {
			return failHero(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: heroPromotionResponse(got)}
	case 52: // EVOLVE_HERO
		if !onlyStockGameplayParams(req.Envelope.Params, "partner_id") {
			return badHero("invalid_hero_evolve")
		}
		partnerID, err := requiredInt64(req.Envelope.Params, "partner_id")
		if err != nil || partnerID <= 0 {
			return badHero("invalid_hero_evolve")
		}
		if err := d.Service.Evolve(ctx, actor, partnerID, req.Envelope.Operation); err != nil {
			return failHero(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	case 54: // SET_HERO_EQUIP (CA4-5 shared Normal/Super production wire)
		if !onlyStockGameplayParams(req.Envelope.Params, "partner_id", "equip_index") {
			return badHero("invalid_hero_equip")
		}
		partnerID, e1 := requiredInt64(req.Envelope.Params, "partner_id")
		equipIndex, e2 := requiredInt64(req.Envelope.Params, "equip_index")
		if e1 != nil || e2 != nil || partnerID <= 0 || equipIndex < 1 || equipIndex > character.HeroEquipmentSlotCount {
			return badHero("invalid_hero_equip")
		}
		got, err := d.Service.EquipItem(ctx, actor, partnerID, equipIndex, req.Envelope.Operation)
		if err != nil {
			return failHero(err)
		}
		if got.AlreadyEquipped {
			return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"error_code": int64(30001)}}
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	case 62: // ONE_KEY_HERO_EQUIP (CA4-5 production-qualified Normal-only wire)
		if !onlyStockGameplayParams(req.Envelope.Params, "partner_id") {
			return badHero("invalid_hero_one_key_equip")
		}
		partnerID, err := requiredInt64(req.Envelope.Params, "partner_id")
		if err != nil || partnerID <= 0 {
			return badHero("invalid_hero_one_key_equip")
		}
		got, err := d.Service.OneKeyEquip(ctx, actor, partnerID, req.Envelope.Operation)
		if err != nil {
			return failHero(err)
		}
		if d.Economy == nil {
			return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "hero_projection_unavailable"}}
		}
		mana, err := d.Economy.CurrentScalar(ctx, actor.PlayerID, "mana", req.Envelope.Operation)
		if err != nil {
			return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "hero_projection_failed"}}
		}
		equips := make([]any, character.HeroEquipmentSlotCount)
		for i, v := range got.Equipment {
			equips[i] = v
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"equips": equips, "economy_": map[string]any{"mana": mana}}}
	case 58: // FUMO_EQUIP / Hero Fumo (CA4-3A)
		if !onlyStockGameplayParams(req.Envelope.Params, "partner_id", "equip_index", "materials") {
			return badHero("invalid_hero_fumo")
		}
		partnerID, e1 := requiredInt64(req.Envelope.Params, "partner_id")
		equipIndex, e2 := requiredInt64(req.Envelope.Params, "equip_index")
		materials, e3 := decodeHeroFumoMaterials(req.Envelope.Params["materials"])
		if e1 != nil || e2 != nil || e3 != nil || partnerID <= 0 || equipIndex < 1 || equipIndex > character.HeroEquipmentSlotCount {
			return badHero("invalid_hero_fumo")
		}
		got, err := d.Service.FeedFumo(ctx, actor, partnerID, equipIndex, materials, req.Envelope.Operation)
		if err != nil {
			return failHero(err)
		}
		if d.Economy == nil {
			return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "hero_projection_unavailable"}}
		}
		mana, err := d.Economy.CurrentScalar(ctx, actor.PlayerID, "mana", req.Envelope.Operation)
		if err != nil {
			return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "hero_projection_failed"}}
		}
		levels := make([]any, character.HeroEquipmentSlotCount)
		for i, v := range got.Levels {
			levels[i] = v
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"fumo": got.Fumo, "fumo_lev": levels, "economy_": map[string]any{"mana": mana}}}
	case 55: // USE_EXP_ITEM
		if !onlyStockGameplayParams(req.Envelope.Params, "item_id", "partner_id", "item_num", "total_num") {
			return badHero("invalid_hero_exp_item")
		}
		itemID, e1 := requiredInt64(req.Envelope.Params, "item_id")
		partnerID, e2 := requiredInt64(req.Envelope.Params, "partner_id")
		itemNum, e3 := requiredInt64(req.Envelope.Params, "item_num")
		totalNum, e4 := requiredInt64(req.Envelope.Params, "total_num")
		if e1 != nil || e2 != nil || e3 != nil || e4 != nil || itemID <= 0 || partnerID <= 0 || itemNum <= 0 || totalNum < 0 {
			return badHero("invalid_hero_exp_item")
		}
		got, err := d.Service.UseExpItem(ctx, actor, partnerID, itemID, itemNum, req.Envelope.Operation)
		if err != nil {
			return failHero(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"item_id": itemID, "partner_exp": got.Exp, "total_num": got.Remaining[itemID]}}
	case 63: // USE_EXP_ITEMS
		if !onlyStockGameplayParams(req.Envelope.Params, "items", "partner_id") {
			return badHero("invalid_hero_exp_items")
		}
		partnerID, err := requiredInt64(req.Envelope.Params, "partner_id")
		if err != nil || partnerID <= 0 {
			return badHero("invalid_hero_exp_items")
		}
		items, err := decodeHeroExpItems(req.Envelope.Params["items"])
		if err != nil {
			return badHero("invalid_hero_exp_items")
		}
		if _, err := d.Service.UseExpItems(ctx, actor, partnerID, items, req.Envelope.Operation); err != nil {
			return failHero(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	case 59: // STONE_SUMMON_HERO (implemented for CA2-3 diagnostics; production router remains unregistered)
		if !onlyStockGameplayParams(req.Envelope.Params, "table_id", "stone", "stone_num") {
			return badHero("invalid_hero_summon")
		}
		tableID, e1 := requiredInt64(req.Envelope.Params, "table_id")
		stoneID, e2 := requiredInt64(req.Envelope.Params, "stone")
		stoneNum, e3 := requiredInt64(req.Envelope.Params, "stone_num")
		if e1 != nil || e2 != nil || e3 != nil || tableID <= 0 || stoneID <= 0 || stoneNum <= 0 {
			return badHero("invalid_hero_summon")
		}
		h, err := d.Service.SummonNormal(ctx, actor, tableID, stoneID, stoneNum, req.Envelope.Operation)
		if err != nil {
			return failHero(err)
		}
		body, err := heroproj.StockHero(h)
		if err != nil {
			return failHero(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
	case 304: // UPGRADE_SUPER_EQUIP (CA4-5)
		if !onlyStockGameplayParams(req.Envelope.Params, "partner_id", "equip_index", "enhance_times") {
			return badHero("invalid_super_equip_enhance")
		}
		partnerID, e1 := requiredInt64(req.Envelope.Params, "partner_id")
		equipIndex, e2 := requiredInt64(req.Envelope.Params, "equip_index")
		enhanceTimes, e3 := requiredInt64(req.Envelope.Params, "enhance_times")
		if e1 != nil || e2 != nil || e3 != nil || partnerID <= 0 || equipIndex < 1 || equipIndex > character.HeroEquipmentSlotCount || enhanceTimes <= 0 {
			return badHero("invalid_super_equip_enhance")
		}
		if _, err := d.Service.EnhanceSuperEquipment(ctx, actor, partnerID, equipIndex, enhanceTimes, req.Envelope.Operation); err != nil {
			return failHero(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	case 305: // SUMMON_SUPER_HERO / Vows (diagnostic only; not production-registered)
		if !onlyStockGameplayParams(req.Envelope.Params, "table_id") {
			return badHero("invalid_vows_create")
		}
		tableID, err := requiredInt64(req.Envelope.Params, "table_id")
		if err != nil || tableID <= 0 {
			return badHero("invalid_vows_create")
		}
		h, err := d.Service.CreateVows(ctx, actor, tableID, req.Envelope.Operation)
		if err != nil {
			return failHero(err)
		}
		partner, err := heroproj.StockHero(h)
		if err != nil {
			return failHero(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"partner_info": partner}}
	case 67: // LOAD_HERO_PIECES
		if !onlyStockGameplayParams(req.Envelope.Params) {
			return badHero("invalid_hero_pieces")
		}
		pieces, err := d.Service.HeroPieces(ctx, actor)
		if err != nil {
			return failHero(err)
		}
		body := make(map[string]any, len(pieces))
		for origin, qty := range pieces {
			body[strconv.FormatInt(origin, 10)] = qty
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
	case 89:
		sortType, err := requiredInt64(req.Envelope.Params, "sort_type")
		if err != nil || sortType < 0 || sortType > character.MaxSortType {
			return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "invalid_hero_sort_type"}}
		}
		if err := d.Service.SaveSortType(ctx, actor, sortType, req.Envelope.Operation); err != nil {
			return failHero(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	default:
		return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error": "not_hero_mid"}}
	}
}
func (d HeroDispatcher) actor(ctx context.Context, req httpedge.DispatchRequest) (identity.ActorContext, *httpedge.Response) {
	if d.Authority == nil || req.Envelope.Claims.Token == "" {
		r := httpedge.Response{HTTPStatus: http.StatusUnauthorized, Body: map[string]any{"error": "gameplay_auth_required"}}
		return identity.ActorContext{}, &r
	}
	a, err := d.Authority.ResolveGameplayBearer(ctx, req.Envelope.Claims.Token, req.Envelope.ReceivedAt)
	if err != nil {
		r := authFailure(err)
		return identity.ActorContext{}, &r
	}
	if req.Envelope.Claims.Region != int64(a.LogicalServerID) {
		r := httpedge.Response{HTTPStatus: http.StatusForbidden, Body: map[string]any{"error": "region_mismatch"}}
		return identity.ActorContext{}, &r
	}
	return a, nil
}
func onlyHeroParams(params map[string]any, allowed ...string) bool {
	set := make(map[string]struct{}, len(allowed))
	for _, k := range allowed {
		set[k] = struct{}{}
	}
	for k := range params {
		if _, ok := set[k]; !ok {
			return false
		}
	}
	return true
}

func decodeHeroFumoMaterials(raw any) ([]int64, error) {
	rows, ok := raw.([]any)
	if !ok || len(rows) == 0 {
		return nil, errors.New("invalid Hero Fumo material list")
	}
	out := make([]int64, 0, len(rows))
	for _, v := range rows {
		id, err := requiredInt64(map[string]any{"item": v}, "item")
		if err != nil || id <= 0 {
			return nil, errors.New("invalid Hero Fumo material")
		}
		out = append(out, id)
	}
	return out, nil
}

func decodeHeroExpItems(raw any) ([]appi5.HeroExpItemDebit, error) {
	rows, ok := raw.([]any)
	if !ok || len(rows) == 0 || len(rows) > 5 {
		return nil, errors.New("invalid Hero EXP item list")
	}
	out := make([]appi5.HeroExpItemDebit, 0, len(rows))
	seen := make(map[int64]struct{}, len(rows))
	for _, rawRow := range rows {
		row, ok := rawRow.(map[string]any)
		if !ok || !onlyHeroParams(row, "item_id", "item_num") || len(row) != 2 {
			return nil, errors.New("invalid Hero EXP item row")
		}
		id, e1 := requiredInt64(row, "item_id")
		n, e2 := requiredInt64(row, "item_num")
		if e1 != nil || e2 != nil || id <= 0 || n <= 0 {
			return nil, errors.New("invalid Hero EXP item row")
		}
		if _, ok := seen[id]; ok {
			return nil, errors.New("duplicate Hero EXP item")
		}
		seen[id] = struct{}{}
		out = append(out, appi5.HeroExpItemDebit{ItemID: id, Count: n})
	}
	return out, nil
}

func heroPromotionResponse(got apphero.HeroPromotionResult) map[string]any {
	body := map[string]any{}
	if len(got.RestoreItems) > 0 {
		rows := make([]any, 0, len(got.RestoreItems))
		for _, award := range got.RestoreItems {
			rows = append(rows, map[string]any{"table_id": award.TableID, "item_num": award.ItemNum})
		}
		body["restore_items"] = rows
	}
	if got.ManaAfter != nil {
		body["economy_"] = map[string]any{"mana": *got.ManaAfter}
	}
	return body
}

func badHero(code string) httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": code}}
}

func failHero(err error) httpedge.Response {
	if errors.Is(err, apphero.ErrHeroContentInactive) || errors.Is(err, apphero.ErrHeroProgressionContentInactive) || errors.Is(err, apphero.ErrHeroEquipmentContentInactive) || errors.Is(err, apphero.ErrHeroFumoContentInactive) || errors.Is(err, apphero.ErrHeroPromotionContentInactive) || errors.Is(err, apphero.ErrHeroCapacityUnavailable) {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "hero_content_inactive"}}
	}
	if errors.Is(err, apphero.ErrHeroExpMax) || errors.Is(err, apphero.ErrHeroEvolutionUnavailable) || errors.Is(err, apphero.ErrHeroPrerequisites) || errors.Is(err, apphero.ErrHeroNotFound) || errors.Is(err, apphero.ErrHeroCapacityExceeded) || errors.Is(err, apphero.ErrHeroDuplicateOrigin) || errors.Is(err, apphero.ErrHeroAcquisitionInvalid) || errors.Is(err, apphero.ErrHeroVowsLevel) || errors.Is(err, apphero.ErrHeroEquipmentUnavailable) || errors.Is(err, apphero.ErrHeroFumoUnavailable) || errors.Is(err, apphero.ErrHeroPromotionUnavailable) || errors.Is(err, apphero.ErrHeroPromotionPrerequisites) || errors.Is(err, apphero.ErrHeroPromotionCorruptState) {
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "hero_operation_rejected"}}
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "hero_operation_failed"}}
}
