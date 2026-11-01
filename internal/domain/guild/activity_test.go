package guild

import "testing"

func TestActivityBalanceClampsToTheGuildCap(t *testing.T) {
	if got := ActivityBalance(279000, 500); got != 279500 {
		t.Fatalf("below cap = %d", got)
	}
	if got := ActivityBalance(279000, 5000); got != ActivityGuildCap {
		t.Fatalf("above cap = %d", got)
	}
}

func TestLifetimeAfterLeavingRoundsDown(t *testing.T) {
	if got := LifetimeAfterLeaving(1001); got != 500 {
		t.Fatalf("lifetime = %d", got)
	}
}
