package stockruntime

import (
	"context"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/occult"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type occultStub struct {
	err       error
	created   int64
	teamed    int64
	joined    int64
	invited   identity.PlayerID
	kicked    identity.PlayerID
	started   bool
	settled   app.SettleRequest
	accept    *bool
	picked    app.FormationRequest
	key       string
	duplicate bool
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
func (s *occultStub) CreateTeam(_ context.Context, _ identity.ActorContext, chapter int64, _ operation.Context) (map[string]any, error) {
	s.teamed = chapter
	return s.reply()
}
func (s *occultStub) JoinRoom(_ context.Context, _ identity.ActorContext, room int64, _ operation.Context) (map[string]any, error) {
	s.joined = room
	return s.reply()
}
func (s *occultStub) Invite(_ context.Context, _ identity.ActorContext, target identity.PlayerID, _ operation.Context) (map[string]any, error) {
	s.invited = target
	return s.reply()
}
func (s *occultStub) Kick(_ context.Context, _ identity.ActorContext, target identity.PlayerID, _ operation.Context) (map[string]any, error) {
	s.kicked = target
	return s.reply()
}
func (s *occultStub) StartChallenge(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	s.started = true
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
func (s *occultStub) Settle(_ context.Context, _ identity.ActorContext, request app.SettleRequest, _ operation.Context) (app.SettleResponse, error) {
	s.settled = request
	body, err := s.reply()
	return app.SettleResponse{Body: body, Duplicate: s.duplicate}, err
}
func (s *occultStub) Sweep(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	return s.reply()
}

func (s *occultStub) TeamInvite(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error) {
	return s.reply()
}
func (s *occultStub) TeamAccept(_ context.Context, _ identity.ActorContext, _, _ int64, accept bool, _ operation.Context) (map[string]any, error) {
	s.accept = &accept
	return s.reply()
}
func (s *occultStub) TeamQuit(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error) {
	return s.reply()
}
func (s *occultStub) TeamPrepare(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error) {
	return s.reply()
}
func (s *occultStub) StartTeamFight(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error) {
	return s.reply()
}
func (s *occultStub) TeamSelect(_ context.Context, _ identity.ActorContext, request app.FormationRequest, _ operation.Context) (map[string]any, error) {
	s.picked = request
	return s.reply()
}
func (s *occultStub) TeamReport(_ context.Context, _ identity.ActorContext, key string, _ operation.Context) (map[string]any, error) {
	s.key = key
	return s.reply()
}

func TestOccultReadsTeamFightFields(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	stub := &occultStub{}
	dispatcher := OccultDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: stub}
	send := func(mid uint16, params map[string]any) int {
		return dispatcher.Dispatch(context.Background(), illusionRequest(mid, params, now)).HTTPStatus
	}
	stage := map[string]any{"campaign_id": int64(20011), "sub_id": int64(1)}
	if send(2375, map[string]any{"campaign_id": int64(20011), "sub_id": int64(1), "is_accept": int64(0)}) != 200 || stub.accept == nil || *stub.accept {
		t.Fatalf("refusal not read: %v", stub.accept)
	}
	if send(2383, map[string]any{"campaign_id": int64(20011), "sub_id": int64(1), "partner_id": int64(7), "pos": int64(2)}) != 200 || stub.picked.PartnerID != 7 || stub.picked.Position != 2 {
		t.Fatalf("hero pick %+v", stub.picked)
	}
	if send(2382, map[string]any{"campaign_id": int64(20011), "sub_id": int64(1), "report_key": "abc"}) != 200 || stub.key != "abc" {
		t.Fatalf("report key %q", stub.key)
	}
	for name, status := range map[string]int{
		"accept flag out of range": send(2375, map[string]any{"campaign_id": int64(1), "sub_id": int64(1), "is_accept": int64(2)}),
		"report key not text":      send(2382, map[string]any{"campaign_id": int64(1), "sub_id": int64(1), "report_key": int64(5)}),
		"extra key on start":       send(2377, map[string]any{"campaign_id": int64(1), "sub_id": int64(1), "cheat": int64(1)}),
		"stage missing":            send(2374, map[string]any{"campaign_id": int64(1)}),
	} {
		if status != 400 {
			t.Fatalf("%s: %d", name, status)
		}
	}
	if send(2377, stage) != 200 {
		t.Fatal("start refused")
	}
}

func TestOccultEveryRoomMIDRoutes(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	dispatcher := OccultDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: &occultStub{}}
	stage := func() map[string]any { return map[string]any{"campaign_id": int64(20011), "sub_id": int64(1)} }
	requests := map[uint16]map[string]any{
		2362: {}, 2363: {}, 2367: {"room_id": int64(7)}, 2369: {"player_id": int64(100002)}, 2370: {"player_id": int64(100002)}, 2364: {"campaign_id": int64(20011), "stay_pos": int64(20010)}, 2365: {"player_id": int64(100001)},
		2366: {"chapter_id": int64(2), "campaign_type": int64(2)}, 2368: {"room_id": int64(7)}, 2371: stage(), 2373: stage(), 2379: stage(), 2380: {},
		2372: {"campaign_id": int64(20011), "sub_id": int64(1), "star": int64(3), "formation": "11|12", "hero_status": map[string]any{"11": map[string]any{"hp": float64(90), "mp": float64(40), "is_reborn": float64(0)}}, "monster_status": map[string]any{}},
		2384: {"stay_pos": int64(20010)}, 2385: {"chapter_id": int64(2)},
		2374: stage(), 2376: stage(), 2377: stage(), 2378: stage(),
		2375: {"campaign_id": int64(20011), "sub_id": int64(1), "is_accept": int64(1)},
		2382: {"campaign_id": int64(20011), "sub_id": int64(1), "report_key": "k"},
		2383: {"campaign_id": int64(20011), "sub_id": int64(1), "pet_id": int64(9)},
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

func TestOccultDuplicateTerminalAnswersFightExist(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	duplicate := OccultDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: &occultStub{duplicate: true}}
	params := map[string]any{"campaign_id": int64(20011), "sub_id": int64(1), "star": int64(3), "formation": "11", "hero_status": map[string]any{}}
	got := duplicate.Dispatch(context.Background(), illusionRequest(2372, params, now))
	if got.HTTPStatus != 200 || got.Body["error_code"] != int64(30005) {
		t.Fatalf("duplicate %d %#v", got.HTTPStatus, got.Body)
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

func TestOccultTeamCommandsReachTheService(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	stub := &occultStub{}
	dispatcher := OccultDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: stub}
	for mid, params := range map[uint16]map[string]any{
		2366: {"chapter_id": int64(2), "campaign_type": int64(1)}, 2367: {"room_id": int64(9)}, 2369: {"player_id": int64(100002)}, 2370: {"player_id": int64(100003)}, 2363: {},
	} {
		if got := dispatcher.Dispatch(context.Background(), illusionRequest(mid, params, now)); got.HTTPStatus != 200 {
			t.Fatalf("MID %d: %d %#v", mid, got.HTTPStatus, got.Body)
		}
	}
	if stub.teamed != 2 || stub.created != 0 || stub.joined != 9 || stub.invited != 100002 || stub.kicked != 100003 || !stub.started {
		t.Fatalf("stub %+v", stub)
	}
}

func TestOccultRoomRefusalsAreBareErrorCodes(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	for _, refusal := range []error{sharedroom.ErrFull, sharedroom.ErrKicked, sharedroom.ErrNotOwner, sharedroom.ErrExpired, sr.ErrNotFound, economy.ErrInsufficientBalance} {
		dispatcher := OccultDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: &occultStub{err: refusal}}
		got := dispatcher.Dispatch(context.Background(), illusionRequest(2367, map[string]any{"room_id": int64(7)}, now))
		if got.HTTPStatus != 409 || got.Body["error_code"] != int64(1) {
			t.Fatalf("%v: %d %#v", refusal, got.HTTPStatus, got.Body)
		}
	}
}

func TestOccultRefusalIsBareErrorCodeAndFailureIs503(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	refused := OccultDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: &occultStub{err: d.ErrRefused}}
	if got := refused.Dispatch(context.Background(), illusionRequest(2362, map[string]any{}, now)); got.HTTPStatus != 409 || got.Body["error_code"] != int64(1) {
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
