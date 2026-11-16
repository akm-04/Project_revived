//go:build postgres

package playerdisplay_test

import (
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	app "gxb.local/backend/v2/internal/application/campaign"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
)

// The first Normal clear of 100007 offers campaign.lua's two assist partners;
// the win pays that partner's stone (item 40001053 for partner 10001053).
var assistFirstClearChain = []int64{100001, 100002, 100004, 100005}
var assistFirstClearTeam = []int64{0, 1, 2, 0, 0}

func assistPlayer(t *testing.T, p *pg.Pool, revision string) identity.ActorContext {
	t.Helper()
	a := bornActor(t, p)
	bornHero(t, p, a, revision, 10001001, 1)
	bornHero(t, p, a, revision, 10001002, 2)
	exec(t, p, `UPDATE player_progression SET level=1,exp=0 WHERE player_id=$1`, int64(a.PlayerID))
	return a
}

func assistPlayerAtStage(t *testing.T, s app.Mode, p *pg.Pool, revision string) identity.ActorContext {
	t.Helper()
	a := assistPlayer(t, p, revision)
	for _, id := range assistFirstClearChain {
		assistFirstClear(t, s, a, id, 0)
	}
	return a
}

func assistFirstClear(t *testing.T, s app.Mode, a identity.ActorContext, campaignID, assistPartner int64) app.Settled {
	t.Helper()
	if _, err := s.Fight(ctx, a, app.Fight{CampaignID: campaignID, Type: d.Normal, Formation: assistFirstClearTeam}, op()); err != nil {
		t.Fatalf("fight %d: %v", campaignID, err)
	}
	settled, err := s.Result(ctx, a, app.Result{CampaignID: campaignID, Type: d.Normal, Star: 3, Formation: assistFirstClearTeam, AssistPartner: assistPartner}, op())
	if err != nil {
		t.Fatalf("result %d: %v", campaignID, err)
	}
	return settled
}

func assistStoneQuantity(t *testing.T, p *pg.Pool, player identity.PlayerID, itemID int64) int64 {
	t.Helper()
	var quantity int64
	if err := p.Raw().QueryRow(ctx, `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(player), itemID).Scan(&quantity); err != nil {
		t.Fatal(err)
	}
	return quantity
}

func TestI9_11CampaignAssistNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := campaignMode(t, p)
	revision := installed(t, p)

	withoutPartner := assistPlayerAtStage(t, s, p, revision)
	noPartner := assistFirstClear(t, s, withoutPartner, 100007, 0)
	if awards, present := noPartner.Body["assist_awards"]; present {
		t.Fatalf("award without an assist partner: %v", awards)
	}
	if quantity := assistStoneQuantity(t, p, withoutPartner.PlayerID, 40001053); quantity != 0 {
		t.Fatalf("stones granted without an assist partner: %d", quantity)
	}

	withoutStones := assistPlayer(t, p, revision)
	plain := assistFirstClear(t, s, withoutStones, 100001, 10001053)
	if awards, present := plain.Body["assist_awards"]; present {
		t.Fatalf("award on a stage without assist stones: %v", awards)
	}

	withPartner := assistPlayerAtStage(t, s, p, revision)
	won := assistFirstClear(t, s, withPartner, 100007, 10001053)
	awards, ok := won.Body["assist_awards"].([]any)
	if !ok || len(awards) != 1 {
		t.Fatalf("assist awards %v", won.Body["assist_awards"])
	}
	row, _ := awards[0].(map[string]any)
	if row["table_id"] != int64(40001053) || row["item_num"] != int64(5) || row["to_stone"] != true {
		t.Fatalf("assist award row %v", row)
	}
	if quantity := assistStoneQuantity(t, p, withPartner.PlayerID, 40001053); quantity != 5 {
		t.Fatalf("assist stone stack %d", quantity)
	}

	replay, err := s.Result(ctx, withPartner, app.Result{CampaignID: 100007, Type: d.Normal, Star: 3, Formation: assistFirstClearTeam, AssistPartner: 10001053}, op())
	if err != nil || !replay.Duplicate {
		t.Fatalf("replayed result %+v %v", replay, err)
	}
	if awards, present := replay.Body["assist_awards"]; !present || len(awards.([]any)) != 1 {
		t.Fatalf("replayed body %v", replay.Body["assist_awards"])
	}
	if quantity := assistStoneQuantity(t, p, withPartner.PlayerID, 40001053); quantity != 5 {
		t.Fatalf("replay granted again: %d", quantity)
	}
}
