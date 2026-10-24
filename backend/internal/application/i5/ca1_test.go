package i5

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/redeem"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type ca1Materializer struct {
	locks            []lockkey.Key
	preflightCalls   int
	lockCalls        int
	validateCalls    int
	applyCalls       int
	lastBatch        PartnerEntityBatch
	trace            *[]string
	wantTx           tx.Tx
	wrongTx          bool
	preflightErr     error
	validateErr      error
	applyErr         error
	results          []PartnerEntityMaterialization
	providerID       string
	providerRevision string
}

func (m *ca1Materializer) ProviderID() string {
	if m.providerID != "" {
		return m.providerID
	}
	return "ca1-test-partner"
}

func (m *ca1Materializer) ProviderRevision() string {
	if m.providerRevision != "" {
		return m.providerRevision
	}
	return "ca1-test-v1"
}

func (m *ca1Materializer) PreflightPartnerEntityBatchTx(_ context.Context, _ tx.Queryer, batch PartnerEntityBatch) (PartnerEntityPreflight, error) {
	m.preflightCalls++
	m.lastBatch = batch
	if m.preflightErr != nil {
		return PartnerEntityPreflight{}, m.preflightErr
	}
	return PartnerEntityPreflight{Locks: append([]lockkey.Key(nil), m.locks...)}, nil
}

func (m *ca1Materializer) LockPartnerEntityKeyTx(_ context.Context, got tx.Tx, key lockkey.Key) error {
	m.lockCalls++
	if m.wantTx != nil && got != m.wantTx {
		m.wrongTx = true
	}
	if m.trace != nil {
		*m.trace = append(*m.trace, fmt.Sprintf("character:%d:%s", key.DomainRank, key.OwnerKind))
	}
	return nil
}

func (m *ca1Materializer) ValidatePartnerEntityBatchLockedTx(_ context.Context, got tx.Tx, _ PartnerEntityBatch, _ PartnerEntityPreflight) error {
	m.validateCalls++
	if m.wantTx != nil && got != m.wantTx {
		m.wrongTx = true
	}
	return m.validateErr
}

func (m *ca1Materializer) MaterializePartnerEntityBatchTx(_ context.Context, got tx.Tx, batch PartnerEntityBatch, _ PartnerEntityPreflight, _ operation.Context) ([]PartnerEntityMaterialization, error) {
	m.applyCalls++
	if m.wantTx != nil && got != m.wantTx {
		m.wrongTx = true
	}
	if m.applyErr != nil {
		return nil, m.applyErr
	}
	if m.results != nil {
		return append([]PartnerEntityMaterialization(nil), m.results...), nil
	}
	out := make([]PartnerEntityMaterialization, 0, len(batch.Lines))
	for _, line := range batch.Lines {
		payload, _ := json.Marshal(map[string]any{"test_instance_ids": []int64{900000 + int64(line.Identity.LineOrdinal)}})
		out = append(out, PartnerEntityMaterialization{LineOrdinal: line.Identity.LineOrdinal, ResultSchema: "gxb.ca1.test.partner.v1", ResultPayload: payload})
	}
	return out, nil
}

type ca1TraceStore struct {
	*testStore
	trace *[]string
}

func (s *ca1TraceStore) LockEconomyOwnerTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) error {
	if s.trace != nil {
		*s.trace = append(*s.trace, "economy-owner")
	}
	return s.testStore.LockEconomyOwnerTx(ctx, t, pid)
}

func (s *ca1TraceStore) LockProgressionTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (player.Progression, error) {
	if s.trace != nil {
		*s.trace = append(*s.trace, "progression")
	}
	return s.testStore.LockProgressionTx(ctx, t, pid)
}

func (s *ca1TraceStore) LockScalarTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, key string, now time.Time) (economy.ScalarBalance, bool, error) {
	if s.trace != nil {
		*s.trace = append(*s.trace, "scalar:"+key)
	}
	return s.testStore.LockScalarTx(ctx, t, pid, key, now)
}

