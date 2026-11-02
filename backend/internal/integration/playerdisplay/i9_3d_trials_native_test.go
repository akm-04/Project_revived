//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	app "gxb.local/backend/v2/internal/application/campaign"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"testing"
	"time"
)

func TestI9_3DTrialsAndPurchasesNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := campaignMode(t, p)
	a, rev := bornActor(t, p), installed(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	bornHero(t, p, a, rev, 10001002, 2)
	compositeLevel(t, p, a, rev, 100)
	lines := []grant.Line{{Kind: grant.Temporal, ResourceKey: "energy", Amount: 1000}, {Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 1000}}
	if _, e := compositeI5(p).AdminGrant(ctx, authority().Operator, a.PlayerID, uuid().String(), "I9_3D_NATIVE", lines, opPinned(rev)); e != nil {
		t.Fatal(e)
	}
	cat, e := s.Content.CampaignCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	day := modes.Day(time.Now())
	prophecy, _ := cat.Group(cat.Prophecy(day))
	if _, e := s.Fight(ctx, a, app.Fight{CampaignID: prophecy.Nodes[0], Type: prophecy.ID, Formation: []int64{0, 0, 0, 0, 2}}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("Prophecy without owned purple", e)
	}
	// BLUE2 (6) is still below source PURPLE (7).
	exec(t, p, `UPDATE player_heroes SET color=6,state_version=state_version+1 WHERE player_id=$1 AND partner_id=2`, int64(a.PlayerID))
	if _, e := s.Fight(ctx, a, app.Fight{CampaignID: prophecy.Nodes[0], Type: prophecy.ID, Formation: []int64{0, 0, 0, 0, 2}}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("Prophecy with BLUE2 instead of purple", e)
	}
	// Native fixture for prior Character promotion; stock scenario qualifies actual MID57 separately.
	exec(t, p, `UPDATE player_heroes SET color=7,state_version=state_version+1 WHERE player_id=$1 AND partner_id=2`, int64(a.PlayerID))
	body, e := s.TrialLoad(ctx, a, 115, op())
	if e != nil {
		t.Fatal(e)
	}
	if len(body["trial_info"].(map[string]any)["trials"].([]any)) != 8 || len(body["challenge_info"].(map[string]any)["challenges"].([]any)) != 1 {
		t.Fatal("115 groups", body)
	}
	forecast, e := s.TrialLoad(ctx, a, 123, op())
	if e != nil || fmt.Sprint(forecast["challenges"].([]any)[0].(map[string]any)["id"]) != fmt.Sprint(cat.Prophecy(day)) {
		t.Fatal("123 forecast", forecast, e)
	}
	daily, e := s.TrialLoad(ctx, a, 28, op())
	if e != nil || daily["buy_times"] != "0|0|0|0|0|0|0|0|0|0" {
		t.Fatal("new daily counters", daily, e)
	}
	for _, g := range cat.TrialGroups {
		if d.Cloud(g.ID) {
			continue
		} // Cloud has its own source pet-team qualification below.
		team := []int64{0, 0, 0, 0, 2}
		if g.ID == 12 {
			team[4] = 1
		}
		fight := app.Fight{CampaignID: g.Nodes[0], Type: g.ID, Formation: team}
		_, e := s.Fight(ctx, a, fight, op())
		if !g.Scheduled(cat, day) {
			if !errors.Is(e, d.ErrRefused) {
				t.Fatal("closed trial", g.ID, e)
			}
			continue
		}
		if e != nil {
			t.Fatal("fight", g.ID, e)
		}
		won, e := s.Result(ctx, a, app.Result{CampaignID: fight.CampaignID, Type: g.ID, Star: 3, Formation: team}, op())
		if e != nil {
			t.Fatal("result", g.ID, e)
		}
		key := "trial"
		if g.NextID != 0 {
			key = "challenge"
		}
		if fmt.Sprint(won.Body[key].(map[string]any)["left_times"]) != fmt.Sprint(g.DailyLimit-1) {
			t.Fatal("quota projection", g.ID, won)
		}
		if g.NextID != 0 {
			exec(t, p, `UPDATE player_heroes SET color=1,state_version=state_version+1 WHERE player_id=$1 AND partner_id=2`, int64(a.PlayerID))
		}
		replay, e := s.Result(ctx, a, app.Result{CampaignID: fight.CampaignID, Type: g.ID, Star: 3, Formation: team}, op())
		if e != nil || !replay.Duplicate {
			t.Fatal("duplicate", g.ID, e)
		}
		if g.NextID != 0 {
			exec(t, p, `UPDATE player_heroes SET color=7,state_version=state_version+1 WHERE player_id=$1 AND partner_id=2`, int64(a.PlayerID))
		}
	}
	// Wrong faction and skipped Cloud difficulty refuse before a Combat attempt.
	if _, e = s.Fight(ctx, a, app.Fight{CampaignID: 1001, Type: 11, Formation: []int64{0, 0, 0, 0, 1}}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("faction", e)
	}
	// One actual purchase, exact retry after service reload, then a competing pair.
	var selected d.TrialGroup
	for _, g := range cat.TrialGroups {
		if g.ConsumeID > 0 && g.Scheduled(cat, day) {
			selected = g
			break
		}
	}
	purchase := op()
	before := int64(0)
	if e = p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&before); e != nil {
		t.Fatal(e)
	}
	if _, e = s.BuyTrial(ctx, a, selected.ConsumeID, purchase); e != nil {
		t.Fatal("buy", e)
	}
	if _, e = campaignMode(t, p).BuyTrial(ctx, a, selected.ConsumeID, purchase); e != nil {
		t.Fatal("receipt retry", e)
	}
	if _, e = s.BuyTrial(ctx, a, selected.ConsumeID, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("buy cap", e)
	}
	if _, e = s.BuyTrial(ctx, a, 1, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("missing GoldenHand provider", e)
	}
	var next d.TrialGroup
	for _, g := range cat.TrialGroups {
		if g.ConsumeID > 0 && g.ID != selected.ID && g.Scheduled(cat, day) {
			next = g
			break
		}
	}
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() { defer wg.Done(); _, err := s.BuyTrial(ctx, a, next.ConsumeID, op()); errs <- err }()
	}
	wg.Wait()
	close(errs)
	wins, refused := 0, 0
	for err := range errs {
		if err == nil {
			wins++
		} else if errors.Is(err, d.ErrRefused) {
			refused++
		} else {
			t.Fatal(err)
		}
	}
	if wins != 1 || refused != 1 {
		t.Fatal("purchase race", wins, refused)
	}
	var after int64
	if e = p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&after); e != nil || before-after != 40 {
		t.Fatal("purchase cost/retry", before, after, e)
	}
	// Record a native fixture gate and prove branch writes preserve the trial counters.
	_, e = (tx.Runner{DB: p}).Run(ctx, op(), app.ModeProfile(), tx.Options{}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, sc tx.Scope) error {
		r, e := s.Store.LockTx(c, sc.Tx, a.PlayerID, sc.Operation.StartedAt)
		if e != nil {
			return e
		}
		ids := []int64{cat.ChallengeGateCampaignID, 100001, 100002, 100004}
		for _, id := range ids {
			r.Progress = r.Progress.WithNode(d.NodeState{CampaignID: id, Star: 3})
		}
		return s.Store.SaveTx(c, sc.Tx, a.PlayerID, r, ids, sc.Operation.StartedAt)
	})
	if e != nil {
		t.Fatal(e)
	}
	team := []int64{0, 0, 0, 0, 2}
	if _, e = s.Fight(ctx, a, app.Fight{CampaignID: 24111, Type: 24, Formation: []int64{0, 0, 0, 0, 1}}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("protected Hero admitted", e)
	}
	if _, e = s.Fight(ctx, a, app.Fight{CampaignID: 24111, Type: 24, Formation: team}, op()); e != nil {
		t.Fatal("Challenge fight", e)
	}
	won, e := s.Result(ctx, a, app.Result{CampaignID: 24111, Type: 24, Star: 3, Formation: team}, op())
	if e != nil || len(won.Body["campaigns"].([]any)) != 3 {
		t.Fatal("Challenge branch", won, e)
	}
	record, e := s.Store.ReadTx(ctx, p, a.PlayerID)
	if e != nil || len(record.Progress.TrialWins) == 0 {
		t.Fatal("lost group counters", record, e)
	}
}

