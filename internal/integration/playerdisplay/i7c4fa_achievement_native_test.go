//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/conquerstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildcampaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/inscriptionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/memoirstore"
	"gxb.local/backend/v2/internal/adapters/postgres/mentorstore"
	"gxb.local/backend/v2/internal/adapters/postgres/occultstore"
	"gxb.local/backend/v2/internal/adapters/postgres/petcampaignstore"
	ach "gxb.local/backend/v2/internal/application/achievement"
	appbook "gxb.local/backend/v2/internal/application/bookskill"
	appcampaign "gxb.local/backend/v2/internal/application/campaign"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	appconquer "gxb.local/backend/v2/internal/application/conquerschool"
	appcourse "gxb.local/backend/v2/internal/application/course"
	appdorm "gxb.local/backend/v2/internal/application/dormhouse"
	gen "gxb.local/backend/v2/internal/application/generation"
	appguildcampaign "gxb.local/backend/v2/internal/application/guildcampaign"
	"gxb.local/backend/v2/internal/application/i5"
	appinscription "gxb.local/backend/v2/internal/application/inscription"
	applibrary "gxb.local/backend/v2/internal/application/librarylocal"
	appmemoir "gxb.local/backend/v2/internal/application/memoir"
	appmentor "gxb.local/backend/v2/internal/application/mentor"
	appoccult "gxb.local/backend/v2/internal/application/occult"
	apppetcampaign "gxb.local/backend/v2/internal/application/petcampaign"
	d "gxb.local/backend/v2/internal/domain/achievement"
	campaigndomain "gxb.local/backend/v2/internal/domain/campaign"
	coursedomain "gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/identity"
	inscriptiondomain "gxb.local/backend/v2/internal/domain/inscription"
	librarydomain "gxb.local/backend/v2/internal/domain/librarylocal"
	mentordomain "gxb.local/backend/v2/internal/domain/mentor"
	occultdomain "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"strconv"
	"strings"
	"testing"
	"time"
)

type fixedCounts map[int64]int64

func (f fixedCounts) OwnedStateCountsTx(_ context.Context, _ ca.CoherentReadScope, _ identity.PlayerID, families []int64) map[int64]int64 {
	out := map[int64]int64{}
	for _, id := range families {
		if n, ok := f[id]; ok {
			out[id] = n
		}
	}
	return out
}

