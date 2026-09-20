package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	"math"
	"net/http"
	"strconv"
	"strings"
	"time"

	apppet "gxb.local/backend/v2/internal/application/characterpet"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	petproj "gxb.local/backend/v2/internal/projection/pet"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type PetServicePort interface {
	RosterView(context.Context, identity.ActorContext, time.Time) (character.PetRoot, []apppet.PetRosterView, error)
	Summon(context.Context, identity.ActorContext, int64, operation.Context) (character.Pet, error)
	CleanCD(context.Context, identity.ActorContext, int64, operation.Context) (apppet.HatchResult, error)
	SetShow(context.Context, identity.ActorContext, int64, operation.Context) error
	Evolve(context.Context, identity.ActorContext, int64, operation.Context) (apppet.EvolveResult, error)
	Feed(context.Context, identity.ActorContext, int64, int64, int64, operation.Context) (apppet.ExpResult, error)
	UseExpItems(context.Context, identity.ActorContext, int64, []appi5.PetExpItemDebit, operation.Context) (apppet.ExpResult, error)
	UpgradeSkills(context.Context, identity.ActorContext, int64, []apppet.SkillUpgrade, operation.Context) (apppet.SkillResult, error)
	EquipItem(context.Context, identity.ActorContext, int64, int64, operation.Context) (apppet.EquipItemResult, error)
	OneKeyEquip(context.Context, identity.ActorContext, int64, operation.Context) (apppet.OneKeyEquipResult, error)
	Advance(context.Context, identity.ActorContext, int64, operation.Context) (apppet.AdvanceResult, error)
	OneKeyAdvance(context.Context, identity.ActorContext, int64, operation.Context) (apppet.OneKeyAdvanceResult, error)
	AcquirePetStyle(context.Context, identity.ActorContext, int64, operation.Context) (apppet.PetStyleAcquireResult, error)
	SelectPetStyle(context.Context, identity.ActorContext, int64, int64, operation.Context) (apppet.PetStyleSelectResult, error)
	CancelPetStyle(context.Context, identity.ActorContext, int64, operation.Context) (apppet.PetStyleCancelResult, error)
}

type PetEconomyProjectionPort interface {
	CurrentScalar(context.Context, identity.PlayerID, string, operation.Context) (int64, error)
}

type PetDispatcher struct {
	Authority apprealtime.GameplayAuthorityPort
	Service   PetServicePort
	Economy   PetEconomyProjectionPort
}

