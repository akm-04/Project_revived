//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"math"
	"sync"
	"testing"
	"time"

	combat "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Fixture families (D9 Q3): a March-shaped family (formation carried, a win
// clears every enemy, hp bounded by the frozen HP attribute) and a
// Treasure-shaped family (no formation; absolute hp cap only).
var (
	fixtureMarchPolicy    = d.ReportPolicy{ID: "FIXTURE_MARCH_REPORT_V1", Version: 1, Formation: true, WinClearsEnemies: true, MaxHP: 1e15, HPPerFrozen: 3}
	fixtureTreasurePolicy = d.ReportPolicy{ID: "FIXTURE_TREASURE_REPORT_V1", Version: 1, MaxHP: 1e15}
)

func (f kindFixture) reportStart(stage, generation string, formation []int64) combat.StartRequest {
	request := f.request(stage, generation)
	request.TrustProfile = d.ClientFullReportAttested
	request.Battle.Formation = formation
	return request
}

func (f kindFixture) report(slot int, win bool) d.Report {
	enemyHP := 1.0
	if win {
		enemyHP = 0
	}
	return d.Report{Win: win, Formation: f.slot(slot), Allies: []d.ActorStatus{{Player: int64(f.actor.PlayerID), Identity: f.partner, HP: 1234.5, MP: 1000, Reborn: 1}},
		Enemies: []d.ActorStatus{{Identity: fixtureEnemy, HP: enemyHP, MP: 250}}}
}

func (f kindFixture) reportRequest(generation string, policy d.ReportPolicy, report d.Report) combat.ReportRequest {
	return combat.ReportRequest{Locator: f.locator, GenerationRef: generation, TerminalKind: "FIXTURE_SETTLED", At: time.Now().UTC(), Policy: policy, Report: report}
}

func (f kindFixture) attestReport(db tx.Beginner, request combat.ReportRequest, attempts int) (combat.SummaryAttested, error) {
	var attested combat.SummaryAttested
	receipt := ""
	evidence := summaryEvidence{service: f.service, locator: request.Locator, receipt: &receipt}
	_, err := (tx.Runner{DB: db}).Run(ctx, opPinned(f.rev), combatTestProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: attempts, RetryDefiniteAbort: true}, evidence, func(c context.Context, scope tx.Scope) error {
		var err error
		attested, err = f.service.AttestReportTx(c, scope.Tx, request)
		receipt = attested.Attempt.SemanticReceiptID
		return err
	})
	return attested, err
}

// frozenHPAttribute is the owner's frozen HP attribute (battle_totals.total[3]).
func (f kindFixture) frozenHPAttribute(t *testing.T, attempt d.Attempt) float64 {
	t.Helper()
	var totals struct {
		Total []float64 `json:"total"`
	}
	if err := json.Unmarshal(f.frozen(t, attempt).Battle.TeamA[0].BattleTotals, &totals); err != nil || len(totals.Total) < 4 || totals.Total[3] <= 0 {
		t.Fatal("frozen HP attribute", totals, err)
	}
	return totals.Total[3]
}