func ca1CharacterKey(t *testing.T, rank uint16, owner string, id int64) lockkey.Key {
	t.Helper()
	k, err := lockkey.New(rank, owner, lockkey.Int64(id))
	if err != nil {
		t.Fatal(err)
	}
	return k
}

func TestCA1PartnerEntityFailClosedDoesNotConsultFungibleCatalog(t *testing.T) {
	actor := testActor(t)
	store := &testStore{}
	content := &testContent{policies: map[grant.LineKind]ResourcePolicy{}}
	rs := newMemoryReceipts()
	svc := Service{Store: store, Content: content, Receipts: rs, ReceiptRead: rs}
	plan := grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "test", Operation: "partner", BusinessKey: "p:1", PolicyVersion: "p1"}, Lines: []grant.Line{{Kind: grant.PartnerEntity, ItemID: 7001, Amount: 1}}}
	_, err := svc.SettleGrantTx(context.Background(), &testTx{}, actor, plan, mustBindTestContent(t, testOperation(10), testContentRevisionA), GrantTxOptions{AllowOverflowMail: true})
	if !errors.Is(err, ErrUnsupportedGrantDestination) {
		t.Fatalf("error=%v", err)
	}
	content.mu.Lock()
	resolveCalls := content.resolveCalls
	content.mu.Unlock()
	if resolveCalls != 0 {
		t.Fatalf("PartnerEntity leaked through fungible content resolver: calls=%d", resolveCalls)
	}
}

func TestCA1PartnerEntityMixedGrantOrdersLocksAndReplaysTypedResult(t *testing.T) {
	actor := testActor(t)
	trace := []string{}
	base := &testStore{policies: map[grant.LineKind]ResourcePolicy{grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "p1"}}}
	store := &ca1TraceStore{testStore: base, trace: &trace}
	content := &testContent{policies: base.policies}
	rs := newMemoryReceipts()
	callerTx := &testTx{}
	provider := &ca1Materializer{
		locks: []lockkey.Key{
			ca1CharacterKey(t, 450, "character.hero-roster", int64(actor.PlayerID)),
			ca1CharacterKey(t, 410, "character.hero-allocator", int64(actor.PlayerID)),
		},
		trace:  &trace,
		wantTx: callerTx,
	}
	svc := Service{Store: store, Content: content, PartnerEntities: provider, Receipts: rs, ReceiptRead: rs}
	plan := grant.Plan{
		PlayerID: actor.PlayerID,
		Source:   grant.SourceIdentity{Domain: "test", Operation: "mixed-partner", BusinessKey: "grant:1", Occurrence: "slot:1", PolicyVersion: "p1"},
		Lines: []grant.Line{
			{Kind: grant.PartnerEntity, ItemID: 7001, Amount: 1, Metadata: map[string]string{"source": "fixture"}},
			{Kind: grant.ScalarCurrency, ResourceKey: "gold", Amount: 7},
		},
	}
	op := mustBindTestContent(t, testOperation(11), testContentRevisionA)
	first, err := svc.SettleGrantTx(context.Background(), callerTx, actor, plan, op, GrantTxOptions{AllowOverflowMail: true})
	if err != nil {
		t.Fatal(err)
	}
	if provider.wrongTx {
		t.Fatal("provider did not receive exact caller-owned transaction")
	}
	if provider.preflightCalls != 1 || provider.lockCalls != 2 || provider.validateCalls != 1 || provider.applyCalls != 1 {
		t.Fatalf("provider lifecycle preflight=%d locks=%d validate=%d apply=%d", provider.preflightCalls, provider.lockCalls, provider.validateCalls, provider.applyCalls)
	}
	if len(provider.lastBatch.Lines) != 1 || provider.lastBatch.Lines[0].Identity.LineOrdinal != 0 || provider.lastBatch.Lines[0].Identity.GrantSemanticKey != plan.Source.SemanticKey() {
		t.Fatalf("stable line identity=%+v", provider.lastBatch)
	}
	if len(trace) < 4 || !strings.HasPrefix(trace[0], "character:410:") || !strings.HasPrefix(trace[1], "character:450:") || trace[2] != "economy-owner" || trace[3] != "scalar:gold" {
		t.Fatalf("combined lock order=%#v", trace)
	}
	if len(first.Materializations) != 1 || first.Materializations[0].LineOrdinal != 0 || first.Materializations[0].ProviderID != provider.ProviderID() || first.Materializations[0].ProviderRevision != provider.ProviderRevision() {
		t.Fatalf("materializations=%+v", first.Materializations)
	}
	if len(first.Awards) != 1 || first.Awards[0].ResourceKey != "gold" || first.Awards[0].ItemNum != 7 {
		t.Fatalf("CA1 fabricated or lost stock awards: %+v", first.Awards)
	}
	if base.scalar.Amount != 7 || base.saveScalarCalls != 1 {
		t.Fatalf("scalar state=%+v saves=%d", base.scalar, base.saveScalarCalls)
	}
	id, err := plan.ReceiptIdentity()
	if err != nil {
		t.Fatal(err)
	}
	rr, ok, err := rs.Find(context.Background(), id)
	if err != nil || !ok {
		t.Fatalf("receipt ok=%v err=%v", ok, err)
	}
	if rr.ResultSchema != "gxb.i5.grant.v3" {
		t.Fatalf("schema=%s", rr.ResultSchema)
	}
	content.mu.Lock()
	resolveCalls := content.resolveCalls
	content.mu.Unlock()
	if resolveCalls != 1 {
		t.Fatalf("expected only scalar content resolution, got %d", resolveCalls)
	}

	second, err := svc.SettleGrantTx(context.Background(), callerTx, actor, plan, testOperation(12), GrantTxOptions{AllowOverflowMail: true})
	if err != nil {
		t.Fatal(err)
	}
	if second.ReceiptID != first.ReceiptID || !bytes.Equal(second.Materializations[0].ResultPayload, first.Materializations[0].ResultPayload) {
		t.Fatalf("typed replay mismatch first=%+v second=%+v", first, second)
	}
	if provider.preflightCalls != 1 || provider.applyCalls != 1 || base.saveScalarCalls != 1 {
		t.Fatalf("replay re-entered provider/owner preflight=%d apply=%d scalar_saves=%d", provider.preflightCalls, provider.applyCalls, base.saveScalarCalls)
	}
}

