package characterhero

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type acqStore struct {
	root           character.HeroRoot
	heroes         map[int64]character.Hero
	rootLocks      int
	lockedPartners []int64
	inserts        int
	allocatorSaves int
	lockErrOnce    error
	onLockErr      func()
}

func (s *acqStore) ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (character.HeroRoot, error) {
	return s.root, nil
}
func (s *acqStore) LockRootTx(context.Context, tx.Tx, identity.PlayerID) (character.HeroRoot, error) {
	s.rootLocks++
	if s.lockErrOnce != nil {
		err := s.lockErrOnce
		s.lockErrOnce = nil
		if s.onLockErr != nil {
			s.onLockErr()
		}
		return character.HeroRoot{}, err
	}
	return s.root, nil
}
func (s *acqStore) ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error) {
	out := make([]character.Hero, 0, len(s.heroes))
	for _, h := range s.heroes {
		out = append(out, h)
	}
	return out, nil
}
func (s *acqStore) LockHeroByPartnerIDTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, id int64) (character.Hero, error) {
	s.lockedPartners = append(s.lockedPartners, id)
	h, ok := s.heroes[id]
	if !ok {
		return character.Hero{}, ErrHeroNotFound
	}
	return h, nil
}
func (s *acqStore) SaveRootAllocatorTx(_ context.Context, _ tx.Tx, r character.HeroRoot, old int64) error {
	if s.root.StateVersion != old || r.StateVersion != old+1 {
		return errors.New("allocator lost race")
	}
	s.root = r
	s.allocatorSaves++
	return nil
}
func (s *acqStore) InsertHeroTx(_ context.Context, _ tx.Tx, h character.Hero) error {
	if s.heroes == nil {
		s.heroes = map[int64]character.Hero{}
	}
	if _, ok := s.heroes[h.PartnerID]; ok {
		return ErrHeroDuplicateOrigin
	}
	for _, cur := range s.heroes {
		if cur.OriginTableID == h.OriginTableID {
			return ErrHeroDuplicateOrigin
		}
	}
	s.heroes[h.PartnerID] = h
	s.inserts++
	return nil
}

type acqContent struct {
	progContent
	byItem       map[int64]character.HeroAcquisitionTemplate
	summon       map[int64]character.HeroNormalSummonPolicy
	vowsRequired int64
}

func (c acqContent) HeroAcquisitionByItemTx(_ context.Context, _ tx.Queryer, _ string, item int64) (character.HeroAcquisitionTemplate, error) {
	v, ok := c.byItem[item]
	if !ok {
		return character.HeroAcquisitionTemplate{}, errors.New("missing acquisition item")
	}
	return v, nil
}
func (c acqContent) HeroNormalSummonTx(_ context.Context, _ tx.Queryer, revision string, table int64) (character.HeroNormalSummonPolicy, error) {
	if c.seenRevisions != nil {
		*c.seenRevisions = append(*c.seenRevisions, revision)
	}
	v, ok := c.summon[table]
	if !ok {
		return character.HeroNormalSummonPolicy{}, errors.New("missing summon policy")
	}
	return v, nil
}
func (c acqContent) HeroVowsRequiredLevelTx(context.Context, tx.Queryer, string) (int64, error) {
	if c.vowsRequired <= 0 {
		return 0, errors.New("missing Vows level")
	}
	return c.vowsRequired, nil
}

type capAuth struct {
	max   int
	calls int
}

func (c *capAuth) AuthorizeHeroAddition(_ identity.PlayerID, current, add int) error {
	c.calls++
	if c.max < 0 || current < 0 || add <= 0 || current+add > c.max {
		return ErrHeroCapacityExceeded
	}
	return nil
}

type costDebiter struct {
	calls int
	cost  appi5.MaterialCost
}

