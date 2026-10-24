//go:build postgres

package playerdisplay_test

import (
	"errors"
	"fmt"
	"sync"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/combatstore"
	combat "gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
)

// Fight 10000 is one wave of five monsters; fight 19007 carries the assist
// partners [80136130, 99990002] and three monster waves.
const singleWaveFight, assistFight = 10000, 19007

type lineupFixture struct {
	pool    *pg.Pool
	rev     string
	service combat.Service
	owner   identity.ActorContext
	hero    character.HeroRef
}

func newLineupFixture(t *testing.T) lineupFixture {
	pool := pool(t)
	f := lineupFixture{pool: pool, service: combatService(t, pool)}
	f.owner, f.rev, f.hero = combatOwner(t, pool, rankingServer(t, pool))
	return f
}

// request fights the owner's Hero beside the assist partner against the waves
// of fight, all from the shared D23b provider.
func (f lineupFixture) request(t *testing.T, scope string, fight int64) combat.StartRequest {
	t.Helper()
	waves := must(combat.MonsterWaves(f.service.Rules, fight))(t, "monster waves")
	trial := must(combat.AssistTrial(f.service.Rules, assistFight, 1))(t, "assist trial")
	locator := d.Locator{DomainKind: "i8-6b-fixture-mode", AuthorityScope: scope, DomainLocator: fmt.Sprint(f.owner.PlayerID)}
	return combat.StartRequest{Actor: f.owner, Locator: locator, GenerationRef: "fixture-generation-1", StartFingerprint: fingerprint(locator.AuthorityScope + locator.DomainLocator),
		Battle: combat.BattleRequest{CampaignType: 1, BattleID: fight,
			TeamA:  []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: f.owner.PlayerID, Identity: f.hero.PartnerID}, trial},
			WavesB: waves}}
}

func (f lineupFixture) snapshot(t *testing.T, attempt d.Attempt) d.Snapshot {
	t.Helper()
	raw := must((combatstore.Store{}).ReadSnapshotTx(ctx, f.pool, attempt.SnapshotHash))(t, "snapshot")
	return must(d.DecodeSnapshot(raw, attempt.SnapshotHash))(t, "decode")
}

func (f lineupFixture) attempts(t *testing.T) int64 {
	return scalar(t, f.pool, `SELECT count(*) FROM combat_attempts WHERE domain_kind='i8-6b-fixture-mode' AND domain_locator=$1`, fmt.Sprint(f.owner.PlayerID))
}

func (f lineupFixture) ownerState(t *testing.T) [2]int64 {
	return [2]int64{
		scalar(t, f.pool, `SELECT count(*) FROM player_heroes WHERE player_id=$1`, int64(f.owner.PlayerID)),
		scalar(t, f.pool, `SELECT coalesce(sum(state_version), 0) FROM player_heroes WHERE player_id=$1`, int64(f.owner.PlayerID)),
	}
}

