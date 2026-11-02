//go:build postgres

package playerdisplay_test

import (
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	appCampaign "gxb.local/backend/v2/internal/application/campaign"
	dCampaign "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/grant"
)

func TestPlaytestCampaignOverflowLandsInMail(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := bornActor(t, p)
	mode := campaignMode(t, p)
	bornHero(t, p, a, revision, 10001001, 1)
	team := []int64{1, 0, 0, 0, 0}
	exec(t, p, `UPDATE player_progression SET level=1,exp=0 WHERE player_id=$1`, int64(a.PlayerID))
	if _, err := mode.Fight(ctx, a, appCampaign.Fight{CampaignID: 100001, Type: dCampaign.Normal, Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	record, err := (campaignstore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	occurrences := map[int64]int{}
	for _, item := range record.PendingItems {
		occurrences[item.ItemID]++
	}
	item, stackCap := int64(0), int64(0)
	for _, pending := range record.PendingItems {
		if occurrences[pending.ItemID] != 1 {
			continue
		}
		resolved, e := (contentstore.Store{}).ResolveResourceTx(ctx, p, revision, grant.Line{Kind: grant.StackItem, ItemID: pending.ItemID, Amount: 1})
		if e == nil && resolved.Stack != nil {
			item, stackCap = pending.ItemID, resolved.Stack.StackCap
			break
		}
	}
	if item == 0 {
		t.Fatal("campaign drop has no unique stack item")
	}
	existing := stackQuantity(t, p, a.PlayerID, item)
	if existing < stackCap {
		grantGenuine(t, p, a, revision, "playtest full stack", []grant.Line{{Kind: grant.StackItem, ItemID: item, Amount: stackCap - existing}})
	}
	mailCount := func() int64 {
		return leagueScalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1`, int64(a.PlayerID))
	}
	before := mailCount()
	if _, err = mode.Result(ctx, a, appCampaign.Result{CampaignID: 100001, Type: dCampaign.Normal, Star: 3, Formation: team}, op()); err != nil {
		t.Fatalf("campaign result refused on a full stack: %v", err)
	}
	if quantity := stackQuantity(t, p, a.PlayerID, item); quantity != stackCap {
		t.Fatalf("fit not credited: stack=%d cap=%d", quantity, stackCap)
	}
	if after := mailCount(); after != before+1 {
		t.Fatalf("overflow mails %d, want one more than %d", after, before)
	}
}
