package i5

import (
	"errors"
	"math/big"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
)

// PetPromotionRestorationPolicyVersion freezes the CA4-4B preservation policy
// identity. Source fractions and denominations remain immutable content facts;
// this identifier names only the compatibility rounding/decomposition rule.
const PetPromotionRestorationPolicyVersion = "PET_FUMO_RESTORE_V1_AGGREGATE_FLOOR_GREEDY_SOURCE_ORDER"

// PromotionRestorationInput is one raw-Fumo value that will be destroyed by a
// promotion transition together with its source-qualified equipment quality.
type PromotionRestorationInput struct {
	RawFumo int64
	Quality int64
}

// PlanPromotionRestoration is the family-neutral CA4 restoration calculator.
// It performs exact rational aggregation, floors once after aggregation,
// greedily decomposes in source denomination order, and discards residual value
// below the smallest denomination. Family-specific eligibility and q1 policy
// remain with the Character caller; this function never invents a coefficient.
func PlanPromotionRestoration(in []PromotionRestorationInput, policy character.PromotionRestorationPolicy) ([]grant.Line, error) {
	if err := policy.Validate(); err != nil {
		return nil, err
	}
	fractions := make(map[int64]character.PromotionRestorationFraction, len(policy.Fractions))
	for _, f := range policy.Fractions {
		fractions[f.Quality] = f
	}
	total := new(big.Rat)
	for _, x := range in {
		if x.RawFumo < 0 {
			return nil, errors.New("i5: negative promotion restoration Fumo")
		}
		if x.RawFumo == 0 {
			continue
		}
		f, ok := fractions[x.Quality]
		if !ok {
			return nil, errors.New("i5: missing promotion restoration fraction")
		}
		num := new(big.Int).Mul(big.NewInt(x.RawFumo), big.NewInt(f.Numerator))
		term := new(big.Rat).SetFrac(num, big.NewInt(f.Denominator))
		total.Add(total, term)
	}
	if total.Sign() <= 0 {
		return nil, nil
	}
	floor := new(big.Int).Quo(total.Num(), total.Denom())
	if !floor.IsInt64() || floor.Sign() < 0 {
		return nil, errors.New("i5: promotion restoration value overflow")
	}
	remaining := floor.Int64()
	out := make([]grant.Line, 0, len(policy.Denominations))
	for _, d := range policy.Denominations {
		count := remaining / d.Value
		if count <= 0 {
			continue
		}
		out = append(out, grant.Line{Kind: grant.StackItem, ItemID: int64(d.ItemID), Amount: count})
		remaining %= d.Value
	}
	return out, nil
}
