//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	app "gxb.local/backend/v2/internal/application/march"
	"gxb.local/backend/v2/internal/domain/grant"
	"testing"
)

func TestI9_5CMarchChestOverflowMail(t *testing.T) {
	p := pool(t)
	a, revision := bornActor(t, p), installed(t, p)
	s := marchMode(t, p)
	bornHero(t, p, a, revision, 10001001, 1)
	compositeLevel(t, p, a, revision, 30)
	if _, e := s.Load(ctx, a, op()); e != nil {
		t.Fatal(e)
	}
	team := []int64{1, 0, 0, 0, 0}
	if _, e := s.Start(ctx, a, app.Fight{Formation: team}, op()); e != nil {
		t.Fatal(e)
	}
	if _, e := s.Result(ctx, a, marchReport(marchRecord(t, p, a), int64(a.PlayerID), team, true), op()); e != nil {
		t.Fatal(e)
	}
	var item, cap int64
	for _, row := range marchRecord(t, p, a).Rewards["1"] {
		raw, _ := json.Marshal(row)
		var award struct {
			ID    int64 `json:"table_id"`
			Count int64 `json:"item_num"`
		}
		if e := json.Unmarshal(raw, &award); e != nil {
			t.Fatal(e)
		}
		if award.ID <= 0 || award.Count <= 0 {
			continue
		}
		rp, e := (contentstore.Store{}).ResolveResourceTx(ctx, p, revision, grant.Line{Kind: grant.StackItem, ItemID: award.ID, Amount: 1})
		if e == nil && rp.Stack != nil {
			item, cap = award.ID, rp.Stack.StackCap
			break
		}
	}
	if item == 0 {
		t.Fatal("source chest has no stack item")
	}
	existing := stackQuantity(t, p, a.PlayerID, item)
	if existing < cap {
		grantGenuine(t, p, a, revision, "prior full stack fixture", []grant.Line{{Kind: grant.StackItem, ItemID: item, Amount: cap - existing}})
	}
	mails := func() int64 {
		return leagueScalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1`, int64(a.PlayerID))
	}
	before := mails()
	claim := op()
	if _, e := s.Chest(ctx, a, 1, claim); e != nil {
		t.Fatal("full stack chest must use F9 Mail", e)
	}
	if _, e := s.Chest(ctx, a, 1, claim); e != nil {
		t.Fatal("exact retry", e)
	}
	if mails() != before+1 || stackQuantity(t, p, a.PlayerID, item) != cap {
		t.Fatal("overflow mail or receipt not once", before, mails())
	}
}
