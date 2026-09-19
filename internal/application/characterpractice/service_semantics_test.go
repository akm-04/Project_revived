package characterpractice

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"slices"
	"sync"
	"testing"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type practiceHarnessTag int64

func (t practiceHarnessTag) RowsAffected() int64 { return int64(t) }

type practiceHarnessRow struct{ err error }

func (r practiceHarnessRow) Scan(...any) error { return r.err }

type practiceHarnessTx struct {
	h         *practiceHarness
	commitErr error
}

func (t *practiceHarnessTx) QueryRow(context.Context, string, ...any) tx.Row {
	return practiceHarnessRow{err: errors.New("unexpected harness QueryRow")}
}
func (t *practiceHarnessTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return practiceHarnessTag(1), nil
}
func (t *practiceHarnessTx) Commit(context.Context) error   { return t.commitErr }
func (t *practiceHarnessTx) Rollback(context.Context) error { return nil }

type practiceActorState struct {
	tableID int64
	attrs   character.PracticeAttrs
	version int64
}

type practiceHarness struct {
	mu                 sync.Mutex
	revision           string
	root               Root
	heroes             map[int64]practiceActorState
	pets               map[int64]practiceActorState
	heroProposals      map[string]Proposal
	petProposals       map[string]Proposal
	receipts           map[string]receipt.Receipt
	methods            map[int64]Method
	locks              map[int64]LockCost
	facts              PolicyFacts
	vip                int64
	level              int64
	ticketQty          int64
	awakened           bool
	seq                []string
	scalarCalls        int
	scalarKey          string
	scalarAmount       int64
	levelCalls         int
	ticketPrepareCalls int
	ticketApplyCalls   int
	actorCASCalls      int
	commitErr          error
}

func newPracticeHarness(now time.Time) *practiceHarness {
	rev := "86e64265941ab4e438f56548ffa0f1e2d78b77acb9af7204c73706ec048f6041"
	h := &practiceHarness{
		revision:      rev,
		heroes:        map[int64]practiceActorState{11: {tableID: 101, attrs: character.PracticeAttrs{100, 100, 100}, version: 7}, 12: {tableID: 102, attrs: character.PracticeAttrs{50, 60, 70}, version: 4}},
		pets:          map[int64]practiceActorState{21: {tableID: 201, attrs: character.PracticeAttrs{0, 199, 200}, version: 9}},
		heroProposals: map[string]Proposal{}, petProposals: map[string]Proposal{}, receipts: map[string]receipt.Receipt{},
		methods: map[int64]Method{1: {ID: 1, CurrencyType: 1, BaseCost: 20000, VIPMin: 0}, 2: {ID: 2, CurrencyType: 2, BaseCost: 50, VIPMin: 0}, 3: {ID: 3, CurrencyType: 2, BaseCost: 100, VIPMin: 5}},
		locks:   map[int64]LockCost{1: {Count: 1, ManaStep: 70000, CrystalStep: 15, BlessCost: 10}, 2: {Count: 2, ManaStep: 200000, CrystalStep: 40, BlessCost: 40}, 3: {Count: 3, ManaStep: 200000, CrystalStep: 40, BlessCost: 60}},
		facts:   accountingFacts(), vip: 0, level: 100, ticketQty: 3, awakened: true,
	}
	epoch, _ := AlchemyEpochStartV1(now)
	v := int64(0)
	h.root = Root{PlayerID: identity.PlayerID(100001), DailyEpochStartAt: &epoch, DailyEpochPolicyVersion: DailyEpochPolicyV1, BlessRemaining: 100, BlessCapacityAtEpoch: 100, BlessVIPLevelAtEpoch: &v, BlessPrivilegeProviderRevision: "test.vip.v1", BlessContentRevision: rev, StateVersion: 3, CreatedAt: now.Add(-48 * time.Hour), UpdatedAt: now.Add(-time.Hour)}
	return h
}

func (h *practiceHarness) record(s string) { h.seq = append(h.seq, s) }
func (h *practiceHarness) Begin(context.Context, tx.Options) (tx.Tx, error) {
	h.mu.Lock()
	e := h.commitErr
	h.commitErr = nil
	h.mu.Unlock()
	return &practiceHarnessTx{h: h, commitErr: e}, nil
}
func (h *practiceHarness) QueryRow(context.Context, string, ...any) tx.Row {
	return practiceHarnessRow{err: errors.New("unexpected harness QueryRow")}
}

func (h *practiceHarness) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	h.record("fence")
	return nil
}

func (h *practiceHarness) ReadPracticeRootTx(context.Context, tx.Queryer, identity.PlayerID) (Root, error) {
	return h.root, nil
}
func (h *practiceHarness) LockPracticeRootTx(context.Context, tx.Tx, identity.PlayerID) (Root, error) {
	h.record("root")
	return h.root, nil
}
func (h *practiceHarness) SaveGenerationTx(_ context.Context, _ tx.Tx, next Root, old int64) error {
	h.record("root-save-generation")
	if old != h.root.StateVersion || next.StateVersion != old+1 {
		return ErrStaleVersion
	}
	h.root = next
	return nil
}
func (h *practiceHarness) SaveAccountingTx(_ context.Context, _ tx.Tx, next Root, old int64) error {
	h.record("root-save-accounting")
	if old != h.root.StateVersion || next.StateVersion != old+1 {
		return ErrStaleVersion
	}
	h.root = next
	return nil
}
func (h *practiceHarness) EnsureRootTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (bool, error) {
	return false, nil
}
func proposalKey(sid identity.SessionID, id int64) string {
	return sid.UUID().String() + fmt.Sprintf("/%d", id)
}
func (h *practiceHarness) readProposal(m map[string]Proposal, sid identity.SessionID, id int64) (Proposal, error) {
	p, ok := m[proposalKey(sid, id)]
	if !ok {
		return Proposal{}, ErrCandidateMissing
	}
	return p, nil
}
func (h *practiceHarness) ReadHeroProposalTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID, sid identity.SessionID, id int64) (Proposal, error) {
	return h.readProposal(h.heroProposals, sid, id)
}
func (h *practiceHarness) LockHeroProposalTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, sid identity.SessionID, id int64) (Proposal, error) {
	h.record("hero-proposal-lock")
	return h.readProposal(h.heroProposals, sid, id)
}
func (h *practiceHarness) UpsertHeroProposalTx(_ context.Context, _ tx.Tx, p Proposal) error {
	h.record("hero-proposal-upsert")
	h.heroProposals[proposalKey(p.SessionID, p.ActorID)] = p
	return nil
}
func (h *practiceHarness) DeleteHeroProposalTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, sid identity.SessionID, id int64) error {
	h.record("hero-proposal-delete")
	delete(h.heroProposals, proposalKey(sid, id))
	return nil
}
func (h *practiceHarness) ReadPetProposalTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID, sid identity.SessionID, id int64) (Proposal, error) {
	return h.readProposal(h.petProposals, sid, id)
}
func (h *practiceHarness) LockPetProposalTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, sid identity.SessionID, id int64) (Proposal, error) {
	h.record("pet-proposal-lock")
	return h.readProposal(h.petProposals, sid, id)
}
func (h *practiceHarness) UpsertPetProposalTx(_ context.Context, _ tx.Tx, p Proposal) error {
	h.record("pet-proposal-upsert")
	h.petProposals[proposalKey(p.SessionID, p.ActorID)] = p
	return nil
}
func (h *practiceHarness) DeletePetProposalTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, sid identity.SessionID, id int64) error {
	h.record("pet-proposal-delete")
	delete(h.petProposals, proposalKey(sid, id))
	return nil
}