func (d *costDebiter) DebitMaterialCostTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, cost appi5.MaterialCost, _ operation.Context) (appi5.MaterialDebitResult, error) {
	d.calls++
	d.cost = cost
	return appi5.MaterialDebitResult{}, nil
}

type levelReader struct {
	level int64
	calls int
}

func (r *levelReader) PlayerLevelTx(context.Context, tx.Tx, identity.PlayerID) (int64, error) {
	r.calls++
	return r.level, nil
}

func acquisitionService(as *acqStore, c acqContent, cap *capAuth, costs *costDebiter, level *levelReader, rr *receipts) Service {
	now := time.Unix(1, 0).UTC()
	core := &store{root: character.HeroRoot{PlayerID: 7, NextPartnerID: as.root.NextPartnerID, StateVersion: 1, CreatedAt: now, UpdatedAt: now}}
	return Service{Runner: tx.Runner{DB: fakeDB{}}, Store: core, Fencer: &fence{}, Content: gate(true), Receipts: rr, ReceiptRead: rr, Progression: c, AcquisitionStore: as, Acquisition: c, MaterialCosts: costs, PlayerLevel: level, Capacity: cap}
}

func TestSummonNormalUsesAuthoritativeCostAndTemplateInitialStar(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 40, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, heroes: map[int64]character.Hero{}}
	tmpl := character.HeroAcquisitionTemplate{TableID: 10001062, OriginTableID: 10001062, Kind: character.NormalHero, InitialStar: 5, FragmentItemID: 40001062}
	content := acqContent{progContent: progContent{}, summon: map[int64]character.HeroNormalSummonPolicy{10001062: {Template: tmpl, FragmentCount: 330, Mana: 1300000}}}
	cap := &capAuth{max: 100}
	costs := &costDebiter{}
	level := &levelReader{level: 100}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	svc := acquisitionService(as, content, cap, costs, level, rr)
	op := testOp(t, "88888888-8888-4888-8888-888888888888")
	h, err := svc.SummonNormal(context.Background(), testActor(t), 10001062, 40001062, 330, op)
	if err != nil {
		t.Fatal(err)
	}
	if h.PartnerID != 40 || h.Star != 5 || h.Level != 1 || h.Exp != 0 || h.Color != 1 || h.Kind != character.NormalHero {
		t.Fatalf("created Hero=%+v", h)
	}
	if costs.calls != 1 || len(costs.cost.Scalars) != 1 || costs.cost.Scalars[0].ResourceKey != "mana" || costs.cost.Scalars[0].Amount != 1300000 || len(costs.cost.Stacks) != 1 || costs.cost.Stacks[0].ItemID != 40001062 || costs.cost.Stacks[0].Amount != 330 {
		t.Fatalf("authoritative cost=%+v calls=%d", costs.cost, costs.calls)
	}
	if as.root.NextPartnerID != 41 || as.inserts != 1 || as.allocatorSaves != 1 {
		t.Fatalf("root=%+v inserts=%d saves=%d", as.root, as.inserts, as.allocatorSaves)
	}
	// Same backend operation is receipt reconciliation, not another summon.
	if _, err := svc.SummonNormal(context.Background(), testActor(t), 10001062, 40001062, 330, op); err != nil {
		t.Fatal(err)
	}
	if costs.calls != 1 || as.inserts != 1 {
		t.Fatalf("receipt replay reapplied acquisition costs=%d inserts=%d", costs.calls, as.inserts)
	}
}