func (d PetDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	actor, fail := d.petActor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "pet_unavailable"}}
	}
	switch req.Envelope.MID {
	case 780:
		if !onlyStockGameplayParams(req.Envelope.Params) {
			return petBad("invalid_pet_roster")
		}
		_, pets, err := d.Service.RosterView(ctx, actor, req.Envelope.Operation.StartedAt)
		if err != nil {
			return petFail(err)
		}
		views := make([]petproj.RosterPetView, 0, len(pets))
		for _, pet := range pets {
			views = append(views, petproj.RosterPetView{Pet: pet.Pet, Appearance: petproj.AppearanceView{OwnerStateVersion: pet.Appearance.OwnerStateVersion, ActiveStyle: pet.Appearance.ActiveStyle, OwnedStyles: append([]int64(nil), pet.Appearance.OwnedStyles...)}})
		}
		body, err := petproj.StockRosterView(views)
		if err != nil {
			return petFail(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
	case 781:
		if !onlyStockGameplayParams(req.Envelope.Params, "table_id") {
			return petBad("invalid_pet_summon")
		}
		tableID, err := requiredInt64(req.Envelope.Params, "table_id")
		if err != nil || tableID <= 0 {
			return petBad("invalid_pet_summon")
		}
		p, err := d.Service.Summon(ctx, actor, tableID, req.Envelope.Operation)
		if err != nil {
			return petFail(err)
		}
		body, err := petproj.StockPrivate(p, true)
		if err != nil {
			return petFail(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
	case 782:
		if !onlyStockGameplayParams(req.Envelope.Params, "pet_id") {
			return petBad("invalid_pet_clean_cd")
		}
		petID, err := requiredInt64(req.Envelope.Params, "pet_id")
		if err != nil || petID <= 0 {
			return petBad("invalid_pet_clean_cd")
		}
		if _, err := d.Service.CleanCD(ctx, actor, petID, req.Envelope.Operation); err != nil {
			return petFail(err)
		}
		if d.Economy == nil {
			return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "pet_projection_unavailable"}}
		}
		crystal, err := d.Economy.CurrentScalar(ctx, actor.PlayerID, "crystal", req.Envelope.Operation)
		if err != nil {
			return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "pet_projection_failed"}}
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"economy_": map[string]any{"crystal": crystal}}}
	case 789:
		if !onlyStockGameplayParams(req.Envelope.Params, "pet_id") {
			return petBad("invalid_pet_set_show")
		}
		petID, err := requiredInt64(req.Envelope.Params, "pet_id")
		if err != nil || petID <= 0 {
			return petBad("invalid_pet_set_show")
		}
		if err := d.Service.SetShow(ctx, actor, petID, req.Envelope.Operation); err != nil {
			return petFail(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	case 1893: // GET_PET_STYLE_FORM_ITEM — CA7-5 grant-only ownership convergence
		if !onlyStockGameplayParams(req.Envelope.Params, "item_id") {
			return petBad("invalid_pet_style_acquire")
		}
		itemID, err := requiredPetInt64(req.Envelope.Params, "item_id")
		if err != nil || itemID <= 0 {
			return petBad("invalid_pet_style_acquire")
		}
		got, err := d.Service.AcquirePetStyle(ctx, actor, itemID, req.Envelope.Operation)
		if err != nil {
			return petFail(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"active_style": got.ActiveStyle, "pet_styles": append([]int64(nil), got.PetStyles...)}}
	case 1894: // USE_PET_STYLE — CA7-5 explicit owned-style assignment
		if !onlyStockGameplayParams(req.Envelope.Params, "pet_id", "style_id") {
			return petBad("invalid_pet_style_select")
		}
		petID, e1 := requiredPetInt64(req.Envelope.Params, "pet_id")
		styleID, e2 := requiredPetInt64(req.Envelope.Params, "style_id")
		if e1 != nil || e2 != nil || petID <= 0 || styleID <= 0 {
			return petBad("invalid_pet_style_select")
		}
		got, err := d.Service.SelectPetStyle(ctx, actor, petID, styleID, req.Envelope.Operation)
		if err != nil {
			return petFail(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"active_style": got.ActiveStyle}}
	case 1895: // CANCEL_PET_STYLE — CA7-5 explicit active_style=0 assignment
		if !onlyStockGameplayParams(req.Envelope.Params, "pet_id") {
			return petBad("invalid_pet_style_cancel")
		}
		petID, err := requiredPetInt64(req.Envelope.Params, "pet_id")
		if err != nil || petID <= 0 {
			return petBad("invalid_pet_style_cancel")
		}
		if _, err := d.Service.CancelPetStyle(ctx, actor, petID, req.Envelope.Operation); err != nil {
			return petFail(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	case 783: // PET_EQUIP (CA4-4A)
		if !onlyStockGameplayParams(req.Envelope.Params, "pet_id", "equip_index") {
			return petBad("invalid_pet_equip")
		}
		petID, e1 := requiredPetInt64(req.Envelope.Params, "pet_id")
		equipIndex, e2 := requiredPetInt64(req.Envelope.Params, "equip_index")
		if e1 != nil || e2 != nil || petID <= 0 || equipIndex < 1 || equipIndex > character.PetEquipmentSlotCount {
			return petBad("invalid_pet_equip")
		}
		got, err := d.Service.EquipItem(ctx, actor, petID, equipIndex, req.Envelope.Operation)
		if err != nil {
			return petFail(err)
		}
		if got.AlreadyEquipped {
			return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"error_code": int64(30001)}}
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	case 785: // PET_ADVANCE (CA4-4B)
		if !onlyStockGameplayParams(req.Envelope.Params, "pet_id") {
			return petBad("invalid_pet_advance")
		}
		petID, err := requiredPetInt64(req.Envelope.Params, "pet_id")
		if err != nil || petID <= 0 {
			return petBad("invalid_pet_advance")
		}
		got, err := d.Service.Advance(ctx, actor, petID, req.Envelope.Operation)
		if err != nil {
			return petFail(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: petRestorationResponse(got.RestoreItems)}
	case 790: // PET_ONE_KEY_UP (CA4-4B)
		if !onlyStockGameplayParams(req.Envelope.Params, "pet_id") {
			return petBad("invalid_pet_one_key_up")
		}
		petID, err := requiredPetInt64(req.Envelope.Params, "pet_id")
		if err != nil || petID <= 0 {
			return petBad("invalid_pet_one_key_up")
		}
		got, err := d.Service.OneKeyAdvance(ctx, actor, petID, req.Envelope.Operation)
		if err != nil {
			return petFail(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: petRestorationResponse(got.RestoreItems)}
	case 786: // PET_EVOLVE
		if !onlyStockGameplayParams(req.Envelope.Params, "pet_id") {
			return petBad("invalid_pet_evolve")
		}
		petID, err := requiredPetInt64(req.Envelope.Params, "pet_id")
		if err != nil || petID <= 0 {
			return petBad("invalid_pet_evolve")
		}
		if _, err := d.Service.Evolve(ctx, actor, petID, req.Envelope.Operation); err != nil {
			return petFail(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	case 787: // PET_FEED
		if !onlyStockGameplayParams(req.Envelope.Params, "pet_id", "item_id", "item_num") {
			return petBad("invalid_pet_feed")
		}
		petID, e1 := requiredPetInt64(req.Envelope.Params, "pet_id")
		itemID, e2 := requiredPetInt64(req.Envelope.Params, "item_id")
		itemNum, e3 := requiredPetInt64(req.Envelope.Params, "item_num")
		if e1 != nil || e2 != nil || e3 != nil || petID <= 0 || itemNum <= 0 || !isPetExpItem(itemID) {
			return petBad("invalid_pet_feed")
		}
		if _, err := d.Service.Feed(ctx, actor, petID, itemID, itemNum, req.Envelope.Operation); err != nil {
			return petFail(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	case 134: // PET_USE_EXP_ITEMS
		if !onlyStockGameplayParams(req.Envelope.Params, "pet_id", "items") {
			return petBad("invalid_pet_exp_items")
		}
		petID, err := requiredPetInt64(req.Envelope.Params, "pet_id")
		if err != nil || petID <= 0 {
			return petBad("invalid_pet_exp_items")
		}
		items, err := decodePetExpItems(req.Envelope.Params["items"])
		if err != nil {
			return petBad("invalid_pet_exp_items")
		}
		if _, err := d.Service.UseExpItems(ctx, actor, petID, items, req.Envelope.Operation); err != nil {
			return petFail(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	case 792: // PET_ONE_KEY_EQUIP (CA4-4A)
		if !onlyStockGameplayParams(req.Envelope.Params, "pet_id") {
			return petBad("invalid_pet_one_key_equip")
		}
		petID, err := requiredPetInt64(req.Envelope.Params, "pet_id")
		if err != nil || petID <= 0 {
			return petBad("invalid_pet_one_key_equip")
		}
		if _, err := d.Service.OneKeyEquip(ctx, actor, petID, req.Envelope.Operation); err != nil {
			return petFail(err)
		}
		// Stock subtracts its locally planned Mana/resources after this callback.
		// Do not project economy_.mana or invented plan fields here.
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	case 791: // PET_UPGRADE_ALL_SKILL
		if !onlyStockGameplayParams(req.Envelope.Params, "pet_id", "skill_colors", "skill_counts") {
			return petBad("invalid_pet_skills")
		}
		petID, err := requiredPetInt64(req.Envelope.Params, "pet_id")
		if err != nil || petID <= 0 {
			return petBad("invalid_pet_skills")
		}
		upgrades, err := decodePetSkillUpgrades(req.Envelope.Params["skill_colors"], req.Envelope.Params["skill_counts"])
		if err != nil {
			return petBad("invalid_pet_skills")
		}
		if _, err := d.Service.UpgradeSkills(ctx, actor, petID, upgrades, req.Envelope.Operation); err != nil {
			return petFail(err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	default:
		return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error": "not_pet_mid"}}
	}
}

func (d PetDispatcher) petActor(ctx context.Context, req httpedge.DispatchRequest) (identity.ActorContext, *httpedge.Response) {
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

func onlyPetParams(params map[string]any, allowed ...string) bool {
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

func requiredPetInt64(m map[string]any, key string) (int64, error) {
	v, ok := m[key]
	if !ok {
		return 0, errors.New("missing Pet integer")
	}
	switch n := v.(type) {
	case json.Number:
		return n.Int64()
	case int:
		return int64(n), nil
	case int32:
		return int64(n), nil
	case int64:
		return n, nil
	case float64:
		if math.IsNaN(n) || math.IsInf(n, 0) || math.Trunc(n) != n || n > math.MaxInt64 || n < math.MinInt64 {
			return 0, errors.New("non-integral Pet integer")
		}
		return int64(n), nil
	default:
		return 0, errors.New("invalid Pet integer type")
	}
}

func isPetExpItem(id int64) bool { return id == 50001087 || id == 50001088 || id == 50001089 }

func decodePetExpItems(raw any) ([]appi5.PetExpItemDebit, error) {
	rows, ok := raw.([]any)
	if !ok || len(rows) == 0 || len(rows) > 3 {
		return nil, errors.New("invalid Pet EXP item list")
	}
	out := make([]appi5.PetExpItemDebit, 0, len(rows))
	seen := make(map[int64]struct{}, len(rows))
	for _, rawRow := range rows {
		row, ok := rawRow.(map[string]any)
		if !ok || !onlyPetParams(row, "item_id", "item_num") || len(row) != 2 {
			return nil, errors.New("invalid Pet EXP item row")
		}
		id, e1 := requiredPetInt64(row, "item_id")
		n, e2 := requiredPetInt64(row, "item_num")
		if e1 != nil || e2 != nil || !isPetExpItem(id) || n <= 0 {
			return nil, errors.New("invalid Pet EXP item row")
		}
		if _, ok := seen[id]; ok {
			return nil, errors.New("duplicate Pet EXP item")
		}
		seen[id] = struct{}{}
		out = append(out, appi5.PetExpItemDebit{ItemID: id, Count: n})
	}
	return out, nil
}

func canonicalPositivePipe(raw any, max int) ([]int64, error) {
	s, ok := raw.(string)
	if !ok || s == "" || strings.HasPrefix(s, "|") || strings.HasSuffix(s, "|") {
		return nil, errors.New("invalid pipe vector")
	}
	parts := strings.Split(s, "|")
	if len(parts) == 0 || len(parts) > max {
		return nil, errors.New("invalid pipe cardinality")
	}
	out := make([]int64, 0, len(parts))
	for _, token := range parts {
		if token == "" {
			return nil, errors.New("empty pipe token")
		}
		v, err := strconv.ParseInt(token, 10, 64)
		if err != nil || v <= 0 || strconv.FormatInt(v, 10) != token {
			return nil, errors.New("non-canonical pipe token")
		}
		out = append(out, v)
	}
	return out, nil
}

func decodePetSkillUpgrades(rawSlots, rawCounts any) ([]apppet.SkillUpgrade, error) {
	slots, err := canonicalPositivePipe(rawSlots, 5)
	if err != nil {
		return nil, err
	}
	counts, err := canonicalPositivePipe(rawCounts, 5)
	if err != nil || len(slots) != len(counts) {
		return nil, errors.New("mismatched Pet skill vectors")
	}
	seen := map[int64]struct{}{}
	out := make([]apppet.SkillUpgrade, 0, len(slots))
	for i, slot := range slots {
		if slot < 1 || slot > 5 {
			return nil, errors.New("invalid Pet skill slot")
		}
		if _, ok := seen[slot]; ok {
			return nil, errors.New("duplicate Pet skill slot")
		}
		seen[slot] = struct{}{}
		out = append(out, apppet.SkillUpgrade{Slot: slot, Count: counts[i]})
	}
	return out, nil
}

func petRestorationResponse(items []appi5.Award) map[string]any {
	body := map[string]any{}
	if len(items) > 0 {
		rows := make([]any, 0, len(items))
		for _, award := range items {
			rows = append(rows, map[string]any{"table_id": award.TableID, "item_num": award.ItemNum})
		}
		body["restore_items"] = rows
	}
	return body
}

func petBad(code string) httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": code}}
}

func petFail(err error) httpedge.Response {
	switch {
	case errors.Is(err, apppet.ErrPetAcquisitionContentInactive), errors.Is(err, apppet.ErrPetProgressionContentInactive), errors.Is(err, apppet.ErrPetEquipmentContentInactive), errors.Is(err, apppet.ErrPetPromotionContentInactive), errors.Is(err, apppet.ErrPetAppearanceContentInactive), errors.Is(err, apppet.ErrPetAwakeningProviderUnavailable):
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "pet_content_inactive"}}
	case errors.Is(err, apppet.ErrPetNotFound):
		return httpedge.Response{HTTPStatus: http.StatusNotFound, Body: map[string]any{"error": "pet_not_found"}}
	case errors.Is(err, apppet.ErrPetStillIncubating), errors.Is(err, apppet.ErrPetNotShown), errors.Is(err, apppet.ErrPetTimeDiscontinuity), errors.Is(err, apppet.ErrPetStyleSwitchConflict), errors.Is(err, economy.ErrInsufficientBalance):
		return httpedge.Response{HTTPStatus: http.StatusConflict, Body: map[string]any{"error": "pet_operation_rejected"}}
	case errors.Is(err, apppet.ErrPetAppearanceUnavailable), errors.Is(err, apppet.ErrPetExpMax), errors.Is(err, apppet.ErrPetEvolutionUnavailable), errors.Is(err, apppet.ErrPetSkillUnavailable), errors.Is(err, apppet.ErrPetEquipmentUnavailable), errors.Is(err, apppet.ErrPetPromotionUnavailable), errors.Is(err, apppet.ErrPetPromotionPrerequisites), errors.Is(err, apppet.ErrPetPromotionCorruptState), errors.Is(err, apppet.ErrPetPromotionQ1Unsupported):
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "pet_operation_rejected"}}
	default:
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "pet_operation_failed"}}
	}
}

var _ PetServicePort = apppet.Service{}
