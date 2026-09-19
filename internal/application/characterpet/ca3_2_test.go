package characterpet

import (
	"context"
	"errors"
	"sort"
	"testing"
	"time"

	appgeneration "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type caTag int64

func (t caTag) RowsAffected() int64 { return int64(t) }

type caRow struct{}

func (caRow) Scan(...any) error { return nil }

type caTx struct{}

func (caTx) QueryRow(context.Context, string, ...any) tx.Row             { return caRow{} }
func (caTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return caTag(1), nil }
func (caTx) Commit(context.Context) error                                { return nil }
func (caTx) Rollback(context.Context) error                              { return nil }

type caDB struct{}

func (caDB) Begin(context.Context, tx.Options) (tx.Tx, error) { return caTx{}, nil }

type caReceipts struct {
	m       map[receipt.Identity]receipt.Receipt
	findTxN int
}

func newCAReceipts() *caReceipts { return &caReceipts{m: map[receipt.Identity]receipt.Receipt{}} }
func (r *caReceipts) PutTx(_ context.Context, _ tx.Tx, x receipt.Receipt) (receipt.PutResult, error) {
	if old, ok := r.m[x.Identity]; ok {
		return receipt.PutResult{Receipt: old}, nil
	}
	r.m[x.Identity] = x
	return receipt.PutResult{Receipt: x, Inserted: true}, nil
}
func (r *caReceipts) FindTx(_ context.Context, _ tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	r.findTxN++
	x, ok := r.m[id]
	return x, ok, nil
}
func (r *caReceipts) Find(_ context.Context, id receipt.Identity) (receipt.Receipt, bool, error) {
	x, ok := r.m[id]
	return x, ok, nil
}

type caStore struct {
	root       character.PetRoot
	byID       map[int64]character.Pet
	onLockPet  func()
	lockErrors []error
	lockCalls  int
}

func (s *caStore) ReadPetRoot(context.Context, identity.PlayerID) (character.PetRoot, error) {
	return s.root, nil
}
func (s *caStore) ListPets(context.Context, identity.PlayerID) ([]character.Pet, error) {
	out := make([]character.Pet, 0, len(s.byID))
	for _, p := range s.byID {
		out = append(out, p)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].PetID < out[j].PetID })
	return out, nil
}
func (s *caStore) LockPetRootTx(context.Context, tx.Tx, identity.PlayerID) (character.PetRoot, error) {
	return s.root, nil
}
func (s *caStore) SavePetRootAllocatorTx(_ context.Context, _ tx.Tx, r character.PetRoot, _ int64) error {
	s.root = r
	return nil
}
func (s *caStore) SavePetRootFreeHatchTx(_ context.Context, _ tx.Tx, r character.PetRoot, _ int64) error {
	s.root = r
	return nil
}
func (s *caStore) InsertPetTx(_ context.Context, _ tx.Tx, p character.Pet) error {
	if s.byID == nil {
		s.byID = map[int64]character.Pet{}
	}
	s.byID[p.PetID] = p
	return nil
}
func (s *caStore) FindPetByOriginTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID, origin int64) (character.Pet, bool, error) {
	for _, p := range s.byID {
		if p.OriginTableID == origin {
			return p, true, nil
		}
	}
	return character.Pet{}, false, nil
}
func (s *caStore) LockPetByIDTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, id int64) (character.Pet, bool, error) {
	s.lockCalls++
	if s.onLockPet != nil {
		s.onLockPet()
	}
	if len(s.lockErrors) > 0 {
		err := s.lockErrors[0]
		s.lockErrors = s.lockErrors[1:]
		if err != nil {
			return character.Pet{}, false, err
		}
	}
	p, ok := s.byID[id]
	return p, ok, nil
}
func (s *caStore) SavePetShowStateTx(_ context.Context, _ tx.Tx, p character.Pet, _ int64) error {
	s.byID[p.PetID] = p
	return nil
}
func (s *caStore) SavePetStateTx(_ context.Context, _ tx.Tx, p character.Pet, _ int64) error {
	s.byID[p.PetID] = p
	return nil
}

type caFence struct{}

func (caFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

type caContent struct {
	rev    string
	def    AcquisitionTemplate
	policy AcquisitionPolicy
}

func (c caContent) PetAcquisitionActive(context.Context) (string, bool, error) {
	return c.rev, true, nil
}
func (c caContent) PetAcquisitionRevision(context.Context, string) (bool, error) { return true, nil }
func (c caContent) PetAcquisitionRevisionTx(context.Context, tx.Queryer, string) (bool, error) {
	return true, nil
}
func (c caContent) PetAcquisitionTx(context.Context, tx.Queryer, string, int64) (AcquisitionTemplate, error) {
	return c.def, nil
}
func (c caContent) PetAcquisitionPolicyTx(context.Context, tx.Queryer, string) (AcquisitionPolicy, error) {
	return c.policy, nil
}

type caAcqDebit struct{ calls int }

func (d *caAcqDebit) DebitPetAcquisitionTx(context.Context, tx.Tx, identity.PlayerID, int64, int64, int64, operation.Context) (appi5.PetAcquisitionDebitResult, error) {
	d.calls++
	return appi5.PetAcquisitionDebitResult{ItemID: 50001050, Count: 1, UsedEgg: true}, nil
}
func (d *caAcqDebit) DebitPetAcquisitionAtTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, _, _, _ int64, _ operation.Context, at time.Time) (appi5.PetAcquisitionDebitResult, error) {
	d.calls++
	return appi5.PetAcquisitionDebitResult{ItemID: 50001050, Count: 1, UsedEgg: true}, nil
}

