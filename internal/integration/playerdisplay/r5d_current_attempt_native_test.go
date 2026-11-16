//go:build postgres

package playerdisplay_test

import (
	"fmt"
	"testing"
	"time"

	combat "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// R5D-01: the shared Combat read answers a mode's RESULT bookkeeping from the
// durable attempt: the open attempt, else the newest terminal one, with the
// formation, generation and start time its START froze.
func TestR5DCurrentAttemptNative(t *testing.T) {
	pool := pool(t)
	a, rev, ref := combatOwner(t, pool, rankingServer(t, pool))
	s := combatService(t, pool)
	formation := []int64{ref.PartnerID}
	locator := d.Locator{DomainKind: "r5d-fixture-mode", AuthorityScope: "current", DomainLocator: fmt.Sprint(a.PlayerID)}
	read := func(at d.Locator) (combat.CurrentAttempt, bool, error) {
		return s.CurrentAttemptTx(ctx, pool, at)
	}

	if _, found, err := read(d.Locator{DomainKind: "r5d-fixture-mode", AuthorityScope: "current", DomainLocator: "absent"}); err != nil || found {
		t.Fatal("R5D-01 a locator that never had an attempt must not be found", found, err)
	}
	start := func(generation, name string) combat.Started {
		t.Helper()
		request := combat.StartRequest{Actor: a, Locator: locator, GenerationRef: generation, StartFingerprint: fingerprint(name),
			Battle: combat.BattleRequest{CampaignType: 1, BattleID: 0, Formation: formation,
				TeamA:  []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: a.PlayerID, Identity: ref.PartnerID}},
				WavesB: [][]combat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}},
			TrustProfile: d.ClientSummaryAttested, Replay: d.ReplaySpec{Response: d.ReplayOK}}
		started, err := fixtureStart(t, s, rev, request, pool)
		if err != nil {
			t.Fatal("R5D-01 START", name, err)
		}
		return started
	}
	attest := func(attempt d.Attempt) {
		t.Helper()
		policy := d.SummaryPolicy{ID: "R5D_NATIVE_SUMMARY_V1", Version: 1, MaxStar: 1, MaxDamage: 1_000_000}
		tr, err := pool.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
		if err != nil {
			t.Fatal(err)
		}
		defer tr.Rollback(ctx)
		_, err = s.AttestSummaryTx(ctx, tr, combat.SummaryRequest{Locator: attempt.Locator, GenerationRef: attempt.GenerationRef, TerminalKind: "R5D_SETTLED", At: time.Now().UTC(), Policy: policy,
			Summary: d.Summary{Star: 1, Win: true, Damage: 10, Alive: 1, Formation: formation}})
		if err != nil {
			t.Fatal("R5D-01 attest", err)
		}
		if err = tr.Commit(ctx); err != nil {
			t.Fatal(err)
		}
	}

	first := start("generation-1", "r5d-current-1")
	open, found, err := read(locator)
	if err != nil || !found || open.Attempt.ID != first.Attempt.ID || open.Attempt.State == d.Terminal {
		t.Fatal("R5D-01 open attempt", open, found, err)
	}
	if open.Attempt.GenerationRef != "generation-1" || open.Attempt.StartedAt.IsZero() {
		t.Fatal("R5D-01 frozen generation and start time", open.Attempt)
	}
	if fmt.Sprint(open.Formation) != fmt.Sprint(formation) {
		t.Fatal("R5D-01 frozen formation", open.Formation)
	}

	attest(first.Attempt)
	settled, found, err := read(locator)
	if err != nil || !found || settled.Attempt.ID != first.Attempt.ID || settled.Attempt.State != d.Terminal || fmt.Sprint(settled.Formation) != fmt.Sprint(formation) {
		t.Fatal("R5D-01 terminal attempt", settled, found, err)
	}

	second := start("generation-2", "r5d-current-2")
	attest(second.Attempt)
	newest, found, err := read(locator)
	if err != nil || !found || newest.Attempt.ID != second.Attempt.ID || newest.Attempt.State != d.Terminal {
		t.Fatal("R5D-01 newest terminal", newest, found, err)
	}

	third := start("generation-3", "r5d-current-3")
	open, found, err = read(locator)
	if err != nil || !found || open.Attempt.ID != third.Attempt.ID || open.Attempt.State == d.Terminal {
		t.Fatal("R5D-01 an open attempt wins over an older terminal", open, found, err)
	}

	// A settlement row is append-only in every mode table.
	exec(t, pool, `INSERT INTO worldboss_attempt_settlements(attempt_id,player_id,damage,settled_at)VALUES($1,$2,5,clock_timestamp())`, second.Attempt.ID.String(), int64(a.PlayerID))
	exec(t, pool, `INSERT INTO illusion_attempt_settlements(attempt_id,player_id,damage,settled_at)VALUES($1,$2,5,clock_timestamp())`, second.Attempt.ID.String(), int64(a.PlayerID))
	exec(t, pool, `INSERT INTO adventure_attempt_settlements(attempt_id,player_id,damage,settled_at)VALUES($1,$2,5,clock_timestamp())`, second.Attempt.ID.String(), int64(a.PlayerID))
	for _, table := range []string{"worldboss_attempt_settlements", "illusion_attempt_settlements", "adventure_attempt_settlements"} {
		if _, err = pool.Raw().Exec(ctx, `UPDATE `+table+` SET damage=damage+1 WHERE attempt_id=$1`, second.Attempt.ID.String()); err == nil {
			t.Fatalf("R5D-01 %s accepted UPDATE", table)
		}
		if _, err = pool.Raw().Exec(ctx, `DELETE FROM `+table+` WHERE attempt_id=$1`, second.Attempt.ID.String()); err == nil {
			t.Fatalf("R5D-01 %s accepted DELETE", table)
		}
	}
}
