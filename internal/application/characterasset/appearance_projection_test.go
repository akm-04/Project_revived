package characterasset

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
)

type appearanceReadFake struct {
	skins  map[int64]AppearanceSkinDefinition
	lives  map[int64]AppearanceLIVEDefinition
	styles map[int64]AppearancePetStyleDefinition
}

func (f appearanceReadFake) AppearanceSkin(_ context.Context, _ string, id int64) (AppearanceSkinDefinition, bool, error) {
	v, ok := f.skins[id]
	return v, ok, nil
}
func (f appearanceReadFake) AppearanceLIVE(_ context.Context, _ string, id int64) (AppearanceLIVEDefinition, bool, error) {
	v, ok := f.lives[id]
	return v, ok, nil
}
func (f appearanceReadFake) AppearancePetStyle(_ context.Context, _ string, id int64) (AppearancePetStyleDefinition, bool, error) {
	v, ok := f.styles[id]
	return v, ok, nil
}

func appearanceHero(kind character.HeroKind) character.Hero {
	now := time.Unix(100, 0).UTC()
	return character.Hero{
		PlayerID: identity.PlayerID(7), PartnerID: 9, TableID: 10001001, OriginTableID: 10001001, Kind: kind,
		Star: 1, Level: 1, Color: 1, CurrentSkinID: 40001001, IllusionSkinID: 40001002,
		CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		StateVersion:            5, CreatedAt: now, UpdatedAt: now,
	}
}

func TestTimedEntitlementEqualityAndStaleSelectorQualification(t *testing.T) {
	deadline := time.Unix(200, 0).UTC()
	h := appearanceHero(character.NormalHero)
	content := appearanceReadFake{skins: map[int64]AppearanceSkinDefinition{
		40001001: {ModelID: 40001001, HeroOriginTableID: h.OriginTableID},
		40001002: {ModelID: 40001002, HeroOriginTableID: h.OriginTableID},
	}}
	ents := []character.HeroSkinEntitlement{
		{PlayerID: h.PlayerID, PartnerID: h.PartnerID, ModelID: 40001001, ExpiresAt: &deadline},
		{PlayerID: h.PlayerID, PartnerID: h.PartnerID, ModelID: 40001002, ExpiresAt: &deadline},
	}

	atDeadline, err := BuildEffectiveHeroAppearance(context.Background(), h.CreationContentRevision, h, ents, nil, deadline, content)
	if err != nil {
		t.Fatal(err)
	}
	if atDeadline.CurrentSkinID != 40001001 || atDeadline.IllusionSkinID != 40001002 || len(atDeadline.Skins) != 2 {
		t.Fatalf("deadline equality not valid: %+v", atDeadline)
	}

	after, err := BuildEffectiveHeroAppearance(context.Background(), h.CreationContentRevision, h, ents, nil, deadline.Add(time.Second), content)
	if err != nil {
		t.Fatal(err)
	}
	if after.CurrentSkinID != 0 || after.IllusionSkinID != character.DefaultIllusionSkinID || len(after.Skins) != 0 {
		t.Fatalf("expired selectors were not fail-closed: %+v", after)
	}
}

func TestHeroAppearanceFiltersWrongFamilyAndSortsLIVE(t *testing.T) {
	h := appearanceHero(character.NormalHero)
	h.CurrentSkinID = 0
	h.IllusionSkinID = character.DefaultIllusionSkinID
	content := appearanceReadFake{
		skins: map[int64]AppearanceSkinDefinition{
			40001001: {ModelID: 40001001, HeroOriginTableID: h.OriginTableID},
			40009999: {ModelID: 40009999, HeroOriginTableID: 10009999},
		},
		lives: map[int64]AppearanceLIVEDefinition{
			40001003: {ModelID: 40001003, HeroOriginTableID: h.OriginTableID, CrystalCost: 10, ActivationItemID: 50005171, ActivationItemCount: 2},
			40001002: {ModelID: 40001002, HeroOriginTableID: h.OriginTableID, CrystalCost: 10, ActivationItemID: 50005171, ActivationItemCount: 2},
			40009999: {ModelID: 40009999, HeroOriginTableID: 10009999, CrystalCost: 10, ActivationItemID: 50005171, ActivationItemCount: 2},
		},
	}
	out, err := BuildEffectiveHeroAppearance(context.Background(), h.CreationContentRevision, h,
		[]character.HeroSkinEntitlement{{PlayerID: h.PlayerID, PartnerID: h.PartnerID, ModelID: 40009999}, {PlayerID: h.PlayerID, PartnerID: h.PartnerID, ModelID: 40001001}},
		[]character.HeroLIVEEntitlement{{PlayerID: h.PlayerID, PartnerID: h.PartnerID, ModelID: 40001003, IsShow: false}, {PlayerID: h.PlayerID, PartnerID: h.PartnerID, ModelID: 40001002, IsShow: true}, {PlayerID: h.PlayerID, PartnerID: h.PartnerID, ModelID: 40009999, IsShow: true}},
		time.Unix(150, 0).UTC(), content)
	if err != nil {
		t.Fatal(err)
	}
	if len(out.Skins) != 1 || out.Skins[0].ModelID != 40001001 {
		t.Fatalf("skin qualification=%+v", out.Skins)
	}
	if len(out.LIVE) != 2 || out.LIVE[0].ModelID != 40001002 || !out.LIVE[0].IsShow || out.LIVE[1].ModelID != 40001003 || out.LIVE[1].IsShow {
		t.Fatalf("LIVE normalization=%+v", out.LIVE)
	}

	h.Kind = character.SuperHero
	out, err = BuildEffectiveHeroAppearance(context.Background(), h.CreationContentRevision, h, nil,
		[]character.HeroLIVEEntitlement{{PlayerID: h.PlayerID, PartnerID: h.PartnerID, ModelID: 40001002, IsShow: true}},
		time.Unix(150, 0).UTC(), content)
	if err != nil {
		t.Fatal(err)
	}
	if len(out.LIVE) != 0 {
		t.Fatalf("Super Hero received paid LIVE state: %+v", out.LIVE)
	}
}

