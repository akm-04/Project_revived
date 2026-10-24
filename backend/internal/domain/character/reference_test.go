package character

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
)

func TestHeroRefIsOwnerScopedAndCarriesNoMutableState(t *testing.T) {
	ref := HeroRef{PlayerID: identity.PlayerID(7), PartnerID: 9}
	if err := ref.Validate(); err != nil {
		t.Fatal(err)
	}
	for _, bad := range []HeroRef{{}, {PlayerID: 7}, {PartnerID: 9}, {PlayerID: 7, PartnerID: -1}} {
		if err := bad.Validate(); err == nil {
			t.Fatalf("invalid HeroRef accepted: %+v", bad)
		}
	}
	h := Hero{RawSkills: NewHeroRawSkillSeed(), PlayerID: 7, PartnerID: 9}
	if got := h.Ref(); got != ref {
		t.Fatalf("Hero.Ref()=%+v want %+v", got, ref)
	}
}
