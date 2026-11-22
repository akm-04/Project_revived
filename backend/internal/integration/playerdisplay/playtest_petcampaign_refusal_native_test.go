//go:build postgres

package playerdisplay_test

import (
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	app "gxb.local/backend/v2/internal/application/petcampaign"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPlaytestPetCampaignDrainedResultRefusesAndClearsFight(t *testing.T) {
	p := pool(t)
	a, revision := bornActor(t, p), installed(t, p)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	mode := petCampaignMode(t, p, clock)
	compositeLevel(t, p, a, revision, 100)
	bornHero(t, p, a, revision, 10001001, 1)
	catalog, err := (contentstore.Store{}).PetCampaignCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal(err)
	}
	floor, _ := catalog.Floor(1, 1)
	if _, err = mode.Start(ctx, a, app.Fight{Campaign: floor.ID, Formation: []int64{1, 0, 0, 0, 0}}, op()); err != nil {
		t.Fatal(err)
	}
	record := petCampaignRecord(t, p, a)
	if record.Fight == nil {
		t.Fatal("START did not freeze a fight")
	}
	generation := record.Fight.ID
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	locator := cd.Locator{DomainKind: "petcampaign", AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID), DomainLocator: fmt.Sprint(a.PlayerID)}
	if _, err = combatService(t, p).CloseTx(ctx, tr, appcombat.TerminalRequest{Locator: locator, GenerationRef: generation,
		TerminalKind: "PET_CAMPAIGN_RESULT", SemanticReceiptID: "playtest-drain:" + generation, At: time.Now().UTC()}); err != nil {
		tr.Rollback(ctx)
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	dispatcher := stockruntime.PetCampaignDispatcher{Authority: playtestAuthority{a}, Service: mode}
	response := dispatcher.Dispatch(ctx, playtestRequest(a, 820, map[string]any{"is_win": true, "floor": int64(1), "floor_type": int64(1)}))
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(35028) {
		t.Fatalf("drained result reached the OK callback: %+v", response)
	}
	if petCampaignRecord(t, p, a).Fight != nil {
		t.Fatal("drained result did not persist the cleared fight")
	}
	response = dispatcher.Dispatch(ctx, playtestRequest(a, 819, map[string]any{"campaign_id": floor.ID, "formation": "1|0|0|0|0"}))
	if response.HTTPStatus != 200 {
		t.Fatalf("START after drain %+v", response)
	}
}
