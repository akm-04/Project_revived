package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/application/socialdismiss"
	"gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
	"time"
)

type SocialRelationCommands interface {
	Execute(context.Context, identity.ActorContext, sr.Command, operation.Context) (sr.Result, error)
}
type SocialDismissCommands interface {
	Dismiss(context.Context, identity.ActorContext, []socialinbox.NoticeID, operation.Context) ([]socialinbox.NoticeID, error)
}
type SocialProjectionQueries interface {
	LoadBase(context.Context, identity.ActorContext, operation.Context) (sp.Result, error)
	LoadList(context.Context, identity.ActorContext, sp.ListKind, operation.Context) (sp.Result, error)
	Search(context.Context, identity.ActorContext, sp.SearchQuery, operation.Context) (sp.Result, error)
	Recommend(context.Context, identity.ActorContext, operation.Context) (sp.Result, error)
}
type SocialReloadEmitter interface {
	Emit(context.Context, []sr.ReloadReference)
}
type SocialGiftCommands interface {
	Send(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (socialgift.Result, error)
	Claim(context.Context, identity.ActorContext, []socialinbox.NoticeID, operation.Context) (socialgift.Result, error)
	ReloadReferences(context.Context, identity.ActorContext, identity.PlayerID, socialgift.Result, operation.Context) ([]sr.ReloadReference, error)
}
type SocialDispatcher struct {
	Gifts          SocialGiftCommands
	giftStockReady bool
	Scalar         i5.CurrentScalarProjectionPort
	Authority      realtimeauth.GameplayAuthorityPort
	Relations      SocialRelationCommands
	Dismissal      SocialDismissCommands
	Projection     SocialProjectionQueries
	Emitter        SocialReloadEmitter
	Tracker        *lobby.BootTracker
}

var SocialHTTPMIDs = []uint16{176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190}

func RegisterSocialRoutes(router *httpedge.Router, d SocialDispatcher) error {
	for _, mid := range SocialHTTPMIDs {
		if mid == 183 && !d.giftStockReady {
			continue
		}
		if e := router.Register(mid, d); e != nil {
			return e
		}
	}
	return nil
}
func strictSocialInt(v any) (int64, error) {
	switch n := v.(type) {
	case json.Number:
		return n.Int64()
	case int64:
		return n, nil
	case int:
		return int64(n), nil
	default:
		return 0, sr.ErrInvalidCommand
	}
}
func socialFields(params map[string]any, allowed ...string) (map[string]any, error) {
	keep := map[string]bool{}
	for _, k := range allowed {
		keep[k] = true
	}
	out := map[string]any{}
	for k, v := range params {
		switch k {
		case "mid", "token", "region", "v_", "app_v", "platform":
			continue
		}
		if !keep[k] {
			return nil, sr.ErrInvalidCommand
		}
		out[k] = v
	}
	return out, nil
}
func socialTargets(m map[string]any, key string, batch bool) ([]identity.PlayerID, error) {
	var values []any
	if batch {
		v, ok := m[key].([]any)
		if !ok {
			return nil, sr.ErrInvalidCommand
		}
		values = v
	} else {
		v, ok := m[key]
		if !ok {
			return nil, sr.ErrInvalidCommand
		}
		values = []any{v}
	}
	out := make([]identity.PlayerID, 0, len(values))
	for _, v := range values {
		n, e := strictSocialInt(v)
		if e != nil {
			return nil, e
		}
		id := identity.PlayerID(n)
		if _, e = sr.CanonicalServer(id); e != nil {
			return nil, e
		}
		out = append(out, id)
	}
	return out, nil
}
func socialFailure(e error) httpedge.Response {
	var stock *sr.StockError
	if errors.As(e, &stock) {
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"error_code": stock.Code}}
	}
	return httpedge.Response{HTTPStatus: http.StatusConflict, Body: map[string]any{"error": "social_unavailable"}}
}
func (d SocialDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	// One finite parent deadline covers authority, command and postcommit projection.
	if req.Envelope.MID == 183 || req.Envelope.MID == 184 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, 12*time.Second)
		defer cancel()
	}
	bad := func() httpedge.Response {
		return httpedge.Response{HTTPStatus: 400, Body: map[string]any{"error": "invalid_social_request"}}
	}
	if d.Authority == nil || req.Envelope.Claims.Token == "" {
		return httpedge.Response{HTTPStatus: 401, Body: map[string]any{"error": "gameplay_auth_required"}}
	}
	a, e := d.Authority.ResolveGameplayBearer(ctx, req.Envelope.Claims.Token, req.Envelope.ReceivedAt)
	if e != nil {
		return authFailure(e)
	}
	if req.Envelope.Claims.Region != int64(a.LogicalServerID) {
		return httpedge.Response{HTTPStatus: 403, Body: map[string]any{"error": "region_mismatch"}}
	}
	mid := req.Envelope.MID
	op := req.Envelope.Operation
	m := req.Envelope.Params
	if mid == 176 || mid == 188 || mid == 189 || mid == 190 {
		if d.Projection == nil {
			return socialFailure(sp.ErrInvalidRead)
		}
		var v sp.Result
		var body any
		switch mid {
		case 176:
			if _, e = socialFields(m); e != nil {
				return bad()
			}
			v, e = d.Projection.LoadBase(ctx, a, op)
			if e == nil {
				body = socialpresentation.MapBase(v)
				if d.Tracker != nil {
					_ = d.Tracker.Record(d.Tracker.Correlate(lobby.BootEvent{MID: 176, Kind: lobby.BootExplicitHTTP, Phase: lobby.PhaseClientRequestObserved, At: req.Envelope.ReceivedAt}, a.SessionID.UUID().String(), a.ContextID.UUID().String(), ""))
				}
			}
		case 188:
			fields, er := socialFields(m, "msg", "player_name")
			if er != nil {
				return bad()
			}
			raw, er := json.Marshal(fields)
			if er != nil {
				return bad()
			}
			q, er := socialpresentation.DecodeSearch(raw)
			if er != nil {
				return bad()
			}
			v, e = d.Projection.Search(ctx, a, q, op)
			if e == nil {
				body, e = socialpresentation.MapSearch(v, q.Mode)
			}
		case 189:
			fields, er := socialFields(m, "list_type")
			if er != nil {
				return bad()
			}
			k, er := strictSocialInt(fields["list_type"])
			if er != nil || k < 1 || k > 4 {
				return bad()
			}
			v, e = d.Projection.LoadList(ctx, a, sp.ListKind(k), op)
			if e == nil {
				body, e = socialpresentation.MapList(v, sp.ListKind(k))
			}
		case 190:
			if _, e = socialFields(m); e != nil {
				return bad()
			}
			v, e = d.Projection.Recommend(ctx, a, op)
			if e == nil {
				body = socialpresentation.MapRecommend(v)
			}
		}
		if e != nil {
			return socialFailure(e)
		}
		return httpedge.Response{HTTPStatus: 200, JSON: body}
	}
	if mid == 183 {
		fields, e := socialFields(m, "player_id")
		if e != nil {
			return bad()
		}
		targets, e := socialTargets(fields, "player_id", false)
		if e != nil || len(targets) != 1 {
			return bad()
		}
		if !d.giftStockReady || d.Gifts == nil || d.Scalar == nil || d.Projection == nil || d.Emitter == nil {
			return giftFailure()
		}
		result, e := d.Gifts.Send(ctx, a, targets[0], op)
		if e != nil {
			return giftFailure()
		}
		refs, e := d.Gifts.ReloadReferences(ctx, a, targets[0], result, op)
		if e == nil && len(refs) > 0 {
			d.Emitter.Emit(ctx, refs)
		}
		return httpedge.Response{HTTPStatus: 200, Body: map[string]any{}}
	}
	if mid == 184 {
		fields, e := socialFields(m, "notice_ids")
		if e != nil {
			return bad()
		}
		values, ok := fields["notice_ids"].([]any)
		if !ok {
			return bad()
		}
		ids := make([]socialinbox.NoticeID, 0, len(values))
		for _, v := range values {
			n, e := strictSocialInt(v)
			if e != nil || !socialinbox.NoticeID(n).WireSafe() {
				return bad()
			}
			ids = append(ids, socialinbox.NoticeID(n))
		}
		if d.giftStockReady {
			if d.Gifts == nil || d.Scalar == nil || d.Projection == nil || d.Emitter == nil {
				return giftFailure()
			}
			result, e := d.Gifts.Claim(ctx, a, ids, op)
			if e != nil {
				return giftFailure()
			}
			out := result.NoticeIDs
			if out == nil {
				out = []socialinbox.NoticeID{}
			}
			body := map[string]any{"ids": out, "awards": []any{}}
			if result.Amount > 0 {
				amount, e := d.Scalar.CurrentScalar(ctx, a.PlayerID, "friendship_coin", op)
				if e != nil || amount < 0 || amount > 9007199254740991 {
					return giftFailure()
				}
				body["economy_"] = map[string]any{"friendship_coin": amount}
			}
			return httpedge.Response{HTTPStatus: 200, Body: body}
		}
		if d.Dismissal == nil {
			return socialFailure(socialinbox.ErrInvalidNotice)
		}
		out, e := d.Dismissal.Dismiss(ctx, a, ids, op)
		if e != nil {
			return socialFailure(e)
		}
		if out == nil {
			out = []socialinbox.NoticeID{}
		}
		return httpedge.Response{HTTPStatus: 200, Body: map[string]any{"ids": out}}
	}
	if d.Relations == nil {
		return socialFailure(sr.ErrInvalidCommand)
	}
	command := sr.Command{}
	batch := false
	key := "player_id"
	allowed := []string{key}
	switch mid {
	case 177:
		command.Kind = sr.RequestFriend
		allowed = append(allowed, "msg")
	case 178:
		command.Kind = sr.DenyRequests
		batch = true
	case 179:
		command.Kind = sr.IgnoreRequests
		batch = true
	case 180:
		command.Kind = sr.AcceptRequest
	case 181:
		command.Kind = sr.DeleteFriend
	case 182:
		command.Kind = sr.AcceptAllRequests
		batch = true
	case 185:
		command.Kind = sr.AddBlock
	case 186:
		command.Kind = sr.RemoveBlock
	case 187:
		command.Kind = sr.ClearBlocks
		allowed = nil
	default:
		return bad()
	}
	if batch {
		key = "player_ids"
		allowed = []string{key}
	}
	fields, e := socialFields(m, allowed...)
	if e != nil {
		return bad()
	}
	if mid != 187 {
		command.Targets, e = socialTargets(fields, key, batch)
		if e != nil {
			return bad()
		}
	}
	if msg, ok := fields["msg"]; ok {
		command.Message, ok = msg.(string)
		if !ok {
			return bad()
		}
	}
	result, e := d.Relations.Execute(ctx, a, command, op)
	if e != nil {
		return socialFailure(e)
	}
	var body any = map[string]any{}
	// Projection helpers preserve typed booleans and the source-specific batch object.
	switch mid {
	case 180, 182, 185:
		body, e = mapSocialMutation(result, mid)
		if e != nil {
			return socialFailure(e)
		}
	}
	if d.Emitter != nil && len(result.Reloads) > 0 {
		d.Emitter.Emit(ctx, result.Reloads)
	}
	return httpedge.Response{HTTPStatus: 200, JSON: body}
}

var _ SocialDismissCommands = socialdismiss.Service{}

func giftFailure() httpedge.Response {
	return httpedge.Response{HTTPStatus: 409, Body: map[string]any{"error": "social_gift_unavailable"}}
}
