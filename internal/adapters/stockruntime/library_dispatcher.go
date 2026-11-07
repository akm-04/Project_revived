package stockruntime

import (
	"context"
	"errors"
	app "gxb.local/backend/v2/internal/application/librarylocal"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
	"strconv"
	"strings"
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
	case 836, 2784, 2497:
	case 2498:
		allowed = []string{"table_id"}
	case 853, 854, 72:
		allowed = []string{"partner_id"}
	case 837:
		allowed = []string{"partner_id", "dialog_id"}
	case 838, 841, 842:
		allowed = []string{"partner_id"}
	case 843:
		allowed = []string{"partner_id", "dialog_id", "select_info"}
	case 844:
		allowed = []string{"partner_id", "act_id"}
	case 845, 846, 847:
		allowed = []string{"partner_id", "mission_id"}
	case 851:
		allowed = []string{"talk_id"}
	case 840:
		allowed = []string{"partner_id", "gift_id", "gift_num"}
	case 839:
		allowed = []string{"gift_id", "gift_num"}
	case 835:
		allowed = []string{"partner_id", "card_status", "board_model_id"}
	case 855:
		allowed = []string{"index"}
	case 856:
		allowed = []string{"bg_id"}
	case 857:
		allowed = []string{"_type", "bg_id"}
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
	if mid != 836 && mid != 839 && mid != 851 && mid != 855 && mid != 856 && mid != 857 && mid != 2497 && mid != 2498 && mid != 2784 && mid != 2785 {
		c.PartnerID, e = requiredInt64(params, "partner_id")
		if e != nil || c.PartnerID <= 0 {
			return badHero("invalid_library_partner")
		}
	}
	targetIdentifier := c.PartnerID
	if mid == 2498 {
		targetIdentifier, e = requiredInt64(params, "table_id")
		if e != nil || targetIdentifier <= 0 {
			return badHero("invalid_library_table")
		}
	}
	if mid == 836 || mid == 838 || mid == 841 || mid == 842 || mid == 2784 || mid == 853 || mid == 2497 || mid == 2498 {
		body, e := d.Service.Read(ctx, actor, req.Envelope.Operation, mid, targetIdentifier)
		if e != nil {
			return failLibraryMode(e)
		}
		return httpedge.Response{HTTPStatus: 200, Body: body}
	}
	switch mid {
	case 837:
		c.Family = app.ReadDialog
		c.Value, e = requiredInt64(params, "dialog_id")
	case 843:
		c.Family = app.TalkAward
		c.Value, e = requiredInt64(params, "dialog_id")
		if e == nil {
			var rawReward int64
			c.SelectID, rawReward, c.HasSelect, e = librarySelectInfo(params)
			c.IsReward = rawReward > 0
			if rawReward > 1 {
				c.RawReward = rawReward
			}
		}
	case 844:
		c.Family = app.ActAward
		c.Value, e = requiredInt64(params, "act_id")
	case 845, 846, 847:
		// No stock caller and no recovered reply shape (C14/B7).
		return conflictRefusal(1)
	case 851:
		c.Family = app.SchoolStory
		c.Value, e = requiredInt64(params, "talk_id")
	case 840:
		c.Family = app.Gift
		c.Value, e = requiredInt64(params, "gift_id")
		n, err := requiredInt64(params, "gift_num")
		if err != nil || n != 1 {
			return badHero("invalid_library_gift_num")
		}
	case 839:
		c.Family = app.BuyGift
		c.Value, e = requiredInt64(params, "gift_id")
		n, err := requiredInt64(params, "gift_num")
		if err != nil || n != 1 {
			return badHero("invalid_library_gift_num")
		}
	case 835:
		c.Family = app.Board
		c.Value, e = requiredInt64(params, "card_status")
		if e == nil {
			c.SelectID, e = requiredInt64(params, "board_model_id")
			c.HasSelect = true
		}
	case 855:
		c.Family = app.CGClaim
		c.Value, e = requiredInt64(params, "index")
	case 856:
		c.Family = app.Background
		c.Value, e = requiredInt64(params, "bg_id")
	case 857:
		c.Family = app.Background
		c.Value, e = requiredInt64(params, "bg_id")
		if e == nil {
			c.SelectID, e = requiredInt64(params, "_type")
			c.HasSelect = true
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
	case 843:
		if !out.HasDialog {
			return failLibrary(app.ErrUnavailable)
		}
		body["dialog_info"] = map[string]any{"is_awarded": libraryBit(out.Dialog.IsAwarded), "select_id": out.Dialog.SelectID}
		body["favor_degree"] = out.Favor
		body["awards"] = []any{}
	case 844:
		body["favor_degree"] = out.Favor
	case 851:
		body["awards"] = app.StockAwardRows(out.Awards)
	case 840:
		body = map[string]any{"gift_id": c.Value, "favor_degree": out.Favor, "is_married": func() int64 {
			if out.Married {
				return 1
			}
			return 0
		}()}
		// Replay of a receipt saved before these projections existed omits the
		// keys, so the client keeps its stored partner state.
		if out.PartnerDialogs != nil {
			body["partner_dialogs"] = out.PartnerDialogs
		}
		if out.PartnerActs != nil {
			body["partner_acts"] = out.PartnerActs
		}
	case 852:
		body["feed_add"] = out.Delta
	case 854:
		body["feed_attrs"] = out.Applied
	case 835:
		body = map[string]any{"board_partner": out.BoardPartner, "board_card": out.BoardCard, "board_model_id": out.BoardModelID}
	case 839:
		body = map[string]any{"gift_id": out.GiftID, "gift_num": out.GiftNum}
	case 855:
		body["awards"] = app.StockAwardRows(out.Awards)
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
	if errors.Is(e, app.ErrRejected) || errors.Is(e, app.ErrRetired) || errors.Is(e, library.ErrUnqualified) || errors.Is(e, library.ErrDialogClosed) || errors.Is(e, library.ErrActLocked) || errors.Is(e, library.ErrActAwarded) || errors.Is(e, library.ErrCGClaimed) || errors.Is(e, library.ErrBgOwned) || errors.Is(e, economy.ErrInsufficientBalance) {
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

// librarySelectInfo parses 843's "<is_reward>|<option>" without inventing a
// default when the field is absent (the dialog-end call).
func librarySelectInfo(params map[string]any) (selectID, rawReward int64, present bool, err error) {
	raw, ok := params["select_info"]
	if !ok {
		return 0, 0, false, nil
	}
	text, ok := raw.(string)
	if !ok {
		return 0, 0, false, errors.New("invalid select_info")
	}
	parts := strings.Split(text, "|")
	if len(parts) != 2 {
		return 0, 0, false, errors.New("invalid select_info")
	}
	reward, rewardError := strconv.ParseInt(parts[0], 10, 64)
	if rewardError != nil || reward < 0 || reward > library.MaxWireInt || strconv.FormatInt(reward, 10) != parts[0] {
		return 0, 0, false, errors.New("invalid select_info")
	}
	option, optionError := strconv.ParseInt(parts[1], 10, 64)
	if optionError != nil || option <= 0 {
		return 0, 0, false, errors.New("invalid select_info")
	}
	return option, reward, true, nil
}
