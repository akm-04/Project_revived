//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/illusionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/oneononestore"
	"gxb.local/backend/v2/internal/adapters/postgres/summonstore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	"gxb.local/backend/v2/internal/adapters/postgres/worldbossstore"
	apparena "gxb.local/backend/v2/internal/application/arena"
	appdorm "gxb.local/backend/v2/internal/application/dormhouse"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	appillusion "gxb.local/backend/v2/internal/application/illusion"
	apponeonone "gxb.local/backend/v2/internal/application/oneonone"
	appsummon "gxb.local/backend/v2/internal/application/summon"
	apptopfloor "gxb.local/backend/v2/internal/application/topfloor"
	appworldboss "gxb.local/backend/v2/internal/application/worldboss"
	ar "gxb.local/backend/v2/internal/domain/arena"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	oo "gxb.local/backend/v2/internal/domain/oneonone"
	tf "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func m12bAdmin() i5.AdminOperator {
	return i5.AdminOperator{ID: "m12b-native", ReasonCode: "M12b native reset"}
}

func m12bTimed(p *pg.Pool) gen.TimedRunner {
	return gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}
}

func m12bTopFloorService(p *pg.Pool) apptopfloor.Service {
	return apptopfloor.Service{Timed: m12bTimed(p), Store: topfloorstore.Store{}, Content: contentstore.Store{Queryer: p}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func m12bOneOnOneService(p *pg.Pool) apponeonone.Service {
	return apponeonone.Service{Timed: m12bTimed(p), Store: oneononestore.Store{}, Content: contentstore.Store{Queryer: p}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func m12bWorldBossService(p *pg.Pool) appworldboss.Mode {
	return appworldboss.Mode{Timed: m12bTimed(p), Store: worldbossstore.Store{}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func m12bIllusionService(p *pg.Pool) appillusion.Mode {
	return appillusion.Mode{Timed: m12bTimed(p), Store: illusionstore.Store{}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func m12bDormGlueService(p *pg.Pool) appdorm.Service {
	return appdorm.Service{Timed: m12bTimed(p), GluePurchases: dormstore.Store{}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func m12bArenaService(p *pg.Pool) apparena.Service {
	return apparena.Service{Timed: m12bTimed(p), Store: arenastore.Store{}, Content: contentstore.Store{Queryer: p}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func m12bSummonService(p *pg.Pool) appsummon.Mode {
	return appsummon.Mode{Timed: m12bTimed(p), Store: summonstore.Store{}, Content: contentstore.Store{Queryer: p}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func m12bSeedTopFloor(t *testing.T, p *pg.Pool, player identity.PlayerID, revision string, at time.Time) tf.Catalog {
	t.Helper()
	exec(t, p, `INSERT INTO top_floor_ladders(logical_server_id,content_revision,policy_id,size,settled_day,state_version,created_at,updated_at) VALUES(1,$1,'C5B_TOP_FLOOR_PRIVATE_POLICY_V1',10325,0,1,$2,$2) ON CONFLICT (logical_server_id) DO NOTHING`, revision, at)
	catalog, err := (contentstore.Store{}).TopFloorCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal(err)
	}
	seed := catalog.NewPlayer(player, 1, revision, 10326, at)
	seed.TicketsLeft, seed.Purchases = 0, 1
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if err = (topfloorstore.Store{}).InsertPlayerTx(ctx, transaction, seed); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	return catalog
}

func m12bSeedOneOnOne(t *testing.T, p *pg.Pool, player identity.PlayerID, revision string, at time.Time) oo.Catalog {
	t.Helper()
	exec(t, p, `INSERT INTO one_on_one_competitions(competition_id,content_revision,policy_id,master_count,senior_count,settled_through,opened_through,closed_through,state_version,created_at,updated_at) VALUES('GLOBAL',$1,'C5C_ONE_ON_ONE_PRIVATE_POLICY_V1',0,0,0,0,0,1,$2,$2) ON CONFLICT (competition_id) DO NOTHING`, revision, at)
	catalog, err := (contentstore.Store{}).OneOnOneCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal(err)
	}
	seed := catalog.NewPlayer(player, 1, revision, at)
	seed.TriesLeft, seed.Purchases = 0, 1
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if err = (oneononestore.Store{}).InsertPlayerTx(ctx, transaction, seed); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	return catalog
}

func m12bSeedArena(t *testing.T, p *pg.Pool, player identity.PlayerID, revision string, at time.Time) ar.Catalog {
	t.Helper()
	exec(t, p, `INSERT INTO arena_competitions(competition_id,content_revision,policy_id,settled_through,state_version,created_at,updated_at) VALUES('GLOBAL',$1,'C5D_ARENA_PRIVATE_POLICY_V1',0,1,$2,$2) ON CONFLICT (competition_id) DO NOTHING`, revision, at)
	catalog, err := (contentstore.Store{}).ArenaCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal(err)
	}
	seed := ar.NewPlayer(catalog, player, 1, at)
	seed.DailyFights = 5
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if err = (arenastore.Store{}).InsertPlayerTx(ctx, transaction, seed, revision); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	return catalog
}

func TestI11A_M12BTopFloorResetNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	service := m12bTopFloorService(p)
	a := bornActor(t, p)
	at := m12aDatabaseNow(t, p)
	catalog := m12bSeedTopFloor(t, p, a.PlayerID, revision, at)

	if err := service.ResetOperatorTopFloor(ctx, m12bAdmin(), a.PlayerID, "top-floor:1", op()); err != nil {
		t.Fatal(err)
	}
	player, found, err := (topfloorstore.Store{}).ReadPlayerTx(ctx, p, a.PlayerID, false)
	if err != nil || !found {
		t.Fatalf("top floor row: found=%v err=%v", found, err)
	}
	if player.TicketsLeft != catalog.FreeTickets || player.Purchases != 0 {
		t.Fatalf("top floor after reset = tickets %d purchases %d", player.TicketsLeft, player.Purchases)
	}

	exec(t, p, `UPDATE top_floor_players SET tickets_left=0,purchases=1,state_version=state_version+1,updated_at=$2 WHERE player_id=$1`, int64(a.PlayerID), m12aDatabaseNow(t, p))
	if err = service.ResetOperatorTopFloor(ctx, m12bAdmin(), a.PlayerID, "top-floor:1", op()); err != nil {
		t.Fatal(err)
	}
	player, _, err = (topfloorstore.Store{}).ReadPlayerTx(ctx, p, a.PlayerID, false)
	if err != nil {
		t.Fatal(err)
	}
	if player.TicketsLeft != 0 || player.Purchases != 1 {
		t.Fatalf("a replayed key reset new use: tickets %d purchases %d", player.TicketsLeft, player.Purchases)
	}

	missing := bornActor(t, p)
	if err = service.ResetOperatorTopFloor(ctx, m12bAdmin(), missing.PlayerID, "top-floor:2", op()); err != nil {
		t.Fatal(err)
	}
	var rows int
	if err = p.Raw().QueryRow(ctx, `SELECT count(*) FROM top_floor_players WHERE player_id=$1`, int64(missing.PlayerID)).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Fatalf("missing top floor row was created: %d", rows)
	}
}

func TestI11A_M12BOneOnOneResetNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	service := m12bOneOnOneService(p)
	a := bornActor(t, p)
	at := m12aDatabaseNow(t, p)
	catalog := m12bSeedOneOnOne(t, p, a.PlayerID, revision, at)

	if err := service.ResetOperatorOneOnOne(ctx, m12bAdmin(), a.PlayerID, "one-on-one:1", op()); err != nil {
		t.Fatal(err)
	}
	player, _, found, err := (oneononestore.Store{}).ReadPlayerTx(ctx, p, a.PlayerID, false)
	if err != nil || !found {
		t.Fatalf("one on one row: found=%v err=%v", found, err)
	}
	if player.TriesLeft != catalog.FreeTries || player.Purchases != 0 {
		t.Fatalf("one on one after reset = tries %d purchases %d", player.TriesLeft, player.Purchases)
	}

	exec(t, p, `UPDATE one_on_one_players SET tries_left=0,purchases=1,state_version=state_version+1,updated_at=$2 WHERE player_id=$1`, int64(a.PlayerID), m12aDatabaseNow(t, p))
	if err = service.ResetOperatorOneOnOne(ctx, m12bAdmin(), a.PlayerID, "one-on-one:1", op()); err != nil {
		t.Fatal(err)
	}
	player, _, _, err = (oneononestore.Store{}).ReadPlayerTx(ctx, p, a.PlayerID, false)
	if err != nil {
		t.Fatal(err)
	}
	if player.TriesLeft != 0 || player.Purchases != 1 {
		t.Fatalf("a replayed key reset new use: tries %d purchases %d", player.TriesLeft, player.Purchases)
	}

	missing := bornActor(t, p)
	if err = service.ResetOperatorOneOnOne(ctx, m12bAdmin(), missing.PlayerID, "one-on-one:2", op()); err != nil {
		t.Fatal(err)
	}
	var rows int
	if err = p.Raw().QueryRow(ctx, `SELECT count(*) FROM one_on_one_players WHERE player_id=$1`, int64(missing.PlayerID)).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Fatalf("missing one on one row was created: %d", rows)
	}
}

func TestI11A_M12BWorldBossResetNative(t *testing.T) {
	p := pool(t)
	service := m12bWorldBossService(p)
	a := bornActor(t, p)
	at := m12aDatabaseNow(t, p)
	day := modes.Day(at)
	exec(t, p, `INSERT INTO worldboss_players(player_id,logical_server_id,challenged_day,day,attempts,bought,swept_day,best_hit,best_hit_at,updated_at) VALUES($1,1,0,$2,0,3,0,0,0,$3)`, int64(a.PlayerID), day, at)

	if err := service.ResetOperatorWorldBoss(ctx, m12bAdmin(), a.PlayerID, "world-boss:1", op()); err != nil {
		t.Fatal(err)
	}
	player, found, err := (worldbossstore.Store{}).ReadPlayerTx(ctx, p, a.PlayerID)
	if err != nil || !found {
		t.Fatalf("world boss row: found=%v err=%v", found, err)
	}
	if player.Day != day || player.Bought != 0 || player.Attempts != 5 {
		t.Fatalf("world boss after reset = %+v", player)
	}

	exec(t, p, `UPDATE worldboss_players SET day=$2,attempts=1,bought=2,updated_at=$3 WHERE player_id=$1`, int64(a.PlayerID), day, m12aDatabaseNow(t, p))
	if err = service.ResetOperatorWorldBoss(ctx, m12bAdmin(), a.PlayerID, "world-boss:1", op()); err != nil {
		t.Fatal(err)
	}
	player, _, err = (worldbossstore.Store{}).ReadPlayerTx(ctx, p, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	if player.Bought != 2 || player.Attempts != 1 {
		t.Fatalf("a replayed key reset new use: %+v", player)
	}

	missing := bornActor(t, p)
	if err = service.ResetOperatorWorldBoss(ctx, m12bAdmin(), missing.PlayerID, "world-boss:2", op()); err != nil {
		t.Fatal(err)
	}
	var rows int
	if err = p.Raw().QueryRow(ctx, `SELECT count(*) FROM worldboss_players WHERE player_id=$1`, int64(missing.PlayerID)).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Fatalf("missing world boss row was created: %d", rows)
	}
}

func TestI11A_M12BIllusionResetNative(t *testing.T) {
	p := pool(t)
	service := m12bIllusionService(p)
	a := bornActor(t, p)
	at := m12aDatabaseNow(t, p)
	day := modes.Day(at)
	exec(t, p, `INSERT INTO illusion_players(player_id,logical_server_id,day,chances,bought,best_hit,best_time,updated_at) VALUES($1,1,$2,0,2,100,7,$3)`, int64(a.PlayerID), day, at)

	if err := service.ResetOperatorIllusion(ctx, m12bAdmin(), a.PlayerID, "illusion:1", op()); err != nil {
		t.Fatal(err)
	}
	player, found, err := (illusionstore.Store{}).ReadPlayerTx(ctx, p, a.PlayerID)
	if err != nil || !found {
		t.Fatalf("illusion row: found=%v err=%v", found, err)
	}
	if player.Day != day || player.Chances != 5 || player.Bought != 0 || player.BestHit != 0 {
		t.Fatalf("illusion after reset = %+v", player)
	}

	exec(t, p, `UPDATE illusion_players SET day=$2,chances=1,bought=1,updated_at=$3 WHERE player_id=$1`, int64(a.PlayerID), day, m12aDatabaseNow(t, p))
	if err = service.ResetOperatorIllusion(ctx, m12bAdmin(), a.PlayerID, "illusion:1", op()); err != nil {
		t.Fatal(err)
	}
	player, _, err = (illusionstore.Store{}).ReadPlayerTx(ctx, p, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	if player.Chances != 1 || player.Bought != 1 {
		t.Fatalf("a replayed key reset new use: %+v", player)
	}

	missing := bornActor(t, p)
	if err = service.ResetOperatorIllusion(ctx, m12bAdmin(), missing.PlayerID, "illusion:2", op()); err != nil {
		t.Fatal(err)
	}
	var rows int
	if err = p.Raw().QueryRow(ctx, `SELECT count(*) FROM illusion_players WHERE player_id=$1`, int64(missing.PlayerID)).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Fatalf("missing illusion row was created: %d", rows)
	}
}

func TestI11A_M12BDormGlueResetNative(t *testing.T) {
	p := pool(t)
	service := m12bDormGlueService(p)
	a := bornActor(t, p)
	at := m12aDatabaseNow(t, p)
	day := modes.Day(at)
	exec(t, p, `INSERT INTO player_dorm_roots(player_id,next_house_id,state_version,created_at,updated_at) VALUES($1,2,1,$2,$2) ON CONFLICT (player_id) DO NOTHING`, int64(a.PlayerID), at)
	exec(t, p, `INSERT INTO player_dorm_glue_purchases(player_id,game_day,purchase_count,state_version,updated_at) VALUES($1,$2,3,1,$3)`, int64(a.PlayerID), day, at)

	if err := service.ResetOperatorDormGlue(ctx, m12bAdmin(), a.PlayerID, "dorm-glue:1", op()); err != nil {
		t.Fatal(err)
	}
	stored, found, err := (dormstore.Store{}).ReadGluePurchasesTx(ctx, p, a.PlayerID)
	if err != nil || !found {
		t.Fatalf("glue row: found=%v err=%v", found, err)
	}
	count, err := dorm.EffectiveGluePurchaseCount(&stored, a.PlayerID, day, at)
	if err != nil {
		t.Fatal(err)
	}
	if count != 0 || stored.StateVersion != 2 {
		t.Fatalf("glue after reset = count %d version %d", count, stored.StateVersion)
	}

	exec(t, p, `UPDATE player_dorm_glue_purchases SET game_day=$2,purchase_count=1,state_version=state_version+1,updated_at=$3 WHERE player_id=$1`, int64(a.PlayerID), day, m12aDatabaseNow(t, p))
	if err = service.ResetOperatorDormGlue(ctx, m12bAdmin(), a.PlayerID, "dorm-glue:1", op()); err != nil {
		t.Fatal(err)
	}
	stored, _, err = (dormstore.Store{}).ReadGluePurchasesTx(ctx, p, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	if stored.GameDay != day || stored.Count != 1 {
		t.Fatalf("a replayed key reset new use: %+v", stored)
	}

	missing := bornActor(t, p)
	if err = service.ResetOperatorDormGlue(ctx, m12bAdmin(), missing.PlayerID, "dorm-glue:2", op()); err != nil {
		t.Fatal(err)
	}
	var rows int
	if err = p.Raw().QueryRow(ctx, `SELECT count(*) FROM player_dorm_glue_purchases WHERE player_id=$1`, int64(missing.PlayerID)).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Fatalf("missing glue row was created: %d", rows)
	}
}

func TestI11A_M12BArenaDailyResetNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	service := m12bArenaService(p)
	a := bornActor(t, p)
	at := m12aDatabaseNow(t, p)
	m12bSeedArena(t, p, a.PlayerID, revision, at)

	if err := service.ResetOperatorArenaDaily(ctx, m12bAdmin(), a.PlayerID, "arena-daily:1", op()); err != nil {
		t.Fatal(err)
	}
	player, found, err := (arenastore.Store{}).ReadPlayerTx(ctx, p, a.PlayerID, false)
	if err != nil || !found {
		t.Fatalf("arena row: found=%v err=%v", found, err)
	}
	if player.DailyFights != 0 {
		t.Fatalf("arena after reset = fights %d", player.DailyFights)
	}

	exec(t, p, `UPDATE arena_players SET daily_fights=3,state_version=state_version+1,updated_at=$2 WHERE player_id=$1`, int64(a.PlayerID), m12aDatabaseNow(t, p))
	if err = service.ResetOperatorArenaDaily(ctx, m12bAdmin(), a.PlayerID, "arena-daily:1", op()); err != nil {
		t.Fatal(err)
	}
	player, _, err = (arenastore.Store{}).ReadPlayerTx(ctx, p, a.PlayerID, false)
	if err != nil {
		t.Fatal(err)
	}
	if player.DailyFights != 3 {
		t.Fatalf("a replayed key reset new use: fights %d", player.DailyFights)
	}

	missing := bornActor(t, p)
	if err = service.ResetOperatorArenaDaily(ctx, m12bAdmin(), missing.PlayerID, "arena-daily:2", op()); err != nil {
		t.Fatal(err)
	}
	var rows int
	if err = p.Raw().QueryRow(ctx, `SELECT count(*) FROM arena_players WHERE player_id=$1`, int64(missing.PlayerID)).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Fatalf("missing arena row was created: %d", rows)
	}
}

func TestI11A_M12BSummonFreeResetNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	service := m12bSummonService(p)
	a := bornActor(t, p)
	at := m12aDatabaseNow(t, p)
	day := modes.Day(at)
	catalog, err := (contentstore.Store{}).SummonCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal(err)
	}
	exec(t, p, `INSERT INTO summon_players(player_id,mana_free_time,mana_free_num,mana_free_day,crystal_free_time,counters,featured_target,featured_pity,sx_target,sx_pity,magic_target,state_version,updated_at) VALUES($1,1234,0,$2,4321,'{}'::jsonb,0,0,0,0,0,1,$3)`, int64(a.PlayerID), day, at)

	if err = service.ResetOperatorSummonFree(ctx, m12bAdmin(), a.PlayerID, "summon-free:1", op()); err != nil {
		t.Fatal(err)
	}
	state, found, err := (summonstore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if err != nil || !found {
		t.Fatalf("summon row: found=%v err=%v", found, err)
	}
	if state.ManaFreeDay != day || state.ManaFreeNum != catalog.Free.ManaNum || state.CrystalFreeTime != 0 || state.ManaFreeTime != 1234 {
		t.Fatalf("summon after reset = %+v", state)
	}

	exec(t, p, `UPDATE summon_players SET mana_free_num=0,crystal_free_time=999,state_version=state_version+1,updated_at=$2 WHERE player_id=$1`, int64(a.PlayerID), m12aDatabaseNow(t, p))
	if err = service.ResetOperatorSummonFree(ctx, m12bAdmin(), a.PlayerID, "summon-free:1", op()); err != nil {
		t.Fatal(err)
	}
	state, _, err = (summonstore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	if state.ManaFreeNum != 0 || state.CrystalFreeTime != 999 {
		t.Fatalf("a replayed key reset new use: %+v", state)
	}

	missing := bornActor(t, p)
	if err = service.ResetOperatorSummonFree(ctx, m12bAdmin(), missing.PlayerID, "summon-free:2", op()); err != nil {
		t.Fatal(err)
	}
	var rows int
	if err = p.Raw().QueryRow(ctx, `SELECT count(*) FROM summon_players WHERE player_id=$1`, int64(missing.PlayerID)).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Fatalf("missing summon row was created: %d", rows)
	}
}