// Accept, H-05 drain, H-42/H-43 rejections, non-finite refusal and the
// cross-profile guard through one March-shaped locator.
func TestI8_5BFullReportAttemptNative(t *testing.T) {
	f := newKindFixture(t, "full-report")
	first, err := f.start(f.reportStart("stage-1", "g1", f.slot(0)), 3)
	if err != nil || first.Attempt.TrustProfile != d.ClientFullReportAttested || first.Attempt.ResolverStatus != d.ResolverNotRequired || first.Package == nil {
		t.Fatal("client full-report START", first, err)
	}
	if snapshot := f.frozen(t, first.Attempt); snapshot.TrustProfile != d.ClientFullReportAttested.ID || snapshot.Battle.Formation[0] != f.partner {
		t.Fatal("frozen full-report snapshot", snapshot.TrustProfile)
	}
	if _, err = f.attestSummary(f.pool, f.summaryRequest("g1", fixtureCampaignPolicy, f.summary(0, 3)), 1); !errors.Is(err, d.ErrStale) {
		t.Fatal("a summary RESULT must not close a full-report attempt", err)
	}
	// H-43 codec: an overflowing literal never decodes; a non-finite value is refused with zero writes.
	if err = json.Unmarshal([]byte(`{"allies":[{"identity":1,"hp":1e400}]}`), &d.Report{}); err == nil {
		t.Fatal("the JSON codec must refuse an overflowing number")
	}
	before := f.counts(t)
	nonFinite := f.report(0, true)
	nonFinite.Allies[0].HP = math.Inf(1)
	if _, err = f.attestReport(f.pool, f.reportRequest("g1", fixtureMarchPolicy, nonFinite), 1); !errors.Is(err, d.ErrInvalid) || f.counts(t) != before {
		t.Fatal("non-finite report must be refused before any write", err)
	}
	accepted, err := f.attestReport(f.pool, f.reportRequest("g1", fixtureMarchPolicy, f.report(0, true)), 1)
	if err != nil || accepted.Drained || accepted.Attestation.Verdict != d.VerdictAccepted || accepted.Attempt.TerminalKind != "FIXTURE_SETTLED" || accepted.Attempt.SemanticReceiptID != "attest:"+first.Attempt.ID.String() {
		t.Fatal("accepted report", accepted, err)
	}
	if accepted.Attestation.ValidatorID != fixtureMarchPolicy.ID || storedReason(t, accepted.Attestation) != "" || f.counts(t) != [3]int{before[0], before[1], before[2] + 1} {
		t.Fatal("stored CLIENT_ATTESTED report", accepted.Attestation)
	}
	// H-05: a duplicate after the terminal drains with zero writes.
	before = f.counts(t)
	if got, err := f.attestReport(f.pool, f.reportRequest("g1", fixtureMarchPolicy, f.report(0, true)), 1); err != nil || !got.Drained || f.counts(t) != before {
		t.Fatal("duplicate RESULT", got, err)
	}
	frozenHP := f.frozenHPAttribute(t, first.Attempt)
	rejections := map[string]func(*d.Report){
		"ALLY_UNKNOWN":          func(r *d.Report) { r.Allies[0].Identity++ },
		"ALLY_MISSING":          func(r *d.Report) { r.Allies = nil },
		"ENEMY_UNKNOWN":         func(r *d.Report) { r.Enemies[0].Identity++ },
		"HP_ABOVE_FROZEN_BOUND": func(r *d.Report) { r.Allies[0].HP = frozenHP*fixtureMarchPolicy.HPPerFrozen + 0.5 },
		"MP_OUT_OF_RANGE":       func(r *d.Report) { r.Enemies[0].MP = 1001 },
		"WIN_WITH_ENEMY_ALIVE":  func(r *d.Report) { r.Enemies[0].HP = 1 },
		"FORMATION_CHANGED":     func(r *d.Report) { r.Formation = f.slot(1) },
	}
	stage := 2
	for reason, mutate := range rejections {
		started, err := f.start(f.reportStart(string(rune('a'+stage)), "g1", f.slot(0)), 3)
		stage++
		if err != nil {
			t.Fatal(err)
		}
		report := f.report(0, true)
		mutate(&report)
		got, err := f.attestReport(f.pool, f.reportRequest("g1", fixtureMarchPolicy, report), 1)
		if err != nil || got.Attempt.ID != started.Attempt.ID || got.Attestation.Verdict != d.VerdictRejected || got.Attempt.TerminalKind != d.RejectedKind || storedReason(t, got.Attestation) != reason {
			t.Fatal(reason, got, err)
		}
	}
	// A Treasure-shaped family carries no formation and no frozen ratio; a loss is a valid report.
	treasure, err := f.start(f.reportStart("treasure", "g1", nil), 3)
	if err != nil {
		t.Fatal(err)
	}
	loss := f.report(0, false)
	loss.Formation, loss.Allies[0].HP = nil, frozenHP*10
	if got, err := f.attestReport(f.pool, f.reportRequest("g1", fixtureTreasurePolicy, loss), 1); err != nil || got.Attempt.ID != treasure.Attempt.ID || got.Attestation.Verdict != d.VerdictAccepted {
		t.Fatal("treasure-shaped loss", got, err)
	}
	if n := f.counts(t); n != [3]int{2 + len(rejections), 2 + len(rejections), 2 + len(rejections)} {
		t.Fatal("rows", n)
	}
}

// H-03: concurrent duplicate full reports settle once; H-04: an ambiguous
// commit reconciles from the attempt's own receipt.
func TestI8_5BConcurrentAndAmbiguousReportNative(t *testing.T) {
	f := newKindFixture(t, "full-report-concurrency")
	if _, err := f.start(f.reportStart("stage", "g1", f.slot(0)), 3); err != nil {
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
			results[i], errs[i] = f.attestReport(f.pool, f.reportRequest("g1", fixtureMarchPolicy, f.report(0, true)), 4*racers)
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
	if _, err := f.start(f.reportStart("stage-2", "g1", f.slot(0)), 3); err != nil {
		t.Fatal(err)
	}
	request := f.reportRequest("g1", fixtureMarchPolicy, f.report(0, false))
	var unknown *tx.UnknownCommitError
	if _, err := f.attestReport(metricCommitDB{Beginner: f.pool, commit: false}, request, 1); !errors.As(err, &unknown) || f.rows(t, "combat_attestations") != 1 {
		t.Fatal("rolled-back ambiguous RESULT must stay unknown", err)
	}
	committed, err := f.attestReport(metricCommitDB{Beginner: f.pool, commit: true}, request, 1)
	if err != nil || committed.Attestation.Verdict != d.VerdictAccepted || f.rows(t, "combat_attestations") != 2 {
		t.Fatal("ambiguous RESULT commit must reconcile from evidence", committed, err)
	}
	if again, err := f.attestReport(f.pool, request, 1); err != nil || !again.Drained || f.rows(t, "combat_attestations") != 2 {
		t.Fatal("retry after a committed RESULT must not settle again", again, err)
	}
}