type caMaterial struct {
	calls        int
	last         appi5.MaterialCost
	scalarCalls  int
	scalarKey    string
	scalarAmount int64
	scalarAt     time.Time
}

func (d *caMaterial) DebitMaterialCostTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, c appi5.MaterialCost, _ operation.Context) (appi5.MaterialDebitResult, error) {
	d.calls++
	d.last = c
	return appi5.MaterialDebitResult{}, nil
}
func (d *caMaterial) DebitScalarTx(_ context.Context, _ tx.Tx, pid identity.PlayerID, key string, amount int64, at time.Time) (economy.ScalarBalance, error) {
	d.scalarCalls++
	d.scalarKey, d.scalarAmount, d.scalarAt = key, amount, at.UTC()
	return economy.ScalarBalance{PlayerID: pid, ResourceKey: key, Amount: 999 - amount, StateVersion: 2, UpdatedAt: at.UTC()}, nil
}

type caTime struct{ at time.Time }

func (c *caTime) Now(context.Context) (time.Time, error) { return c.at, nil }

func caActor(t *testing.T) identity.ActorContext {
	u, err := ids.ParseUUID("11111111-1111-4111-8111-111111111111")
	if err != nil {
		t.Fatal(err)
	}
	a, _ := identity.AccountIDFrom(u)
	ss, _ := identity.SessionIDFrom(u)
	cc, _ := identity.ContextIDFrom(u)
	return identity.ActorContext{AccountID: a, AccountUID: "u", SessionID: ss, ContextID: cc, LogicalServerID: 1, PlayerID: 7, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func caOp(t *testing.T, raw string, at int64) operation.Context {
	u, err := ids.ParseUUID(raw)
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: u, StartedAt: time.Unix(at, 0).UTC()}
}
func caService(t *testing.T) (Service, *caStore, *caAcqDebit, *caMaterial, *caTime) {
	now := time.Unix(1, 0).UTC()
	st := &caStore{root: character.PetRoot{PlayerID: 7, NextPetID: 1, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, byID: map[int64]character.Pet{}}
	rec := newCAReceipts()
	acq := &caAcqDebit{}
	mat := &caMaterial{}
	rev := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	def := AcquisitionTemplate{TableID: 10030001, OriginTableID: 10030001, InitialStar: 1, EggItemID: 50001050, EssenceItemID: 90001003, FragmentCount: 10, HatchSeconds: 86400, SummonType: 4}
	tm := &caTime{at: time.Unix(100, 0).UTC()}
	runner := tx.Runner{DB: caDB{}}
	svc := Service{Runner: runner, Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: tm}, Runner: runner}, Store: st, Fencer: caFence{}, Content: caContent{rev: rev, def: def, policy: AcquisitionPolicy{StarterEggItemID: 50001050, HatchCostParam: 12960000}}, Receipts: rec, ReceiptRead: rec, Acquisition: acq, MaterialCosts: mat, Scalar: mat}
	return svc, st, acq, mat, tm
}

func TestSummonCreatesOnceAndLineageRetryDoesNotDebitAgain(t *testing.T) {
	svc, st, acq, _, tm := caService(t)
	actor := caActor(t)
	tm.at = time.Unix(100, 0).UTC()
	p, err := svc.Summon(context.Background(), actor, 10030001, caOp(t, "22222222-2222-4222-8222-222222222222", 100))
	if err != nil {
		t.Fatal(err)
	}
	if p.PetID != 1 || p.Birthday != 100 || acq.calls != 1 || st.root.NextPetID != 2 {
		t.Fatalf("p=%+v root=%+v calls=%d", p, st.root, acq.calls)
	}
	tm.at = time.Unix(101, 0).UTC()
	p2, err := svc.Summon(context.Background(), actor, 10030001, caOp(t, "33333333-3333-4333-8333-333333333333", 101))
	if err != nil {
		t.Fatal(err)
	}
	if p2.PetID != 1 || acq.calls != 1 || st.root.NextPetID != 2 {
		t.Fatalf("retry p=%+v root=%+v calls=%d", p2, st.root, acq.calls)
	}
}

