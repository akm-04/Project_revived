//go:build postgres

package playerdisplay_test

import (
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/adventurestore"
	d "gxb.local/backend/v2/internal/domain/adventure"
)

// A-186: a Library favor raise creates one 10002 occurrence whose special_data
// is the favored partner id, and 2416 lists it.
func TestI9_11T34AdventureFavorOccurrenceNative(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	exec(t, p, `UPDATE player_directory_profiles SET lev=11 WHERE player_id=$1`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)
		VALUES($1,68,$2,$3,clock_timestamp()-interval '1 minute') ON CONFLICT(player_id,function_id)DO NOTHING`,
		int64(a.PlayerID), rev, fmt.Sprintf("native:favor:%d", a.PlayerID))
	setLibraryFavor(t, p, a, 1, 100)

	service := libraryFactService(p)
	operation := triggeringIntimacyOperation(t, a.PlayerID)
	response := libraryDispatchService(t, a, service, 844, map[string]any{"partner_id": int64(1), "act_id": int64(1)}, operation)
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(105) {
		t.Fatalf("act award status %d body %+v", response.HTTPStatus, response.Body)
	}

	rows, err := (adventurestore.Store{}).ListOccurrencesTx(ctx, p, a.LogicalServerID, a.PlayerID, time.Now().UTC().Add(time.Hour), 32)
	if err != nil {
		t.Fatal(err)
	}
	favor := 0
	for _, row := range rows {
		if row.EventType != d.EventFavor {
			continue
		}
		favor++
		if row.SpecialData != 1 {
			t.Fatalf("favor special_data %d want partner 1", row.SpecialData)
		}
	}
	if favor != 1 {
		t.Fatalf("favor occurrences %d", favor)
	}

	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	listOperation := opPinned(rev)
	listOperation.StartedAt = clock.at
	body, err := mode.List(ctx, a, listOperation)
	if err != nil {
		t.Fatal("2416 list", err)
	}
	list, ok := body["adventure_list"].(map[string]any)["list"].(map[string]any)
	if !ok {
		t.Fatalf("2416 list body %#v", body)
	}
	row, ok := list["10002"].(map[string]any)
	if !ok || row["special_data"] != int64(1) {
		t.Fatalf("2416 favor row %#v", list["10002"])
	}
	if row["table_id"] != d.EventFavor {
		t.Fatalf("2416 favor table_id %#v", row)
	}

	// A stored pre-fix row with special_data 0 is retired from the list.
	exec(t, p, `DELETE FROM adventure_occurrences WHERE player_id=$1 AND event_type=$2`, int64(a.PlayerID), d.EventFavor)
	putAdventureOccurrence(t, p, a.PlayerID, d.EventFavor, 0, time.Now().UTC(), time.Now().UTC().Add(time.Hour), "retired-favor")
	body, err = mode.List(ctx, a, listOperation)
	if err != nil {
		t.Fatal("2416 list after retirement", err)
	}
	list = body["adventure_list"].(map[string]any)["list"].(map[string]any)
	if row, ok := list["10002"].(map[string]any); !ok || len(row) != 0 {
		t.Fatalf("retired favor row served %#v", list["10002"])
	}
}
