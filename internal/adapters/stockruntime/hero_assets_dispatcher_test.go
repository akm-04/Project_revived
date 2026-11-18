package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"testing"

	"gxb.local/backend/v2/internal/domain/economy"
	d "gxb.local/backend/v2/internal/domain/heroassets"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type heroAssetsFake struct {
	itemID int64
	num    int64
	err    error
	body   map[string]any
	calls  int
}

func (f *heroAssetsFake) SkillPointBuy(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	f.calls++
	return f.body, f.err
}

func (f *heroAssetsFake) UseSkillPointItem(_ context.Context, _ identity.ActorContext, itemID, num int64, _ operation.Context) (map[string]any, error) {
	f.calls++
	f.itemID, f.num = itemID, num
	return f.body, f.err
}

func TestHeroAssetsMIDsWireSuccessAndRefusal(t *testing.T) {
	stub := &heroAssetsFake{body: map[string]any{"buy_skill_times": int64(4), "skill_point": int64(13), "skill_time": int64(1700000000)}}
	dispatcher := HeroAssetsDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: stub}

	buy := dispatcher.Dispatch(context.Background(), heroReq(t, 99, map[string]any{}))
	if buy.HTTPStatus != http.StatusOK || buy.Body["buy_skill_times"] != int64(4) || stub.calls != 1 {
		t.Fatalf("MID 99 success: %+v", buy)
	}
	use := dispatcher.Dispatch(context.Background(), heroReq(t, 90, map[string]any{"item_id": int64(d.SkillPointItemID), "item_num": int64(3)}))
	if use.HTTPStatus != http.StatusOK || stub.itemID != d.SkillPointItemID || stub.num != 3 {
		t.Fatalf("MID 90 success: %+v", use)
	}
	for _, tc := range []struct {
		mid    uint16
		params map[string]any
	}{
		{99, map[string]any{"item_id": int64(1)}},
		{90, map[string]any{"item_id": int64(1)}},
		{90, map[string]any{"item_id": int64(d.SkillPointItemID), "item_num": int64(0)}},
	} {
		if malformed := dispatcher.Dispatch(context.Background(), heroReq(t, tc.mid, tc.params)); malformed.HTTPStatus != http.StatusBadRequest {
			t.Fatalf("MID %d malformed %#v: %+v", tc.mid, tc.params, malformed)
		}
	}

	for _, tc := range []struct {
		err  error
		code int64
	}{
		{d.ErrVipRequired, unprovenRefusalCode},
		{d.ErrUnsupportedItem, unprovenRefusalCode},
		{d.ErrContentMissing, unprovenRefusalCode},
		{d.ErrStaleState, staleConflictCode},
		{economy.InsufficientBalance("crystal"), insufficientDiamondCode},
	} {
		stub.err = tc.err
		refusal := dispatcher.Dispatch(context.Background(), heroReq(t, 99, map[string]any{}))
		if refusal.HTTPStatus != http.StatusConflict || refusal.Body["error_code"] != tc.code || refusal.Body["error_msg"] != "" {
			t.Fatalf("%v refusal: %+v", tc.err, refusal)
		}
	}
	stub.err = d.ErrUnavailable
	if unavailable := dispatcher.Dispatch(context.Background(), heroReq(t, 99, map[string]any{})); unavailable.HTTPStatus != http.StatusServiceUnavailable {
		t.Fatalf("unavailable: %+v", unavailable)
	}
	stub.err = errors.New("boom")
	if defect := dispatcher.Dispatch(context.Background(), heroReq(t, 99, map[string]any{})); defect.HTTPStatus != http.StatusInternalServerError {
		t.Fatalf("defect: %+v", defect)
	}
}
