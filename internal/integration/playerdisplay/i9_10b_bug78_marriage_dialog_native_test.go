//go:build postgres

package playerdisplay_test

import (
	"reflect"
	"testing"

	app "gxb.local/backend/v2/internal/application/librarylocal"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// Bug 78: the stock client swaps the detail page's mission button for feeding
// once a girl is married (TuJianHeroDetailWindow.lua:826-871), so the dialog
// collection must not lose rows at that commit. Marriage adds the type-3 row
// (library_dialog_config id 10) while every opened row remains served.
func TestI9_10BBug78MarriageKeepsDialogsAndAddsMarried(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	setLibraryFavor(t, p, a, 1, lib.FavorLimit)

	before := libraryDialogsFrom836(t, libraryCall(t, p, a, 836, map[string]any{}))
	for _, row := range before {
		if row.DialogID == 10 {
			t.Fatalf("married dialog open before marriage %+v", row)
		}
	}

	seedStack(t, p, a, rev, 50001112, 1)
	married := libraryCall(t, p, a, 840, map[string]any{"partner_id": int64(1), "gift_id": int64(50001112), "gift_num": int64(1)})
	if married.HTTPStatus != 200 || married.Body["is_married"] != int64(1) {
		t.Fatalf("840 marriage status %d body %+v", married.HTTPStatus, married.Body)
	}

	after836 := libraryDialogsFrom836(t, libraryCall(t, p, a, 836, map[string]any{}))
	dialogResponse := libraryCall(t, p, a, 838, map[string]any{"partner_id": int64(1)})
	after838, ok := dialogResponse.Body["partner_dialogs"].([]app.DialogRow)
	if !ok {
		t.Fatalf("838 partner_dialogs %T", dialogResponse.Body["partner_dialogs"])
	}
	if !containsDialog(after836, 10) {
		t.Fatalf("836 after marriage %+v", after836)
	}
	if dialogRowByID(after838, 10) == nil {
		t.Fatalf("838 after marriage lacks married dialog %+v", after838)
	}
	for _, row := range before {
		kept := dialogRowByID(after838, row.DialogID)
		if kept == nil || !reflect.DeepEqual(*kept, row) {
			t.Fatalf("dialog %d lost or changed after marriage: before %+v after %+v", row.DialogID, row, kept)
		}
	}
	if !reflect.DeepEqual(after836, after838) {
		t.Fatalf("836 %+v differs from 838 %+v", after836, after838)
	}
}

func libraryDialogsFrom836(t *testing.T, response httpedge.Response) []app.DialogRow {
	t.Helper()
	infos, ok := response.Body["library_infos"].(map[string]any)
	if !ok {
		t.Fatalf("library_infos %T", response.Body["library_infos"])
	}
	row, ok := infos["1"].(map[string]any)["partner_dialogs"].([]app.DialogRow)
	if !ok {
		t.Fatalf("836 partner_dialogs %T", infos["1"].(map[string]any)["partner_dialogs"])
	}
	return row
}

func containsDialog(rows []app.DialogRow, id int64) bool {
	return dialogRowByID(rows, id) != nil
}

func dialogRowByID(rows []app.DialogRow, id int64) *app.DialogRow {
	for index := range rows {
		if rows[index].DialogID == id {
			return &rows[index]
		}
	}
	return nil
}
