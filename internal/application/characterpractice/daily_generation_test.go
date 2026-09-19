package characterpractice

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type practiceTestTag int64

func (t practiceTestTag) RowsAffected() int64 { return int64(t) }

type practiceTestRow struct{ err error }

func (r practiceTestRow) Scan(...any) error { return r.err }

type practiceTestTx struct{ commitErr error }

func (t *practiceTestTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return practiceTestTag(1), nil
}
func (t *practiceTestTx) QueryRow(context.Context, string, ...any) tx.Row {
	return practiceTestRow{err: errors.New("unused test row")}
}
func (t *practiceTestTx) Commit(context.Context) error   { return t.commitErr }
func (t *practiceTestTx) Rollback(context.Context) error { return nil }

type practiceTestDB struct {
	beginCount int
	commitErr  error
}

func (d *practiceTestDB) Begin(context.Context, tx.Options) (tx.Tx, error) {
	d.beginCount++
	return &practiceTestTx{commitErr: d.commitErr}, nil
}

type practiceTestQueryer struct{}

func (practiceTestQueryer) QueryRow(context.Context, string, ...any) tx.Row {
	return practiceTestRow{err: errors.New("unused test row")}
}

type practiceTestStore struct{ root Root }

func (s *practiceTestStore) ReadPracticeRootTx(context.Context, tx.Queryer, identity.PlayerID) (Root, error) {
	return s.root, nil
}
func (s *practiceTestStore) LockPracticeRootTx(context.Context, tx.Tx, identity.PlayerID) (Root, error) {
	return s.root, nil
}
func (s *practiceTestStore) SaveGenerationTx(_ context.Context, _ tx.Tx, next Root, old int64) error {
	if s.root.StateVersion != old {
		return ErrStaleVersion
	}
	s.root = next
	return nil
}
func (s *practiceTestStore) SaveAccountingTx(_ context.Context, _ tx.Tx, next Root, old int64) error {
	if s.root.StateVersion != old {
		return ErrStaleVersion
	}
	s.root = next
	return nil
}
func (s *practiceTestStore) EnsureRootTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (bool, error) {
	return false, nil
}
func (s *practiceTestStore) ReadHeroProposalTx(context.Context, tx.Queryer, identity.PlayerID, identity.SessionID, int64) (Proposal, error) {
	return Proposal{}, ErrCandidateMissing
}
func (s *practiceTestStore) LockHeroProposalTx(context.Context, tx.Tx, identity.PlayerID, identity.SessionID, int64) (Proposal, error) {
	return Proposal{}, ErrCandidateMissing
}
func (s *practiceTestStore) UpsertHeroProposalTx(context.Context, tx.Tx, Proposal) error { return nil }
func (s *practiceTestStore) DeleteHeroProposalTx(context.Context, tx.Tx, identity.PlayerID, identity.SessionID, int64) error {
	return nil
}
func (s *practiceTestStore) ReadPetProposalTx(context.Context, tx.Queryer, identity.PlayerID, identity.SessionID, int64) (Proposal, error) {
	return Proposal{}, ErrCandidateMissing
}
func (s *practiceTestStore) LockPetProposalTx(context.Context, tx.Tx, identity.PlayerID, identity.SessionID, int64) (Proposal, error) {
	return Proposal{}, ErrCandidateMissing
}
func (s *practiceTestStore) UpsertPetProposalTx(context.Context, tx.Tx, Proposal) error { return nil }
func (s *practiceTestStore) DeletePetProposalTx(context.Context, tx.Tx, identity.PlayerID, identity.SessionID, int64) error {
	return nil
}

type practiceTestContent struct {
	revision string
	bless    int64
}