func TestI9_3DBoundaryRollbackAndPurchaseRefusalNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := campaignMode(t, p)
	a, rev := bornActor(t, p), installed(t, p)
	bornHero(t, p, a, rev, 10001002, 1)
	compositeLevel(t, p, a, rev, 100)
	cat, e := s.Content.CampaignCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	day := modes.Day(time.Now())
	g, _ := cat.Group(12)
	for !g.Scheduled(cat, day) || g.Scheduled(cat, day+1) {
		day++
	}
	boundary := modes.DayBegins(day + 1)
	clock := &leagueClock{at: boundary.Add(-30 * time.Second)}
	s.Timed.Binder.Time = clock
	team := []int64{0, 0, 0, 0, 1}
	g, _ = cat.Group(11)
	// Find a supported Hero faction for the group that closes at this boundary.
	closing, _ := cat.Group(12)
	bornHero(t, p, a, rev, 10001001, 2)
	team[4] = 2
	if _, e = s.Fight(ctx, a, app.Fight{CampaignID: closing.Nodes[0], Type: closing.ID, Formation: team}, op()); e != nil {
		t.Fatal("boundary start", e)
	}
	var before int64
	if e = p.QueryRow(ctx, `SELECT stored_amount FROM player_temporal_resources WHERE player_id=$1 AND resource_key='energy'`, int64(a.PlayerID)).Scan(&before); e != nil {
		t.Fatal(e)
	}
	clock.Set(boundary.Add(30 * time.Second))
	if _, e = s.Result(ctx, a, app.Result{CampaignID: closing.Nodes[0], Type: closing.ID, Formation: team, Star: 3}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("closed-day result", e)
	}
	var after int64
	if e = p.QueryRow(ctx, `SELECT stored_amount FROM player_temporal_resources WHERE player_id=$1 AND resource_key='energy'`, int64(a.PlayerID)).Scan(&after); e != nil || after != before {
		t.Fatal("refusal charged energy", before, after, e)
	}
	// A purchase with insufficient crystals must not consume its daily entitlement.
	exec(t, p, `UPDATE player_currency_balances SET amount=0 WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))
	for !g.Scheduled(cat, modes.Day(clock.at)) {
		clock.Set(clock.at.Add(24 * time.Hour))
	}
	if _, e = s.BuyTrial(ctx, a, g.ConsumeID, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("short crystal", e)
	}
	daily, e := s.TrialLoad(ctx, a, 28, op())
	if e != nil || daily["buy_times"] != "0|0|0|0|0|0|0|0|0|0" {
		t.Fatal("failed buy spent entitlement", daily, e)
	}
	exec(t, p, `UPDATE player_currency_balances SET amount=100 WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))
	purchase := op()
	if _, e = s.BuyTrial(ctx, a, g.ConsumeID, purchase); e != nil {
		t.Fatal(e)
	}
	clock.Set(clock.at.Add(-24 * time.Hour))
	if _, e = s.TrialLoad(ctx, a, 28, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("backwards day read", e)
	}
	if _, e = s.BuyTrial(ctx, a, g.ConsumeID, purchase); e != nil {
		t.Fatal("receipt must replay before current calendar", e)
	}
}

