package i5

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/audit"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type testTag int64

func (t testTag) RowsAffected() int64 { return int64(t) }

type testRow struct{ err error }

func (r testRow) Scan(...any) error { return r.err }

type testTx struct {
	commitErr  error
	committed  bool
	rolledBack bool
}

func (t *testTx) QueryRow(context.Context, string, ...any) tx.Row             { return testRow{} }
func (t *testTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return testTag(1), nil }
func (t *testTx) Commit(context.Context) error                                { t.committed = t.commitErr == nil; return t.commitErr }
func (t *testTx) Rollback(context.Context) error                              { t.rolledBack = true; return nil }

type testBeginner struct {
	mu           sync.Mutex
	beginCount   int
	commitErrors []error
	txs          []*testTx
}

func (b *testBeginner) Begin(context.Context, tx.Options) (tx.Tx, error) {
	b.mu.Lock()
	defer b.mu.Unlock()
	i := b.beginCount
	b.beginCount++
	var ce error
	if i < len(b.commitErrors) {
		ce = b.commitErrors[i]
	}
	t := &testTx{commitErr: ce}
	b.txs = append(b.txs, t)
	return t, nil
}

type memoryReceipts struct {
	mu sync.Mutex
	m  map[receipt.Identity]receipt.Receipt
}

func newMemoryReceipts() *memoryReceipts {
	return &memoryReceipts{m: map[receipt.Identity]receipt.Receipt{}}
}
func (s *memoryReceipts) PutTx(_ context.Context, _ tx.Tx, r receipt.Receipt) (receipt.PutResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if old, ok := s.m[r.Identity]; ok {
		return receipt.PutResult{Receipt: old, Inserted: false}, nil
	}
	s.m[r.Identity] = r
	return receipt.PutResult{Receipt: r, Inserted: true}, nil
}
func (s *memoryReceipts) FindTx(_ context.Context, _ tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	r, ok := s.m[id]
	return r, ok, nil
}
func (s *memoryReceipts) Find(_ context.Context, id receipt.Identity) (receipt.Receipt, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	r, ok := s.m[id]
	return r, ok, nil
}

type missingReceiptReader struct{}

func (missingReceiptReader) Find(context.Context, receipt.Identity) (receipt.Receipt, bool, error) {
	return receipt.Receipt{}, false, nil
}

const (
	testContentRevisionA = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	testContentRevisionB = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
)

type testContent struct {
	mu                  sync.Mutex
	activeRevisions     []string
	activeCalls         int
	policies            map[grant.LineKind]ResourcePolicy
	resolveErrors       []error
	resolveCalls        int
	seenRevisions       []string
	objectives          map[string]ObjectiveDefinition
	progressionPolicies map[string]player.ProgressionPolicy
	functionPolicies    map[string]FunctionGatePolicy
	wantQueryer         tx.Queryer
	wrongQueryer        bool
}

func (c *testContent) ActiveRevision(_ context.Context, q tx.Queryer) (string, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.wantQueryer != nil && q != c.wantQueryer {
		c.wrongQueryer = true
	}
	i := c.activeCalls
	c.activeCalls++
	if len(c.activeRevisions) == 0 {
		return testContentRevisionA, nil
	}
	if i >= len(c.activeRevisions) {
		i = len(c.activeRevisions) - 1
	}
	return c.activeRevisions[i], nil
}

func (c *testContent) ResolveResourceTx(_ context.Context, q tx.Queryer, revision string, line grant.Line) (ResourcePolicy, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.wantQueryer != nil && q != c.wantQueryer {
		c.wrongQueryer = true
	}
	c.seenRevisions = append(c.seenRevisions, revision)
	i := c.resolveCalls
	c.resolveCalls++
	if i < len(c.resolveErrors) && c.resolveErrors[i] != nil {
		return ResourcePolicy{}, c.resolveErrors[i]
	}
	p, ok := c.policies[line.Kind]
	if !ok {
		return ResourcePolicy{}, economy.ErrUnknownResource
	}
	if line.Kind == grant.StackItem && p.Stack != nil && p.Stack.ItemID != line.ItemID {
		return ResourcePolicy{}, economy.ErrUnknownResource
	}
	return p, nil
}

func (c *testContent) ResolveProgressionPolicyTx(_ context.Context, q tx.Queryer, revision string) (player.ProgressionPolicy, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.wantQueryer != nil && q != c.wantQueryer {
		c.wrongQueryer = true
	}
	c.seenRevisions = append(c.seenRevisions, revision)
	if p, ok := c.progressionPolicies[revision]; ok {
		return p, nil
	}
	return player.ProgressionPolicy{}, economy.ErrUnknownResource
}

func (c *testContent) ResolveFunctionGatePolicyTx(_ context.Context, q tx.Queryer, revision string) (FunctionGatePolicy, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.wantQueryer != nil && q != c.wantQueryer {
		c.wrongQueryer = true
	}
	c.seenRevisions = append(c.seenRevisions, revision)
	if p, ok := c.functionPolicies[revision]; ok {
		return p, nil
	}
	return FunctionGatePolicy{}, economy.ErrUnknownResource
}

func (c *testContent) ResolvePetStarterPolicyTx(_ context.Context, q tx.Queryer, revision string) (PetStarterPolicy, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.wantQueryer != nil && q != c.wantQueryer {
		c.wrongQueryer = true
	}
	c.seenRevisions = append(c.seenRevisions, revision)
	return PetStarterPolicy{StarterEggItemID: 50001050}, nil
}

func objectiveContentKey(revision, program string, objectiveID int64, definitionRevision string) string {
	return fmt.Sprintf("%s\x00%s\x00%d\x00%s", revision, program, objectiveID, definitionRevision)
}

func (c *testContent) ResolveObjective(_ context.Context, revision, program string, objectiveID int64, definitionRevision string) (ObjectiveDefinition, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.seenRevisions = append(c.seenRevisions, revision)
	d, ok := c.objectives[objectiveContentKey(revision, program, objectiveID, definitionRevision)]
	if !ok {
		return ObjectiveDefinition{}, ErrObjectiveNotFound
	}
	return d, nil
}

func (c *testContent) ResolveObjectiveTx(_ context.Context, q tx.Queryer, revision, program string, objectiveID int64, definitionRevision string) (ObjectiveDefinition, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.wantQueryer != nil && q != c.wantQueryer {
		c.wrongQueryer = true
	}
	c.seenRevisions = append(c.seenRevisions, revision)
	d, ok := c.objectives[objectiveContentKey(revision, program, objectiveID, definitionRevision)]
	if !ok {
		return ObjectiveDefinition{}, ErrObjectiveNotFound
	}
	return d, nil
}

type testStore struct {
	Store // nil embedded interface supplies unexercised methods

	mu                   sync.Mutex
	policies             map[grant.LineKind]ResourcePolicy
	scalar               economy.ScalarBalance
	scalarExists         bool
	saveScalarCalls      int
	progression          player.Progression
	saveProgressionCalls int
	temporal             map[string]economy.TemporalState
	saveTemporalCalls    int
	rebindTemporalCalls  int
	legacyTemporal       map[string]ResourcePolicy
	functionVersion      int64
	eligibility          map[int64]player.FunctionEligibility
	unlocks              map[int64]player.FunctionUnlock
	advanceFunctionCalls int

	stack            economy.StackState
	stackExists      bool
	saveStackCalls   int
	deleteStackCalls int

	nextMailID    int64
	insertedMail  []mail.Record
	lockedMail    mail.Record
	saveMailCalls int
	fenceCalls    int
	lockTrace     []string

	objectiveInst      objective.Instance
	objectiveDef       ObjectiveDefinition
	saveObjectiveCalls int
}

func legacyTemporalTestKey(resourceKey, policyVersion string) string {
	return resourceKey + "\x00" + policyVersion
}

