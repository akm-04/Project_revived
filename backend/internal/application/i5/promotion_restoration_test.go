package i5

import (
	"math"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
)

func ca44bRestorationPolicy() character.PromotionRestorationPolicy {
	return character.PromotionRestorationPolicy{
		Fractions: []character.PromotionRestorationFraction{
			{Quality: 2, Numerator: 1, Denominator: 1},
			{Quality: 3, Numerator: 3, Denominator: 8},
			{Quality: 4, Numerator: 9, Denominator: 50},
			{Quality: 5, Numerator: 9, Denominator: 100},
			{Quality: 6, Numerator: 9, Denominator: 200},
		},
		Denominations: []character.PromotionRestorationDenomination{
			{ItemID: 50001007, Ordinal: 0, Value: 200},
			{ItemID: 50001006, Ordinal: 1, Value: 60},
			{ItemID: 50001003, Ordinal: 2, Value: 10},
		},
	}
}

func TestPetPromotionRestorationPolicyIdentityFrozen(t *testing.T) {
	const want = "PET_FUMO_RESTORE_V1_AGGREGATE_FLOOR_GREEDY_SOURCE_ORDER"
	if PetPromotionRestorationPolicyVersion != want {
		t.Fatalf("policy id=%q want=%q", PetPromotionRestorationPolicyVersion, want)
	}
}

func TestPromotionRestorationCA44BNumericVectors(t *testing.T) {
	policy := ca44bRestorationPolicy()
	tests := []struct {
		name string
		in   []PromotionRestorationInput
		want []grant.Line
	}{
		{
			name: "aggregate mixed qualities then greedy 200-60-10",
			in:   []PromotionRestorationInput{{RawFumo: 200, Quality: 2}, {RawFumo: 200, Quality: 3}},
			want: []grant.Line{{Kind: grant.StackItem, ItemID: 50001007, Amount: 1}, {Kind: grant.StackItem, ItemID: 50001006, Amount: 1}, {Kind: grant.StackItem, ItemID: 50001003, Amount: 1}},
		},
		{
			name: "floor once after aggregation not per slot",
			in:   []PromotionRestorationInput{{RawFumo: 79, Quality: 3}, {RawFumo: 81, Quality: 3}},
			want: []grant.Line{{Kind: grant.StackItem, ItemID: 50001006, Amount: 1}},
		},
		{
			name: "residual below ten discarded",
			in:   []PromotionRestorationInput{{RawFumo: 100, Quality: 6}},
			want: []grant.Line{},
		},
		{
			name: "source denomination order remains greedy",
			in:   []PromotionRestorationInput{{RawFumo: 320, Quality: 2}},
			want: []grant.Line{{Kind: grant.StackItem, ItemID: 50001007, Amount: 1}, {Kind: grant.StackItem, ItemID: 50001006, Amount: 2}},
		},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got, err := PlanPromotionRestoration(tc.in, policy)
			if err != nil {
				t.Fatal(err)
			}
			if !reflect.DeepEqual(got, tc.want) {
				t.Fatalf("got=%+v want=%+v", got, tc.want)
			}
		})
	}
}

func TestPromotionRestorationCA44BFailsClosedWithoutQ1Coefficient(t *testing.T) {
	if _, err := PlanPromotionRestoration([]PromotionRestorationInput{{RawFumo: 1, Quality: 1}}, ca44bRestorationPolicy()); err == nil {
		t.Fatal("q1 nonzero restoration input accepted without a source coefficient")
	}
}

func TestPromotionRestorationCA44BRejectsAggregateOverflow(t *testing.T) {
	_, err := PlanPromotionRestoration([]PromotionRestorationInput{{RawFumo: math.MaxInt64, Quality: 2}, {RawFumo: math.MaxInt64, Quality: 2}}, ca44bRestorationPolicy())
	if err == nil {
		t.Fatal("aggregate overflow accepted")
	}
}