func catalogAchievements(p *pg.Pool, counts ach.Counter) ach.Service {
	values := i5store.Store{Queryer: p}
	content := contentstore.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	grants := i5.Service{Runner: runner, Store: values, Content: content, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i7c4fa-achievement-native-fixture-secret")}
	runtime := &ach.Runtime{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Fresh: p, Active: content, Counts: counts, Fence: values, Grants: grants, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Directory: i4store.PlayerDirectoryReader{}, Servers: i4store.ServerNames{}}
	return ach.Service{Store: achievementstore.Store{}, Content: content, Population: libraryService(p, p), Runtime: runtime}
}

// productionOwnerCounts mirrors the production owner ports, which a first
// observation reads for every owned-state family.
func productionOwnerCounts(p *pg.Pool, skins ach.Skins) ach.OwnerCounts {
	content := contentstore.Store{Queryer: p}
	heroes := characterstore.Store{Queryer: p}
	return ach.OwnerCounts{
		Roster:       characterstore.RosterMetricReader{Store: characterstore.Store{}, Content: content},
		Kinds:        content,
		Books:        appbook.Service{Owner: bookstore.Store{}, Content: content, Heroes: characterstore.LibraryHeroPort{Store: heroes}},
		Conquer:      appconquer.Service{Owner: conquerstore.Store{}, Content: content, Heroes: heroes, Kinds: content, Players: i4store.PlayerRootLocker{}},
		Courses:      appcourse.Service{Owner: coursestore.Store{}, Content: content, Heroes: heroes},
		Inscriptions: appinscription.Service{Owner: inscriptionstore.Store{}, Content: content, Heroes: heroes},
		Dorm:         appdorm.Service{Heroes: characterstore.LibraryHeroPort{Store: heroes}, Owner: dormstore.Store{}, Content: content},
		Skins:        skins,
	}
}

func entry(v ach.View, id int64) ach.Entry {
	for _, x := range v.Entries {
		if x.AchievementID == id {
			return x
		}
	}
	return ach.Entry{}
}

func TestI7C4FALegacyBackfillPointsClaimsRankAndNotices(t *testing.T) {
	p := pool(t)
	a, _ := libraryFixture(t, p, true)
	if _, tracked, e := (achievementstore.Store{}).ReadRootTx(ctx, p, a.PlayerID, false); e != nil || tracked {
		t.Fatal("fixture must start as a legacy character without a root", tracked, e)
	}
	s := catalogAchievements(p, fixedCounts{d.PetsID: 9, d.NormalHeroesID: 10})
	v, e := s.Load(ctx, a, op())
	if e != nil {
		t.Fatal(e)
	}
	if len(v.Entries) != 33 || entry(v, d.PetsID).Progress != 9 || entry(v, d.PetsID).CompleteTimes[1] == 0 || entry(v, d.PetsID).CompleteTimes[2] != 0 || entry(v, 100014).CompleteTimes[0] == 0 || entry(v, 100008).Status != d.ModeNotLive || entry(v, 100008).Progress != 0 {
		t.Fatal("legacy backfill view", v)
	}
	if v.TotalPoints != 2500 || v.PointLevel != 2 || v.Rank < 1 || !reflect.DeepEqual(v.AwardStatus, []int64{-1, 1, 0, 0, 0, 0, 0, 0, 0, 0}) {
		t.Fatal("points", v.TotalPoints, v.PointLevel, v.Rank, v.AwardStatus)
	}
	var notices int
	if e = p.QueryRow(ctx, `SELECT count(*) FROM achievement_notices WHERE player_id=$1`, int64(a.PlayerID)).Scan(&notices); e != nil || notices != 4 {
		t.Fatal("notice intents", notices, e)
	}
	taken, e := s.TakeNotices(ctx, a.PlayerID, op())
	if e != nil || len(taken) == 0 || len(taken) > 3 || taken[0].TotalPoints != 2500 || taken[0].PointLevel != 2 {
		t.Fatal("notice params", taken, e)
	}
	if again, e := s.TakeNotices(ctx, a.PlayerID, op()); e != nil || len(again) != 0 {
		t.Fatal("notices delivered twice", again, e)
	}
	first := op()
	claim, e := s.Claim(ctx, a, first)
	if e != nil || claim.Level != 2 || !reflect.DeepEqual(claim.AwardStatus, []int64{-1, -1, 0, 0, 0, 0, 0, 0, 0, 0}) {
		t.Fatal("first claim", claim, e)
	}
	replay, e := s.Claim(ctx, a, first)
	if e != nil || !reflect.DeepEqual(replay, claim) {
		t.Fatal("receipt replay", replay, e)
	}
	if _, e = s.Claim(ctx, a, op()); !errors.Is(e, ach.ErrNothingToClaim) {
		t.Fatal("claim beyond reached level must refuse", e)
	}
	higher := catalogAchievements(p, fixedCounts{d.PetsID: 15, d.NormalHeroesID: 150, d.TextbooksID: 30, d.RegionsID: 5})
	if v, e = higher.Load(ctx, a, op()); e != nil || v.TotalPoints != 12500 || v.PointLevel != 3 {
		t.Fatal("higher", v.TotalPoints, v.PointLevel, e)
	}
	if second, e := higher.Claim(ctx, a, op()); e != nil || second.Level != 3 {
		t.Fatal("second claim", second, e)
	}
	var items int64
	if e = p.QueryRow(ctx, `SELECT COALESCE(sum(quantity),0) FROM player_item_stacks WHERE player_id=$1 AND item_id IN (50001039,50001173)`, int64(a.PlayerID)).Scan(&items); e != nil || items != 3 {
		t.Fatal("granted level items", items, e)
	}
	lower := catalogAchievements(p, fixedCounts{d.PetsID: 1})
	after, e := lower.Load(ctx, a, op())
	if e != nil || after.TotalPoints != 12500 || entry(after, d.PetsID).Progress != 1 || entry(after, d.PetsID).CompleteTimes[2] == 0 {
		t.Fatal("tiers must survive a falling count", after, e)
	}
	b, _ := libraryFixture(t, p, false)
	richer, e := catalogAchievements(p, fixedCounts{d.PetsID: 15, d.NormalHeroesID: 150, d.TextbooksID: 30, d.RegionsID: 5, d.RoomsID: 15}).Load(ctx, b, op())
	if e != nil || richer.TotalPoints != 15000 {
		t.Fatal(richer.TotalPoints, e)
	}
	again, e := lower.Load(ctx, a, op())
	if e != nil || richer.Rank < 1 || again.Rank <= richer.Rank {
		t.Fatal("live trophy rank order", again.Rank, richer.Rank, e)
	}
	board, e := lower.TrophyBoard(ctx, a)
	if e != nil || board.MyRank != again.Rank || board.MyPoints != 12500 || board.Region == "" {
		t.Fatal("trophy board viewer", board, e)
	}
	position := map[identity.PlayerID]int64{}
	for _, row := range board.Rows {
		position[row.Player] = row.Rank
	}
	if position[b.PlayerID] != richer.Rank || position[a.PlayerID] != again.Rank {
		t.Fatal("trophy board order", position)
	}
}

// R3_LEGACY_BACKFILL: the first observation that creates the root evaluates
// every owned-state family and 100014, even when an owner command triggers it
// for one family only.
func TestI7C4FALegacyFirstSingleFamilyObservationBackfillsAllFamilies(t *testing.T) {
	p := pool(t)
	a, _ := libraryFixture(t, p, true)
	s := catalogAchievements(p, fixedCounts{d.PetsID: 9, d.NormalHeroesID: 10})
	if e := s.Observe(ctx, a, op(), ach.Families["Pet"]); e != nil {
		t.Fatal(e)
	}
	root, tracked, e := (achievementstore.Store{}).ReadRootTx(ctx, p, a.PlayerID, false)
	if e != nil || !tracked || root.CompleteTimes[0] == nil {
		t.Fatal("100014 must be evaluated at the first observation", tracked, root.CompleteTimes, e)
	}
	progress := map[int64]int64{}
	streaks, e := (achievementstore.Store{}).ReadStreaksTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	for _, streak := range streaks {
		progress[streak.AchievementID] = streak.Current
	}
	if progress[d.PetsID] != 9 || progress[d.NormalHeroesID] != 10 {
		t.Fatal("every owned-state family must be evaluated at the first observation", progress)
	}
}

func TestI7C4FAOwnerCountsReadCanonicalRoster(t *testing.T) {
	p := pool(t)
	a, rev := libraryFixture(t, p, false)
	counts := ach.OwnerCounts{Roster: characterstore.RosterMetricReader{Store: characterstore.Store{}, Content: contentstore.Store{}}, Kinds: contentstore.Store{}}
	var got map[int64]int64
	_, e := (tx.Runner{DB: p}).Run(ctx, opPinned(rev), ach.Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		scope, e := ca.NewCoherentReadScope(sc, rev, sc.Operation.StartedAt)
		if e != nil {
			return e
		}
		got = counts.OwnedStateCountsTx(c, scope, a.PlayerID, []int64{d.NormalHeroesID, d.AwakenedHeroesID})
		return nil
	})
	if e != nil || got[d.NormalHeroesID] != 1 {
		t.Fatal(got, e)
	}
}