func (s *testStore) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	s.mu.Lock()
	s.fenceCalls++
	s.mu.Unlock()
	return nil
}
func (s *testStore) LockEconomyOwnerTx(context.Context, tx.Tx, identity.PlayerID) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.lockTrace = append(s.lockTrace, "economy-owner")
	return nil
}
func (s *testStore) LockMailNamespaceCounterTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, ns mail.Namespace) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.lockTrace = append(s.lockTrace, "mail:"+ns.String())
	return nil
}
func (s *testStore) ResolveResourceTx(_ context.Context, _ tx.Tx, line grant.Line) (ResourcePolicy, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	p, ok := s.policies[line.Kind]
	if !ok {
		return ResourcePolicy{}, economy.ErrUnknownResource
	}
	if line.Kind == grant.StackItem && p.Stack != nil && p.Stack.ItemID != line.ItemID {
		return ResourcePolicy{}, economy.ErrUnknownResource
	}
	return p, nil
}
func (s *testStore) LockScalarTx(_ context.Context, _ tx.Tx, pid identity.PlayerID, key string, _ time.Time) (economy.ScalarBalance, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.lockTrace = append(s.lockTrace, "scalar:"+key)
	if !s.scalarExists {
		return economy.ScalarBalance{}, false, nil
	}
	if s.scalar.PlayerID != pid || s.scalar.ResourceKey != key {
		return economy.ScalarBalance{}, false, nil
	}
	return s.scalar, true, nil
}
func (s *testStore) SaveScalarTx(_ context.Context, _ tx.Tx, b economy.ScalarBalance, _ bool) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.scalar = b
	s.scalarExists = true
	s.saveScalarCalls++
	return nil
}
func (s *testStore) ReadScalarTx(_ context.Context, _ tx.Queryer, pid identity.PlayerID, key string) (economy.ScalarBalance, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.scalarExists || s.scalar.PlayerID != pid || s.scalar.ResourceKey != key {
		return economy.ScalarBalance{}, false, nil
	}
	return s.scalar, true, nil
}
func (s *testStore) ReadProgressionTx(_ context.Context, _ tx.Queryer, pid identity.PlayerID) (player.Progression, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.progression.PlayerID != pid {
		return player.Progression{}, errors.New("progression not found")
	}
	return s.progression, nil
}
func (s *testStore) LockProgressionTx(_ context.Context, _ tx.Tx, pid identity.PlayerID) (player.Progression, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.lockTrace = append(s.lockTrace, "progression")
	if s.progression.PlayerID != pid {
		return player.Progression{}, errors.New("progression not found")
	}
	return s.progression, nil
}
func (s *testStore) SaveProgressionTx(_ context.Context, _ tx.Tx, got player.Progression, expected int64) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.progression.StateVersion != expected {
		return errors.New("progression optimistic conflict")
	}
	s.progression = got
	s.saveProgressionCalls++
	return nil
}
func (s *testStore) LockTemporalTx(_ context.Context, _ tx.Tx, pid identity.PlayerID, key string) (economy.TemporalState, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.lockTrace = append(s.lockTrace, "temporal:"+key)
	st, ok := s.temporal[key]
	if !ok || st.PlayerID != pid {
		return economy.TemporalState{}, false, nil
	}
	return st, true, nil
}
func (s *testStore) SaveTemporalTx(_ context.Context, _ tx.Tx, st economy.TemporalState) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.temporal == nil {
		s.temporal = map[string]economy.TemporalState{}
	}
	old, ok := s.temporal[st.ResourceKey]
	if !ok || st.StateVersion != old.StateVersion+1 {
		return errors.New("temporal optimistic conflict")
	}
	s.temporal[st.ResourceKey] = st
	s.saveTemporalCalls++
	return nil
}
func (s *testStore) ResolveLegacyTemporalPolicyTx(_ context.Context, _ tx.Queryer, resourceKey, policyVersion string) (ResourcePolicy, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	p, ok := s.legacyTemporal[legacyTemporalTestKey(resourceKey, policyVersion)]
	if !ok {
		return ResourcePolicy{}, economy.ErrUnknownResource
	}
	return p, nil
}
func (s *testStore) RebindTemporalTx(_ context.Context, _ tx.Tx, st economy.TemporalState, expected int64) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.temporal == nil {
		return errors.New("temporal row missing")
	}
	old, ok := s.temporal[st.ResourceKey]
	if !ok || old.StateVersion != expected || old.ContentRevision != "" || st.StateVersion != expected+1 {
		return errors.New("temporal rebind optimistic conflict")
	}
	s.temporal[st.ResourceKey] = st
	s.rebindTemporalCalls++
	return nil
}
func (s *testStore) LockFunctionStateTx(_ context.Context, _ tx.Tx, pid identity.PlayerID) (int64, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.lockTrace = append(s.lockTrace, "function-state")
	if !pid.Valid() {
		return 0, errors.New("invalid player")
	}
	if s.functionVersion == 0 {
		s.functionVersion = 1
	}
	return s.functionVersion, nil
}
func (s *testStore) InsertFunctionEligibilityTx(_ context.Context, _ tx.Tx, e player.FunctionEligibility) (bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.eligibility == nil {
		s.eligibility = map[int64]player.FunctionEligibility{}
	}
	if _, ok := s.eligibility[e.FunctionID]; ok {
		return false, nil
	}
	s.eligibility[e.FunctionID] = e
	return true, nil
}
func (s *testStore) InsertFunctionUnlockTx(_ context.Context, _ tx.Tx, u player.FunctionUnlock) (bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.unlocks == nil {
		s.unlocks = map[int64]player.FunctionUnlock{}
	}
	if _, ok := s.unlocks[u.FunctionID]; ok {
		return false, nil
	}
	s.unlocks[u.FunctionID] = u
	return true, nil
}
func (s *testStore) AdvanceFunctionStateTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, expected int64, _ time.Time) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.functionVersion == 0 {
		s.functionVersion = 1
	}
	if s.functionVersion != expected {
		return errors.New("function-state optimistic conflict")
	}
	s.functionVersion++
	s.advanceFunctionCalls++
	return nil
}

func (s *testStore) ReadTemporalTx(_ context.Context, _ tx.Queryer, pid identity.PlayerID, key string) (economy.TemporalState, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	st, ok := s.temporal[key]
	if !ok || st.PlayerID != pid {
		return economy.TemporalState{}, false, nil
	}
	return st, true, nil
}
func (s *testStore) LockStackTx(_ context.Context, _ tx.Tx, pid identity.PlayerID, itemID int64, now time.Time) (economy.StackState, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.lockTrace = append(s.lockTrace, fmt.Sprintf("stack:%d", itemID))
	if !s.stackExists {
		return economy.StackState{}, false, nil
	}
	if s.stack.PlayerID != pid || s.stack.ItemID != itemID {
		return economy.StackState{}, false, nil
	}
	return s.stack, true, nil
}
func (s *testStore) SaveStackTx(_ context.Context, _ tx.Tx, st economy.StackState, _ bool) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.stack = st
	s.stackExists = true
	s.saveStackCalls++
	return nil
}
func (s *testStore) DeleteStackTx(_ context.Context, _ tx.Tx, st economy.StackState) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.stackExists || s.stack.PlayerID != st.PlayerID || s.stack.ItemID != st.ItemID || s.stack.StateVersion != st.StateVersion-1 {
		return errors.New("stack delete optimistic conflict")
	}
	s.stack = economy.StackState{}
	s.stackExists = false
	s.deleteStackCalls++
	return nil
}
func (s *testStore) AllocateMailWireIDTx(context.Context, tx.Tx, identity.PlayerID, mail.Namespace) (int64, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.nextMailID == 0 {
		s.nextMailID = 1
	}
	v := s.nextMailID
	s.nextMailID++
	return v, nil
}
func (s *testStore) InsertMailTx(_ context.Context, _ tx.Tx, r mail.Record) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.insertedMail = append(s.insertedMail, r)
	return nil
}
func (s *testStore) LockMailTx(_ context.Context, _ tx.Tx, pid identity.PlayerID, addr mail.Address) (mail.Record, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.lockedMail.Recipient != pid || s.lockedMail.Address != addr {
		return mail.Record{}, ErrMailNotFound
	}
	return s.lockedMail, nil
}
func (s *testStore) SaveMailStateTx(_ context.Context, _ tx.Tx, r mail.Record, _ int64) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.lockedMail = r
	s.saveMailCalls++
	return nil
}
func (s *testStore) LockObjectiveTx(_ context.Context, _ tx.Tx, pid identity.PlayerID, family objective.StockFamily, objectiveID int64, generation string) (objective.Instance, ObjectiveDefinition, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.objectiveInst.PlayerID != pid || s.objectiveInst.ObjectiveID != objectiveID || s.objectiveInst.GenerationID != generation || (s.objectiveInst.ContentRevision == "" && s.objectiveDef.Family != family) {
		return objective.Instance{}, ObjectiveDefinition{}, ErrObjectiveNotFound
	}
	return s.objectiveInst, s.objectiveDef, nil
}
func (s *testStore) LockObjectiveForClaimTx(_ context.Context, _ tx.Tx, pid identity.PlayerID, objectiveID int64, generation string) (objective.Instance, ObjectiveDefinition, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.objectiveInst.PlayerID != pid || s.objectiveInst.ObjectiveID != objectiveID || (generation != "" && s.objectiveInst.GenerationID != generation) {
		return objective.Instance{}, ObjectiveDefinition{}, ErrObjectiveNotFound
	}
	return s.objectiveInst, s.objectiveDef, nil
}
func (s *testStore) SaveObjectiveTx(_ context.Context, _ tx.Tx, inst objective.Instance, _ int64) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.objectiveInst = inst
	s.saveObjectiveCalls++
	return nil
}

type testDirectory struct {
	mu      sync.Mutex
	level   int64
	version int64
	failSet bool
	trace   *[]string
}

func (d *testDirectory) LockTx(_ context.Context, _ tx.Tx, _ identity.PlayerID) (DirectoryLevelProjection, error) {
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.trace != nil {
		*d.trace = append(*d.trace, "directory")
	}
	if d.version == 0 {
		d.version = 1
	}
	return DirectoryLevelProjection{Level: d.level, StateVersion: d.version}, nil
}
func (d *testDirectory) SetLevelTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, expected, level int64, _ operation.Context) error {
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.failSet {
		return errors.New("directory set failure")
	}
	if d.version != expected {
		return errors.New("directory optimistic conflict")
	}
	d.level = level
	d.version++
	return nil
}

func testUUID(last byte) ids.UUID { var u ids.UUID; u[15] = last; return u }
func testActor(t *testing.T) identity.ActorContext {
	t.Helper()
	aid, err := identity.AccountIDFrom(testUUID(1))
	if err != nil {
		t.Fatal(err)
	}
	sid, err := identity.SessionIDFrom(testUUID(2))
	if err != nil {
		t.Fatal(err)
	}
	cid, err := identity.ContextIDFrom(testUUID(3))
	if err != nil {
		t.Fatal(err)
	}
	return identity.ActorContext{AccountID: aid, AccountUID: "20000007", SessionID: sid, ContextID: cid, LogicalServerID: 1, PlayerID: 100001, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func testOperation(last byte) operation.Context {
	return operation.Context{ID: testUUID(last), StartedAt: time.Unix(1700000000+int64(last), 0).UTC()}
}
func scalarPlan(pid identity.PlayerID, amount int64) grant.Plan {
	return grant.Plan{PlayerID: pid, Source: grant.SourceIdentity{Domain: "test", Operation: "award", BusinessKey: "event:1", PolicyVersion: "p1"}, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "gold", Amount: amount}}}
}
func testService(store *testStore, rs *memoryReceipts, beginner *testBeginner) Service {
	return Service{Runner: tx.Runner{DB: beginner}, Store: store, Content: &testContent{policies: store.policies}, Receipts: rs, ReceiptRead: rs}
}

func mustBindTestContent(t *testing.T, op operation.Context, revision string) operation.Context {
	t.Helper()
	bound, err := bindContentRevision(op, revision)
	if err != nil {
		t.Fatal(err)
	}
	return bound
}

func TestSettleGrantSemanticReplayCreditsExactlyOnce(t *testing.T) {
	actor := testActor(t)
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "p1"}}}
	rs := newMemoryReceipts()
	db := &testBeginner{}
	svc := testService(store, rs, db)

	first, err := svc.SettleGrant(context.Background(), actor, scalarPlan(actor.PlayerID, 100), testOperation(10))
	if err != nil {
		t.Fatal(err)
	}
	second, err := svc.SettleGrant(context.Background(), actor, scalarPlan(actor.PlayerID, 100), testOperation(11))
	if err != nil {
		t.Fatal(err)
	}
	if first.ReceiptID == "" || first.ReceiptID != second.ReceiptID {
		t.Fatalf("receipt replay mismatch: %#v %#v", first, second)
	}
	if store.scalar.Amount != 100 || store.saveScalarCalls != 1 {
		t.Fatalf("grant replay double-applied: amount=%d saves=%d", store.scalar.Amount, store.saveScalarCalls)
	}
	if db.beginCount != 2 {
		t.Fatalf("expected two admitted operations, got %d", db.beginCount)
	}
}

