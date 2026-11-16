//go:build postgres

package playerdisplay_test

import (
	"context"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/guildviewread"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildprojection"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appactivity "gxb.local/backend/v2/internal/application/activitydirectory"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	appworldboss "gxb.local/backend/v2/internal/application/worldboss"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	di "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/modes"
	dp "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Each test pauses the migrated read after its first statement, commits a
// concurrent write, then lets the read finish from the same snapshot.

func TestC13BPart2ActivityDirectory229Native(t *testing.T) {
	database := pool(t)
	installed(t, database)
	a := actor(t, database)
	exec(t, database, `UPDATE player_directory_profiles SET lev=47 WHERE player_id=$1`, int64(a.PlayerID))
	registry, err := appactivity.NewRegistry([]appactivity.Registration{{Name: "worldboss", TableID: 1026, RuntimeCapability: "activity.worldboss",
		Provider: appworldboss.ActivityProvider{Queryer: database, Directory: i4store.PlayerDirectoryReader{}}}}, nil)
	if err != nil {
		t.Fatal(err)
	}
	runtime := appactivity.Runtime{Directory: appactivity.Directory{Registry: registry}, Time: pg.AuthoritativeTime{Queryer: database}}
	gate := newSnapshotGate(database)
	dispatcher := stockruntime.ActivityDispatcher{Authority: fixedLibraryAuthority{actor: a}, Service: runtime,
		Reads: tx.Runner{DB: gate}, Levels: i4store.PlayerDirectoryReader{}}
	var response = struct{ body map[string]any }{}
	var readErr error
	err = runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE player_directory_profiles SET lev=60 WHERE player_id=$1`, int64(a.PlayerID))
		},
		func(c context.Context) error {
			reply := dispatcher.Dispatch(c, nativeDispatch(a, 229, map[string]any{}, op()))
			if reply.HTTPStatus != 200 {
				t.Fatalf("229 status %d body %+v", reply.HTTPStatus, reply.Body)
			}
			response.body = reply.Body
			readErr = nil
			return nil
		})
	if err != nil || readErr != nil {
		t.Fatalf("229 read: %v", err)
	}
	rows, ok := response.body["list"].([]any)
	if !ok || len(rows) != 1 {
		t.Fatalf("229 list %+v", response.body)
	}
	if row := rows[0].(map[string]any); row["table_id"] != int64(1026) || row["is_open"] != int64(0) {
		t.Fatalf("229 mixed the concurrent level write into the reply: %+v", row)
	}
	if got := scalar(t, database, `SELECT lev FROM player_directory_profiles WHERE player_id=$1`, int64(a.PlayerID)); got != 60 {
		t.Fatalf("concurrent write did not commit: %d", got)
	}
}

func TestC13BPart2Adventure2416Native(t *testing.T) {
	database := pool(t)
	installed(t, database)
	a, _ := adventureOwner(t, database, rankingServer(t, database), 11)
	mode := adventureTestMode(t, database, pg.AuthoritativeTime{Queryer: database}, adventureOpponents{})
	gate := newSnapshotGate(database)
	mode.Timed.Runner.DB = gate
	var body map[string]any
	err := runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE player_directory_profiles SET lev=1 WHERE player_id=$1`, int64(a.PlayerID))
		},
		func(c context.Context) error {
			var readErr error
			body, readErr = mode.List(c, a, op())
			return readErr
		})
	if err != nil {
		t.Fatalf("2416 read: %v", err)
	}
	list, ok := body["adventure_list"].(map[string]any)["list"].(map[string]any)
	if !ok || len(list) != 6 {
		t.Fatalf("2416 list %+v", body)
	}
	if got := scalar(t, database, `SELECT lev FROM player_directory_profiles WHERE player_id=$1`, int64(a.PlayerID)); got != 1 {
		t.Fatalf("concurrent write did not commit: %d", got)
	}
}

