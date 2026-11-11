//go:build postgres

package playerdisplay_test

import (
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/domain/identity"
)

// girlsLogs reads the Girls Log through 836, the MID the model fills from
// (SelfPlayer.lua:5203) and tujian_herodetail reads at TuJianHeroDetailWindow.lua:1536.
func girlsLogs(t *testing.T, p *pg.Pool, a identity.ActorContext) map[string]any {
	t.Helper()
	response := libraryCall(t, p, a, 836, nil)
	if response.HTTPStatus != 200 {
		t.Fatalf("836 status %d body %+v", response.HTTPStatus, response.Body)
	}
	infos, ok := response.Body["library_infos"].(map[string]any)
	if !ok {
		t.Fatalf("library_infos %T", response.Body["library_infos"])
	}
	row, ok := infos["1"].(map[string]any)
	if !ok {
		t.Fatalf("library_infos[1] %T", infos["1"])
	}
	logs, ok := row["partner_logs"].(map[string]any)
	if !ok {
		t.Fatalf("partner_logs %T", row["partner_logs"])
	}
	return logs
}

// TestI9_10BulkGiftCountExact proves the GiftbagUseWindow shape: one 840 with
// gift_num equal to the slider count (GiftbagUseWindow.lua:126-128), favor and
// the item stack scaled by that count, an exact receipt retry, and a refusal
// when the stack is short of the requested count.
func TestI9_10BulkGiftCountExact(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	const likeGift = int64(50005011) // category 1 == table 10001001 like type: 8+5 per gift
	seedStack(t, p, a, rev, likeGift, 5)

	bulk := op()
	response := libraryDispatch(t, p, a, 840, map[string]any{"partner_id": int64(1), "gift_id": likeGift, "gift_num": int64(3)}, bulk)
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(39) {
		t.Fatalf("bulk gift status %d body %+v", response.HTTPStatus, response.Body)
	}
	if got := stackQuantityOrZero(t, p, a.PlayerID, likeGift); got != 2 {
		t.Fatalf("bulk gift left %d, want 2", got)
	}

	retry := libraryDispatch(t, p, a, 840, map[string]any{"partner_id": int64(1), "gift_id": likeGift, "gift_num": int64(3)}, bulk)
	if retry.HTTPStatus != 200 || retry.Body["favor_degree"] != int64(39) {
		t.Fatalf("bulk retry status %d body %+v", retry.HTTPStatus, retry.Body)
	}
	if got := stackQuantityOrZero(t, p, a.PlayerID, likeGift); got != 2 {
		t.Fatalf("bulk retry debited again: %d", got)
	}
	if !reflect.DeepEqual(response.Body["partner_dialogs"], retry.Body["partner_dialogs"]) || !reflect.DeepEqual(response.Body["partner_acts"], retry.Body["partner_acts"]) {
		t.Fatalf("bulk retry changed the post-state")
	}

	short := libraryDispatch(t, p, a, 840, map[string]any{"partner_id": int64(1), "gift_id": likeGift, "gift_num": int64(3)}, op())
	if short.HTTPStatus != 409 || short.Body["error_code"] != int64(35028) {
		t.Fatalf("short bulk gift status %d body %+v", short.HTTPStatus, short.Body)
	}
	if got := libraryHeroFavor(t, p, a.PlayerID, 1); got != 39 {
		t.Fatalf("short bulk gift changed favor to %d", got)
	}
	if got := stackQuantityOrZero(t, p, a.PlayerID, likeGift); got != 2 {
		t.Fatalf("short bulk gift debited to %d", got)
	}

	const dislikeGift = int64(50005014) // category 2 == table 10001001 dislike type: 8-3 per gift
	seedStack(t, p, a, rev, dislikeGift, 2)
	response = libraryDispatch(t, p, a, 840, map[string]any{"partner_id": int64(1), "gift_id": dislikeGift, "gift_num": int64(2)}, op())
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(49) {
		t.Fatalf("second bulk gift status %d body %+v", response.HTTPStatus, response.Body)
	}
	if got := stackQuantityOrZero(t, p, a.PlayerID, dislikeGift); got != 0 {
		t.Fatalf("second bulk gift left %d", got)
	}
}

// TestI9_10GirlsLogImportReconstructionAndMilestone covers the empty log on
// imported girls: test_harness/import_legacy.py:1055 inserts the Library facet
// and deletes all log rows (:1018), bypassing both writers. 836 must still
// report acquisition, and a gift that crosses 100 must add the 80001 milestone.
func TestI9_10GirlsLogImportReconstructionAndMilestone(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	acquired := time.Now().UTC().Add(-2 * time.Hour).Truncate(time.Second)
	exec(t, p, `DELETE FROM player_library_hero_logs WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	exec(t, p, `UPDATE player_library_heroes SET created_at=$2 WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID), acquired)

	logs := girlsLogs(t, p, a)
	entry, ok := logs["10001"].(map[string]any)
	if !ok || entry["time"] != acquired.Unix() {
		t.Fatalf("imported facet acquisition log %+v", logs)
	}

	seedStack(t, p, a, rev, 50001113, 1) // +100 favor crosses the first threshold
	response := libraryCall(t, p, a, 840, map[string]any{"partner_id": int64(1), "gift_id": int64(50001113), "gift_num": int64(1)})
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(100) {
		t.Fatalf("milestone gift status %d body %+v", response.HTTPStatus, response.Body)
	}
	logs = girlsLogs(t, p, a)
	if _, ok := logs["10001"]; !ok {
		t.Fatalf("acquisition log lost after gift %+v", logs)
	}
	milestone, ok := logs["80001"].(map[string]any)
	if !ok || milestone["time"].(int64) < acquired.Unix() {
		t.Fatalf("favor 100 milestone missing %+v", logs)
	}
}
