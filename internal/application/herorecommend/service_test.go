package herorecommend

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/guild"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	statrules "gxb.local/backend/v2/internal/domain/statrules"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const testRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

type fakeTime struct{ now time.Time }

func (f *fakeTime) Now(context.Context) (time.Time, error) { return f.now, nil }

type fakeBeginner struct{}

func (fakeBeginner) Begin(context.Context, tx.Options) (tx.Tx, error) { return fakeTx{}, nil }

type fakeTx struct{}

func (fakeTx) QueryRow(context.Context, string, ...any) tx.Row { return fakeRow{} }
func (fakeTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return fakeTag{}, nil
}
func (fakeTx) Commit(context.Context) error   { return nil }
func (fakeTx) Rollback(context.Context) error { return nil }

type fakeRow struct{}

func (fakeRow) Scan(...any) error { return errors.New("no rows") }

type fakeTag struct{}

func (fakeTag) RowsAffected() int64 { return 1 }

type fakeStore struct {
	snapshots map[int64]d.Snapshot
	inserts   int
}

func (s *fakeStore) LatestSnapshotTx(_ context.Context, _ tx.Queryer, server identity.LogicalServerID) (d.Snapshot, bool, error) {
	snapshot, ok := s.snapshots[int64(server)]
	return snapshot, ok, nil
}
func (s *fakeStore) InsertSnapshotTx(_ context.Context, _ tx.Tx, snapshot d.Snapshot) error {
	if s.snapshots == nil {
		s.snapshots = map[int64]d.Snapshot{}
	}
	s.snapshots[snapshot.Server] = snapshot
	s.inserts++
	return nil
}

type fakeSource struct {
	data  d.Source
	calls int
}

func (s *fakeSource) HeroRecommendSourceTx(context.Context, tx.Queryer, identity.LogicalServerID, time.Time, int) (d.Source, error) {
	s.calls++
	return s.data, nil
}

type fakeCohort struct {
	servers []identity.LogicalServerID
	afters  []identity.LogicalServerID
	limits  []int
}

func (c *fakeCohort) ListLogicalServersAfterTx(_ context.Context, _ tx.Queryer, after identity.LogicalServerID, limit int) ([]identity.LogicalServerID, error) {
	c.afters = append(c.afters, after)
	c.limits = append(c.limits, limit)
	out := make([]identity.LogicalServerID, 0, limit)
	for _, server := range c.servers {
		if server <= after {
			continue
		}
		out = append(out, server)
		if len(out) == limit {
			break
		}
	}
	return out, nil
}

type fakeContent struct{}

func (fakeContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return testRevision, nil
}

type fakeDirectory struct {
	profiles map[identity.PlayerID]playerdirectory.Profile
}

func (d fakeDirectory) ProfileTx(_ context.Context, _ tx.Queryer, pid identity.PlayerID) (playerdirectory.Profile, bool, error) {
	profile, ok := d.profiles[pid]
	return profile, ok, nil
}

type fakeGuilds struct{}

func (fakeGuilds) ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error) {
	return guild.Membership{}, false, nil
}
func (fakeGuilds) ReadGuildTx(context.Context, tx.Queryer, guild.ID) (guild.Guild, bool, error) {
	return guild.Guild{}, false, nil
}

type fakeRoster struct{ heroes map[int64][]map[string]any }

func (r fakeRoster) HeroOriginTableIDsTx(_ context.Context, _ tx.Queryer, playerID identity.PlayerID) (map[int64]int64, error) {
	out := map[int64]int64{}
	for _, row := range r.heroes[int64(playerID)] {
		if origin, ok := row["origin_table_id"].(int64); ok {
			out[row["partner_id"].(int64)] = origin
			continue
		}
		out[row["partner_id"].(int64)] = row["table_id"].(int64)
	}
	return out, nil
}

func (r fakeRoster) OverlayMID1(_ context.Context, _ tx.Queryer, actor identity.ActorContext, _ bool, _ time.Time, detail map[string]any) error {
	rows := map[string]any{}
	for _, row := range r.heroes[int64(actor.PlayerID)] {
		rows[formatID(row["partner_id"].(int64))] = row
	}
	detail["49"] = map[string]any{"heros": rows}
	detail["780"] = map[string]any{"pets": []any{map[string]any{"pet_id": int64(7), "table_id": int64(1001)}}}
	return nil
}