func TestSummonNormalRejectsClientCostMismatchBeforeMutation(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 1, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, heroes: map[int64]character.Hero{}}
	tmpl := character.HeroAcquisitionTemplate{TableID: 1001, OriginTableID: 1001, Kind: character.NormalHero, InitialStar: 1, FragmentItemID: 4001}
	content := acqContent{summon: map[int64]character.HeroNormalSummonPolicy{1001: {Template: tmpl, FragmentCount: 10, Mana: 1000}}}
	costs := &costDebiter{}
	svc := acquisitionService(as, content, &capAuth{max: 10}, costs, &levelReader{level: 100}, &receipts{m: map[receipt.Identity]receipt.Receipt{}})
	_, err := svc.SummonNormal(context.Background(), testActor(t), 1001, 4001, 9, testOp(t, "99999999-9999-4999-8999-999999999999"))
	if !errors.Is(err, ErrHeroAcquisitionInvalid) {
		t.Fatalf("error=%v", err)
	}
	if costs.calls != 0 || as.inserts != 0 || as.root.NextPartnerID != 1 {
		t.Fatalf("mismatch mutated state costs=%d inserts=%d root=%+v", costs.calls, as.inserts, as.root)
	}
}

func TestCapacityDenyLeavesSummonUnmutated(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 2, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, heroes: map[int64]character.Hero{1: heroAt(1, 11, 11, 1, 1, 0, now)}}
	tmpl := character.HeroAcquisitionTemplate{TableID: 12, OriginTableID: 12, Kind: character.NormalHero, InitialStar: 1, FragmentItemID: 4012}
	content := acqContent{summon: map[int64]character.HeroNormalSummonPolicy{12: {Template: tmpl, FragmentCount: 10, Mana: 1000}}}
	costs := &costDebiter{}
	svc := acquisitionService(as, content, &capAuth{max: 1}, costs, &levelReader{level: 100}, &receipts{m: map[receipt.Identity]receipt.Receipt{}})
	_, err := svc.SummonNormal(context.Background(), testActor(t), 12, 4012, 10, testOp(t, "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"))
	if !errors.Is(err, ErrHeroCapacityExceeded) {
		t.Fatalf("error=%v", err)
	}
	if costs.calls != 0 || as.inserts != 0 || as.allocatorSaves != 0 || len(as.heroes) != 1 {
		t.Fatalf("capacity denial mutated state")
	}
}

func TestCreateVowsLocksPrerequisitesNumericallyAndUsesQualifyingCount(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	heroes := map[int64]character.Hero{
		10: heroAt(10, 101, 101, 5, 1, 0, now),
		2:  heroAt(2, 102, 102, 5, 1, 0, now),
		30: heroAt(30, 103, 103, 4, 1, 0, now),
		4:  heroAt(4, 104, 104, 5, 1, 0, now),
		50: heroAt(50, 105, 105, 3, 1, 0, now),
	}
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 60, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, heroes: heroes}
	content := acqContent{progContent: progContent{template: map[int64]character.HeroTemplateProgression{9001: {Kind: character.SuperHero, OriginTableID: 9001, InitialStar: 1}}, prereq: map[int64][]int64{9001: {101, 102, 103, 104, 105}}}, vowsRequired: 100}
	level := &levelReader{level: 100}
	svc := acquisitionService(as, content, &capAuth{max: 100}, &costDebiter{}, level, &receipts{m: map[receipt.Identity]receipt.Receipt{}})
	h, err := svc.CreateVows(context.Background(), testActor(t), 9001, testOp(t, "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"))
	if err != nil {
		t.Fatal(err)
	}
	if h.PartnerID != 60 || h.Star != 3 || h.Kind != character.SuperHero {
		t.Fatalf("Vows=%+v", h)
	}
	want := []int64{2, 4, 10, 30, 50}
	if len(as.lockedPartners) != len(want) {
		t.Fatalf("locks=%v", as.lockedPartners)
	}
	for i := range want {
		if as.lockedPartners[i] != want[i] {
			t.Fatalf("locks=%v want=%v", as.lockedPartners, want)
		}
	}
	if level.calls != 1 {
		t.Fatalf("level calls=%d", level.calls)
	}
}

