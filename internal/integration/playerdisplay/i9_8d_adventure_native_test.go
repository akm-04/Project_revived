//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/adventurestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	appsharedroom "gxb.local/backend/v2/internal/application/sharedroom"
	d "gxb.local/backend/v2/internal/domain/adventure"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	heroproj "gxb.local/backend/v2/internal/projection/hero"
)

type adventureWake struct{}

func (adventureWake) WakeAdventureNotice(context.Context, tx.Execer, identity.PlayerID) error {
	return nil
}

type adventureOpponents struct {
	arena      appadventure.Opponent
	arenaFound bool
	robot      appadventure.Opponent
	robotFound bool
}

func (o adventureOpponents) ArenaOpponentTx(context.Context, tx.Queryer, identity.PlayerID, int64, uint64) (appadventure.Opponent, bool, error) {
	return o.arena, o.arenaFound, nil
}

func (o adventureOpponents) RobotOpponentTx(context.Context, tx.Queryer, uint64) (appadventure.Opponent, bool, error) {
	return o.robot, o.robotFound, nil
}

func adventureTestMode(t *testing.T, p *pg.Pool, clock gen.TimeAuthority, opponents appadventure.Opponents) appadventure.Mode {
	t.Helper()
	fight := combatService(t, p)
	values := i5store.Store{Queryer: p}
	content := contentstore.Store{Queryer: p}
	timed := gen.TimedRunner{Binder: gen.Binder{Time: clock}, Runner: tx.Runner{DB: p}}
	rooms := appsharedroom.Service{Timed: timed, Fresh: p, Store: sharedroomstore.Store{}, Fence: values, Players: i4store.PlayerRootLocker{}}
	fight.Inputs.Rooms = appsharedroom.AdmissionRouter{
		"ADVENTURE_ILLUSION": {Store: sharedroomstore.Store{}, Family: appadventure.RoomFamily, Slot: appadventure.IllusionSlot, ConvenerFirst: true},
		"ADVENTURE_DEFENSE":  {Store: sharedroomstore.Store{}, Family: appadventure.RoomFamily, Slot: appadventure.DefenseSlot},
	}
	owner := occultI5(p)
	return appadventure.Mode{Timed: timed, Fresh: p, Store: adventurestore.Store{}, Content: content,
		Functions: values, Directory: i4store.PlayerDirectoryReader{}, Heroes: fight.Inputs.Heroes, Combat: fight,
		Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Grants: owner, Opponents: opponents, Wake: adventureWake{},
		Rooms: rooms, RoomStore: sharedroomstore.Store{}, Mail: i5.SettlementMail{Store: values},
		Partners: ownerSummoner(p), HeroWire: heroproj.StockHero}
}

func adventureFacts(p *pg.Pool) i5.ObjectiveFacts {
	owner := occultI5(p)
	return i5.ObjectiveFacts{Owner: owner, Open: i5store.Store{Queryer: p}, Observer: appadventure.Observer{Store: adventurestore.Store{}, Wake: adventureWake{}}}
}

// adventureOwner births genuine heroes and opens functions 68 (level 11) and 43.
func adventureOwner(t *testing.T, p *pg.Pool, server identity.LogicalServerID, level int64, tables ...int64) (identity.ActorContext, []int64) {
	t.Helper()
	a, birthPartner := occultOwner(t, p, server, 0)
	picks := []int64{}
	revision := installed(t, p)
	for _, table := range tables {
		if table == 10001001 {
			picks = append(picks, birthPartner)
			continue
		}
		def := collectionResources(t, p, a, revision, table)
		h, err := ownerSummoner(p).SummonNormal(ctx, a, def.Template.TableID, def.Template.FragmentItemID, def.FragmentCount, op())
		if err != nil {
			t.Fatal("adventure hero", table, err)
		}
		picks = append(picks, h.Ref().PartnerID)
	}
	exec(t, p, `UPDATE player_directory_profiles SET lev=$2 WHERE player_id=$1`, int64(a.PlayerID), level)
	for _, function := range []int64{68, 43} {
		exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)
			VALUES($1,$2,$3,$4,clock_timestamp()-interval '1 minute') ON CONFLICT(player_id,function_id)DO NOTHING`,
			int64(a.PlayerID), function, revision, fmt.Sprintf("native:function:%d", function))
	}
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',100000,1,clock_timestamp())
		ON CONFLICT(player_id,resource_key)DO UPDATE SET amount=100000`, int64(a.PlayerID))
	return a, picks
}

