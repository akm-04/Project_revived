package i5

import (
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
)

func mixedExchangePlan() grant.Plan {
	return grant.Plan{
		PlayerID: identity.PlayerID(1),
		Source:   grant.SourceIdentity{Domain: "items-energy", Operation: "box_open", BusinessKey: "op", Occurrence: "op", PolicyVersion: "p1"},
		Lines: []grant.Line{
			{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: 5},
			{Kind: grant.Temporal, ResourceKey: "energy", Amount: 50},
			{Kind: grant.StackItem, ItemID: 50000002, Amount: 3},
			{Kind: grant.PlayerExp, Amount: 10},
		},
	}
}

func TestItemsEnergyExchangeRestorationValidator(t *testing.T) {
	if err := validateItemsEnergyRestoration(mixedExchangePlan()); err != nil {
		t.Fatalf("mixed restoration refused: %v", err)
	}
	plan := mixedExchangePlan()
	plan.Lines = append(plan.Lines, grant.Line{Kind: grant.PartnerEntity, ItemID: 7001, Amount: 1})
	if err := validateItemsEnergyRestoration(plan); !errors.Is(err, ErrInvalidItemsEnergyExchange) {
		t.Fatalf("partner entity accepted: %v", err)
	}
	plan = mixedExchangePlan()
	plan.Lines = append(plan.Lines, grant.Line{Kind: grant.SpecializedDomain, Domain: "spirit", Amount: 1})
	if err := validateItemsEnergyRestoration(plan); !errors.Is(err, ErrInvalidItemsEnergyExchange) {
		t.Fatalf("specialized domain accepted: %v", err)
	}
}
