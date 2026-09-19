package contentstore

import (
	"context"
	"errors"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPetPromotionRestorationEligibilityUsesExactRevisionAndAllowsQ1(t *testing.T) {
	revision := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	for _, tc := range []struct {
		item    int64
		quality int64
	}{{80001001, 1}, {80001005, 6}} {
		q := &recording{values: []any{tc.quality}}
		got, err := (Store{}).PetPromotionRestorationEligibilityTx(context.Background(), q, revision, character.EquipmentTemplateID(tc.item))
		if err != nil {
			t.Fatal(err)
		}
		if int64(got.ItemID) != tc.item || got.SourceQuality != tc.quality {
			t.Fatalf("eligibility=%+v", got)
		}
		if q.sql != contentqueries.ReadPetPromotionRestorationEquipment || !reflect.DeepEqual(q.args, []any{revision, tc.item}) {
			t.Fatalf("lookup not exact revision/item: sql=%q args=%v", q.sql, q.args)
		}
	}
}

type promotionPolicyRow string

func (r promotionPolicyRow) Scan(dest ...any) error {
	if len(dest) != 1 {
		return errors.New("scan arity")
	}
	p, ok := dest[0].(*string)
	if !ok {
		return errors.New("scan type")
	}
	*p = string(r)
	return nil
}

type promotionPolicyQueryer struct {
	queries []string
	args    [][]any
}

func (q *promotionPolicyQueryer) QueryRow(_ context.Context, sql string, args ...any) tx.Row {
	q.queries = append(q.queries, sql)
	q.args = append(q.args, append([]any(nil), args...))
	switch sql {
	case contentqueries.ReadHeroPromotionRestorationFractions:
		return promotionPolicyRow(`[{"quality":2,"numerator":1,"denominator":1},{"quality":3,"numerator":3,"denominator":8},{"quality":4,"numerator":9,"denominator":50},{"quality":5,"numerator":9,"denominator":100},{"quality":6,"numerator":9,"denominator":200}]`)
	case contentqueries.ReadHeroPromotionRestorationDenominations:
		return promotionPolicyRow(`[{"item_id":50001007,"ordinal":0,"value":200},{"item_id":50001006,"ordinal":1,"value":60},{"item_id":50001003,"ordinal":2,"value":10}]`)
	default:
		return promotionPolicyRow("")
	}
}

func TestPromotionRestorationPolicyTxIsFamilyNeutralAndRevisionQualified(t *testing.T) {
	revision := "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
	q := &promotionPolicyQueryer{}
	got, err := (Store{}).PromotionRestorationPolicyTx(context.Background(), q, revision)
	if err != nil {
		t.Fatal(err)
	}
	if err := got.Validate(); err != nil || len(got.Fractions) != 5 || len(got.Denominations) != 3 {
		t.Fatalf("policy=%+v err=%v", got, err)
	}
	wantQueries := []string{contentqueries.ReadHeroPromotionRestorationFractions, contentqueries.ReadHeroPromotionRestorationDenominations}
	if !reflect.DeepEqual(q.queries, wantQueries) {
		t.Fatalf("queries=%v want=%v", q.queries, wantQueries)
	}
	if len(q.args) != 2 || !reflect.DeepEqual(q.args[0], []any{revision}) || !reflect.DeepEqual(q.args[1], []any{revision}) {
		t.Fatalf("args=%v", q.args)
	}
}
