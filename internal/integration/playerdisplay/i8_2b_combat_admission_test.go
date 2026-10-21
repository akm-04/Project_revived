//go:build postgres

package playerdisplay_test

import (
	"errors"
	"fmt"
	"reflect"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/combatworker"
	combat "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/combat"
)

// H-39/H-11 soak on R2 PostgreSQL with the real worker binary: a burst wider
// than the pool is refused without touching the attempt row, and every
// attempt still resolves exactly once afterwards.
func TestI8_2BCombatAdmissionSoakNative(t *testing.T) {
	const attempts, workers = 8, 2
	pool := pool(t)
	server := rankingServer(t, pool)
	a, rev, ref := combatOwner(t, pool, server)
	s := combatService(t, pool)
	launcher := combatworker.New(combatLimits(t), workers, 300*time.Millisecond)
	t.Cleanup(launcher.Close)
	s.Worker = launcher
	staged := make([]d.Attempt, attempts)
	for i := range staged {
		name := fmt.Sprintf("soak-%d", i)
		locator := d.Locator{DomainKind: "i8-2b-fixture-mode", AuthorityScope: "admission", DomainLocator: fmt.Sprintf("%d/%s", a.PlayerID, name)}
		started, err := fixtureStart(t, s, rev, combat.StartRequest{Actor: a, Locator: locator, GenerationRef: "g", StartFingerprint: fingerprint(name), Battle: combat.BattleRequest{CampaignType: 1,
			TeamA: []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: a.PlayerID, Identity: ref.PartnerID}}, WavesB: [][]combat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}, pool)
		if err != nil {
			t.Fatal(name, err)
		}
		staged[i] = started.Attempt
	}
	before := combatRows(t, pool)
	errs := make([]error, attempts)
	var burst sync.WaitGroup
	for i := range staged {
		burst.Add(1)
		go func(i int) {
			defer burst.Done()
			_, errs[i] = s.Resolve(ctx, op(), staged[i].ID)
		}(i)
	}
	burst.Wait()
	saturated := 0
	for i, err := range errs {
		if err == nil {
			continue
		}
		if !errors.Is(err, combat.ErrWorkerSaturated) {
			t.Fatalf("attempt %d: %v", i, err)
		}
		saturated++
		current, _, readErr := s.Store.ReadAttemptTx(ctx, pool, staged[i].ID)
		if readErr != nil || !reflect.DeepEqual(current, staged[i]) {
			t.Fatalf("saturation touched attempt %d: %+v %v", i, current, readErr)
		}
	}
	if saturated == 0 || saturated > attempts-workers {
		t.Fatalf("burst of %d over %d workers saturated %d", attempts, workers, saturated)
	}
	for i, err := range errs {
		for err != nil {
			_, err = s.Resolve(ctx, op(), staged[i].ID)
			if err != nil && !errors.Is(err, combat.ErrWorkerSaturated) {
				t.Fatalf("retry %d: %v", i, err)
			}
		}
	}
	after := combatRows(t, pool)
	if after[0] != before[0] || after[1] != before[1] || after[2] != before[2]+attempts {
		t.Fatal("rows", before, after)
	}
	for i := range staged {
		first, err := s.Resolve(ctx, op(), staged[i].ID)
		if err != nil || first.Attempt.State != d.ResolutionReady || first.Attempt.ResolverFailure != "" {
			t.Fatalf("attempt %d resolved more or less than once: %+v %v", i, first.Attempt, err)
		}
	}
	t.Logf("burst of %d over %d workers: %d refused, all resolved once", attempts, workers, saturated)
}
