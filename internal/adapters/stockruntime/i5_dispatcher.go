package stockruntime

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	backpackproj "gxb.local/backend/v2/internal/projection/backpack"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// I5ServicePort is the concrete application-facing seam used by production and
// easily faked in stock-wire tests.
type I5ServicePort interface {
	SaveStory(context.Context, identity.ActorContext, int64, int64, int64, operation.Context) error
	ListBackpack(context.Context, identity.ActorContext) ([]economy.StackState, error)
	ListMail(context.Context, identity.ActorContext, time.Time, int) (appi5.MailListResult, error)
	ClaimMail(context.Context, identity.ActorContext, mail.Address, operation.Context) (appi5.MID369Result, error)
	ClaimMailBatch(context.Context, identity.ActorContext, []mail.Address, operation.Context) (appi5.MID370Result, error)
	ListObjectives(context.Context, identity.ActorContext, objective.StockFamily, time.Time) ([]objective.Instance, []appi5.ObjectiveDefinition, error)
	ClaimObjectiveByID(context.Context, identity.ActorContext, int64, string, operation.Context) (appi5.ObjectiveClaimResult, error)
	Redeem(context.Context, identity.ActorContext, string, string, operation.Context) (appi5.RedeemResult, error)
}

type I5Dispatcher struct {
	Authority apprealtime.GameplayAuthorityPort
	Service   I5ServicePort
}

func (d I5Dispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	actor, fail := d.actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "i5_unavailable"}}
	}
	switch req.Envelope.MID {
	case 26: // SAVE_STORY
		storyID, e1 := requiredInt64(req.Envelope.Params, "story_id")
		storyState, e2 := requiredInt64(req.Envelope.Params, "story_state")
		guideID, e3 := requiredInt64(req.Envelope.Params, "guide_id")
		if e1 != nil || e2 != nil || e3 != nil || storyID < 0 || storyState < 0 || guideID < 0 {
			return badI5("invalid_story")
		}
		if err := d.Service.SaveStory(ctx, actor, storyID, storyState, guideID, req.Envelope.Operation); err != nil {
			return failI5(err)
		}
		return okI5(map[string]any{})
	case 81: // LOAD_BACKPACK
		stacks, err := d.Service.ListBackpack(ctx, actor)
		if err != nil {
			return failI5(err)
		}
		body, err := backpackproj.Build(stacks)
		if err != nil {
			return failI5(err)
		}
		return okI5(body)
	case 368: // LOAD_MAIL_LIST
		limit := int64(20)
		if _, ok := req.Envelope.Params["load_num"]; ok {
			v, err := requiredInt64(req.Envelope.Params, "load_num")
			if err != nil || v <= 0 || v > 200 {
				return badI5("invalid_mail_limit")
			}
			limit = v
		}
		view, err := d.Service.ListMail(ctx, actor, req.Envelope.ReceivedAt, int(limit))
		if err != nil {
			return failI5(err)
		}
		wire, err := stockMailRecords(view.MailList)
		if err != nil {
			return failI5(err)
		}
		return okI5(map[string]any{"mail_list": wire, "total": view.Total, "new_mail_total": view.NewMailTotal})
	case 369: // SET_MAIL_READ / claim attachment
		id, err := requiredInt64(req.Envelope.Params, "id")
		if err != nil || id <= 0 {
			return badI5("invalid_mail_id")
		}
		ns, err := stockMailNamespace(req.Envelope.Params["is_region"])
		if err != nil {
			return badI5("invalid_mail_namespace")
		}
		got, err := d.Service.ClaimMail(ctx, actor, mail.Address{Namespace: ns, WireID: id}, req.Envelope.Operation)
		if err != nil {
			return failI5(err)
		}
		body := map[string]any{"changed": got.Changed, "is_new": got.IsNew, "is_shown": got.IsShown, "rewards": appi5.StockMID369Rewards(got.Rewards)}
		applySettlementProjection(body, got.Projection)
		return okI5(body)
	case 370: // MAIL_ONEKEY
		normal := stringParam(req.Envelope.Params, "normal_ids")
		region := stringParam(req.Envelope.Params, "region_ids")
		addrs, err := mail.ParseMID370(normal, region, 200)
		if err != nil || len(addrs) == 0 {
			return badI5("invalid_mail_batch")
		}
		got, err := d.Service.ClaimMailBatch(ctx, actor, addrs, req.Envelope.Operation)
		if err != nil {
			return failI5(err)
		}
		awards := appi5.StockRepresentableBulkAwards(got.Awards)
		wire, err := stockMailRecords(got.Mail.MailList)
		if err != nil {
			return failI5(err)
		}
		body := map[string]any{"awards": awards, "mail_list": map[string]any{"mail_list": wire, "total": got.Mail.Total, "new_mail_total": got.Mail.NewMailTotal}}
		applySettlementProjection(body, got.Projection)
		return okI5(body)
	case 2736: // TASK_LOAD_BY_TYPE
		familyRaw, err := requiredInt64(req.Envelope.Params, "mission_type")
		if err != nil || familyRaw < int64(objective.Daily) || familyRaw > int64(objective.Challenge) {
			return badI5("invalid_mission_type")
		}
		instances, _, err := d.Service.ListObjectives(ctx, actor, objective.StockFamily(familyRaw), req.Envelope.ReceivedAt)
		if err != nil {
			return failI5(err)
		}
		return okI5(map[string]any{"mission_list": stockMissionList(objective.StockFamily(familyRaw), instances)})
	case 161: // TAKE_MISSION_AWARD
		tableID, err := requiredInt64(req.Envelope.Params, "table_id")
		if err != nil || tableID <= 0 {
			return badI5("invalid_mission_id")
		}
		generation := ""
		if raw, ok := req.Envelope.Params["hero_table_id"]; ok {
			h, err := numericValue(raw)
			if err != nil || h <= 0 {
				return badI5("invalid_hero_table_id")
			}
			generation = "hero:" + strconv.FormatInt(h, 10)
		}
		got, err := d.Service.ClaimObjectiveByID(ctx, actor, tableID, generation, req.Envelope.Operation)
		if err != nil {
			return failI5(err)
		}
		awards := appi5.StockRepresentableBulkAwards(got.Awards)
		body := map[string]any{"awards": awards}
		applySettlementProjection(body, got.Projection)
		return okI5(body)
	case 230: // REDEEM_CODE
		code, _ := req.Envelope.Params["code"].(string)
		if code == "" {
			return badI5("invalid_redeem")
		}
		platform := fmt.Sprint(req.Envelope.Params["platform"])
		got, err := d.Service.Redeem(ctx, actor, code, platform, req.Envelope.Operation)
		if err != nil {
			return failI5(err)
		}
		awards := appi5.StockRepresentableBulkAwards(got.Awards)
		body := map[string]any{"awards": awards}
		applySettlementProjection(body, got.Projection)
		return okI5(body)
	default:
		return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error": "not_i5_mid"}}
	}
}