func TestI7C4FAOwnerCountsReadWholeRosterForCoursesAndSuits(t *testing.T) {
	p := pool(t)
	a, rev := bornActor(t, p), installed(t, p)
	var tables []int64
	rows, e := p.Raw().Query(ctx, `SELECT table_id FROM gxb_content_hero_templates WHERE revision_id=$1 AND kind='NORMAL' ORDER BY table_id LIMIT 2`, rev)
	if e != nil {
		t.Fatal(e)
	}
	for rows.Next() {
		var table int64
		if e = rows.Scan(&table); e != nil {
			t.Fatal(e)
		}
		tables = append(tables, table)
	}
	rows.Close()
	if e = rows.Err(); e != nil {
		t.Fatal(e)
	}
	if len(tables) != 2 {
		t.Fatal("fixture hero templates", tables)
	}
	for index, table := range tables {
		bornHero(t, p, a, rev, table, int64(index+1))
	}
	catalog, e := (contentstore.Store{Queryer: p}).CourseCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	insCatalog, e := (contentstore.Store{Queryer: p}).InscriptionCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	var courseID int64
	for id := range catalog.Tickets {
		if courseID == 0 || id < courseID {
			courseID = id
		}
	}
	var slots inscriptiondomain.HeroFacts
	for _, row := range insCatalog.Tables["suits"] {
		for position, id := range strings.Split(row["item_id"], "|") {
			itemID, parseErr := strconv.ParseInt(id, 10, 64)
			if parseErr != nil || position > 2 {
				t.Fatal("fixture suit", row, parseErr)
			}
			slots.Slots[position] = itemID
		}
		break
	}
	if slots.Validate(insCatalog) != nil {
		t.Fatal("fixture suit does not validate")
	}
	observed := time.Now().UTC()
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = (coursestore.Store{}).EnsureRootTx(ctx, tr, a.PlayerID, rev, observed); e != nil {
		t.Fatal(e)
	}
	if e = (inscriptionstore.Store{}).EnsureRootTx(ctx, tr, a.PlayerID, rev, observed); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	for partner := int64(1); partner <= 2; partner++ {
		tr, e = p.Begin(ctx, tx.Options{})
		if e != nil {
			t.Fatal(e)
		}
		courseHero, e := (coursestore.Store{}).LockHeroTx(ctx, tr, a.PlayerID, partner)
		if e != nil {
			t.Fatal(e)
		}
		oldCourseVersion := courseHero.Version
		courseHero.Version++
		courseHero.Facts.Courses = []coursedomain.Record{{ID: courseID, Progress: 100, Quality: catalog.Quality(0)}}
		if e = (coursestore.Store{}).SaveHeroTx(ctx, tr, courseHero, oldCourseVersion); e != nil {
			t.Fatal(e)
		}
		insHero, e := (inscriptionstore.Store{}).LockHeroTx(ctx, tr, a.PlayerID, partner)
		if e != nil {
			t.Fatal(e)
		}
		oldInscriptionVersion := insHero.Version
		insHero.Version++
		insHero.Facts = slots
		if e = (inscriptionstore.Store{}).SaveHeroTx(ctx, tr, insHero, oldInscriptionVersion); e != nil {
			t.Fatal(e)
		}
		if e = tr.Commit(ctx); e != nil {
			t.Fatal(e)
		}
	}
	courses := appcourse.Service{Owner: coursestore.Store{}, Content: contentstore.Store{Queryer: p}, Heroes: characterstore.Store{Queryer: p}}
	if n, e := courses.CompletedCourseCountTx(ctx, p, appcourse.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: observed}); e != nil || n != 2 {
		t.Fatalf("completed courses %d %v", n, e)
	}
	inscriptions := appinscription.Service{Owner: inscriptionstore.Store{}, Content: contentstore.Store{Queryer: p}, Heroes: characterstore.Store{Queryer: p}}
	if n, e := inscriptions.CompleteSuitCountTx(ctx, p, appinscription.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: observed}); e != nil || n != 2 {
		t.Fatalf("complete suits %d %v", n, e)
	}
	exec(t, p, `DELETE FROM player_course_heroes WHERE player_id=$1 AND partner_id=2`, int64(a.PlayerID))
	if _, e := courses.CompletedCourseCountTx(ctx, p, appcourse.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: observed}); e == nil {
		t.Fatal("a missing owner row must stay unobserved, never zero")
	}
}

