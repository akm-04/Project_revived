//go:build postgres

package missions_test

import (
	"context"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
	"gxb.local/backend/v2/internal/protocol/wire"
)

// Authentication is a controlled boundary here; the real service still fences the native actor/session rows.
// This proves native dispatcher/value composition, not stock-client or bearer-transport acceptance.
type activityFixtureAuthority struct{ actor identity.ActorContext }

func (a activityFixtureAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

func TestActivityNativeMIDs160169170(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	now, err := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	at := now.Add(24 * time.Hour)
	a := runtimeActor(t, p, at)
	service := runtimeService(p, &missionClock{at: at})
	dispatcher := stockruntime.I5Dispatcher{Authority: activityFixtureAuthority{a}, Service: service, Missions: service}
	request := func(mid uint16, index any) httpedge.Response {
		t.Helper()
		params := map[string]any{}
		if index != nil {
			params["index"] = index
		}
		return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: runtimeOperation(t, at), MID: mid, ReceivedAt: at, Params: params, Claims: wire.CredentialClaims{Token: "fixture", Region: 1}}})
	}
	read := request(160, nil)
	if read.HTTPStatus != 200 || read.Body["extra_info"] == nil {
		t.Fatalf("MID160 %#v", read)
	}
	for _, mid := range []uint16{169, 170} {
		refused := request(mid, int64(1))
		if refused.HTTPStatus != 409 || refused.Body["error_code"] != int64(35028) {
			t.Fatalf("MID%d incomplete %#v", mid, refused)
		}
	}
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	store := i5store.Store{}
	root, err := store.LockMissionRootTx(ctx, tr, a.PlayerID, at)
	if err != nil {
		t.Fatal(err)
	}
	version := root.StateVersion
	root.DayHuoyue = 30
	root.WeekHuoyue = 500
	root.StateVersion++
	if err = store.SaveMissionRootTx(ctx, tr, root, version); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	for _, mid := range []uint16{169, 170} {
		for range 2 {
			reply := request(mid, int64(1))
			if reply.HTTPStatus != 200 || reply.Body["awards"] == nil || reply.Body["huoyue_info"] == nil || reply.Body["error_code"] != nil {
				t.Fatalf("MID%d success/replay %#v", mid, reply)
			}
		}
	}
	invalid := request(170, int64(3))
	if invalid.HTTPStatus != 409 || invalid.Body["error_code"] != int64(35028) {
		t.Fatalf("weekly display offset accepted %#v", invalid)
	}
}

