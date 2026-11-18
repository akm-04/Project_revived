package main

import (
	"testing"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// TestItemsEnergyRoutesRegister proves the 11B MID set is registrable once and
// leaves the shared campaign MIDs 28/29 unclaimed by its exclusive list.
func TestItemsEnergyRoutesRegister(t *testing.T) {
	router := httpedge.NewRouter()
	dispatcher := stockruntime.ItemsEnergyDispatcher{}
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
