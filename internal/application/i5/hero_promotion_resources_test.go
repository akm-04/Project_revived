package i5

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type revealAfterFirstFindReceipts struct {
	inner     *memoryReceipts
	hideFinds int
}

func (r *revealAfterFirstFindReceipts) PutTx(ctx context.Context, t tx.Tx, got receipt.Receipt) (receipt.PutResult, error) {
	return r.inner.PutTx(ctx, t, got)
}
func (r *revealAfterFirstFindReceipts) FindTx(ctx context.Context, q tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	if r.hideFinds > 0 {
		r.hideFinds--
		return receipt.Receipt{}, false, nil
	}
	return r.inner.FindTx(ctx, q, id)
}
func (r *revealAfterFirstFindReceipts) Find(ctx context.Context, id receipt.Identity) (receipt.Receipt, bool, error) {
	return r.inner.Find(ctx, id)
}

func TestStrictRestorationPrepareApplyFailsClosedOnReplay(t *testing.T) {
	svc, store, _, actor, fixture := exchangeService(t)
	plan := exchangePlan(actor.PlayerID, 200, 3, "partner:77")
	prepared, err := svc.PrepareStrictRestorationTx(context.Background(), &testTx{}, actor, StrictRestorationRequest{Plan: plan, AllowOverflowMail: true}, fixture.op(t, 41))
	if err != nil {
		t.Fatal(err)
	}
	if store.stacks[200].Quantity != 1 {
		t.Fatal("prepare mutated restoration stack")
	}
	got, err := svc.ApplyStrictRestorationTx(context.Background(), &testTx{}, prepared)
	if err != nil {
		t.Fatal(err)
	}
	if store.stacks[200].Quantity != 4 || len(got.Awards) != 1 {
		t.Fatalf("restoration result=%+v qty=%d", got, store.stacks[200].Quantity)
	}
	if _, err := svc.ApplyStrictRestorationTx(context.Background(), &testTx{}, prepared); err == nil {
		t.Fatal("second strict Apply accepted")
	}
}

func TestStrictRestorationExistingNestedReceiptFailsPrepare(t *testing.T) {
	svc, _, _, actor, fixture := exchangeService(t)
	plan := exchangePlan(actor.PlayerID, 200, 1, "partner:77")
	if _, err := svc.SettleGrantTx(context.Background(), &testTx{}, actor, plan, fixture.op(t, 42), GrantTxOptions{AllowOverflowMail: true}); err != nil {
		t.Fatal(err)
	}
	if _, err := svc.PrepareStrictRestorationTx(context.Background(), &testTx{}, actor, StrictRestorationRequest{Plan: plan, AllowOverflowMail: true}, fixture.op(t, 43)); !errors.Is(err, ErrStrictRestorationAlreadySettled) {
		t.Fatalf("err=%v", err)
	}
}

func TestStrictRestorationConcurrentWaiterRechecksReceiptAfterLockAcquisition(t *testing.T) {
	svc, _, rs, actor, fixture := exchangeService(t)
	plan := exchangePlan(actor.PlayerID, 200, 1, "partner:77")
	if _, err := svc.SettleGrantTx(context.Background(), &testTx{}, actor, plan, fixture.op(t, 47), GrantTxOptions{AllowOverflowMail: true}); err != nil {
		t.Fatal(err)
	}
	gated := &revealAfterFirstFindReceipts{inner: rs, hideFinds: 1}
	svc.Receipts, svc.ReceiptRead = gated, gated
	_, err := svc.PrepareStrictRestorationTx(context.Background(), &testTx{}, actor, StrictRestorationRequest{Plan: plan, AllowOverflowMail: true}, fixture.op(t, 48))
	if !errors.Is(err, ErrStrictRestorationAlreadySettled) {
		t.Fatalf("waiter err=%v", err)
	}
}

func TestHeroPromotionPrepareClosesUnionBeforeSnapshotAndApplyUsesSubset(t *testing.T) {
	svc, store, _, actor, fixture := exchangeService(t)
	content := svc.Content.(*exchangeContent)
	now := time.Unix(1700000100, 0).UTC()
	store.progression = testPlayerProgression(actor.PlayerID, 80, now)
	store.scalar = economy.ScalarBalance{PlayerID: actor.PlayerID, ResourceKey: "mana", Amount: 1000, StateVersion: 1, UpdatedAt: now}
	store.scalarExists = true
	content.stackDefs[300] = economy.StackDefinition{ItemID: 300, StackCap: 99, OverflowToMail: true}
	content.testContent.policies[grant.ScalarCurrency] = ResourcePolicy{Kind: grant.ScalarCurrency, PolicyVersion: testContentRevisionA}
	restore := exchangePlan(actor.PlayerID, 200, 2, "partner:77")
	prepared, err := svc.PrepareHeroPromotionResourcesTx(context.Background(), &testTx{}, actor, HeroPromotionResourceRequest{
		PotentialStackItemIDs: []int64{300, 100}, Restoration: &restore, AllowOverflowMail: true,
	}, fixture.op(t, 44))
	if err != nil {
		t.Fatal(err)
	}
	if prepared.PlayerLevel() != 80 || prepared.Mana() != 1000 || !prepared.HasRestoration() {
		t.Fatalf("snapshot level=%d mana=%d restore=%v", prepared.PlayerLevel(), prepared.Mana(), prepared.HasRestoration())
	}
	if got, ok := prepared.StackQuantity(300); !ok || got != 0 {
		t.Fatalf("absent potential stack=(%d,%v)", got, ok)
	}
	if got := prepared.PreparedStackItemIDs(); !reflect.DeepEqual(got, []int64{100, 300}) {
		t.Fatalf("prepared ids=%v", got)
	}
	store.mu.Lock()
	trace := append([]string(nil), store.lockTrace...)
	store.mu.Unlock()
	wantPrefix := []string{"mail:NORMAL", "economy-owner", "progression", "scalar:mana", "stack:100", "stack:200", "stack:300"}
	if len(trace) < len(wantPrefix) || !reflect.DeepEqual(trace[:len(wantPrefix)], wantPrefix) {
		t.Fatalf("union lock prefix=%v want=%v full=%v", trace[:minInt(len(trace), len(wantPrefix))], wantPrefix, trace)
	}
	result, err := svc.ApplyHeroPromotionResourcesTx(context.Background(), &testTx{}, prepared, HeroEquipmentResourceDebit{Mana: 250, Stacks: []HeroEquipmentStackDebit{{ItemID: 100, Count: 2}}})
	if err != nil {
		t.Fatal(err)
	}
	if result.Debit.Mana.Amount != 750 || result.Restoration == nil || store.stacks[100].Quantity != 3 || store.stacks[200].Quantity != 3 {
		t.Fatalf("result=%+v debitQty=%d restoreQty=%d", result, store.stacks[100].Quantity, store.stacks[200].Quantity)
	}
	if _, err := svc.ApplyHeroPromotionResourcesTx(context.Background(), &testTx{}, prepared, HeroEquipmentResourceDebit{}); err == nil {
		t.Fatal("second promotion Apply accepted")
	}
}

