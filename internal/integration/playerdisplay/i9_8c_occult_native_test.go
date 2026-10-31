//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"errors"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterbirth"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/occultstore"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	"gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/application/characterpet"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	oc "gxb.local/backend/v2/internal/application/occult"
	appsharedroom "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// occultI5 is the production I5 owner with the awakening runtime the freeze needs.
func occultI5(p *pg.Pool) i5.Service {
	owner := compositeI5(p)
	content := contentstore.Store{Queryer: p}
	store := characterstore.Store{Queryer: p}
	owner.Awakening = &i5.AwakeningRuntime{Store: i5store.Store{Queryer: p}, Content: content, Stacks: i5store.Store{Queryer: p},
		Costs: i5.MaterialCostDebiter{Store: i5store.Store{Queryer: p}, Content: content},
		Heroes: characterhero.Service{AcquisitionStore: store, Acquisition: content, CollectionAdmission: characterhero.CatalogCollectionAdmission{Content: content},
			FreshFacets: characterbirth.FreshHeroFacets(), Equipment: content, Awakening: struct {
				characterstore.Store
				characterstore.RawAwakeningStore
			}{Store: store}},
		Pets: characterpet.Service{Store: store, Awakening: store, Equipment: content}}
	return owner
}

func occultMode(t *testing.T, p *pg.Pool, clock gen.TimeAuthority) oc.Mode {
	t.Helper()
	fight := combatService(t, p)
	values := i5store.Store{Queryer: p}
	content := contentstore.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	timed := gen.TimedRunner{Binder: gen.Binder{Time: clock}, Runner: runner}
	rooms := appsharedroom.Service{Timed: timed, Fresh: p, Store: sharedroomstore.Store{}, Fence: values, Players: i4store.PlayerRootLocker{}}
	fight.Inputs.Rooms = appsharedroom.AdmissionBinding{Store: sharedroomstore.Store{}, Family: oc.RoomFamily, Slot: oc.RoomSlot}
	owner := occultI5(p)
	return oc.Mode{Timed: timed, Fresh: p, Store: occultstore.Store{}, Content: content, Fence: values, Players: i4store.PlayerRootLocker{},
		Functions: values, Directory: i4store.PlayerDirectoryReader{}, Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets,
		Rooms: rooms, RoomStore: sharedroomstore.Store{}, Combat: fight, Tickets: owner, Values: owner, Awakening: owner,
		Facts: i5.ObjectiveFacts{Owner: owner, Open: values}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func occultSetTickets(t *testing.T, p *pg.Pool, player identity.PlayerID, amount int64) {
	t.Helper()
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'occult_ticket',$2,1,clock_timestamp())
		ON CONFLICT(player_id,resource_key)DO UPDATE SET amount=$2,state_version=player_currency_balances.state_version+1`, int64(player), amount)
}

func occultTickets(t *testing.T, p *pg.Pool, player identity.PlayerID) int64 {
	t.Helper()
	return scalar(t, p, `SELECT COALESCE((SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='occult_ticket'),0)`, int64(player))
}

// occultOwner is a level-100 genuine combat owner with function 67 open and the
// requested ticket balance; it returns the birth Hero used as the solo formation.
func occultOwner(t *testing.T, p *pg.Pool, server identity.LogicalServerID, tickets int64) (identity.ActorContext, int64) {
	t.Helper()
	a, _, ref := combatOwner(t, p, server)
	revision := installed(t, p)
	exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)VALUES($1,67,$2,'function.lua:67:1|85',clock_timestamp()-interval '1 minute')
		ON CONFLICT(player_id,function_id)DO NOTHING`, int64(a.PlayerID), revision)
	exec(t, p, `UPDATE player_directory_profiles SET lev=100 WHERE player_id=$1`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_pet_roots(player_id,next_pet_id,state_version,created_at,updated_at)VALUES($1,1,1,clock_timestamp(),clock_timestamp())
		ON CONFLICT(player_id)DO NOTHING`, int64(a.PlayerID))
	occultSetTickets(t, p, a.PlayerID, tickets)
	return a, ref.PartnerID
}

func occultTestMode(t *testing.T, p *pg.Pool) (oc.Mode, *leagueClock) {
	t.Helper()
	clock := &leagueClock{at: time.Now().UTC().Truncate(time.Second)}
	return occultMode(t, p, clock), clock
}

func occultRoomID(t *testing.T, body map[string]any) int64 {
	t.Helper()
	base, _ := body["base_info"].(map[string]any)
	roomID, ok := base["room_id"].(int64)
	if !ok || roomID <= 0 {
		t.Fatalf("room id %#v", body)
	}
	return roomID
}

func occultRoomState(t *testing.T, p *pg.Pool, roomID int64) d.RunState {
	t.Helper()
	var raw string
	if err := p.QueryRow(ctx, `SELECT payload::text FROM shared_rooms WHERE room_id=$1`, roomID).Scan(&raw); err != nil {
		t.Fatal(err)
	}
	state, err := d.LoadRunState([]byte(raw))
	if err != nil {
		t.Fatal(err)
	}
	return state
}

func occultItemQuantity(t *testing.T, p *pg.Pool, player identity.PlayerID, item int64) int64 {
	t.Helper()
	return scalar(t, p, `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(player), item)
}

