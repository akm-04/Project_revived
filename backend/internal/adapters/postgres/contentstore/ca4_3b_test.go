package contentstore

import (
	"context"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/domain/character"
)

func TestHeroPromotionRestorationEligibilityUsesExactRevisionAndItem(t *testing.T) {
	revision := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	q := &recording{values: []any{int64(5)}}
	got, err := (Store{}).HeroPromotionRestorationEligibilityTx(context.Background(), q, revision, character.EquipmentTemplateID(20001016))
	if err != nil {
		t.Fatal(err)
	}
	if got.ItemID != 20001016 || got.SourceQuality != 5 {
		t.Fatalf("eligibility=%+v", got)
	}
	if q.sql != contentqueries.ReadHeroPromotionRestorationEquipment || !reflect.DeepEqual(q.args, []any{revision, int64(20001016)}) {
		t.Fatalf("lookup not exact revision/item: sql=%q args=%v", q.sql, q.args)
	}
}

func TestHeroPromotionRestorationDomainPolicyValidation(t *testing.T) {
	policy := character.HeroPromotionRestorationPolicy{
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
	if err := policy.Validate(); err != nil {
		t.Fatal(err)
	}
	policy.Denominations[1].Value = 250
	if err := policy.Validate(); err == nil {
		t.Fatal("non-descending denomination policy accepted")
	}
}
