//go:build postgres

package rankingstore_test

import (
	"context"
	"encoding/binary"
	"os"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/rankingstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var r7Ctx = context.Background()

func r7Pool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_R7_RANKING_DSN")
	if dsn == "" {
		t.Skip("GXB_R7_RANKING_DSN required")
	}
	p, e := pg.Open(r7Ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second})
	if e != nil {
		t.Fatal(e)
	}
	t.Cleanup(p.Close)
	return p
}

func r7Server(t *testing.T, p *pg.Pool) identity.LogicalServerID {
	t.Helper()
	for i := 0; i < 20; i++ {
		u, e := ids.NewUUID()
		if e != nil {
			t.Fatal(e)
		}
		b := u.Bytes()
		server := int64(1000 + int(binary.BigEndian.Uint16(b[:2])))
		tag, e := p.Raw().Exec(r7Ctx, `INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)VALUES($1,'R7 ranking native',clock_timestamp(),true,true,true,$2,$3,1,clock_timestamp())ON CONFLICT DO NOTHING`, server, server*100000+25001, (server+1)*100000-1)
		if e != nil {
			t.Fatal(e)
		}
		if tag.RowsAffected() == 1 {
			return identity.LogicalServerID(server)
		}
	}
	t.Fatal("no isolated native server")
	return 0
}