func TestC13BPart2ArenaPartners769Native(t *testing.T) {
	database := pool(t)
	installed(t, database)
	service := arenaService(t, database)
	a, _ := oneOnOnePlayer(t, database, rankingServer(t, database))
	if _, err := service.Info(ctx, a, op()); err != nil {
		t.Fatal("arena entry", err)
	}
	before := scalar(t, database, `SELECT point FROM arena_players WHERE player_id=$1`, int64(a.PlayerID))
	gate := newSnapshotGate(database)
	service.Timed.Runner.DB = gate
	var partners = struct {
		view struct{ Player struct{ Point int64 } }
	}{}
	err := runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE arena_players SET point=point+100 WHERE player_id=$1`, int64(a.PlayerID))
		},
		func(c context.Context) error {
			view, readErr := service.Partners(c, a, op())
			partners.view.Player.Point = view.Player.Point
			return readErr
		})
	if err != nil {
		t.Fatalf("769 read: %v", err)
	}
	if partners.view.Player.Point != before {
		t.Fatalf("769 saw the concurrent point write: %d want %d", partners.view.Player.Point, before)
	}
}

func TestC13BPart2HeroPieces67Native(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	a := actor(t, database)
	service := privateHeroService(database)
	mappings, err := (contentstore.Store{}).HeroPieceMappingsTx(ctx, database, revision)
	if err != nil || len(mappings) == 0 {
		t.Fatalf("piece mappings %v", err)
	}
	mapping := mappings[0]
	exec(t, database, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,5,1,clock_timestamp(),clock_timestamp())
		ON CONFLICT(player_id,item_id)DO UPDATE SET quantity=5`, int64(a.PlayerID), mapping.ItemID)
	gate := newSnapshotGate(database)
	service.Runner = tx.Runner{DB: gate}
	var pieces map[int64]int64
	err = runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE player_item_stacks SET quantity=9 WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), mapping.ItemID)
		},
		func(c context.Context) error {
			var readErr error
			pieces, readErr = service.HeroPieces(c, a, op())
			return readErr
		})
	if err != nil {
		t.Fatalf("67 read: %v", err)
	}
	if pieces[mapping.OriginTableID] != 5 {
		t.Fatalf("67 saw the concurrent stack write: %+v", pieces)
	}
}

func TestC13BPart2Charge354Native(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	a := bornActor(t, database)
	chargeTap(t, database, revision, a, 80001007, uuid().String())
	service := chargeService(database)
	gate := newSnapshotGate(database)
	service.Timed.Runner.DB = gate
	var reply map[string]any
	err := runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE commerce_charge_purchases SET charge_count=charge_count+1 WHERE player_id=$1 AND charge_id=80001007`, int64(a.PlayerID))
		},
		func(c context.Context) error {
			var readErr error
			reply, readErr = service.Query(c, a, time.Unix(1700000000, 0), op())
			return readErr
		})
	if err != nil {
		t.Fatalf("354 read: %v", err)
	}
	charges, ok := reply["charges"].([]dp.Purchase)
	if !ok {
		t.Fatalf("354 charges %#v", reply["charges"])
	}
	for _, charge := range charges {
		if charge.ChargeID == 80001007 && charge.ChargeCount != 1 {
			t.Fatalf("354 saw the concurrent purchase: %+v", charge)
		}
	}
}

func TestC13BPart2ConquerReports1571Native(t *testing.T) {
	database := pool(t)
	installed(t, database)
	service := conquerMode(t, database)
	a, girls := conquerPlayer(t, database, rankingServer(t, database))
	conquerWin(t, service, a, 10001, 1, girls[:2], 2, 5000)
	all, err := service.Reports(ctx, 1, 10001, 1, op())
	if err != nil {
		t.Fatalf("baseline reports %v", err)
	}
	// 1571 lists every server's kept reports; other tests in this database add their own.
	var before []int64
	for _, row := range all {
		if row.Owner == a.PlayerID {
			before = append(before, row.Score)
		}
	}
	if len(before) == 0 {
		t.Fatal("baseline has no report of the fixture player")
	}
	gate := newSnapshotGate(database)
	service.Timed.Runner.DB = gate
	var reports = struct{ rows []int64 }{}
	err = runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE conquer_school_reports SET score=score+1000 WHERE owner_player_id=$1`, int64(a.PlayerID))
		},
		func(c context.Context) error {
			rows, readErr := service.Reports(c, 1, 10001, 1, op())
			reports.rows = make([]int64, 0, len(rows))
			for _, row := range rows {
				if row.Owner == a.PlayerID {
					reports.rows = append(reports.rows, row.Score)
				}
			}
			return readErr
		})
	if err != nil {
		t.Fatalf("1571 read: %v", err)
	}
	if !reflect.DeepEqual(reports.rows, before) {
		t.Fatalf("1571 saw the concurrent score write: %v want %v", reports.rows, before)
	}
}

