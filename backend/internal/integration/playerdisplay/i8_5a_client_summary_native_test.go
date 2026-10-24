//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/combatstore"
	combat "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Fixture families (D9 Q3): a campaign-shaped family (star 0..3, win from
// star, no damage) and a boss-shaped family (damage bounded by frozen force).
var (
	fixtureCampaignPolicy = d.SummaryPolicy{ID: "FIXTURE_CAMPAIGN_SUMMARY_V1", Version: 1, MaxStar: 3, WinFromStar: true}
	fixtureBossPolicy     = d.SummaryPolicy{ID: "FIXTURE_BOSS_DAMAGE_V1", Version: 1, MaxDamage: 1_000_000_000_000_000, DamagePerForce: 1000}
)

const fixtureEnemy = 10001002

// summaryStart is a client-summary START: the hero in the given slot, one
// template enemy wave, a drop plan drawn from the START package stream.
func (f kindFixture) summaryStart(stage, generation string, formation []int64) combat.StartRequest {
	request := f.request(stage, generation)
	request.TrustProfile = d.ClientSummaryAttested
	request.Battle.Formation = formation
	return request
}

func (f kindFixture) slot(slot int) []int64 {
	formation := make([]int64, 6)
	formation[slot] = f.partner
	return formation
}

func (f kindFixture) summary(slot int, star int64) d.Summary {
	return d.Summary{Star: star, Win: star > 0, Alive: 1, Formation: f.slot(slot), Enemies: []d.EnemyStatus{{Identity: fixtureEnemy}}}
}

func (f kindFixture) summaryRequest(generation string, policy d.SummaryPolicy, summary d.Summary) combat.SummaryRequest {
	return combat.SummaryRequest{Locator: f.locator, GenerationRef: generation, TerminalKind: "FIXTURE_SETTLED", At: time.Now().UTC(), Policy: policy, Summary: summary}
}

// summaryEvidence reconciles an ambiguous RESULT commit from the positive
// postcondition only: the attested attempt is terminal under its own receipt.
type summaryEvidence struct {
	service combat.Service
	locator d.Locator
	receipt *string
}

func (e summaryEvidence) Resolve(c context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
	unknown := tx.Resolution{State: tx.ResolutionUnknown}
	if *e.receipt == "" {
		return unknown, nil
	}
	a, found, err := e.service.TerminalEvidenceTx(c, e.service.Fresh, e.locator, *e.receipt)
	if err != nil || !found {
		return unknown, err
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: a.SemanticReceiptID}, nil
}

func (f kindFixture) attestSummary(db tx.Beginner, request combat.SummaryRequest, attempts int) (combat.SummaryAttested, error) {
	var attested combat.SummaryAttested
	receipt := ""
	evidence := summaryEvidence{service: f.service, locator: request.Locator, receipt: &receipt}
	_, err := (tx.Runner{DB: db}).Run(ctx, opPinned(f.rev), combatTestProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: attempts, RetryDefiniteAbort: true}, evidence, func(c context.Context, scope tx.Scope) error {
		var err error
		attested, err = f.service.AttestSummaryTx(c, scope.Tx, request)
		receipt = attested.Attempt.SemanticReceiptID
		return err
	})
	return attested, err
}

func (f kindFixture) frozen(t *testing.T, attempt d.Attempt) d.Snapshot {
	t.Helper()
	raw, err := (combatstore.Store{}).ReadSnapshotTx(ctx, f.service.Fresh, attempt.SnapshotHash)
	if err != nil {
		t.Fatal(err)
	}
	snapshot, err := d.DecodeSnapshot(raw, attempt.SnapshotHash)
	if err != nil {
		t.Fatal(err)
	}
	return snapshot
}

func (f kindFixture) counts(t *testing.T) [3]int {
	return [3]int{f.rows(t, "combat_attempts"), f.rows(t, "combat_start_packages"), f.rows(t, "combat_attestations")}
}

func storedReason(t *testing.T, attestation d.Attestation) string {
	t.Helper()
	var record d.SummaryRecord
	if err := json.Unmarshal(attestation.Summary, &record); err != nil {
		t.Fatal(err)
	}
	return record.Reason
}

