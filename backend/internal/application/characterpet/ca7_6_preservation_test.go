package characterpet

import (
	"context"
	"testing"

	"gxb.local/backend/v2/internal/domain/character"
)

func TestCA76PetProgressionMutationPreservesAppearanceStyle(t *testing.T) {
	svc, st, _, _, _ := progressionFixture(t)
	p := st.byID[1]
	p.ActiveStyle = 50001376
	st.byID[1] = p
	before := st.byID[1]
	if _, err := svc.Evolve(context.Background(), caActor(t), 1, caOp(t, "78787878-7878-4878-8878-787878787878", 4000)); err != nil {
		t.Fatal(err)
	}
	after := st.byID[1]
	if after.ActiveStyle != before.ActiveStyle || after.OriginTableID != before.OriginTableID || after.CreationContentRevision != before.CreationContentRevision {
		t.Fatalf("CA3 progression rewrote CA7 Pet appearance identity/style before=%+v after=%+v", before, after)
	}
	if after.StateVersion != before.StateVersion+1 || after.Star == before.Star {
		t.Fatalf("expected real Pet progression mutation before=%+v after=%+v", before, after)
	}
}

func TestCA76PetEquipmentMutationPreservesAppearanceStyle(t *testing.T) {
	svc, st, _, _, _ := petEquipmentFixture(t, character.PetEquipmentOrdinary, false)
	p := st.byID[1]
	p.ActiveStyle = 50001376
	st.byID[1] = p
	before := st.byID[1]
	if _, err := svc.EquipItem(context.Background(), caActor(t), 1, 1, caOp(t, "79797979-7979-4979-8979-797979797979", 4001)); err != nil {
		t.Fatal(err)
	}
	after := st.byID[1]
	if after.ActiveStyle != before.ActiveStyle || after.OriginTableID != before.OriginTableID || after.CreationContentRevision != before.CreationContentRevision {
		t.Fatalf("CA4 equipment rewrote CA7 Pet appearance identity/style before=%+v after=%+v", before, after)
	}
	if after.StateVersion != before.StateVersion+1 || after.Equipment[0] != 1 {
		t.Fatalf("expected real Pet equipment mutation before=%+v after=%+v", before, after)
	}
}