func putAdventureOccurrence(t *testing.T, p *pg.Pool, player identity.PlayerID, eventType, specialData int64, occurred, end time.Time, key string) {
	t.Helper()
	exec(t, p, `INSERT INTO adventure_occurrences(player_id,event_type,occurred_at,end_time,special_data,source_key)
		VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT DO NOTHING`, int64(player), eventType, occurred.UTC(), end.UTC(), specialData, key)
}

// triggeringFact finds one fact business key whose Derive roll fires the event.
func triggeringFact(t *testing.T, player identity.PlayerID, kind string, eventID int64, opContext operation.Context) objective.Fact {
	t.Helper()
	event, ok := d.Profile(eventID)
	if !ok {
		t.Fatal("event profile")
	}
	for index := 0; index < 100000; index++ {
		fact := objective.Fact{PlayerID: player, SourceDomain: "campaign", SourceBusinessKey: fmt.Sprintf("%s-%d", kind, index), Kind: kind, Delta: 1}
		key, err := fact.Key()
		if err != nil {
			t.Fatal(err)
		}
		fires, err := d.Roll(event, key, opContext)
		if err != nil {
			t.Fatal(err)
		}
		if fires {
			return fact
		}
	}
	t.Fatal("no triggering fact")
	return objective.Fact{}
}

func recordAdventureFacts(t *testing.T, p *pg.Pool, facts i5.ObjectiveFacts, opContext operation.Context, fact objective.Fact) {
	t.Helper()
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if err = facts.RecordTx(ctx, tr, opContext, fact); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func TestI9_8DAdventureTriggerReadsAndExpiryNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, _ := adventureOwner(t, p, server, 11, 10001001)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	facts := adventureFacts(p)
	opContext := opPinned(installed(t, p))
	opContext.StartedAt = clock.at

	fact := triggeringFact(t, a.PlayerID, objective.CampaignSweepKind, d.EventDefense, opContext)
	recordAdventureFacts(t, p, facts, opContext, fact)
	if count := scalar(t, p, `SELECT count(*) FROM adventure_occurrences WHERE player_id=$1 AND event_type=10001`, int64(a.PlayerID)); count != 1 {
		t.Fatalf("trigger count %d", count)
	}
	recordAdventureFacts(t, p, facts, opContext, fact)
	if count := scalar(t, p, `SELECT count(*) FROM adventure_occurrences WHERE player_id=$1 AND event_type=10001`, int64(a.PlayerID)); count != 1 {
		t.Fatal("a replayed fact created a second occurrence")
	}
	other := triggeringFact(t, a.PlayerID, objective.CampaignSweepKind, d.EventDefense, opContext)
	recordAdventureFacts(t, p, facts, opContext, other)
	if count := scalar(t, p, `SELECT count(*) FROM adventure_occurrences WHERE player_id=$1 AND event_type=10001`, int64(a.PlayerID)); count != 1 {
		t.Fatal("one active per type was not enforced")
	}

	listed, err := mode.List(ctx, a, opContext)
	if err != nil {
		t.Fatal(err)
	}
	adventureList, _ := listed["adventure_list"].(map[string]any)
	list, _ := adventureList["list"].(map[string]any)
	if len(list) != 6 {
		t.Fatalf("list %#v", list)
	}
	info, err := mode.Info(ctx, a, d.EventDefense, opContext)
	if err != nil {
		t.Fatal(err)
	}
	detail, _ := info["detail"].(map[string]any)
	roomInfo, _ := detail["room_info"].(map[string]any)
	if roomInfo["table_id"] != int64(d.EventDefense) {
		t.Fatalf("defense detail %#v", detail)
	}
	if scalar(t, p, `SELECT count(*) FROM shared_rooms WHERE owner_player=$1 AND family='adventure' AND slot=$2`, int64(a.PlayerID), appadventure.DefenseSlot) != 1 {
		t.Fatal("first info did not create the defense room")
	}

	// 10002 and 10003 have no producer and never fire.
	for _, kind := range []string{"FAVOR", "STORE_SPEND"} {
		if _, ok := d.EventForFactKind(kind); ok {
			t.Fatal("kind has an event", kind)
		}
	}
	unknown := objective.Fact{PlayerID: a.PlayerID, SourceDomain: "library", SourceBusinessKey: "favor-1", Kind: "FAVOR", Delta: 1}
	recordAdventureFacts(t, p, facts, opContext, unknown)
	if count := scalar(t, p, `SELECT count(*) FROM adventure_occurrences WHERE player_id=$1 AND event_type IN (10002,10003)`, int64(a.PlayerID)); count != 0 {
		t.Fatal("10002/10003 fired")
	}

	// Function 68 closes below academy level 11.
	low, _ := adventureOwner(t, p, rankingServer(t, p), 10, 10001001)
	if _, err = mode.Info(ctx, low, d.EventDefense, opContext); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("level 10 gate %v", err)
	}

	// A past occurrence read answers the expiry error.
	expired := time.Now().UTC().Add(-4 * time.Hour)
	putAdventureOccurrence(t, p, a.PlayerID, d.EventBattle, 0, expired, expired.Add(2*time.Hour), "expired-pvp")
	if _, err = mode.Info(ctx, a, d.EventBattle, opContext); !errors.Is(err, d.ErrExpired) {
		t.Fatalf("expired read %v", err)
	}
}

func TestI9_8DAdventureShopPvpRobotNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, picks := adventureOwner(t, p, server, 11, 10001001)
	defender, _, defenderHero := combatOwner(t, p, server)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{arena: appadventure.Opponent{PlayerID: defender.PlayerID, Heroes: []int64{defenderHero.PartnerID}}, arenaFound: true})
	opContext := opPinned(installed(t, p))
	opContext.StartedAt = clock.at

	// Shop: 10003 is seeded because its producer is I9-11.
	now := clock.at
	putAdventureOccurrence(t, p, a.PlayerID, d.EventShop, 1001, now, now.Add(time.Hour), "shop-1")
	before := scalar(t, p, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))
	response, err := mode.BuyShop(ctx, a, 1001, opContext)
	if err != nil || response.Duplicate {
		t.Fatal("shop buy", err, response)
	}
	after := scalar(t, p, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))
	if before-after != 20 {
		t.Fatalf("shop debit %d -> %d", before, after)
	}
	if quantity := scalar(t, p, `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=50005015),0)`, int64(a.PlayerID)); quantity != 1 {
		t.Fatalf("shop grant %d", quantity)
	}
	response, err = mode.BuyShop(ctx, a, 1001, opContext)
	if err != nil || !response.Duplicate {
		t.Fatal("shop replay", err, response)
	}

	// Refusal: no crystals.
	exec(t, p, `UPDATE player_currency_balances SET amount=0 WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))
	putAdventureOccurrence(t, p, a.PlayerID, d.EventShop, 1002, now.Add(time.Minute), now.Add(time.Hour), "shop-2")
	if _, err = mode.BuyShop(ctx, a, 1002, opContext); !errors.Is(err, economy.ErrInsufficientBalance) {
		t.Fatalf("shop refusal %v", err)
	}
	exec(t, p, `UPDATE player_currency_balances SET amount=100000 WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))

	// PVP against a real Arena-shaped defense: server report and is_win.
	putAdventureOccurrence(t, p, a.PlayerID, d.EventBattle, 0, now, now.Add(2*time.Hour), "pvp-1")
	response, err = mode.Fight(ctx, a, appadventure.FightRequest{Formation: []int64{picks[0]}}, opContext)
	if err != nil {
		t.Fatal("pvp fight", err)
	}
	report, _ := response.Body["battle_report"].(string)
	if report == "" {
		t.Fatal("pvp report missing")
	}
	if win, ok := response.Body["is_win"].(int64); !ok || (win != 0 && win != 1) {
		t.Fatalf("is_win %#v", response.Body["is_win"])
	}

	// Robot fallback: no Arena opponent, a template team resolves.
	clock.Set(clock.at.Add(time.Minute))
	robotMode := adventureTestMode(t, p, clock, adventureOpponents{robot: appadventure.Opponent{TemplateHeroes: []cb.Participant{{Origin: cd.Template, Kind: cd.HeroActor, Identity: 10001001, TemplateParams: templateParams(10001001)}}}, robotFound: true})
	putAdventureOccurrence(t, p, a.PlayerID, d.EventBattle, 0, clock.at, clock.at.Add(2*time.Hour), "pvp-robot")
	response, err = robotMode.Fight(ctx, a, appadventure.FightRequest{Formation: []int64{picks[0]}}, opContext)
	if err != nil {
		t.Fatal("robot pvp", err)
	}
	if report, _ = response.Body["battle_report"].(string); report == "" {
		t.Fatal("robot report missing")
	}
}