func TestCleanCDFirstUseFreeAndPaidUsesSourceFormula(t *testing.T) {
	svc, st, _, mat, tm := caService(t)
	actor := caActor(t)
	tm.at = time.Unix(100, 0).UTC()
	p, err := svc.Summon(context.Background(), actor, 10030001, caOp(t, "22222222-2222-4222-8222-222222222222", 100))
	if err != nil {
		t.Fatal(err)
	}
	tm.at = time.Unix(200, 0).UTC()
	got, err := svc.CleanCD(context.Background(), actor, p.PetID, caOp(t, "44444444-4444-4444-8444-444444444444", 200))
	if err != nil {
		t.Fatal(err)
	}
	if !got.FirstFree || mat.calls != 0 || !st.root.FirstFreeHatchUsed || !st.byID[p.PetID].IsShow {
		t.Fatalf("got=%+v root=%+v mat=%d", got, st.root, mat.calls)
	}
	// Add a second still-incubating Pet after the one-use flag has been consumed.
	now := time.Unix(100, 0).UTC()
	p2 := p
	p2.PetID = 2
	p2.Birthday = 100
	p2.IsShow = false
	p2.StateVersion = 1
	p2.CreatedAt = now
	p2.UpdatedAt = now
	st.byID[2] = p2
	at := int64(100 + 43200)
	want, _ := hatchCost(86400, 43200, 12960000)
	tm.at = time.Unix(at, 0).UTC()
	got2, err := svc.CleanCD(context.Background(), actor, 2, caOp(t, "55555555-5555-4555-8555-555555555555", at))
	if err != nil {
		t.Fatal(err)
	}
	if got2.FirstFree || got2.CrystalCost != want || mat.scalarCalls != 1 || mat.scalarKey != "crystal" || mat.scalarAmount != want || !mat.scalarAt.Equal(time.Unix(at, 0).UTC()) {
		t.Fatalf("got2=%+v want=%d scalar=%s/%d at=%v", got2, want, mat.scalarKey, mat.scalarAmount, mat.scalarAt)
	}
}

func TestSetShowFailsEarlyAndSucceedsAtDeadline(t *testing.T) {
	svc, st, _, _, tm := caService(t)
	actor := caActor(t)
	tm.at = time.Unix(100, 0).UTC()
	p, err := svc.Summon(context.Background(), actor, 10030001, caOp(t, "22222222-2222-4222-8222-222222222222", 100))
	if err != nil {
		t.Fatal(err)
	}
	tm.at = time.Unix(200, 0).UTC()
	err = svc.SetShow(context.Background(), actor, p.PetID, caOp(t, "66666666-6666-4666-8666-666666666666", 200))
	if !errors.Is(err, ErrPetStillIncubating) {
		t.Fatalf("early err=%v", err)
	}
	if st.byID[p.PetID].IsShow {
		t.Fatal("early set-show mutated Pet")
	}
	tm.at = time.Unix(100+86400, 0).UTC()
	err = svc.SetShow(context.Background(), actor, p.PetID, caOp(t, "77777777-7777-4777-8777-777777777777", 100+86400))
	if err != nil {
		t.Fatal(err)
	}
	if !st.byID[p.PetID].IsShow {
		t.Fatal("deadline did not show Pet")
	}
}

func TestPetLockDefiniteAbortRetriesAndMissingRemainsSemantic(t *testing.T) {
	svc, st, _, _, tm := caService(t)
	actor := caActor(t)
	tm.at = time.Unix(100, 0).UTC()
	p, err := svc.Summon(context.Background(), actor, 10030001, caOp(t, "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", 100))
	if err != nil {
		t.Fatal(err)
	}
	p.IsShow = true
	st.byID[p.PetID] = p
	st.lockCalls = 0
	st.lockErrors = []error{tx.MarkDefiniteAbort(errors.New("serialization abort")), nil}
	tm.at = time.Unix(101, 0).UTC()
	if err := svc.SetShow(context.Background(), actor, p.PetID, caOp(t, "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb", 101)); err != nil {
		t.Fatalf("definite abort was not retried: %v", err)
	}
	if st.lockCalls != 2 {
		t.Fatalf("lock calls=%d want 2", st.lockCalls)
	}

	infra := errors.New("connection lost")
	st.lockCalls = 0
	st.lockErrors = []error{infra}
	if err := svc.SetShow(context.Background(), actor, p.PetID, caOp(t, "cccccccc-cccc-4ccc-8ccc-cccccccccccc", 102)); !errors.Is(err, infra) {
		t.Fatalf("infrastructure error masked as semantic result: %v", err)
	}
	if st.lockCalls != 1 {
		t.Fatalf("ordinary infrastructure error unexpectedly retried: calls=%d", st.lockCalls)
	}

	st.lockErrors = nil
	if err := svc.SetShow(context.Background(), actor, 9999, caOp(t, "dddddddd-dddd-4ddd-8ddd-dddddddddddd", 103)); !errors.Is(err, ErrPetNotFound) {
		t.Fatalf("missing Pet did not map to ErrPetNotFound: %v", err)
	}
}
