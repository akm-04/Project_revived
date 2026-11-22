package stockruntime

import (
	"context"
	"net/http"

	appevents "gxb.local/backend/v2/internal/application/events"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// ActivityRewardMIDs is the generic activity claim surface (MID 231).
var ActivityRewardMIDs = []uint16{231}

// ActivityRewardPort is the events owner's MID 231 claim.
type ActivityRewardPort interface {
	Claim(context.Context, identity.ActorContext, operation.Context, int64, int64, int) (appevents.ClaimResult, error)
}

// ActivityRewardDispatcher serves MID 231. The client request carries
// activity_id, award_id (tier) and sub_award_id (choice) and reads only
// `awards` (Activities.lua:141-147, Activity1071.lua:190-205).
type ActivityRewardDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   ActivityRewardPort
}

func (d ActivityRewardDispatcher) Dispatch(c context.Context, req httpedge.DispatchRequest) httpedge.Response {
	actor, fail := (HeroDispatcher{Authority: d.Authority}).actor(c, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return failureReply(defect(nil))
	}
	activityID, firstErr := requiredInt64(req.Envelope.Params, "activity_id")
	tierID, secondErr := requiredInt64(req.Envelope.Params, "award_id")
	if firstErr != nil || secondErr != nil || activityID <= 0 || tierID <= 0 {
		return failureReply(malformed("invalid_activity_reward_parameter"))
	}
	choice := int64(0)
	if _, present := req.Envelope.Params["sub_award_id"]; present {
		parsed, choiceErr := requiredInt64(req.Envelope.Params, "sub_award_id")
		if choiceErr != nil {
			return failureReply(malformed("invalid_activity_reward_parameter"))
		}
		choice = parsed
	}
	result, err := d.Service.Claim(c, actor, req.Envelope.Operation, activityID, tierID, int(choice))
	if err != nil {
		return failureFromRows(activityRewardFailureRows, err)
	}
	awards := result.Awards
	if awards == nil {
		awards = []map[string]any{}
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"awards": awards, "activity_id": activityID}}
}

// EA-7: every MID 231 refusal is 409 with the D5 unproven code; only an absent
// owner is a transient fault.
var activityRewardFailureRows = []failureRow{
	{match: appevents.ErrClaimRejected, class: failureRefusal, code: unprovenRefusalCode},
	{match: appevents.ErrUnavailable, class: failureUnavailable},
}