func TestC13BPart2GuildView612Native(t *testing.T) {
	database := pool(t)
	installed(t, database)
	leader := bornActor(t, database)
	gid := guildFixture(t, database, leader)
	baseline := guildviewread.Reader{Runner: tx.Runner{DB: database}}
	before, found, err := baseline.Self(ctx, leader)
	if err != nil || !found {
		t.Fatalf("baseline self %v %v", found, err)
	}
	gate := newSnapshotGate(database)
	reader := guildviewread.Reader{Runner: tx.Runner{DB: gate}}
	var name = struct{ value string }{}
	err = runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE guilds SET name='c13b-writer' WHERE guild_id=$1`, int64(gid))
		},
		func(c context.Context) error {
			view, ok, readErr := reader.Self(c, leader)
			if ok {
				name.value = view.GuildInfo.Name
			}
			return readErr
		})
	if err != nil {
		t.Fatalf("612 read: %v", err)
	}
	if name.value != before.GuildInfo.Name {
		t.Fatalf("612 saw the concurrent guild write: %q want %q", name.value, before.GuildInfo.Name)
	}
}

func TestC13BPart2GuildRentalOwnOffers593Native(t *testing.T) {
	fixture := newRentalFixture(t)
	if err := fixture.service.Place(ctx, fixture.lender, guild.RentalHero, fixture.hero, opPinned(fixture.revision)); err != nil {
		t.Fatal("place", err)
	}
	content := contentstore.Store{Queryer: fixture.pool}
	reader := rentalReader(fixture, content, authoritativeObservation)
	gate := newSnapshotGate(fixture.pool)
	reader.Runner = tx.Runner{DB: gate}
	var offers = struct{ count int }{}
	err := runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return fixture.service.Place(c, fixture.lender, guild.RentalHero, fixture.second, opPinned(fixture.revision))
		},
		func(c context.Context) error {
			rows, readErr := reader.OwnOffers(c, fixture.lender, guild.RentalHero, opPinned(fixture.revision))
			offers.count = len(rows)
			return readErr
		})
	if err != nil {
		t.Fatalf("593 read: %v", err)
	}
	if offers.count != 1 {
		t.Fatalf("593 saw the concurrent offer: %d want 1", offers.count)
	}
}

func TestC13BPart2SpiritBackpack81Native(t *testing.T) {
	database := pool(t)
	a, _, service := spiritFixture(t, database)
	const stackItem int64 = 20001157
	exec(t, database, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,3,1,clock_timestamp(),clock_timestamp())
		ON CONFLICT(player_id,item_id)DO UPDATE SET quantity=3`, int64(a.PlayerID), stackItem)
	gate := newSnapshotGate(database)
	service.Reads = tx.Runner{DB: gate}
	var quantity = struct{ value int64 }{}
	err := runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE player_item_stacks SET quantity=quantity+1 WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), stackItem)
		},
		func(c context.Context) error {
			snapshot, readErr := service.BackpackSnapshot(c, a, op())
			for _, stack := range snapshot.Stacks {
				if stack.ItemID == stackItem {
					quantity.value = stack.Quantity
				}
			}
			return readErr
		})
	if err != nil {
		t.Fatalf("81 read: %v", err)
	}
	if quantity.value != 3 {
		t.Fatalf("81 saw the concurrent stack write: %d want 3", quantity.value)
	}
}

