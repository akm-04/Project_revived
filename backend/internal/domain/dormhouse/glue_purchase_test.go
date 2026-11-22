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
	// A backward day step stays on the stored day instead of refusing; it never
	// grants a second daily reset.
	if count, err = EffectiveGluePurchaseCount(&second, player, 0, at); err != nil || count != 2 {
		t.Fatalf("backwards day: count=%d err=%v", count, err)
	}
	vipPrevious := GluePurchases{Player: player, GameDay: 2, Count: 1, StateVersion: 4, UpdatedAt: at.Add(time.Minute)}
	backwardDay, _, err := rules.PlanPurchase(&vipPrevious, player, 1, 0, at.Add(-time.Second))
	if err != nil || backwardDay.GameDay != 2 || backwardDay.Count != 2 {
		t.Fatalf("backwards day purchase = %+v %v", backwardDay, err)
	}
	// K2/K3: a backwards clock step observes at the stored row and keeps the
	// written timestamp monotone; it is not a stale-time refusal.
	if count, err = EffectiveGluePurchaseCount(&second, player, 2, at.Add(-time.Second)); err != nil || count != 0 {
		t.Fatalf("backwards timestamp: count=%d err=%v", count, err)
	}
	if planned, _, err := rules.PlanPurchase(&second, player, 0, 2, at.Add(-time.Second)); err != nil || planned.UpdatedAt.Before(second.UpdatedAt) {
		t.Fatalf("backwards purchase stamp = %+v %v", planned, err)
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