type fakePower struct{ force map[[2]int64]int64 }

func (p fakePower) HeroTx(_ context.Context, _ characterasset.CoherentReadScope, ref character.HeroRef, _ publicstats.View) (publicstats.Result, error) {
	force, ok := p.force[[2]int64{int64(ref.PlayerID), ref.PartnerID}]
	if !ok {
		return publicstats.Result{}, errors.New("missing force")
	}
	return publicstats.Result{Stats: statrules.Result{Force: float64(force)}}, nil
}

func formatID(id int64) string {
	return time.Unix(id, 0).Format("") + itoa(id)
}

func itoa(id int64) string {
	if id == 0 {
		return "0"
	}
	out := ""
	for id > 0 {
		out = string(rune('0'+id%10)) + out
		id /= 10
	}
	return out
}

func testService(t *testing.T) (Service, *fakeStore, *fakeTime) {
	t.Helper()
	player := identity.PlayerID(100001)
	other := identity.PlayerID(100002)
	first := map[string]any{"partner_id": int64(55), "table_id": int64(10001001), "lev": int64(10)}
	second := map[string]any{"partner_id": int64(56), "table_id": int64(10001002), "lev": int64(10)}
	third := map[string]any{"partner_id": int64(57), "table_id": int64(10001003), "lev": int64(20)}
	topFloor := &fakeSource{data: d.Source{
		Popularity: []d.Popularity{{PlayerID: int64(player), PartnerID: 55, Score: 10}, {PlayerID: int64(player), PartnerID: 56, Score: 4}},
		Formations: []d.Formation{{PlayerID: int64(player), PartnerIDs: []int64{55, 56}, PetID: 7, Weight: 14}},
	}}
	oneOnOne := &fakeSource{data: d.Source{Formations: []d.Formation{{PlayerID: int64(player), PartnerIDs: []int64{55, 56}, PetID: 7, Weight: 100}}}}
	arena := &fakeSource{data: d.Source{
		Popularity: []d.Popularity{{PlayerID: int64(other), TableID: 10001003, Score: 5}},
		Formations: []d.Formation{{PlayerID: int64(other), TableIDs: []int64{10001003}, Weight: 2000}},
	}}
	fantasy := &fakeSource{data: d.Source{
		Popularity: []d.Popularity{{PlayerID: int64(player), PartnerID: 55, Score: 50}},
		Formations: []d.Formation{{PlayerID: int64(player), PartnerIDs: []int64{55}, Weight: 50, ParadiseID: 100004}},
	}}
	champion := &fakeSource{data: d.Source{
		Popularity: []d.Popularity{{PlayerID: int64(other), PartnerID: 57, Score: 3}},
		Formations: []d.Formation{{PlayerID: int64(other), PartnerIDs: []int64{57}, Weight: 9}},
	}}
	store := &fakeStore{}
	clock := &fakeTime{now: time.Date(2026, 11, 7, 12, 0, 0, 0, time.UTC)}
	service := Service{
		Timed:   gen.TimedRunner{Binder: gen.Binder{Time: clock}, Runner: tx.Runner{DB: fakeBeginner{}}},
		Store:   store,
		Sources: Sources{TopFloor: topFloor, OneOnOne: oneOnOne, Arena: arena, Fantasy: fantasy, GuildEvent: &fakeSource{}, Champion: champion},
		Content: fakeContent{},
		Directory: fakeDirectory{profiles: map[identity.PlayerID]playerdirectory.Profile{
			player: {PlayerID: player, Name: "first", Level: 30, AvatarID: 1, AvatarFrameID: 2, ConquerLevel: 3, ConquerLoopID: 4},
			other:  {PlayerID: other, Name: "second", Level: 40, AvatarID: 5, AvatarFrameID: 6, ConquerLevel: 7, ConquerLoopID: 8},
		}},
		Guilds:    fakeGuilds{},
		Heroes:    fakeRoster{heroes: map[int64][]map[string]any{int64(player): {first, second}, int64(other): {third}}},
		Pets:      fakeRoster{},
		HeroPower: fakePower{force: map[[2]int64]int64{{int64(player), 55}: 100, {int64(player), 56}: 200, {int64(other), 57}: 300}},
	}
	return service, store, clock
}

func testActor() identity.ActorContext {
	contextID, _ := identity.ContextIDFrom(ids.UUID{15: 1})
	return identity.ActorContext{PlayerID: 100001, LogicalServerID: 1, AccountUID: identity.AccountUID("20000007"), ContextID: contextID}
}