func (c practiceTestContent) PracticeActive(context.Context) (string, bool, error) {
	return c.revision, true, nil
}
func (c practiceTestContent) PracticeRevision(_ context.Context, rev string) (bool, error) {
	return rev == c.revision, nil
}
func (c practiceTestContent) PracticeMethodTx(context.Context, tx.Queryer, string, int64) (Method, error) {
	return Method{}, nil
}
func (c practiceTestContent) PracticeLockTx(context.Context, tx.Queryer, string, int64) (LockCost, error) {
	return LockCost{}, nil
}
func (c practiceTestContent) PracticeVIPBlessTx(context.Context, tx.Queryer, string, int64) (int64, error) {
	return c.bless, nil
}
func (c practiceTestContent) PracticePolicyFactsTx(context.Context, tx.Queryer, string) (PolicyFacts, error) {
	return PolicyFacts{}, nil
}
func (c practiceTestContent) HeroPracticeThresholdsTx(context.Context, tx.Queryer, string, int64) ([]Threshold, error) {
	return nil, nil
}
func (c practiceTestContent) PetPracticeThresholdsTx(context.Context, tx.Queryer, string, int64) ([]Threshold, error) {
	return nil, nil
}
func (c practiceTestContent) HeroTemplateAwakenedTx(context.Context, tx.Queryer, string, int64) (bool, error) {
	return true, nil
}
func (c practiceTestContent) PetTemplateAwakenedTx(context.Context, tx.Queryer, string, int64) (bool, error) {
	return true, nil
}

type practiceTestPrivileges struct{ snap appi5.PrivilegeSnapshot }

func (p practiceTestPrivileges) SnapshotTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (appi5.PrivilegeSnapshot, error) {
	return p.snap, nil
}

func practiceTestOperation(t *testing.T, at time.Time) operation.Context {
	t.Helper()
	id, err := ids.NewUUIDFrom(strings.NewReader(strings.Repeat("x", 16)))
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: id, StartedAt: at.UTC()}
}

func practiceNeutralRoot(at time.Time) Root {
	return Root{PlayerID: identity.PlayerID(7), StateVersion: 1, CreatedAt: at.UTC(), UpdatedAt: at.UTC()}
}

func practiceTestService(store *practiceTestStore, db *practiceTestDB, rev string, bless int64, vip int64) Service {
	return Service{
		Runner: tx.Runner{DB: db}, Store: store,
		Content:          practiceTestContent{revision: rev, bless: bless},
		Privileges:       practiceTestPrivileges{snap: appi5.PrivilegeSnapshot{ProviderRevision: "vip-test/v1", VIPLevel: vip}},
		ReconcileQueryer: practiceTestQueryer{},
	}
}

func TestAlchemyEpochStartV1UsesGMTPlus8Midnight(t *testing.T) {
	got, err := AlchemyEpochStartV1(time.Date(2026, 9, 18, 17, 30, 0, 0, time.UTC)) // 01:30 next day GMT+8
	if err != nil {
		t.Fatal(err)
	}
	want := time.Date(2026, 9, 18, 16, 0, 0, 0, time.UTC)
	if !got.Equal(want) {
		t.Fatalf("epoch=%s want=%s", got, want)
	}
}

