//go:build postgres

package playerdisplay_test

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/combatkeys"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/combatstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	combat "gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// I8-7 report lifecycle (I8_REPORT_LIFECYCLE_V1, D25): the PASS418 H-rows for
// retention, corpus upgrade, key rotation, store failure, settlement atomicity,
// revocation, expiry and lost or duplicate notifications.

type lifecycleFixture struct {
	pool *pg.Pool
	s    combat.Service
	a    identity.ActorContext
	rev  string
	ref  character.HeroRef
}

func newLifecycle(t *testing.T) lifecycleFixture {
	t.Helper()
	p := pool(t)
	a, rev, ref := combatOwner(t, p, rankingServer(t, p))
	return lifecycleFixture{pool: p, s: combatService(t, p), a: a, rev: rev, ref: ref}
}

func (f lifecycleFixture) locator(name string) d.Locator {
	return d.Locator{DomainKind: "i8-7-lifecycle-fixture", AuthorityScope: "lifecycle", DomainLocator: fmt.Sprintf("%d/%s", f.a.PlayerID, name)}
}

func (f lifecycleFixture) start(t *testing.T, s combat.Service, name string) d.Attempt {
	t.Helper()
	request := combat.StartRequest{Actor: f.a, Locator: f.locator(name), GenerationRef: "fixture-generation-1", StartFingerprint: fingerprint(name), Battle: combat.BattleRequest{CampaignType: 1,
		TeamA: []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: f.a.PlayerID, Identity: f.ref.PartnerID}}, WavesB: [][]combat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}
	started, err := fixtureStart(t, s, f.rev, request, f.pool)
	if err != nil {
		t.Fatal(name, err)
	}
	return started.Attempt
}

func (f lifecycleFixture) ready(t *testing.T, name string) combat.Resolved {
	t.Helper()
	resolved, err := f.s.Resolve(ctx, op(), f.start(t, f.s, name).ID)
	if err != nil {
		t.Fatal(name, err)
	}
	return resolved
}

// settle is a mode RESULT transaction: before runs ahead of Combat TERMINAL
// (the liveness fence), after runs once the I5 Grant is written (fault injection).
func (f lifecycleFixture) settle(name, receipt string, before func(context.Context, tx.Scope) error, after func(tx.Scope) error) (combat.Settled, error) {
	var settled combat.Settled
	o := opPinned(f.rev)
	locator := f.locator(name)
	evidence := terminalEvidence{service: f.s, q: f.pool, locator: locator, receipt: receipt}
	_, err := (tx.Runner{DB: f.pool}).Run(ctx, o, combatTestProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, evidence, func(c context.Context, scope tx.Scope) error {
		var at time.Time
		if err := scope.Tx.QueryRow(c, "SELECT clock_timestamp()").Scan(&at); err != nil {
			return err
		}
		if err := before(c, scope); err != nil {
			return err
		}
		var err error
		settled, err = f.s.TerminalTx(c, scope.Tx, combat.TerminalRequest{Locator: locator, GenerationRef: "fixture-generation-1", TerminalKind: "FIXTURE_SETTLED", SemanticReceiptID: receipt, At: at})
		if err != nil || settled.Replayed {
			return err
		}
		plan := grant.Plan{PlayerID: f.a.PlayerID, Source: grant.SourceIdentity{Domain: "i8-7-lifecycle-fixture", Operation: "combat-terminal", BusinessKey: receipt, PolicyVersion: "i8-7-fixture-v1"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 50005013, Amount: 1}}}
		if _, err = combatGrant(f.pool).SettleGrantTx(c, scope.Tx, f.a, plan, o, i5.GrantTxOptions{}); err != nil {
			return err
		}
		return after(scope)
	})
	return settled, err
}

func (f lifecycleFixture) close(name, receipt string, at time.Time) (combat.Closed, error) {
	var closed combat.Closed
	_, err := (tx.Runner{DB: f.pool}).Run(ctx, opPinned(f.rev), combatTestProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, scope tx.Scope) error {
		var err error
		closed, err = f.s.CloseTx(c, scope.Tx, combat.TerminalRequest{Locator: f.locator(name), GenerationRef: "fixture-generation-1", TerminalKind: "FIXTURE_EXPIRED", SemanticReceiptID: receipt, At: at})
		return err
	})
	return closed, err
}