func TestC13BPart2IllusionInfo1344Native(t *testing.T) {
	database := pool(t)
	server := rankingServer(t, database)
	a, _ := illusionOwner(t, database, server)
	service := illusionService(t, database, illusionTime(t), illusionPrivileges{level: 3}, illusionGuildSource{})
	exec(t, database, `INSERT INTO illusion_players(player_id,logical_server_id,day,chances,bought,best_hit,best_time,updated_at)VALUES($1,$2,0,$3,0,0,0,clock_timestamp())
		ON CONFLICT(player_id)DO UPDATE SET chances=$3`, int64(a.PlayerID), int64(server), di.FreeChances)
	gate := newSnapshotGate(database)
	service.Timed.Runner.DB = gate
	var chances = struct{ value int64 }{}
	err := runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE illusion_players SET chances=99 WHERE player_id=$1`, int64(a.PlayerID))
		},
		func(c context.Context) error {
			info, readErr := service.Info(c, a, op())
			chances.value = info["challenge_times"].(int64)
			return readErr
		})
	if err != nil {
		t.Fatalf("1344 read: %v", err)
	}
	if chances.value != di.FreeChances {
		t.Fatalf("1344 saw the concurrent chance write: %d want %d", chances.value, di.FreeChances)
	}
}

func TestC13BPart2OccultCampaignInfo2364Native(t *testing.T) {
	database := pool(t)
	server := rankingServer(t, database)
	a, _ := occultOwner(t, database, server, 2)
	service, _ := occultTestMode(t, database)
	if _, err := service.CreateSolo(ctx, a, 1, op()); err != nil {
		t.Fatal("create solo", err)
	}
	before, err := service.CampaignInfo(ctx, a, 10015, op())
	if err != nil {
		t.Fatalf("baseline campaign info %v", err)
	}
	gate := newSnapshotGate(database)
	service.Timed.Runner.DB = gate
	var under map[string]any
	err = runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE player_currency_balances SET amount=0 WHERE player_id=$1 AND resource_key='occult_ticket'`, int64(a.PlayerID))
		},
		func(c context.Context) error {
			var readErr error
			under, readErr = service.CampaignInfo(c, a, 10015, op())
			return readErr
		})
	if err != nil {
		t.Fatalf("2364 read: %v", err)
	}
	if !reflect.DeepEqual(before, under) {
		t.Fatalf("2364 reply changed under the concurrent write: %+v want %+v", under, before)
	}
}