func TestCA1PartnerEntityRejectsLockOutsideReservedBandBeforeMutation(t *testing.T) {
	actor := testActor(t)
	store := &testStore{}
	rs := newMemoryReceipts()
	provider := &ca1Materializer{locks: []lockkey.Key{ca1CharacterKey(t, 610, "character.bad-rank", int64(actor.PlayerID))}}
	svc := Service{Store: store, PartnerEntities: provider, Receipts: rs, ReceiptRead: rs}
	plan := grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "test", Operation: "partner", BusinessKey: "bad-rank", PolicyVersion: "p1"}, Lines: []grant.Line{{Kind: grant.PartnerEntity, ItemID: 7001, Amount: 1}}}
	_, err := svc.SettleGrantTx(context.Background(), &testTx{}, actor, plan, mustBindTestContent(t, testOperation(13), testContentRevisionA), GrantTxOptions{})
	if err == nil || !strings.Contains(err.Error(), "outside Character Asset band") {
		t.Fatalf("error=%v", err)
	}
	if provider.lockCalls != 0 || provider.validateCalls != 0 || provider.applyCalls != 0 {
		t.Fatalf("invalid provider progressed past preflight: locks=%d validate=%d apply=%d", provider.lockCalls, provider.validateCalls, provider.applyCalls)
	}
}

