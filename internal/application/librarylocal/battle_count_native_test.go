//go:build postgres

package librarylocal_test

import (
	"context"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterbirth"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/nativebirth"
	app "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func battleCountPool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_G2A_DSN")
	if dsn == "" {
		t.Skip("GXB_G2A_DSN with a migrated disposable database is required")
	}
	p, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	return p
}

func battleCountPlayer(t *testing.T, p *pg.Pool) identity.PlayerID {
	t.Helper()
	ctx := context.Background()
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	var playerID int64
	if err = tr.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=1 RETURNING next_player_id-1`).Scan(&playerID); err != nil {
		t.Fatal(err)
	}
	if _, err = tr.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, account.String(), account.String()); err != nil {
		t.Fatal(err)
	}
	if _, err = tr.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,clock_timestamp(),'i9-11g2a')`, playerID, account.String()); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	player := identity.PlayerID(playerID)
	if err = nativebirth.PersistBare(ctx, p, account, 1, player); err != nil {
		t.Fatal(err)
	}
	return player
}

func battleCountHero(t *testing.T, p *pg.Pool, player identity.PlayerID, partnerID int64) {
	t.Helper()
	ctx := context.Background()
	revision, err := (contentstore.Store{}).ActiveRevision(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	at := time.Now().UTC().Add(-time.Minute)
	hero := character.Hero{PlayerID: player, PartnerID: partnerID, TableID: 10001001, OriginTableID: 10001001, Star: 1, Level: 1, Color: 1,
		CreationContentRevision: revision, RawSkills: character.NewHeroRawSkillSeed(), IllusionSkinID: character.DefaultIllusionSkinID,
		StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	if err = (characterstore.Store{}).InsertHeroTx(ctx, tr, hero); err != nil {
		t.Fatal(err)
	}
	if err = characterbirth.FreshHeroFacets().InitFreshHeroTx(ctx, tr, hero.Ref(), at); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func battleCountService() app.Service {
	return app.Service{Library: librarystore.Store{}, Heroes: characterstore.LibraryHeroPort{Store: characterstore.Store{}}}
}

func observeBattle(t *testing.T, p *pg.Pool, player identity.PlayerID, partnerIDs []int64) {
	t.Helper()
	ctx := context.Background()
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if err = battleCountService().ObserveBattleTx(ctx, tr, player, partnerIDs, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func battleCountValue(t *testing.T, p *pg.Pool, player identity.PlayerID, partnerID int64) (int64, bool) {
	t.Helper()
	var count int64
	err := p.Raw().QueryRow(context.Background(), `SELECT count FROM library_hero_battle_counts WHERE player_id=$1 AND partner_id=$2`, int64(player), partnerID).Scan(&count)
	if err != nil {
		return 0, false
	}
	return count, true
}

func battleCountLogRows(t *testing.T, p *pg.Pool, player identity.PlayerID, partnerID int64) map[int64]int64 {
	t.Helper()
	rows, err := p.Raw().Query(context.Background(), `SELECT log_id,count(*) FROM player_library_hero_logs WHERE player_id=$1 AND partner_id=$2 GROUP BY log_id`, int64(player), partnerID)
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	out := map[int64]int64{}
	for rows.Next() {
		var logID, count int64
		if err = rows.Scan(&logID, &count); err != nil {
			t.Fatal(err)
		}
		out[logID] = count
	}
	if err = rows.Err(); err != nil {
		t.Fatal(err)
	}
	return out
}

type battleWakeupListener struct {
	messages chan realtimewakeup.Envelope
	failure  chan error
}

func startBattleWakeupListener(t *testing.T, p *pg.Pool) *battleWakeupListener {
	t.Helper()
	ctx := context.Background()
	connection, err := p.Raw().Acquire(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = connection.Exec(ctx, `LISTEN `+pg.RealtimeWakeupChannel); err != nil {
		connection.Release()
		t.Fatal(err)
	}
	listener := &battleWakeupListener{messages: make(chan realtimewakeup.Envelope, 8), failure: make(chan error, 1)}
	listenContext, cancel := context.WithCancel(ctx)
	finished := make(chan struct{})
	t.Cleanup(func() {
		cancel()
		<-finished
		connection.Release()
	})
	go func() {
		defer close(finished)
		for {
			notification, err := connection.Conn().WaitForNotification(listenContext)
			if err != nil {
				select {
				case listener.failure <- err:
				default:
				}
				return
			}
			envelope, err := realtimewakeup.Decode([]byte(notification.Payload))
			if err != nil {
				listener.failure <- err
				return
			}
			select {
			case listener.messages <- envelope:
			case <-listenContext.Done():
				return
			}
		}
	}()
	return listener
}

func (l *battleWakeupListener) expect(t *testing.T, player identity.PlayerID, partnerID int64) {
	t.Helper()
	deadline := time.After(3 * time.Second)
	for {
		select {
		case envelope := <-l.messages:
			if envelope.Route != app.PartnerLogNoticeRoute || envelope.Ref != app.PartnerLogRef(player, partnerID) {
				continue
			}
			return
		case err := <-l.failure:
			t.Fatalf("wakeup listener: %v", err)
		case <-deadline:
			t.Fatalf("no Girls Log wakeup for player %d partner %d", player, partnerID)
		}
	}
}

// TestObserveBattleCountFirstWritesMilestoneAndWakeup covers G2: the first
// settled battle writes log 60001 and wakes the notice-24 projection.
func TestObserveBattleCountFirstWritesMilestoneAndWakeup(t *testing.T) {
	p := battleCountPool(t)
	player := battleCountPlayer(t, p)
	battleCountHero(t, p, player, 1)
	listener := startBattleWakeupListener(t, p)
	observeBattle(t, p, player, []int64{1})
	if count, ok := battleCountValue(t, p, player, 1); !ok || count != 1 {
		t.Fatalf("count=%d present=%v want 1", count, ok)
	}
	if rows := battleCountLogRows(t, p, player, 1); rows[60001] != 1 || len(rows) != 2 {
		t.Fatalf("log rows=%v, want 10001 and one 60001", rows)
	}
	listener.expect(t, player, 1)
}

// TestObserveBattleCountFiftiethWritesMilestoneOnce covers G2: 50 settled
// battles cross 60002 once and further battles do not rewrite it.
func TestObserveBattleCountFiftiethWritesMilestoneOnce(t *testing.T) {
	p := battleCountPool(t)
	player := battleCountPlayer(t, p)
	battleCountHero(t, p, player, 1)
	for index := 0; index < 50; index++ {
		observeBattle(t, p, player, []int64{1})
	}
	observeBattle(t, p, player, []int64{1})
	if count, ok := battleCountValue(t, p, player, 1); !ok || count != 51 {
		t.Fatalf("count=%d present=%v want 51", count, ok)
	}
	rows := battleCountLogRows(t, p, player, 1)
	if rows[60001] != 1 || rows[60002] != 1 || len(rows) != 3 {
		t.Fatalf("log rows=%v, want 10001, one 60001 and one 60002", rows)
	}
}

// TestObserveBattleCountDuplicateAndNonOwnedIds covers G2: a duplicate id in
// one call counts once and a non-owned id is skipped.
func TestObserveBattleCountDuplicateAndNonOwnedIds(t *testing.T) {
	p := battleCountPool(t)
	player := battleCountPlayer(t, p)
	battleCountHero(t, p, player, 1)
	observeBattle(t, p, player, []int64{1, 1, 2})
	if count, ok := battleCountValue(t, p, player, 1); !ok || count != 1 {
		t.Fatalf("owned count=%d present=%v want 1", count, ok)
	}
	if count, ok := battleCountValue(t, p, player, 2); ok {
		t.Fatalf("non-owned id was counted: %d", count)
	}
	if rows := battleCountLogRows(t, p, player, 2); len(rows) != 0 {
		t.Fatalf("non-owned id wrote log rows: %v", rows)
	}
}

// TestObserveBattleCountConcurrentSettlements covers G2: two concurrent
// settlement transactions end at the exact count.
func TestObserveBattleCountConcurrentSettlements(t *testing.T) {
	p := battleCountPool(t)
	player := battleCountPlayer(t, p)
	battleCountHero(t, p, player, 1)
	errors := make(chan error, 2)
	for index := 0; index < 2; index++ {
		go func() {
			ctx := context.Background()
			tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
			if err != nil {
				errors <- err
				return
			}
			defer tr.Rollback(ctx)
			if err = battleCountService().ObserveBattleTx(ctx, tr, player, []int64{1}, time.Now().UTC()); err != nil {
				errors <- err
				return
			}
			errors <- tr.Commit(ctx)
		}()
	}
	for index := 0; index < 2; index++ {
		if err := <-errors; err != nil {
			t.Fatal(err)
		}
	}
	if count, ok := battleCountValue(t, p, player, 1); !ok || count != 2 {
		t.Fatalf("count=%d present=%v want 2", count, ok)
	}
}
