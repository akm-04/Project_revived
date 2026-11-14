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
		return failureReply(defect(nil))
	}
	if req.Envelope.MID != 1793 {
		return failureReply(refusal(unprovenRefusalCode))
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
	if d.Authority == nil {
		r := failureReply(defect(nil))
		return identity.ActorContext{}, &r
	}
	if req.Envelope.Claims.Token == "" {
		r := failureReply(sessionFailure())
		return identity.ActorContext{}, &r
	}
	a, err := d.Authority.ResolveGameplayBearer(ctx, req.Envelope.Claims.Token, req.Envelope.ReceivedAt)
	if err != nil {
		r := authFailure(err)
		return identity.ActorContext{}, &r
	}
	if req.Envelope.Claims.Region != int64(a.LogicalServerID) {
		r := failureReply(refusal(unprovenRefusalCode))
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
	return failureReply(malformed(code))
}

var savedPresetFailureRows = []failureRow{
	{match: appsavedpreset.ErrInvalidCommand, class: failureMalformed, detail: "saved_preset_rejected"},
	{match: characterasset.ErrReferenceNotFound, class: failureMalformed, detail: "saved_preset_rejected"},
	{match: appsavedpreset.ErrAmbiguousLegacyDelete, class: failureRefusal, code: staleConflictCode},
	{match: appsavedpreset.ErrStaleLegacyDelete, class: failureRefusal, code: staleConflictCode},
}

func failSavedPreset(err error) httpedge.Response {
	var unknown *tx.UnknownCommitError
	if errors.As(err, &unknown) {
		return failureReply(unknownCommit("saved_preset_commit_unknown", err))
	}
	return failureFromRows(savedPresetFailureRows, err)
}