func TestI7C4FBOwnerFactCountsObserve(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	content := contentstore.Store{Queryer: p}
	at := time.Now().UTC()

	var superTable int64
	if e := p.QueryRow(ctx, `SELECT table_id FROM gxb_content_hero_templates WHERE revision_id=$1 AND kind='SUPER' ORDER BY table_id LIMIT 1`, rev).Scan(&superTable); e != nil {
		t.Fatal(e)
	}
	bornHero(t, p, a, rev, superTable, 1)

	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = (guildcampaignstore.Store{}).UpsertDamageTx(ctx, tr, 1, 7, 1, int64(a.PlayerID), 1000000, at); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}

	tr, e = p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	petState, e := (petcampaignstore.Store{}).LockTx(ctx, tr, a.PlayerID, at)
	if e != nil {
		t.Fatal(e)
	}
	petState.Max = 50
	if e = (petcampaignstore.Store{}).SaveTx(ctx, tr, a.PlayerID, petState, at); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}

	campaignCatalog, e := content.CampaignCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	tr, e = p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	campaignRecord, e := (campaignstore.Store{}).LockTx(ctx, tr, a.PlayerID, at)
	if e != nil {
		t.Fatal(e)
	}
	if campaignRecord.Progress.Nodes == nil {
		campaignRecord.Progress.Nodes = map[int64]campaigndomain.NodeState{}
	}
	changed := []int64{}
	expectedStars := int64(0)
	for _, nodeID := range campaignCatalog.Chain(campaigndomain.Normal) {
		node, found := campaignCatalog.Node(nodeID)
		if !found || node.MapType == 1 {
			continue
		}
		nodeState := campaignRecord.Progress.State(nodeID)
		nodeState.CampaignID = nodeID
		nodeState.Star = 3
		campaignRecord.Progress.Nodes[nodeID] = nodeState
		changed = append(changed, nodeID)
		expectedStars += 3
		if expectedStars >= 100 {
			break
		}
	}
	if expectedStars < 100 {
		t.Fatalf("fixture has only %d normal campaign stars", expectedStars)
	}
	if e = (campaignstore.Store{}).SaveTx(ctx, tr, a.PlayerID, campaignRecord, changed, at); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}

	tr, e = p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = (librarystore.Store{}).EnsurePlayerRootTx(ctx, tr, a.PlayerID, at); e != nil {
		t.Fatal(e)
	}
	if _, e = (librarystore.Store{}).InsertTalkClaimTx(ctx, tr, librarydomain.TalkClaimFact{PlayerID: a.PlayerID, TalkID: 1001, ClaimedAt: at}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}

	mentorCatalog, e := content.MentorCatalog()
	if e != nil {
		t.Fatal(e)
	}
	graduatedMission := int64(0)
	for _, mission := range mentorCatalog.Missions {
		if mission.Category == mentordomain.CategoryGraduated {
			graduatedMission = mission.ID
			break
		}
	}
	if graduatedMission == 0 {
		t.Fatal("fixture has no graduated mission")
	}
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	if e = (mentorstore.Store{}).PutMissionProgressTx(ctx, tr, nil, appmentor.MissionProgress{PlayerID: a.PlayerID, MissionID: graduatedMission, Progress: 1, Version: 1}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}

	tr, e = p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	memoirState, e := (memoirstore.Store{}).LockTx(ctx, tr, a.PlayerID, at)
	if e != nil {
		t.Fatal(e)
	}
	memoirState.Initialize()
	for girl := int64(1); girl <= 10; girl++ {
		memoirState.MaxFloor[girl] = 1
	}
	if e = (memoirstore.Store{}).SaveTx(ctx, tr, a.PlayerID, memoirState, at); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}

	occultCatalog, e := content.OccultCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	if len(occultCatalog.Chapters) == 0 {
		t.Fatal("fixture has no occult chapters")
	}
	tr, e = p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if _, e = (occultstore.Store{}).LockPlayerTx(ctx, tr, int64(a.LogicalServerID), a.PlayerID, at); e != nil {
		t.Fatal(e)
	}
	chapterID := occultCatalog.Chapters[0].ID
	if e = (occultstore.Store{}).SaveScoresTx(ctx, tr, a.PlayerID, occultdomain.Scores{strconv.FormatInt(chapterID, 10): 10}, at); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}

	counts := ach.OwnerCounts{
		Roster: characterstore.RosterMetricReader{Store: characterstore.Store{}, Content: content}, Kinds: content,
		GuildCampaign: appguildcampaign.Mode{Service: appguildcampaign.Service{Store: guildcampaignstore.Store{}}},
		PetCampaign:   apppetcampaign.Mode{Store: petcampaignstore.Store{}},
		Campaign:      appcampaign.Mode{Store: campaignstore.Store{}, Content: content},
		SchoolStories: applibrary.Service{Library: librarystore.Store{}},
		Mentor:        appmentor.Service{Store: mentorstore.Store{}, Content: content},
		Memoir:        appmemoir.Mode{Store: memoirstore.Store{}},
		Occult:        appoccult.Mode{Store: occultstore.Store{}, Content: content},
	}
	service := catalogAchievements(p, counts)
	ids := []int64{d.GuildDamageID, d.SkyTowerID, d.CampaignStarsID, d.SchoolStoriesID, d.GraduatedStudentsID, d.MemoirFloorsID, d.OccultChaptersID, d.TitanID}
	if e = service.Observe(ctx, a, op(), ids); e != nil {
		t.Fatal(e)
	}
	view, e := catalogAchievements(p, fixedCounts{}).Load(ctx, a, op())
	if e != nil {
		t.Fatal(e)
	}
	want := map[int64]int64{
		d.GuildDamageID:       100,
		d.SkyTowerID:          50,
		d.CampaignStarsID:     expectedStars,
		d.SchoolStoriesID:     1,
		d.GraduatedStudentsID: 1,
		d.MemoirFloorsID:      1,
		d.OccultChaptersID:    1,
		d.TitanID:             1,
	}
	for id, progress := range want {
		got := entry(view, id)
		if got.Progress != progress || got.CompleteTimes[0] == 0 {
			t.Fatalf("achievement %d progress=%d complete=%v, want %d and tier 1", id, got.Progress, got.CompleteTimes, progress)
		}
	}
}
