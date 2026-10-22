//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	combat "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// fixtureDodgeballPolicy is a Dodgeball-shaped family (D9 Q3): a throw draw and
// a friend-throw gate draw per throw; lengths are private policy (D20).
var fixtureDodgeballPolicy = d.DrawPolicy{ID: "FIXTURE_DODGEBALL_DRAWS_V1", Version: 1, Streams: []d.DrawStream{{Name: "self_rd", Length: 40, Low: 1, High: d.PermilleScale}, {Name: "friend_rd", Length: 40, Low: 1, High: d.PermilleScale}}}

// challengeStart is a battle-less Dodgeball START over three sandbag targets.
func (f kindFixture) challengeStart(stage, generation string) combat.StartRequest {
	request := f.request(stage, generation)
	request.Battle = combat.BattleRequest{}
	request.Challenge = &d.Challenge{Targets: []int64{1, 2, 1}}
	request.Package = func(stream *d.Stream) (any, error) {
		f.builds.Add(1)
		return fixtureDodgeballPolicy.Build(stream)
	}
	return request
}

func (f kindFixture) derivedRequest(generation string, policy d.DrawPolicy, derivation d.Derivation) combat.DerivedRequest {
	return combat.DerivedRequest{Locator: f.locator, GenerationRef: generation, TerminalKind: "FIXTURE_SETTLED", At: time.Now().UTC(), Policy: policy, Derivation: derivation}
}

func (f kindFixture) attestDerived(db tx.Beginner, request combat.DerivedRequest, attempts int) (combat.SummaryAttested, error) {
	var attested combat.SummaryAttested
	receipt := ""
	evidence := summaryEvidence{service: f.service, locator: request.Locator, receipt: &receipt}
	_, err := (tx.Runner{DB: db}).Run(ctx, opPinned(f.rev), combatTestProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: attempts, RetryDefiniteAbort: true}, evidence, func(c context.Context, scope tx.Scope) error {
		var err error
		attested, err = f.service.AttestDerivedTx(c, scope.Tx, request)
		receipt = attested.Attempt.SemanticReceiptID
		return err
	})
	return attested, err
}

func (f kindFixture) endPractice(generation string) (combat.PracticeEnded, error) {
	var ended combat.PracticeEnded
	request := combat.PracticeRequest{Locator: f.locator, GenerationRef: generation, At: time.Now().UTC()}
	_, err := (tx.Runner{DB: f.pool}).Run(ctx, opPinned(f.rev), combatTestProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, scope tx.Scope) error {
		var err error
		ended, err = f.service.EndPracticeTx(c, scope.Tx, request)
		return err
	})
	return ended, err
}

// drawPackage is the stored START package of the attempt.
func drawPackage(t *testing.T, started combat.Started) d.DrawPackage {
	t.Helper()
	pack, err := d.DecodeDrawPackage(*started.Package)
	if err != nil || !fixtureDodgeballPolicy.Issued(pack) {
		t.Fatal("stored draw package", err)
	}
	return pack
}

// honest claims what the stock window derives with certainty: a target hit at
// probability 1000 and the friend gate at its own draw.
func honest(pack d.DrawPackage) d.Derivation {
	return d.Derivation{Claims: []d.DrawClaim{
		{Stream: "self_rd", Index: 1, Target: 2, Permille: d.PermilleScale},
		{Stream: "friend_rd", Index: 1, Permille: pack.Streams["friend_rd"][0]},
		{Stream: "friend_rd", Index: 1, Target: 3, Permille: d.PermilleScale},
	}}
}

