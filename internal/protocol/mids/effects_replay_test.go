package mids

import "testing"

// TestCompatAndServerTimeEffects pins the I9-11D replay class: the server-time
// reply must never be replayed from a stored mark (its countdown reset would go
// backwards), the 279 terminal settles nothing, and the three preference MIDs
// are state.
func TestCompatAndServerTimeEffects(t *testing.T) {
	for _, mid := range []uint16{3, 279} {
		if StateChanging(mid) {
			t.Fatalf("MID %d is classified state-changing; a stored reply must not be replayed", mid)
		}
	}
	for _, mid := range []uint16{1025, 1026, 1864} {
		if !StateChanging(mid) {
			t.Fatalf("MID %d is classified read; an undelivered reply would not be replayed", mid)
		}
	}
}