func TestCA1PartnerEntityInvalidTypedResultFailsBeforeFungibleWrite(t *testing.T) {
	actor := testActor(t)
	base := &testStore{policies: map[grant.LineKind]ResourcePolicy{grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "p1"}}}
	content := &testContent{policies: base.policies}
	rs := newMemoryReceipts()
	provider := &ca1Materializer{
		locks:   []lockkey.Key{ca1CharacterKey(t, 420, "character.fixture", int64(actor.PlayerID))},
		results: []PartnerEntityMaterialization{},
	}
	svc := Service{Store: base, Content: content, PartnerEntities: provider, Receipts: rs, ReceiptRead: rs}
	plan := grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "test", Operation: "mixed-partner", BusinessKey: "invalid-result", PolicyVersion: "p1"}, Lines: []grant.Line{{Kind: grant.PartnerEntity, ItemID: 7001, Amount: 1}, {Kind: grant.ScalarCurrency, ResourceKey: "gold", Amount: 4}}}
	_, err := svc.SettleGrantTx(context.Background(), &testTx{}, actor, plan, mustBindTestContent(t, testOperation(14), testContentRevisionA), GrantTxOptions{})
	if err == nil || !strings.Contains(err.Error(), "materialization count") {
		t.Fatalf("error=%v", err)
	}
	if base.saveScalarCalls != 0 || base.scalarExists {
		t.Fatalf("invalid provider result allowed fungible mutation: saves=%d scalar=%+v", base.saveScalarCalls, base.scalar)
	}
}

func TestCA1FungibleGrantRetainsV2ReceiptAndOmitsMaterializations(t *testing.T) {
	actor := testActor(t)
	store := &testStore{policies: map[grant.LineKind]ResourcePolicy{grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "p1"}}}
	rs := newMemoryReceipts()
	svc := Service{Store: store, Content: &testContent{policies: store.policies}, Receipts: rs, ReceiptRead: rs}
	plan := scalarPlan(actor.PlayerID, 3)
	got, err := svc.SettleGrantTx(context.Background(), &testTx{}, actor, plan, mustBindTestContent(t, testOperation(15), testContentRevisionA), GrantTxOptions{})
	if err != nil {
		t.Fatal(err)
	}
	if len(got.Materializations) != 0 {
		t.Fatalf("unexpected materializations=%+v", got.Materializations)
	}
	id, _ := plan.ReceiptIdentity()
	rr, ok, err := rs.Find(context.Background(), id)
	if err != nil || !ok {
		t.Fatalf("receipt ok=%v err=%v", ok, err)
	}
	if rr.ResultSchema != "gxb.i5.grant.v2" || bytes.Contains(rr.ResultPayload, []byte("materializations")) {
		t.Fatalf("fungible receipt drift schema=%s payload=%s", rr.ResultSchema, rr.ResultPayload)
	}
}

func TestCA1MaterialDebitPlansAllBalancesBeforeFirstWrite(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700000500, 0).UTC()
	def := economy.StackDefinition{ItemID: 9001, StackCap: 99}
	store := &testStore{
		scalarExists: true,
		scalar:       economy.ScalarBalance{PlayerID: actor.PlayerID, ResourceKey: "gold", Amount: 10, StateVersion: 2, UpdatedAt: now},
		stackExists:  true,
		stack:        economy.StackState{PlayerID: actor.PlayerID, ItemID: 9001, Quantity: 1, StateVersion: 3, AcquiredAt: now.Add(-time.Hour), UpdatedAt: now},
	}
	content := &testContent{policies: map[grant.LineKind]ResourcePolicy{
		grant.ScalarCurrency: {Kind: grant.ScalarCurrency, PolicyVersion: "p1"},
		grant.StackItem:      {Kind: grant.StackItem, Stack: &def, WireTableID: 9001, PolicyVersion: "p1"},
	}}
	debit := MaterialCostDebiter{Store: store, Content: content}
	_, err := debit.DebitMaterialCostTx(context.Background(), &testTx{}, actor.PlayerID, MaterialCost{Scalars: []ScalarMaterialCost{{ResourceKey: "gold", Amount: 2}}, Stacks: []StackMaterialCost{{ItemID: 9001, Amount: 2}}}, mustBindTestContent(t, operation.Context{ID: testUUID(16), StartedAt: now}, testContentRevisionA))
	if !errors.Is(err, economy.ErrInsufficientBalance) {
		t.Fatalf("error=%v", err)
	}
	if store.saveScalarCalls != 0 || store.saveStackCalls != 0 || store.deleteStackCalls != 0 || store.scalar.Amount != 10 || store.stack.Quantity != 1 {
		t.Fatalf("shortage partially wrote state scalar=%+v stack=%+v scalarSaves=%d stackSaves=%d deletes=%d", store.scalar, store.stack, store.saveScalarCalls, store.saveStackCalls, store.deleteStackCalls)
	}
	if len(store.lockTrace) < 3 || store.lockTrace[0] != "economy-owner" || store.lockTrace[1] != "scalar:gold" || store.lockTrace[2] != "stack:9001" {
		t.Fatalf("material lock order=%#v", store.lockTrace)
	}
}

