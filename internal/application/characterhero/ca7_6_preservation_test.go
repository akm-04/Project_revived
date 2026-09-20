package characterhero

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/receipt"
)

func TestCA76HeroProgressionMutationPreservesAppearanceSelectors(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 1, 0, now)
	h.CurrentSkinID = 40002006
	h.IllusionSkinID = character.DefaultIllusionSkinID
	ps := &progStore{heroes: map[int64]character.Hero{11: h}}
	pc := progContent{exp: map[int64]int64{50001001: 60}}
	pe := &progEconomy{playerLevel: 20, remaining: map[int64]int64{50001001: 3}}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	svc := progressionService(ps, pc, pe, rr)
	before := ps.heroes[11]
	if _, err := svc.UseExpItem(context.Background(), testActor(t), 11, 50001001, 1, testOp(t, "76767676-7676-4676-8676-767676767676")); err != nil {
		t.Fatal(err)
	}
	after := ps.heroes[11]
	if after.CurrentSkinID != before.CurrentSkinID || after.IllusionSkinID != before.IllusionSkinID || after.OriginTableID != before.OriginTableID || after.CreationContentRevision != before.CreationContentRevision {
		t.Fatalf("CA2 progression rewrote CA7 appearance identity/selectors before=%+v after=%+v", before, after)
	}
	if after.StateVersion != before.StateVersion+1 || after.Exp == before.Exp {
		t.Fatalf("expected real progression mutation before=%+v after=%+v", before, after)
	}
}

func TestCA76HeroEquipmentMutationPreservesAppearanceSelectors(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	h := heroAt(11, 1001, 1001, 3, 2, 25, now)
	h.CurrentSkinID = 40002006
	h.IllusionSkinID = character.DefaultIllusionSkinID
	svc, ps, _, _ := equipmentServiceFixture(t, h, nil)
	before := ps.heroes[11]
	if _, err := svc.EquipItem(context.Background(), testActor(t), 11, 1, testOp(t, "77777777-7777-4777-8777-777777777777")); err != nil {
		t.Fatal(err)
	}
	after := ps.heroes[11]
	if after.CurrentSkinID != before.CurrentSkinID || after.IllusionSkinID != before.IllusionSkinID || after.OriginTableID != before.OriginTableID || after.CreationContentRevision != before.CreationContentRevision {
		t.Fatalf("CA4 equipment rewrote CA7 appearance identity/selectors before=%+v after=%+v", before, after)
	}
	if after.StateVersion != before.StateVersion+1 || after.Equipment[0] != 1 {
		t.Fatalf("expected real equipment mutation before=%+v after=%+v", before, after)
	}
}