func TestPetAppearanceQualifiesOriginAndActiveOwnership(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	p := character.Pet{PlayerID: 7, PetID: 3, TableID: 10030001, OriginTableID: 10030001, Star: 1, Level: 1, Color: 1,
		Skills: character.DefaultPetSkillLevels(), ActiveStyle: 50030002,
		CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 4, CreatedAt: now, UpdatedAt: now}
	content := appearanceReadFake{styles: map[int64]AppearancePetStyleDefinition{
		50030001: {StyleItemID: 50030001, PetOriginTableID: p.OriginTableID},
		50030002: {StyleItemID: 50030002, PetOriginTableID: 10039999},
	}}
	out, err := BuildEffectivePetAppearance(context.Background(), p.CreationContentRevision, p,
		[]character.PetStyleEntitlement{{PlayerID: p.PlayerID, PetID: p.PetID, StyleItemID: 50030002}, {PlayerID: p.PlayerID, PetID: p.PetID, StyleItemID: 50030001}},
		now, content)
	if err != nil {
		t.Fatal(err)
	}
	if out.ActiveStyle != 0 || len(out.OwnedStyles) != 1 || out.OwnedStyles[0] != 50030001 {
		t.Fatalf("Pet appearance qualification=%+v", out)
	}
}

func TestPaidLIVERemainsEffectiveAcrossOrdinaryTimedSkinExpiry(t *testing.T) {
	deadline := time.Unix(200, 0).UTC()
	h := appearanceHero(character.NormalHero)
	h.CurrentSkinID = 40001001
	h.IllusionSkinID = character.DefaultIllusionSkinID
	content := appearanceReadFake{
		skins: map[int64]AppearanceSkinDefinition{
			40001001: {ModelID: 40001001, HeroOriginTableID: h.OriginTableID},
		},
		lives: map[int64]AppearanceLIVEDefinition{
			40001002: {ModelID: 40001002, HeroOriginTableID: h.OriginTableID, CrystalCost: 10, ActivationItemID: 50005171, ActivationItemCount: 2},
		},
	}
	skins := []character.HeroSkinEntitlement{{PlayerID: h.PlayerID, PartnerID: h.PartnerID, ModelID: 40001001, ExpiresAt: &deadline}}
	lives := []character.HeroLIVEEntitlement{{PlayerID: h.PlayerID, PartnerID: h.PartnerID, ModelID: 40001002, IsShow: true}}
	atDeadline, err := BuildEffectiveHeroAppearance(context.Background(), h.CreationContentRevision, h, skins, lives, deadline, content)
	if err != nil {
		t.Fatal(err)
	}
	after, err := BuildEffectiveHeroAppearance(context.Background(), h.CreationContentRevision, h, skins, lives, deadline.Add(time.Second), content)
	if err != nil {
		t.Fatal(err)
	}
	if atDeadline.CurrentSkinID != 40001001 || len(atDeadline.LIVE) != 1 || !atDeadline.LIVE[0].IsShow {
		t.Fatalf("pre-expiry appearance=%+v", atDeadline)
	}
	if after.CurrentSkinID != 0 || len(after.Skins) != 0 || len(after.LIVE) != 1 || after.LIVE[0].ModelID != 40001002 || !after.LIVE[0].IsShow {
		t.Fatalf("paid LIVE did not survive ordinary skin expiry: %+v", after)
	}
}
