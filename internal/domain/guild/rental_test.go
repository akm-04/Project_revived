package guild

import (
	"testing"
	"time"
)

func TestRentalMoney(t *testing.T) {
	money := RentalMoney{PriceForceDivisor: 2, PriceFloorMana: 1000, HourlyInterestForceDivisor: 100, RecallMinimumSeconds: 1800, LevelUpCeiling: 5}
	if !money.Valid() {
		t.Fatal("policy invalid")
	}
	if money.Price(10000) != 5000 || money.Price(100) != 1000 {
		t.Fatalf("price %d %d", money.Price(10000), money.Price(100))
	}
	placed := time.Date(2026, 11, 1, 0, 0, 0, 0, time.UTC)
	offer := RentalOffer{Force: 10000, RentAward: 700, RentTime: placed}
	if got := money.Interest(offer, placed.Add(59*time.Minute)); got != 0 {
		t.Fatalf("part hour interest %d", got)
	}
	if got := money.Payout(offer, placed.Add(2*time.Hour)); got != 900 {
		t.Fatalf("payout %d", got)
	}
	if money.RecallAllowed(offer, placed.Add(1799*time.Second)) || !money.RecallAllowed(offer, placed.Add(1800*time.Second)) {
		t.Fatal("recall boundary")
	}
	if !money.LevelAllowed(55, 50, 9) || money.LevelAllowed(56, 50, 9) || money.LevelAllowed(53, 50, 2) {
		t.Fatal("level gate")
	}
}