func TestSettleGrantRejectsUnimplementedOwnerWithoutMutation(t *testing.T) {
	actor := testActor(t)
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{
		grant.PartnerEntity: {Kind: grant.PartnerEntity, WireTableID: 7001, PolicyVersion: "p1"},
	}}
	rs := newMemoryReceipts()
	svc := testService(store, rs, &testBeginner{})
	plan := grant.Plan{
		PlayerID: actor.PlayerID,
		Source:   grant.SourceIdentity{Domain: "test", Operation: "partner_award", BusinessKey: "entity:7001", PolicyVersion: "p1"},
		Lines:    []grant.Line{{Kind: grant.PartnerEntity, ItemID: 7001, Amount: 1}},
	}
	_, err := svc.SettleGrant(context.Background(), actor, plan, testOperation(12))
	if !errors.Is(err, ErrUnsupportedGrantDestination) {
		t.Fatalf("expected unsupported owner rejection, got %v", err)
	}
	if store.saveScalarCalls != 0 || len(store.insertedMail) != 0 {
		t.Fatalf("unsupported owner mutated canonical state: scalar_saves=%d mail=%d", store.saveScalarCalls, len(store.insertedMail))
	}
	id, idErr := plan.ReceiptIdentity()
	if idErr != nil {
		t.Fatal(idErr)
	}
	if _, ok, findErr := rs.Find(context.Background(), id); findErr != nil || ok {
		t.Fatalf("unsupported owner persisted success receipt: ok=%v err=%v", ok, findErr)
	}
}

func TestSettleGrantSameSemanticIdentityDifferentRequestConflicts(t *testing.T) {
	actor := testActor(t)
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "p1"}}}
	rs := newMemoryReceipts()
	svc := testService(store, rs, &testBeginner{})
	if _, err := svc.SettleGrant(context.Background(), actor, scalarPlan(actor.PlayerID, 100), testOperation(20)); err != nil {
		t.Fatal(err)
	}
	_, err := svc.SettleGrant(context.Background(), actor, scalarPlan(actor.PlayerID, 101), testOperation(21))
	var conflict *receipt.ConflictError
	if !errors.As(err, &conflict) {
		t.Fatalf("expected receipt conflict, got %v", err)
	}
	if store.scalar.Amount != 100 || store.saveScalarCalls != 1 {
		t.Fatalf("conflicting replay mutated state: %+v saves=%d", store.scalar, store.saveScalarCalls)
	}
}

func TestSettleGrantAmbiguousCommitReconcilesWithoutReplay(t *testing.T) {
	actor := testActor(t)
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "p1"}}}
	rs := newMemoryReceipts()
	db := &testBeginner{commitErrors: []error{errors.New("connection lost at COMMIT")}}
	svc := testService(store, rs, db)
	got, err := svc.SettleGrant(context.Background(), actor, scalarPlan(actor.PlayerID, 77), testOperation(30))
	if err != nil {
		t.Fatal(err)
	}
	if got.ReceiptID == "" {
		t.Fatal("reconciled grant lost terminal receipt")
	}
	if db.beginCount != 1 || store.saveScalarCalls != 1 || store.scalar.Amount != 77 {
		t.Fatalf("ambiguous commit replayed body: begins=%d saves=%d amount=%d", db.beginCount, store.saveScalarCalls, store.scalar.Amount)
	}
}

func TestStackOverflowCreatesDurableMailAndOnlyFitsCanonicalStack(t *testing.T) {
	actor := testActor(t)
	def := economy.StackDefinition{ItemID: 9001, StackCap: 5, OverflowToMail: true}
	now := time.Unix(1700000040, 0).UTC()
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{grant.StackItem: {Kind: grant.StackItem, WireTableID: 9001, Stack: &def, PolicyVersion: "items-v1"}}, stackExists: true, stack: economy.StackState{PlayerID: actor.PlayerID, ItemID: 9001, Quantity: 4, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}}
	rs := newMemoryReceipts()
	svc := testService(store, rs, &testBeginner{})
	p := grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "objective", Operation: "claim", BusinessKey: "daily:1", PolicyVersion: "items-v1"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 9001, Amount: 3}}}
	got, err := svc.SettleGrant(context.Background(), actor, p, testOperation(40))
	if err != nil {
		t.Fatal(err)
	}
	if store.stack.Quantity != 5 || store.saveStackCalls != 1 {
		t.Fatalf("canonical stack not capped: %+v", store.stack)
	}
	if len(store.insertedMail) != 1 || len(store.insertedMail[0].Attachments) != 1 || store.insertedMail[0].Attachments[0].Line.Amount != 2 {
		t.Fatalf("overflow mail mismatch: %#v", store.insertedMail)
	}
	if len(got.Awards) != 1 || got.Awards[0].ItemNum != 1 {
		t.Fatalf("wire award must contain only immediate fit: %#v", got.Awards)
	}
}

func TestMailClaimRefusesRecursiveOverflowAndLeavesMailUnclaimed(t *testing.T) {
	actor := testActor(t)
	def := economy.StackDefinition{ItemID: 9001, StackCap: 5, OverflowToMail: true}
	now := time.Unix(1700000050, 0).UTC()
	mu := testUUID(9)
	addr := mail.Address{Namespace: mail.Normal, WireID: 7}
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{grant.StackItem: {Kind: grant.StackItem, WireTableID: 9001, Stack: &def, PolicyVersion: "items-v1"}}, stackExists: true, stack: economy.StackState{PlayerID: actor.PlayerID, ItemID: 9001, Quantity: 5, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}}
	store.lockedMail = mail.Record{MailUUID: mu, Recipient: actor.PlayerID, Address: addr, SourceKind: "SYSTEM", SourceKey: "m1", CreatedAt: now, Shown: true, Platform: mail.AnyPlatform, CompatibilityPolicyVersion: "items-v1", StateVersion: 1, Attachments: []mail.Attachment{{Ordinal: 0, Line: grant.Line{Kind: grant.StackItem, ItemID: 9001, Amount: 1}}}}
	rs := newMemoryReceipts()
	svc := testService(store, rs, &testBeginner{})
	_, err := svc.ClaimMail(context.Background(), actor, addr, testOperation(50))
	if !errors.Is(err, ErrMailStackFull) {
		t.Fatalf("expected recursive overflow refusal, got %v", err)
	}
	if store.saveMailCalls != 0 || store.lockedMail.ClaimedAt != nil {
		t.Fatalf("mail was consumed despite failed settlement: %+v", store.lockedMail)
	}
	if len(store.insertedMail) != 0 {
		t.Fatalf("claim recursively created overflow mail: %#v", store.insertedMail)
	}
}

func TestGrantResultReceiptPayloadRoundTrips(t *testing.T) {
	in := GrantResult{ReceiptID: testUUID(7).String(), Awards: []Award{{TableID: 1, ItemNum: 2}}}
	raw, err := json.Marshal(in)
	if err != nil {
		t.Fatal(err)
	}
	var out GrantResult
	if err := json.Unmarshal(raw, &out); err != nil {
		t.Fatal(err)
	}
	if out.ReceiptID != in.ReceiptID || len(out.Awards) != 1 || out.Awards[0] != in.Awards[0] {
		t.Fatalf("terminal replay payload unstable: %#v", out)
	}
}

type testAudit struct {
	mu     sync.Mutex
	events []audit.Event
}

func (a *testAudit) Emit(_ context.Context, e audit.Event) {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.events = append(a.events, e)
}

func TestAdminGrantUsesCanonicalGrantWithoutGameplayFenceAndAudits(t *testing.T) {
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "ops-v1"}}}
	rs := newMemoryReceipts()
	db := &testBeginner{}
	ae := &testAudit{}
	svc := testService(store, rs, db)
	svc.Audit = ae
	admin := AdminOperator{ID: "operator-7", ReasonCode: "preservation-test"}
	lines := []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "gold", Amount: 50}}
	first, err := svc.AdminGrant(context.Background(), admin, 100001, "grant-42", "ops-v1", lines, testOperation(60))
	if err != nil {
		t.Fatal(err)
	}
	second, err := svc.AdminGrant(context.Background(), admin, 100001, "grant-42", "ops-v1", lines, testOperation(61))
	if err != nil {
		t.Fatal(err)
	}
	if first.ReceiptID == "" || first.ReceiptID != second.ReceiptID {
		t.Fatalf("admin replay receipt mismatch: %#v %#v", first, second)
	}
	if store.scalar.Amount != 50 || store.saveScalarCalls != 1 {
		t.Fatalf("admin grant double applied: %+v saves=%d", store.scalar, store.saveScalarCalls)
	}
	if store.fenceCalls != 0 {
		t.Fatalf("operator entitlement incorrectly required target gameplay liveness: fences=%d", store.fenceCalls)
	}
	if len(ae.events) != 2 || ae.events[0].ActorKind != "AdminOperator" || ae.events[0].Action != "grant" {
		t.Fatalf("audit=%#v", ae.events)
	}
}

func TestAdminSendMailUsesMailOwnerAndSemanticReplay(t *testing.T) {
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{}}
	rs := newMemoryReceipts()
	db := &testBeginner{}
	ae := &testAudit{}
	svc := testService(store, rs, db)
	svc.Audit = ae
	admin := AdminOperator{ID: "operator-7", ReasonCode: "support"}
	lines := []grant.Line{{Kind: grant.StackItem, ItemID: 9001, Amount: 2}}
	first, err := svc.AdminSendMail(context.Background(), admin, 100001, mail.Normal, "mail-42", "Gift", "GM", "Preserved reward", "ops-v1", lines, nil, testOperation(62))
	if err != nil {
		t.Fatal(err)
	}
	second, err := svc.AdminSendMail(context.Background(), admin, 100001, mail.Normal, "mail-42", "Gift", "GM", "Preserved reward", "ops-v1", lines, nil, testOperation(63))
	if err != nil {
		t.Fatal(err)
	}
	if first.ReceiptID == "" || first.ReceiptID != second.ReceiptID || first.MailUUID != second.MailUUID {
		t.Fatalf("mail replay mismatch: %#v %#v", first, second)
	}
	if len(store.insertedMail) != 1 || store.insertedMail[0].SourceKind != "ADMIN" {
		t.Fatalf("operator mail bypassed/corrupted mail owner: %#v", store.insertedMail)
	}
	if len(ae.events) != 2 || ae.events[0].Action != "mail.deliver" {
		t.Fatalf("audit=%#v", ae.events)
	}
}