func (f lifecycleFixture) stack(t *testing.T) int64 {
	return stackQuantity(t, f.pool, f.a.PlayerID, 50005013)
}

func noHook(context.Context, tx.Scope) error { return nil }
func noFault(tx.Scope) error                 { return nil }

func attemptRow(t *testing.T, p *pg.Pool, id ids.UUID) string {
	t.Helper()
	var row string
	if err := p.QueryRow(ctx, `SELECT row_to_json(a)::text FROM combat_attempts a WHERE attempt_id=$1`, id.String()).Scan(&row); err != nil {
		t.Fatal(err)
	}
	return row
}

func reportRows(t *testing.T, p *pg.Pool) [2]int64 {
	t.Helper()
	var n [2]int64
	if err := p.QueryRow(ctx, `SELECT (SELECT count(*) FROM combat_report_blobs),(SELECT count(*) FROM combat_resolutions)`).Scan(&n[0], &n[1]); err != nil {
		t.Fatal(err)
	}
	return n
}

// H-29, H-58: the retention version decides availability at read time; expiry
// answers out-of-date and never rewrites the attempt or its report.
func TestI8_7RetentionVersionsNative(t *testing.T) {
	f := newLifecycle(t)
	resolved := f.ready(t, "retention")
	settled, err := f.settle("retention", "retention-receipt", noHook, noFault)
	if err != nil {
		t.Fatal(err)
	}
	staged := f.start(t, f.s, "retention-staged")
	id := settled.Attempt.ID
	rowBefore, reportsBefore := attemptRow(t, f.pool, id), reportRows(t, f.pool)
	terminalAt := *settled.Attempt.TerminalAt
	v1 := combatRetention()
	v2 := d.Retention{ID: "I8_7_FIXTURE_RETENTION_V2", Version: 2, Window: 48 * time.Hour}
	at := terminalAt.Add(72 * time.Hour)
	replayed, served, err := f.s.ReplayTx(ctx, f.pool, id, v1, at)
	if err != nil || !served || string(replayed.Report) != string(resolved.Report) || replayed.Resolution != resolved.Resolution {
		t.Fatal("V1 replay within window", served, err)
	}
	if _, served, err = f.s.ReplayTx(ctx, f.pool, id, v2, at); err != nil || served {
		t.Fatal("V2 must answer out-of-date at 72h", served, err)
	}
	if _, served, err = f.s.ReplayTx(ctx, f.pool, id, v1, terminalAt.Add(d.RetentionCeiling)); err != nil || served {
		t.Fatal("window end is exclusive", served, err)
	}
	if _, served, err = f.s.ReplayTx(ctx, f.pool, staged.ID, v1, at); err != nil || served {
		t.Fatal("staged attempt has no replay", served, err)
	}
	beyond := d.Retention{ID: "I8_7_FIXTURE_RETENTION_V3", Version: 3, Window: d.RetentionCeiling + time.Hour}
	if _, _, err = f.s.ReplayTx(ctx, f.pool, id, beyond, at); !errors.Is(err, d.ErrInvalid) {
		t.Fatal("retention above the ceiling", err)
	}
	if attemptRow(t, f.pool, id) != rowBefore || reportRows(t, f.pool) != reportsBefore {
		t.Fatal("retention read rewrote stored rows")
	}
}

type upgradedCorpus struct{ combat.Rules }

func (upgradedCorpus) ID() string { return fingerprint("i8-7-upgraded-corpus") }

