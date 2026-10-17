package playerdisplay

import (
	"gxb.local/backend/v2/internal/domain/player"
	"testing"
)

func TestHeroSourceBranchesRemainIndependent(t *testing.T) {
	v := player.Cosmetic{Family: "avatar", Type: 2, PartnerID: 100}
	hs := []HeroFacet{{PlayerID: 1, PartnerID: 1, TableID: 100, Color: 6, Star: 1, Version: 1}}
	if len(HeroEligibility(v, 2, hs, player.DisplayCatalog{})) != 0 {
		t.Fatal("belowpurple")
	}
	hs[0].Color = 7
	if len(HeroEligibility(v, 2, hs, player.DisplayCatalog{})) != 1 {
		t.Fatal("purple")
	}
	hs[0].Super = true
	if len(HeroEligibility(v, 2, hs, player.DisplayCatalog{})) != 1 {
		t.Fatal("source color branch independent of Super")
	}
	if len(HeroEligibility(v, 3, hs, player.DisplayCatalog{})) != 0 {
		t.Fatal("Super star1")
	}
	hs[0].Star = 2
	if len(HeroEligibility(v, 3, hs, player.DisplayCatalog{})) != 1 {
		t.Fatal("Super star2")
	}
	hs[0] = HeroFacet{PlayerID: 1, PartnerID: 1, TableID: 200, BeforeAwaken: 100, Awakened: true, Version: 2}
	if len(HeroEligibility(v, 2, hs, player.DisplayCatalog{})) != 1 {
		t.Fatal("beforeAwaken")
	}
	v.Type = 3
	v.PartnerID = 200
	if len(HeroEligibility(v, 4, hs, player.DisplayCatalog{})) != 1 {
		t.Fatal("currentawaken")
	}
	p := player.DisplayCatalog{Collection: []int64{1, 2, 3, 4}, Cosmetics: []player.Cosmetic{{Family: "avatar", ID: 1, PartnerID: 11}, {Family: "avatar", ID: 2, PartnerID: 12}, {Family: "avatar", ID: 3, PartnerID: 13}, {Family: "avatar", ID: 4, PartnerID: 14}}}
	v = player.Cosmetic{Family: "avatar", ID: 110006002, Type: 11}
	hs[0].Skins = []int64{11, 12, 13}
	if len(HeroEligibility(v, 5, hs, p)) != 0 {
		t.Fatal("incompletecollection")
	}
	hs[0].Skins = append(hs[0].Skins, 14)
	if len(HeroEligibility(v, 5, hs, p)) != 1 {
		t.Fatal("collection")
	}
	v.Type = 7
	v.PartnerID = 11
	if len(HeroEligibility(v, 5, hs, p)) != 1 {
		t.Fatal("ownedskin")
	}
}