func testOperation(at time.Time) operation.Context {
	return operation.Context{ID: ids.UUID{15: 2}, StartedAt: at}
}

func TestOverviewAndDetailPayloads(t *testing.T) {
	service, _, _ := testService(t)
	at := time.Date(2026, 11, 7, 12, 0, 0, 0, time.UTC)
	body, err := service.Overview(context.Background(), testActor(), testOperation(at))
	if err != nil {
		t.Fatal(err)
	}
	sub, ok := body["sub_rank_list"].(map[string][]int64)
	if !ok {
		t.Fatalf("sub_rank_list %T", body["sub_rank_list"])
	}
	if len(sub["1"]) != 2 || sub["1"][0] != 10001001 || sub["1"][1] != 10001002 {
		t.Fatalf("category 1 %+v", sub["1"])
	}
	if len(sub["2"]) != 0 || len(sub["5"]) != 0 {
		t.Fatalf("empty categories %+v", sub)
	}
	if len(sub["3"]) != 1 || sub["3"][0] != 10001003 || len(sub["4"]) != 1 || sub["4"][0] != 10001001 || len(sub["6"]) != 1 || sub["6"][0] != 10001003 {
		t.Fatalf("source categories %+v", sub)
	}
	total, ok := body["total_rank_list"].([]map[string]any)
	if !ok || len(total) != 3 {
		t.Fatalf("total_rank_list %T %+v", body["total_rank_list"], body["total_rank_list"])
	}
	if total[0]["table_id"] != int64(10001001) || total[0]["recommend_score"] != int64(60) || total[1]["table_id"] != int64(10001003) || total[2]["table_id"] != int64(10001002) {
		t.Fatalf("total order %+v", total)
	}

	detail, err := service.Detail(context.Background(), testActor(), testOperation(at), 10001001)
	if err != nil {
		t.Fatal(err)
	}
	if detail["recommend_score"] != int64(60) {
		t.Fatalf("score %+v", detail["recommend_score"])
	}
	forceInfo, ok := detail["force_info"].(map[string]any)
	if !ok {
		t.Fatalf("force_info %T", detail["force_info"])
	}
	topHero, ok := forceInfo["top_hero_info"].(map[string]any)
	if !ok || topHero["force"] != int64(100) || topHero["table_id"] != int64(10001001) {
		t.Fatalf("top_hero_info %+v", forceInfo["top_hero_info"])
	}
	myHero, ok := forceInfo["my_hero_info"].(map[string]any)
	if !ok || myHero["force"] != int64(100) {
		t.Fatalf("my_hero_info %+v", forceInfo["my_hero_info"])
	}
	if forceInfo["exceed_percent"] != float64(0) {
		t.Fatalf("exceed_percent %+v", forceInfo["exceed_percent"])
	}
	formations, ok := detail["recommend_formations"].(map[string]any)
	if !ok {
		t.Fatalf("recommend_formations %T", detail["recommend_formations"])
	}
	if _, ok := formations["1"].(map[string]any); !ok {
		t.Fatalf("category 1 must be an object: %T", formations["1"])
	}
	if _, ok := formations["4"].([]map[string]any); !ok {
		t.Fatalf("category 4 must be an array: %T", formations["4"])
	}
	if _, present := formations["5"]; present {
		t.Fatal("empty Guild Event category must not be fabricated")
	}
}