// PASS420 DODGEBALL binding through one locator: START stores the draws and
// the policy version, a lost START returns the same entropy, RESULT is judged
// against the stored draws and a duplicate RESULT converges.
func TestI8_5CServerEntropyAttemptNative(t *testing.T) {
	f := newKindFixture(t, "server-entropy")
	before := f.counts(t)
	missing := f.challengeStart("stage-0", "g0")
	missing.Package = nil
	if _, err := f.start(missing, 1); !errors.Is(err, d.ErrInvalid) || f.counts(t) != before {
		t.Fatal("an entropy START without a package must be refused before any write", err)
	}
	first, err := f.start(f.challengeStart("stage-1", "g1"), 3)
	if err != nil || first.Attempt.TrustProfile != d.ServerEntropyClientDerived || first.Package == nil {
		t.Fatal("challenge START", first, err)
	}
	if snapshot := f.frozen(t, first.Attempt); snapshot.Challenge == nil || len(snapshot.Challenge.Targets) != 3 || len(snapshot.Battle.TeamA) != 0 || snapshot.ProducerProfile != "" {
		t.Fatal("frozen challenge snapshot", snapshot.Challenge)
	}
	pack := drawPackage(t, first)
	builds := f.builds.Load()
	again, err := f.start(f.challengeStart("stage-1", "g1"), 3)
	if err != nil || !again.Replayed || again.Attempt.ID != first.Attempt.ID || !bytes.Equal(again.Package.Canonical, first.Package.Canonical) || f.builds.Load() != builds {
		t.Fatal("lost START must return the same entropy without drawing", err)
	}
	if _, err = f.attestSummary(f.pool, f.summaryRequest("g1", fixtureCampaignPolicy, f.summary(0, 3)), 1); !errors.Is(err, d.ErrStale) {
		t.Fatal("a summary RESULT must not close an entropy attempt", err)
	}
	before = f.counts(t)
	upgraded := fixtureDodgeballPolicy
	upgraded.Version = 2
	if _, err = f.attestDerived(f.pool, f.derivedRequest("g1", upgraded, honest(pack)), 1); !errors.Is(err, d.ErrStale) || f.counts(t) != before {
		t.Fatal("a RESULT under another policy version must be stale with zero writes", err)
	}
	accepted, err := f.attestDerived(f.pool, f.derivedRequest("g1", fixtureDodgeballPolicy, honest(pack)), 1)
	if err != nil || accepted.Drained || accepted.Attestation.Verdict != d.VerdictAccepted || accepted.Attempt.TerminalKind != "FIXTURE_SETTLED" || accepted.Attempt.SemanticReceiptID != "attest:"+first.Attempt.ID.String() {
		t.Fatal("accepted derivation", accepted, err)
	}
	if accepted.Attestation.ValidatorID != fixtureDodgeballPolicy.ID || storedReason(t, accepted.Attestation) != "" || f.counts(t) != [3]int{before[0], before[1], before[2] + 1} {
		t.Fatal("stored CLIENT_ATTESTED derivation", accepted.Attestation)
	}
	before = f.counts(t)
	if got, err := f.attestDerived(f.pool, f.derivedRequest("g1", fixtureDodgeballPolicy, honest(pack)), 1); err != nil || !got.Drained || f.counts(t) != before {
		t.Fatal("duplicate RESULT", got, err)
	}
	rejections := map[string]func(d.DrawPackage, *d.Derivation){
		"STREAM_UNKNOWN": func(_ d.DrawPackage, v *d.Derivation) { v.Claims[0].Stream = "boss_rd" },
		"INDEX_OUT_OF_RANGE": func(_ d.DrawPackage, v *d.Derivation) {
			v.Claims[0].Index = fixtureDodgeballPolicy.Streams[0].Length + 1
		},
		"TARGET_UNKNOWN":   func(_ d.DrawPackage, v *d.Derivation) { v.Claims[0].Target = 4 },
		"TARGET_DUPLICATE": func(_ d.DrawPackage, v *d.Derivation) { v.Claims[2].Target = 2 },
		"GATE_DUPLICATE":   func(_ d.DrawPackage, v *d.Derivation) { v.Claims = append(v.Claims, v.Claims[1]) },
		"DRAW_ABOVE_CLAIM": func(p d.DrawPackage, v *d.Derivation) {
			v.Claims[1].Permille = p.Streams["friend_rd"][0] - 1
		},
	}
	stage := 2
	for reason, mutate := range rejections {
		started, err := f.start(f.challengeStart(string(rune('a'+stage)), "g1"), 3)
		stage++
		if err != nil {
			t.Fatal(err)
		}
		draws := drawPackage(t, started)
		if reason == "DRAW_ABOVE_CLAIM" && draws.Streams["friend_rd"][0] == 0 {
			t.Fatal("fixture draws start at 1")
		}
		derivation := honest(draws)
		mutate(draws, &derivation)
		got, err := f.attestDerived(f.pool, f.derivedRequest("g1", fixtureDodgeballPolicy, derivation), 1)
		if err != nil || got.Attempt.ID != started.Attempt.ID || got.Attestation.Verdict != d.VerdictRejected || got.Attempt.TerminalKind != d.RejectedKind || storedReason(t, got.Attestation) != reason {
			t.Fatal(reason, got, err)
		}
	}
	if n := f.counts(t); n != [3]int{1 + len(rejections), 1 + len(rejections), 1 + len(rejections)} {
		t.Fatal("rows", n)
	}
}