func TestCA1MaterialDebitDeletesZeroAndAllowsImportedOverCapSpendDown(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700000600, 0).UTC()
	def := economy.StackDefinition{ItemID: 9001, StackCap: 5}
	content := &testContent{policies: map[grant.LineKind]ResourcePolicy{grant.StackItem: {Kind: grant.StackItem, Stack: &def, WireTableID: 9001, PolicyVersion: "p1"}}}

	zeroStore := &testStore{stackExists: true, stack: economy.StackState{PlayerID: actor.PlayerID, ItemID: 9001, Quantity: 3, StateVersion: 2, AcquiredAt: now.Add(-time.Hour), UpdatedAt: now}}
	debit := MaterialCostDebiter{Store: zeroStore, Content: content}
	got, err := debit.DebitMaterialCostTx(context.Background(), &testTx{}, actor.PlayerID, MaterialCost{Stacks: []StackMaterialCost{{ItemID: 9001, Amount: 3}}}, mustBindTestContent(t, operation.Context{ID: testUUID(17), StartedAt: now}, testContentRevisionA))
	if err != nil {
		t.Fatal(err)
	}
	if zeroStore.stackExists || zeroStore.deleteStackCalls != 1 || len(got.Stacks) != 1 || got.Stacks[0].Quantity != 0 {
		t.Fatalf("zero-delete result=%+v store=%+v deletes=%d", got, zeroStore.stack, zeroStore.deleteStackCalls)
	}

	overStore := &testStore{stackExists: true, stack: economy.StackState{PlayerID: actor.PlayerID, ItemID: 9001, Quantity: 10, StateVersion: 4, AcquiredAt: now.Add(-time.Hour), UpdatedAt: now}}
	debit = MaterialCostDebiter{Store: overStore, Content: content}
	got, err = debit.DebitMaterialCostTx(context.Background(), &testTx{}, actor.PlayerID, MaterialCost{Stacks: []StackMaterialCost{{ItemID: 9001, Amount: 3}}}, mustBindTestContent(t, operation.Context{ID: testUUID(18), StartedAt: now}, testContentRevisionA))
	if err != nil {
		t.Fatal(err)
	}
	if overStore.stack.Quantity != 7 || overStore.saveStackCalls != 1 || len(got.Stacks) != 1 || got.Stacks[0].Quantity != 7 {
		t.Fatalf("over-cap spend-down result=%+v store=%+v saves=%d", got, overStore.stack, overStore.saveStackCalls)
	}
}

type ca1RedeemStore struct {
	*testStore
	code             RedeemCode
	campaign         RedeemCampaign
	reward           grant.Plan
	redemptionExists bool
	inserted         int
	advanced         int
}

func (s *ca1RedeemStore) LockRedeemByDigestTx(_ context.Context, _ tx.Tx, _ [32]byte) (RedeemCode, RedeemCampaign, grant.Plan, error) {
	s.mu.Lock()
	s.lockTrace = append(s.lockTrace, "redeem-source")
	s.mu.Unlock()
	return s.code, s.campaign, s.reward, nil
}

func (s *ca1RedeemStore) FindRedemptionTx(context.Context, tx.Tx, string, string, string, int64) (Redemption, bool, error) {
	return Redemption{}, s.redemptionExists, nil
}

func (s *ca1RedeemStore) CountCampaignRedemptionsTx(context.Context, tx.Tx, string) (int64, error) {
	if s.redemptionExists {
		return 1, nil
	}
	return 0, nil
}

