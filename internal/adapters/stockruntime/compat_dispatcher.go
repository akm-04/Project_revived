package stockruntime

import (
	"context"
	"errors"
	"net/http"

	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	d "gxb.local/backend/v2/internal/domain/compat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// CompatMIDs are the I9-11D compatibility preference MIDs.
var CompatMIDs = []uint16{1025, 1026, 1864}

// CompatPort applies one stock preference toggle under the player root lock.
type CompatPort interface {
	SetMessagePush(context.Context, identity.ActorContext, int64, bool, operation.Context) error
	FirstMainTouch(context.Context, identity.ActorContext, operation.Context) error
}

// CompatDispatcher answers MID 1025/1026 (message-push toggles) and MID 1864
// (first main touch). The callbacks read no reply field, so an empty object is
// the whole success contract.
type CompatDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   CompatPort
}

func NewCompatDispatcher(authority rt.GameplayAuthorityPort, service CompatPort) CompatDispatcher {
	return CompatDispatcher{Authority: authority, Service: service}
}

func (o CompatDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	actor, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failureReply(defect(nil))
	}
	params := req.Envelope.Params
	switch req.Envelope.MID {
	case 1025, 1026:
		if !onlyStockGameplayParams(params, "message_type") {
			return badCompat()
		}
		messageType, err := compatMessageType(params)
		if err != nil {
			return badCompat()
		}
		err = o.Service.SetMessagePush(ctx, actor, messageType, req.Envelope.MID == 1025, req.Envelope.Operation)
		if err != nil {
			return failCompat(err)
		}
		return okCompat()
	case 1864:
		if !onlyStockGameplayParams(params) {
			return badCompat()
		}
		if err := o.Service.FirstMainTouch(ctx, actor, req.Envelope.Operation); err != nil {
			return failCompat(err)
		}
		return okCompat()
	}
	return failureReply(refusal(unprovenRefusalCode))
}

func okCompat() httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
}

func badCompat() httpedge.Response {
	return failureReply(malformed("compat_invalid_parameter"))
}

// compatMessageType accepts the JSON number the stock client sends and refuses
// a text encoding of the same digits (I9-11D C2).
func compatMessageType(params map[string]any) (int64, error) {
	if _, isText := params["message_type"].(string); isText {
		return 0, errors.New("message_type is text")
	}
	return requiredInt64(params, "message_type")
}

func failCompat(err error) httpedge.Response {
	if errors.Is(err, d.ErrInvalidMessageType) {
		return badCompat()
	}
	if errors.Is(err, d.ErrStaleState) {
		return failureReply(refusal(staleConflictCode))
	}
	return failureFromRows(nil, err)
}
