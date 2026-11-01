package guild

import (
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// RentalKind orders offer locks: HERO sorts before PET (I9_GUILD_RENTAL_V1 C2).
type RentalKind string

const (
	RentalHero RentalKind = "HERO"
	RentalPet  RentalKind = "PET"
)

// RentalOffer is one open lent unit. Force is fixed at placement.
type RentalOffer struct {
	Lender    identity.PlayerID
	Kind      RentalKind
	Unit      int64
	Guild     ID
	Force     int64
	RentAward int64
	RentTime  time.Time
}

// RentalUse is a borrower's one unit from one lender for one game day.
type RentalUse struct {
	Borrower     identity.PlayerID
	Lender       identity.PlayerID
	GameDay      int64
	Kind         RentalKind
	Unit         int64
	CampaignType int64
	CostMana     int64
	UsedAt       time.Time
}

// RentalMoney is the PRIVATE_POLICY rental arithmetic of I9_GUILD_POLICY_V1 (D408).
type RentalMoney struct {
	PriceForceDivisor          int64
	PriceFloorMana             int64
	HourlyInterestForceDivisor int64
	RecallMinimumSeconds       int64
	LevelUpCeiling             int64
}

func (m RentalMoney) Valid() bool {
	return m.PriceForceDivisor > 0 && m.PriceFloorMana > 0 && m.HourlyInterestForceDivisor > 0 && m.RecallMinimumSeconds > 0 && m.LevelUpCeiling >= 0
}

func (m RentalMoney) Price(force int64) int64 {
	return max(force/m.PriceForceDivisor, m.PriceFloorMana)
}

// Interest accrues per whole hour since placement.
func (m RentalMoney) Interest(offer RentalOffer, at time.Time) int64 {
	hours := int64(at.Sub(offer.RentTime) / time.Hour)
	if hours <= 0 {
		return 0
	}
	return offer.Force * hours / m.HourlyInterestForceDivisor
}

// Payout is everything the lender collects when the offer closes.
func (m RentalMoney) Payout(offer RentalOffer, at time.Time) int64 {
	return offer.RentAward + m.Interest(offer, at)
}

func (m RentalMoney) RecallAllowed(offer RentalOffer, at time.Time) bool {
	return at.Sub(offer.RentTime) >= time.Duration(m.RecallMinimumSeconds)*time.Second
}

// LevelAllowed is rule 6 and 16: the unit may exceed the borrower by the VIP
// rent_level_up, up to the ceiling.
func (m RentalMoney) LevelAllowed(unitLevel, borrowerLevel, vipLevelUp int64) bool {
	return unitLevel <= borrowerLevel+min(vipLevelUp, m.LevelUpCeiling)
}