// H-01, H-02, H-41, H-05, H-45, H-06 and the deadline drain through one locator.
func TestI8_5AClientSummaryAttemptNative(t *testing.T) {
	f := newKindFixture(t, "client-summary")
	s := f.service
	unformed := f.summaryStart("stage-1", "g1", nil)
	if _, err := f.start(unformed, 1); !errors.Is(err, d.ErrInvalid) {
		t.Fatal("a client-summary START must freeze its formation", err)
	}
	if got, err := f.attestSummary(f.pool, f.summaryRequest("g1", fixtureCampaignPolicy, f.summary(0, 3)), 1); err != nil || !got.Drained {
		t.Fatal("RESULT without any attempt must drain", got, err)
	}
	first, err := f.start(f.summaryStart("stage-1", "g1", f.slot(0)), 3)
	if err != nil || first.Attempt.TrustProfile != d.ClientSummaryAttested || first.Attempt.ResolverStatus != d.ResolverNotRequired || first.Package == nil {
		t.Fatal("client-summary START", first, err)
	}
	snapshot := f.frozen(t, first.Attempt)
	if snapshot.TrustProfile != d.ClientSummaryAttested.ID || len(snapshot.Battle.Formation) != 6 || snapshot.Battle.Formation[0] != f.partner || len(snapshot.Battle.TeamA[0].BattleTotals) == 0 {
		t.Fatal("frozen formation and battle-facing projection", snapshot.Battle.Formation)
	}
	builds := f.builds.Load()
	// H-01/H-02: a repeated or retried START replays even with a changed formation (PASS120).
	moved, err := f.start(f.summaryStart("stage-1", "g1", f.slot(1)), 3)
	if err != nil || !moved.Replayed || moved.Attempt.ID != first.Attempt.ID || string(moved.Package.Canonical) != string(first.Package.Canonical) || f.builds.Load() != builds {
		t.Fatal("same-stage START must replay the frozen START", err)
	}
	if evidence, found, err := s.StartEvidenceTx(ctx, s.Fresh, f.locator, first.Attempt.StartFingerprint); err != nil || !found || evidence.ID != first.Attempt.ID {
		t.Fatal("lost START response evidence", found, err)
	}
	// H-41: the client fought with the moved formation; the frozen one decides.
	before := f.counts(t)
	rejected, err := f.attestSummary(f.pool, f.summaryRequest("g1", fixtureCampaignPolicy, f.summary(1, 3)), 1)
	if err != nil || rejected.Drained || rejected.Attestation.Verdict != d.VerdictRejected || rejected.Attempt.TerminalKind != d.RejectedKind || storedReason(t, rejected.Attestation) != "FORMATION_CHANGED" {
		t.Fatal("formation change after START", rejected, err)
	}
	if after := f.counts(t); after != [3]int{before[0], before[1], before[2] + 1} {
		t.Fatal("rejection writes one attestation", before, after)
	}
	// H-05: a duplicate after the terminal drains with zero writes; the attempt pins FightExist.
	before = f.counts(t)
	duplicate, err := f.attestSummary(f.pool, f.summaryRequest("g1", fixtureCampaignPolicy, f.summary(1, 3)), 1)
	if err != nil || !duplicate.Drained || f.counts(t) != before || rejected.Attempt.Replay != (d.ReplaySpec{Response: d.ReplayFightExist, ErrorCode: d.FightExistCode}) {
		t.Fatal("duplicate RESULT", duplicate, err)
	}
	second, err := f.start(f.summaryStart("stage-1", "g1", f.slot(0)), 3)
	if err != nil || second.Replayed || second.Attempt.ID == first.Attempt.ID || second.Superseded != nil {
		t.Fatal("a START after the terminal stages a new attempt", err)
	}
	// Deadline drain: a RESULT past the result deadline settles nothing.
	late := f.summaryRequest("g1", fixtureCampaignPolicy, f.summary(0, 3))
	late.At = second.Attempt.ResultDeadline.Add(time.Second)
	before = f.counts(t)
	if got, err := f.attestSummary(f.pool, late, 1); err != nil || !got.Drained || f.counts(t) != before {
		t.Fatal("RESULT past the deadline must drain", got, err)
	}
	accepted, err := f.attestSummary(f.pool, f.summaryRequest("g1", fixtureCampaignPolicy, f.summary(0, 3)), 1)
	if err != nil || accepted.Drained || accepted.Attestation.Verdict != d.VerdictAccepted || accepted.Attempt.TerminalKind != "FIXTURE_SETTLED" || accepted.Attempt.SemanticReceiptID != "attest:"+second.Attempt.ID.String() {
		t.Fatal("accepted summary", accepted, err)
	}
	stored, err := (combatstore.Store{}).ReadAttestationTx(ctx, s.Fresh, second.Attempt.ID)
	if err != nil || stored.ValidatorID != fixtureCampaignPolicy.ID || stored.ValidatorVersion != 1 || string(stored.Summary) != string(accepted.Attestation.Summary) {
		t.Fatal("stored CLIENT_ATTESTED summary", stored, err)
	}
	// H-45: a RESULT of another generation drains; the next START supersedes the stale attempt.
	stale, err := f.start(f.summaryStart("stage-2", "g2", f.slot(0)), 3)
	if err != nil {
		t.Fatal(err)
	}
	before = f.counts(t)
	if got, err := f.attestSummary(f.pool, f.summaryRequest("g3", fixtureCampaignPolicy, f.summary(0, 1)), 1); err != nil || !got.Drained || f.counts(t) != before {
		t.Fatal("late generation RESULT must drain", got, err)
	}
	current, err := f.start(f.summaryStart("stage-3", "g3", f.slot(2)), 3)
	if err != nil || current.Superseded == nil || current.Superseded.ID != stale.Attempt.ID || current.Superseded.TerminalKind != d.SupersededKind {
		t.Fatal("next generation START converges the stale attempt", err)
	}
	// H-06: an old RESULT shaped for the superseded attempt is judged against the newest snapshot.
	old, err := f.attestSummary(f.pool, f.summaryRequest("g3", fixtureCampaignPolicy, f.summary(0, 3)), 1)
	if err != nil || old.Attempt.ID != current.Attempt.ID || old.Attestation.Verdict != d.VerdictRejected || storedReason(t, old.Attestation) != "FORMATION_CHANGED" {
		t.Fatal("late old RESULT after a newer START", old, err)
	}
	if n := f.counts(t); n != [3]int{4, 4, 3} {
		t.Fatal("rows", n)
	}
}