func TestObjectiveFactReceiptPreventsDoubleProgress(t *testing.T) {
	actor := testActor(t)
	store := &testStore{}
	rs := newMemoryReceipts()
	svc := Service{Store: store, Receipts: rs, ReceiptRead: rs}
	def := ObjectiveDefinition{Family: objective.Daily, Definition: objective.Definition{ProgramID: "daily", ObjectiveID: 101, DefinitionRevision: "r1", Strategy: objective.CommittedDeltaFact, AcceptedFactKind: "battle_win", Target: 3}}
	inst := objective.Instance{PlayerID: actor.PlayerID, ProgramID: "daily", ObjectiveID: 101, GenerationID: "2026-09-06", DefinitionRevision: "r1", Progress: 0, ClaimState: objective.Unclaimed, StateVersion: 1}
	fact := objective.Fact{PlayerID: actor.PlayerID, SourceDomain: "arena", SourceBusinessKey: "attempt-7", Kind: "battle_win", Delta: 1}
	txv := &testTx{}
	next, changed, err := svc.ApplyObjectiveFactTx(context.Background(), txv, def, inst, fact, testOperation(70))
	if err != nil || !changed || next.Progress != 1 {
		t.Fatalf("first fact next=%+v changed=%v err=%v", next, changed, err)
	}
	again, changed, err := svc.ApplyObjectiveFactTx(context.Background(), txv, def, next, fact, testOperation(71))
	if err != nil || changed || again.Progress != 1 {
		t.Fatalf("replayed fact next=%+v changed=%v err=%v", again, changed, err)
	}
	if store.saveObjectiveCalls != 1 {
		t.Fatalf("objective fact saved %d times", store.saveObjectiveCalls)
	}
}

func TestObjectiveClaimReplayGrantsOnce(t *testing.T) {
	actor := testActor(t)
	completed := time.Unix(1700000000, 0).UTC()
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "obj-v1"}}}
	store.objectiveInst = objective.Instance{PlayerID: actor.PlayerID, ProgramID: "daily", ObjectiveID: 102, GenerationID: "2026-09-06", DefinitionRevision: "r1", Progress: 3, CompletedAt: &completed, ClaimState: objective.Unclaimed, StateVersion: 2}
	store.objectiveDef = ObjectiveDefinition{Family: objective.Daily, Definition: objective.Definition{ProgramID: "daily", ObjectiveID: 102, DefinitionRevision: "r1", Strategy: objective.CommittedDeltaFact, AcceptedFactKind: "battle_win", Target: 3}, Reward: grant.Plan{Source: grant.SourceIdentity{PolicyVersion: "obj-v1"}, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "gold", Amount: 5}}}}
	rs := newMemoryReceipts()
	svc := testService(store, rs, &testBeginner{})
	first, err := svc.ClaimObjective(context.Background(), actor, objective.Daily, 102, "2026-09-06", testOperation(72))
	if err != nil {
		t.Fatal(err)
	}
	second, err := svc.ClaimObjective(context.Background(), actor, objective.Daily, 102, "2026-09-06", testOperation(73))
	if err != nil {
		t.Fatal(err)
	}
	if len(first.Awards) != 1 || len(second.Awards) != 1 || store.scalar.Amount != 5 || store.saveScalarCalls != 1 || store.saveObjectiveCalls != 1 {
		t.Fatalf("claim replay first=%#v second=%#v amount=%d scalar_saves=%d objective_saves=%d", first, second, store.scalar.Amount, store.saveScalarCalls, store.saveObjectiveCalls)
	}
}

func TestSettleGrantTxUsesCallerOwnedTransactionWithoutNestedBegin(t *testing.T) {
	actor := testActor(t)
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{
		grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "p1"},
	}}
	rs := newMemoryReceipts()
	db := &testBeginner{}
	svc := testService(store, rs, db)
	callerTx := &testTx{}

	got, err := svc.SettleGrantTx(context.Background(), callerTx, actor, scalarPlan(actor.PlayerID, 9), mustBindTestContent(t, testOperation(90), testContentRevisionA), GrantTxOptions{AllowOverflowMail: true})
	if err != nil {
		t.Fatal(err)
	}
	if got.ReceiptID == "" || store.scalar.Amount != 9 {
		t.Fatalf("caller-owned grant did not settle: got=%+v scalar=%+v", got, store.scalar)
	}
	if db.beginCount != 0 || callerTx.committed || callerTx.rolledBack {
		t.Fatalf("transaction-scoped grant took transaction ownership: begins=%d committed=%v rolled_back=%v", db.beginCount, callerTx.committed, callerTx.rolledBack)
	}
}

func TestGrantPreflightCanonicalLockOrderIndependentOfLineOrder(t *testing.T) {
	actor := testActor(t)
	def := economy.StackDefinition{ItemID: 9001, StackCap: 5, OverflowToMail: true}
	policies := map[grant.LineKind]ResourcePolicy{
		grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "p1"},
		grant.StackItem:      {Kind: grant.StackItem, WireTableID: 9001, Stack: &def, PolicyVersion: "p1"},
	}
	linesA := []grant.Line{
		{Kind: grant.StackItem, ItemID: 9001, Amount: 1},
		{Kind: grant.ScalarCurrency, ResourceKey: "gold", Amount: 2},
	}
	linesB := []grant.Line{linesA[1], linesA[0]}
	var traces [][]string
	for i, lines := range [][]grant.Line{linesA, linesB} {
		store := &testStore{policies: policies}
		rs := newMemoryReceipts()
		svc := testService(store, rs, &testBeginner{})
		plan := grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "test", Operation: "lock-order", BusinessKey: fmt.Sprintf("case:%d", i), PolicyVersion: "p1"}, Lines: lines}
		if _, err := svc.SettleGrant(context.Background(), actor, plan, testOperation(byte(91+i))); err != nil {
			t.Fatal(err)
		}
		if len(store.lockTrace) < 4 {
			t.Fatalf("short lock trace: %#v", store.lockTrace)
		}
		traces = append(traces, append([]string(nil), store.lockTrace[:4]...))
	}
	want := []string{"mail:NORMAL", "economy-owner", "scalar:gold", "stack:9001"}
	for i, got := range traces {
		if fmt.Sprint(got) != fmt.Sprint(want) {
			t.Fatalf("case %d lock order = %#v want %#v", i, got, want)
		}
	}
}

type txWitnessStore struct {
	*testStore
	want  tx.Tx
	wrong bool
}

func (s *txWitnessStore) witness(t tx.Tx) {
	if t != s.want {
		s.wrong = true
	}
}
func (s *txWitnessStore) LockEconomyOwnerTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) error {
	s.witness(t)
	return s.testStore.LockEconomyOwnerTx(ctx, t, pid)
}
func (s *txWitnessStore) LockScalarTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, key string, now time.Time) (economy.ScalarBalance, bool, error) {
	s.witness(t)
	return s.testStore.LockScalarTx(ctx, t, pid, key, now)
}
func (s *txWitnessStore) SaveScalarTx(ctx context.Context, t tx.Tx, b economy.ScalarBalance, exists bool) error {
	s.witness(t)
	return s.testStore.SaveScalarTx(ctx, t, b, exists)
}

func TestSettleGrantTxPropagatesExactCallerTransactionToOwner(t *testing.T) {
	actor := testActor(t)
	base := &testStore{policies: map[grant.LineKind]ResourcePolicy{
		grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "p1"},
	}}
	callerTx := &testTx{}
	store := &txWitnessStore{testStore: base, want: callerTx}
	rs := newMemoryReceipts()
	content := &testContent{policies: base.policies, wantQueryer: callerTx}
	svc := Service{Store: store, Content: content, Receipts: rs, ReceiptRead: rs}
	if _, err := svc.SettleGrantTx(context.Background(), callerTx, actor, scalarPlan(actor.PlayerID, 4), mustBindTestContent(t, testOperation(93), testContentRevisionA), GrantTxOptions{AllowOverflowMail: true}); err != nil {
		t.Fatal(err)
	}
	if store.wrong || content.wrongQueryer {
		t.Fatalf("Grant owner/content operation observed a transaction other than the caller-owned tx: store=%v content=%v", store.wrong, content.wrongQueryer)
	}
}

func TestObjectiveStockClaimReplayGrantsOnce(t *testing.T) {
	actor := testActor(t)
	completed := time.Unix(1700000000, 0).UTC()
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "obj-v1"}}}
	store.objectiveInst = objective.Instance{PlayerID: actor.PlayerID, ProgramID: "daily", ObjectiveID: 103, GenerationID: "2026-09-06", DefinitionRevision: "r1", Progress: 3, CompletedAt: &completed, ClaimState: objective.Unclaimed, StateVersion: 2}
	store.objectiveDef = ObjectiveDefinition{Family: objective.Daily, Definition: objective.Definition{ProgramID: "daily", ObjectiveID: 103, DefinitionRevision: "r1", Strategy: objective.CommittedDeltaFact, AcceptedFactKind: "battle_win", Target: 3}, Reward: grant.Plan{Source: grant.SourceIdentity{PolicyVersion: "obj-v1"}, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "gold", Amount: 5}}}}
	rs := newMemoryReceipts()
	svc := testService(store, rs, &testBeginner{})

	first, err := svc.ClaimObjectiveByID(context.Background(), actor, 103, "2026-09-06", testOperation(74))
	if err != nil {
		t.Fatal(err)
	}
	second, err := svc.ClaimObjectiveByID(context.Background(), actor, 103, "2026-09-06", testOperation(75))
	if err != nil {
		t.Fatal(err)
	}
	if len(first.Awards) != 1 || len(second.Awards) != 1 || store.scalar.Amount != 5 || store.saveScalarCalls != 1 || store.saveObjectiveCalls != 1 {
		t.Fatalf("stock claim replay first=%#v second=%#v amount=%d scalar_saves=%d objective_saves=%d", first, second, store.scalar.Amount, store.saveScalarCalls, store.saveObjectiveCalls)
	}
}