// putOccultAwakening writes one active ordinary stage-1 occurrence at the given
// generation; mission 0 leaves the root empty.
func putOccultAwakening(t *testing.T, p *pg.Pool, player identity.PlayerID, mission, generation int64, complete bool) {
	t.Helper()
	revision := installed(t, p)
	root := objective.NewAwakeRoot()
	if mission > 0 {
		root.Active[0] = objective.AwakeInstance{Mission: mission, Type: 1, OwnerID: int64(player), Generation: generation, Revision: revision, Complete: complete}
		root.NextGeneration = generation + 1
	}
	raw, err := json.Marshal(root)
	if err != nil {
		t.Fatal(err)
	}
	exec(t, p, `INSERT INTO player_awakening_roots(player_id,state_version,payload)VALUES($1,$2,$3::jsonb)
		ON CONFLICT(player_id)DO UPDATE SET state_version=EXCLUDED.state_version,payload=EXCLUDED.payload`, int64(player), root.Version, string(raw))
}

type occultStagePlan struct {
	campaign int64
	stages   int64
}

var occultChapterTwoSolo = []occultStagePlan{{20011, 1}, {20012, 2}, {20013, 3}, {20014, 1}, {20015, 1}, {20016, 1}, {20017, 1}, {20018, 1}}

func occultClearChapterTwoSolo(t *testing.T, p *pg.Pool, s oc.Mode, a identity.ActorContext, formation []int64) {
	t.Helper()
	for _, plan := range occultChapterTwoSolo {
		for sub := int64(1); sub <= plan.stages; sub++ {
			if _, err := s.StartFight(ctx, a, plan.campaign, sub, op()); err != nil {
				t.Fatalf("chapter 2 fight %d/%d: %v", plan.campaign, sub, err)
			}
			if _, err := s.Settle(ctx, a, oc.SettleRequest{CampaignID: plan.campaign, SubID: sub, Star: 3, Formation: formation}, op()); err != nil {
				t.Fatalf("chapter 2 settle %d/%d: %v", plan.campaign, sub, err)
			}
		}
	}
}

func TestI9_8COccultTicketAccrualNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, _ := occultOwner(t, p, server, 0)
	revision := installed(t, p)
	exec(t, p, `INSERT INTO player_temporal_resources(player_id,resource_key,stored_amount,regen_anchor_at,state_version,policy_version,content_revision,updated_at)
		VALUES($1,'energy',100000,NULL,1,$2,$2,clock_timestamp()) ON CONFLICT(player_id,resource_key)DO UPDATE SET stored_amount=100000,state_version=player_temporal_resources.state_version+1`,
		int64(a.PlayerID), revision)
	owner := compositeI5(p)
	debit := func(amount int64) {
		t.Helper()
		tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
		if err != nil {
			t.Fatal(err)
		}
		if _, err = owner.DebitTemporalTx(ctx, tr, a.PlayerID, "energy", amount, opPinned(revision)); err != nil {
			tr.Rollback(ctx)
			t.Fatal(err)
		}
		if err = tr.Commit(ctx); err != nil {
			t.Fatal(err)
		}
	}
	debit(3000)
	if got := occultTickets(t, p, a.PlayerID); got != 1 {
		t.Fatalf("one ticket at 3000 energy, got %d", got)
	}
	if got := scalar(t, p, `SELECT COALESCE((SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='occult_energy_progress'),0)`, int64(a.PlayerID)); got != 0 {
		t.Fatalf("progress after exact ticket %d", got)
	}
	debit(3000)
	if got := occultTickets(t, p, a.PlayerID); got != 2 {
		t.Fatalf("cap of two, got %d", got)
	}
	debit(3000)
	if got := occultTickets(t, p, a.PlayerID); got != 2 {
		t.Fatalf("cap held, got %d", got)
	}
	if got := scalar(t, p, `SELECT COALESCE((SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='occult_energy_progress'),0)`, int64(a.PlayerID)); got != 0 {
		t.Fatalf("progress at cap %d", got)
	}
}

