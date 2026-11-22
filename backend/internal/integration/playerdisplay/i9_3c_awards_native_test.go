//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	app "gxb.local/backend/v2/internal/application/campaign"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"testing"
)

func TestI9_3CAwardsNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := campaignMode(t, p)
	a, rev := bornActor(t, p), installed(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	compositeLevel(t, p, a, rev, 45)
	if _, err := s.Bonus(ctx, a, d.Normal, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("unearned bonus", err)
	}
	if _, err := s.ChapterAward(ctx, a, 1, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("unearned chapter", err)
	}
	choice := app.StoryChoice{CampaignID: 200002, Type: 1, Partner: 10001005}
	if _, err := s.StoryAward(ctx, a, choice, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("story without start", err)
	}
	// Populate legitimate prior clears as a native fixture. VC proves UI acquisition separately.
	_, err := (tx.Runner{DB: p}).Run(ctx, op(), app.ModeProfile(), tx.Options{}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, sc tx.Scope) error {
		r, e := s.Store.LockTx(c, sc.Tx, a.PlayerID, sc.Operation.StartedAt)
		if e != nil {
			return e
		}
		catalog, e := s.Content.CampaignCatalogTx(c, sc.Tx, rev)
		if e != nil {
			return e
		}
		changed := []int64{}
		for _, id := range catalog.Chain(d.Normal) {
			if id == 200002 {
				break
			}
			r.Progress = r.Progress.WithNode(d.NodeState{CampaignID: id, Star: 3})
			changed = append(changed, id)
		}
		return s.Store.SaveTx(c, sc.Tx, a.PlayerID, r, changed, sc.Operation.StartedAt)
	})
	if err != nil {
		t.Fatal(err)
	}
	tracked, _ := changes.Track(ctx)
	bonusOp := op()
	bonus, err := s.Bonus(tracked, a, d.Normal, bonusOp)
	if err != nil {
		t.Fatal(err)
	}
	replay, err := s.Bonus(ctx, a, d.Normal, bonusOp)
	if err != nil || canonicalJSON(replay["awards"]) != canonicalJSON(bonus["awards"]) {
		t.Fatal("bonus replay", replay, err)
	}
	// One chapter entitlement, two independent operations. Only one may settle.
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() { defer wg.Done(); _, e := s.ChapterAward(ctx, a, 1, op()); errs <- e }()
	}
	wg.Wait()
	close(errs)
	wins, refused := 0, 0
	for e := range errs {
		if e == nil {
			wins++
		} else if errors.Is(e, d.ErrRefused) {
			refused++
		} else {
			t.Fatal(e)
		}
	}
	if wins != 1 || refused != 1 {
		t.Fatal("competing chapter claims", wins, refused)
	}
	if _, err = s.ChapterAward(ctx, a, 7, op()); !errors.Is(err, d.ErrInvalid) {
		t.Fatal("boss gift", err)
	}
	team := []int64{1, 0, 0, 0, 0}
	if _, err = s.Fight(ctx, a, app.Fight{CampaignID: 200002, Type: 1, Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	claimOp := op()
	body, err := s.StoryAward(ctx, a, choice, claimOp)
	if err != nil || body["story_drop_awards"] == nil {
		t.Fatal("story", body, err)
	}
	for _, requestOp := range []operation.Context{claimOp, op()} {
		again, e := s.StoryAward(ctx, a, choice, requestOp)
		if e != nil || canonicalJSON(again["story_drop_awards"]) != canonicalJSON(body["story_drop_awards"]) {
			t.Fatal("story replay", again, e)
		}
	}
	r, err := (campaignstore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if err != nil || !r.Progress.State(200002).PartnerDrop || r.PendingGeneration != "1/200002" {
		t.Fatal("claim lost fight", r, err)
	}
	var claim map[string]json.RawMessage
	if err = json.Unmarshal(r.Progress.StoryClaims[200002], &claim); err != nil || len(claim["admission"]) == 0 || body["admission"] != nil {
		t.Fatal("story admission provenance", err)
	}

	tracked, _ = changes.Track(ctx)
	if _, err = s.Result(tracked, a, app.Result{CampaignID: 200002, Type: 1, Formation: team, Star: 3}, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = s.StoryAward(ctx, a, choice, op()); err != nil {
		t.Fatal("story reconnect after result", err)
	}
	caps, err := s.Caps(ctx, a, op())
	if err != nil || caps["max_lev"] != int64(100) || caps["max_color"] != int64(7) {
		t.Fatal(caps, err)
	}
	world, err := s.Load(ctx, a, op())
	if err != nil || len(world["chapter_events"].([]any)) != 6 {
		t.Fatal(world, err)
	}

}

func canonicalJSON(v any) string { raw, _ := json.Marshal(v); return string(raw) }

func TestI9_3CPetBattleCreditNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := campaignMode(t, p)
	a, rev := bornActor(t, p), installed(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	compositeLevel(t, p, a, rev, 45)
	content := contentstore.Store{Queryer: p}
	def, err := content.PetAcquisitionTx(ctx, p, rev, 10010001)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = compositeI5(p).AdminGrant(ctx, authority().Operator, a.PlayerID, uuid().String(), "I9_3C_NATIVE", []grant.Line{{Kind: grant.StackItem, ItemID: def.EggItemID, Amount: 1}, {Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 1000}}, opPinned(rev)); err != nil {
		t.Fatal(err)
	}
	pets := genuinePetService(p)
	pet, err := pets.Summon(ctx, a, def.TableID, op())
	if err != nil {
		t.Fatal(err)
	}
	if _, err = pets.CleanCD(ctx, a, pet.PetID, op()); err != nil {
		t.Fatal(err)
	}
	if err = pets.SetShow(ctx, a, pet.PetID, op()); err != nil {
		t.Fatal(err)
	}
	team := []int64{1, 0, 0, 0, 0}
	if _, err = s.Fight(ctx, a, app.Fight{CampaignID: 100001, Type: 1, Formation: team, Pet: pet.PetID}, op()); err != nil {
		t.Fatal(err)
	}
	tracked, _ := changes.Track(ctx)
	result, err := s.Result(tracked, a, app.Result{CampaignID: 100001, Type: 1, Formation: team, Pet: pet.PetID, Star: 3}, op())
	if err != nil {
		t.Fatal(err)
	}
	if rows, ok := result.Body["pet_exps"].([]any); !ok || len(rows) != 1 || rows[0].(map[string]any)["exp"] != int64(75) {
		t.Fatal(result.Body)
	}
	tracked, _ = changes.Track(ctx)
	again, err := s.Result(tracked, a, app.Result{CampaignID: 100001, Type: 1, Formation: team, Pet: pet.PetID, Star: 3}, op())
	if err != nil || !again.Duplicate {
		t.Fatal(again, err)
	}
}

func TestI9_3CChapterAwardFullyMailedNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := campaignMode(t, p)
	a, rev := bornActor(t, p), installed(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	compositeLevel(t, p, a, rev, 45)
	conditions := []int64{100018, 100024}
	_, err := (tx.Runner{DB: p}).Run(ctx, op(), app.ModeProfile(), tx.Options{}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, sc tx.Scope) error {
		r, e := s.Store.LockTx(c, sc.Tx, a.PlayerID, sc.Operation.StartedAt)
		if e != nil {
			return e
		}
		for _, id := range conditions {
			r.Progress = r.Progress.WithNode(d.NodeState{CampaignID: id, Star: 3})
		}
		return s.Store.SaveTx(c, sc.Tx, a.PlayerID, r, conditions, sc.Operation.StartedAt)
	})
	if err != nil {
		t.Fatal(err)
	}
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,50001024,999,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour') ON CONFLICT(player_id,item_id) DO UPDATE SET quantity=999,state_version=player_item_stacks.state_version+1,updated_at=clock_timestamp()`, int64(a.PlayerID))
	mails := scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1`, int64(a.PlayerID))
	if _, err = s.ChapterAward(ctx, a, 1, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("fully mailed chapter gift = %v", err)
	}
	if got := scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1`, int64(a.PlayerID)); got != mails {
		t.Fatalf("refusal wrote %d mail rows", got-mails)
	}
	if got := scalar(t, p, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_kind='player' AND owner_key=$1 AND domain='campaign' AND operation='chapter-award'`, fmt.Sprint(int64(a.PlayerID))); got != 0 {
		t.Fatalf("refusal wrote %d chapter-award receipts", got)
	}
	r, err := (campaignstore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if err != nil || r.Progress.ChapterClaims[1] != 0 || r.Progress.State(100018).Star != 3 {
		t.Fatalf("refusal advanced the claim: %+v %v", r.Progress, err)
	}
	if got := scalar(t, p, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=50001024`, int64(a.PlayerID)); got != 999 {
		t.Fatalf("refusal changed the stack to %d", got)
	}
	exec(t, p, `UPDATE player_item_stacks SET quantity=998 WHERE player_id=$1 AND item_id=50001024`, int64(a.PlayerID))
	body, err := s.ChapterAward(ctx, a, 1, op())
	if err != nil {
		t.Fatal(err)
	}
	rows, ok := body["awards"].([]any)
	if !ok || len(rows) != 1 || rows[0].(map[string]any)["item_num"] != int64(1) {
		t.Fatalf("partial fit awards = %v", body["awards"])
	}
}

func TestI9_3CStoryAwardOwnedPartnerNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := campaignMode(t, p)
	a, rev := bornActor(t, p), installed(t, p)
	bornHero(t, p, a, rev, 10001008, 1)
	compositeLevel(t, p, a, rev, 45)
	_, err := (tx.Runner{DB: p}).Run(ctx, op(), app.ModeProfile(), tx.Options{}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, sc tx.Scope) error {
		r, e := s.Store.LockTx(c, sc.Tx, a.PlayerID, sc.Operation.StartedAt)
		if e != nil {
			return e
		}
		catalog, e := s.Content.CampaignCatalogTx(c, sc.Tx, rev)
		if e != nil {
			return e
		}
		changed := []int64{}
		for _, id := range catalog.Chain(d.Normal) {
			if id == 200002 {
				break
			}
			r.Progress = r.Progress.WithNode(d.NodeState{CampaignID: id, Star: 3})
			changed = append(changed, id)
		}
		return s.Store.SaveTx(c, sc.Tx, a.PlayerID, r, changed, sc.Operation.StartedAt)
	})
	if err != nil {
		t.Fatal(err)
	}
	team := []int64{1, 0, 0, 0, 0}
	if _, err = s.Fight(ctx, a, app.Fight{CampaignID: 200002, Type: d.Normal, Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	choice := app.StoryChoice{CampaignID: 200002, Type: d.Normal, Partner: 10001008}
	claimOp := op()
	body, err := s.StoryAward(ctx, a, choice, claimOp)
	if err != nil {
		t.Fatal(err)
	}
	rows, ok := body["story_drop_awards"].([]any)
	if !ok || len(rows) != 1 {
		t.Fatalf("story_drop_awards = %v", body["story_drop_awards"])
	}
	row := rows[0].(map[string]any)
	if row["table_id"] != int64(40001008) || row["item_num"] != int64(7) || row["to_stone"] != true {
		t.Fatalf("owned partner row = %v", row)
	}
	if _, partner := row["is_partner"]; partner {
		t.Fatalf("owned partner still claims is_partner: %v", row)
	}
	if got := scalar(t, p, `SELECT count(*) FROM player_heroes WHERE player_id=$1 AND origin_table_id=10001008`, int64(a.PlayerID)); got != 1 {
		t.Fatalf("roster has %d partner rows", got)
	}
	stoneSQL := `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=40001008),0)`
	if got := scalar(t, p, stoneSQL, int64(a.PlayerID)); got != 7 {
		t.Fatalf("stone stack = %d, want 7", got)
	}
	again, err := s.StoryAward(ctx, a, choice, claimOp)
	if err != nil || canonicalJSON(again["story_drop_awards"]) != canonicalJSON(body["story_drop_awards"]) {
		t.Fatalf("story replay = %v %v", again, err)
	}
	if got := scalar(t, p, stoneSQL, int64(a.PlayerID)); got != 7 {
		t.Fatalf("replay granted again: stone stack = %d", got)
	}
}
