package stockruntime

import "testing"

func TestAdventureIllusionAdmissionRequiresTheOwnerSeat(t *testing.T) {
	binding, found := NewAdmissionRouter()["ADVENTURE_ILLUSION"]
	if !found {
		t.Fatal("no ADVENTURE_ILLUSION admission binding")
	}
	if binding.ConvenerFirst {
		t.Fatal("ADVENTURE_ILLUSION accepts a non-owner as convener; C5 needs the seated roster in seat order")
	}
}