func TestI9_8COccultSoloLifecycleNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := occultOwner(t, p, server, 2)
	s, _ := occultTestMode(t, p)
	formation := []int64{partner}

	info, err := s.Info(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	if info["occult_ticket"] != int64(2) || info["base_info"].(map[string]any)["room_id"] != int64(0) {
		t.Fatalf("fresh info %#v", info)
	}
	created, err := s.CreateSolo(ctx, a, 1, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := occultRoomID(t, created)
	if created["function_type"] != int64(1) || created["room_info"].(map[string]any)["room_size"] != int64(1) {
		t.Fatalf("create %#v", created)
	}
	if got := occultTickets(t, p, a.PlayerID); got != 1 {
		t.Fatalf("solo create ticket %d", got)
	}
	campaignInfo, err := s.CampaignInfo(ctx, a, 10015, op())
	if err != nil {
		t.Fatal(err)
	}
	if rows, ok := campaignInfo["monster_infos"].([][]map[string]any); !ok || len(rows) != 3 {
		t.Fatalf("campaign info %#v", campaignInfo)
	}
	if _, err = s.StartFight(ctx, a, 10015, 1, op()); err != nil {
		t.Fatal("start", err)
	}
	if _, err = s.QuitFight(ctx, a, op()); err != nil {
		t.Fatal("quit", err)
	}
	if _, err = s.Settle(ctx, a, oc.SettleRequest{CampaignID: 10015, SubID: 1, Star: 3, Formation: formation}, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("quit stage settled", err)
	}
	if _, err = s.StartFight(ctx, a, 10015, 1, op()); err != nil {
		t.Fatal("restart after quit", err)
	}
	settled, err := s.Settle(ctx, a, oc.SettleRequest{CampaignID: 10015, SubID: 1, Star: 3, Formation: formation, Heroes: map[int64]d.HeroStatus{partner: {HP: 90, MP: 80}}}, op())
	if err != nil {
		t.Fatal("settle", err)
	}
	if settled.Duplicate || settled.Body["award_info"].(map[string]any)["award_detail"].(map[string]any)["point"] != int64(3) {
		t.Fatalf("settle %+v", settled)
	}
	duplicate, err := s.Settle(ctx, a, oc.SettleRequest{CampaignID: 10015, SubID: 1, Star: 3, Formation: formation}, op())
	if err != nil || !duplicate.Duplicate {
		t.Fatalf("duplicate %+v %v", duplicate, err)
	}
	if _, err = s.Prepare(ctx, a, 10015, 1, op()); err != nil {
		t.Fatal("prepare", err)
	}
	if _, err = s.ChangePosition(ctx, a, 10014, op()); err != nil {
		t.Fatal("change position", err)
	}
	if _, err = s.ChangePosition(ctx, a, 10015, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("non-start position accepted", err)
	}
	member, err := s.MemberStat(ctx, a, a.PlayerID, op())
	if err != nil {
		t.Fatal(err)
	}
	if heroes, ok := member["dispatch_heroes"].([]any); !ok || len(heroes) != 1 {
		t.Fatalf("member stat %#v", member)
	}
	logs, err := s.Logs(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	if rows, ok := logs["log_list"].([]json.RawMessage); !ok || len(rows) != 1 {
		t.Fatalf("logs %#v", logs)
	}
	if _, err = s.Sweep(ctx, a, 1, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("sweep without a best score", err)
	}
	if _, err = s.ExitRoom(ctx, a, roomID, op()); err != nil {
		t.Fatal("exit", err)
	}
	after, err := s.Info(ctx, a, op())
	if err != nil || after["base_info"].(map[string]any)["room_id"] != int64(0) {
		t.Fatalf("after exit %#v %v", after, err)
	}
}

func TestI9_8COccultEventAutoPassNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := occultOwner(t, p, server, 1)
	s, _ := occultTestMode(t, p)
	formation := []int64{partner}
	if _, err := s.CreateSolo(ctx, a, 1, op()); err != nil {
		t.Fatal(err)
	}
	for _, plan := range []occultStagePlan{{10015, 3}, {10016, 3}} {
		for sub := int64(1); sub <= plan.stages; sub++ {
			if _, err := s.StartFight(ctx, a, plan.campaign, sub, op()); err != nil {
				t.Fatal(err)
			}
			if _, err := s.Settle(ctx, a, oc.SettleRequest{CampaignID: plan.campaign, SubID: sub, Star: 3, Formation: formation}, op()); err != nil {
				t.Fatal(err)
			}
		}
	}
	prepared, err := s.Prepare(ctx, a, 10017, 1, op())
	if err != nil {
		t.Fatal(err)
	}
	if prepared["is_auto_pass"] != true {
		t.Fatalf("event 1 did not pass the campaign: %#v", prepared)
	}
	room, found, err := (sharedroomstore.Store{}).ReadPlayerRoomTx(ctx, p, a.PlayerID, oc.RoomFamily, oc.RoomSlot)
	if err != nil || !found {
		t.Fatal(found, err)
	}
	if state := occultRoomState(t, p, room.ID); state.StagesOf(10017)[0].HP != 0 {
		t.Fatal("auto pass left the stage standing")
	}
}

func TestI9_8COccultGateNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, _ := occultOwner(t, p, server, 2)
	s, clock := occultTestMode(t, p)
	exec(t, p, `UPDATE player_directory_profiles SET lev=84 WHERE player_id=$1`, int64(a.PlayerID))
	if _, err := s.Info(ctx, a, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("level 84 info", err)
	}
	if _, err := s.CreateSolo(ctx, a, 2, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("level 84 create", err)
	}
	exec(t, p, `UPDATE player_directory_profiles SET lev=100 WHERE player_id=$1`, int64(a.PlayerID))
	exec(t, p, `UPDATE player_function_eligibility SET eligible_at=$2 WHERE player_id=$1 AND function_id=67`, int64(a.PlayerID), clock.at.Add(time.Hour))
	if _, err := s.Info(ctx, a, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("early function gate", err)
	}
	exec(t, p, `DELETE FROM player_function_eligibility WHERE player_id=$1 AND function_id=67`, int64(a.PlayerID))
	if _, err := s.Info(ctx, a, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("closed function gate", err)
	}
}