func TestEnsureDailyGenerationMaterializesOnceAndFreezesProvenance(t *testing.T) {
	created := time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC)
	store := &practiceTestStore{root: practiceNeutralRoot(created)}
	db := &practiceTestDB{}
	rev := strings.Repeat("a", 64)
	svc := practiceTestService(store, db, rev, 180, 3)
	op := practiceTestOperation(t, time.Date(2026, 9, 18, 2, 15, 0, 0, time.UTC))

	got, err := svc.EnsureDailyGeneration(context.Background(), identity.PlayerID(7), op)
	if err != nil {
		t.Fatal(err)
	}
	wantEpoch := time.Date(2026, 9, 17, 16, 0, 0, 0, time.UTC)
	if got.DailyEpochStartAt == nil || !got.DailyEpochStartAt.Equal(wantEpoch) {
		t.Fatalf("epoch=%v want=%v", got.DailyEpochStartAt, wantEpoch)
	}
	if got.DailyEpochPolicyVersion != DailyEpochPolicyV1 || got.BlessRemaining != 180 || got.BlessCapacityAtEpoch != 180 {
		t.Fatalf("unexpected root: %#v", got)
	}
	if got.BlessVIPLevelAtEpoch == nil || *got.BlessVIPLevelAtEpoch != 3 || got.BlessPrivilegeProviderRevision != "vip-test/v1" || got.BlessContentRevision != rev {
		t.Fatalf("bad provenance: %#v", got)
	}
	if got.BaseMana != 0 || got.BaseCrystal != 0 || got.StateVersion != 2 {
		t.Fatalf("bad reset/version: %#v", got)
	}
	if db.beginCount != 1 {
		t.Fatalf("beginCount=%d want=1", db.beginCount)
	}

	got2, err := svc.EnsureDailyGeneration(context.Background(), identity.PlayerID(7), op)
	if err != nil {
		t.Fatal(err)
	}
	if got2.StateVersion != 2 || db.beginCount != 1 {
		t.Fatalf("same epoch rematerialized: root=%#v begins=%d", got2, db.beginCount)
	}
}

func TestEnsureDailyGenerationClockRegressionDoesNotReopen(t *testing.T) {
	created := time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC)
	epoch := time.Date(2026, 9, 18, 16, 0, 0, 0, time.UTC)
	vip := int64(5)
	root := practiceNeutralRoot(created)
	root.DailyEpochStartAt = &epoch
	root.DailyEpochPolicyVersion = DailyEpochPolicyV1
	root.BlessRemaining, root.BlessCapacityAtEpoch = 200, 300
	root.BlessVIPLevelAtEpoch = &vip
	root.BlessPrivilegeProviderRevision = "vip-test/v1"
	root.BlessContentRevision = strings.Repeat("b", 64)
	root.BaseMana, root.BaseCrystal, root.StateVersion = 70000, 15, 4
	store := &practiceTestStore{root: root}
	db := &practiceTestDB{}
	svc := practiceTestService(store, db, root.BlessContentRevision, 999, 15)
	older := practiceTestOperation(t, time.Date(2026, 9, 18, 1, 0, 0, 0, time.UTC))

	got, err := svc.EnsureDailyGeneration(context.Background(), identity.PlayerID(7), older)
	if err != nil {
		t.Fatal(err)
	}
	if got.StateVersion != 4 || got.BlessRemaining != 200 || db.beginCount != 0 {
		t.Fatalf("clock regression changed root=%#v begins=%d", got, db.beginCount)
	}
}

func TestEnsureDailyGenerationUnknownCommitReconcilesDurablePostcondition(t *testing.T) {
	created := time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC)
	store := &practiceTestStore{root: practiceNeutralRoot(created)}
	db := &practiceTestDB{commitErr: errors.New("transport lost after commit")}
	rev := strings.Repeat("c", 64)
	svc := practiceTestService(store, db, rev, 420, 7)
	op := practiceTestOperation(t, time.Date(2026, 9, 18, 8, 0, 0, 0, time.UTC))

	got, err := svc.EnsureDailyGeneration(context.Background(), identity.PlayerID(7), op)
	if err != nil {
		t.Fatal(err)
	}
	if got.DailyEpochStartAt == nil || got.BlessRemaining != 420 || got.StateVersion != 2 {
		t.Fatalf("reconciliation did not expose committed generation: %#v", got)
	}
	if db.beginCount != 1 {
		t.Fatalf("ambiguous commit replayed body: beginCount=%d", db.beginCount)
	}
}