// BUGS #106: the stock Task model seeds one huoyue copy from 2736 and adds
// each claimed mission's medal locally, so the claim path and the 2736 seed
// must agree; the Awake family carries the same seed because one model serves
// every tab.
func TestActivityNativeWeeklyHuoyueSeedAndThreshold(t *testing.T) {
	p, service, a, _, at := awakeningNativeAt(t, upcomingOctober27())
	ctx := context.Background()
	catalog, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	if _, err = service.ReadMissions(ctx, a, objective.Daily, runtimeOperation(t, at)); err != nil {
		t.Fatal(err)
	}
	op := runtimeOperation(t, at)
	op.Policies, err = policy.NewSet(policy.Ref{Name: "content", Version: catalog.RevisionID()})
	if err != nil {
		t.Fatal(err)
	}
	timed, err := gen.NewTimedOperation(op, at)
	if err != nil {
		t.Fatal(err)
	}
	facts := i5.ObjectiveFacts{Owner: service, Open: i5store.Store{}}
	record := func(source, kind string, delta int64) {
		t.Helper()
		tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
		if err != nil {
			t.Fatal(err)
		}
		prepared, err := facts.PrepareTx(ctx, tr, a.PlayerID, timed)
		if err != nil {
			tr.Rollback(ctx)
			t.Fatal(err)
		}
		if err = facts.RecordTx(prepared, tr, op, objective.Fact{PlayerID: a.PlayerID, SourceDomain: "huoyue-native", SourceBusinessKey: source, Kind: kind, Delta: delta}); err != nil {
			tr.Rollback(ctx)
			t.Fatal(err)
		}
		if err = tr.Commit(ctx); err != nil {
			t.Fatal(err)
		}
	}
	for _, claim := range []struct {
		id     int64
		source string
		kind   string
		delta  int64
	}{
		{10002, "huoyue-campaign", "CAMPAIGN_NORMAL_WIN", 10},
		{10006, "huoyue-pvp", "PVP_FIGHT", 3},
		{10007, "huoyue-skill", "HERO_SKILL_UPGRADED", 3},
		{10009, "huoyue-juice", "VENDING_JUICE_PURCHASED", 5},
		{10029, "huoyue-intimacy", "INTIMACY_IMPROVED", 1},
	} {
		record(claim.source, claim.kind, claim.delta)
		if _, err = service.ClaimMission(ctx, a, claim.id, "", runtimeOperation(t, at)); err != nil {
			t.Fatalf("claim %d: %v", claim.id, err)
		}
	}
	var expected int64
	for _, definition := range catalog.Objectives.Definitions {
		for _, id := range []int64{10002, 10006, 10007, 10009, 10029} {
			if definition.ObjectiveID == id {
				expected += definition.Huoyue
			}
		}
	}
	root, err := (i5store.Store{}).ReadMissionRootTx(ctx, p, a.PlayerID)
	if err != nil || root.DayHuoyue != expected || root.WeekHuoyue != expected {
		t.Fatalf("claim medals day=%d week=%d want %d: %v", root.DayHuoyue, root.WeekHuoyue, expected, err)
	}

	dispatcher := stockruntime.I5Dispatcher{Authority: activityFixtureAuthority{a}, Service: service, Missions: service, Awakening: &service}
	request := func(mid uint16, params map[string]any) httpedge.Response {
		t.Helper()
		return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: runtimeOperation(t, at), MID: mid, ReceivedAt: at, Params: params, Claims: wire.CredentialClaims{Token: "fixture", Region: 1}}})
	}
	huoyue := func(body map[string]any) map[string]any {
		t.Helper()
		extra, ok := body["extra_info"].(map[string]any)
		if !ok {
			t.Fatalf("reply lacks extra_info: %+v", body)
		}
		info, ok := extra["huoyue_info"].(map[string]any)
		if !ok {
			t.Fatalf("reply lacks huoyue_info: %+v", extra)
		}
		return info
	}
	daily := request(2736, map[string]any{"mission_type": int64(1)})
	if daily.HTTPStatus != 200 || root.WeekHuoyue != huoyue(daily.Body)["week_huoyue"] {
		t.Fatalf("2736 daily seed %#v", daily)
	}
	if violations := (replyconformance.Checker{}).Check(2736, daily.Body); len(violations) != 0 {
		t.Fatalf("2736 daily conformance: %v", violations)
	}
	awake := request(2736, map[string]any{"mission_type": int64(5)})
	if awake.HTTPStatus != 200 || awake.Body["mission_list"] == nil || huoyue(awake.Body)["week_huoyue"] != expected {
		t.Fatalf("2736 awake seed %#v", awake)
	}
	if violations := (replyconformance.Checker{}).Check(2736, awake.Body); len(violations) != 0 {
		t.Fatalf("2736 awake conformance: %v", violations)
	}
	dayChest := request(169, map[string]any{"index": int64(1)})
	if awards, _ := dayChest.Body["awards"].([]map[string]any); dayChest.HTTPStatus != 200 || len(awards) == 0 {
		t.Fatalf("day chest at %d: %#v", expected, dayChest)
	}
	below := request(170, map[string]any{"index": int64(1)})
	if below.HTTPStatus != 409 || below.Body["error_code"] != int64(35028) {
		t.Fatalf("weekly chest below 500: %#v", below)
	}
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	store := i5store.Store{}
	root, err = store.LockMissionRootTx(ctx, tr, a.PlayerID, at)
	if err != nil {
		tr.Rollback(ctx)
		t.Fatal(err)
	}
	version := root.StateVersion
	root.WeekHuoyue = 500
	root.StateVersion++
	if err = store.SaveMissionRootTx(ctx, tr, root, version); err != nil {
		tr.Rollback(ctx)
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	atThreshold := request(170, map[string]any{"index": int64(1)})
	awards, _ := atThreshold.Body["awards"].([]map[string]any)
	flags, _ := atThreshold.Body["huoyue_info"].(map[string]any)["week_award"].([]int64)
	if atThreshold.HTTPStatus != 200 || len(awards) == 0 || len(flags) != 2 || flags[0] != 1 {
		t.Fatalf("weekly chest at 500: %#v", atThreshold)
	}
	high := request(170, map[string]any{"index": int64(2)})
	if high.HTTPStatus != 409 || high.Body["error_code"] != int64(35028) {
		t.Fatalf("weekly chest 1000 at 500: %#v", high)
	}
}
