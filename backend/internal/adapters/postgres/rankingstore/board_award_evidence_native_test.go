//go:build postgres

package rankingstore_test

import (
	"context"
	"os"
	"reflect"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/rankingstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	awardServer   = identity.LogicalServerID(11)
	awardPlayer   = identity.PlayerID(1100001)
	awardOther    = identity.PlayerID(1100002)
	awardAbsent   = identity.PlayerID(1100003)
	awardRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
)

type rankingAwardFixture struct {
	transaction tx.Tx
}

func newRankingAwardFixture(t *testing.T) *rankingAwardFixture {
	t.Helper()
	dsn := os.Getenv("GXB_R8_MANIFEST_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_MANIFEST_DSN required")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = transaction.Rollback(ctx) })
	if _, err := transaction.Exec(ctx, `INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES(11,'award-evidence-probe',NULL,false,false,false,1125001,1199999,1,now()) ON CONFLICT DO NOTHING`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO gxb_content_revisions(revision_id,content_sha256,schema_version,compiler_version,parser_version,manifest)
VALUES($1,decode($1,'hex'),1,'probe','probe',jsonb_build_object('revision_id',$1,'schema_version',1,'compiler_version','probe','parser_version','probe')) ON CONFLICT DO NOTHING`, awardRevision); err != nil {
		t.Fatal(err)
	}
	for _, pid := range []identity.PlayerID{awardPlayer, awardOther} {
		account, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',now())`, account.String(), account.String()); err != nil {
			t.Fatal(err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,11,now(),'award-evidence-native')`, int64(pid), account.String()); err != nil {
			t.Fatal(err)
		}
	}
	return &rankingAwardFixture{transaction: transaction}
}

func seedSettledBoard(t *testing.T, ctx context.Context, store rankingstore.Store, transaction tx.Tx, board d.Board, observedAt time.Time, settledAt time.Time, values map[identity.PlayerID]int64) d.BoardSnapshot {
	t.Helper()
	root, err := store.LockBoardRootTx(ctx, transaction, board, awardServer, observedAt.Add(-time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	operation, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	entries := make([]d.BoardEntry, 0, len(values))
	for player, value := range values {
		entries = append(entries, d.BoardEntry{
			Metric: d.BoardMetric{Player: player, Owner: board.SourceOwner, Policy: board.SourcePolicy, Semantics: board.SourceSemantics,
				Revision: awardRevision, PopulationDigest: strings.Repeat("b", 64), FieldID: board.FieldID, Value: value,
				SourceVersion: 1, PopulationVersion: 1, ObservedAt: observedAt},
			Display:    d.BoardPresentation{Player: player, Name: "Award", Level: 10, AvatarID: 110001001},
			ScoreSince: observedAt.Add(-time.Minute),
		})
	}
	next, snapshot, err := d.FreezeBoardSnapshot(root, observedAt, awardRevision, operation, entries)
	if err != nil {
		t.Fatal(err)
	}
	if err := store.InsertBoardSnapshotTx(ctx, transaction, snapshot); err != nil {
		t.Fatal(err)
	}
	if err := store.BindBoardPeriodTx(ctx, transaction, snapshot); err != nil {
		t.Fatal(err)
	}
	if err := store.SaveBoardRootTx(ctx, transaction, next, root.StateVersion); err != nil {
		t.Fatal(err)
	}
	week, err := d.BoardWeek(observedAt)
	if err != nil {
		t.Fatal(err)
	}
	period := d.BoardPeriod{Server: int64(awardServer), Policy: board.Policy, Week: week, Generation: snapshot.Generation}
	if err := store.SettleBoardPeriodTx(ctx, transaction, snapshot, period, settledAt); err != nil {
		t.Fatal(err)
	}
	return snapshot
}

func TestBoardAwardEvidenceReadsSettledRows(t *testing.T) {
	ctx := context.Background()
	fixture := newRankingAwardFixture(t)
	store := rankingstore.Store{}
	firstWeek := time.Date(2026, 11, 11, 3, 0, 0, 0, time.UTC)
	secondWeek := time.Date(2026, 11, 18, 4, 0, 0, 0, time.UTC)
	firstSettled := firstWeek.Add(2 * time.Hour)
	secondSettled := secondWeek.Add(2 * time.Hour)

	first := seedSettledBoard(t, ctx, store, fixture.transaction, d.GirlsBoard, firstWeek, firstSettled, map[identity.PlayerID]int64{awardPlayer: 10, awardOther: 5})
	second := seedSettledBoard(t, ctx, store, fixture.transaction, d.GirlsBoard, secondWeek, secondSettled, map[identity.PlayerID]int64{awardPlayer: 5, awardOther: 10})
	skins := seedSettledBoard(t, ctx, store, fixture.transaction, d.SkinsBoard, firstWeek, firstSettled, map[identity.PlayerID]int64{awardPlayer: 7})

	for _, generation := range []int64{first.Generation, second.Generation} {
		var version int16
		if err := fixture.transaction.QueryRow(ctx, `SELECT payload_version FROM ranking_girls_snapshots WHERE logical_server_id=$1 AND policy_id=$2 AND generation=$3`, int64(awardServer), d.GirlsPolicy, generation).Scan(&version); err != nil {
			t.Fatal(err)
		}
		if version != payload.Current {
			t.Fatalf("ranking_girls_snapshots generation %d payload_version=%d want %d", generation, version, payload.Current)
		}
	}
	if sum := entryCount(first); sum != 2 {
		t.Fatalf("first snapshot entries=%d want 2", sum)
	}
	if sum := entryScore(first); sum != 15 {
		t.Fatalf("first snapshot score sum=%d want 15", sum)
	}

	// Origin keys carry the UTC date of the R3 game-week start (Monday 05:00 GMT+8 = Sunday 21:00 UTC).
	evidence, err := store.BoardAwardEvidenceTx(ctx, fixture.transaction, d.GirlsBoard, awardPlayer)
	if err != nil {
		t.Fatal("BoardAwardEvidenceTx", err)
	}
	wantWeekOne := d.BoardAwardEvidence{Snapshot: first, Award: d.BoardAward{Player: awardPlayer, Rank: 1, TitleID: d.GirlsBoard.Titles[0],
		OriginKey: "ranking:" + d.GirlsPolicy + ":11:2026-11-08:1100001", StartsAt: firstWeek, EndTime: firstWeek.Unix() + d.BoardTitleDuration},
		Server: int64(awardServer), Generation: first.Generation, SnapshotDigest: first.Digest, SettledAt: firstSettled}
	wantWeekTwo := d.BoardAwardEvidence{Snapshot: second, Award: d.BoardAward{Player: awardPlayer, Rank: 2, TitleID: d.GirlsBoard.Titles[1],
		OriginKey: "ranking:" + d.GirlsPolicy + ":11:2026-11-15:1100001", StartsAt: secondWeek, EndTime: secondWeek.Unix() + d.BoardTitleDuration},
		Server: int64(awardServer), Generation: second.Generation, SnapshotDigest: second.Digest, SettledAt: secondSettled}
	requireAwardEvidence(t, evidence, []d.BoardAwardEvidence{wantWeekOne, wantWeekTwo})

	skinsEvidence, err := store.BoardAwardEvidenceTx(ctx, fixture.transaction, d.SkinsBoard, awardPlayer)
	if err != nil {
		t.Fatal("BoardAwardEvidenceTx skins", err)
	}
	wantSkins := d.BoardAwardEvidence{Snapshot: skins, Award: d.BoardAward{Player: awardPlayer, Rank: 1, TitleID: d.SkinsBoard.Titles[0],
		OriginKey: "ranking:" + d.SkinsPolicy + ":11:2026-11-08:1100001", StartsAt: firstWeek, EndTime: firstWeek.Unix() + d.BoardTitleDuration},
		Server: int64(awardServer), Generation: skins.Generation, SnapshotDigest: skins.Digest, SettledAt: firstSettled}
	requireAwardEvidence(t, skinsEvidence, []d.BoardAwardEvidence{wantSkins})

	empty, err := store.BoardAwardEvidenceTx(ctx, fixture.transaction, d.GirlsBoard, awardAbsent)
	if err != nil {
		t.Fatal("BoardAwardEvidenceTx empty", err)
	}
	if len(empty) != 0 {
		t.Fatalf("empty evidence=%+v want none", empty)
	}
}

func requireAwardEvidence(t *testing.T, got, want []d.BoardAwardEvidence) {
	t.Helper()
	if len(got) != len(want) {
		t.Fatalf("evidence count=%d want %d: %+v", len(got), len(want), got)
	}
	for index := range want {
		actual, expected := got[index], want[index]
		if !reflect.DeepEqual(actual.Snapshot, expected.Snapshot) {
			t.Fatalf("evidence %d snapshot=%+v want %+v", index, actual.Snapshot, expected.Snapshot)
		}
		if actual.Server != expected.Server || actual.Generation != expected.Generation || actual.SnapshotDigest != expected.SnapshotDigest {
			t.Fatalf("evidence %d provenance=%+v want %+v", index, actual, expected)
		}
		if !actual.SettledAt.Equal(expected.SettledAt) {
			t.Fatalf("evidence %d settled_at=%s want %s", index, actual.SettledAt, expected.SettledAt)
		}
		if actual.Award.Player != expected.Award.Player || actual.Award.Rank != expected.Award.Rank || actual.Award.TitleID != expected.Award.TitleID ||
			actual.Award.OriginKey != expected.Award.OriginKey || actual.Award.EndTime != expected.Award.EndTime || !actual.Award.StartsAt.Equal(expected.Award.StartsAt) {
			t.Fatalf("evidence %d award=%+v want %+v", index, actual.Award, expected.Award)
		}
	}
}

func entryCount(snapshot d.BoardSnapshot) int {
	return len(snapshot.Entries)
}

func entryScore(snapshot d.BoardSnapshot) int64 {
	total := int64(0)
	for _, entry := range snapshot.Entries {
		total += entry.Metric.Value
	}
	return total
}
