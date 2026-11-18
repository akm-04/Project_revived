package main

import (
	"testing"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// TestItemsEnergyRoutesRegister proves the constructed 11B command owner is
// registrable once and leaves the shared campaign MIDs 28/29 to the dispatcher
// that also owns the 11B commands.
func TestItemsEnergyRoutesRegister(t *testing.T) {
	composition := stockruntime.NewItemsEnergyComposition(stockruntime.ItemsEnergyDependencies{})
	dispatcher := stockruntime.ItemsEnergyDispatcher{Service: composition.Service}
	router := httpedge.NewRouter()
	registered := append(append([]uint16(nil), stockruntime.ItemsEnergyMIDs...), stockruntime.ItemsEnergySharedMIDs...)
	for _, mid := range registered {
		if err := router.Register(mid, dispatcher); err != nil {
			t.Fatalf("MID %d did not register: %v", mid, err)
		}
	}
	for _, mid := range registered {
		if err := router.Register(mid, dispatcher); err == nil {
			t.Fatalf("MID %d registered twice", mid)
		}
	}
	want := map[uint16]bool{27: true, 28: true, 29: true, 82: true, 86: true, 87: true, 96: true, 97: true, 241: true}
	if len(registered) != len(want) {
		t.Fatalf("registration set = %v", registered)
	}
	for _, mid := range registered {
		if !want[mid] {
			t.Fatalf("unexpected MID %d in the 11B registration set", mid)
		}
	}
}