func (s *ca1RedeemStore) InsertRedemptionTx(_ context.Context, _ tx.Tx, _ Redemption) error {
	s.inserted++
	s.redemptionExists = true
	return nil
}

func (s *ca1RedeemStore) AdvanceRedeemCodeTx(_ context.Context, _ tx.Tx, _ RedeemCode) error {
	s.advanced++
	return nil
}

func TestCA1RedeemAcquiresGrantSuffixBeforeProgressionEligibility(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700000700, 0).UTC()
	base := &testStore{
		policies:    map[grant.LineKind]ResourcePolicy{grant.ScalarCurrency: {Kind: grant.ScalarCurrency, WireTableID: 1, PolicyVersion: "redeem-v1"}},
		progression: player.Progression{PlayerID: actor.PlayerID, Level: redeem.StockFunctionLevel, Exp: 0, StateVersion: 1, UpdatedAt: now},
	}
	store := &ca1RedeemStore{
		testStore: base,
		code:      RedeemCode{CodeID: "00000000-0000-0000-0000-000000000001", CampaignID: "00000000-0000-0000-0000-000000000002", CodeKind: "UNIQUE", Status: "ACTIVE", StateVersion: 1},
		campaign:  RedeemCampaign{CampaignID: "00000000-0000-0000-0000-000000000002", Campaign: redeem.Campaign{Status: redeem.Active, Subject: redeem.PlayerSubject, PolicyVersion: "redeem-v1"}, RewardBundleRevisionID: "00000000-0000-0000-0000-000000000003", PerSubjectCap: 1},
		reward:    grant.Plan{Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "gold", Amount: 5}}},
	}
	rs := newMemoryReceipts()
	content := &testContent{activeRevisions: []string{testContentRevisionA}, policies: base.policies}
	svc := Service{Runner: tx.Runner{DB: &testBeginner{}}, Store: store, Content: content, Receipts: rs, ReceiptRead: rs, RedeemSecret: []byte("0123456789abcdef0123456789abcdef")}
	op := operation.Context{ID: testUUID(19), StartedAt: now}
	got, err := svc.Redeem(context.Background(), actor, "VALID-CODE", "test", op)
	if err != nil {
		t.Fatal(err)
	}
	if len(got.Awards) != 1 || base.scalar.Amount != 5 || store.inserted != 1 || store.advanced != 1 {
		t.Fatalf("redeem result=%+v scalar=%+v inserted=%d advanced=%d", got, base.scalar, store.inserted, store.advanced)
	}
	base.mu.Lock()
	trace := append([]string(nil), base.lockTrace...)
	base.mu.Unlock()
	idxEconomy, idxProgression := -1, -1
	for i, x := range trace {
		if x == "economy-owner" && idxEconomy < 0 {
			idxEconomy = i
		}
		if x == "progression" && idxProgression < 0 {
			idxProgression = i
		}
	}
	if idxEconomy < 0 || idxProgression < 0 || idxEconomy >= idxProgression {
		t.Fatalf("Redeem retained progression->economy inversion: trace=%#v", trace)
	}
}

func TestCA1GrantV3DecoderPreservesTypedPayload(t *testing.T) {
	payload := json.RawMessage(`{"instance_ids":[101,102]}`)
	got := GrantResult{ReceiptID: "r", Awards: []Award{}, Materializations: []GrantMaterialization{{LineOrdinal: 2, ProviderID: "hero", ProviderRevision: "rev1", ResultSchema: "hero.v1", ResultPayload: payload}}}
	raw, err := json.Marshal(got)
	if err != nil {
		t.Fatal(err)
	}
	r := receipt.Receipt{ResultSchema: "gxb.i5.grant.v3", ResultPayload: raw}
	decoded, err := decodeGrantReceiptResult(r)
	if err != nil {
		t.Fatal(err)
	}
	if len(decoded.Materializations) != 1 || !bytes.Equal(decoded.Materializations[0].ResultPayload, payload) {
		t.Fatalf("decoded=%+v", decoded)
	}
}