// Source objectives constrain owned slots before Combat; NPCs are not owned Hero identities.
func TestI9_3DChallengeFormationNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := campaignMode(t, p)
	a, rev := bornActor(t, p), installed(t, p)
	compositeLevel(t, p, a, rev, 100)
	for i := int64(1); i <= 5; i++ {
		bornHero(t, p, a, rev, 10001001+i, i)
	}
	cat, e := s.Content.CampaignCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	var solo d.Node
	for _, n := range cat.Nodes {
		if n.Type == d.Challenge && n.ChallengeMode == 6 {
			solo = n
			break
		}
	}
	if solo.ID == 0 {
		t.Fatal("missing source solo challenge")
	}
	_, e = (tx.Runner{DB: p}).Run(ctx, op(), app.ModeProfile(), tx.Options{}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, sc tx.Scope) error {
		r, e := s.Store.LockTx(c, sc.Tx, a.PlayerID, sc.Operation.StartedAt)
		if e != nil {
			return e
		}
		ids := []int64{}
		for _, n := range cat.Nodes {
			if n.ID != solo.ID {
				r.Progress = r.Progress.WithNode(d.NodeState{CampaignID: n.ID, Star: 3})
				ids = append(ids, n.ID)
			}
		}
		return s.Store.SaveTx(c, sc.Tx, a.PlayerID, r, ids, sc.Operation.StartedAt)
	})
	if e != nil {
		t.Fatal(e)
	}
	if _, e = s.Fight(ctx, a, app.Fight{CampaignID: 24111, Type: 24, Formation: []int64{1, 2, 3, 4, 5}}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("five owned plus Protect NPC", e)
	}
	if _, e = s.Fight(ctx, a, app.Fight{CampaignID: solo.ID, Type: 24, Formation: []int64{0, 0, 0, 1, 2}}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("two owned in solo objective", e)
	}
	if _, e = s.Fight(ctx, a, app.Fight{CampaignID: solo.ID, Type: 24, Formation: []int64{0, 0, 0, 0, 1}}, op()); e != nil {
		t.Fatal("solo objective", e)
	}
}

func TestI9_3DCloudOwnedPetTeamNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := campaignMode(t, p)
	a, rev := bornActor(t, p), installed(t, p)
	compositeLevel(t, p, a, rev, 100)
	cs := contentstore.Store{Queryer: p}
	egg := must(cs.PetAcquisitionTx(ctx, p, rev, genuinePetTable))(t, "pet policy").EggItemID
	grantGenuine(t, p, a, rev, "Cloud fixture resources", []grant.Line{{Kind: grant.StackItem, ItemID: egg, Amount: 1}, {Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 1000}})
	pets := genuinePetService(p)
	id := must(pets.Summon(ctx, a, genuinePetTable, op()))(t, "Cloud pet summon").PetID
	must(pets.CleanCD(ctx, a, id, op()))(t, "Cloud pet hatch")
	cat, e := s.Content.CampaignCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	day := modes.Day(time.Now().Add(time.Hour))
	g, _ := cat.Group(40)
	other, _ := cat.Group(41)
	for !g.Scheduled(cat, day) || !other.Scheduled(cat, day) {
		day++
	}
	at := modes.DayBegins(day).Add(time.Hour)
	if at.Before(time.Now().Add(time.Hour)) {
		at = time.Now().Add(time.Hour)
	}
	s.Timed.Binder.Time = &leagueClock{at: at}
	for _, kind := range []int64{40, 41, 42} {
		g, _ = cat.Group(kind)
		req := app.Fight{CampaignID: g.Nodes[0], Type: kind, PetFormation: []int64{id}}
		for _, bad := range []app.Fight{
			{CampaignID: req.CampaignID, Type: kind, Formation: []int64{id}},
			{CampaignID: req.CampaignID, Type: kind, PetFormation: []int64{id, id}},
			{CampaignID: req.CampaignID, Type: kind, PetFormation: []int64{id, id + 1, id + 2, id + 3, id + 4, id + 5}},
		} {
			if _, e = s.Fight(ctx, a, bad, op()); !errors.Is(e, d.ErrInvalid) {
				t.Fatal("invalid pet formation", e)
			}
		}
		if _, e = s.Fight(ctx, a, app.Fight{CampaignID: req.CampaignID, Type: kind, PetFormation: []int64{id + 999}}, op()); !errors.Is(e, d.ErrRefused) {
			t.Fatal("unowned pet", e)
		}
		if _, e = s.Fight(ctx, a, app.Fight{CampaignID: g.Nodes[2], Type: kind, PetFormation: []int64{id}}, op()); !errors.Is(e, d.ErrRefused) {
			t.Fatal("Cloud predecessor", e)
		}
		if _, e = s.Fight(ctx, a, req, op()); e != nil {
			t.Fatal("Cloud start", e)
		}
		won, e := s.Result(ctx, a, app.Result{CampaignID: req.CampaignID, Type: kind, Star: 3}, op())
		if e != nil {
			t.Fatal("Cloud omitted participant result", e)
		}
		if len(won.Body["exps"].([]any)) != 0 || won.Body["pet_exps"] != nil {
			t.Fatal("invented Cloud owner EXP", won)
		}
		repeat, e := campaignMode(t, p).Result(ctx, a, app.Result{CampaignID: req.CampaignID, Type: kind, Star: 3}, op())
		if e != nil || !repeat.Duplicate {
			t.Fatal("Cloud reload duplicate", e)
		}
	}
}