func TestAwakenedHeroRecommendationUsesOriginID(t *testing.T) {
	service, _, _ := testService(t)
	roster := service.Heroes.(fakeRoster)
	awakened := roster.heroes[int64(testActor().PlayerID)][0]
	awakened["table_id"] = int64(10001011)
	awakened["origin_table_id"] = int64(10001001)
	at := time.Date(2026, 11, 7, 12, 0, 0, 0, time.UTC)

	overview, err := service.Overview(context.Background(), testActor(), testOperation(at))
	if err != nil {
		t.Fatal(err)
	}
	subRankList := overview["sub_rank_list"].(map[string][]int64)
	if len(subRankList["1"]) != 2 || subRankList["1"][0] != 10001001 {
		t.Fatalf("awakened recommendation IDs %+v", subRankList["1"])
	}
	totalRankList := overview["total_rank_list"].([]map[string]any)
	if totalRankList[0]["table_id"] != int64(10001001) {
		t.Fatalf("awakened total recommendation %+v", totalRankList[0])
	}

	detail, err := service.Detail(context.Background(), testActor(), testOperation(at), 10001001)
	if err != nil {
		t.Fatal(err)
	}
	forceInfo := detail["force_info"].(map[string]any)
	if forceInfo["top_hero_info"].(map[string]any)["table_id"] != int64(10001011) {
		t.Fatalf("detail lost the current hero form: %+v", forceInfo["top_hero_info"])
	}
	formations := detail["recommend_formations"].(map[string]any)
	formation := formations["1"].(map[string]any)["formation"].([]map[string]any)
	if formation[0]["table_id"] != int64(10001011) {
		t.Fatalf("formation lost the current hero form: %+v", formation)
	}

	rank, err := service.ForceRank(context.Background(), testActor(), testOperation(at), 10001001)
	if err != nil {
		t.Fatal(err)
	}
	myRank := rank["my_rank"].(map[string]any)
	if myRank["rank"] != int64(1) || myRank["force"] != int64(100) {
		t.Fatalf("origin ID did not resolve the viewer hero: %+v", myRank)
	}
}

func TestDetailAlwaysReturnsAnEmptyFormationMap(t *testing.T) {
	service, _, _ := testService(t)
	for _, source := range []Source{service.Sources.TopFloor, service.Sources.OneOnOne, service.Sources.Arena, service.Sources.Fantasy, service.Sources.GuildEvent, service.Sources.Champion} {
		source.(*fakeSource).data.Formations = nil
	}
	at := time.Date(2026, 11, 7, 12, 0, 0, 0, time.UTC)
	detail, err := service.Detail(context.Background(), testActor(), testOperation(at), 10001001)
	if err != nil {
		t.Fatal(err)
	}
	formations, ok := detail["recommend_formations"].(map[string]any)
	if !ok || len(formations) != 0 {
		t.Fatalf("recommend_formations %+v", detail["recommend_formations"])
	}
}

func TestForceRankPayload(t *testing.T) {
	service, _, _ := testService(t)
	at := time.Date(2026, 11, 7, 12, 0, 0, 0, time.UTC)
	body, err := service.ForceRank(context.Background(), testActor(), testOperation(at), 10001001)
	if err != nil {
		t.Fatal(err)
	}
	myRank, ok := body["my_rank"].(map[string]any)
	if !ok || myRank["rank"] != int64(1) || myRank["force"] != int64(100) {
		t.Fatalf("my_rank %+v", body["my_rank"])
	}
	rows, ok := body["rank_list"].([]map[string]any)
	if !ok || len(rows) != 1 || rows[0]["force"] != int64(100) || rows[0]["player_name"] != "first" {
		t.Fatalf("rank_list %+v", body["rank_list"])
	}
}

func TestMissingRecordAndRefusalAreContractSafe(t *testing.T) {
	service, _, _ := testService(t)
	at := time.Date(2026, 11, 7, 12, 0, 0, 0, time.UTC)
	detail, err := service.Detail(context.Background(), testActor(), testOperation(at), 10001999)
	if err != nil {
		t.Fatal(err)
	}
	if len(detail) != 0 {
		t.Fatalf("missing detail %+v", detail)
	}
	body, err := service.ForceRank(context.Background(), testActor(), testOperation(at), 10001999)
	if err != nil {
		t.Fatal(err)
	}
	myRank := body["my_rank"].(map[string]any)
	if myRank["rank"] != int64(0) || myRank["force"] != int64(0) {
		t.Fatalf("unknown hero my_rank %+v", myRank)
	}
	if len(body["rank_list"].([]map[string]any)) != 0 {
		t.Fatalf("unknown hero rank_list %+v", body["rank_list"])
	}
	if _, err := service.Detail(context.Background(), testActor(), testOperation(at), 0); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("zero table id %v", err)
	}
	if _, err := service.ForceRank(context.Background(), testActor(), testOperation(at), -1); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("negative table id %v", err)
	}
}