func (h *practiceHarness) LockHeroPracticeTx(_ context.Context, _ tx.Tx, ref character.HeroRef) (HeroPracticeSnapshot, error) {
	h.record("hero")
	s, ok := h.heroes[ref.PartnerID]
	if !ok {
		return HeroPracticeSnapshot{}, ErrActorMissing
	}
	return HeroPracticeSnapshot{Ref: ref, TableID: s.tableID, Practice: s.attrs, StateVersion: s.version}, nil
}
func (h *practiceHarness) CompareAndSwapHeroPracticeTx(_ context.Context, _ tx.Tx, ref character.HeroRef, expected int64, next character.PracticeAttrs, _ time.Time) error {
	h.record("hero-cas")
	s, ok := h.heroes[ref.PartnerID]
	if !ok {
		return ErrActorMissing
	}
	if s.version != expected {
		return ErrActorStaleVersion
	}
	s.attrs = next
	s.version++
	h.heroes[ref.PartnerID] = s
	h.actorCASCalls++
	return nil
}
func (h *practiceHarness) LockPetPracticeTx(_ context.Context, _ tx.Tx, ref character.PetRef) (PetPracticeSnapshot, error) {
	h.record("pet")
	s, ok := h.pets[ref.PetID]
	if !ok {
		return PetPracticeSnapshot{}, ErrActorMissing
	}
	return PetPracticeSnapshot{Ref: ref, TableID: s.tableID, Practice: s.attrs, StateVersion: s.version}, nil
}
func (h *practiceHarness) CompareAndSwapPetPracticeTx(_ context.Context, _ tx.Tx, ref character.PetRef, expected int64, next character.PracticeAttrs, _ time.Time) error {
	h.record("pet-cas")
	s, ok := h.pets[ref.PetID]
	if !ok {
		return ErrActorMissing
	}
	if s.version != expected {
		return ErrActorStaleVersion
	}
	s.attrs = next
	s.version++
	h.pets[ref.PetID] = s
	h.actorCASCalls++
	return nil
}

func (h *practiceHarness) PracticeActive(context.Context) (string, bool, error) {
	return h.revision, true, nil
}
func (h *practiceHarness) PracticeRevision(_ context.Context, r string) (bool, error) {
	return r == h.revision, nil
}
func (h *practiceHarness) PracticeMethodTx(_ context.Context, _ tx.Queryer, _ string, id int64) (Method, error) {
	m, ok := h.methods[id]
	if !ok {
		return Method{}, errors.New("method missing")
	}
	return m, nil
}
func (h *practiceHarness) PracticeLockTx(_ context.Context, _ tx.Queryer, _ string, n int64) (LockCost, error) {
	x, ok := h.locks[n]
	if !ok {
		return LockCost{}, errors.New("lock row missing")
	}
	return x, nil
}
func (h *practiceHarness) PracticeVIPBlessTx(context.Context, tx.Queryer, string, int64) (int64, error) {
	return 100, nil
}
func (h *practiceHarness) PracticePolicyFactsTx(context.Context, tx.Queryer, string) (PolicyFacts, error) {
	return h.facts, nil
}
func (h *practiceHarness) HeroPracticeThresholdsTx(context.Context, tx.Queryer, string, int64) ([]Threshold, error) {
	return nil, nil
}
func (h *practiceHarness) PetPracticeThresholdsTx(context.Context, tx.Queryer, string, int64) ([]Threshold, error) {
	return nil, nil
}
func (h *practiceHarness) HeroTemplateAwakenedTx(context.Context, tx.Queryer, string, int64) (bool, error) {
	return h.awakened, nil
}
func (h *practiceHarness) PetTemplateAwakenedTx(context.Context, tx.Queryer, string, int64) (bool, error) {
	return h.awakened, nil
}
func (h *practiceHarness) SnapshotTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (appi5.PrivilegeSnapshot, error) {
	return appi5.PrivilegeSnapshot{ProviderRevision: "test.vip.v1", VIPLevel: h.vip}, nil
}

func (h *practiceHarness) PlayerLevelTx(context.Context, tx.Tx, identity.PlayerID) (int64, error) {
	h.record("level")
	h.levelCalls++
	return h.level, nil
}
func (h *practiceHarness) AuthorizeLevelAndDebitScalarTx(_ context.Context, _ tx.Tx, pid identity.PlayerID, min int64, key string, amount int64, at time.Time) (int64, economy.ScalarBalance, error) {
	h.record("scalar")
	h.scalarCalls++
	h.scalarKey = key
	h.scalarAmount = amount
	if h.level < min {
		return h.level, economy.ScalarBalance{}, appi5.ErrLevelRequirement
	}
	return h.level, economy.ScalarBalance{PlayerID: pid, ResourceKey: key, Amount: 1_000_000 - amount, StateVersion: 2, UpdatedAt: at}, nil
}
func (h *practiceHarness) PrepareLevelAndStackDebitTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, req appi5.LevelStackDebitRequest, _ operation.Context) (appi5.PreparedLevelStackDebit, error) {
	h.record("ticket-prepare")
	h.ticketPrepareCalls++
	if h.level < req.MinPlayerLevel {
		return appi5.PreparedLevelStackDebit{}, appi5.ErrLevelRequirement
	}
	if req.ItemID != h.facts.TicketItemID || req.Count != 1 {
		return appi5.PreparedLevelStackDebit{}, economy.ErrUnknownResource
	}
	if h.ticketQty < 1 {
		return appi5.PreparedLevelStackDebit{}, economy.ErrInsufficientBalance
	}
	return appi5.PreparedLevelStackDebit{}, nil
}
func (h *practiceHarness) ApplyLevelAndStackDebitTx(context.Context, tx.Tx, appi5.PreparedLevelStackDebit) (appi5.LevelStackDebitResult, error) {
	h.record("ticket-apply")
	h.ticketApplyCalls++
	if h.ticketQty < 1 {
		return appi5.LevelStackDebitResult{}, economy.ErrInsufficientBalance
	}
	h.ticketQty--
	return appi5.LevelStackDebitResult{PlayerLevel: h.level}, nil
}

