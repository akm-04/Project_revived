//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"net/http"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	app "gxb.local/backend/v2/internal/application/inscription"
)

func TestI7C2FReplaceChargesRemoveCostOnceAndReplayDoesNotDebitAgain(t *testing.T) {
	p := pool(t)
	a, rev, s := inscriptionFixture(t, p)
	catalog, e := (contentstore.Store{}).InscriptionCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	cost := catalog.RemoveCost()
	if cost <= 0 {
		t.Fatalf("catalog remove cost %d", cost)
	}
	insCmd(t, s, a, app.Command{Family: app.Insert, PartnerID: 1, ItemID: 160100101})
	crystals := libraryAmount(t, p, a, "crystal")
	oldHeld := dormStack(t, p, a, 160100101)
	newHeld := dormStack(t, p, a, 160100102)
	o := op()
	cmd := app.Command{Family: app.Insert, PartnerID: 1, ItemID: 160100102, ReplaceID: 160100101}
	r, e := s.Command(ctx, a, cmd, o)
	if e != nil {
		t.Fatal(e)
	}
	if got := libraryAmount(t, p, a, "crystal"); got != crystals-cost {
		t.Fatalf("crystal %d, want %d after charging %d", got, crystals-cost, cost)
	}
	if dormStack(t, p, a, 160100101) != oldHeld+1 || dormStack(t, p, a, 160100102) != newHeld-1 {
		t.Fatal("medals not swapped")
	}
	if insFacet(t, p, a, 1).Facts.Slots[0] != 160100102 {
		t.Fatal("slot not replaced")
	}
	replayed, e := s.Command(ctx, a, cmd, o)
	if e != nil || replayed.OperationID != r.OperationID {
		t.Fatal("replay", replayed, e)
	}
	if libraryAmount(t, p, a, "crystal") != crystals-cost || dormStack(t, p, a, 160100101) != oldHeld+1 {
		t.Fatal("replay debited again")
	}
}

func TestI7C2FReplaceWithoutCrystalsRefuses409AndChangesNothing(t *testing.T) {
	p := pool(t)
	a, rev, s := inscriptionFixture(t, p)
	catalog, e := (contentstore.Store{}).InscriptionCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	cost := catalog.RemoveCost()
	if cost <= 0 {
		t.Fatalf("catalog remove cost %d", cost)
	}
	insCmd(t, s, a, app.Command{Family: app.Insert, PartnerID: 1, ItemID: 160100101})
	exec(t, p, `UPDATE player_currency_balances SET amount=$2 WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID), cost-1)
	root := insRoot(t, p, a)
	hero := insFacet(t, p, a, 1)
	oldHeld := dormStack(t, p, a, 160100101)
	newHeld := dormStack(t, p, a, 160100102)
	dispatcher := stockruntime.InscriptionDispatcher{Authority: playtestAuthority{a}, Service: s}
	response := dispatcher.Dispatch(ctx, playtestRequest(a, 1402, map[string]any{
		"partner_id":      json.Number("1"),
		"item_id":         json.Number("160100102"),
		"replace_item_id": json.Number("160100101"),
	}))
	if response.HTTPStatus != http.StatusConflict {
		t.Fatalf("status %d body %+v", response.HTTPStatus, response.Body)
	}
	if response.Body["error_code"] != int64(20005) {
		t.Fatalf("error_code %v, want 20005", response.Body["error_code"])
	}
	if libraryAmount(t, p, a, "crystal") != cost-1 {
		t.Fatal("refusal changed crystal")
	}
	afterRoot := insRoot(t, p, a)
	afterHero := insFacet(t, p, a, 1)
	if afterRoot.Version != root.Version || afterHero.Version != hero.Version {
		t.Fatal("refusal changed owner state")
	}
	if afterHero.Facts.Slots[0] != 160100101 || dormStack(t, p, a, 160100101) != oldHeld || dormStack(t, p, a, 160100102) != newHeld {
		t.Fatal("refusal moved medals")
	}
}
