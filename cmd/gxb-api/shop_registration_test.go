package main

import (
	"testing"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// TestShopRoutesRegister proves the constructed 11C owner registers its six
// routes once and leaves MID 35 to the inactive dispatcher.
func TestShopRoutesRegister(t *testing.T) {
	composition := stockruntime.NewShopComposition(stockruntime.ShopDependencies{})
	router := httpedge.NewRouter()
	for _, mid := range stockruntime.ShopMIDs {
		if err := router.Register(mid, composition.Dispatcher); err != nil {
			t.Fatalf("MID %d did not register: %v", mid, err)
		}
	}
	for _, mid := range stockruntime.ShopMIDs {
		if err := router.Register(mid, composition.Dispatcher); err == nil {
			t.Fatalf("MID %d registered twice", mid)
		}
	}
	want := map[uint16]bool{32: true, 33: true, 34: true, 37: true, 38: true, 2982: true}
	if len(stockruntime.ShopMIDs) != len(want) {
		t.Fatalf("registration set = %v", stockruntime.ShopMIDs)
	}
	for _, mid := range stockruntime.ShopMIDs {
		if !want[mid] {
			t.Fatalf("unexpected MID %d in the 11C registration set", mid)
		}
	}
}
