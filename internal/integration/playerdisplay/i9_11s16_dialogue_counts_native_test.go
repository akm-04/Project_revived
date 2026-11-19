//go:build postgres

package playerdisplay_test

import (
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const i911s16MigrationFile = "00182_i9_11s16_dialogue_counts.sql"

func dialogueCountValue(t *testing.T, p *pg.Pool, player identity.PlayerID, partnerID int64) int64 {
	t.Helper()
	var count int64
	if e := p.QueryRow(ctx, `SELECT COALESCE((SELECT count FROM library_hero_dialogue_counts WHERE player_id=$1 AND partner_id=$2),0)`, int64(player), partnerID).Scan(&count); e != nil {
		t.Fatal(e)
	}
	return count
}

func dialogueMilestoneRows(t *testing.T, p *pg.Pool, player identity.PlayerID, partnerID int64) map[int64]int64 {
	t.Helper()
	rows, e := p.Raw().Query(ctx, `SELECT log_id,count(*) FROM player_library_hero_logs WHERE player_id=$1 AND partner_id=$2 AND log_id BETWEEN 70001 AND 70004 GROUP BY log_id`, int64(player), partnerID)
	if e != nil {
		t.Fatal(e)
	}
	defer rows.Close()
	out := map[int64]int64{}
	for rows.Next() {
		var logID, count int64
		if e = rows.Scan(&logID, &count); e != nil {
			t.Fatal(e)
		}
		out[logID] = count
	}
	if e = rows.Err(); e != nil {
		t.Fatal(e)
	}
	return out
}

func partnerLogs836(t *testing.T, p *pg.Pool, a identity.ActorContext, partnerID int64) map[string]any {
	t.Helper()
	response := libraryCall(t, p, a, 836, nil)
	if response.HTTPStatus != 200 {
		t.Fatalf("836 status %d body %+v", response.HTTPStatus, response.Body)
	}
	infos, ok := response.Body["library_infos"].(map[string]any)
	if !ok {
		t.Fatalf("library_infos %T", response.Body["library_infos"])
	}
	info, ok := infos[strconv.FormatInt(partnerID, 10)].(map[string]any)
	if !ok {
		t.Fatalf("partner %d absent from 836 %+v", partnerID, infos)
	}
	logs, ok := info["partner_logs"].(map[string]any)
	if !ok {
		t.Fatalf("partner_logs %T", info["partner_logs"])
	}
	return logs
}

// A-168 S16: every completed talk counts, first or repeat, so 30 talks of one
// girl reach 70003 and 836 serves it; D482 grants favor once.
func TestI9_11S16DialogueRepeatsReachThirty(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	setLibraryFavor(t, p, a, 1, 100)
	params := map[string]any{"partner_id": int64(1), "dialog_id": int64(2), "select_info": "2|202001"}
	for index := 0; index < 30; index++ {
		if response := libraryCall(t, p, a, 843, params); response.HTTPStatus != 200 {
			t.Fatalf("talk %d status %d body %+v", index+1, response.HTTPStatus, response.Body)
		}
	}
	if count := dialogueCountValue(t, p, a.PlayerID, 1); count != 30 {
		t.Fatalf("dialogue count=%d want 30", count)
	}
	rows := dialogueMilestoneRows(t, p, a.PlayerID, 1)
	if len(rows) != 3 || rows[70001] != 1 || rows[70002] != 1 || rows[70003] != 1 {
		t.Fatalf("milestone rows=%v want one each of 70001-70003", rows)
	}
	logs := partnerLogs836(t, p, a, 1)
	for _, id := range []string{"70001", "70002", "70003"} {
		if _, present := logs[id]; !present {
			t.Fatalf("836 partner_logs lacks %s: %+v", id, logs)
		}
	}
	facts, e := (librarystore.Store{}).ReadHeroTx(ctx, p, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
	if e != nil || facts.Favor != 102 {
		t.Fatalf("favor=%d err=%v want 102 (D482 once-only)", facts.Favor, e)
	}

	// An exact receipt replay of one talk counts once.
	talkOperation := op()
	if response := libraryDispatch(t, p, a, 843, params, talkOperation); response.HTTPStatus != 200 {
		t.Fatalf("replay talk status %d body %+v", response.HTTPStatus, response.Body)
	}
	if count := dialogueCountValue(t, p, a.PlayerID, 1); count != 31 {
		t.Fatalf("fresh talk count=%d want 31", count)
	}
	if response := libraryDispatch(t, p, a, 843, params, talkOperation); response.HTTPStatus != 200 {
		t.Fatalf("exact replay status %d body %+v", response.HTTPStatus, response.Body)
	}
	if count := dialogueCountValue(t, p, a.PlayerID, 1); count != 31 {
		t.Fatalf("receipt replay counted again: %d", count)
	}

	// A refused talk (dialog 3 needs favor 200) does not count.
	response := libraryCall(t, p, a, 843, map[string]any{"partner_id": int64(1), "dialog_id": int64(3)})
	if response.HTTPStatus != 409 {
		t.Fatalf("closed dialog status %d body %+v", response.HTTPStatus, response.Body)
	}
	if count := dialogueCountValue(t, p, a.PlayerID, 1); count != 31 {
		t.Fatalf("refused talk moved count to %d", count)
	}
}

// A-168 S16: the migration backfill sets the counter to the existing distinct
// awarded rows, and 836 derives the milestones from that counter.
func TestI9_11S16DialogueBackfillFromAwardedRows(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	at := time.Now().UTC().Add(-time.Minute).Truncate(time.Microsecond)
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	for dialogID := int64(1); dialogID <= 10; dialogID++ {
		if e = (librarystore.Store{}).SaveDialogTx(ctx, tr, lib.DialogFact{PlayerID: a.PlayerID, PartnerID: 1, DialogID: dialogID, IsRead: true, IsAwarded: true, UpdatedAt: at}); e != nil {
			tr.Rollback(ctx)
			t.Fatal(e)
		}
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	// The migration backfill is a whole-table upgrade statement; empty the
	// counter so it runs exactly as on a database upgrading from 00181.
	exec(t, p, `DELETE FROM library_hero_dialogue_counts`)

	migration, e := os.ReadFile("../../../migrations/" + i911s16MigrationFile)
	if e != nil {
		t.Fatal(e)
	}
	applied := false
	for _, statement := range strings.Split(string(migration), ";") {
		if !strings.Contains(statement, "INSERT INTO library_hero_dialogue_counts") {
			continue
		}
		if _, e = p.Raw().Exec(ctx, statement); e != nil {
			t.Fatalf("apply backfill: %v", e)
		}
		applied = true
	}
	if !applied {
		t.Fatal("migration has no dialogue count backfill")
	}
	if count := dialogueCountValue(t, p, a.PlayerID, 1); count != 10 {
		t.Fatalf("backfilled count=%d want 10", count)
	}
	logs := partnerLogs836(t, p, a, 1)
	for _, id := range []string{"70001", "70002"} {
		if _, present := logs[id]; !present {
			t.Fatalf("836 lacks counter milestone %s: %+v", id, logs)
		}
	}
	if _, present := logs["70003"]; present {
		t.Fatalf("10 completions reached 70003: %+v", logs)
	}
}