// H-30: after a corpus upgrade a terminal report loads without a rerun, and a
// staged attempt frozen under the retired corpus fails permanently, closable.
func TestI8_7CorpusUpgradeNative(t *testing.T) {
	f := newLifecycle(t)
	resolved := f.ready(t, "corpus-terminal")
	if _, err := f.settle("corpus-terminal", "corpus-receipt", noHook, noFault); err != nil {
		t.Fatal(err)
	}
	staged := f.start(t, f.s, "corpus-staged")
	upgraded := f.s
	upgraded.Rules, upgraded.Worker = upgradedCorpus{f.s.Rules}, failingWorker{}
	replayed, served, err := upgraded.ReplayTx(ctx, f.pool, resolved.Attempt.ID, combatRetention(), time.Now().UTC())
	if err != nil || !served || string(replayed.Report) != string(resolved.Report) {
		t.Fatal("old report under the new corpus", served, err)
	}
	reportsBefore := reportRows(t, f.pool)
	_, err = upgraded.Resolve(ctx, op(), staged.ID)
	if !errors.Is(err, d.ErrResolverPermanent) || !strings.Contains(err.Error(), "RULES_CORPUS_RETIRED") {
		t.Fatal("retired corpus must fail permanently before the worker", err)
	}
	failed, _, err := f.s.AttemptTx(ctx, f.pool, staged.ID)
	if err != nil || failed.ResolverStatus != d.ResolverPermanentFailed || failed.ResolverFailure != "RULES_CORPUS_RETIRED" || reportRows(t, f.pool) != reportsBefore {
		t.Fatal("retired corpus failure not recorded", failed, err)
	}
	if closed, err := f.close("corpus-staged", "corpus-close", time.Now().UTC()); err != nil || closed.Attempt.State != d.Terminal {
		t.Fatal("retired attempt not closable", err)
	}
}

func combatRetention() d.Retention {
	return d.Retention{ID: "I8_7_FIXTURE_RETENTION_V1", Version: 1, Window: d.RetentionCeiling}
}

func keyRing(t *testing.T, current string, versions ...string) combatkeys.Ring {
	t.Helper()
	var entries []string
	for _, version := range versions {
		key := sha256.Sum256([]byte("i8-7-native-key-" + version))
		entries = append(entries, version+"="+hex.EncodeToString(key[:]))
	}
	ring, err := combatkeys.Parse(strings.Join(entries, ","), current)
	if err != nil {
		t.Fatal(err)
	}
	return ring
}

// H-32: rotation keeps each attempt on its frozen key version; a ring that
// dropped the version refuses the resolution and writes nothing.
func TestI8_7KeyRotationNative(t *testing.T) {
	f := newLifecycle(t)
	before := f.s
	before.Keys = keyRing(t, "v1", "v1")
	old := f.start(t, before, "rotation-old")
	rotated := f.s
	rotated.Keys = keyRing(t, "v2", "v1", "v2")
	fresh := f.start(t, rotated, "rotation-new")
	if old.EntropyKeyVersion != "v1" || fresh.EntropyKeyVersion != "v2" {
		t.Fatal("frozen key versions", old.EntropyKeyVersion, fresh.EntropyKeyVersion)
	}
	retired := f.s
	retired.Keys = keyRing(t, "v2", "v2")
	rowBefore, reportsBefore := attemptRow(t, f.pool, old.ID), reportRows(t, f.pool)
	if _, err := retired.Resolve(ctx, op(), old.ID); !errors.Is(err, d.ErrKeyUnavailable) {
		t.Fatal("dropped key version must fail closed", err)
	}
	if attemptRow(t, f.pool, old.ID) != rowBefore || reportRows(t, f.pool) != reportsBefore {
		t.Fatal("refused resolution wrote rows")
	}
	resolved, err := rotated.Resolve(ctx, op(), old.ID)
	if err != nil || resolved.Attempt.EntropyKeyVersion != "v1" {
		t.Fatal("historical attempt under the rotated ring", err)
	}
	again, err := retired.Resolve(ctx, op(), old.ID)
	if err != nil || string(again.Report) != string(resolved.Report) {
		t.Fatal("persisted resolution needs no key", err)
	}
}

type failingSaveStore struct{ combatstore.Store }

func (failingSaveStore) SaveAttemptTx(context.Context, tx.Tx, d.Attempt, int64) error {
	return errors.New("injected attempt save failure")
}

