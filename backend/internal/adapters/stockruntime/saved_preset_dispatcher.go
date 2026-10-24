package stockruntime

import (
	"context"
	"errors"
	"net/http"

	"gxb.local/backend/v2/internal/application/characterasset"
	appsavedpreset "gxb.local/backend/v2/internal/application/charactersavedpreset"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type SavedPresetServicePort interface {
	Replace(context.Context, identity.ActorContext, appsavedpreset.Command, operation.Context) (appsavedpreset.MutationResult, error)
}

type SavedPresetDispatcher struct {
	Authority apprealtime.GameplayAuthorityPort
	Service   SavedPresetServicePort
}

func (d SavedPresetDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	actor, fail := d.actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "saved_preset_unavailable"}}
	}
	if req.Envelope.MID != 1793 {
		return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error": "not_saved_preset_mid"}}
	}
	if !onlyStockGameplayParams(req.Envelope.Params, "team_str", "team_name_str", "pet_str") {
		return badSavedPreset("invalid_saved_preset")
	}
	team, ok := strictStringParam(req.Envelope.Params, "team_str")
	if !ok {
		return badSavedPreset("invalid_saved_preset")
	}
	name, ok := strictStringParam(req.Envelope.Params, "team_name_str")
	if !ok {
		return badSavedPreset("invalid_saved_preset")
	}
	petRaw, petPresent := req.Envelope.Params["pet_str"]
	pet := ""
	if petPresent {
		var ok bool
		pet, ok = petRaw.(string)
		if !ok {
			return badSavedPreset("invalid_saved_preset")
		}
	}
	got, err := d.Service.Replace(ctx, actor, appsavedpreset.Command{
		TeamString: team, TeamNameString: name, PetPresent: petPresent, PetString: pet,
	}, req.Envelope.Operation)
	if err != nil {
		return failSavedPreset(err)
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{
		"save_team": got.Wire.SaveTeam, "save_team_name": got.Wire.SaveTeamName, "save_pet": got.Wire.SavePet,
	}}
}

func (d SavedPresetDispatcher) actor(ctx context.Context, req httpedge.DispatchRequest) (identity.ActorContext, *httpedge.Response) {
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

func strictStringParam(params map[string]any, key string) (string, bool) {
	v, ok := params[key]
	if !ok {
		return "", false
	}
	s, ok := v.(string)
	return s, ok
}

func badSavedPreset(code string) httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": code}}
}

func failSavedPreset(err error) httpedge.Response {
	var unknown *tx.UnknownCommitError
	var conflict *receipt.ConflictError
	switch {
	case errors.Is(err, appsavedpreset.ErrInvalidCommand), errors.Is(err, characterasset.ErrReferenceNotFound):
		return badSavedPreset("saved_preset_rejected")
	case errors.Is(err, appsavedpreset.ErrAmbiguousLegacyDelete), errors.Is(err, appsavedpreset.ErrStaleLegacyDelete), errors.As(err, &conflict):
		return httpedge.Response{HTTPStatus: http.StatusConflict, Body: map[string]any{"error": "saved_preset_conflict"}}
	case errors.As(err, &unknown):
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "saved_preset_commit_unknown"}}
	default:
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "saved_preset_failed"}}
	}
}