func TestCreateVowsFailsClosedBelowLevelWithoutInsert(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	heroes := map[int64]character.Hero{}
	for i, origin := range []int64{101, 102, 103, 104, 105} {
		heroes[int64(i+1)] = heroAt(int64(i+1), origin, origin, 5, 1, 0, now)
	}
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 10, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, heroes: heroes}
	content := acqContent{progContent: progContent{template: map[int64]character.HeroTemplateProgression{9001: {Kind: character.SuperHero, OriginTableID: 9001, InitialStar: 1}}, prereq: map[int64][]int64{9001: {101, 102, 103, 104, 105}}}, vowsRequired: 100}
	svc := acquisitionService(as, content, &capAuth{max: 100}, &costDebiter{}, &levelReader{level: 99}, &receipts{m: map[receipt.Identity]receipt.Receipt{}})
	_, err := svc.CreateVows(context.Background(), testActor(t), 9001, testOp(t, "cccccccc-cccc-4ccc-8ccc-cccccccccccc"))
	if !errors.Is(err, ErrHeroVowsLevel) {
		t.Fatalf("error=%v", err)
	}
	if as.inserts != 0 || as.allocatorSaves != 0 {
		t.Fatalf("level failure mutated Hero state")
	}
}

func TestHeroMaterializerUsesInitialStarAndLineOrdinalAllocator(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 20, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, heroes: map[int64]character.Hero{}}
	content := acqContent{byItem: map[int64]character.HeroAcquisitionTemplate{
		40001062: {TableID: 10001062, OriginTableID: 10001062, Kind: character.NormalHero, InitialStar: 5, FragmentItemID: 40001062},
		40001001: {TableID: 10001001, OriginTableID: 10001001, Kind: character.NormalHero, InitialStar: 1, FragmentItemID: 40001001},
	}}
	m := HeroMaterializer{Store: as, Content: content, Capacity: &capAuth{max: 100}}
	batch := appi5.PartnerEntityBatch{PlayerID: 7, ContentRevision: progRev, Lines: []appi5.PartnerEntityLine{
		{Identity: appi5.PartnerEntityLineIdentity{GrantSemanticKey: "g", LineOrdinal: 3}, ItemID: 40001001, Amount: 1},
		{Identity: appi5.PartnerEntityLineIdentity{GrantSemanticKey: "g", LineOrdinal: 1}, ItemID: 40001062, Amount: 1},
	}}
	pf, err := m.PreflightPartnerEntityBatchTx(context.Background(), &fakeTx{}, batch)
	if err != nil {
		t.Fatal(err)
	}
	if err := m.LockPartnerEntityKeyTx(context.Background(), &fakeTx{}, pf.Locks[0]); err != nil {
		t.Fatal(err)
	}
	got, err := m.MaterializePartnerEntityBatchTx(context.Background(), &fakeTx{}, batch, pf, testOp(t, "dddddddd-dddd-4ddd-8ddd-dddddddddddd"))
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 2 || got[0].LineOrdinal != 1 || got[1].LineOrdinal != 3 {
		t.Fatalf("results=%+v", got)
	}
	var a, b heroMaterializationPayload
	if err := json.Unmarshal(got[0].ResultPayload, &a); err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal(got[1].ResultPayload, &b); err != nil {
		t.Fatal(err)
	}
	if a.PartnerID != 20 || a.TableID != 10001062 || b.PartnerID != 21 || b.TableID != 10001001 {
		t.Fatalf("payloads a=%+v b=%+v", a, b)
	}
	if as.heroes[20].Star != 5 || as.heroes[21].Star != 1 || as.root.NextPartnerID != 22 {
		t.Fatalf("heroes=%+v root=%+v", as.heroes, as.root)
	}
}