// B7-01..B7-03: TRIAL and table-shaped monster waves through START, resolve
// and terminal; refusals write nothing; multi-wave stays client-run (D23).
func TestI8_6BTrialLineupNative(t *testing.T) {
	f := newLineupFixture(t)
	s := f.service
	owner := f.ownerState(t)

	// B7-01: the assist partner freezes as a TRIAL with the provider's
	// provenance, the monsters as table-shaped TEMPLATE rows; the fight
	// resolves and settles without the owner gaining or changing a Hero.
	request := f.request(t, "trial", singleWaveFight)
	started := must(fixtureStart(t, s, f.rev, request, f.pool))(t, "trial START")
	snapshot := f.snapshot(t, started.Attempt)
	trial := snapshot.Battle.TeamA[1]
	if trial.Origin != d.Trial || trial.Player != 0 || trial.Identity != 80136130 || trial.Provenance == nil ||
		trial.Provenance.Capability != combat.AssistCapability || trial.Provenance.Reference != "battle/19007/1" || !d.TableShaped(trial.Params) {
		t.Fatalf("B7-01 trial actor %+v", trial)
	}
	if len(snapshot.Battle.WavesB) != 1 || len(snapshot.Battle.WavesB[0]) != 5 || snapshot.Battle.WavesB[0][0].Identity != 90000006 || !d.TableShaped(snapshot.Battle.WavesB[0][0].Params) {
		t.Fatal("B7-01 monster wave", snapshot.Battle.WavesB)
	}
	resolved := must(s.Resolve(ctx, op(), started.Attempt.ID))(t, "resolve")
	if resolved.Resolution.Outcome.Frames <= 0 {
		t.Fatal("B7-01 resolution", resolved.Resolution.Outcome)
	}
	settled := must(fixtureTerminal(t, s, f.pool, f.owner, request.Locator, "i8-6b-receipt", f.pool, opPinned(f.rev)))(t, "terminal")
	if settled.Attempt.State != d.Terminal || f.ownerState(t) != owner {
		t.Fatal("B7-01 the owner must never own or change through the TRIAL", owner, f.ownerState(t))
	}

	// B7-02: a TRIAL without provenance, with an owner or on side B, a
	// table-shaped Pet, a monster in full partner params and a wave id with no
	// source row refuse START with zero writes; an unknown fight has no lineup.
	before := f.attempts(t)
	unknownWave := must(combat.MonsterWaves(s.Rules, 9820001))(t, "9820001 waves")
	refusals := map[string]struct {
		mutate func(*combat.StartRequest)
		want   error
	}{
		"trial without provenance": {func(r *combat.StartRequest) { r.Battle.TeamA[1].Provenance = nil }, d.ErrInvalid},
		"trial with owner":         {func(r *combat.StartRequest) { r.Battle.TeamA[1].Player = f.owner.PlayerID }, d.ErrInvalid},
		"trial enemy": {func(r *combat.StartRequest) {
			r.Battle.WavesB[0] = append(r.Battle.WavesB[0], r.Battle.TeamA[1])
			r.Battle.TeamA = r.Battle.TeamA[:1]
		}, d.ErrInvalid},
		"table-shaped pet": {func(r *combat.StartRequest) {
			r.Battle.PetsA = []combat.Participant{{Origin: d.Template, Kind: d.PetActor, Identity: 90000006, TemplateParams: map[string]any{"table_id": 90000006}}}
		}, d.ErrInvalid},
		"monster in partner params": {func(r *combat.StartRequest) {
			r.Battle.WavesB[0][0] = combat.Participant{Origin: d.Template, Kind: d.HeroActor, Identity: 90000006, TemplateParams: templateParams(90000006)}
		}, d.ErrClassUnavailable},
		"wave id without source row": {func(r *combat.StartRequest) { r.Battle.WavesB = unknownWave }, d.ErrClassUnavailable},
	}
	for name, refusal := range refusals {
		r := f.request(t, "refused-"+name, singleWaveFight)
		refusal.mutate(&r)
		if _, err := fixtureStart(t, s, f.rev, r, f.pool); !errors.Is(err, refusal.want) {
			t.Fatal("B7-02", name, err)
		}
	}
	if _, err := combat.MonsterWaves(s.Rules, 1); !errors.Is(err, d.ErrInvalid) {
		t.Fatal("B7-02 unknown fight", err)
	}
	if _, err := combat.AssistTrial(s.Rules, singleWaveFight, 1); !errors.Is(err, d.ErrInvalid) {
		t.Fatal("B7-02 fight without assist partners", err)
	}
	if f.attempts(t) != before || f.ownerState(t) != owner {
		t.Fatal("B7-02 a refused lineup wrote", f.attempts(t), before)
	}

	// B7-03 (D23f): a multi-wave lineup freezes every wave for the attested
	// summary judge, and the server resolver refuses it permanently.
	multi := must(fixtureStart(t, s, f.rev, f.request(t, "multi-wave", assistFight), f.pool))(t, "multi-wave START")
	if waves := f.snapshot(t, multi.Attempt).Battle.WavesB; len(waves) != 3 {
		t.Fatal("B7-03 waves", len(waves))
	}
	if _, err := s.Resolve(ctx, op(), multi.Attempt.ID); !errors.Is(err, d.ErrResolverPermanent) {
		t.Fatal("B7-03 multi-wave must be refused permanently", err)
	}
}

// B7-04: concurrent STARTs of one lineup converge on one attempt and one
// frozen snapshot.
func TestI8_6BConcurrentLineupStartNative(t *testing.T) {
	f := newLineupFixture(t)
	request := f.request(t, "concurrent", singleWaveFight)
	var wait sync.WaitGroup
	results := make([]combat.Started, 4)
	failures := make([]error, len(results))
	for i := range results {
		wait.Add(1)
		go func() {
			defer wait.Done()
			results[i], failures[i] = fixtureStart(t, f.service, f.rev, request, f.pool)
		}()
	}
	wait.Wait()
	for i, started := range results {
		if failures[i] != nil || started.Attempt.ID != results[0].Attempt.ID || started.Attempt.SnapshotHash != results[0].Attempt.SnapshotHash {
			t.Fatal("B7-04 concurrent START diverged", i, failures[i])
		}
	}
	if f.attempts(t) != 1 {
		t.Fatal("B7-04 attempts", f.attempts(t))
	}
}
