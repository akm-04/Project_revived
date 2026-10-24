//go:build postgres

package playerdisplay_test

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"os"
	osexec "os/exec"
	"path/filepath"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/combatresolver"
	"gxb.local/backend/v2/internal/adapters/combatworker"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/combatstore"
	"gxb.local/backend/v2/internal/adapters/postgres/conquerstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/elementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/inscriptionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/spiritstore"
	boot "gxb.local/backend/v2/internal/application/bootstrap"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	combat "gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/i5"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	combatWorkerOnce   sync.Once
	combatWorkerBinary string
	combatWorkerErr    error
)

func combatLauncher(t *testing.T) *combatworker.Launcher {
	t.Helper()
	launcher := combatworker.New(combatLimits(t), 3, 5*time.Second)
	t.Cleanup(launcher.Close)
	return launcher
}

func combatLimits(t *testing.T) combatworker.Limits {
	t.Helper()
	combatWorkerOnce.Do(func() {
		dir, err := os.MkdirTemp("", "i7c5a-worker-")
		if err != nil {
			combatWorkerErr = err
			return
		}
		combatWorkerBinary = filepath.Join(dir, "gxb-combat-worker")
		out, err := osexec.Command("go", "build", "-o", combatWorkerBinary, "gxb.local/backend/v2/cmd/gxb-combat-worker").CombinedOutput()
		if err != nil {
			combatWorkerErr = fmt.Errorf("%v: %s", err, out)
		}
	})
	if combatWorkerErr != nil {
		t.Fatal(combatWorkerErr)
	}
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	return combatworker.Limits{Binary: combatWorkerBinary, Deadline: 120 * time.Second, AddressSpace: 4 << 30, CPUSeconds: 180, OpenFiles: 64, MaxOutputBytes: 16 << 20, ExpectedCorpus: corpus.ID()}
}

type combatKeys struct{ missing bool }

func (k combatKeys) Current() (string, []byte, error) {
	if k.missing {
		return "", nil, errors.New("no current key")
	}
	key := sha256.Sum256([]byte("i7c5a-native-test-key-v1"))
	return "test-v1", key[:], nil
}
func (k combatKeys) Key(version string) ([]byte, error) {
	if k.missing || version != "test-v1" {
		return nil, errors.New("retired key unavailable")
	}
	key := sha256.Sum256([]byte("i7c5a-native-test-key-v1"))
	return key[:], nil
}

func combatService(t *testing.T, p *pg.Pool) combat.Service {
	t.Helper()
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	cs := contentstore.Store{Queryer: p}
	library := libraryService(p, p)
	heroes := characterstore.HeroBootstrapProjection{Content: cs, Library: library, Dorm: dormService(p, p), Book: bookService(p, p), Course: courseService(p, p), Inscription: inscriptionService(p, p), Element: elementService(p, p), Spirit: spiritService(p, p), Evolution: evolutionService(p, p)}
	return combat.Service{Rules: corpus, Keys: combatKeys{}, Worker: combatLauncher(t), Store: combatstore.Store{}, Content: cs, Runner: tx.Runner{DB: p}, Fresh: p,
		Inputs: combat.Inputs{Heroes: heroes, Pets: characterstore.PetBootstrapProjection{Content: cs}, Stats: rawBirthStats(p), Awakening: rawBirthReader(), Collection: library, Conquer: conquerService(p), Stacks: i5store.Store{Queryer: p}}}
}

// combatOwner bootstraps the owner roots like I4 and births a genuine Normal
// Hero through the production fresh-facet chain, so every 3B provider is live.
func combatOwner(t *testing.T, p *pg.Pool, server identity.LogicalServerID) (identity.ActorContext, string, character.HeroRef) {
	t.Helper()
	rev := installed(t, p)
	a := rankingActor(t, p, server, true)
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	o := opPinned(rev)
	o.StartedAt = time.Now().UTC().Add(-time.Minute)
	b := logicalserver.BootstrapContext{PlayerID: a.PlayerID, Operation: o, BootstrapProfileVersion: "I7C5A_COMBAT_NATIVE_FIXTURE"}
	for _, c := range []boot.CharacterBootstrapPersistenceContributor{dormstore.BootstrapContributor{Revision: rev}, bookstore.BootstrapContributor{Revision: rev}, coursestore.BootstrapContributor{Revision: rev}, inscriptionstore.BootstrapContributor{Revision: rev}, elementstore.BootstrapContributor{Revision: rev}, spiritstore.BootstrapContributor{Revision: rev}, conquerstore.BootstrapContributor{Revision: rev}} {
		if err = c.PersistCharacterBootstrap(ctx, tr, b); err != nil {
			t.Fatal(c.Name(), err)
		}
	}
	if err = (librarystore.Store{}).EnsurePlayerRootTx(ctx, tr, a.PlayerID, o.StartedAt); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	def := collectionResources(t, p, a, rev, 10001001)
	h, err := ownerSummoner(p).SummonNormal(ctx, a, def.Template.TableID, def.Template.FragmentItemID, def.FragmentCount, op())
	if err != nil {
		t.Fatal(err)
	}
	return a, rev, h.Ref()
}