func practiceReceiptKey(i receipt.Identity) string {
	return i.OwnerKind + "|" + i.OwnerKey + "|" + i.Domain + "|" + i.Operation + "|" + i.SemanticKey
}
func (h *practiceHarness) PutTx(_ context.Context, _ tx.Tx, r receipt.Receipt) (receipt.PutResult, error) {
	h.record("receipt-put")
	k := practiceReceiptKey(r.Identity)
	if old, ok := h.receipts[k]; ok {
		if !bytes.Equal(old.RequestFingerprint[:], r.RequestFingerprint[:]) {
			return receipt.PutResult{}, &receipt.ConflictError{Identity: r.Identity}
		}
		return receipt.PutResult{Receipt: old, Inserted: false}, nil
	}
	h.receipts[k] = r
	return receipt.PutResult{Receipt: r, Inserted: true}, nil
}
func (h *practiceHarness) FindTx(_ context.Context, _ tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	r, ok := h.receipts[practiceReceiptKey(id)]
	return r, ok, nil
}
func (h *practiceHarness) Find(_ context.Context, id receipt.Identity) (receipt.Receipt, bool, error) {
	r, ok := h.receipts[practiceReceiptKey(id)]
	return r, ok, nil
}

func practiceTestUUID(b byte) ids.UUID { var u ids.UUID; u[15] = b; return u }
func practiceTestActor() identity.ActorContext {
	a, _ := identity.AccountIDFrom(practiceTestUUID(1))
	s, _ := identity.SessionIDFrom(practiceTestUUID(2))
	c, _ := identity.ContextIDFrom(practiceTestUUID(3))
	return identity.ActorContext{AccountID: a, AccountUID: identity.AccountUID("20000007"), SessionID: s, ContextID: c, LogicalServerID: 1, PlayerID: 100001, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func practiceTestOp(b byte, at time.Time) operation.Context {
	var seed [32]byte
	for i := range seed {
		seed[i] = byte(i) + b
	}
	return operation.Context{ID: practiceTestUUID(b), StartedAt: at.UTC(), EntropySeed: seed}
}
func practiceHarnessService(h *practiceHarness) Service {
	return Service{Runner: tx.Runner{DB: h}, Store: h, Content: h, Privileges: h, ReconcileQueryer: h, Deps: ServiceDeps{Fencer: h, HeroOwner: h, PetOwner: h, Level: h, LevelAndScalar: h, TicketDebit: h, Receipts: h, ReceiptRead: h}}
}

func TestServiceGETLazyGenerationAndClockRegression(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	svc := practiceHarnessService(h)
	oldEpoch := h.root.DailyEpochStartAt.Add(-24 * time.Hour)
	h.root.DailyEpochStartAt = &oldEpoch
	h.root.DailyEpochPolicyVersion = DailyEpochPolicyV1
	h.root.BaseMana = 777
	h.root.BaseCrystal = 88
	h.root.BlessRemaining = 1
	h.root.BlessCapacityAtEpoch = 100
	info, err := svc.GetInfo(context.Background(), 100001, practiceTestOp(10, now))
	if err != nil {
		t.Fatal(err)
	}
	wantEpoch, _ := AlchemyEpochStartV1(now)
	if h.root.DailyEpochStartAt == nil || !h.root.DailyEpochStartAt.Equal(wantEpoch) || h.root.BaseMana != 0 || h.root.BaseCrystal != 0 || h.root.BlessRemaining != 100 || info.BaseMana != 0 || info.BaseCrystal != 0 || info.BlessValue != 100 {
		t.Fatalf("root=%+v info=%+v", h.root, info)
	}
	ver := h.root.StateVersion
	// Regressing operation time must not reopen or roll back the newer generation.
	if _, err := svc.GetInfo(context.Background(), 100001, practiceTestOp(11, now.Add(-48*time.Hour))); err != nil {
		t.Fatal(err)
	}
	if h.root.StateVersion != ver || !h.root.DailyEpochStartAt.Equal(wantEpoch) {
		t.Fatalf("clock regression changed root: %+v", h.root)
	}
}

func TestServiceManualFreeNoLockReceiptReplayAndConflict(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	op := practiceTestOp(20, now)
	cmd := ManualCommand{Target: Target{Hero: true, ActorID: 11}, Locks: PracticeLocks{}, Method: 1}
	out, err := svc.Manual(context.Background(), actor, cmd, op)
	if err != nil {
		t.Fatal(err)
	}
	if h.levelCalls != 1 || h.scalarCalls != 0 || h.root.FreeLastConsumedAt == nil || !h.root.FreeLastConsumedAt.Equal(now) || h.root.BaseMana != 0 || h.root.BlessRemaining != 100 || h.heroes[11].attrs != (character.PracticeAttrs{100, 100, 100}) {
		t.Fatalf("level=%d scalar=%d root=%+v hero=%+v", h.levelCalls, h.scalarCalls, h.root, h.heroes[11])
	}
	p, ok := h.heroProposals[proposalKey(actor.SessionID, 11)]
	if !ok || p.ActorStateVersion != 7 || p.GenerationOperationID != op.ID || p.GenerationContentRevision != h.revision {
		t.Fatalf("proposal=%+v ok=%v", p, ok)
	}
	if got, ok := p.GenerationPolicyRefs.Get(RollPolicyRef); !ok || got != RollPolicyV1 {
		t.Fatalf("proposal policies=%v", p.GenerationPolicyRefs.Refs())
	}
	rootVersion := h.root.StateVersion
	seqLen := len(h.seq)
	replay, err := svc.Manual(context.Background(), actor, cmd, op)
	if err != nil {
		t.Fatal(err)
	}
	if !replay.Replayed || replay.AddAttr != out.AddAttr || h.levelCalls != 1 || h.root.StateVersion != rootVersion || len(h.seq) != seqLen {
		t.Fatalf("replay=%+v seq=%v", replay, h.seq)
	}
	bad := cmd
	bad.Method = 2
	if _, err := svc.Manual(context.Background(), actor, bad, op); err == nil {
		t.Fatal("same semantic operation with different fingerprint accepted")
	} else {
		var c *receipt.ConflictError
		if !errors.As(err, &c) {
			t.Fatalf("err=%T %v", err, err)
		}
	}
}

func TestServiceManualPaidThreeLockAccountingAndVIPFailClosed(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	last := now.Add(-time.Hour)
	h.root.FreeLastConsumedAt = &last
	h.vip = 5
	cmd := ManualCommand{Target: Target{Hero: true, ActorID: 11}, Locks: PracticeLocks{true, true, true}, Method: 3}
	if _, err := svc.Manual(context.Background(), actor, cmd, practiceTestOp(30, now)); err != nil {
		t.Fatal(err)
	}
	if h.scalarCalls != 1 || h.scalarKey != "crystal" || h.scalarAmount != 290 || h.root.BaseCrystal != 120 || h.root.BlessRemaining != 40 || !h.root.FreeLastConsumedAt.Equal(last) {
		t.Fatalf("scalar=%d %s/%d root=%+v", h.scalarCalls, h.scalarKey, h.scalarAmount, h.root)
	}
	wantOrder := []string{"fence", "hero", "root", "scalar", "root-save-accounting", "hero-proposal-upsert", "receipt-put"}
	if !containsOrdered(h.seq, wantOrder) {
		t.Fatalf("seq=%v want ordered=%v", h.seq, wantOrder)
	}

	h2 := newPracticeHarness(now)
	h2.root.FreeLastConsumedAt = &last
	svc2 := practiceHarnessService(h2)
	if _, err := svc2.Manual(context.Background(), actor, cmd, practiceTestOp(31, now)); !errors.Is(err, ErrPracticePrivilege) {
		t.Fatalf("vip0 err=%v", err)
	}
	if h2.scalarCalls != 0 || len(h2.heroProposals) != 0 {
		t.Fatalf("VIP failure mutated scalar/proposal")
	}
}

func TestServiceSaveAppliesLatestProposalOnceAndStaleFails(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	manual, err := svc.Manual(context.Background(), actor, ManualCommand{Target: Target{Hero: true, ActorID: 11}, Method: 1}, practiceTestOp(40, now))
	if err != nil {
		t.Fatal(err)
	}
	proposal := h.heroProposals[proposalKey(actor.SessionID, 11)]
	rootBefore := h.root
	levelCalls := h.levelCalls
	scalarCalls := h.scalarCalls
	out, err := svc.Save(context.Background(), actor, Target{Hero: true, ActorID: 11}, practiceTestOp(41, now.Add(time.Second)))
	if err != nil {
		t.Fatal(err)
	}
	if out.PracticeAttr != proposal.Proposed || h.heroes[11].attrs != proposal.Proposed || h.heroes[11].version != 8 || h.actorCASCalls != 1 {
		t.Fatalf("out=%+v hero=%+v", out, h.heroes[11])
	}
	if _, ok := h.heroProposals[proposalKey(actor.SessionID, 11)]; ok {
		t.Fatal("proposal not deleted")
	}
	if h.root.StateVersion != rootBefore.StateVersion || h.levelCalls != levelCalls || h.scalarCalls != scalarCalls {
		t.Fatal("SAVE touched Root/I5")
	}
	replay, err := svc.Save(context.Background(), actor, Target{Hero: true, ActorID: 11}, practiceTestOp(41, now.Add(time.Second)))
	if err != nil {
		t.Fatal(err)
	}
	if !replay.Replayed || replay.PracticeAttr != manual.Info.PracticeAttr && replay.PracticeAttr != proposal.Proposed || h.actorCASCalls != 1 {
		t.Fatalf("replay=%+v cas=%d", replay, h.actorCASCalls)
	}

	// Fresh manual followed by an unrelated aggregate version change must fence SAVE.
	if _, err := svc.Manual(context.Background(), actor, ManualCommand{Target: Target{Hero: true, ActorID: 12}, Method: 1}, practiceTestOp(42, now.Add(2*time.Second))); err != nil {
		t.Fatal(err)
	}
	s := h.heroes[12]
	s.version++
	h.heroes[12] = s
	if _, err := svc.Save(context.Background(), actor, Target{Hero: true, ActorID: 12}, practiceTestOp(43, now.Add(3*time.Second))); !errors.Is(err, ErrActorStaleVersion) {
		t.Fatalf("stale err=%v", err)
	}
	if _, ok := h.heroProposals[proposalKey(actor.SessionID, 12)]; !ok {
		t.Fatal("stale SAVE deleted proposal")
	}
}

func TestServiceTicketPetBoundedProposalReplayAndNoRootAccounting(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	rootBefore := h.root
	out, err := svc.Ticket(context.Background(), actor, Target{Hero: false, ActorID: 21}, practiceTestOp(50, now))
	if err != nil {
		t.Fatal(err)
	}
	if out.AddAttr != (PracticeDelta{1, 1, 0}) || h.ticketQty != 2 || h.ticketPrepareCalls != 1 || h.ticketApplyCalls != 1 {
		t.Fatalf("out=%+v qty=%d prep/apply=%d/%d", out, h.ticketQty, h.ticketPrepareCalls, h.ticketApplyCalls)
	}
	if h.root.StateVersion != rootBefore.StateVersion || h.root.BlessRemaining != rootBefore.BlessRemaining || h.root.BaseMana != rootBefore.BaseMana || h.root.BaseCrystal != rootBefore.BaseCrystal || h.root.FreeLastConsumedAt != rootBefore.FreeLastConsumedAt {
		t.Fatalf("ticket changed current-epoch root before=%+v after=%+v", rootBefore, h.root)
	}
	p, ok := h.petProposals[proposalKey(actor.SessionID, 21)]
	if !ok || p.Proposed != (character.PracticeAttrs{1, 200, 200}) || p.GenerationKind != PendingTicket {
		t.Fatalf("proposal=%+v ok=%v", p, ok)
	}
	replay, err := svc.Ticket(context.Background(), actor, Target{Hero: false, ActorID: 21}, practiceTestOp(50, now))
	if err != nil {
		t.Fatal(err)
	}
	if !replay.Replayed || replay.AddAttr != out.AddAttr || h.ticketQty != 2 || h.ticketPrepareCalls != 1 || h.ticketApplyCalls != 1 {
		t.Fatalf("replay=%+v qty=%d", replay, h.ticketQty)
	}
	if !containsOrdered(h.seq, []string{"fence", "pet", "root", "ticket-prepare", "ticket-apply", "pet-proposal-upsert", "receipt-put"}) {
		t.Fatalf("seq=%v", h.seq)
	}
}

func TestServiceUnknownCommitUsesReceiptAndDoesNotReplayBody(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	h.commitErr = errors.New("ambiguous transport after commit")
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	out, err := svc.Manual(context.Background(), actor, ManualCommand{Target: Target{Hero: true, ActorID: 11}, Method: 1}, practiceTestOp(60, now))
	if err != nil {
		t.Fatal(err)
	}
	if !out.Replayed {
		t.Fatalf("reconciled result must decode receipt evidence: %+v", out)
	}
	if h.levelCalls != 1 || countString(h.seq, "root-save-accounting") != 1 || countString(h.seq, "receipt-put") != 1 {
		t.Fatalf("body replayed seq=%v", h.seq)
	}
}

func containsOrdered(got, want []string) bool {
	j := 0
	for _, x := range got {
		if j < len(want) && x == want[j] {
			j++
		}
	}
	return j == len(want)
}
func countString(xs []string, w string) int {
	n := 0
	for _, x := range xs {
		if x == w {
			n++
		}
	}
	return n
}

func TestServiceManualLazyGenerationFoldsIntoSingleRootTransition(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	oldVersion := h.root.StateVersion
	oldEpoch := h.root.DailyEpochStartAt.Add(-24 * time.Hour)
	h.root.DailyEpochStartAt = &oldEpoch
	h.root.BaseMana = 900000
	h.root.BaseCrystal = 123
	h.root.BlessRemaining = 1

	out, err := svc.Manual(context.Background(), actor, ManualCommand{Target: Target{Hero: true, ActorID: 11}, Locks: PracticeLocks{true, false, false}, Method: 1}, practiceTestOp(70, now))
	if err != nil {
		t.Fatal(err)
	}
	wantEpoch, _ := AlchemyEpochStartV1(now)
	if h.root.DailyEpochStartAt == nil || !h.root.DailyEpochStartAt.Equal(wantEpoch) || h.root.StateVersion != oldVersion+1 {
		t.Fatalf("generation/root version not folded into one transition: %+v", h.root)
	}
	if h.root.BaseMana != 70000 || h.root.BaseCrystal != 0 || h.root.BlessRemaining != 90 || h.scalarAmount != 70000 {
		t.Fatalf("daily reset was not applied before lock recurrence: root=%+v scalar=%d", h.root, h.scalarAmount)
	}
	if h.root.FreeLastConsumedAt == nil || !h.root.FreeLastConsumedAt.Equal(now) || out.Info.BaseMana != 70000 || out.Info.BaseCrystal != 0 || out.Info.BlessValue != 90 {
		t.Fatalf("out=%+v root=%+v", out, h.root)
	}
	if countString(h.seq, "root-save-generation") != 0 || countString(h.seq, "root-save-accounting") != 1 {
		t.Fatalf("nested/double root materialization: seq=%v", h.seq)
	}
}

func TestServiceTicketLazyGenerationFoldsIntoSingleRootTransition(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	oldVersion := h.root.StateVersion
	oldEpoch := h.root.DailyEpochStartAt.Add(-24 * time.Hour)
	h.root.DailyEpochStartAt = &oldEpoch
	h.root.BaseMana = 111
	h.root.BaseCrystal = 222
	h.root.BlessRemaining = 1

	out, err := svc.Ticket(context.Background(), actor, Target{Hero: false, ActorID: 21}, practiceTestOp(71, now))
	if err != nil {
		t.Fatal(err)
	}
	wantEpoch, _ := AlchemyEpochStartV1(now)
	if h.root.DailyEpochStartAt == nil || !h.root.DailyEpochStartAt.Equal(wantEpoch) || h.root.StateVersion != oldVersion+1 || h.root.BaseMana != 0 || h.root.BaseCrystal != 0 || h.root.BlessRemaining != 100 {
		t.Fatalf("ticket did not fold daily generation: root=%+v", h.root)
	}
	if out.Info.BaseMana != 0 || out.Info.BaseCrystal != 0 || out.Info.BlessValue != 100 || h.ticketQty != 2 {
		t.Fatalf("out=%+v qty=%d", out, h.ticketQty)
	}
	if countString(h.seq, "root-save-generation") != 0 || countString(h.seq, "root-save-accounting") != 1 {
		t.Fatalf("nested/double root materialization: seq=%v", h.seq)
	}
}

func TestServiceAllCapRejectsBeforeEconomyOrTicketDebit(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	actor := practiceTestActor()

	h := newPracticeHarness(now)
	s := h.heroes[11]
	s.attrs = character.PracticeAttrs{200, 200, 200}
	h.heroes[11] = s
	rootBefore := h.root
	if _, err := practiceHarnessService(h).Manual(context.Background(), actor, ManualCommand{Target: Target{Hero: true, ActorID: 11}, Method: 1}, practiceTestOp(72, now)); !errors.Is(err, ErrPracticeAdmission) {
		t.Fatalf("manual all-cap err=%v", err)
	}
	if h.levelCalls != 0 || h.scalarCalls != 0 || h.root.StateVersion != rootBefore.StateVersion || len(h.heroProposals) != 0 || len(h.receipts) != 0 {
		t.Fatalf("manual all-cap mutated state: level=%d scalar=%d root=%+v proposals=%d receipts=%d", h.levelCalls, h.scalarCalls, h.root, len(h.heroProposals), len(h.receipts))
	}

	h2 := newPracticeHarness(now)
	p := h2.pets[21]
	p.attrs = character.PracticeAttrs{200, 200, 200}
	h2.pets[21] = p
	rootBefore = h2.root
	if _, err := practiceHarnessService(h2).Ticket(context.Background(), actor, Target{Hero: false, ActorID: 21}, practiceTestOp(73, now)); !errors.Is(err, ErrPracticeAdmission) {
		t.Fatalf("ticket all-cap err=%v", err)
	}
	if h2.ticketPrepareCalls != 0 || h2.ticketApplyCalls != 0 || h2.root.StateVersion != rootBefore.StateVersion || len(h2.petProposals) != 0 || len(h2.receipts) != 0 {
		t.Fatalf("ticket all-cap mutated state: prepare/apply=%d/%d root=%+v proposals=%d receipts=%d", h2.ticketPrepareCalls, h2.ticketApplyCalls, h2.root, len(h2.petProposals), len(h2.receipts))
	}
}

func TestServiceReceiptReplayIsReloadStableAndProposalLatestWinsPerSession(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	cmd := ManualCommand{Target: Target{Hero: true, ActorID: 11}, Method: 1}
	op1 := practiceTestOp(74, now)
	first, err := svc.Manual(context.Background(), actor, cmd, op1)
	if err != nil {
		t.Fatal(err)
	}
	// Change durable projection inputs after commit. Exact replay must remain the
	// terminal receipt payload and must not re-enter current content/root state.
	h.root.BaseMana = 999999
	h.root.BlessRemaining = 3
	h.methods[1] = Method{ID: 1, CurrencyType: 1, BaseCost: 777777, VIPMin: 0}
	seqLen := len(h.seq)
	replay, err := svc.Manual(context.Background(), actor, cmd, op1)
	if err != nil {
		t.Fatal(err)
	}
	if !replay.Replayed || replay.Info.LastTime != first.Info.LastTime || replay.Info.PracticeAttr != first.Info.PracticeAttr || !slices.Equal(replay.Info.Lock, first.Info.Lock) || replay.Info.Times != first.Info.Times || replay.Info.BaseCrystal != first.Info.BaseCrystal || replay.Info.BaseMana != first.Info.BaseMana || replay.Info.BlessValue != first.Info.BlessValue || replay.AddAttr != first.AddAttr || len(h.seq) != seqLen {
		t.Fatalf("receipt replay depended on reloaded state: first=%+v replay=%+v seq=%v", first, replay, h.seq)
	}
	// Restore qualified content for a distinct semantic command; same-session
	// generation is latest-wins without changing the aggregate actor version.
	h.methods[1] = Method{ID: 1, CurrencyType: 1, BaseCost: 20000, VIPMin: 0}
	h.root.BlessRemaining = 100
	secondOp := practiceTestOp(75, now.Add(time.Second))
	if _, err := svc.Manual(context.Background(), actor, cmd, secondOp); err != nil {
		t.Fatal(err)
	}
	latest := h.heroProposals[proposalKey(actor.SessionID, 11)]
	if latest.GenerationOperationID != secondOp.ID || latest.ActorStateVersion != 7 || len(h.heroProposals) != 1 {
		t.Fatalf("same-session proposal was not latest-wins: %+v map=%v", latest, h.heroProposals)
	}
	actor2 := actor
	s2, _ := identity.SessionIDFrom(practiceTestUUID(9))
	actor2.SessionID = s2
	thirdOp := practiceTestOp(76, now.Add(2*time.Second))
	if _, err := svc.Manual(context.Background(), actor2, cmd, thirdOp); err != nil {
		t.Fatal(err)
	}
	if len(h.heroProposals) != 2 || h.heroProposals[proposalKey(actor.SessionID, 11)].GenerationOperationID != secondOp.ID || h.heroProposals[proposalKey(actor2.SessionID, 11)].GenerationOperationID != thirdOp.ID {
		t.Fatalf("session-scoped proposals collapsed: %v", h.heroProposals)
	}
}

func TestServiceSaveUnknownCommitResolvesReceiptWithoutSecondActorCAS(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	if _, err := svc.Manual(context.Background(), actor, ManualCommand{Target: Target{Hero: true, ActorID: 11}, Method: 1}, practiceTestOp(80, now)); err != nil {
		t.Fatal(err)
	}
	h.commitErr = errors.New("ambiguous transport after save commit")
	out, err := svc.Save(context.Background(), actor, Target{Hero: true, ActorID: 11}, practiceTestOp(81, now.Add(time.Second)))
	if err != nil {
		t.Fatal(err)
	}
	if !out.Replayed || h.actorCASCalls != 1 || countString(h.seq, "hero-cas") != 1 {
		t.Fatalf("save reconciliation reran actor mutation: out=%+v cas=%d seq=%v", out, h.actorCASCalls, h.seq)
	}
}

func TestServiceTicketUnknownCommitResolvesReceiptWithoutSecondDebit(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	h.commitErr = errors.New("ambiguous transport after ticket commit")
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	out, err := svc.Ticket(context.Background(), actor, Target{Hero: false, ActorID: 21}, practiceTestOp(82, now))
	if err != nil {
		t.Fatal(err)
	}
	if !out.Replayed || h.ticketQty != 2 || h.ticketPrepareCalls != 1 || h.ticketApplyCalls != 1 || countString(h.seq, "pet-proposal-upsert") != 1 {
		t.Fatalf("ticket reconciliation reran debit/body: out=%+v qty=%d prep/apply=%d/%d seq=%v", out, h.ticketQty, h.ticketPrepareCalls, h.ticketApplyCalls, h.seq)
	}
}

func TestServiceAutoHeroAtomicBatchReplayAndConflict(t *testing.T) {
	now := time.Date(2026, 9, 18, 13, 0, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	oldFree := now.Add(-3 * time.Hour)
	h.root.FreeLastConsumedAt = &oldFree
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	cmd := AutoCommand{Target: Target{Hero: true, ActorID: 11}, Locks: PracticeLocks{true, false, false}, Method: 1, BatchSize: 2, Save: AutoSavePredicates{true, false, false, false}}
	op := practiceTestOp(90, now)
	out, err := svc.Auto(context.Background(), actor, cmd, op)
	if err != nil {
		t.Fatal(err)
	}
	if len(out.AddAttrs) != 2 || len(out.IsAdds) != 2 || out.IsAdds[0] != 1 || out.IsAdds[1] != 1 || out.PracticeAttr[0] != 102 {
		t.Fatalf("out=%+v", out)
	}
	if h.scalarCalls != 1 || h.scalarKey != "mana" || h.scalarAmount != 250000 {
		t.Fatalf("scalar calls/key/amount=%d/%s/%d", h.scalarCalls, h.scalarKey, h.scalarAmount)
	}
	if h.root.StateVersion != 4 || h.root.BaseMana != 140000 || h.root.BlessRemaining != 80 || h.root.FreeLastConsumedAt == nil || !h.root.FreeLastConsumedAt.Equal(oldFree) {
		t.Fatalf("root=%+v", h.root)
	}
	if h.heroes[11].version != 8 || h.heroes[11].attrs != out.PracticeAttr || h.actorCASCalls != 1 || len(h.heroProposals) != 0 {
		t.Fatalf("hero=%+v cas=%d proposals=%v", h.heroes[11], h.actorCASCalls, h.heroProposals)
	}
	if !containsOrdered(h.seq, []string{"fence", "hero", "root", "scalar", "root-save-accounting", "hero-cas", "receipt-put"}) {
		t.Fatalf("seq=%v", h.seq)
	}
	if countString(h.seq, "root-save-accounting") != 1 || countString(h.seq, "hero-cas") != 1 || countString(h.seq, "receipt-put") != 1 {
		t.Fatalf("write counts seq=%v", h.seq)
	}

	seqLen := len(h.seq)
	replay, err := svc.Auto(context.Background(), actor, cmd, op)
	if err != nil {
		t.Fatal(err)
	}
	if !replay.Replayed || !slices.Equal(replay.AddAttrs, out.AddAttrs) || !slices.Equal(replay.IsAdds, out.IsAdds) || replay.PracticeAttr != out.PracticeAttr || replay.Info.LastTime != out.Info.LastTime || replay.Info.PracticeAttr != out.Info.PracticeAttr || !slices.Equal(replay.Info.Lock, out.Info.Lock) || replay.Info.Times != out.Info.Times || replay.Info.BaseCrystal != out.Info.BaseCrystal || replay.Info.BaseMana != out.Info.BaseMana || replay.Info.BlessValue != out.Info.BlessValue || len(h.seq) != seqLen || h.scalarCalls != 1 || h.actorCASCalls != 1 {
		t.Fatalf("replay=%+v first=%+v seq=%v", replay, out, h.seq)
	}
	conflict := cmd
	conflict.BatchSize = 4
	if _, err := svc.Auto(context.Background(), actor, conflict, op); err == nil {
		t.Fatal("same semantic key with different AUTO fingerprint did not conflict")
	} else {
		var c *receipt.ConflictError
		if !errors.As(err, &c) {
			t.Fatalf("conflict err=%v", err)
		}
	}
}

func TestServiceAutoAllRejectedStillFencesOlderProposal(t *testing.T) {
	now := time.Date(2026, 9, 18, 13, 10, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	s := h.heroes[11]
	s.attrs = character.PracticeAttrs{200, 100, 100}
	h.heroes[11] = s
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	if _, err := svc.Manual(context.Background(), actor, ManualCommand{Target: Target{Hero: true, ActorID: 11}, Method: 1}, practiceTestOp(91, now)); err != nil {
		t.Fatal(err)
	}
	proposal := h.heroProposals[proposalKey(actor.SessionID, 11)]
	if proposal.ActorStateVersion != 7 {
		t.Fatalf("proposal=%+v", proposal)
	}
	h.seq = nil
	out, err := svc.Auto(context.Background(), actor, AutoCommand{Target: Target{Hero: true, ActorID: 11}, Method: 2, BatchSize: 2, Save: AutoSavePredicates{true, false, false, false}}, practiceTestOp(92, now.Add(time.Second)))
	if err != nil {
		t.Fatal(err)
	}
	if out.PracticeAttr != (character.PracticeAttrs{200, 100, 100}) || !slices.Equal(out.IsAdds, []int64{0, 0}) || h.heroes[11].version != 8 || h.actorCASCalls != 1 {
		t.Fatalf("out=%+v hero=%+v cas=%d", out, h.heroes[11], h.actorCASCalls)
	}
	if len(h.heroProposals) != 1 {
		t.Fatalf("AUTO must leave older proposal row stale, not delete it: %v", h.heroProposals)
	}
	if _, err := svc.Save(context.Background(), actor, Target{Hero: true, ActorID: 11}, practiceTestOp(93, now.Add(2*time.Second))); !errors.Is(err, ErrActorStaleVersion) {
		t.Fatalf("stale pre-AUTO proposal SAVE err=%v", err)
	}
	if h.actorCASCalls != 1 {
		t.Fatalf("stale SAVE performed second actor CAS: %d", h.actorCASCalls)
	}
}

func TestServiceAutoUnknownCommitResolvesExactReceiptWithoutSecondMutation(t *testing.T) {
	now := time.Date(2026, 9, 18, 13, 20, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	h.commitErr = errors.New("ambiguous transport after AUTO commit")
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	cmd := AutoCommand{Target: Target{Hero: false, ActorID: 21}, Method: 2, BatchSize: 4, Save: AutoSavePredicates{false, false, false, true}}
	out, err := svc.Auto(context.Background(), actor, cmd, practiceTestOp(94, now))
	if err != nil {
		t.Fatal(err)
	}
	if !out.Replayed || len(out.AddAttrs) != 4 || len(out.IsAdds) != 4 || h.scalarCalls != 1 || h.actorCASCalls != 1 || countString(h.seq, "root-save-accounting") != 1 || countString(h.seq, "pet-cas") != 1 || countString(h.seq, "receipt-put") != 1 {
		t.Fatalf("out=%+v scalar=%d cas=%d seq=%v", out, h.scalarCalls, h.actorCASCalls, h.seq)
	}
}

func TestServiceAutoLazyGenerationFoldsResetAndAccountingIntoOneRootCAS(t *testing.T) {
	now := time.Date(2026, 9, 18, 13, 30, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	oldEpoch := h.root.DailyEpochStartAt.Add(-24 * time.Hour)
	h.root.DailyEpochStartAt = &oldEpoch
	h.root.BaseMana = 999999
	h.root.BaseCrystal = 123
	h.root.BlessRemaining = 1
	oldVersion := h.root.StateVersion
	out, err := practiceHarnessService(h).Auto(context.Background(), practiceTestActor(), AutoCommand{Target: Target{Hero: true, ActorID: 11}, Locks: PracticeLocks{true, false, false}, Method: 1, BatchSize: 2, Save: AutoSavePredicates{true, false, false, false}}, practiceTestOp(95, now))
	if err != nil {
		t.Fatal(err)
	}
	wantEpoch, _ := AlchemyEpochStartV1(now)
	if h.root.DailyEpochStartAt == nil || !h.root.DailyEpochStartAt.Equal(wantEpoch) || h.root.StateVersion != oldVersion+1 || h.root.BaseMana != 140000 || h.root.BaseCrystal != 0 || h.root.BlessRemaining != 80 || h.scalarAmount != 250000 {
		t.Fatalf("root=%+v scalar=%d", h.root, h.scalarAmount)
	}
	if out.Info.BaseMana != 140000 || out.Info.BaseCrystal != 0 || out.Info.BlessValue != 80 || countString(h.seq, "root-save-generation") != 0 || countString(h.seq, "root-save-accounting") != 1 {
		t.Fatalf("out=%+v seq=%v", out, h.seq)
	}
}

func TestServiceAutoAllCapRejectsBeforeDebitOrWrites(t *testing.T) {
	now := time.Date(2026, 9, 18, 13, 40, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	s := h.pets[21]
	s.attrs = character.PracticeAttrs{200, 200, 200}
	h.pets[21] = s
	rootBefore := h.root
	_, err := practiceHarnessService(h).Auto(context.Background(), practiceTestActor(), AutoCommand{Target: Target{Hero: false, ActorID: 21}, Method: 2, BatchSize: 2, Save: AutoSavePredicates{false, false, false, true}}, practiceTestOp(96, now))
	if !errors.Is(err, ErrPracticeAdmission) {
		t.Fatalf("all-cap err=%v", err)
	}
	if h.scalarCalls != 0 || h.actorCASCalls != 0 || h.root.StateVersion != rootBefore.StateVersion || len(h.receipts) != 0 || countString(h.seq, "root-save-accounting") != 0 {
		t.Fatalf("all-cap mutated state scalar=%d cas=%d root=%+v receipts=%d seq=%v", h.scalarCalls, h.actorCASCalls, h.root, len(h.receipts), h.seq)
	}
}

func TestServiceAutoSerialAcceptedOrderPreservesSharedRootAccounting(t *testing.T) {
	now := time.Date(2026, 9, 18, 14, 0, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	cmd := AutoCommand{Locks: PracticeLocks{true, false, false}, Method: 1, BatchSize: 2, Save: AutoSavePredicates{true, false, false, false}}

	// Same actor twice: accepted serialization must carry Root450 running-base
	// accounting forward and advance the common actor fence on each command.
	cmd.Target = Target{Hero: true, ActorID: 11}
	if _, err := svc.Auto(context.Background(), actor, cmd, practiceTestOp(97, now)); err != nil {
		t.Fatal(err)
	}
	if _, err := svc.Auto(context.Background(), actor, cmd, practiceTestOp(98, now.Add(time.Second))); err != nil {
		t.Fatal(err)
	}
	if h.root.StateVersion != 5 || h.root.BaseMana != 280000 || h.root.BlessRemaining != 60 || h.heroes[11].version != 9 || h.scalarCalls != 2 || h.actorCASCalls != 2 {
		t.Fatalf("same-actor accepted order lost state: root=%+v hero=%+v scalar=%d cas=%d", h.root, h.heroes[11], h.scalarCalls, h.actorCASCalls)
	}

	// A different typed actor on the same player must continue from that same
	// Root450 accounting state rather than from a per-actor copy.
	cmd.Target = Target{Hero: false, ActorID: 21}
	if _, err := svc.Auto(context.Background(), actor, cmd, practiceTestOp(99, now.Add(2*time.Second))); err != nil {
		t.Fatal(err)
	}
	if h.root.StateVersion != 6 || h.root.BaseMana != 420000 || h.root.BlessRemaining != 40 || h.pets[21].version != 10 || h.scalarCalls != 3 || h.actorCASCalls != 3 {
		t.Fatalf("cross-actor accepted order lost shared accounting: root=%+v pet=%+v scalar=%d cas=%d", h.root, h.pets[21], h.scalarCalls, h.actorCASCalls)
	}
}

func TestServiceAutoFencesSameAndDifferentSessionProposals(t *testing.T) {
	now := time.Date(2026, 9, 18, 14, 10, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	svc := practiceHarnessService(h)
	actorA := practiceTestActor()
	actorB := actorA
	sidB, _ := identity.SessionIDFrom(practiceTestUUID(12))
	actorB.SessionID = sidB

	manual := ManualCommand{Target: Target{Hero: true, ActorID: 11}, Method: 1}
	if _, err := svc.Manual(context.Background(), actorA, manual, practiceTestOp(100, now)); err != nil {
		t.Fatal(err)
	}
	if _, err := svc.Manual(context.Background(), actorB, manual, practiceTestOp(101, now.Add(time.Second))); err != nil {
		t.Fatal(err)
	}
	if len(h.heroProposals) != 2 {
		t.Fatalf("expected isolated session proposals, got %v", h.heroProposals)
	}

	if _, err := svc.Auto(context.Background(), actorA, AutoCommand{Target: Target{Hero: true, ActorID: 11}, Method: 2, BatchSize: 2, Save: AutoSavePredicates{false, false, false, true}}, practiceTestOp(102, now.Add(2*time.Second))); err != nil {
		t.Fatal(err)
	}
	if h.heroes[11].version != 8 || len(h.heroProposals) != 2 {
		t.Fatalf("AUTO must fence but not own/delete proposals: hero=%+v proposals=%v", h.heroes[11], h.heroProposals)
	}
	for i, actor := range []identity.ActorContext{actorA, actorB} {
		if _, err := svc.Save(context.Background(), actor, Target{Hero: true, ActorID: 11}, practiceTestOp(byte(103+i), now.Add(time.Duration(3+i)*time.Second))); !errors.Is(err, ErrActorStaleVersion) {
			t.Fatalf("session %d stale proposal SAVE err=%v", i, err)
		}
	}
	if h.actorCASCalls != 1 {
		t.Fatalf("stale proposal SAVE performed extra actor CAS: %d", h.actorCASCalls)
	}
}

func TestServiceSaveThenAutoPreservesAcceptedActorOrder(t *testing.T) {
	now := time.Date(2026, 9, 18, 14, 20, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	if _, err := svc.Manual(context.Background(), actor, ManualCommand{Target: Target{Hero: true, ActorID: 11}, Method: 1}, practiceTestOp(105, now)); err != nil {
		t.Fatal(err)
	}
	if _, err := svc.Save(context.Background(), actor, Target{Hero: true, ActorID: 11}, practiceTestOp(106, now.Add(time.Second))); err != nil {
		t.Fatal(err)
	}
	if h.heroes[11].version != 8 || len(h.heroProposals) != 0 || h.actorCASCalls != 1 {
		t.Fatalf("SAVE did not establish expected actor fence: hero=%+v proposals=%v cas=%d", h.heroes[11], h.heroProposals, h.actorCASCalls)
	}
	if _, err := svc.Auto(context.Background(), actor, AutoCommand{Target: Target{Hero: true, ActorID: 11}, Method: 2, BatchSize: 2, Save: AutoSavePredicates{false, false, false, true}}, practiceTestOp(107, now.Add(2*time.Second))); err != nil {
		t.Fatal(err)
	}
	if h.heroes[11].version != 9 || h.actorCASCalls != 2 {
		t.Fatalf("AUTO did not serialize after SAVE: hero=%+v cas=%d", h.heroes[11], h.actorCASCalls)
	}
}

func TestServiceAutoReceiptReplaySurvivesLaterDurableStateChanges(t *testing.T) {
	now := time.Date(2026, 9, 18, 14, 30, 0, 0, time.UTC)
	h := newPracticeHarness(now)
	svc := practiceHarnessService(h)
	actor := practiceTestActor()
	cmd := AutoCommand{Target: Target{Hero: true, ActorID: 11}, Method: 2, BatchSize: 4, Save: AutoSavePredicates{false, false, false, true}}
	op := practiceTestOp(108, now)
	first, err := svc.Auto(context.Background(), actor, cmd, op)
	if err != nil {
		t.Fatal(err)
	}
	seqLen := len(h.seq)
	scalarCalls := h.scalarCalls
	casCalls := h.actorCASCalls

	// Simulate later committed state. Semantic receipt replay must project the
	// original terminal response and must not consult/rewrite this newer state.
	h.root.BaseMana = 999999
	h.root.BaseCrystal = 777
	h.root.BlessRemaining = 3
	h.root.StateVersion += 10
	hero := h.heroes[11]
	hero.attrs = character.PracticeAttrs{1, 2, 3}
	hero.version += 10
	h.heroes[11] = hero

	replay, err := svc.Auto(context.Background(), actor, cmd, op)
	if err != nil {
		t.Fatal(err)
	}
	if !replay.Replayed || !slices.Equal(replay.AddAttrs, first.AddAttrs) || !slices.Equal(replay.IsAdds, first.IsAdds) || replay.PracticeAttr != first.PracticeAttr || replay.Info.LastTime != first.Info.LastTime || replay.Info.PracticeAttr != first.Info.PracticeAttr || !slices.Equal(replay.Info.Lock, first.Info.Lock) || replay.Info.Times != first.Info.Times || replay.Info.BaseCrystal != first.Info.BaseCrystal || replay.Info.BaseMana != first.Info.BaseMana || replay.Info.BlessValue != first.Info.BlessValue {
		t.Fatalf("replay drifted after later state: first=%+v replay=%+v", first, replay)
	}
	if len(h.seq) != seqLen || h.scalarCalls != scalarCalls || h.actorCASCalls != casCalls {
		t.Fatalf("receipt replay reran body: seq=%v scalar=%d/%d cas=%d/%d", h.seq, h.scalarCalls, scalarCalls, h.actorCASCalls, casCalls)
	}
}