// H-49: a report written in a transaction that fails to reference it rolls
// back with it, so no orphan blob or resolution gains authority.
func TestI8_7ReportStoreFailureNative(t *testing.T) {
	f := newLifecycle(t)
	staged := f.start(t, f.s, "orphan")
	broken := f.s
	broken.Store = failingSaveStore{}
	reportsBefore := reportRows(t, f.pool)
	if _, err := broken.Resolve(ctx, op(), staged.ID); err == nil {
		t.Fatal("failed attempt save committed")
	}
	current, _, err := f.s.AttemptTx(ctx, f.pool, staged.ID)
	if err != nil || reportRows(t, f.pool) != reportsBefore || !current.Runnable() || current.ResolutionHash != "" {
		t.Fatal("orphan report rows or attempt moved", current, err)
	}
	resolved, err := f.s.Resolve(ctx, op(), staged.ID)
	if err != nil || resolved.Attempt.State != d.ResolutionReady || reportRows(t, f.pool) == reportsBefore {
		t.Fatal("rerun after store failure", err)
	}
}

type injectedAbort struct{}

func (injectedAbort) Error() string       { return "injected definite abort" }
func (injectedAbort) DefiniteAbort() bool { return true }

// H-47, H-48, H-59, H-60: TERMINAL commits only with its Grant; an objective
// retry and a duplicate callback pay once; a lost notification reloads the
// canonical attempt and replays identical bytes.
func TestI8_7SettlementAtomicityNative(t *testing.T) {
	f := newLifecycle(t)
	resolved := f.ready(t, "atomic")
	paid := f.stack(t)
	_, err := f.settle("atomic", "atomic-receipt", noHook, func(tx.Scope) error { return errors.New("injected grant failure") })
	current, _, readErr := f.s.AttemptTx(ctx, f.pool, resolved.Attempt.ID)
	if err == nil || readErr != nil || current.State != d.ResolutionReady || f.stack(t) != paid {
		t.Fatal("terminal committed without its grant", err, current.State)
	}
	aborts := 0
	settled, err := f.settle("atomic", "atomic-receipt", noHook, func(scope tx.Scope) error {
		if scope.Attempt == 1 {
			aborts++
			return injectedAbort{}
		}
		return nil
	})
	if err != nil || aborts != 1 || settled.Replayed || settled.Attempt.State != d.Terminal || f.stack(t) != paid+1 {
		t.Fatal("objective retry", err, aborts, f.stack(t)-paid)
	}
	duplicate, err := f.settle("atomic", "atomic-receipt", noHook, noFault)
	if err != nil || !duplicate.Replayed || string(duplicate.Report) != string(resolved.Report) || f.stack(t) != paid+1 {
		t.Fatal("duplicate callback", err, f.stack(t)-paid)
	}
	lost := f.ready(t, "lost")
	if _, err = fixtureTerminal(t, f.s, f.pool, f.a, f.locator("lost"), "lost-receipt", metricCommitDB{Beginner: f.pool, commit: true}, opPinned(f.rev)); err != nil {
		t.Fatal("ambiguous terminal commit not reconciled", err)
	}
	reloaded, found, err := f.s.TerminalEvidenceTx(ctx, f.pool, f.locator("lost"), "lost-receipt")
	if err != nil || !found || reloaded.ID != lost.Attempt.ID {
		t.Fatal("canonical attempt lost", err)
	}
	replayed, served, err := f.s.ReplayTx(ctx, f.pool, reloaded.ID, combatRetention(), time.Now().UTC())
	if err != nil || !served || string(replayed.Report) != string(lost.Report) {
		t.Fatal("lost notification replay", served, err)
	}
	again, err := fixtureTerminal(t, f.s, f.pool, f.a, f.locator("lost"), "lost-receipt", f.pool, opPinned(f.rev))
	if err != nil || !again.Replayed || f.stack(t) != paid+2 {
		t.Fatal("redelivered lost notification paid again", err, f.stack(t)-paid)
	}
}