func TestSettleGrantRetryPinsFirstBoundContentRevision(t *testing.T) {
	actor := testActor(t)
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{
		grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "p1"},
	}}
	rs := newMemoryReceipts()
	content := &testContent{
		activeRevisions: []string{testContentRevisionA, testContentRevisionB},
		policies:        store.policies,
		resolveErrors:   []error{tx.MarkDefiniteAbort(errors.New("serialization abort")), nil},
	}
	svc := Service{Runner: tx.Runner{DB: &testBeginner{}}, Store: store, Content: content, Receipts: rs, ReceiptRead: rs}
	got, err := svc.SettleGrant(context.Background(), actor, scalarPlan(actor.PlayerID, 13), testOperation(100))
	if err != nil {
		t.Fatal(err)
	}
	if got.ReceiptID == "" || store.scalar.Amount != 13 || store.saveScalarCalls != 1 {
		t.Fatalf("retry settlement=%+v scalar=%+v saves=%d", got, store.scalar, store.saveScalarCalls)
	}
	content.mu.Lock()
	defer content.mu.Unlock()
	if content.activeCalls != 1 {
		t.Fatalf("active content was re-resolved across retry: calls=%d", content.activeCalls)
	}
	if len(content.seenRevisions) != 2 || content.seenRevisions[0] != testContentRevisionA || content.seenRevisions[1] != testContentRevisionA {
		t.Fatalf("retry did not remain pinned: %#v", content.seenRevisions)
	}
}

func TestSettleGrantLegacyV1ReceiptReplaysWithoutActiveContentLookup(t *testing.T) {
	actor := testActor(t)
	plan := scalarPlan(actor.PlayerID, 21)
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{
		grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "p1"},
	}}
	rs := newMemoryReceipts()
	fp, err := receiptFingerprintForGrant(plan)
	if err != nil {
		t.Fatal(err)
	}
	_, legacyID, err := plan.ReceiptIdentities()
	if err != nil {
		t.Fatal(err)
	}
	raw, _ := json.Marshal(GrantResult{ReceiptID: "legacy-receipt", Awards: []Award{{TableID: 1, ResourceKey: "gold", ItemNum: 21}}})
	legacy, err := receipt.New(testOperation(101), legacyID, "I5_GRANT", "gxb.i5.grant.v1", raw, fp)
	if err != nil {
		t.Fatal(err)
	}
	rs.m[legacyID] = legacy
	content := &testContent{activeRevisions: []string{testContentRevisionA}, policies: store.policies}
	svc := Service{Runner: tx.Runner{DB: &testBeginner{}}, Store: store, Content: content, Receipts: rs, ReceiptRead: rs}
	got, err := svc.SettleGrant(context.Background(), actor, plan, testOperation(102))
	if err != nil {
		t.Fatal(err)
	}
	if got.ReceiptID != "legacy-receipt" || store.saveScalarCalls != 0 {
		t.Fatalf("legacy replay mutated or changed result: got=%+v saves=%d", got, store.saveScalarCalls)
	}
	content.mu.Lock()
	defer content.mu.Unlock()
	if content.activeCalls != 0 || content.resolveCalls != 0 {
		t.Fatalf("legacy replay consulted current content: active=%d resolve=%d", content.activeCalls, content.resolveCalls)
	}
}

func TestSettleGrantConflictingV2AndV1ReceiptsFailClosedBeforeContentLookup(t *testing.T) {
	actor := testActor(t)
	plan := scalarPlan(actor.PlayerID, 22)
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{
		grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "p1"},
	}}
	rs := newMemoryReceipts()
	fp, err := receiptFingerprintForGrant(plan)
	if err != nil {
		t.Fatal(err)
	}
	v2id, v1id, err := plan.ReceiptIdentities()
	if err != nil {
		t.Fatal(err)
	}
	for i, entry := range []struct {
		id  receipt.Identity
		out GrantResult
	}{
		{id: v2id, out: GrantResult{ReceiptID: "v2", Awards: []Award{{TableID: 1, ResourceKey: "gold", ItemNum: 22}}}},
		{id: v1id, out: GrantResult{ReceiptID: "v1", Awards: []Award{{TableID: 1, ResourceKey: "gold", ItemNum: 23}}}},
	} {
		raw, _ := json.Marshal(entry.out)
		r, e := receipt.New(testOperation(byte(103+i)), entry.id, "I5_GRANT", "gxb.i5.grant.v1", raw, fp)
		if e != nil {
			t.Fatal(e)
		}
		rs.m[entry.id] = r
	}
	content := &testContent{activeRevisions: []string{testContentRevisionA}, policies: store.policies}
	svc := Service{Runner: tx.Runner{DB: &testBeginner{}}, Store: store, Content: content, Receipts: rs, ReceiptRead: rs}
	_, err = svc.SettleGrant(context.Background(), actor, plan, testOperation(105))
	if !errors.Is(err, ErrGrantDualReceiptConflict) {
		t.Fatalf("expected dual-receipt conflict, got %v", err)
	}
	content.mu.Lock()
	defer content.mu.Unlock()
	if content.activeCalls != 0 || content.resolveCalls != 0 || store.saveScalarCalls != 0 {
		t.Fatalf("dual conflict crossed replay boundary: active=%d resolve=%d saves=%d", content.activeCalls, content.resolveCalls, store.saveScalarCalls)
	}
}

func TestGrantReceiptPersistsBoundContentPolicyRef(t *testing.T) {
	actor := testActor(t)
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{
		grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "p1"},
	}}
	rs := newMemoryReceipts()
	content := &testContent{activeRevisions: []string{testContentRevisionA}, policies: store.policies}
	svc := Service{Runner: tx.Runner{DB: &testBeginner{}}, Store: store, Content: content, Receipts: rs, ReceiptRead: rs}
	plan := scalarPlan(actor.PlayerID, 7)
	if _, err := svc.SettleGrant(context.Background(), actor, plan, testOperation(106)); err != nil {
		t.Fatal(err)
	}
	id, err := plan.ReceiptIdentity()
	if err != nil {
		t.Fatal(err)
	}
	r, ok, err := rs.Find(context.Background(), id)
	if err != nil || !ok {
		t.Fatalf("receipt missing ok=%v err=%v", ok, err)
	}
	got, ok := r.OperationPolicyRefs.Get(contentPolicyRefName)
	if !ok || got != testContentRevisionA {
		t.Fatalf("receipt content ref = %q,%v", got, ok)
	}
}

func TestContentBackedObjectiveClaimUsesPersistedRevisionForDefinitionAndNestedGrant(t *testing.T) {
	actor := testActor(t)
	completed := time.Unix(1700000000, 0).UTC()
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{
		grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "content-p1"},
	}}
	store.objectiveInst = objective.Instance{PlayerID: actor.PlayerID, ProgramID: "daily", ObjectiveID: 104, GenerationID: "gen-1", DefinitionRevision: "r1", ContentRevision: testContentRevisionA, Progress: 3, CompletedAt: &completed, ClaimState: objective.Unclaimed, StateVersion: 2}
	store.objectiveDef = ObjectiveDefinition{}
	resolved := ObjectiveDefinition{Family: objective.Daily, Definition: objective.Definition{ProgramID: "daily", ObjectiveID: 104, DefinitionRevision: "r1", Strategy: objective.CommittedDeltaFact, AcceptedFactKind: "battle_win", Target: 3}, Reward: grant.Plan{Source: grant.SourceIdentity{PolicyVersion: "content-p1"}, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "gold", Amount: 6}}}}
	content := &testContent{
		activeRevisions: []string{testContentRevisionB},
		policies:        store.policies,
		objectives: map[string]ObjectiveDefinition{
			objectiveContentKey(testContentRevisionA, "daily", 104, "r1"): resolved,
		},
	}
	rs := newMemoryReceipts()
	svc := Service{Runner: tx.Runner{DB: &testBeginner{}}, Store: store, Content: content, Receipts: rs, ReceiptRead: rs}
	got, err := svc.ClaimObjective(context.Background(), actor, objective.Daily, 104, "gen-1", testOperation(107))
	if err != nil {
		t.Fatal(err)
	}
	if len(got.Awards) != 1 || got.Awards[0].ItemNum != 6 || store.scalar.Amount != 6 {
		t.Fatalf("content objective claim result=%+v scalar=%+v", got, store.scalar)
	}
	content.mu.Lock()
	if content.activeCalls != 0 {
		content.mu.Unlock()
		t.Fatalf("persisted objective revision was replaced by active content: calls=%d", content.activeCalls)
	}
	for _, revision := range content.seenRevisions {
		if revision != testContentRevisionA {
			content.mu.Unlock()
			t.Fatalf("objective/nested grant escaped persisted revision: %#v", content.seenRevisions)
		}
	}
	content.mu.Unlock()
	grantReceipts := 0
	objectiveReceipts := 0
	rs.mu.Lock()
	for _, r := range rs.m {
		ref, ok := r.OperationPolicyRefs.Get(contentPolicyRefName)
		if r.Identity.Domain == "grant" {
			grantReceipts++
			if !ok || ref != testContentRevisionA {
				rs.mu.Unlock()
				t.Fatalf("nested grant content ref=%q,%v", ref, ok)
			}
		}
		if r.Identity.Domain == "objective" {
			objectiveReceipts++
			if !ok || ref != testContentRevisionA {
				rs.mu.Unlock()
				t.Fatalf("objective receipt content ref=%q,%v", ref, ok)
			}
		}
	}
	rs.mu.Unlock()
	if grantReceipts != 1 || objectiveReceipts != 1 {
		t.Fatalf("unexpected receipt counts grant=%d objective=%d", grantReceipts, objectiveReceipts)
	}
}