// ownerSummoner births heroes with every fresh facet the combat roster reads.
func ownerSummoner(p *pg.Pool) hero.Service {
	s := rawBirthService(p)
	s.FreshFacets = hero.FreshFacetChain{librarystore.Store{}, dormstore.Store{}, coursestore.Store{}, inscriptionstore.Store{}, elementstore.Store{}, spiritstore.Store{}, characterstore.EvolutionStore{}, characterstore.RawAwakeningStore{}}
	return s
}

func templateParams(tableID int64) map[string]any {
	return map[string]any{"player_id": 0, "partner_id": tableID, "table_id": tableID, "star": 3, "lev": 20, "color": 2, "skin_ids": map[string]any{}, "spirit_equip": []any{}, "spirit_item": []any{},
		"equips": []any{0, 0, 0, 0, 0, 0}, "fumos": []any{0, 0, 0, 0, 0, 0}, "skills": []any{1, 1, 1, 1, 1, 1}}
}

// combatTestProfile bounds the fixture mode transactions generously enough for
// race-instrumented runs, where START's owner reads are an order slower.
func combatTestProfile() tx.Profile {
	return tx.Profile{Name: "I7C5A_FIXTURE_MODE", AcquireTimeout: 10 * time.Second, LockTimeout: 60 * time.Second, StatementTimeout: 60 * time.Second, TransactionTimeout: 120 * time.Second, CleanupTimeout: 5 * time.Second, ReconcileTimeout: 30 * time.Second, OperationTimeout: 180 * time.Second}
}

func fingerprint(s string) string {
	sum := sha256.Sum256([]byte(s))
	return hex.EncodeToString(sum[:])
}

// fixtureStart is a test-only mode consumer: its own RepeatableRead START
// transaction witnesses the coherent scope and calls Combat START inside it.
func fixtureStart(t *testing.T, s combat.Service, rev string, request combat.StartRequest, db tx.Beginner) (combat.Started, error) {
	t.Helper()
	var started combat.Started
	runner := tx.Runner{DB: db}
	evidence := startEvidence{service: s, q: s.Fresh, locator: request.Locator, fingerprint: request.StartFingerprint}
	_, err := runner.Run(ctx, opPinned(rev), combatTestProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, evidence, func(c context.Context, scope tx.Scope) error {
		var at time.Time
		if err := scope.Tx.QueryRow(c, "SELECT clock_timestamp()").Scan(&at); err != nil {
			return err
		}
		sc, err := ca.NewCoherentReadScope(scope, rev, at)
		if err != nil {
			return err
		}
		request.ResultDeadline = at.Add(time.Hour)
		started, err = s.StartTx(c, scope.Tx, sc, request)
		return err
	})
	if err == nil && started.Attempt.ID.IsZero() {
		a, found, e := s.StartEvidenceTx(ctx, s.Fresh, request.Locator, request.StartFingerprint)
		if e != nil || !found {
			t.Fatal("reconciled START without attempt evidence", e)
		}
		started = combat.Started{Attempt: a}
	}
	return started, err
}

type startEvidence struct {
	service     combat.Service
	q           tx.Queryer
	locator     d.Locator
	fingerprint string
}

func (e startEvidence) Resolve(c context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
	a, found, err := e.service.StartEvidenceTx(c, e.q, e.locator, e.fingerprint)
	if err != nil || !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, err
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: a.ID}, nil
}

type terminalEvidence struct {
	service combat.Service
	q       tx.Queryer
	locator d.Locator
	receipt string
}

func (e terminalEvidence) Resolve(c context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
	a, found, err := e.service.TerminalEvidenceTx(c, e.q, e.locator, e.receipt)
	if err != nil || !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, err
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: a.ID}, nil
}

// fixtureTerminal settles the attempt and pays an I5 Grant in one mode transaction;
// a replayed terminal reconstructs the recorded result and pays nothing.
func fixtureTerminal(t *testing.T, s combat.Service, pool *pg.Pool, a identity.ActorContext, locator d.Locator, receipt string, db tx.Beginner, o operation.Context) (combat.Settled, error) {
	t.Helper()
	var settled combat.Settled
	runner := tx.Runner{DB: db}
	_, err := runner.Run(ctx, o, combatTestProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, terminalEvidence{service: s, q: s.Fresh, locator: locator, receipt: receipt}, func(c context.Context, scope tx.Scope) error {
		var at time.Time
		if err := scope.Tx.QueryRow(c, "SELECT clock_timestamp()").Scan(&at); err != nil {
			return err
		}
		var err error
		settled, err = s.TerminalTx(c, scope.Tx, combat.TerminalRequest{Locator: locator, GenerationRef: "fixture-generation-1", TerminalKind: "FIXTURE_SETTLED", SemanticReceiptID: receipt, At: at})
		if err != nil || settled.Replayed {
			return err
		}
		plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i7c5a-fixture-mode", Operation: "combat-terminal", BusinessKey: receipt, PolicyVersion: "i7c5a-fixture-v1"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 50005013, Amount: 1}}}
		_, err = combatGrant(pool).SettleGrantTx(c, scope.Tx, a, plan, o, i5.GrantTxOptions{})
		return err
	})
	return settled, err
}