func TestC13BPart2OneOnOneRecords2487Native(t *testing.T) {
	database := pool(t)
	installed(t, database)
	service := oneOnOneService(t, database)
	a, _ := oneOnOnePlayer(t, database, rankingServer(t, database))
	if _, err := service.Load(ctx, a, op()); err != nil {
		t.Fatalf("baseline load %v", err)
	}
	gate := newSnapshotGate(database)
	service.Timed.Runner.DB = gate
	var records = struct{ count int }{}
	err := runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE one_on_one_players SET points=points+100 WHERE player_id=$1`, int64(a.PlayerID))
		},
		func(c context.Context) error {
			rows, readErr := service.Records(c, a, op())
			records.count = len(rows)
			return readErr
		})
	if err != nil {
		t.Fatalf("2487 read: %v", err)
	}
	if records.count != 0 {
		t.Fatalf("2487 saw a concurrent record: %d", records.count)
	}
}

func TestC13BPart2Discovery192Native(t *testing.T) {
	database := pool(t)
	a := actor(t, database)
	gid := guildFixture(t, database, a)
	keyID := "c13b-part2-native"
	bearerKey := []byte("c13b-part2-bearer-key-00000001")
	digestKey := []byte("c13b-part2-digest-key-00000001")
	raw, err := identity.DeriveGameplayBearer(bearerKey, identity.GameplayContext{ID: a.ContextID, ContextGeneration: a.ContextGeneration})
	if err != nil {
		t.Fatal(err)
	}
	digest, err := identity.DigestGameplayBearer(digestKey, raw)
	if err != nil {
		t.Fatal(err)
	}
	exec(t, database, `INSERT INTO gameplay_context_credentials(credential_id,context_id,session_id,digest,credential_generation,derivation_key_id,issued_at)VALUES($1,$2,$3,$4,1,$5,clock_timestamp())`,
		uuid().String(), a.ContextID.UUID().String(), a.SessionID.UUID().String(), digest[:], keyID)
	realtime := apprealtime.Service{
		Authority: i4store.RealtimeAuthority{Queryer: database, DigestSecret: digestKey, BearerKeys: appidentity.StaticBearerKeyResolver{Key: appidentity.BearerDerivationKey{ID: keyID, Secret: bearerKey}}},
		Guilds:    guildprojection.RealtimeMembership{Queryer: database},
		Endpoints: stockruntime.StaticEndpoints{Endpoint: apprealtime.Endpoint{Host: "127.0.0.1", Port: 9000}},
	}
	gate := newSnapshotGate(database)
	dispatcher := stockruntime.DiscoveryDispatcher{Realtime: realtime, Reads: tx.Runner{DB: gate}}
	var room = struct{ value int64 }{}
	err = runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `DELETE FROM guild_memberships WHERE player_id=$1`, int64(a.PlayerID))
		},
		func(c context.Context) error {
			request := nativeDispatch(a, 192, map[string]any{"room_id": int64(gid)}, op())
			request.Envelope.Claims.Token = raw
			reply := dispatcher.Dispatch(c, request)
			if reply.HTTPStatus != 200 {
				t.Fatalf("192 status %d body %+v", reply.HTTPStatus, reply.Body)
			}
			room.value = reply.Body["room_id"].(int64)
			return nil
		})
	if err != nil {
		t.Fatalf("192 read: %v", err)
	}
	if room.value != int64(gid) {
		t.Fatalf("192 room %d want %d", room.value, gid)
	}
	if got := scalar(t, database, `SELECT count(*) FROM guild_memberships WHERE player_id=$1`, int64(a.PlayerID)); got != 0 {
		t.Fatalf("concurrent membership delete did not commit: %d", got)
	}
}

func TestC13BPart2TopFloorPreFight294Native(t *testing.T) {
	database := pool(t)
	service := topFloorService(t, database)
	a, _, _ := topFloorPlayer(t, database, rankingServer(t, database))
	view, err := service.Load(ctx, a, op())
	if err != nil || len(view.Enemies) == 0 {
		t.Fatalf("load offers %v", err)
	}
	enemy := view.Enemies[0].Occupant.TableID()
	if err := service.PreFight(ctx, a, enemy, op()); err != nil {
		t.Fatalf("baseline pre-fight %v", err)
	}
	gate := newSnapshotGate(database)
	service.Timed.Runner.DB = gate
	err = runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE top_floor_players SET offered='[]'::jsonb WHERE player_id=$1`, int64(a.PlayerID))
		},
		func(c context.Context) error {
			return service.PreFight(c, a, enemy, op())
		})
	if err != nil {
		t.Fatalf("294 read: %v", err)
	}
}

func TestC13BPart2WorldBossInfo624Native(t *testing.T) {
	database := pool(t)
	service := worldBossService(t, database, worldBossTime(t))
	server := rankingServer(t, database)
	a, _ := worldBossActor(t, database, server)
	worldBossSetPlayer(t, database, a.PlayerID, modes.Day(time.Now().UTC()), 2, 0)
	before, err := service.Info(ctx, a, op())
	if err != nil {
		t.Fatalf("baseline info %v", err)
	}
	gate := newSnapshotGate(database)
	service.Timed.Runner.DB = gate
	var attempts = struct{ value int64 }{}
	err = runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE worldboss_players SET attempts=99 WHERE player_id=$1`, int64(a.PlayerID))
		},
		func(c context.Context) error {
			body, readErr := service.Info(c, a, op())
			attempts.value = body["challenge_times"].(int64)
			return readErr
		})
	if err != nil {
		t.Fatalf("624 read: %v", err)
	}
	if attempts.value != before["challenge_times"].(int64) {
		t.Fatalf("624 saw the concurrent attempt write: %d", attempts.value)
	}
}
