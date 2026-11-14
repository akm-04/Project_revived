package stockruntime

import (
	"context"
	"strings"

	authentication "gxb.local/backend/v2/internal/application/realtimeauth"
	invite "gxb.local/backend/v2/internal/application/socialinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialinvite"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

const sameAccountInviteCode int64 = 20033

type SocialInviteReadPort interface {
	Read(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
}

type SocialInviteBindPort interface {
	Bind(context.Context, identity.ActorContext, string, operation.Context) (map[string]any, error)
}

type SocialInviteClaimPort interface {
	Claim(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
}

// SocialInviteDispatcher serves the stock friend-invitation surface:
// 384 LOAD_INVITE_INFOS, 385 GET_INVITE_AWARD and 386 SEND_INVITE_CODE.
type SocialInviteDispatcher struct {
	Authority authentication.GameplayAuthorityPort
	Read      SocialInviteReadPort
	Bind      SocialInviteBindPort
	Claim     SocialInviteClaimPort
}

func (dispatcher SocialInviteDispatcher) Dispatch(ctx context.Context, request httpedge.DispatchRequest) httpedge.Response {
	actor, failure := (HeroDispatcher{Authority: dispatcher.Authority}).actor(ctx, request)
	if failure != nil {
		return *failure
	}
	parameters := request.Envelope.Params
	switch request.Envelope.MID {
	case 384:
		if !onlyStockGameplayParams(parameters) {
			return badHero("invalid_social_invite_request")
		}
		if dispatcher.Read == nil {
			return failureReply(defect(nil))
		}
		body, err := dispatcher.Read.Read(ctx, actor, request.Envelope.Operation)
		if err != nil {
			return socialInviteFailure(err)
		}
		return okI5(body)
	case 385:
		mission, valid := topFloorInteger(parameters, "mission_id", true)
		if !valid || mission <= 0 || !onlyStockGameplayParams(parameters, "mission_id") {
			return badHero("invalid_social_invite_request")
		}
		if dispatcher.Claim == nil {
			return failureReply(defect(nil))
		}
		body, err := dispatcher.Claim.Claim(ctx, actor, mission, request.Envelope.Operation)
		if err != nil {
			return socialInviteFailure(err)
		}
		return okI5(body)
	case 386:
		raw, ok := parameters["invite_code"].(string)
		if !ok || !onlyStockGameplayParams(parameters, "invite_code") {
			return badHero("invalid_social_invite_request")
		}
		code := strings.TrimSpace(raw)
		if code == "" {
			return badHero("invalid_social_invite_request")
		}
		if dispatcher.Bind == nil {
			return failureReply(defect(nil))
		}
		body, err := dispatcher.Bind.Bind(ctx, actor, code, request.Envelope.Operation)
		if err != nil {
			return socialInviteFailure(err)
		}
		return okI5(body)
	default:
		return badHero("invalid_social_invite_request")
	}
}

// Every business refusal is HTTP 409 with the stock error_code body; the client
// treats any 200 as success and indexes nested fields.
var socialInviteFailureRows = []failureRow{
	{match: domain.ErrSameAccount, class: failureRefusal, code: sameAccountInviteCode},
	{match: invite.ErrBindRefused, class: failureRefusal, code: unprovenRefusalCode},
	{match: invite.ErrClaimRefused, class: failureRefusal, code: unprovenRefusalCode},
	{match: invite.ErrFacts, class: failureRefusal, code: unprovenRefusalCode},
}

func socialInviteFailure(err error) httpedge.Response {
	return failureFromRows(socialInviteFailureRows, err)
}