func TestReconcilerPagesLogicalServersAndWraps(t *testing.T) {
	service, _, _ := testService(t)
	service.Fresh = fakeTx{}
	cohort := &fakeCohort{servers: []identity.LogicalServerID{1, 2, 3}}
	service.Cohort = cohort
	reconciler := Reconciler{Service: service}
	at := time.Date(2026, 11, 7, 12, 0, 0, 0, time.UTC)
	timedOperation, err := gen.NewTimedOperation(testOperation(at), at)
	if err != nil {
		t.Fatal(err)
	}

	first, err := reconciler.Reconcile(context.Background(), timedOperation, 2)
	if err != nil {
		t.Fatal(err)
	}
	if first.Scanned != 2 || first.Settled != 2 {
		t.Fatalf("first page %+v", first)
	}
	second, err := reconciler.Reconcile(context.Background(), timedOperation, 2)
	if err != nil {
		t.Fatal(err)
	}
	if second.Scanned != 1 || second.Settled != 1 {
		t.Fatalf("second page %+v", second)
	}
	third, err := reconciler.Reconcile(context.Background(), timedOperation, 2)
	if err != nil {
		t.Fatal(err)
	}
	if third.Scanned != 2 || third.Settled != 2 {
		t.Fatalf("wrapped page %+v", third)
	}
	wantAfters := []identity.LogicalServerID{0, 2, 3, 0}
	if len(cohort.afters) != len(wantAfters) {
		t.Fatalf("page cursors %+v", cohort.afters)
	}
	for index, after := range wantAfters {
		if cohort.afters[index] != after || cohort.limits[index] != 2 {
			t.Fatalf("page %d after=%d limit=%d", index, cohort.afters[index], cohort.limits[index])
		}
	}
}

func TestWeeklySnapshotIsCachedAndRebuiltAtTheBoundary(t *testing.T) {
	service, store, clock := testService(t)
	topFloor := service.Sources.TopFloor.(*fakeSource)
	at := time.Date(2026, 11, 7, 12, 0, 0, 0, time.UTC)
	if _, err := service.Overview(context.Background(), testActor(), testOperation(at)); err != nil {
		t.Fatal(err)
	}
	if topFloor.calls != 1 || store.inserts != 1 {
		t.Fatalf("first refresh calls=%d inserts=%d", topFloor.calls, store.inserts)
	}
	if _, err := service.Overview(context.Background(), testActor(), testOperation(at.Add(time.Hour))); err != nil {
		t.Fatal(err)
	}
	if topFloor.calls != 1 || store.inserts != 1 {
		t.Fatalf("cached refresh calls=%d inserts=%d", topFloor.calls, store.inserts)
	}
	clock.now = time.Date(2026, 11, 9, 5, 0, 0, 0, time.UTC)
	if _, err := service.Overview(context.Background(), testActor(), testOperation(clock.now)); err != nil {
		t.Fatal(err)
	}
	if topFloor.calls != 2 || store.inserts != 2 {
		t.Fatalf("boundary refresh calls=%d inserts=%d", topFloor.calls, store.inserts)
	}
}

func TestWeekStartUsesMondayFiveGMT8(t *testing.T) {
	before := time.Date(2026, 11, 1, 20, 59, 59, 0, time.UTC) // Monday 04:59:59 GMT+8
	if got := WeekStart(before); !got.Equal(time.Date(2026, 10, 25, 21, 0, 0, 0, time.UTC)) {
		t.Fatalf("before boundary %s", got)
	}
	after := time.Date(2026, 11, 1, 21, 0, 0, 0, time.UTC) // Monday 05:00 GMT+8
	if got := WeekStart(after); !got.Equal(after) {
		t.Fatalf("at boundary %s", got)
	}
}

// An old Monday 04:00 UTC snapshot that still covers the instant is this
// week's snapshot until the old week rolls.
func TestLegacyWeekSnapshotIsServedAcrossTheSwitch(t *testing.T) {
	service, store, clock := testService(t)
	at := time.Date(2026, 11, 2, 1, 0, 0, 0, time.UTC) // Monday 09:00 GMT+8
	clock.now = at
	legacy := LegacyWeekStart(at)
	if legacy.Equal(WeekStart(at)) {
		t.Fatal("fixture does not cross the calendars")
	}
	store.snapshots = map[int64]d.Snapshot{1: {Schema: d.Schema, Server: 1, Generation: legacy.Unix(), Revision: testRevision, ObservedAt: at.Add(-time.Hour), Digest: "legacy"}}
	if _, err := service.Overview(context.Background(), testActor(), testOperation(at)); err != nil {
		t.Fatal(err)
	}
	if store.inserts != 0 {
		t.Fatalf("legacy snapshot was rebuilt: inserts=%d", store.inserts)
	}
}
