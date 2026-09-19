package contentstore

import (
	"context"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/domain/character"
)

func TestHeroFumoTargetTxDecodesSparseExactDecimalStages(t *testing.T) {
	revision := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	q := &recording{values: []any{`[20,40,100]`, int64(160), int64(150), `[{"1":"1.5"},{"1":"2","7":"0.25"},{"7":"3"}]`}}
	got, err := (Store{}).HeroFumoTargetTx(context.Background(), q, revision, character.EquipmentTemplateID(20001001))
	if err != nil {
		t.Fatal(err)
	}
	if q.sql != contentqueries.ReadHeroFumoTarget || !reflect.DeepEqual(q.args, []any{revision, int64(20001001)}) {
		t.Fatalf("query=%q args=%v", q.sql, q.args)
	}
	if got.TotalCap != 160 || got.ManaPerFumo != 150 || len(got.StageDeltaByAttr) != 3 || got.StageDeltaByAttr[0][1] != "1.5" || got.StageDeltaByAttr[1][7] != "0.25" || got.StageDeltaByAttr[2][7] != "3" {
		t.Fatalf("target=%+v", got)
	}
}

func TestHeroFumoMaterialTxEnforcesHeroPolicy(t *testing.T) {
	revision := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	q := &recording{values: []any{int64(5), int64(99)}}
	got, err := (Store{}).HeroFumoMaterialTx(context.Background(), q, revision, character.EquipmentTemplateID(30001))
	if err != nil {
		t.Fatal(err)
	}
	if got.ItemType != 5 || got.Moneng != 99 || q.sql != contentqueries.ReadHeroFumoMaterial {
		t.Fatalf("material=%+v query=%q", got, q.sql)
	}
	q = &recording{values: []any{int64(8), int64(99)}}
	if _, err := (Store{}).HeroFumoMaterialTx(context.Background(), q, revision, character.EquipmentTemplateID(30001)); err == nil {
		t.Fatal("type-8 material accepted")
	}
}