func TestGenerationResolverRequiresExactProvenanceForExactEpoch(t *testing.T) {
	created := time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC)
	epoch := time.Date(2026, 9, 18, 16, 0, 0, 0, time.UTC)
	vip := int64(0)
	root := practiceNeutralRoot(created)
	root.DailyEpochStartAt = &epoch
	root.DailyEpochPolicyVersion = "other-policy"
	root.BlessVIPLevelAtEpoch = &vip
	root.BlessPrivilegeProviderRevision = "vip-test/v1"
	root.BlessContentRevision = strings.Repeat("d", 64)
	store := &practiceTestStore{root: root}
	resolver := generationResolver{Store: store, Queryer: practiceTestQueryer{}, PlayerID: identity.PlayerID(7), DesiredEpoch: epoch, PolicyVersion: DailyEpochPolicyV1, ContentRevision: root.BlessContentRevision}
	res, err := resolver.Resolve(context.Background(), tx.ResolutionRequest{})
	if err != nil {
		t.Fatal(err)
	}
	if res.State != tx.ResolutionUnknown {
		t.Fatalf("state=%v want unknown", res.State)
	}
}

func TestPlanDailyGenerationTxIsNoWriteReusableTransition(t *testing.T) {
	created := time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC)
	free := time.Date(2026, 9, 17, 4, 0, 0, 0, time.UTC)
	root := practiceNeutralRoot(created)
	root.FreeLastConsumedAt = &free
	root.BaseMana = 70000
	root.BaseCrystal = 15
	store := &practiceTestStore{root: root}
	rev := strings.Repeat("e", 64)
	svc := practiceTestService(store, &practiceTestDB{}, rev, 240, 4)
	op := practiceTestOperation(t, time.Date(2026, 9, 18, 8, 0, 0, 0, time.UTC))
	desired, err := AlchemyEpochStartV1(op.StartedAt)
	if err != nil {
		t.Fatal(err)
	}

	next, changed, err := svc.planDailyGenerationTx(context.Background(), practiceTestQueryer{}, root, desired, op, rev)
	if err != nil {
		t.Fatal(err)
	}
	if !changed {
		t.Fatal("expected generation transition")
	}
	if store.root.StateVersion != root.StateVersion || store.root.BaseMana != root.BaseMana {
		t.Fatalf("planner wrote canonical store: %#v", store.root)
	}
	if next.StateVersion != root.StateVersion+1 || next.BaseMana != 0 || next.BaseCrystal != 0 || next.BlessRemaining != 240 {
		t.Fatalf("unexpected planned root: %#v", next)
	}
	if next.FreeLastConsumedAt == nil || !next.FreeLastConsumedAt.Equal(free) {
		t.Fatalf("planner changed independent free entitlement timestamp: %#v", next.FreeLastConsumedAt)
	}
}

func TestPlanDailyGenerationTxCurrentEpochIsIdentity(t *testing.T) {
	created := time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC)
	epoch := time.Date(2026, 9, 18, 16, 0, 0, 0, time.UTC)
	vip := int64(0)
	root := practiceNeutralRoot(created)
	root.DailyEpochStartAt = &epoch
	root.DailyEpochPolicyVersion = DailyEpochPolicyV1
	root.BlessVIPLevelAtEpoch = &vip
	root.BlessPrivilegeProviderRevision = "vip-test/v1"
	root.BlessContentRevision = strings.Repeat("f", 64)
	root.BlessRemaining = 10
	root.BlessCapacityAtEpoch = 20
	root.StateVersion = 3
	root.BaseMana = 5
	root.UpdatedAt = epoch
	svc := practiceTestService(&practiceTestStore{root: root}, &practiceTestDB{}, root.BlessContentRevision, 999, 15)
	op := practiceTestOperation(t, epoch.Add(time.Hour))
	next, changed, err := svc.planDailyGenerationTx(context.Background(), practiceTestQueryer{}, root, epoch, op, root.BlessContentRevision)
	if err != nil {
		t.Fatal(err)
	}
	if changed || next.StateVersion != root.StateVersion || next.BlessRemaining != root.BlessRemaining || next.BaseMana != root.BaseMana {
		t.Fatalf("current epoch should be identity: changed=%v next=%#v", changed, next)
	}
}
