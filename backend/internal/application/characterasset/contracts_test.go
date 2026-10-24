package characterasset

import "testing"

func TestPromotionRestorationSemanticIdentityIgnoresPolicyRevision(t *testing.T) {
	a, err := HeroPromotionRestorationSource(77, 2, 3, "content-revision-a")
	if err != nil {
		t.Fatal(err)
	}
	b, err := HeroPromotionRestorationSource(77, 2, 3, "content-revision-b")
	if err != nil {
		t.Fatal(err)
	}
	if a.SemanticKey() != b.SemanticKey() {
		t.Fatalf("policy/content revision manufactured a second entitlement: %s != %s", a.SemanticKey(), b.SemanticKey())
	}
	if a.LegacySemanticKeyV1() == b.LegacySemanticKeyV1() {
		t.Fatal("legacy compatibility key unexpectedly ignored policy version")
	}
}

func TestHeroAndPetPromotionRestorationIdentitiesAreFamilyQualified(t *testing.T) {
	h, err := HeroPromotionRestorationSource(77, 2, 3, "p")
	if err != nil {
		t.Fatal(err)
	}
	p, err := PetPromotionRestorationSource(77, 2, 3, "p")
	if err != nil {
		t.Fatal(err)
	}
	if h.SemanticKey() == p.SemanticKey() {
		t.Fatal("Hero and Pet restoration identities collapsed")
	}
}