func TestAdjustStackOverCapSpendAndSemanticReplayProtectsRecreatedRow(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700000200, 0).UTC()
	def := economy.StackDefinition{ItemID: 9001, StackCap: 5, OverflowToMail: true}
	store := &testStore{
		policies:    map[grant.LineKind]ResourcePolicy{grant.StackItem: {Kind: grant.StackItem, Stack: &def, WireTableID: 9001, PolicyVersion: "items-v1"}},
		stackExists: true,
		stack:       economy.StackState{PlayerID: actor.PlayerID, ItemID: 9001, Quantity: 10, StateVersion: 4, AcquiredAt: now.Add(-time.Hour), UpdatedAt: now.Add(-time.Minute)},
	}
	rs := newMemoryReceipts()
	svc := testService(store, rs, &testBeginner{})
	source := grant.SourceIdentity{Domain: "craft", Operation: "consume", BusinessKey: "craft:42", Occurrence: "1", PolicyVersion: "craft-v1"}
	first, err := svc.AdjustStack(context.Background(), actor, source, 9001, -3, testOperation(120))
	if err != nil {
		t.Fatal(err)
	}
	if first.BeforeQuantity != 10 || first.AfterQuantity != 7 || first.Deleted || store.stack.Quantity != 7 || store.saveStackCalls != 1 {
		t.Fatalf("over-cap debit mismatch: result=%+v stack=%+v saves=%d", first, store.stack, store.saveStackCalls)
	}
	// A later owner action may delete/recreate the row. Replaying the old
	// semantic consume must resolve by receipt, not by the row's existence.
	store.mu.Lock()
	store.stackExists = true
	store.stack = economy.StackState{PlayerID: actor.PlayerID, ItemID: 9001, Quantity: 4, StateVersion: 20, AcquiredAt: now, UpdatedAt: now}
	store.mu.Unlock()
	second, err := svc.AdjustStack(context.Background(), actor, source, 9001, -3, testOperation(121))
	if err != nil {
		t.Fatal(err)
	}
	if second.ReceiptID != first.ReceiptID || store.stack.Quantity != 4 || store.saveStackCalls != 1 || store.deleteStackCalls != 0 {
		t.Fatalf("semantic replay touched recreated row: first=%+v second=%+v stack=%+v saves=%d deletes=%d", first, second, store.stack, store.saveStackCalls, store.deleteStackCalls)
	}
}

func TestAdjustStackExactZeroDeletesAndShortageIsAtomic(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700000300, 0).UTC()
	def := economy.StackDefinition{ItemID: 9001, StackCap: 99}
	store := &testStore{
		policies:    map[grant.LineKind]ResourcePolicy{grant.StackItem: {Kind: grant.StackItem, Stack: &def, WireTableID: 9001, PolicyVersion: "items-v1"}},
		stackExists: true,
		stack:       economy.StackState{PlayerID: actor.PlayerID, ItemID: 9001, Quantity: 3, StateVersion: 2, AcquiredAt: now.Add(-time.Hour), UpdatedAt: now},
	}
	rs := newMemoryReceipts()
	svc := testService(store, rs, &testBeginner{})
	source := grant.SourceIdentity{Domain: "shop", Operation: "consume", BusinessKey: "buy:1", Occurrence: "1", PolicyVersion: "shop-v1"}
	got, err := svc.AdjustStack(context.Background(), actor, source, 9001, -3, testOperation(122))
	if err != nil {
		t.Fatal(err)
	}
	if !got.Deleted || got.AfterQuantity != 0 || store.stackExists || store.deleteStackCalls != 1 {
		t.Fatalf("exact-zero delete mismatch: result=%+v exists=%v deletes=%d", got, store.stackExists, store.deleteStackCalls)
	}

	store2 := &testStore{
		policies:    store.policies,
		stackExists: true,
		stack:       economy.StackState{PlayerID: actor.PlayerID, ItemID: 9001, Quantity: 2, StateVersion: 7, AcquiredAt: now.Add(-time.Hour), UpdatedAt: now},
	}
	rs2 := newMemoryReceipts()
	svc2 := testService(store2, rs2, &testBeginner{})
	_, err = svc2.AdjustStack(context.Background(), actor, grant.SourceIdentity{Domain: "shop", Operation: "consume", BusinessKey: "buy:2", Occurrence: "1", PolicyVersion: "shop-v1"}, 9001, -3, testOperation(123))
	if !errors.Is(err, economy.ErrInsufficientBalance) {
		t.Fatalf("shortage error=%v", err)
	}
	if store2.stack.Quantity != 2 || store2.saveStackCalls != 0 || store2.deleteStackCalls != 0 {
		t.Fatalf("shortage mutated stack: %+v saves=%d deletes=%d", store2.stack, store2.saveStackCalls, store2.deleteStackCalls)
	}
}

func TestAdjustStackAbsentNegativeDoesNotCreateRow(t *testing.T) {
	actor := testActor(t)
	def := economy.StackDefinition{ItemID: 9001, StackCap: 99}
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{grant.StackItem: {Kind: grant.StackItem, Stack: &def, WireTableID: 9001, PolicyVersion: "items-v1"}}}
	rs := newMemoryReceipts()
	svc := testService(store, rs, &testBeginner{})
	_, err := svc.AdjustStack(context.Background(), actor, grant.SourceIdentity{Domain: "craft", Operation: "consume", BusinessKey: "missing", Occurrence: "1", PolicyVersion: "craft-v1"}, 9001, -1, testOperation(124))
	if !errors.Is(err, economy.ErrInsufficientBalance) {
		t.Fatalf("absent debit error=%v", err)
	}
	if store.stackExists || store.saveStackCalls != 0 || store.deleteStackCalls != 0 {
		t.Fatalf("absent debit created state: exists=%v saves=%d deletes=%d", store.stackExists, store.saveStackCalls, store.deleteStackCalls)
	}
}

func TestObjectiveOuterV1ReplayProjectsCurrentCanonicalEconomy(t *testing.T) {
	actor := testActor(t)
	store := &testStore{
		policies:     map[grant.LineKind]ResourcePolicy{grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "obj-v1"}},
		scalarExists: true,
		scalar:       economy.ScalarBalance{PlayerID: actor.PlayerID, ResourceKey: "gold", Amount: 99, StateVersion: 8, UpdatedAt: time.Unix(1700000400, 0).UTC()},
	}
	rs := newMemoryReceipts()
	family, objectiveID, generation := objective.Daily, int64(201), "gen-v1"
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "objective", Operation: "claim", SemanticKey: fmt.Sprintf("%d:%d:%s", family, objectiveID, generation)}
	fp, _ := receipt.FingerprintRequest(map[string]any{"family": int64(family), "objective_id": objectiveID, "generation_id": generation})
	legacyPayload, _ := json.Marshal(ObjectiveClaimResult{Awards: []Award{{TableID: 1, ResourceKey: "gold", ItemNum: 5}}, Huoyue: 2})
	legacy, err := receipt.New(testOperation(125), id, "I5_OBJECTIVE", "gxb.i5.objective-claim.v1", legacyPayload, fp)
	if err != nil {
		t.Fatal(err)
	}
	rs.m[id] = legacy
	svc := testService(store, rs, &testBeginner{})
	got, err := svc.ClaimObjective(context.Background(), actor, family, objectiveID, generation, testOperation(126))
	if err != nil {
		t.Fatal(err)
	}
	if !got.Replayed || got.Grant != nil || got.Projection.Economy["gold"] != 99 {
		t.Fatalf("legacy outer replay projection=%+v", got)
	}
	if store.saveObjectiveCalls != 0 || store.saveScalarCalls != 0 {
		t.Fatalf("legacy outer replay mutated state: objective=%d scalar=%d", store.saveObjectiveCalls, store.saveScalarCalls)
	}
}

func TestObjectiveOuterV1PlayerExpReplayProjectsCanonicalProgressionWithoutR5SideEffects(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700000450, 0).UTC()
	store := &testStore{
		progression: player.Progression{PlayerID: actor.PlayerID, Level: 4, Exp: 18, StateVersion: 7, UpdatedAt: now},
		policies:    map[grant.LineKind]ResourcePolicy{},
	}
	rs := newMemoryReceipts()
	family, objectiveID, generation := objective.Daily, int64(204), "gen-v1-exp"
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "objective", Operation: "claim", SemanticKey: fmt.Sprintf("%d:%d:%s", family, objectiveID, generation)}
	fp, _ := receipt.FingerprintRequest(map[string]any{"family": int64(family), "objective_id": objectiveID, "generation_id": generation})
	legacyPayload, _ := json.Marshal(ObjectiveClaimResult{Awards: []Award{{ResourceKey: "exp", ItemNum: 18}}})
	legacy, err := receipt.New(testOperation(250), id, "I5_OBJECTIVE", "gxb.i5.objective-claim.v1", legacyPayload, fp)
	if err != nil {
		t.Fatal(err)
	}
	rs.m[id] = legacy
	svc := testService(store, rs, &testBeginner{})
	got, err := svc.ClaimObjective(context.Background(), actor, family, objectiveID, generation, testOperation(251))
	if err != nil {
		t.Fatal(err)
	}
	if !got.Replayed || got.Grant != nil {
		t.Fatalf("expected historical outer replay, got %+v", got)
	}
	if got.Projection.Economy["exp"] != 18 || got.Projection.Economy["lev"] != 4 {
		t.Fatalf("historical EXP replay did not project canonical progression: %+v", got.Projection)
	}
	if _, ok := got.Projection.Economy["energy"]; ok {
		t.Fatalf("historical v1 EXP replay fabricated R5 Energy effect: %+v", got.Projection)
	}
	if len(got.Projection.NewFunctionIDs) != 0 {
		t.Fatalf("historical v1 EXP replay fabricated function announcements: %+v", got.Projection)
	}
	if store.saveProgressionCalls != 0 || store.saveTemporalCalls != 0 || store.advanceFunctionCalls != 0 {
		t.Fatalf("historical replay mutated R5 owners: progression=%d temporal=%d functions=%d", store.saveProgressionCalls, store.saveTemporalCalls, store.advanceFunctionCalls)
	}
}

