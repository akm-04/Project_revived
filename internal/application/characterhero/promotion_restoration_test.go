package characterhero

import (
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
)

func testRestorationPolicy() character.HeroPromotionRestorationPolicy {
	return character.HeroPromotionRestorationPolicy{
		Fractions: []character.HeroPromotionRestorationFraction{
			{Quality: 2, Numerator: 1, Denominator: 1},
			{Quality: 3, Numerator: 3, Denominator: 8},
			{Quality: 4, Numerator: 9, Denominator: 50},
			{Quality: 5, Numerator: 9, Denominator: 100},
			{Quality: 6, Numerator: 9, Denominator: 200},
		},
		Denominations: []character.HeroPromotionRestorationDenomination{
			{ItemID: 50001007, Ordinal: 0, Value: 200},
			{ItemID: 50001006, Ordinal: 1, Value: 60},
			{ItemID: 50001003, Ordinal: 2, Value: 10},
		},
	}
}

func TestPromotionRestorationAggregateFloorThenGreedySourceOrder(t *testing.T) {
	// 200*q2 + 200*q3 = 200 + 75 = 275 => 200 + 60 + 10,
	// residual 5 is discarded only after aggregate-floor decomposition.
	got, err := planBasePromotionRestoration([]heroPromotionRestorationInput{{RawFumo: 200, Quality: 2}, {RawFumo: 200, Quality: 3}}, testRestorationPolicy())
	if err != nil {
		t.Fatal(err)
	}
	want := []grant.Line{
		{Kind: grant.StackItem, ItemID: 50001007, Amount: 1},
		{Kind: grant.StackItem, ItemID: 50001006, Amount: 1},
		{Kind: grant.StackItem, ItemID: 50001003, Amount: 1},
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got=%+v want=%+v", got, want)
	}
}

func TestPromotionRestorationFloorsAggregateOnceNotPerSlot(t *testing.T) {
	// q3 values 79 and 81 yield 29.625 + 30.375 = 60 exactly.
	// Flooring per slot would produce only 59, while the accepted aggregate
	// policy produces one 60-denomination refund.
	got, err := planBasePromotionRestoration([]heroPromotionRestorationInput{{RawFumo: 79, Quality: 3}, {RawFumo: 81, Quality: 3}}, testRestorationPolicy())
	if err != nil {
		t.Fatal(err)
	}
	want := []grant.Line{{Kind: grant.StackItem, ItemID: 50001006, Amount: 1}}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got=%+v want=%+v", got, want)
	}
}

func TestPromotionRestorationBelowSmallestDenominationProducesNoGrant(t *testing.T) {
	got, err := planBasePromotionRestoration([]heroPromotionRestorationInput{{RawFumo: 100, Quality: 6}}, testRestorationPolicy())
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 0 {
		t.Fatalf("unexpected lines=%+v", got)
	}
}