func TestHeroMaterializerRejectsAmountAndAggregateCapacity(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 1, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, heroes: map[int64]character.Hero{}}
	content := acqContent{byItem: map[int64]character.HeroAcquisitionTemplate{1: {TableID: 101, OriginTableID: 101, Kind: character.NormalHero, InitialStar: 1, FragmentItemID: 1}, 2: {TableID: 102, OriginTableID: 102, Kind: character.NormalHero, InitialStar: 1, FragmentItemID: 2}}}
	m := HeroMaterializer{Store: as, Content: content, Capacity: &capAuth{max: 1}}
	bad := appi5.PartnerEntityBatch{PlayerID: 7, ContentRevision: progRev, Lines: []appi5.PartnerEntityLine{{Identity: appi5.PartnerEntityLineIdentity{GrantSemanticKey: "g", LineOrdinal: 0}, ItemID: 1, Amount: 2}}}
	if _, err := m.PreflightPartnerEntityBatchTx(context.Background(), &fakeTx{}, bad); !errors.Is(err, ErrHeroAcquisitionInvalid) {
		t.Fatalf("amount error=%v", err)
	}
	batch := appi5.PartnerEntityBatch{PlayerID: 7, ContentRevision: progRev, Lines: []appi5.PartnerEntityLine{{Identity: appi5.PartnerEntityLineIdentity{GrantSemanticKey: "g", LineOrdinal: 0}, ItemID: 1, Amount: 1}, {Identity: appi5.PartnerEntityLineIdentity{GrantSemanticKey: "g", LineOrdinal: 1}, ItemID: 2, Amount: 1}}}
	pf, err := m.PreflightPartnerEntityBatchTx(context.Background(), &fakeTx{}, batch)
	if err != nil {
		t.Fatal(err)
	}
	if err := m.ValidatePartnerEntityBatchLockedTx(context.Background(), &fakeTx{}, batch, pf); !errors.Is(err, ErrHeroCapacityExceeded) {
		t.Fatalf("capacity error=%v", err)
	}
	if as.inserts != 0 || as.allocatorSaves != 0 {
		t.Fatal("capacity denial mutated provider state")
	}
}

func TestSummonNormalUnknownCommitReceiptReconcilesWithoutReapply(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 40, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, heroes: map[int64]character.Hero{}}
	tmpl := character.HeroAcquisitionTemplate{TableID: 10001062, OriginTableID: 10001062, Kind: character.NormalHero, InitialStar: 5, FragmentItemID: 40001062}
	content := acqContent{summon: map[int64]character.HeroNormalSummonPolicy{10001062: {Template: tmpl, FragmentCount: 330, Mana: 1300000}}}
	costs := &costDebiter{}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	svc := acquisitionService(as, content, &capAuth{max: 100}, costs, &levelReader{level: 100}, rr)
	db := &commitErrorDB{err: errors.New("commit acknowledgement lost")}
	svc.Runner = tx.Runner{DB: db}
	h, err := svc.SummonNormal(context.Background(), testActor(t), 10001062, 40001062, 330, testOp(t, "12121212-1212-4212-8212-121212121212"))
	if err != nil {
		t.Fatal(err)
	}
	if h.PartnerID != 40 || db.begins != 1 || costs.calls != 1 || as.inserts != 1 || as.allocatorSaves != 1 {
		t.Fatalf("unknown-commit reconciliation drift hero=%+v begins=%d costs=%d inserts=%d saves=%d", h, db.begins, costs.calls, as.inserts, as.allocatorSaves)
	}
}