func TestObjectiveOuterUnknownSchemaFailsClosed(t *testing.T) {
	actor := testActor(t)
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{}}
	rs := newMemoryReceipts()
	family, objectiveID, generation := objective.Daily, int64(202), "gen-bad"
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "objective", Operation: "claim", SemanticKey: fmt.Sprintf("%d:%d:%s", family, objectiveID, generation)}
	fp, _ := receipt.FingerprintRequest(map[string]any{"family": int64(family), "objective_id": objectiveID, "generation_id": generation})
	bad, err := receipt.New(testOperation(127), id, "I5_OBJECTIVE", "gxb.i5.objective-claim.v999", json.RawMessage(`{"awards":[]}`), fp)
	if err != nil {
		t.Fatal(err)
	}
	rs.m[id] = bad
	svc := testService(store, rs, &testBeginner{})
	if _, err := svc.ClaimObjective(context.Background(), actor, family, objectiveID, generation, testOperation(128)); err == nil || !strings.Contains(err.Error(), "unsupported outer receipt schema") {
		t.Fatalf("unknown schema did not fail closed: %v", err)
	}
}

func TestObjectiveOuterReplayAfterInterveningGrantProjectsFreshEconomy(t *testing.T) {
	actor := testActor(t)
	completed := time.Unix(1700000500, 0).UTC()
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "obj-v1"}}}
	store.objectiveInst = objective.Instance{PlayerID: actor.PlayerID, ProgramID: "daily", ObjectiveID: 203, GenerationID: "gen-current", DefinitionRevision: "r1", Progress: 1, CompletedAt: &completed, ClaimState: objective.Unclaimed, StateVersion: 1}
	store.objectiveDef = ObjectiveDefinition{Family: objective.Daily, Definition: objective.Definition{ProgramID: "daily", ObjectiveID: 203, DefinitionRevision: "r1", Strategy: objective.CommittedDeltaFact, AcceptedFactKind: "battle_win", Target: 1}, Reward: grant.Plan{Source: grant.SourceIdentity{PolicyVersion: "obj-v1"}, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "gold", Amount: 5}}}}
	rs := newMemoryReceipts()
	svc := testService(store, rs, &testBeginner{})
	first, err := svc.ClaimObjective(context.Background(), actor, objective.Daily, 203, "gen-current", testOperation(129))
	if err != nil {
		t.Fatal(err)
	}
	if first.Replayed || first.Grant == nil || first.Projection.Economy["gold"] != 5 {
		t.Fatalf("first settlement projection=%+v", first)
	}
	intervening := grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "test", Operation: "award", BusinessKey: "after-objective", Occurrence: "1", PolicyVersion: "p1"}, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "gold", Amount: 7}}}
	if _, err := svc.SettleGrant(context.Background(), actor, intervening, testOperation(130)); err != nil {
		t.Fatal(err)
	}
	second, err := svc.ClaimObjective(context.Background(), actor, objective.Daily, 203, "gen-current", testOperation(131))
	if err != nil {
		t.Fatal(err)
	}
	if !second.Replayed || second.Grant == nil || second.Projection.Economy["gold"] != 12 {
		t.Fatalf("replay did not project current canonical economy: %+v", second)
	}
	if store.saveObjectiveCalls != 1 || store.scalar.Amount != 12 || store.saveScalarCalls != 2 {
		t.Fatalf("replay reapplied settlement: objective=%d scalar=%+v saves=%d", store.saveObjectiveCalls, store.scalar, store.saveScalarCalls)
	}
}

func r5PlayerExpTestService(t *testing.T, dir *testDirectory, store *testStore, rs *memoryReceipts, db *testBeginner) Service {
	t.Helper()
	progressionPolicy := player.ProgressionPolicy{
		Revision: testContentRevisionA,
		Rows: []player.ProgressionRow{
			{Level: 1, MaxEnergy: 60, AwardEnergy: 5, TotalExp: 6},
			{Level: 2, MaxEnergy: 70, AwardEnergy: 6, TotalExp: 20},
			{Level: 3, MaxEnergy: 80, AwardEnergy: 0, TotalExp: 100},
		},
	}
	functionPolicy := FunctionGatePolicy{Revision: testContentRevisionA, Gates: []FunctionGate{
		{FunctionID: 10, GateKind: "PURE_LEVEL", RequiredLevel: 2, RawOpenValue: "1|2", SourceFactKey: "function:10"},
		{FunctionID: 11, GateKind: "PURE_LEVEL", RequiredLevel: 3, RawOpenValue: "1|3", SourceFactKey: "function:11"},
		{FunctionID: 12, GateKind: "UNSUPPORTED_COMPOSITE", RequiredLevel: 1, RawOpenValue: "6|1|2", SourceFactKey: "function:12"},
	}}
	energyDescriptor := &TemporalDescriptor{Revision: testContentRevisionA, ResourceKey: "energy", RegenEvery: 5 * time.Minute, RegenAmount: 1, CapRule: "PLAYER_LEVEL_ENERGY", AllowExplicitGrantAboveNaturalCap: true}
	content := &testContent{
		activeRevisions: []string{testContentRevisionA},
		policies: map[grant.LineKind]ResourcePolicy{
			grant.PlayerExp: {Kind: grant.PlayerExp, PolicyVersion: testContentRevisionA},
			grant.Temporal:  {Kind: grant.Temporal, Descriptor: energyDescriptor, PolicyVersion: testContentRevisionA},
		},
		progressionPolicies: map[string]player.ProgressionPolicy{testContentRevisionA: progressionPolicy},
		functionPolicies:    map[string]FunctionGatePolicy{testContentRevisionA: functionPolicy},
	}
	return Service{
		Runner:      tx.Runner{DB: db},
		Store:       store,
		Content:     content,
		Privileges:  BaselinePrivilegeProvider{},
		Functions:   NoFunctionAnnouncements{},
		Directory:   dir,
		Receipts:    rs,
		ReceiptRead: rs,
	}
}

func r5PlayerExpPlan(pid identity.PlayerID, amount int64) grant.Plan {
	return grant.Plan{PlayerID: pid, Source: grant.SourceIdentity{Domain: "r5-test", Operation: "player-exp", BusinessKey: "exp:1", Occurrence: "1", PolicyVersion: "r5-test-v1"}, Lines: []grant.Line{{Kind: grant.PlayerExp, Amount: amount}}}
}

func TestR5PlayerExpCompositeCrossesLevelsAndUpdatesEnergyEligibilityDirectory(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700000600, 0).UTC()
	store := &testStore{
		progression: player.Progression{PlayerID: actor.PlayerID, Level: 1, Exp: 5, StateVersion: 3, UpdatedAt: now.Add(-time.Hour)},
		temporal: map[string]economy.TemporalState{
			"energy": {PlayerID: actor.PlayerID, ResourceKey: "energy", StoredAmount: 60, RegenAnchorAt: nil, PolicyVersion: testContentRevisionA, ContentRevision: testContentRevisionA, StateVersion: 4, UpdatedAt: now.Add(-time.Hour)},
		},
		functionVersion: 2,
	}
	dir := &testDirectory{level: 1, version: 7, trace: &store.lockTrace}
	rs := newMemoryReceipts()
	db := &testBeginner{}
	svc := r5PlayerExpTestService(t, dir, store, rs, db)

	got, err := svc.SettleGrant(context.Background(), actor, r5PlayerExpPlan(actor.PlayerID, 15), operation.Context{ID: testUUID(130), StartedAt: now})
	if err != nil {
		t.Fatal(err)
	}
	if store.progression.Level != 3 || store.progression.Exp != 20 || store.saveProgressionCalls != 1 {
		t.Fatalf("progression=%+v saves=%d", store.progression, store.saveProgressionCalls)
	}
	energy := store.temporal["energy"]
	if energy.StoredAmount != 71 || energy.RegenAnchorAt == nil || !energy.RegenAnchorAt.Equal(now) || store.saveTemporalCalls != 1 {
		t.Fatalf("energy=%+v saves=%d", energy, store.saveTemporalCalls)
	}
	if len(store.eligibility) != 2 || store.eligibility[10].FunctionID != 10 || store.eligibility[11].FunctionID != 11 {
		t.Fatalf("eligibility=%+v", store.eligibility)
	}
	if len(store.unlocks) != 0 || store.advanceFunctionCalls != 1 {
		t.Fatalf("unsupported announcement leaked: unlocks=%+v advances=%d", store.unlocks, store.advanceFunctionCalls)
	}
	if dir.level != 3 || dir.version != 8 {
		t.Fatalf("directory=%+v", dir)
	}
	if got.Effects == nil || len(got.Effects.Progression) != 1 || got.Effects.Progression[0].EffectiveExp != 15 || got.Effects.Progression[0].EnergyAward != 11 {
		t.Fatalf("effects=%+v", got.Effects)
	}
	if len(got.Effects.EligibleFunctionIDs) != 2 || len(got.Effects.NewFunctionIDs) != 0 {
		t.Fatalf("function effects=%+v", got.Effects)
	}
	wantOrder := []string{"economy-owner", "progression", "temporal:energy", "function-state", "directory"}
	last := -1
	for _, want := range wantOrder {
		found := -1
		for i, got := range store.lockTrace {
			if i > last && got == want {
				found = i
				break
			}
		}
		if found < 0 {
			t.Fatalf("lock order missing %q after %d: %#v", want, last, store.lockTrace)
		}
		last = found
	}
}

func TestR5PlayerExpDirectoryFailureRollsBackAndWritesNoReceipt(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700000700, 0).UTC()
	store := &testStore{
		progression: player.Progression{PlayerID: actor.PlayerID, Level: 1, Exp: 5, StateVersion: 1, UpdatedAt: now.Add(-time.Hour)},
		temporal: map[string]economy.TemporalState{
			"energy": {PlayerID: actor.PlayerID, ResourceKey: "energy", StoredAmount: 60, RegenAnchorAt: nil, PolicyVersion: testContentRevisionA, ContentRevision: testContentRevisionA, StateVersion: 1, UpdatedAt: now.Add(-time.Hour)},
		},
		functionVersion: 1,
	}
	dir := &testDirectory{level: 1, version: 1, failSet: true, trace: &store.lockTrace}
	rs := newMemoryReceipts()
	db := &testBeginner{}
	svc := r5PlayerExpTestService(t, dir, store, rs, db)

	_, err := svc.SettleGrant(context.Background(), actor, r5PlayerExpPlan(actor.PlayerID, 15), operation.Context{ID: testUUID(131), StartedAt: now})
	if err == nil || !strings.Contains(err.Error(), "directory set failure") {
		t.Fatalf("directory failure=%v", err)
	}
	if len(db.txs) != 1 || !db.txs[0].rolledBack || db.txs[0].committed {
		t.Fatalf("transaction outcome=%+v", db.txs)
	}
	if len(rs.m) != 0 {
		t.Fatalf("receipt persisted despite failed composite: %+v", rs.m)
	}
}

