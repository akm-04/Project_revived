package stockruntime

import (
	"context"
	"errors"
	app "gxb.local/backend/v2/internal/application/librarylocal"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

type LibraryPort interface {
	Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error)
	Read(context.Context, identity.ActorContext, operation.Context, uint16, int64) (map[string]any, error)
}
type LibraryDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   LibraryPort
}

func (d LibraryDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	actor, fail := (HeroDispatcher{Authority: d.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return failLibrary(app.ErrUnavailable)
	}
	c := app.Command{}
	params := req.Envelope.Params
	mid := req.Envelope.MID
	allowed := []string{}
	var e error
	switch mid {
	case 836, 2784:
	case 853, 854, 72:
		allowed = []string{"partner_id"}
	case 837:
		allowed = []string{"partner_id", "dialog_id"}
	case 838, 842:
		allowed = []string{"partner_id"}
	case 844:
		allowed = []string{"partner_id", "act_id"}
	case 840:
		allowed = []string{"partner_id", "gift_id", "gift_num"}
	case 852:
		allowed = []string{"partner_id", "cost_id"}
	case 2785:
		allowed = []string{"id"}
	default:
		return badHero("unsupported_library_mid")
	}
	if !onlyStockGameplayParams(params, allowed...) {
		return badHero("invalid_library_params")
	}
	if mid != 836 && mid != 2784 && mid != 2785 {
		c.PartnerID, e = requiredInt64(params, "partner_id")
		if e != nil || c.PartnerID <= 0 {
			return badHero("invalid_library_partner")
		}
	}
	if mid == 836 || mid == 838 || mid == 842 || mid == 2784 || mid == 853 {
		body, e := d.Service.Read(ctx, actor, req.Envelope.Operation, mid, c.PartnerID)
		if e != nil {
			return failLibraryMode(e)
		}
		return httpedge.Response{HTTPStatus: 200, Body: body}
	}
	switch mid {
	case 837:
		c.Family = app.ReadDialog
		c.Value, e = requiredInt64(params, "dialog_id")
	case 844:
		c.Family = app.ActAward
		c.Value, e = requiredInt64(params, "act_id")
	case 840:
		c.Family = app.Gift
		c.Value, e = requiredInt64(params, "gift_id")
		n, err := requiredInt64(params, "gift_num")
		if err != nil || n != 1 {
			return badHero("invalid_library_gift_num")
		}
	case 852:
		c.Family = app.Feed
		c.Value, e = requiredInt64(params, "cost_id")
	case 854:
		c.Family = app.Save
	case 72:
		c.Family = app.NormalClaim
	case 2785:
		c.Family = app.SpecialClaim
		c.Value, e = requiredInt64(params, "id")
	}
	if e != nil || c.Validate() != nil {
		return badHero("invalid_library_command")
	}
	out, e := d.Service.Command(ctx, actor, c, req.Envelope.Operation)
	if e != nil {
		return failLibraryMode(e)
	}
	body := map[string]any{}
	switch mid {
	case 837:
		if !out.HasDialog {
			return failLibrary(app.ErrUnavailable)
		}
		body["dialog"] = map[string]any{"dialog_id": out.Dialog.DialogID, "is_read": libraryBit(out.Dialog.IsRead), "is_awarded": libraryBit(out.Dialog.IsAwarded), "select_id": out.Dialog.SelectID}
	case 844:
		body["favor_degree"] = out.Favor
	case 840:
		body = map[string]any{"gift_id": c.Value, "favor_degree": out.Favor, "is_married": func() int64 {
			if out.Married {
				return 1
			}
			return 0
		}()}
	case 852:
		body["feed_add"] = out.Delta
	case 854:
		body["feed_attrs"] = out.Applied
	}
	return httpedge.Response{HTTPStatus: 200, Body: body}
}
func failLibrary(e error) httpedge.Response {
	status := http.StatusServiceUnavailable
	if errors.Is(e, app.ErrRejected) {
		status = http.StatusBadRequest
	}
	return httpedge.Response{HTTPStatus: status, Body: map[string]any{"error": "library_unavailable"}}
}

// failLibraryMode refuses business conflicts on 409 so the stock Library
// callbacks see ERROR instead of an OK body they would index.
func failLibraryMode(e error) httpedge.Response {
	if errors.Is(e, app.ErrRejected) || errors.Is(e, library.ErrUnqualified) || errors.Is(e, library.ErrDialogClosed) || errors.Is(e, library.ErrActLocked) || errors.Is(e, library.ErrActAwarded) {
		return conflictRefusal(1)
	}
	return failLibrary(e)
}

func libraryBit(v bool) int64 {
	if v {
		return 1
	}
	return 0
}