func TestSummonNormalUnknownCommitWithoutReceiptDoesNotBlindRetry(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 40, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, heroes: map[int64]character.Hero{}}
	tmpl := character.HeroAcquisitionTemplate{TableID: 10001062, OriginTableID: 10001062, Kind: character.NormalHero, InitialStar: 5, FragmentItemID: 40001062}
	content := acqContent{summon: map[int64]character.HeroNormalSummonPolicy{10001062: {Template: tmpl, FragmentCount: 330, Mana: 1300000}}}
	costs := &costDebiter{}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	svc := acquisitionService(as, content, &capAuth{max: 100}, costs, &levelReader{level: 100}, rr)
	db := &commitErrorDB{err: errors.New("commit acknowledgement lost")}
	svc.Runner = tx.Runner{DB: db}
	svc.ReceiptRead = missingProgressionReceiptReader{}
	_, err := svc.SummonNormal(context.Background(), testActor(t), 10001062, 40001062, 330, testOp(t, "13131313-1313-4313-8313-131313131313"))
	var unknown *tx.UnknownCommitError
	if !errors.As(err, &unknown) {
		t.Fatalf("expected UNKNOWN COMMIT, got %v", err)
	}
	if db.begins != 1 || costs.calls != 1 || as.inserts != 1 || as.allocatorSaves != 1 {
		t.Fatalf("ambiguous commit was replayed begins=%d costs=%d inserts=%d saves=%d", db.begins, costs.calls, as.inserts, as.allocatorSaves)
	}
}

func TestSummonNormalRejectsExistingOriginWithoutDebit(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 2, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, heroes: map[int64]character.Hero{1: heroAt(1, 1001, 1001, 1, 1, 0, now)}}
	tmpl := character.HeroAcquisitionTemplate{TableID: 1001, OriginTableID: 1001, Kind: character.NormalHero, InitialStar: 1, FragmentItemID: 4001}
	content := acqContent{summon: map[int64]character.HeroNormalSummonPolicy{1001: {Template: tmpl, FragmentCount: 10, Mana: 1000}}}
	costs := &costDebiter{}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	svc := acquisitionService(as, content, &capAuth{max: 10}, costs, &levelReader{level: 100}, rr)
	_, err := svc.SummonNormal(context.Background(), testActor(t), 1001, 4001, 10, testOp(t, "14141414-1414-4414-8414-141414141414"))
	if !errors.Is(err, ErrHeroDuplicateOrigin) {
		t.Fatalf("error=%v", err)
	}
	if costs.calls != 0 || as.inserts != 0 || as.allocatorSaves != 0 || len(rr.m) != 0 {
		t.Fatalf("duplicate summon mutated state costs=%d inserts=%d saves=%d receipts=%d", costs.calls, as.inserts, as.allocatorSaves, len(rr.m))
	}
}

func TestCreateVowsRequiresAllPrerequisitesWithoutMutation(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	heroes := map[int64]character.Hero{
		1: heroAt(1, 101, 101, 5, 1, 0, now),
		2: heroAt(2, 102, 102, 5, 1, 0, now),
		3: heroAt(3, 103, 103, 5, 1, 0, now),
		4: heroAt(4, 104, 104, 5, 1, 0, now),
	}
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 10, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, heroes: heroes}
	content := acqContent{progContent: progContent{template: map[int64]character.HeroTemplateProgression{9001: {Kind: character.SuperHero, OriginTableID: 9001, InitialStar: 1}}, prereq: map[int64][]int64{9001: {101, 102, 103, 104, 105}}}, vowsRequired: 100}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	svc := acquisitionService(as, content, &capAuth{max: 100}, &costDebiter{}, &levelReader{level: 100}, rr)
	_, err := svc.CreateVows(context.Background(), testActor(t), 9001, testOp(t, "15151515-1515-4515-8515-151515151515"))
	if !errors.Is(err, ErrHeroPrerequisites) {
		t.Fatalf("error=%v", err)
	}
	if as.inserts != 0 || as.allocatorSaves != 0 || len(rr.m) != 0 {
		t.Fatalf("missing prerequisites mutated state inserts=%d saves=%d receipts=%d", as.inserts, as.allocatorSaves, len(rr.m))
	}
}

