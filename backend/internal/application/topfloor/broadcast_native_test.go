//go:build postgres

package topfloor

import (
	"context"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	app "gxb.local/backend/v2/internal/application/broadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var nativeContext = context.Background()

type nativeBroadcastRow struct {
	Server    int64
	MsgType   int64
	Player    int64
	Enemy     int64
	Rank      int64
	KeepWins  int64
	EnemyName string
}

func nativePool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I7B6A_DSN")
	if dsn == "" {
		t.Fatal("GXB_I7B6A_DSN required")
	}
	p, err := pg.Open(nativeContext, dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	return p
}

func nativePlayer(t *testing.T, p *pg.Pool, server identity.LogicalServerID) identity.PlayerID {
	t.Helper()
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	tr, err := p.Begin(nativeContext, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(nativeContext)
	var playerID int64
	if err = tr.QueryRow(nativeContext, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=$1 RETURNING next_player_id-1`, int64(server)).Scan(&playerID); err != nil {
		t.Fatal(err)
	}
	if _, err = tr.Exec(nativeContext, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, account.String(), account.String()); err != nil {
		t.Fatal(err)
	}
	if _, err = tr.Exec(nativeContext, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,$3,clock_timestamp(),'i9-10-broadcast-native')`, playerID, account.String(), int64(server)); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(nativeContext); err != nil {
		t.Fatal(err)
	}
	return identity.PlayerID(playerID)
}

func nativeTopFloorPlayer(t *testing.T, p *pg.Pool, server identity.LogicalServerID, player identity.PlayerID, revision string, streak int64) {
	t.Helper()
	if _, err := p.Raw().Exec(nativeContext, `INSERT INTO top_floor_ladders(logical_server_id,content_revision,policy_id,size,settled_day,state_version,created_at,updated_at)
		VALUES($1,$2,'C5B_TOP_FLOOR_PRIVATE_POLICY_V1',10325,0,1,clock_timestamp(),clock_timestamp()) ON CONFLICT(logical_server_id) DO NOTHING`, int64(server), revision); err != nil {
		t.Fatal(err)
	}
	if _, err := p.Raw().Exec(nativeContext, `INSERT INTO top_floor_players(player_id,logical_server_id,content_revision,best_rank,ticket_day,tickets_left,purchases,last_match_at,refresh_count,offered_day,offered,defense,defense_pet,defense_set_at,fights,wins,win_streak,state_version,created_at,updated_at)
		VALUES($1,$2,$3,10,0,5,0,NULL,0,0,'[]'::jsonb,'[]'::jsonb,0,NULL,10,10,$4,1,clock_timestamp(),clock_timestamp())`,
		int64(player), int64(server), revision, streak); err != nil {
		t.Fatal(err)
	}
}

func nativeSavePlayer(t *testing.T, p *pg.Pool, player d.Player) {
	t.Helper()
	tr, err := p.Begin(nativeContext, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(nativeContext)
	if err = (topfloorstore.Store{}).SavePlayerTx(nativeContext, tr, player, player.StateVersion-1); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(nativeContext); err != nil {
		t.Fatal(err)
	}
}

func nativeEmit(t *testing.T, p *pg.Pool, messages []app.Message) {
	t.Helper()
	tr, err := p.Begin(nativeContext, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(nativeContext)
	for _, message := range messages {
		if err = (pg.BroadcastEmitter{}).EmitTx(nativeContext, tr, message); err != nil {
			t.Fatal(err)
		}
	}
	if err = tr.Commit(nativeContext); err != nil {
		t.Fatal(err)
	}
}

func nativeOutbox(t *testing.T, p *pg.Pool, player identity.PlayerID) []nativeBroadcastRow {
	t.Helper()
	rows, err := p.Raw().Query(nativeContext, `SELECT logical_server_id,msg_type,player_id,COALESCE(enemy_player_id,0),COALESCE((fields->>'rank')::bigint,0),COALESCE((fields->>'keep_win_times')::bigint,0),COALESCE(fields->>'enemy_name','') FROM broadcast_outbox WHERE player_id=$1 ORDER BY broadcast_id`, int64(player))
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	out := []nativeBroadcastRow{}
	for rows.Next() {
		var row nativeBroadcastRow
		if err = rows.Scan(&row.Server, &row.MsgType, &row.Player, &row.Enemy, &row.Rank, &row.KeepWins, &row.EnemyName); err != nil {
			t.Fatal(err)
		}
		out = append(out, row)
	}
	if err = rows.Err(); err != nil {
		t.Fatal(err)
	}
	return out
}

// TestI9_10TopFloorSettlementBroadcastNative proves the 3003 and 3002 producers
// against the real outbox: strict top-three entry announces once, a streak
// announces only at its milestone, and an attack loss resets the stored streak.
func TestI9_10TopFloorSettlementBroadcastNative(t *testing.T) {
	p := nativePool(t)
	server := identity.LogicalServerID(1)
	var revision string
	if err := p.QueryRow(nativeContext, `SELECT revision_id FROM gxb_content_revisions LIMIT 1`).Scan(&revision); err != nil {
		t.Fatal(err)
	}
	challenger := nativePlayer(t, p, server)
	defender := nativePlayer(t, p, server)
	nativeTopFloorPlayer(t, p, server, challenger, revision, 4)
	store := topfloorstore.Store{}
	catalog := d.Catalog{FirstNames: []string{"Robot"}, LastNames: []string{"Name"}}
	robotFight := d.Fight{Server: server, Challenger: challenger, Defender: d.Occupant{Robot: 7}}

	player, found, err := store.ReadPlayerTx(nativeContext, p, challenger, false)
	if err != nil || !found || player.WinStreak != 4 {
		t.Fatalf("seeded streak=%d found=%v err=%v", player.WinStreak, found, err)
	}
	player.WinStreak = nextWinStreak(player.WinStreak, true, true)
	player.StateVersion++
	player.UpdatedAt = time.Now().UTC()
	nativeSavePlayer(t, p, player)
	nativeEmit(t, p, settlementMessages(catalog, robotFight, d.Outcome{Win: true, ChallengerBefore: 8, ChallengerAfter: 8}, player.WinStreak))
	rows := nativeOutbox(t, p, challenger)
	if len(rows) != 1 || rows[0].MsgType != app.ArenaWins || rows[0].KeepWins != 5 || rows[0].Server != int64(server) || rows[0].Player != int64(challenger) {
		t.Fatalf("milestone 5 rows=%+v", rows)
	}

	player, found, err = store.ReadPlayerTx(nativeContext, p, challenger, false)
	if err != nil || !found || player.WinStreak != 5 {
		t.Fatalf("stored streak after win=%d found=%v err=%v", player.WinStreak, found, err)
	}
	player.WinStreak = nextWinStreak(player.WinStreak, true, true)
	player.StateVersion++
	player.UpdatedAt = time.Now().UTC()
	nativeSavePlayer(t, p, player)
	nativeEmit(t, p, settlementMessages(catalog, robotFight, d.Outcome{Win: true, ChallengerBefore: 8, ChallengerAfter: 8}, player.WinStreak))
	if rows = nativeOutbox(t, p, challenger); len(rows) != 1 {
		t.Fatalf("streak 6 announced: %+v", rows)
	}

	player, found, err = store.ReadPlayerTx(nativeContext, p, challenger, false)
	if err != nil || !found || player.WinStreak != 6 {
		t.Fatalf("stored streak after second win=%d found=%v err=%v", player.WinStreak, found, err)
	}
	player.WinStreak = nextWinStreak(player.WinStreak, true, false)
	player.StateVersion++
	player.UpdatedAt = time.Now().UTC()
	nativeSavePlayer(t, p, player)
	nativeEmit(t, p, settlementMessages(catalog, robotFight, d.Outcome{Win: false, ChallengerBefore: 8, ChallengerAfter: 8}, player.WinStreak))
	if rows = nativeOutbox(t, p, challenger); len(rows) != 1 {
		t.Fatalf("loss announced: %+v", rows)
	}
	stored, found, err := store.ReadPlayerTx(nativeContext, p, challenger, false)
	if err != nil || !found || stored.WinStreak != 0 {
		t.Fatalf("loss did not reset stored streak: %d found=%v err=%v", stored.WinStreak, found, err)
	}

	topThree := d.Outcome{Win: true, ChallengerBefore: 5, ChallengerAfter: 3, BestAfter: 3}
	nativeEmit(t, p, settlementMessages(catalog, robotFight, topThree, 0))
	rows = nativeOutbox(t, p, challenger)
	if len(rows) != 2 || rows[1].MsgType != app.ArenaTop3 || rows[1].Rank != 3 || rows[1].EnemyName != catalog.RobotName(7) || rows[1].Enemy != 0 {
		t.Fatalf("top three rows=%+v", rows)
	}

	sameRank := d.Outcome{Win: true, ChallengerBefore: 3, ChallengerAfter: 3, BestAfter: 3}
	nativeEmit(t, p, settlementMessages(catalog, robotFight, sameRank, 0))
	if rows = nativeOutbox(t, p, challenger); len(rows) != 2 {
		t.Fatalf("same-rank win announced: %+v", rows)
	}

	humanFight := d.Fight{Server: server, Challenger: challenger, Defender: d.Occupant{Player: defender}}
	nativeEmit(t, p, settlementMessages(catalog, humanFight, d.Outcome{Win: true, ChallengerBefore: 6, ChallengerAfter: 2, BestAfter: 2}, 0))
	rows = nativeOutbox(t, p, challenger)
	if len(rows) != 3 || rows[2].MsgType != app.ArenaTop3 || rows[2].Enemy != int64(defender) || rows[2].EnemyName != "" {
		t.Fatalf("human top three rows=%+v", rows)
	}
}