func r7Player(t *testing.T, p *pg.Pool, server identity.LogicalServerID, ordinal int64, name string) identity.PlayerID {
	t.Helper()
	account, e := ids.NewUUID()
	if e != nil {
		t.Fatal(e)
	}
	pid := int64(server)*100000 + ordinal
	for _, row := range []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, []any{account.String(), account.String()}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,$3,clock_timestamp(),'r7-ranking-native')`, []any{pid, account.String(), int64(server)}},
		{`INSERT INTO player_directory_profiles(player_id,name,lev,avatar_id,avatar_frame_id,vip,conquer_lev,state_version,created_at,updated_at)VALUES($1,$2,42,110001001,0,0,0,1,clock_timestamp(),clock_timestamp())`, []any{pid, name}},
	} {
		if _, e = p.Raw().Exec(r7Ctx, row.sql, row.args...); e != nil {
			t.Fatal(e)
		}
	}
	return identity.PlayerID(pid)
}

func r7Row(server identity.LogicalServerID, player identity.PlayerID, score int64, at, since time.Time) d.ScoreRow {
	return d.ScoreRow{
		Policy:     d.GirlsBoard.Policy,
		Server:     server,
		Player:     player,
		Score:      score,
		ScoreSince: since,
		Revision:   strings.Repeat("a", 64),
		Metric:     d.BoardMetric{Player: player, Owner: d.GirlsBoard.SourceOwner, Policy: d.GirlsBoard.SourcePolicy, Semantics: d.GirlsBoard.SourceSemantics, Revision: strings.Repeat("a", 64), PopulationDigest: strings.Repeat("b", 64), FieldID: d.GirlsBoard.FieldID, Value: score, SourceVersion: 1, PopulationVersion: 1, ObservedAt: at},
		UpdatedAt:  at,
	}
}

func r7Write(t *testing.T, p *pg.Pool, rows ...d.ScoreRow) {
	t.Helper()
	tr, e := p.Begin(r7Ctx, tx.Options{Isolation: tx.ReadCommitted})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(r7Ctx)
	for _, row := range rows {
		if e = (rankingstore.Store{}).UpsertScoreRowTx(r7Ctx, tr, row); e != nil {
			t.Fatal(e)
		}
	}
	if e = tr.Commit(r7Ctx); e != nil {
		t.Fatal(e)
	}
}

func TestR7ScoreRowRoundTripAndDelete(t *testing.T) {
	p := r7Pool(t)
	server := r7Server(t, p)
	player := r7Player(t, p, server, 1, "Roundtrip")
	at := time.Date(2026, 11, 1, 12, 0, 0, 0, time.UTC)
	store := rankingstore.Store{}
	r7Write(t, p, r7Row(server, player, 7, at, at.Add(-time.Hour)))
	got, ok, e := store.ReadScoreRowTx(r7Ctx, p, d.GirlsBoard.Policy, player)
	if e != nil || !ok || got.Score != 7 || got.Player != player || got.Server != server || !got.ScoreSince.Equal(at.Add(-time.Hour)) || !got.UpdatedAt.Equal(at) || got.Metric.Value != 7 {
		t.Fatal(got, ok, e)
	}
	later := at.Add(time.Hour)
	r7Write(t, p, r7Row(server, player, 9, later, later))
	got, ok, e = store.ReadScoreRowTx(r7Ctx, p, d.GirlsBoard.Policy, player)
	if e != nil || !ok || got.Score != 9 || !got.ScoreSince.Equal(later) {
		t.Fatal("conflict upsert did not replace score", got, ok, e)
	}
	tr, e := p.Begin(r7Ctx, tx.Options{Isolation: tx.ReadCommitted})
	if e != nil {
		t.Fatal(e)
	}
	if e = store.DeleteScoreRowTx(r7Ctx, tr, d.GirlsBoard.Policy, player); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(r7Ctx); e != nil {
		t.Fatal(e)
	}
	if _, ok, e = store.ReadScoreRowTx(r7Ctx, p, d.GirlsBoard.Policy, player); e != nil || ok {
		t.Fatal("deleted row still readable", ok, e)
	}
}

func TestR7ScoreRankCountsRowsOrderedBeforeWithTies(t *testing.T) {
	p := r7Pool(t)
	server := r7Server(t, p)
	at := time.Date(2026, 11, 1, 12, 0, 0, 0, time.UTC)
	first := r7Player(t, p, server, 1, "First")
	second := r7Player(t, p, server, 2, "Second")
	early := r7Player(t, p, server, 3, "Early")
	low := r7Player(t, p, server, 4, "Low")
	top := r7Player(t, p, server, 5, "Top")
	r7Write(t, p, r7Row(server, first, 10, at, at), r7Row(server, second, 10, at, at), r7Row(server, early, 10, at, at.Add(-time.Hour)), r7Row(server, low, 5, at, at), r7Row(server, top, 20, at, at))
	store := rankingstore.Store{}
	for _, want := range []struct {
		player identity.PlayerID
		score  int64
		since  time.Time
		rank   int64
	}{{top, 20, at, 0}, {early, 10, at.Add(-time.Hour), 1}, {first, 10, at, 2}, {second, 10, at, 3}, {low, 5, at, 4}} {
		row := r7Row(server, want.player, want.score, at, want.since)
		got, e := store.ScoreRankTx(r7Ctx, p, d.GirlsBoard.Policy, server, row)
		if e != nil || got != want.rank {
			t.Fatalf("rank of %d = %d, want %d (%v)", want.player, got, want.rank, e)
		}
	}
}

func TestR7TopScoreRowsOrderAndLimit(t *testing.T) {
	p := r7Pool(t)
	server := r7Server(t, p)
	at := time.Date(2026, 11, 1, 12, 0, 0, 0, time.UTC)
	rows := make([]d.ScoreRow, 0, 30)
	for n := int64(1); n <= 30; n++ {
		player := r7Player(t, p, server, n, "Tied")
		rows = append(rows, r7Row(server, player, 100, at, at))
	}
	r7Write(t, p, rows...)
	store := rankingstore.Store{}
	top, e := store.TopScoreRowsTx(r7Ctx, p, d.GirlsBoard.Policy, server, 10)
	if e != nil || len(top) != 10 {
		t.Fatal(len(top), e)
	}
	for i, row := range top {
		want := identity.PlayerID(int64(server)*100000 + int64(i+1))
		if row.Player != want {
			t.Fatalf("top[%d] = %d, want %d", i, row.Player, want)
		}
	}
	all, e := store.AllScoreRowsTx(r7Ctx, p, d.GirlsBoard.Policy, server)
	if e != nil || len(all) != 30 || all[29].Player != identity.PlayerID(int64(server)*100000+30) {
		t.Fatal("all rows", len(all), e)
	}
}

func TestR7ScoreRowRejectsUnknownPlayer(t *testing.T) {
	p := r7Pool(t)
	server := r7Server(t, p)
	at := time.Date(2026, 11, 1, 12, 0, 0, 0, time.UTC)
	unknown := identity.PlayerID(int64(server)*100000 + 999)
	tr, e := p.Begin(r7Ctx, tx.Options{Isolation: tx.ReadCommitted})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(r7Ctx)
	if e = (rankingstore.Store{}).UpsertScoreRowTx(r7Ctx, tr, r7Row(server, unknown, 1, at, at)); e == nil {
		t.Fatal("foreign key accepted an unknown player")
	}
}

func TestR7ProfilesTxReturnsPresentPlayersOnly(t *testing.T) {
	p := r7Pool(t)
	server := r7Server(t, p)
	first := r7Player(t, p, server, 1, "Alpha")
	second := r7Player(t, p, server, 2, "Beta")
	third := r7Player(t, p, server, 3, "Gamma")
	missing := identity.PlayerID(int64(server)*100000 + 998)
	profiles, e := (i4store.PlayerDirectoryReader{}).ProfilesTx(r7Ctx, p, []identity.PlayerID{first, second, third, missing})
	if e != nil || len(profiles) != 3 || profiles[first].Name != "Alpha" || profiles[second].Name != "Beta" || profiles[third].Name != "Gamma" || profiles[third].Level != 42 {
		t.Fatal(profiles, e)
	}
	if _, ok := profiles[missing]; ok {
		t.Fatal("missing player fabricated a profile")
	}
}