func TestI9_8DAdventureRoomsNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, aPicks := adventureOwner(t, p, server, 100, 10001001, 10001002)
	b, bPicks := adventureOwner(t, p, server, 100, 10001003, 10001004)
	c, cPicks := adventureOwner(t, p, server, 100, 10001005, 10001006)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	opContext := opPinned(installed(t, p))
	opContext.StartedAt = clock.at

	// Defense: first info creates the room, tries are capped, a result is attested.
	// Levels 11..15 select defense campaign 100001 (battle 981001).
	now := clock.at
	exec(t, p, `UPDATE player_directory_profiles SET lev=11 WHERE player_id IN ($1,$2)`, int64(a.PlayerID), int64(b.PlayerID))
	putAdventureOccurrence(t, p, a.PlayerID, d.EventDefense, 0, now, now.Add(time.Hour), "defense-room")
	info, err := mode.Info(ctx, a, d.EventDefense, opContext)
	if err != nil {
		t.Fatal(err)
	}
	roomID := adventureRoomID(t, info)
	putAdventureOccurrence(t, p, b.PlayerID, d.EventDefense, 0, now, now.Add(time.Hour), "defense-room-b")
	if _, err = mode.EnterDefense(ctx, b, roomID, opContext); err != nil {
		t.Fatal("defense join", err)
	}
	for try := 0; try < d.DefenseTriesPerPosition; try++ {
		if _, err = mode.PrepareDefense(ctx, a, 1, opContext); err != nil {
			t.Fatal("prepare", try, err)
		}
		if _, err = mode.StartDefense(ctx, a, appadventure.FightRequest{Formation: []int64{aPicks[0]}}, 1, opContext); err != nil {
			t.Fatal("start defense", err)
		}
		if _, err = mode.DefenseResult(ctx, a, appadventure.ResultRequest{Star: 0, Damage: 100, Formation: []int64{aPicks[0]}}, 1, opContext); err != nil {
			t.Fatal("defense result", err)
		}
	}
	if _, err = mode.PrepareDefense(ctx, a, 1, opContext); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("fourth try %v", err)
	}
	// A second member with fresh tries kills the monster; the attested result is
	// clamped and the position records the killer.
	if _, err = mode.PrepareDefense(ctx, b, 1, opContext); err != nil {
		t.Fatal("second member prepare", err)
	}
	if _, err = mode.StartDefense(ctx, b, appadventure.FightRequest{Formation: []int64{bPicks[0]}}, 1, opContext); err != nil {
		t.Fatal("second member start", err)
	}
	if _, err = mode.DefenseResult(ctx, b, appadventure.ResultRequest{Star: 3, Damage: 100, Formation: []int64{bPicks[0]}}, 1, opContext); err != nil {
		t.Fatal("second member result", err)
	}
	var raw string
	if err = p.QueryRow(ctx, `SELECT payload::text FROM shared_rooms WHERE room_id=$1`, roomID).Scan(&raw); err != nil {
		t.Fatal(err)
	}
	state, err := d.LoadRoomState([]byte(raw))
	if err != nil || !state.Monsters[0].Solved {
		t.Fatalf("defense state %+v %v", state, err)
	}
	if _, err = mode.ExitDefense(ctx, a, opContext); err != nil {
		t.Fatal("owner exit", err)
	}
	if scalar(t, p, `SELECT count(*) FROM shared_rooms WHERE room_id=$1 AND status='CLOSED'`, roomID) != 1 {
		t.Fatal("owner exit did not close the defense room")
	}

	// Co-op: three real players, one worker report, mail to all, replay mails once.
	exec(t, p, `UPDATE player_directory_profiles SET lev=100 WHERE player_id IN ($1,$2,$3)`, int64(a.PlayerID), int64(b.PlayerID), int64(c.PlayerID))
	putAdventureOccurrence(t, p, a.PlayerID, d.EventIllusion, d.IllusionHiddenBoss, now, now.Add(2*time.Hour), "coop-room")
	created, err := mode.CreateCoop(ctx, a, opContext)
	if err != nil {
		t.Fatal("create coop", err)
	}
	coopID := adventureRoomIDFrom(created)
	if _, err = mode.CreateCoop(ctx, a, opContext); !errors.Is(err, appsharedroom.ErrAlreadyInRoom) {
		t.Fatalf("second room %v", err)
	}
	for _, member := range []identity.ActorContext{b, c} {
		putAdventureOccurrence(t, p, member.PlayerID, d.EventIllusion, d.IllusionHiddenBoss, now, now.Add(2*time.Hour), fmt.Sprintf("coop-%d", member.PlayerID))
		if _, err = mode.EnterCoop(ctx, member, coopID, opContext); err != nil {
			t.Fatal("coop join", err)
		}
	}
	if _, err = mode.EnterTeamFight(ctx, a, opContext); err != nil {
		t.Fatal("enter team fight", err)
	}
	for index, member := range []struct {
		actor identity.ActorContext
		picks []int64
	}{{a, aPicks}, {b, bPicks}, {c, cPicks}} {
		_ = index
		for position, hero := range member.picks {
			if _, err = mode.SelectCoop(ctx, member.actor, appadventure.PickRequest{PartnerID: hero, Position: int64(position + 1)}, opContext); err != nil {
				t.Fatal("select", err)
			}
		}
	}
	for _, member := range []identity.ActorContext{a, b, c} {
		if _, err = mode.PrepareCoop(ctx, member, opContext); err != nil {
			t.Fatal("prepare coop", err)
		}
	}
	report, err := mode.StartCoop(ctx, a, opContext)
	if err != nil {
		t.Fatal("start coop", err)
	}
	if text, _ := report["battle_report"].(string); text == "" {
		t.Fatal("coop report missing")
	}
	if err = p.QueryRow(ctx, `SELECT payload::text FROM shared_rooms WHERE room_id=$1`, coopID).Scan(&raw); err != nil {
		t.Fatal(err)
	}
	state, err = d.LoadRoomState([]byte(raw))
	if err != nil || len(state.Reports) != 3 || state.ReportID == "" {
		t.Fatalf("coop state %+v %v", state, err)
	}
	if mails := scalar(t, p, `SELECT count(*) FROM mail_records WHERE source_kind='ADVENTURE_ILLUSION' AND source_key=$1`, state.ReportID); mails != 3 {
		t.Fatalf("coop mail %d", mails)
	}
	if replay, err := mode.StartCoop(ctx, a, opContext); err != nil {
		t.Fatal("coop replay", err)
	} else if text, _ := replay["battle_report"].(string); text == "" {
		t.Fatal("coop replay report missing")
	}
	if mails := scalar(t, p, `SELECT count(*) FROM mail_records WHERE source_kind='ADVENTURE_ILLUSION' AND source_key=$1`, state.ReportID); mails != 3 {
		t.Fatal("coop replay mailed again")
	}

	// Logical servers stay isolated: another server's room is not this player's.
	other := rankingServer(t, p)
	dPlayer, _ := adventureOwner(t, p, other, 100, 10001007, 10001008)
	putAdventureOccurrence(t, p, dPlayer.PlayerID, d.EventIllusion, d.IllusionHiddenBoss, now, now.Add(2*time.Hour), "coop-other")
	if _, err = mode.CreateCoop(ctx, dPlayer, opContext); err != nil {
		t.Fatal("other server room", err)
	}
	roomA, found, err := mode.RoomStore.ReadPlayerRoomTx(ctx, p, a.PlayerID, appadventure.RoomFamily, appadventure.IllusionSlot)
	if err != nil || !found || roomA.ID != coopID {
		t.Fatal("server isolation", roomA, found, err)
	}
}

func adventureRoomID(t *testing.T, info map[string]any) int64 {
	t.Helper()
	detail, _ := info["detail"].(map[string]any)
	roomInfo, _ := detail["room_info"].(map[string]any)
	return adventureRoomIDFrom(roomInfo)
}

func adventureRoomIDFrom(body map[string]any) int64 {
	roomID, _ := body["room_id"].(int64)
	return roomID
}