func combatGrant(pool *pg.Pool) i5.Service {
	values, cs := i5store.Store{Queryer: pool}, contentstore.Store{Queryer: pool}
	return i5.Service{Runner: tx.Runner{DB: pool}, Store: values, Content: cs, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: pool}, RedeemSecret: []byte("i7c5a-fixture-redeem-key-000000000")}
}

func combatRows(t *testing.T, pool *pg.Pool) [3]int64 {
	t.Helper()
	var n [3]int64
	if err := pool.QueryRow(ctx, `SELECT (SELECT count(*) FROM combat_snapshots),(SELECT count(*) FROM combat_attempts),(SELECT count(*) FROM combat_resolutions)`).Scan(&n[0], &n[1], &n[2]); err != nil {
		t.Fatal(err)
	}
	return n
}

func TestI7C5ACombatOwnedStartResolveTerminalNative(t *testing.T) {
	pool := pool(t)
	server := rankingServer(t, pool)
	a, rev, ref := combatOwner(t, pool, server)
	b, _, foreignRef := combatOwner(t, pool, server)
	s := combatService(t, pool)
	locator := d.Locator{DomainKind: "i7c5a-fixture-mode", AuthorityScope: fmt.Sprintf("server/%d", server), DomainLocator: fmt.Sprintf("player/%d/target/%d", a.PlayerID, b.PlayerID)}
	request := combat.StartRequest{Actor: a, Locator: locator, GenerationRef: "fixture-generation-1", StartFingerprint: fingerprint(locator.DomainLocator + "/v1"), Battle: combat.BattleRequest{CampaignType: 1, BattleID: 0,
		TeamA:  []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: a.PlayerID, Identity: ref.PartnerID}},
		WavesB: [][]combat.Participant{{{Origin: d.OwnedForeign, Kind: d.HeroActor, Player: b.PlayerID, Identity: foreignRef.PartnerID}, {Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}
	started, err := fixtureStart(t, s, rev, request, pool)
	if err != nil {
		t.Fatal(err)
	}
	attempt := started.Attempt
	if attempt.State != d.Staged || started.Replayed {
		t.Fatal("START", attempt)
	}
	raw, err := (combatstore.Store{}).ReadSnapshotTx(ctx, pool, attempt.SnapshotHash)
	if err != nil {
		t.Fatal(err)
	}
	snapshot, err := d.DecodeSnapshot(raw, attempt.SnapshotHash)
	if err != nil {
		t.Fatal(err)
	}
	// A08: equivalent START replays without resnapshot or new entropy; a different one conflicts.
	again, err := fixtureStart(t, s, rev, request, pool)
	if err != nil || !again.Replayed || again.Attempt.ID != attempt.ID || again.Attempt.SnapshotHash != attempt.SnapshotHash {
		t.Fatal("same START replay", again, err)
	}
	conflict := request
	conflict.StartFingerprint = fingerprint("different")
	if _, err = fixtureStart(t, s, rev, conflict, pool); !errors.Is(err, d.ErrStartConflict) {
		t.Fatal("different START", err)
	}
	// A05: VM totals from frozen source params against the frozen 3B facet.
	corpus, _ := combatcorpus.Load()
	totals, err := combatresolver.EvaluateActors(corpus, snapshot)
	if err != nil {
		t.Fatal(err)
	}
	all := append(append([]d.Actor{}, snapshot.Battle.TeamA...), snapshot.Battle.WavesB[0]...)
	for i, actor := range all {
		if actor.Origin == d.Template {
			continue
		}
		var facet struct {
			Total [49]float64 `json:"total"`
		}
		if err = json.Unmarshal(actor.BattleTotals, &facet); err != nil {
			t.Fatal(err)
		}
		for attr := 1; attr <= 49; attr++ {
			vm, oracle := totals[i][attr], facet.Total[attr-1]
			if math.Abs(vm-oracle) > 1e-6*math.Max(1, math.Abs(oracle)) {
				t.Errorf("A05 actor %d (%s player %d) attr %d: VM %v 3B %v", i, actor.Origin, actor.Player, attr, vm, oracle)
			}
		}
	}
	// A07: owner mutation after START cannot change the frozen attempt.
	exec(t, pool, `UPDATE player_item_stacks SET quantity=quantity+1 WHERE player_id=$1`, int64(a.PlayerID))
	exec(t, pool, `UPDATE player_progression SET level=level+1 WHERE player_id=$1`, int64(b.PlayerID))
	resolved, err := s.Resolve(ctx, op(), attempt.ID)
	if err != nil {
		t.Fatal(err)
	}
	stored, _ := (combatstore.Store{}).ReadSnapshotTx(ctx, pool, attempt.SnapshotHash)
	if string(stored) != string(raw) || resolved.Attempt.State != d.ResolutionReady || resolved.Resolution.SnapshotHash != attempt.SnapshotHash {
		t.Fatal("post-freeze or resolution state", resolved.Attempt)
	}
	t.Logf("owned fight outcome %+v draws %d report %s", resolved.Resolution.Outcome, resolved.Resolution.EntropyDraws, resolved.Resolution.ReportSHA256)
	// A10: replay never reruns entropy: a failing worker still returns the persisted result.
	broken := s
	broken.Worker = failingWorker{}
	replayed, err := broken.Resolve(ctx, op(), attempt.ID)
	if err != nil || replayed.Resolution != resolved.Resolution || string(replayed.Report) != string(resolved.Report) {
		t.Fatal("resolution replay", err)
	}
	// A11: RESULT cannot create an attempt; terminal settles and pays once.
	missing := locator
	missing.DomainLocator += "/absent"
	if _, err = fixtureTerminal(t, s, pool, a, missing, "receipt-absent", pool, opPinned(rev)); !errors.Is(err, combat.ErrAttemptNotFound) {
		t.Fatal("RESULT created an attempt", err)
	}
	before := stackQuantity(t, pool, a.PlayerID, 50005013)
	var wg sync.WaitGroup
	results := make([]combat.Settled, 4)
	errs := make([]error, 4)
	o := opPinned(rev)
	for i := range results {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			results[i], errs[i] = fixtureTerminal(t, s, pool, a, locator, "fixture-receipt-1", pool, o)
		}(i)
	}
	wg.Wait()
	fresh := 0
	for i := range results {
		if errs[i] != nil {
			t.Fatal("competing terminal", errs[i])
		}
		if !results[i].Replayed {
			fresh++
		}
		if results[i].Resolution != resolved.Resolution || results[i].Attempt.State != d.Terminal {
			t.Fatal("terminal result diverged")
		}
	}
	if fresh != 1 || stackQuantity(t, pool, a.PlayerID, 50005013) != before+1 {
		t.Fatal("terminal settled more than once", fresh, before, stackQuantity(t, pool, a.PlayerID, 50005013))
	}
	// After TERMINAL the locator slot is free; the stored rows stay immutable.
	if _, err = pool.Raw().Exec(ctx, `UPDATE combat_snapshots SET rules_corpus_id=rules_corpus_id WHERE snapshot_hash=$1`, attempt.SnapshotHash); err == nil {
		t.Fatal("snapshot mutable")
	}
	if _, err = pool.Raw().Exec(ctx, `UPDATE combat_attempts SET state_version=state_version+1 WHERE attempt_id=$1`, attempt.ID.String()); err == nil {
		t.Fatal("terminal attempt mutable")
	}
}

func stackQuantity(t *testing.T, pool *pg.Pool, player identity.PlayerID, item int64) int64 {
	t.Helper()
	var n int64
	if err := pool.QueryRow(ctx, `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(player), item).Scan(&n); err != nil {
		t.Fatal(err)
	}
	return n
}

type failingWorker struct{}

func (failingWorker) Resolve(context.Context, []byte, string, [32]byte) (combat.WorkerOutput, error) {
	return combat.WorkerOutput{}, fmt.Errorf("%w: test worker must not run", d.ErrResolverRetryable)
}

type unavailableCombatCollection struct{}

func (unavailableCombatCollection) PlayerCollectionInputsTx(context.Context, tx.Queryer, lib.InputScope) (lib.CollectionInputs, error) {
	return lib.CollectionInputs{}, errors.New("collection owner unavailable")
}

type otherArchiveContent struct{ contentstore.Store }

func (otherArchiveContent) SourceArchiveTx(context.Context, tx.Queryer, string) (string, error) {
	return fmt.Sprintf("%064x", 1), nil
}

// A06: every refusal happens before commit and writes no Combat row.
func TestI7C5ACombatFailClosedNative(t *testing.T) {
	pool := pool(t)
	server := rankingServer(t, pool)
	a, rev, ref := combatOwner(t, pool, server)
	base := combatService(t, pool)
	request := func(name string, wave []combat.Participant) combat.StartRequest {
		locator := d.Locator{DomainKind: "i7c5a-fixture-mode", AuthorityScope: "refusals", DomainLocator: fmt.Sprintf("%d/%s", a.PlayerID, name)}
		return combat.StartRequest{Actor: a, Locator: locator, GenerationRef: "g", StartFingerprint: fingerprint(name), Battle: combat.BattleRequest{CampaignType: 1,
			TeamA: []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: a.PlayerID, Identity: ref.PartnerID}}, WavesB: [][]combat.Participant{wave}}}
	}
	template := []combat.Participant{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}
	missingClass := []combat.Participant{{Origin: d.Template, Kind: d.HeroActor, Identity: 11001042, TemplateParams: templateParams(11001042)}}
	badTemplate := templateParams(10001002)
	badTemplate["player_id"] = int64(a.PlayerID)
	cases := []struct {
		name    string
		service func(combat.Service) combat.Service
		wave    []combat.Participant
		want    error
	}{
		{"class-unavailable", func(s combat.Service) combat.Service { return s }, missingClass, d.ErrClassUnavailable},
		{"missing-key", func(s combat.Service) combat.Service { s.Keys = combatKeys{missing: true}; return s }, template, d.ErrKeyUnavailable},
		{"content-archive", func(s combat.Service) combat.Service {
			s.Content = otherArchiveContent{contentstore.Store{Queryer: pool}}
			return s
		}, template, d.ErrContentMismatch},
		{"provider-unavailable", func(s combat.Service) combat.Service { s.Inputs.Collection = unavailableCombatCollection{}; return s }, template, d.ErrProviderUnavailable},
		{"template-owner-claim", func(s combat.Service) combat.Service { return s }, []combat.Participant{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: badTemplate}}, d.ErrInvalid},
		{"foreign-as-self", func(s combat.Service) combat.Service { return s }, []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: a.PlayerID + 1, Identity: 1}}, d.ErrInvalid},
	}
	for _, c := range cases {
		before := combatRows(t, pool)
		_, err := fixtureStart(t, c.service(base), rev, request(c.name, c.wave), pool)
		if !errors.Is(err, c.want) {
			t.Fatalf("%s: %v", c.name, err)
		}
		if combatRows(t, pool) != before {
			t.Fatalf("%s wrote combat rows", c.name)
		}
	}
}

// A08 concurrency: competing equivalent STARTs yield exactly one attempt.
func TestI7C5ACombatConcurrentStartNative(t *testing.T) {
	pool := pool(t)
	server := rankingServer(t, pool)
	a, rev, ref := combatOwner(t, pool, server)
	s := combatService(t, pool)
	locator := d.Locator{DomainKind: "i7c5a-fixture-mode", AuthorityScope: "concurrent", DomainLocator: fmt.Sprint(a.PlayerID)}
	request := combat.StartRequest{Actor: a, Locator: locator, GenerationRef: "g", StartFingerprint: fingerprint("concurrent"), Battle: combat.BattleRequest{CampaignType: 1,
		TeamA: []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: a.PlayerID, Identity: ref.PartnerID}}, WavesB: [][]combat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}
	var wg sync.WaitGroup
	ids := make([]string, 6)
	errs := make([]error, 6)
	for i := range ids {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			started, err := fixtureStart(t, s, rev, request, pool)
			ids[i], errs[i] = started.Attempt.ID.String(), err
		}(i)
	}
	wg.Wait()
	for i := range ids {
		if errs[i] != nil || ids[i] != ids[0] {
			t.Fatal("concurrent START", ids, errs)
		}
	}
	var n int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM combat_attempts WHERE domain_kind=$1 AND authority_scope=$2 AND domain_locator=$3`, locator.DomainKind, locator.AuthorityScope, locator.DomainLocator).Scan(&n); err != nil || n != 1 {
		t.Fatal("attempt rows", n, err)
	}
}

type barrierWorker struct {
	ready  *sync.WaitGroup
	report string
}

func (w barrierWorker) Resolve(context.Context, []byte, string, [32]byte) (combat.WorkerOutput, error) {
	w.ready.Done()
	w.ready.Wait()
	corpus, _ := combatcorpus.Load()
	return combat.WorkerOutput{CorpusID: corpus.ID(), Outcome: d.Outcome{Star: 1, Frames: 10}, Report: []byte(w.report)}, nil
}

// A10/A12: duplicate completion is idempotent, a differing one is an integrity
// failure, and an ambiguous COMMIT resolves only from positive evidence.
func TestI7C5ACombatCompletionAndUnknownCommitNative(t *testing.T) {
	pool := pool(t)
	server := rankingServer(t, pool)
	a, rev, ref := combatOwner(t, pool, server)
	base := combatService(t, pool)
	start := func(name string, db tx.Beginner) combat.Started {
		locator := d.Locator{DomainKind: "i7c5a-fixture-mode", AuthorityScope: "completion", DomainLocator: fmt.Sprintf("%d/%s", a.PlayerID, name)}
		started, err := fixtureStart(t, base, rev, combat.StartRequest{Actor: a, Locator: locator, GenerationRef: "g", StartFingerprint: fingerprint(name), Battle: combat.BattleRequest{CampaignType: 1,
			TeamA: []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: a.PlayerID, Identity: ref.PartnerID}}, WavesB: [][]combat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}, db)
		if err != nil {
			t.Fatal(name, err)
		}
		return started
	}
	race := func(id string, reports [2]string) [2]error {
		var ready sync.WaitGroup
		ready.Add(2)
		var errs [2]error
		var wg sync.WaitGroup
		attempt := start(id, pool).Attempt
		for i := range reports {
			wg.Add(1)
			go func(i int) {
				defer wg.Done()
				s := base
				s.Worker = barrierWorker{ready: &ready, report: reports[i]}
				_, errs[i] = s.Resolve(ctx, op(), attempt.ID)
			}(i)
		}
		wg.Wait()
		return errs
	}
	same := race("duplicate", [2]string{`{"star":1}`, `{"star":1}`})
	if same[0] != nil || same[1] != nil {
		t.Fatal("identical duplicate completion", same)
	}
	differ := race("mismatch", [2]string{`{"star":1}`, `{"star":2}`})
	if (differ[0] == nil) == (differ[1] == nil) || !(errors.Is(differ[0], d.ErrIntegrity) || errors.Is(differ[1], d.ErrIntegrity)) {
		t.Fatal("mismatching completion must fail exactly one as integrity", differ)
	}
	// Ambiguous START COMMIT: the commit happens, the error is ambiguous, evidence confirms.
	ambiguous := start("unknown-commit", metricCommitDB{Beginner: pool, commit: true})
	if ambiguous.Attempt.ID.IsZero() {
		t.Fatal("unknown START commit not reconciled")
	}
	// Ambiguous COMMIT that actually rolled back stays unknown, never a blind retry success.
	locator := d.Locator{DomainKind: "i7c5a-fixture-mode", AuthorityScope: "completion", DomainLocator: fmt.Sprintf("%d/unknown-absent", a.PlayerID)}
	_, err := fixtureStart(t, base, rev, combat.StartRequest{Actor: a, Locator: locator, GenerationRef: "g", StartFingerprint: fingerprint("unknown-absent"), Battle: combat.BattleRequest{CampaignType: 1,
		TeamA: []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: a.PlayerID, Identity: ref.PartnerID}}, WavesB: [][]combat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}, metricCommitDB{Beginner: pool, commit: false})
	var unknown *tx.UnknownCommitError
	if !errors.As(err, &unknown) {
		t.Fatal("rolled-back ambiguous START must stay unknown", err)
	}
	if _, found, _ := base.StartEvidenceTx(ctx, pool, locator, fingerprint("unknown-absent")); found {
		t.Fatal("rolled-back START left an attempt")
	}
}