func TestNeutralPromotionResourceAdapterPreservesHeroBehavior(t *testing.T) {
	svc, store, _, actor, fixture := exchangeService(t)
	content := svc.Content.(*exchangeContent)
	now := time.Unix(1700000100, 0).UTC()
	store.progression = testPlayerProgression(actor.PlayerID, 80, now)
	store.scalar = economy.ScalarBalance{PlayerID: actor.PlayerID, ResourceKey: "mana", Amount: 1000, StateVersion: 1, UpdatedAt: now}
	store.scalarExists = true
	content.testContent.policies[grant.ScalarCurrency] = ResourcePolicy{Kind: grant.ScalarCurrency, PolicyVersion: testContentRevisionA}

	prepared, err := svc.PreparePromotionResourcesTx(context.Background(), &testTx{}, actor, PromotionResourceRequest{PotentialStackItemIDs: []int64{100}}, fixture.op(t, 49))
	if err != nil {
		t.Fatal(err)
	}
	got, err := svc.ApplyPromotionResourcesTx(context.Background(), &testTx{}, prepared, PromotionResourceDebit{Mana: 125, Stacks: []HeroEquipmentStackDebit{{ItemID: 100, Count: 1}}})
	if err != nil {
		t.Fatal(err)
	}
	if got.Debit.Mana.Amount != 875 || store.stacks[100].Quantity != 4 || got.Restoration != nil {
		t.Fatalf("neutral promotion result=%+v mana=%d stack=%d", got, store.scalar.Amount, store.stacks[100].Quantity)
	}
}

func TestHeroPromotionPrepareRejectsRestorationPotentialCollision(t *testing.T) {
	svc, _, _, actor, fixture := exchangeService(t)
	content := svc.Content.(*exchangeContent)
	content.testContent.policies[grant.ScalarCurrency] = ResourcePolicy{Kind: grant.ScalarCurrency, PolicyVersion: testContentRevisionA}
	restore := exchangePlan(actor.PlayerID, 100, 1, "partner:77")
	_, err := svc.PrepareHeroPromotionResourcesTx(context.Background(), &testTx{}, actor, HeroPromotionResourceRequest{PotentialStackItemIDs: []int64{100}, Restoration: &restore, AllowOverflowMail: true}, fixture.op(t, 45))
	if !errors.Is(err, ErrHeroPromotionResourceCollision) {
		t.Fatalf("err=%v", err)
	}
}

func TestHeroPromotionCollectOnlyPrepareHasNoRestoration(t *testing.T) {
	svc, store, _, actor, fixture := exchangeService(t)
	content := svc.Content.(*exchangeContent)
	now := time.Unix(1700000100, 0).UTC()
	store.progression = testPlayerProgression(actor.PlayerID, 80, now)
	store.scalar = economy.ScalarBalance{PlayerID: actor.PlayerID, ResourceKey: "mana", Amount: 1000, StateVersion: 1, UpdatedAt: now}
	store.scalarExists = true
	content.testContent.policies[grant.ScalarCurrency] = ResourcePolicy{Kind: grant.ScalarCurrency, PolicyVersion: testContentRevisionA}
	prepared, err := svc.PrepareHeroPromotionResourcesTx(context.Background(), &testTx{}, actor, HeroPromotionResourceRequest{PotentialStackItemIDs: []int64{100}}, fixture.op(t, 46))
	if err != nil {
		t.Fatal(err)
	}
	if prepared.HasRestoration() {
		t.Fatal("collect-only plan invented restoration")
	}
	got, err := svc.ApplyHeroPromotionResourcesTx(context.Background(), &testTx{}, prepared, HeroEquipmentResourceDebit{})
	if err != nil || got.Restoration != nil || got.Debit.Mana.Amount != 1000 {
		t.Fatalf("result=%+v err=%v", got, err)
	}
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}