// H-27: impossible values reject and close; the force bound uses the frozen projection.
func TestI8_5ABossDamageBoundsNative(t *testing.T) {
	f := newKindFixture(t, "boss-damage")
	started, err := f.start(f.summaryStart("boss", "g1", f.slot(0)), 3)
	if err != nil {
		t.Fatal(err)
	}
	var totals struct {
		Force float64 `json:"force"`
	}
	if err = json.Unmarshal(f.frozen(t, started.Attempt).Battle.TeamA[0].BattleTotals, &totals); err != nil || totals.Force <= 0 {
		t.Fatal("frozen force", totals, err)
	}
	above := f.summary(0, 0)
	above.Damage = int64(totals.Force)*fixtureBossPolicy.DamagePerForce + 1
	rejected, err := f.attestSummary(f.pool, f.summaryRequest("g1", fixtureBossPolicy, above), 1)
	if err != nil || rejected.Attestation.Verdict != d.VerdictRejected || storedReason(t, rejected.Attestation) != "DAMAGE_ABOVE_FORCE_BOUND" {
		t.Fatal("damage above the force bound", rejected, err)
	}
	if _, err = f.start(f.summaryStart("boss", "g1", f.slot(0)), 3); err != nil {
		t.Fatal(err)
	}
	unknown := f.summary(0, 0)
	unknown.Enemies = []d.EnemyStatus{{Identity: fixtureEnemy + 1}}
	if got, err := f.attestSummary(f.pool, f.summaryRequest("g1", fixtureBossPolicy, unknown), 1); err != nil || storedReason(t, got.Attestation) != "ENEMY_UNKNOWN" {
		t.Fatal("unknown enemy", got, err)
	}
	if _, err = f.start(f.summaryStart("boss", "g1", f.slot(0)), 3); err != nil {
		t.Fatal(err)
	}
	within := f.summary(0, 0)
	within.Damage = int64(totals.Force) * fixtureBossPolicy.DamagePerForce
	if got, err := f.attestSummary(f.pool, f.summaryRequest("g1", fixtureBossPolicy, within), 1); err != nil || got.Attestation.Verdict != d.VerdictAccepted {
		t.Fatal("damage within the force bound", got, err)
	}
}

// H-03: concurrent duplicate RESULTs settle once; the rest drain.
func TestI8_5AConcurrentDuplicateResultNative(t *testing.T) {
	f := newKindFixture(t, "concurrent-result")
	if _, err := f.start(f.summaryStart("stage", "g1", f.slot(0)), 3); err != nil {
		t.Fatal(err)
	}
	const racers = 6
	var wg sync.WaitGroup
	results := make([]combat.SummaryAttested, racers)
	errs := make([]error, racers)
	for i := range racers {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			results[i], errs[i] = f.attestSummary(f.pool, f.summaryRequest("g1", fixtureCampaignPolicy, f.summary(0, 3)), 4*racers)
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
}

// H-04: an ambiguous RESULT commit reconciles from the attempt's own receipt;
// one that rolled back stays unknown and a retry settles exactly once.
func TestI8_5AAmbiguousResultCommitNative(t *testing.T) {
	f := newKindFixture(t, "ambiguous-result")
	if _, err := f.start(f.summaryStart("stage", "g1", f.slot(0)), 3); err != nil {
		t.Fatal(err)
	}
	request := f.summaryRequest("g1", fixtureCampaignPolicy, f.summary(0, 2))
	var unknown *tx.UnknownCommitError
	if _, err := f.attestSummary(metricCommitDB{Beginner: f.pool, commit: false}, request, 1); !errors.As(err, &unknown) || f.rows(t, "combat_attestations") != 0 {
		t.Fatal("rolled-back ambiguous RESULT must stay unknown", err)
	}
	committed, err := f.attestSummary(metricCommitDB{Beginner: f.pool, commit: true}, request, 1)
	if err != nil || committed.Attestation.Verdict != d.VerdictAccepted || f.rows(t, "combat_attestations") != 1 {
		t.Fatal("ambiguous RESULT commit must reconcile from evidence", committed, err)
	}
	if again, err := f.attestSummary(f.pool, request, 1); err != nil || !again.Drained || f.rows(t, "combat_attestations") != 1 {
		t.Fatal("retry after a committed RESULT must not settle again", again, err)
	}
}