// A05 nondefault: owner-store mutations, a Super Hero with enhanced Super
// equipment and a Pet. Super has no genuine birth producer, so this differential
// uses the labelled 3B conditional awakening fixture for every actor.
func TestI7C5ACombatNondefaultDifferentialNative(t *testing.T) {
	pool := pool(t)
	a, rev, ref := combatOwner(t, pool, rankingServer(t, pool))
	tr, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	at := time.Now().UTC()
	h, err := (characterstore.Store{}).LockHeroByPartnerIDTx(ctx, tr, a.PlayerID, ref.PartnerID)
	if err != nil {
		t.Fatal(err)
	}
	version := h.StateVersion
	h.Color = 16
	for slot := int64(1); slot <= 6; slot++ {
		pos, err := (contentstore.Store{}).HeroEquipmentPositionTx(ctx, tr, rev, h.TableID, h.Color, slot)
		if err != nil {
			t.Fatal(err)
		}
		if pos.OrdinaryEligible {
			h.Equipment[slot-1] = 1
		}
	}
	h.StateVersion++
	h.UpdatedAt = at
	if err = (characterstore.Store{}).SaveHeroStateTx(ctx, tr, h, version); err != nil {
		t.Fatal(err)
	}
	books := bookstore.Store{}
	root, err := books.LockRootTx(ctx, tr, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	old := root.Version
	root.Version++
	root.Facts.Skills[10010001] = 1
	root.UpdatedAt = at
	if err = books.SaveRootTx(ctx, tr, root, old); err != nil {
		t.Fatal(err)
	}
	courses := coursestore.Store{}
	ch, err := courses.LockHeroTx(ctx, tr, a.PlayerID, ref.PartnerID)
	if err != nil {
		t.Fatal(err)
	}
	old = ch.Version
	ch.Version++
	ch.Facts.Courses = []course.Record{{ID: 100101, Progress: 100, Quality: 1, Skill: 1, EXP: 0}}
	ch.UpdatedAt = at
	if err = courses.SaveHeroTx(ctx, tr, ch, old); err != nil {
		t.Fatal(err)
	}
	library := librarystore.Store{}
	lh, err := library.LockHeroTx(ctx, tr, ref)
	if err != nil {
		t.Fatal(err)
	}
	lh.Married, lh.Favor = true, 2000
	old = lh.StateVersion
	lh.StateVersion++
	lh.UpdatedAt = at
	if err = library.SaveHeroTx(ctx, tr, lh, old); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	for _, item := range []int64{50000001, 50000002} {
		exec(t, pool, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,1,1,clock_timestamp()-interval '1 minute',clock_timestamp()-interval '1 minute')`, int64(a.PlayerID), item)
	}
	super := skillHero(t, pool, a, rev, 11001, 2)
	tr, err = pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	sh, err := (characterstore.Store{}).LockHeroByPartnerIDTx(ctx, tr, a.PlayerID, super.PartnerID)
	if err != nil {
		t.Fatal(err)
	}
	version = sh.StateVersion
	sh.Star = 6
	for slot := range sh.Equipment {
		sh.Equipment[slot] = 21
	}
	sh.StateVersion++
	if err = (characterstore.Store{}).SaveHeroStateTx(ctx, tr, sh, version); err != nil {
		t.Fatal(err)
	}
	for _, c := range []interface {
		InitFreshHeroTx(context.Context, tx.Tx, character.HeroRef, time.Time) error
	}{dormstore.Store{}, coursestore.Store{}, inscriptionstore.Store{}, spiritstore.Store{}, characterstore.EvolutionStore{}} {
		if err = c.InitFreshHeroTx(ctx, tr, super.Ref(), at); err != nil {
			t.Fatal(err)
		}
	}
	if _, err = library.BackfillMissingHeroTx(ctx, tr, super.Ref(), at); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	pet := statPet(t, pool, a, rev)
	s := combatService(t, pool)
	fixture := statAwakeningFixture{p: pool}
	stats := rawBirthStats(pool)
	stats.Awakening = fixture
	s.Inputs.Stats, s.Inputs.Awakening = stats, fixture
	locator := d.Locator{DomainKind: "i7c5a-fixture-mode", AuthorityScope: "nondefault", DomainLocator: fmt.Sprint(a.PlayerID)}
	started, err := fixtureStart(t, s, rev, combat.StartRequest{Actor: a, Locator: locator, GenerationRef: "g", StartFingerprint: fingerprint("nondefault"), Battle: combat.BattleRequest{CampaignType: 1,
		TeamA:  []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: a.PlayerID, Identity: ref.PartnerID}, {Origin: d.OwnedSelf, Kind: d.HeroActor, Player: a.PlayerID, Identity: super.PartnerID}},
		PetsA:  []combat.Participant{{Origin: d.OwnedSelf, Kind: d.PetActor, Player: a.PlayerID, Identity: pet.PetID}},
		WavesB: [][]combat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}, pool)
	if err != nil {
		t.Fatal(err)
	}
	raw, err := (combatstore.Store{}).ReadSnapshotTx(ctx, pool, started.Attempt.SnapshotHash)
	if err != nil {
		t.Fatal(err)
	}
	snapshot, err := d.DecodeSnapshot(raw, started.Attempt.SnapshotHash)
	if err != nil {
		t.Fatal(err)
	}
	var normal map[string]any
	if err = json.Unmarshal(snapshot.Battle.TeamA[0].Params, &normal); err != nil {
		t.Fatal(err)
	}
	if fmt.Sprint(normal["color"]) != "16" || fmt.Sprint(normal["courses"]) == "[]" || fmt.Sprint(normal["is_married"]) != "1" || len(snapshot.Players[0].ExclusiveBooks) != 2 {
		t.Fatal("nondefault inputs not frozen", normal["color"], normal["courses"], normal["is_married"], snapshot.Players[0].ExclusiveBooks)
	}
	corpus, _ := combatcorpus.Load()
	totals, err := combatresolver.EvaluateActors(corpus, snapshot)
	if err != nil {
		t.Fatal(err)
	}
	owned := append(append([]d.Actor{}, snapshot.Battle.TeamA...), snapshot.Battle.PetsA...)
	for i, actor := range owned {
		var facet struct {
			Model string      `json:"model"`
			Total [49]float64 `json:"total"`
		}
		if err = json.Unmarshal(actor.BattleTotals, &facet); err != nil {
			t.Fatal(err)
		}
		mismatches := 0
		for attr := 1; attr <= 49; attr++ {
			vm, oracle := totals[i][attr], facet.Total[attr-1]
			if math.Abs(vm-oracle) > 1e-6*math.Max(1, math.Abs(oracle)) {
				mismatches++
				t.Errorf("A05 %s %s table %d attr %d: VM %v 3B %v", facet.Model, actor.Kind, actor.TableID, attr, vm, oracle)
			}
		}
		t.Logf("A05 %s %s table %d: %d/49 attributes equal (hp VM %v)", facet.Model, actor.Kind, actor.TableID, 49-mismatches, totals[i][1])
	}
	resolved, err := s.Resolve(ctx, op(), started.Attempt.ID)
	if err != nil {
		t.Fatal(err)
	}
	var report map[string]any
	if err = json.Unmarshal(resolved.Report, &report); err != nil || fmt.Sprint(report["zhuge_book_skill_num"]) != fmt.Sprintf("map[%d:2]", a.PlayerID) {
		t.Fatal("report context", report["zhuge_book_skill_num"], err)
	}
	t.Logf("nondefault fight outcome %+v report %s", resolved.Resolution.Outcome, resolved.Resolution.ReportSHA256)
}

// A15: START holds only Combat's rank-609 locator lock. While its transaction
// is open, every owner row stays updatable elsewhere (FOR NO KEY UPDATE is what
// ordinary owner updates take; the attempt foreign key only holds KEY SHARE).
func TestI7C5ACombatStartTakesOnlyCombatLocksNative(t *testing.T) {
	pool := pool(t)
	a, rev, ref := combatOwner(t, pool, rankingServer(t, pool))
	s := combatService(t, pool)
	locator := d.Locator{DomainKind: "i7c5a-fixture-mode", AuthorityScope: "locks", DomainLocator: fmt.Sprint(a.PlayerID)}
	request := combat.StartRequest{Actor: a, Locator: locator, GenerationRef: "g", StartFingerprint: fingerprint("locks"), Battle: combat.BattleRequest{CampaignType: 1,
		TeamA: []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: a.PlayerID, Identity: ref.PartnerID}}, WavesB: [][]combat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}
	var tables []string
	rows, err := pool.Raw().Query(ctx, `SELECT table_name FROM information_schema.columns WHERE table_schema='public' AND column_name='player_id' AND table_name NOT LIKE 'combat_%' ORDER BY table_name`)
	if err != nil {
		t.Fatal(err)
	}
	for rows.Next() {
		var name string
		if err = rows.Scan(&name); err != nil {
			t.Fatal(err)
		}
		tables = append(tables, name)
	}
	rows.Close()
	tr, err := pool.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	var at time.Time
	if err = tr.QueryRow(ctx, "SELECT clock_timestamp()").Scan(&at); err != nil {
		t.Fatal(err)
	}
	o := opPinned(rev)
	sc, err := ca.NewCoherentReadScope(tx.Scope{Tx: tr, Operation: o, Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead}}, rev, at)
	if err != nil {
		t.Fatal(err)
	}
	request.ResultDeadline = at.Add(time.Hour)
	if _, err = s.StartTx(ctx, tr, sc, request); err != nil {
		t.Fatal(err)
	}
	probe := func(sql string, args ...any) error {
		other, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
		if err != nil {
			t.Fatal(err)
		}
		defer other.Rollback(ctx)
		_, err = other.Exec(ctx, sql, args...)
		return err
	}
	for _, table := range tables {
		if err = probe(`SELECT 1 FROM `+table+` WHERE player_id=$1 FOR NO KEY UPDATE NOWAIT`, int64(a.PlayerID)); err != nil {
			t.Errorf("START locked owner table %s: %v", table, err)
		}
	}
	// The root row is uncommitted, so a competing START blocks on its key.
	other, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer other.Rollback(ctx)
	if _, err = other.Exec(ctx, `SET LOCAL lock_timeout='200ms'`); err != nil {
		t.Fatal(err)
	}
	if _, err = other.Exec(ctx, `INSERT INTO combat_locator_roots(domain_kind,authority_scope,domain_locator)VALUES($1,$2,$3) ON CONFLICT DO NOTHING`, locator.DomainKind, locator.AuthorityScope, locator.DomainLocator); err == nil {
		t.Fatal("rank-609 locator lock not held")
	}
	t.Logf("%d owner tables remained lockable during START", len(tables))
}

type permanentWorker struct{}

func (permanentWorker) Resolve(context.Context, []byte, string, [32]byte) (combat.WorkerOutput, error) {
	return combat.WorkerOutput{}, fmt.Errorf("%w: deterministic script failure fixture", d.ErrResolverPermanent)
}

// Pass418 lets the owning mode end an unresolved attempt: a permanently failed
// or expired attempt is closable without settlement, freeing its locator.
func TestI7C5ACombatCloseUnresolvedNative(t *testing.T) {
	pool := pool(t)
	a, rev, ref := combatOwner(t, pool, rankingServer(t, pool))
	s := combatService(t, pool)
	s.Worker = permanentWorker{}
	locator := d.Locator{DomainKind: "i7c5a-fixture-mode", AuthorityScope: "close", DomainLocator: fmt.Sprint(a.PlayerID)}
	request := func(name string) combat.StartRequest {
		return combat.StartRequest{Actor: a, Locator: locator, GenerationRef: "g", StartFingerprint: fingerprint(name), Battle: combat.BattleRequest{CampaignType: 1,
			TeamA: []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: a.PlayerID, Identity: ref.PartnerID}}, WavesB: [][]combat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}
	}
	first, err := fixtureStart(t, s, rev, request("close-1"), pool)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = s.Resolve(ctx, op(), first.Attempt.ID); !errors.Is(err, d.ErrResolverPermanent) {
		t.Fatal("permanent failure", err)
	}
	if _, err = fixtureStart(t, s, rev, request("close-other"), pool); !errors.Is(err, d.ErrStartConflict) {
		t.Fatal("failed attempt must still own its locator", err)
	}
	close := func(receipt string, at time.Time) (combat.Closed, error) {
		var closed combat.Closed
		_, err := (tx.Runner{DB: pool}).Run(ctx, opPinned(rev), combatTestProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, scope tx.Scope) error {
			var err error
			closed, err = s.CloseTx(c, scope.Tx, combat.TerminalRequest{Locator: locator, GenerationRef: "g", TerminalKind: "RESOLVER_FAILED", SemanticReceiptID: receipt, At: at})
			return err
		})
		return closed, err
	}
	_, settleErr := (tx.Runner{DB: pool}).Run(ctx, opPinned(rev), combatTestProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, scope tx.Scope) error {
		_, err := s.TerminalTx(c, scope.Tx, combat.TerminalRequest{Locator: locator, GenerationRef: "g", TerminalKind: "SETTLED", SemanticReceiptID: "never-settled", At: time.Now().UTC()})
		return err
	})
	if !errors.Is(settleErr, d.ErrNotReady) {
		t.Fatal("unresolved attempt settled", settleErr)
	}
	now := time.Now().UTC()
	closed, err := close("close-receipt-1", now)
	if err != nil || closed.Replayed || closed.Attempt.State != d.Terminal || closed.Attempt.ResolutionHash != "" {
		t.Fatal("close permanent failure", closed, err)
	}
	again, err := close("close-receipt-1", now)
	if err != nil || !again.Replayed || again.Attempt.ID != first.Attempt.ID {
		t.Fatal("close replay", again, err)
	}
	second, err := fixtureStart(t, s, rev, request("close-2"), pool)
	if err != nil || second.Attempt.ID == first.Attempt.ID || second.Replayed {
		t.Fatal("locator not freed", err)
	}
	if _, err = close("close-receipt-2", now); !errors.Is(err, d.ErrStale) {
		t.Fatal("pending attempt closed before deadline", err)
	}
	expired, err := close("close-receipt-2", second.Attempt.ResultDeadline)
	if err != nil || expired.Attempt.State != d.Terminal {
		t.Fatal("expired attempt close", err)
	}
}