func TestCapacityDenyWritesNoReceipt(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 2, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, heroes: map[int64]character.Hero{1: heroAt(1, 11, 11, 1, 1, 0, now)}}
	tmpl := character.HeroAcquisitionTemplate{TableID: 12, OriginTableID: 12, Kind: character.NormalHero, InitialStar: 1, FragmentItemID: 4012}
	content := acqContent{summon: map[int64]character.HeroNormalSummonPolicy{12: {Template: tmpl, FragmentCount: 10, Mana: 1000}}}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	svc := acquisitionService(as, content, &capAuth{max: 1}, &costDebiter{}, &levelReader{level: 100}, rr)
	_, err := svc.SummonNormal(context.Background(), testActor(t), 12, 4012, 10, testOp(t, "16161616-1616-4616-8616-161616161616"))
	if !errors.Is(err, ErrHeroCapacityExceeded) {
		t.Fatalf("error=%v", err)
	}
	if len(rr.m) != 0 {
		t.Fatalf("capacity denial wrote receipt count=%d", len(rr.m))
	}
}

func TestSummonNormalPinsContentAcrossDefiniteAbortRetryAndActivationChange(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	active := progRev
	activeCalls := 0
	seen := []string{}
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 40, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, heroes: map[int64]character.Hero{}, lockErrOnce: tx.MarkDefiniteAbort(errors.New("retry witness"))}
	as.onLockErr = func() { active = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" }
	tmpl := character.HeroAcquisitionTemplate{TableID: 1001, OriginTableID: 1001, Kind: character.NormalHero, InitialStar: 1, FragmentItemID: 4001}
	content := acqContent{progContent: progContent{active: &active, activeCalls: &activeCalls, seenRevisions: &seen}, summon: map[int64]character.HeroNormalSummonPolicy{1001: {Template: tmpl, FragmentCount: 10, Mana: 1000}}}
	costs := &costDebiter{}
	svc := acquisitionService(as, content, &capAuth{max: 100}, costs, &levelReader{level: 100}, &receipts{m: map[receipt.Identity]receipt.Receipt{}})
	if _, err := svc.SummonNormal(context.Background(), testActor(t), 1001, 4001, 10, testOp(t, "17171717-1717-4717-8717-171717171717")); err != nil {
		t.Fatal(err)
	}
	if activeCalls != 1 {
		t.Fatalf("active content was rebound across retry: calls=%d", activeCalls)
	}
	if len(seen) != 2 || seen[0] != progRev || seen[1] != progRev {
		t.Fatalf("retry escaped bound content revision: %v", seen)
	}
	if as.rootLocks != 2 || costs.calls != 1 || as.inserts != 1 || as.allocatorSaves != 1 {
		t.Fatalf("unexpected retry effects locks=%d costs=%d inserts=%d saves=%d", as.rootLocks, costs.calls, as.inserts, as.allocatorSaves)
	}
}

func TestAcquisitionWithoutCapacityAuthorityFailsClosed(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	as := &acqStore{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 1, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, heroes: map[int64]character.Hero{}}
	tmpl := character.HeroAcquisitionTemplate{TableID: 1001, OriginTableID: 1001, Kind: character.NormalHero, InitialStar: 1, FragmentItemID: 4001}
	content := acqContent{summon: map[int64]character.HeroNormalSummonPolicy{1001: {Template: tmpl, FragmentCount: 10, Mana: 1000}}}
	costs := &costDebiter{}
	svc := acquisitionService(as, content, &capAuth{max: 100}, costs, &levelReader{level: 100}, &receipts{m: map[receipt.Identity]receipt.Receipt{}})
	svc.Capacity = nil
	_, err := svc.SummonNormal(context.Background(), testActor(t), 1001, 4001, 10, testOp(t, "18181818-1818-4818-8818-181818181818"))
	if !errors.Is(err, ErrHeroCapacityUnavailable) {
		t.Fatalf("expected capacity unavailable, got %v", err)
	}
	if as.rootLocks != 0 || costs.calls != 0 || as.inserts != 0 || as.allocatorSaves != 0 {
		t.Fatalf("nil capacity authority reached mutation locks=%d costs=%d inserts=%d saves=%d", as.rootLocks, costs.calls, as.inserts, as.allocatorSaves)
	}
}