func (d I5Dispatcher) actor(ctx context.Context, req httpedge.DispatchRequest) (identity.ActorContext, *httpedge.Response) {
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

func stockMailRecords(in []mail.Record) ([]any, error) {
	out := make([]any, 0, len(in))
	for _, r := range in {
		v, err := r.WireProjection()
		if err != nil {
			return nil, err
		}
		out = append(out, v)
	}
	return out, nil
}
func stockMailNamespace(v any) (mail.Namespace, error) {
	switch x := v.(type) {
	case bool:
		if x {
			return mail.Region, nil
		}
		return mail.Normal, nil
	case nil:
		return 0, errors.New("missing is_region")
	default:
		n, err := numericValue(x)
		if err != nil {
			return 0, err
		}
		if n == 1 {
			return mail.Region, nil
		}
		if n == 0 {
			return mail.Normal, nil
		}
		return 0, errors.New("invalid is_region")
	}
}
func numericValue(v any) (int64, error) { return requiredInt64(map[string]any{"v": v}, "v") }

func stockMissionList(f objective.StockFamily, in []objective.Instance) any {
	row := func(i objective.Instance) map[string]any {
		complete := int64(0)
		if i.CompletedAt != nil {
			complete = 1
		}
		reward := int64(0)
		if i.ClaimState == objective.Claimed {
			reward = 1
		}
		return map[string]any{"table_id": i.ObjectiveID, "count": i.Progress, "is_complete": complete, "is_reward": reward}
	}
	if f != objective.Partner {
		out := make([]any, 0, len(in))
		for _, i := range in {
			out = append(out, row(i))
		}
		return out
	}
	group := map[string]any{}
	for _, i := range in {
		hero := strings.TrimPrefix(i.GenerationID, "hero:")
		if hero == i.GenerationID || hero == "" {
			continue
		}
		group[hero] = []any{row(i)}
	}
	return group
}
func applySettlementProjection(body map[string]any, p appi5.SettlementProjection) {
	if len(p.Economy) > 0 {
		body["economy_"] = p.Economy
	}
	if len(p.ExtraDrops) > 0 {
		drops := make([]any, 0, len(p.ExtraDrops))
		for _, a := range p.ExtraDrops {
			if a.TableID > 0 && a.ItemNum > 0 {
				drops = append(drops, map[string]any{"table_id": a.TableID, "item_num": a.ItemNum})
			}
		}
		if len(drops) > 0 {
			body["extra_drops_"] = drops
		}
	}
	if len(p.NewFunctionIDs) > 0 {
		body["new_funcs_"] = append([]int64(nil), p.NewFunctionIDs...)
	}
}

func okI5(body map[string]any) httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
}
func badI5(code string) httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": code}}
}
func failI5(err error) httpedge.Response {
	switch {
	case errors.Is(err, appi5.ErrRedeemInvalid):
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "invalid_redeem"}}
	case errors.Is(err, appi5.ErrMailStackFull):
		return httpedge.Response{HTTPStatus: http.StatusConflict, Body: map[string]any{"error": "stack_capacity"}}
	case errors.Is(err, appi5.ErrMailNotFound), errors.Is(err, appi5.ErrObjectiveNotFound):
		return httpedge.Response{HTTPStatus: http.StatusNotFound, Body: map[string]any{"error": "not_found"}}
	default:
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "i5_operation_failed"}}
	}
}