func TestI9_8COccultClearAndSweepNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := occultOwner(t, p, server, 3)
	s, _ := occultTestMode(t, p)
	created, err := s.CreateSolo(ctx, a, 2, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := occultRoomID(t, created)
	occultClearChapterTwoSolo(t, p, s, a, []int64{partner})
	for _, item := range []int64{50010002, 240001002, 40001132, 230001002} {
		if got := occultItemQuantity(t, p, a.PlayerID, item); got != 1 {
			t.Fatalf("clear reward %d quantity %d", item, got)
		}
	}
	var best, finished int64
	if err = p.QueryRow(ctx, `SELECT (scores->>'2')::bigint FROM occult_players WHERE player_id=$1`, int64(a.PlayerID)).Scan(&best); err != nil || best != 33 {
		t.Fatalf("best score %d %v", best, err)
	}
	if err = p.QueryRow(ctx, `SELECT count(*) FROM occult_runs WHERE room_id=$1 AND finished_at IS NOT NULL`, roomID).Scan(&finished); err != nil || finished != 1 {
		t.Fatalf("run finish %d %v", finished, err)
	}
	if got := occultTickets(t, p, a.PlayerID); got != 2 {
		t.Fatalf("tickets after create %d", got)
	}
	sweepOperation := op()
	swept, err := s.Sweep(ctx, a, 2, sweepOperation)
	if err != nil {
		t.Fatal("sweep", err)
	}
	rows, ok := swept["awards"].([]map[string]any)
	if !ok || len(rows) != 3 {
		t.Fatalf("sweep awards %#v", swept)
	}
	for _, row := range rows {
		if row["item_num"] != int64(1) {
			t.Fatalf("sweep floor %#v", row)
		}
		if row["table_id"] == int64(230001002) {
			t.Fatal("a capped unique reward was re-granted")
		}
	}
	if got := occultTickets(t, p, a.PlayerID); got != 1 {
		t.Fatalf("sweep ticket %d", got)
	}
	replay, err := s.Sweep(ctx, a, 2, sweepOperation)
	if err != nil || len(replay["awards"].([]any)) != 3 {
		t.Fatalf("sweep replay %#v %v", replay, err)
	}
	if got := occultTickets(t, p, a.PlayerID); got != 1 {
		t.Fatalf("sweep replay charged again: %d", got)
	}
	if _, err = s.Sweep(ctx, a, 3, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("sweep of an uncleared chapter", err)
	}
}

func TestI9_8COccultAwakeningFragmentNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := occultOwner(t, p, server, 1)
	putOccultAwakening(t, p, a.PlayerID, 1171001, 1, false)
	s, _ := occultTestMode(t, p)
	created, err := s.CreateSolo(ctx, a, 2, op())
	if err != nil {
		t.Fatal(err)
	}
	state := occultRoomState(t, p, occultRoomID(t, created))
	frozen, pinned := state.Frozen[keyOf(int64(a.PlayerID))]
	if !pinned {
		t.Fatal("start did not pin the active occurrence")
	}
	var drop objective.AwakeFrozenDrop
	if err = json.Unmarshal(frozen, &drop); err != nil || drop.Occurrence.Mission != 1171001 || drop.ItemID != 60001170 {
		t.Fatalf("pinned %s %v", frozen, err)
	}
	occultClearChapterTwoSolo(t, p, s, a, []int64{partner})
	if got := occultItemQuantity(t, p, a.PlayerID, 60001170); got != 1 {
		t.Fatalf("fragment quantity %d", got)
	}
	// A relog is a fresh mode instance over the same player rows.
	relogged, _ := occultTestMode(t, p)
	if _, err = relogged.Info(ctx, a, op()); err != nil {
		t.Fatal("relog info", err)
	}
	if got := occultItemQuantity(t, p, a.PlayerID, 60001170); got != 1 {
		t.Fatalf("fragment after relog %d", got)
	}
}

func TestI9_8COccultAwakeningNegativeNative(t *testing.T) {
	for _, testCase := range []struct {
		name    string
		mission int64
		started func(t *testing.T, p *pg.Pool, a identity.ActorContext)
	}{
		{name: "finished mission", mission: 1171001, started: func(t *testing.T, p *pg.Pool, a identity.ActorContext) {
			putOccultAwakening(t, p, a.PlayerID, 1171001, 1, true)
		}},
		{name: "wrong chapter", mission: 1203001},
		{name: "no mission", mission: 0},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			p := pool(t)
			server := rankingServer(t, p)
			a, partner := occultOwner(t, p, server, 1)
			if testCase.mission != 0 && testCase.started == nil {
				putOccultAwakening(t, p, a.PlayerID, testCase.mission, 1, false)
			}
			if testCase.started != nil {
				testCase.started(t, p, a)
			}
			s, _ := occultTestMode(t, p)
			if _, err := s.CreateSolo(ctx, a, 2, op()); err != nil {
				t.Fatal(err)
			}
			occultClearChapterTwoSolo(t, p, s, a, []int64{partner})
			if got := occultItemQuantity(t, p, a.PlayerID, 60001170); got != 0 {
				t.Fatalf("fragment granted on %s: %d", testCase.name, got)
			}
			if got := occultItemQuantity(t, p, a.PlayerID, 50010002); got != 1 {
				t.Fatalf("clear reward missing on %s: %d", testCase.name, got)
			}
		})
	}
}

