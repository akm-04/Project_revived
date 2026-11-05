package dormhouse

import (
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"math"
	"testing"
	"time"
)

func TestGluePurchaseCounterUsesSourceLadderAndReadOnlyDayReset(t *testing.T) {
	at := time.Date(2026, 11, 5, 20, 59, 59, 0, time.UTC)
	rules := GlueRules{DailyFloor: 100, PurchaseAmount: 50, PurchaseStartLimit: 300, VIPDailyCaps: map[int64]int64{0: 1, 1: 2}, PurchaseCosts: map[int64]int64{1: 50, 2: 100}}
	player := identity.PlayerID(7)
	first, cost, err := rules.PlanPurchase(nil, player, 0, 1, at)
	if err != nil || cost != 50 || first.Count != 1 || first.StateVersion != 1 {
		t.Fatal(first, cost, err)
	}
	if _, _, err = rules.PlanPurchase(&first, player, 0, 1, at); !errors.Is(err, ErrGlueDailyLimit) {
		t.Fatal(err)
	}
	second, cost, err := rules.PlanPurchase(&first, player, 1, 1, at.Add(time.Millisecond))
	if err != nil || cost != 100 || second.Count != 2 || second.StateVersion != 2 {
		t.Fatal(second, cost, err)
	}
	count, err := EffectiveGluePurchaseCount(&second, player, 2, at.Add(time.Second))
	if err != nil || count != 0 || second.Count != 2 {
		t.Fatal(count, second, err)
	}
	next, cost, err := rules.PlanPurchase(&second, player, 0, 2, at.Add(time.Second))
	if err != nil || cost != 50 || next.Count != 1 || next.StateVersion != 3 {
		t.Fatal(next, cost, err)
	}
	if _, _, err = rules.PlanPurchase(&second, player, 9, 1, at); err == nil {
		t.Fatal("unknown VIP accepted")
	}
	if _, err = EffectiveGluePurchaseCount(&second, player, 0, at); err == nil {
		t.Fatal("backwards day accepted")
	}
	if _, err = EffectiveGluePurchaseCount(&second, player, 2, at.Add(-time.Second)); err == nil {
		t.Fatal("backwards timestamp accepted")
	}
	if _, err = EffectiveGluePurchaseCount(&second, identity.PlayerID(8), 2, at); err == nil {
		t.Fatal("foreign counter accepted")
	}
	second.StateVersion = math.MaxInt64
	if _, _, err = rules.PlanPurchase(&second, player, 1, 2, at.Add(time.Second)); err == nil {
		t.Fatal("version wrapped")
	}
	delete(rules.PurchaseCosts, 2)
	if _, _, err = rules.PlanPurchase(&first, player, 1, 1, at); err == nil {
		t.Fatal("missing ordinal cost accepted")
	}
}
