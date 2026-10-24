package character

import (
	"gxb.local/backend/v2/internal/domain/identity"
	"testing"
	"time"
)

func TestHeroAndRootValidation(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	r := HeroRoot{PlayerID: 1, NextPartnerID: 1, SortType: 8191, StateVersion: 1, CreatedAt: now, UpdatedAt: now}
	if err := r.Validate(); err != nil {
		t.Fatal(err)
	}
	r.SortType = 8192
	if err := r.Validate(); err == nil {
		t.Fatal("accepted invalid sort")
	}
	h := Hero{RawSkills: NewHeroRawSkillSeed(), PlayerID: identity.PlayerID(1), PartnerID: 2, TableID: 10001001, OriginTableID: 10001001, Star: 1, Level: 1, Color: 1, CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 1, CreatedAt: now, UpdatedAt: now}
	if err := h.ValidatePersistent(); err != nil {
		t.Fatal(err)
	}
	if err := h.Validate(); err == nil {
		t.Fatal("accepted unresolved Hero kind")
	}
	h.Kind = NormalHero
	if err := h.Validate(); err != nil {
		t.Fatal(err)
	}
	h.Star = 9
	if err := h.ValidatePersistent(); err == nil {
		t.Fatal("accepted star above effective client ceiling")
	}
}