func TestI9_8COccultAwakeningAdvancedBetweenStartAndSettleNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := occultOwner(t, p, server, 1)
	putOccultAwakening(t, p, a.PlayerID, 1171001, 1, false)
	s, _ := occultTestMode(t, p)
	if _, err := s.CreateSolo(ctx, a, 2, op()); err != nil {
		t.Fatal(err)
	}
	putOccultAwakening(t, p, a.PlayerID, 1171001, 2, false)
	occultClearChapterTwoSolo(t, p, s, a, []int64{partner})
	if got := occultItemQuantity(t, p, a.PlayerID, 60001170); got != 0 {
		t.Fatalf("a new generation honoured the old freeze: %d", got)
	}
	if got := occultItemQuantity(t, p, a.PlayerID, 50010002); got != 1 {
		t.Fatalf("clear reward lost with the advanced mission: %d", got)
	}
}

func TestI9_8COccultDowntimeNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := occultOwner(t, p, server, 2)
	s, clock := occultTestMode(t, p)
	formation := []int64{partner}
	created, err := s.CreateSolo(ctx, a, 2, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := occultRoomID(t, created)
	if _, err = s.StartFight(ctx, a, 20011, 1, op()); err != nil {
		t.Fatal(err)
	}
	clock.Set(clock.at.Add(2 * d.FightSeconds * time.Second))
	if _, err = s.Settle(ctx, a, oc.SettleRequest{CampaignID: 20011, SubID: 1, Star: 3, Formation: formation}, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("a settle past the fight window was accepted", err)
	}
	if _, err = s.StartFight(ctx, a, 20011, 1, op()); err != nil {
		t.Fatal("a player stuck behind an expired window could not restart", err)
	}
	clock.Set(clock.at.Add(d.RoomSeconds * time.Second))
	reconciler := appsharedroom.Reconciler{Service: s.Rooms, Server: server, Routes: map[string]string{oc.RoomFamily: oc.RoomNoticeRoute}}
	if _, err = reconciler.Reconcile(ctx, mustTimed(t, op(), clock.at), 100); err != nil {
		t.Fatal(err)
	}
	if status := scalar(t, p, `SELECT count(*) FROM shared_rooms WHERE room_id=$1 AND status='CLOSED'`, roomID); status != 1 {
		t.Fatal("the expired room stayed open after downtime")
	}
	if _, err = s.CreateSolo(ctx, a, 2, op()); err != nil {
		t.Fatal("a new room after downtime", err)
	}
	if got := occultTickets(t, p, a.PlayerID); got != 0 {
		t.Fatalf("ticket accounting after downtime %d", got)
	}
}

func TestI9_8COccultLogicalServersIsolatedNative(t *testing.T) {
	p := pool(t)
	first, second := rankingServer(t, p), rankingServer(t, p)
	a, aPartner := occultOwner(t, p, first, 1)
	b, _ := occultOwner(t, p, second, 1)
	s, _ := occultTestMode(t, p)
	if _, err := s.CreateSolo(ctx, a, 2, op()); err != nil {
		t.Fatal(err)
	}
	occultClearChapterTwoSolo(t, p, s, a, []int64{aPartner})
	info, err := s.Info(ctx, b, op())
	if err != nil {
		t.Fatal(err)
	}
	for _, point := range info["base_info"].(map[string]any)["max_points"].([]int64) {
		if point != 0 {
			t.Fatalf("server %d saw server %d points %v", second, first, info["base_info"])
		}
	}
	if _, err = s.Sweep(ctx, b, 2, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("a foreign server unlocked the sweep", err)
	}
	logs, err := s.Logs(ctx, b, op())
	if err != nil {
		t.Fatal(err)
	}
	if rows := logs["log_list"].([]json.RawMessage); len(rows) != 0 {
		t.Fatalf("server %d saw %d foreign logs", second, len(rows))
	}
	if n := scalar(t, p, `SELECT count(*) FROM occult_logs WHERE logical_server_id=$1`, int64(second)); n != 0 {
		t.Fatal("logs leaked across servers", n)
	}
}

func keyOf(id int64) string { return strconv.FormatInt(id, 10) }
