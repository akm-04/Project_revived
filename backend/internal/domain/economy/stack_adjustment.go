package economy

import (
	"errors"
	"math"
	"time"
)

// PlanAdjustment is the signed owner operation. Grant plans remain positive
// entitlements; consuming stock must not disguise a debit as a negative grant.
// The caller persists this result and its semantic receipt in one transaction.
// A zero resulting quantity means delete, not a durable empty inventory row.
func (s StackState) PlanAdjustment(delta int64, def StackDefinition, now time.Time) (StackCreditResult, error) {
	if err := s.Validate(); err != nil {
		return StackCreditResult{}, err
	}
	if err := def.Validate(); err != nil {
		return StackCreditResult{}, err
	}
	if def.ItemID != s.ItemID {
		return StackCreditResult{}, ErrUnknownResource
	}
	if now.IsZero() {
		return StackCreditResult{}, errors.New("invalid stack adjustment time")
	}
	if delta == 0 {
		return StackCreditResult{State: s}, nil
	}
	if s.StateVersion == math.MaxInt64 {
		return StackCreditResult{}, errors.New("stack version overflow")
	}
	if delta > 0 {
		return s.PlanCredit(delta, def, now)
	}
	// Compare without negating delta: -MinInt64 is not representable.
	if delta < -s.Quantity {
		return StackCreditResult{}, ErrInsufficientBalance
	}
	s.Quantity += delta
	s.StateVersion++
	s.UpdatedAt = now.UTC()
	// Fit/Overflow describe positive credits only. Debits never create mail.
	return StackCreditResult{State: s}, nil
}