func TestI9_3DParentWeakGuideOwnerReloadNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	a, rev := bornActor(t, p), installed(t, p)
	s := compositeI5(p)
	request := opPinned(rev)
	first, e := s.SaveGuideFunction(ctx, a, 18, request)
	if e != nil || first.FunctionMap()["18"] != 1 {
		t.Fatal(first, e)
	}
	replay, e := compositeI5(p).SaveGuideFunction(ctx, a, 18, request)
	if e != nil || replay.StateVersion != first.StateVersion {
		t.Fatal("weak guide receipt", replay, e)
	}
	if _, e = s.SaveGuideReturn(ctx, a, 10900202, opPinned(rev)); e != nil {
		t.Fatal(e)
	}
	loaded, e := compositeI5(p).SaveGuideFunction(ctx, a, 18, opPinned(rev))
	if e != nil || loaded.FunctionMap()["18"] != 1 || loaded.GuideReturnID != 10900202 {
		t.Fatal("weak guide durable reload", loaded, e)
	}
}

func TestI9_3DCurrentPurplePromotionNative(t *testing.T) {
	p := pool(t)
	a, rev := genuinePlayer(t, p, rankingServer(t, p))
	cs := contentstore.Store{Queryer: p}
	rule := must(cs.ResolveProgressionPolicyTx(ctx, p, rev))(t, "progression")
	grantGenuine(t, p, a, rev, "purple-player-level", []grant.Line{{Kind: grant.PlayerExp, Amount: rule.Rows[98].TotalExp}})
	grantGenuine(t, p, a, rev, "purple-resources", genuineResources(t, p, rev, []int64{genuineHeroTable}))
	svc := genuineHeroService(p)
	svc.MaxHeroColorPolicy = i5.CurrentMaxHeroColorProvider{}
	def := must(cs.HeroNormalSummonTx(ctx, p, rev, genuineHeroTable))(t, "summon policy")
	h := must(svc.SummonNormal(ctx, a, genuineHeroTable, int64(def.Template.FragmentItemID), def.FragmentCount, op()))(t, "summon")
	must(svc.UseExpItems(ctx, a, h.PartnerID, []i5.HeroExpItemDebit{{ItemID: heroExpItem, Count: 193}}, op()))(t, "hero level")
	for color := int64(1); color < 7; color++ {
		o := op()
		got := must(svc.OneClickJinjie(ctx, a, h.PartnerID, o))(t, "MID57 promote")
		if got.FromColor != color || got.ToColor != color+1 || got.Branch != hero.HeroPromotionMID57Promote {
			t.Fatal("promotion", got)
		}
		retry := must(svc.OneClickJinjie(ctx, a, h.PartnerID, o))(t, "MID57 replay")
		if !retry.Replayed || retry.ToColor != got.ToColor || retry.StateVersion != got.StateVersion {
			t.Fatal("replay", retry)
		}
	}
	// At the cap MID57 collects equipment without promoting beyond purple.
	capped := must(svc.OneClickJinjie(ctx, a, h.PartnerID, op()))(t, "MID57 cap collect")
	if capped.ToColor != 7 || capped.Branch != hero.HeroPromotionMID57Collect {
		t.Fatal("cap", capped)
	}
	var color int64
	if err := p.QueryRow(ctx, `SELECT color FROM player_heroes WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), h.PartnerID).Scan(&color); err != nil || color != 7 {
		t.Fatal("durable purple", color, err)
	}
	var remaining int64
	if err := p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='mana'`, int64(a.PlayerID)).Scan(&remaining); err != nil || remaining >= 100000000 {
		t.Fatal("real resource costs", remaining, err)
	}
}
