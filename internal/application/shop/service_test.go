package shop

import (
	"context"
	"errors"
	"testing"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	achd "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	d "gxb.local/backend/v2/internal/domain/shop"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type stubAchievements struct{ err error }

func (s stubAchievements) ObserveShopPurchaseTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time) error {
	return s.err
}

type recordingFacts struct {
	calls int
	facts []objective.Fact
}

func (f *recordingFacts) PrepareTx(c context.Context, _ tx.Tx, _ identity.PlayerID, _ gen.TimedOperation) (context.Context, error) {
	return c, nil
}

func (f *recordingFacts) RecordTx(_ context.Context, _ tx.Tx, _ operation.Context, facts ...objective.Fact) error {
	f.calls++
	f.facts = append(f.facts, facts...)
	return nil
}

func purchaseScope(t *testing.T) (gen.TimedScope, operation.Context) {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: "test-revision"})
	if err != nil {
		t.Fatal(err)
	}
	op := operation.Context{ID: id, StartedAt: time.Unix(1700000000, 0).UTC(), EntropySeed: [32]byte{1}, Policies: policies}
	timed, err := gen.NewTimedOperation(op, op.StartedAt)
	if err != nil {
		t.Fatal(err)
	}
	return gen.TimedScope{Operation: timed}, op
}

func TestObservePurchaseRecordsOneCrystalFact(t *testing.T) {
	sc, op := purchaseScope(t)
	facts := &recordingFacts{}
	service := Service{Achievements: stubAchievements{}, Facts: facts}
	player := identity.PlayerID(10001001)
	if err := service.observePurchase(context.Background(), sc, player, 20); err != nil {
		t.Fatal(err)
	}
	if facts.calls != 1 || len(facts.facts) != 1 {
		t.Fatalf("calls=%d facts=%+v", facts.calls, facts.facts)
	}
	fact := facts.facts[0]
	if fact.PlayerID != player || fact.SourceDomain != "shop" || fact.SourceBusinessKey != op.ID.String() || fact.Kind != objective.ShopPurchaseKind || fact.Delta != 20 {
		t.Fatalf("fact %+v", fact)
	}
}

func TestObservePurchaseWithoutCrystalRecordsNoFact(t *testing.T) {
	sc, _ := purchaseScope(t)
	facts := &recordingFacts{}
	service := Service{Achievements: stubAchievements{}, Facts: facts}
	if err := service.observePurchase(context.Background(), sc, identity.PlayerID(10001001), 0); err != nil {
		t.Fatal(err)
	}
	if facts.calls != 0 {
		t.Fatalf("coin-only purchase recorded %d facts", facts.calls)
	}
}

func TestObservePurchaseMapsAchievementOvertaken(t *testing.T) {
	sc, _ := purchaseScope(t)
	player := identity.PlayerID(10001001)
	service := Service{Achievements: stubAchievements{err: errors.New("defect")}, Facts: &recordingFacts{}}
	if err := service.observePurchase(context.Background(), sc, player, 20); err == nil {
		t.Fatal("achievement defect was swallowed")
	}
	service.Achievements = stubAchievements{err: achd.ErrOvertaken}
	if err := service.observePurchase(context.Background(), sc, player, 20); !errors.Is(err, d.ErrStaleState) {
		t.Fatalf("overtaken purchase: %v", err)
	}
}

func TestInfoOmitsHotHeroForSpaceShopWithoutFeaturedStock(t *testing.T) {
	sc, _ := purchaseScope(t)
	catalog := d.Catalog{Shops: map[int64]d.Shop{8: {Type: 8}, 1: {Type: 1}}}
	service := Service{}
	for _, testCase := range []struct {
		shopType int64
		present  bool
	}{{shopType: 8, present: false}, {shopType: 1, present: true}} {
		reply, err := service.info(context.Background(), sc, catalog, catalog.Shops[testCase.shopType], d.Row{}, identity.PlayerID(10001001))
		if err != nil {
			t.Fatal(err)
		}
		if _, present := reply["hot_hero"]; present != testCase.present {
			t.Fatalf("shop type %d hot_hero present=%t, want %t", testCase.shopType, present, testCase.present)
		}
	}
}

func TestCrystalDebitReadsOnlyTheCrystalScalar(t *testing.T) {
	mixed := appi5.MaterialCost{Scalars: []appi5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: 30}, {ResourceKey: "mana", Amount: 7}}}
	if got := crystalDebit(mixed); got != 30 {
		t.Fatalf("crystal debit %d", got)
	}
	manaOnly := appi5.MaterialCost{Scalars: []appi5.ScalarMaterialCost{{ResourceKey: "mana", Amount: 7}}}
	if got := crystalDebit(manaOnly); got != 0 {
		t.Fatalf("mana-only debit %d", got)
	}
}
