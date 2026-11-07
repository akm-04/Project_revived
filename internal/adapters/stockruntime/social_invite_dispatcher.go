package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"strings"

	authentication "gxb.local/backend/v2/internal/application/realtimeauth"
	invite "gxb.local/backend/v2/internal/application/socialinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialinvite"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

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
			return inviteUnavailable()
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
			return inviteUnavailable()
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
			return inviteUnavailable()
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

func inviteUnavailable() httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "social_invite_unavailable"}}
}

// Every business refusal is HTTP 409 with the stock error_code body; the client
// treats any 200 as success and indexes nested fields.
func socialInviteFailure(err error) httpedge.Response {
	var conflict *receipt.ConflictError
	if errors.Is(err, invite.ErrUnavailable) {
		return inviteUnavailable()
	}
	if errors.Is(err, domain.ErrSameAccount) {
		return conflictRefusal(20033)
	}
	if errors.Is(err, invite.ErrBindRefused) || errors.Is(err, invite.ErrClaimRefused) || errors.Is(err, invite.ErrFacts) || errors.As(err, &conflict) {
		return conflictRefusal(1)
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "social_invite_unavailable"}}
}
