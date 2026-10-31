package stockruntime

import (
	"context"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/occult"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type occultStub struct {
	err     error
	created int64
	settled app.SettleRequest
}

func (s *occultStub) reply() (map[string]any, error) { return map[string]any{}, s.err }

func (s *occultStub) Info(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return s.reply()
}
func (s *occultStub) CampaignInfo(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	return s.reply()
}
func (s *occultStub) MemberStat(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error) {
	return s.reply()
}
func (s *occultStub) Logs(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return s.reply()
}
func (s *occultStub) CreateSolo(_ context.Context, _ identity.ActorContext, chapter int64, _ operation.Context) (map[string]any, error) {
	s.created = chapter
	return s.reply()
}
func (s *occultStub) ExitRoom(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	return s.reply()
}
func (s *occultStub) Prepare(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error) {
	return s.reply()
}
func (s *occultStub) StartFight(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error) {
	return s.reply()
}
func (s *occultStub) QuitFight(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return s.reply()
}
func (s *occultStub) ChangePosition(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	return s.reply()
}
func (s *occultStub) Settle(_ context.Context, _ identity.ActorContext, request app.SettleRequest, _ operation.Context) (map[string]any, error) {
	s.settled = request
	return s.reply()
}
func (s *occultStub) Sweep(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	return s.reply()
}

func TestOccultEverySoloMIDRoutes(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	dispatcher := OccultDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: &occultStub{}}
	stage := func() map[string]any { return map[string]any{"campaign_id": int64(20011), "sub_id": int64(1)} }
	requests := map[uint16]map[string]any{
		2362: {}, 2364: {"campaign_id": int64(20011), "stay_pos": int64(20010)}, 2365: {"player_id": int64(100001)},
		2366: {"chapter_id": int64(2), "campaign_type": int64(2)}, 2368: {"room_id": int64(7)}, 2371: stage(), 2373: stage(), 2379: stage(), 2380: {},
		2372: {"campaign_id": int64(20011), "sub_id": int64(1), "star": int64(3), "formation": "11|12", "hero_status": map[string]any{"11": map[string]any{"hp": float64(90), "mp": float64(40), "is_reborn": float64(0)}}, "monster_status": map[string]any{}},
		2384: {"stay_pos": int64(20010)}, 2385: {"chapter_id": int64(2)},
	}
	if len(requests) != len(OccultMIDs) {
		t.Fatalf("OccultMIDs %v are not all exercised", OccultMIDs)
	}
	for _, mid := range OccultMIDs {
		got := dispatcher.Dispatch(context.Background(), illusionRequest(mid, requests[mid], now))
		if got.HTTPStatus != 200 {
			t.Fatalf("MID %d: %d %#v", mid, got.HTTPStatus, got.Body)
		}
	}
}

func TestOccultReadsSettleFields(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	stub := &occultStub{}
	dispatcher := OccultDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: stub}
	params := map[string]any{"campaign_id": int64(20011), "sub_id": int64(2), "star": int64(2), "pet_id": int64(5), "formation": "11|12",
		"hero_status": map[string]any{"11": map[string]any{"hp": float64(90), "mp": float64(40)}}}
	if got := dispatcher.Dispatch(context.Background(), illusionRequest(2372, params, now)); got.HTTPStatus != 200 {
		t.Fatalf("%d %#v", got.HTTPStatus, got.Body)
	}
	want := app.SettleRequest{CampaignID: 20011, SubID: 2, Star: 2, PetID: 5, Formation: []int64{11, 12}, Heroes: map[int64]d.HeroStatus{11: {HP: 90, MP: 40}}}
	if stub.settled.CampaignID != want.CampaignID || stub.settled.SubID != 2 || stub.settled.Star != 2 || stub.settled.PetID != 5 || len(stub.settled.Formation) != 2 || stub.settled.Heroes[11] != want.Heroes[11] {
		t.Fatalf("settled=%+v", stub.settled)
	}
}

func TestOccultForgedParametersAre400(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	dispatcher := OccultDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: &occultStub{}}
	for name, request := range map[string]struct {
		mid    uint16
		params map[string]any
	}{
		"star above three":      {2372, map[string]any{"campaign_id": int64(1), "sub_id": int64(1), "star": int64(4), "formation": "11", "hero_status": map[string]any{}}},
		"hero status not map":   {2372, map[string]any{"campaign_id": int64(1), "sub_id": int64(1), "star": int64(1), "formation": "11", "hero_status": "x"}},
		"unknown key":           {2362, map[string]any{"cheat": int64(1)}},
		"zero sub":              {2379, map[string]any{"campaign_id": int64(1), "sub_id": int64(0)}},
		"unknown campaign type": {2366, map[string]any{"chapter_id": int64(1), "campaign_type": int64(3)}},
	} {
		if got := dispatcher.Dispatch(context.Background(), illusionRequest(request.mid, request.params, now)); got.HTTPStatus != 400 {
			t.Fatalf("%s: %d %#v", name, got.HTTPStatus, got.Body)
		}
	}
}

func TestOccultCoopCreateIsRefusedUntilTheTeamFlow(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	stub := &occultStub{}
	dispatcher := OccultDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: stub}
	got := dispatcher.Dispatch(context.Background(), illusionRequest(2366, map[string]any{"chapter_id": int64(2), "campaign_type": int64(1)}, now))
	if got.HTTPStatus != 200 || got.Body["error_code"] != int64(1) || stub.created != 0 {
		t.Fatalf("%d %#v created=%d", got.HTTPStatus, got.Body, stub.created)
	}
}

func TestOccultRefusalIsBareErrorCodeAndFailureIs503(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	refused := OccultDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: &occultStub{err: d.ErrRefused}}
	if got := refused.Dispatch(context.Background(), illusionRequest(2362, map[string]any{}, now)); got.HTTPStatus != 200 || got.Body["error_code"] != int64(1) {
		t.Fatalf("%d %#v", got.HTTPStatus, got.Body)
	}
	failed := OccultDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: &occultStub{err: d.ErrUnavailable}}
	if got := failed.Dispatch(context.Background(), illusionRequest(2362, map[string]any{}, now)); got.HTTPStatus != 503 {
		t.Fatalf("%d %#v", got.HTTPStatus, got.Body)
	}
}

func TestOccultDeadCampaignAwardStaysInactive(t *testing.T) {
	for _, mid := range OccultMIDs {
		if mid == 2381 {
			t.Fatal("2381 has no stock sender and must not be dispatched")
		}
	}
	found := false
	for _, mid := range InactiveModeMIDs {
		found = found || mid == 2381
	}
	if !found {
		t.Fatal("2381 must answer through the inactive dispatcher")
	}
}
