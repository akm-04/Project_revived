//go:build postgres

package playerdisplay_test

import (
	"testing"

	app "gxb.local/backend/v2/internal/application/librarylocal"
)

// TestI9_10IntimacyFavorBandsVisitDialogsAndLog covers bugs 51-53 through the
// production Library service: act gating by library_amour bands, the opened
// visit dialogs, the acquisition log and the favor-threshold log written by a
// gift that raises intimacy.
func TestI9_10IntimacyFavorBandsVisitDialogsAndLog(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)

	body, e := libraryService(p, p).Read(ctx, a, op(), 836, 0)
	if e != nil {
		t.Fatal(e)
	}
	row := body["library_infos"].(map[string]any)["1"].(map[string]any)
	logs, ok := row["partner_logs"].(map[string]any)
	if !ok {
		t.Fatalf("partner_logs %T", row["partner_logs"])
	}
	if _, present := logs["10001"]; !present {
		t.Fatalf("summoned hero has no acquisition log %+v", logs)
	}
	acts, ok := row["partner_acts"].([]app.ActSlot)
	if !ok || len(acts) != 1 {
		t.Fatalf("acts at zero favor %T %+v", row["partner_acts"], row["partner_acts"])
	}

	response := libraryCall(t, p, a, 838, map[string]any{"partner_id": int64(1)})
	if response.HTTPStatus != 200 {
		t.Fatalf("838 status %d body %+v", response.HTTPStatus, response.Body)
	}
	dialogs := libraryDialogRows(t, response.Body)
	if len(dialogs) != 2 || dialogs[0]["dialog_id"] != int64(1) || dialogs[1]["dialog_id"] != int64(12) {
		t.Fatalf("visit dialogs at zero favor %+v", dialogs)
	}

	seedStack(t, p, a, rev, 50001113, 1)
	response = libraryCall(t, p, a, 840, map[string]any{"partner_id": int64(1), "gift_id": int64(50001113), "gift_num": int64(1)})
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(100) {
		t.Fatalf("chocolate gift status %d body %+v", response.HTTPStatus, response.Body)
	}
	if acts, ok := response.Body["partner_acts"].([]app.ActSlot); !ok || len(acts) != 1 {
		t.Fatalf("acts after gift %T %+v", response.Body["partner_acts"], response.Body["partner_acts"])
	}

	body, e = libraryService(p, p).Read(ctx, a, op(), 836, 0)
	if e != nil {
		t.Fatal(e)
	}
	row = body["library_infos"].(map[string]any)["1"].(map[string]any)
	logs = row["partner_logs"].(map[string]any)
	if _, present := logs["80001"]; !present {
		t.Fatalf("favor 100 milestone missing %+v", logs)
	}

	setLibraryFavor(t, p, a, 1, 101)
	response = libraryCall(t, p, a, 842, map[string]any{"partner_id": int64(1)})
	if response.HTTPStatus != 200 {
		t.Fatalf("842 status %d body %+v", response.HTTPStatus, response.Body)
	}
	if acts, ok := response.Body["partner_acts"].([]app.ActSlot); !ok || len(acts) != 2 {
		t.Fatalf("acts above favor 100 %T %+v", response.Body["partner_acts"], response.Body["partner_acts"])
	}
}