func r5TemporalRebindTestService(actor identity.ActorContext, store *testStore, rs *memoryReceipts, db *testBeginner, reader receipt.Reader) (Service, *testContent) {
	d := &TemporalDescriptor{Revision: testContentRevisionA, ResourceKey: "spirit_energy", RegenEvery: 6 * time.Minute, RegenAmount: 1, CapRule: "STATIC", StaticCap: 180, AllowExplicitGrantAboveNaturalCap: true}
	content := &testContent{
		activeRevisions: []string{testContentRevisionB}, // must never be consulted by explicit rebind
		policies: map[grant.LineKind]ResourcePolicy{
			grant.Temporal: {Kind: grant.Temporal, Descriptor: d, PolicyVersion: testContentRevisionA},
		},
	}
	if reader == nil {
		reader = rs
	}
	return Service{Runner: tx.Runner{DB: db}, Store: store, Content: content, Privileges: BaselinePrivilegeProvider{}, Receipts: rs, ReceiptRead: reader}, content
}

func r5LegacySpiritStore(actor identity.ActorContext, now time.Time) *testStore {
	legacyVersion := "legacy-spirit-v1"
	legacy := economy.TemporalPolicy{Version: legacyVersion, RegenEvery: 5 * time.Minute, RegenAmount: 1, NaturalCap: 180, AllowExplicitGrantAboveNaturalCap: true}
	return &testStore{
		temporal: map[string]economy.TemporalState{
			"spirit_energy": {PlayerID: actor.PlayerID, ResourceKey: "spirit_energy", StoredAmount: 100, RegenAnchorAt: func() *time.Time { t := now.Add(-7 * time.Minute); return &t }(), PolicyVersion: legacyVersion, StateVersion: 5, UpdatedAt: now.Add(-7 * time.Minute)},
		},
		legacyTemporal: map[string]ResourcePolicy{
			legacyTemporalTestKey("spirit_energy", legacyVersion): {Kind: grant.Temporal, Temporal: &legacy, PolicyVersion: legacyVersion},
		},
	}
}

func TestR5TemporalRebindRepeatAndRestartReplayExactlyOnce(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700000800, 0).UTC()
	store := r5LegacySpiritStore(actor, now)
	rs := newMemoryReceipts()
	db := &testBeginner{}
	svc, content := r5TemporalRebindTestService(actor, store, rs, db, rs)

	first, err := svc.RebindLegacyTemporal(context.Background(), actor, "spirit_energy", testContentRevisionA, operation.Context{ID: testUUID(140), StartedAt: now})
	if err != nil {
		t.Fatal(err)
	}
	if first.ReceiptID == "" || first.BeforeAmount != 100 || first.AfterAmount != 101 || store.rebindTemporalCalls != 1 {
		t.Fatalf("first rebind=%+v state=%+v calls=%d", first, store.temporal["spirit_energy"], store.rebindTemporalCalls)
	}
	stateAfter := store.temporal["spirit_energy"]
	if stateAfter.ContentRevision != testContentRevisionA || stateAfter.PolicyVersion != testContentRevisionA || stateAfter.RegenAnchorAt == nil || !stateAfter.RegenAnchorAt.Equal(now) {
		t.Fatalf("explicit immutable boundary mismatch: %+v", stateAfter)
	}
	second, err := svc.RebindLegacyTemporal(context.Background(), actor, "spirit_energy", testContentRevisionA, operation.Context{ID: testUUID(141), StartedAt: now.Add(time.Minute)})
	if err != nil {
		t.Fatal(err)
	}
	if second.ReceiptID != first.ReceiptID || store.rebindTemporalCalls != 1 {
		t.Fatalf("repeat rebind was not receipt replay: first=%+v second=%+v calls=%d", first, second, store.rebindTemporalCalls)
	}
	// Simulate application restart: fresh Service/Runner, same durable owner+receipt state.
	restarted, restartedContent := r5TemporalRebindTestService(actor, store, rs, &testBeginner{}, rs)
	third, err := restarted.RebindLegacyTemporal(context.Background(), actor, "spirit_energy", testContentRevisionA, operation.Context{ID: testUUID(142), StartedAt: now.Add(2 * time.Minute)})
	if err != nil {
		t.Fatal(err)
	}
	if third.ReceiptID != first.ReceiptID || store.rebindTemporalCalls != 1 {
		t.Fatalf("restart replay reapplied migration: %+v calls=%d", third, store.rebindTemporalCalls)
	}
	content.mu.Lock()
	activeCalls := content.activeCalls
	content.mu.Unlock()
	restartedContent.mu.Lock()
	restartActiveCalls := restartedContent.activeCalls
	restartedContent.mu.Unlock()
	if activeCalls != 0 || restartActiveCalls != 0 {
		t.Fatalf("explicit rebind consulted active revision: first=%d restart=%d", activeCalls, restartActiveCalls)
	}
}

func TestR5TemporalRebindUnknownCommitDoesNotBlindlyRetryAndLaterReceiptRecovers(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700000900, 0).UTC()
	store := r5LegacySpiritStore(actor, now)
	rs := newMemoryReceipts()
	db := &testBeginner{commitErrors: []error{errors.New("lost COMMIT acknowledgement")}}
	svc, _ := r5TemporalRebindTestService(actor, store, rs, db, missingReceiptReader{})
	_, err := svc.RebindLegacyTemporal(context.Background(), actor, "spirit_energy", testContentRevisionA, operation.Context{ID: testUUID(143), StartedAt: now})
	var unknown *tx.UnknownCommitError
	if !errors.As(err, &unknown) {
		t.Fatalf("expected unknown COMMIT, got %v", err)
	}
	if db.beginCount != 1 || store.rebindTemporalCalls != 1 {
		t.Fatalf("unknown COMMIT blindly replayed body: begins=%d rebinds=%d", db.beginCount, store.rebindTemporalCalls)
	}
	// The in-memory transaction double cannot model rollback/visibility. Once a
	// fresh reader can see the receipt, a later process instance must replay it
	// rather than attempting a second legacy->immutable CAS.
	restarted, _ := r5TemporalRebindTestService(actor, store, rs, &testBeginner{}, rs)
	got, err := restarted.RebindLegacyTemporal(context.Background(), actor, "spirit_energy", testContentRevisionA, operation.Context{ID: testUUID(144), StartedAt: now.Add(time.Minute)})
	if err != nil || got.ReceiptID == "" || store.rebindTemporalCalls != 1 {
		t.Fatalf("later receipt recovery failed: got=%+v err=%v rebinds=%d", got, err, store.rebindTemporalCalls)
	}
}

func TestR5TemporalRebindImmutableStateWithoutReceiptFailsClosed(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700001000, 0).UTC()
	store := r5LegacySpiritStore(actor, now)
	st := store.temporal["spirit_energy"]
	st.ContentRevision, st.PolicyVersion = testContentRevisionA, testContentRevisionA
	store.temporal["spirit_energy"] = st
	rs := newMemoryReceipts()
	svc, _ := r5TemporalRebindTestService(actor, store, rs, &testBeginner{}, rs)
	_, err := svc.RebindLegacyTemporal(context.Background(), actor, "spirit_energy", testContentRevisionA, operation.Context{ID: testUUID(145), StartedAt: now})
	if !errors.Is(err, ErrTemporalRebindStateWithoutReceipt) || store.rebindTemporalCalls != 0 {
		t.Fatalf("immutable state without receipt was not fail-closed: err=%v calls=%d", err, store.rebindTemporalCalls)
	}
}

func TestR5PlayerExpMixedRevisionRejectsBeforeMutation(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700001100, 0).UTC()
	store := &testStore{
		progression: player.Progression{PlayerID: actor.PlayerID, Level: 1, Exp: 5, StateVersion: 1, UpdatedAt: now.Add(-time.Hour)},
		temporal: map[string]economy.TemporalState{
			"energy": {PlayerID: actor.PlayerID, ResourceKey: "energy", StoredAmount: 60, PolicyVersion: testContentRevisionB, ContentRevision: testContentRevisionB, StateVersion: 1, UpdatedAt: now.Add(-time.Hour)},
		},
		functionVersion: 1,
	}
	rs := newMemoryReceipts()
	svc := r5PlayerExpTestService(t, &testDirectory{level: 1, version: 1, trace: &store.lockTrace}, store, rs, &testBeginner{})
	_, err := svc.SettleGrant(context.Background(), actor, r5PlayerExpPlan(actor.PlayerID, 15), operation.Context{ID: testUUID(146), StartedAt: now})
	if !errors.Is(err, ErrContentRevisionConflict) {
		t.Fatalf("mixed revision composite did not fail closed: %v", err)
	}
	if store.saveProgressionCalls != 0 || store.saveTemporalCalls != 0 || store.advanceFunctionCalls != 0 || len(rs.m) != 0 || len(store.lockTrace) != 0 {
		t.Fatalf("mixed revision composite mutated/locked before rejection: prog=%d temporal=%d funcs=%d receipts=%d locks=%v", store.saveProgressionCalls, store.saveTemporalCalls, store.advanceFunctionCalls, len(rs.m), store.lockTrace)
	}
}

func TestR5TemporalRebindMissingLegacyPolicyFailsBeforeMutation(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700001200, 0).UTC()
	store := r5LegacySpiritStore(actor, now)
	store.legacyTemporal = map[string]ResourcePolicy{}
	rs := newMemoryReceipts()
	svc, _ := r5TemporalRebindTestService(actor, store, rs, &testBeginner{}, rs)
	_, err := svc.RebindLegacyTemporal(context.Background(), actor, "spirit_energy", testContentRevisionA, operation.Context{ID: testUUID(147), StartedAt: now})
	if !errors.Is(err, economy.ErrUnknownResource) {
		t.Fatalf("missing exact legacy policy did not fail closed: %v", err)
	}
	if store.rebindTemporalCalls != 0 || len(rs.m) != 0 {
		t.Fatalf("missing legacy policy mutated state/receipt: rebinds=%d receipts=%d", store.rebindTemporalCalls, len(rs.m))
	}
}