// H-52: expiry CLOSE and RESULT TERMINAL race on one ready attempt; the
// locator lock admits exactly one terminal and the loser writes nothing.
func TestI8_7ExpiryVersusResultNative(t *testing.T) {
	f := newLifecycle(t)
	resolved := f.ready(t, "expiry")
	paid := f.stack(t)
	const each = 3
	var wg sync.WaitGroup
	settleErrs, closeErrs := make([]error, each), make([]error, each)
	for i := range each {
		wg.Add(2)
		go func() {
			defer wg.Done()
			_, settleErrs[i] = f.settle("expiry", "expiry-settle", noHook, noFault)
		}()
		go func() {
			defer wg.Done()
			_, closeErrs[i] = f.close("expiry", "expiry-close", resolved.Attempt.ResultDeadline)
		}()
	}
	wg.Wait()
	final, _, err := f.s.AttemptTx(ctx, f.pool, resolved.Attempt.ID)
	if err != nil || final.State != d.Terminal {
		t.Fatal("no terminal", err)
	}
	winners, losers := settleErrs, closeErrs
	if final.TerminalKind == "FIXTURE_EXPIRED" {
		winners, losers = closeErrs, settleErrs
	}
	for i := range each {
		if winners[i] != nil || !errors.Is(losers[i], combat.ErrAttemptNotFound) {
			t.Fatal("exactly one terminal kind must win", final.TerminalKind, settleErrs, closeErrs)
		}
	}
	wantPaid := paid
	if final.TerminalKind == "FIXTURE_SETTLED" {
		wantPaid++
	}
	if f.stack(t) != wantPaid {
		t.Fatal("expiry race value", final.TerminalKind, f.stack(t)-paid)
	}
	t.Logf("expiry race won by %s", final.TerminalKind)
}

// H-51: the RESULT liveness fence holds FOR SHARE on the session, so a
// revocation waits for the in-flight RESULT and every later RESULT refuses.
func TestI8_7RevocationFencesResultNative(t *testing.T) {
	f := newLifecycle(t)
	f.ready(t, "inflight")
	later := f.ready(t, "after-revoke")
	paid := f.stack(t)
	fence := func(c context.Context, scope tx.Scope) error {
		var at time.Time
		if err := scope.Tx.QueryRow(c, "SELECT clock_timestamp()").Scan(&at); err != nil {
			return err
		}
		return i5store.Store{}.FenceActorTx(c, scope.Tx, f.a, at)
	}
	fenced, proceed, done := make(chan struct{}, 1), make(chan struct{}), make(chan error, 1)
	go func() {
		_, err := f.settle("inflight", "inflight-receipt", func(c context.Context, scope tx.Scope) error {
			if err := fence(c, scope); err != nil {
				return err
			}
			fenced <- struct{}{}
			<-proceed
			return nil
		}, noFault)
		done <- err
	}()
	<-fenced
	// Session revocation is native test setup, the identity store's revoke statement.
	revoke := `UPDATE account_sessions SET revoked_at=clock_timestamp(),revocation_reason='I8_7_FIXTURE_REVOCATION',liveness_version=liveness_version+1 WHERE session_id=$1`
	blocked, err := f.pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	if _, err = blocked.Exec(ctx, `SET LOCAL lock_timeout='300ms'`); err != nil {
		t.Fatal(err)
	}
	if _, err = blocked.Exec(ctx, revoke, f.a.SessionID.UUID().String()); err == nil {
		t.Fatal("revocation passed an in-flight fenced RESULT")
	}
	blocked.Rollback(ctx)
	close(proceed)
	if err = <-done; err != nil || f.stack(t) != paid+1 {
		t.Fatal("in-flight RESULT", err)
	}
	exec(t, f.pool, revoke, f.a.SessionID.UUID().String())
	if _, err = f.settle("after-revoke", "after-revoke-receipt", fence, noFault); err == nil {
		t.Fatal("RESULT after revocation passed the fence")
	}
	current, _, err := f.s.AttemptTx(ctx, f.pool, later.Attempt.ID)
	if err != nil || current.State != d.ResolutionReady || f.stack(t) != paid+1 {
		t.Fatal("revoked RESULT wrote effects", current.State, err)
	}
}
