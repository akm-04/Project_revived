package i5

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

type gluePurchaseStore struct {
	*floorStore
	balances map[string]economy.ScalarBalance
}

func (store *gluePurchaseStore) LockScalarTx(_ context.Context, _ tx.Tx, player identity.PlayerID, key string, _ time.Time) (economy.ScalarBalance, bool, error) {
	balance, exists := store.balances[key]
	return balance, exists, nil
}
func (store *gluePurchaseStore) ReadScalarTx(_ context.Context, _ tx.Queryer, player identity.PlayerID, key string) (economy.ScalarBalance, bool, error) {
	balance, exists := store.balances[key]
	return balance, exists, nil
}
func (store *gluePurchaseStore) SaveScalarTx(_ context.Context, _ tx.Tx, balance economy.ScalarBalance, exists bool) error {
	previous, present := store.balances[balance.ResourceKey]
	if present != exists || (exists && previous.StateVersion+1 != balance.StateVersion) {
		return errors.New("bad scalar CAS")
	}
	store.balances[balance.ResourceKey] = balance
	return nil
}

type gluePurchaseContent struct{ *testContent }

func (*gluePurchaseContent) ScalarDailyFloorMinimumTx(context.Context, tx.Queryer) (int64, bool, error) {
	return 100, true, nil
}
func TestGluePurchaseUsesClosedUnionAndPreservesStartLimitSemantics(t *testing.T) {
	actor := testActor(t)
	operation := mustBindTestContent(t, testOperation(71), testContentRevisionA)
	at := operation.StartedAt
	base := &testStore{policies: map[grant.LineKind]ResourcePolicy{grant.ScalarCurrency: {Kind: grant.ScalarCurrency, PolicyVersion: testContentRevisionA}}}
	store := &gluePurchaseStore{floorStore: &floorStore{testStore: base}, balances: map[string]economy.ScalarBalance{"crystal": {PlayerID: actor.PlayerID, ResourceKey: "crystal", Amount: 1000, StateVersion: 1, UpdatedAt: at}, "glue": {PlayerID: actor.PlayerID, ResourceKey: "glue", Amount: 299, StateVersion: 1, UpdatedAt: at}}}
	receipts := newMemoryReceipts()
	service := Service{Store: store, Content: &gluePurchaseContent{&testContent{policies: base.policies}}, Receipts: receipts, ReceiptRead: receipts}
	request := GluePurchaseRequest{CrystalCost: 50, GlueAmount: 50, StartLimit: 300, Source: grant.SourceIdentity{Domain: "dorm-house", Operation: "buy-glue", BusinessKey: "native", Occurrence: operation.ID.String(), PolicyVersion: "source-qualified"}}
	prepared, err := service.PrepareGluePurchaseTx(context.Background(), &testTx{}, actor, request, operation)
	if err != nil {
		t.Fatal(err)
	}
	if store.balances["crystal"].Amount != 1000 || store.balances["glue"].Amount != 299 || store.anchorSaves != 0 {
		t.Fatal("prepare mutated values")
	}
	_, err = service.ApplyGluePurchaseTx(context.Background(), &testTx{}, prepared)
	if err != nil || store.balances["crystal"].Amount != 950 || store.balances["glue"].Amount != 349 || store.anchorSaves != 1 {
		t.Fatal(store.balances, err)
	}
	_, err = service.PrepareGluePurchaseTx(context.Background(), &testTx{}, actor, request, operation)
	if !errors.Is(err, ErrMaterialExchangeGrantAlreadySettled) {
		t.Fatal("fresh debit after inner receipt", err)
	}
	operation.ID = testUUID(72)
	request.Source.Occurrence = operation.ID.String()
	operation.StartedAt = operation.StartedAt.Add(time.Second)
	if _, err = service.PrepareGluePurchaseTx(context.Background(), &testTx{}, actor, request, operation); !errors.Is(err, ErrGluePurchaseLimit) {
		t.Fatal("over limit", err)
	}
	if store.balances["crystal"].Amount != 950 {
		t.Fatal("limit refusal charged crystal")
	}
	legacy := MaterialExchangeRequest{Cost: MaterialCost{Scalars: []ScalarMaterialCost{{ResourceKey: "crystal", Amount: 50}}}, Restoration: grant.Plan{PlayerID: actor.PlayerID, Source: request.Source, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "glue", Amount: 50}}}}
	if _, err = service.PrepareMaterialExchangeTx(context.Background(), &testTx{}, actor, legacy, operation); err == nil {
		t.Fatal("old stack-only contract widened")
	}
}

func TestGluePurchaseRejectsInvalidRequestsBeforeAccessingProviders(t *testing.T) {
	for _, request := range []GluePurchaseRequest{{}, {CrystalCost: -1, GlueAmount: 50, StartLimit: 300}, {CrystalCost: 50, GlueAmount: 0, StartLimit: 300}, {CrystalCost: 50, GlueAmount: 50, StartLimit: 0}} {
		if _, err := (Service{}).PrepareGluePurchaseTx(context.Background(), &testTx{}, testActor(t), request, testOperation(73)); !errors.Is(err, ErrInvalidGluePurchase) {
			t.Fatal(request, err)
		}
	}
	if _, err := (Service{}).ApplyGluePurchaseTx(context.Background(), &testTx{}, nil); !errors.Is(err, ErrInvalidGluePurchase) {
		t.Fatal(err)
	}
}