// H-03: concurrent duplicate derivations settle once; H-04: an ambiguous
// commit reconciles from the attempt's own receipt.
func TestI8_5CConcurrentAndAmbiguousDerivationNative(t *testing.T) {
	f := newKindFixture(t, "server-entropy-concurrency")
	started, err := f.start(f.challengeStart("stage", "g1"), 3)
	if err != nil {
		t.Fatal(err)
	}
	request := f.derivedRequest("g1", fixtureDodgeballPolicy, honest(drawPackage(t, started)))
	const racers = 6
	var wg sync.WaitGroup
	results := make([]combat.SummaryAttested, racers)
	errs := make([]error, racers)
	for i := range racers {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			results[i], errs[i] = f.attestDerived(f.pool, request, 4*racers)
		}(i)
	}
	wg.Wait()
	settled := 0
	for i := range racers {
		if errs[i] != nil {
			t.Fatal(i, errs[i])
		}
		if !results[i].Drained {
			settled++
		}
	}
	if settled != 1 || f.rows(t, "combat_attestations") != 1 {
		t.Fatal("one settlement", settled)
	}
	started, err = f.start(f.challengeStart("stage-2", "g1"), 3)
	if err != nil {
		t.Fatal(err)
	}
	request = f.derivedRequest("g1", fixtureDodgeballPolicy, honest(drawPackage(t, started)))
	var unknown *tx.UnknownCommitError
	if _, err = f.attestDerived(metricCommitDB{Beginner: f.pool, commit: false}, request, 1); !errors.As(err, &unknown) || f.rows(t, "combat_attestations") != 1 {
		t.Fatal("rolled-back ambiguous RESULT must stay unknown", err)
	}
	committed, err := f.attestDerived(metricCommitDB{Beginner: f.pool, commit: true}, request, 1)
	if err != nil || committed.Attestation.Verdict != d.VerdictAccepted || f.rows(t, "combat_attestations") != 2 {
		t.Fatal("ambiguous RESULT commit must reconcile from evidence", committed, err)
	}
	if again, err := f.attestDerived(f.pool, request, 1); err != nil || !again.Drained || f.rows(t, "combat_attestations") != 2 {
		t.Fatal("retry after a committed RESULT must not settle again", again, err)
	}
}

// H-28/HRC-50: a practice attempt closes as PRACTICE with no attestation, and
// no value-bearing RESULT path can close it.
func TestI8_5CPracticeSettlesNoValueNative(t *testing.T) {
	f := newKindFixture(t, "practice")
	practice := func(stage string) combat.StartRequest {
		request := f.request(stage, "g1")
		request.TrustProfile, request.Package = d.PracticeNoValue, nil
		return request
	}
	first, err := f.start(practice("stage-1"), 3)
	if err != nil || first.Attempt.TrustProfile != d.PracticeNoValue || first.Package != nil {
		t.Fatal("practice START", first, err)
	}
	before := f.counts(t)
	refusals := map[string]func() error{
		"attest": func() error { _, err := f.attest(f.attestRequest("g1", "practice-attest")); return err },
		"summary": func() error {
			_, err := f.attestSummary(f.pool, f.summaryRequest("g1", fixtureCampaignPolicy, f.summary(0, 3)), 1)
			return err
		},
		"report": func() error {
			_, err := f.attestReport(f.pool, f.reportRequest("g1", fixtureTreasurePolicy, f.report(0, true)), 1)
			return err
		},
		"derived": func() error {
			_, err := f.attestDerived(f.pool, f.derivedRequest("g1", fixtureDodgeballPolicy, d.Derivation{}), 1)
			return err
		},
	}
	for name, attempt := range refusals {
		if err = attempt(); err == nil || f.counts(t) != before {
			t.Fatal("a value-bearing RESULT closed a practice attempt", name)
		}
	}
	ended, err := f.endPractice("g1")
	if err != nil || ended.Drained || ended.Attempt.ID != first.Attempt.ID || ended.Attempt.TerminalKind != d.PracticeKind || ended.Attempt.State != d.Terminal {
		t.Fatal("end practice", ended, err)
	}
	if again, err := f.endPractice("g1"); err != nil || !again.Drained {
		t.Fatal("duplicate practice RESULT must drain", again, err)
	}
	if _, err = f.start(f.request("stage-2", "g1"), 3); err != nil {
		t.Fatal(err)
	}
	if _, err = f.endPractice("g1"); !errors.Is(err, d.ErrStale) {
		t.Fatal("a practice RESULT must not close a value-bearing attempt", err)
	}
	if n := f.counts(t); n != [3]int{2, 1, 0} {
		t.Fatal("rows: practice writes no package and no attestation", n)
	}
}
