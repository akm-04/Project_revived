package characterasset

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type heroBaseErrFake struct{ err error }

func (f heroBaseErrFake) HeroBaseObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64) (HeroBaseObservation, error) {
	return HeroBaseObservation{}, f.err
}

type heroBaseByIDFake struct{ byID map[int64]HeroBaseObservation }

func (f heroBaseByIDFake) HeroBaseObservationTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID, partnerID int64) (HeroBaseObservation, error) {
	v, ok := f.byID[partnerID]
	if !ok {
		return HeroBaseObservation{}, errors.New("missing Hero fixture")
	}
	return v, nil
}

type petBaseByIDFake struct{ byID map[int64]PetBaseObservation }

func (f petBaseByIDFake) PetBaseObservationTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID, petID int64) (PetBaseObservation, error) {
	v, ok := f.byID[petID]
	if !ok {
		return PetBaseObservation{}, errors.New("missing Pet fixture")
	}
	return v, nil
}

func TestPublicShowcaseHeroAndPetSuccess(t *testing.T) {
	scope := ca83CoherentScope(t)

	hb, href := heroCompositeFixture(t)
	hr := PublicShowcaseCharacterReader{OwnerComposite: &hb}
	h, err := hr.HeroTx(context.Background(), scope, href)
	if err != nil {
		t.Fatal(err)
	}
	if h.Origin != ActorOriginOwned || h.Base.Ref != href || h.Equipment.Disposition != ProviderQualifiedActive || h.Practice.Disposition != ProviderQualifiedActive || h.Appearance.Disposition != ProviderQualifiedActive {
		t.Fatalf("Hero facet=%+v", h)
	}
	if h.HeroSkillsDisposition != ProviderUnavailableUnqualified {
		t.Fatalf("Hero skills disposition=%q", h.HeroSkillsDisposition)
	}

	pb, pref := petCompositeFixture(t)
	base := pb.PetBase.(petBaseFake)
	base.v.Skills = character.PetSkillLevels{1, 2, 3, 4, 5}
	base.v.Birthday = 12345
	base.v.IsShow = true
	pb.PetBase = base
	pr := PublicShowcaseCharacterReader{OwnerComposite: &pb}
	p, err := pr.PetTx(context.Background(), scope, pref)
	if err != nil {
		t.Fatal(err)
	}
	if p.Origin != ActorOriginOwned || p.Base.Ref != pref || p.Base.Skills != base.v.Skills || p.Base.Birthday != 12345 || !p.Base.IsShow {
		t.Fatalf("Pet facet=%+v", p)
	}
}

func TestPublicShowcaseFailsClosedInvalidRequests(t *testing.T) {
	ctx := context.Background()
	scope := ca83CoherentScope(t)
	b, href := heroCompositeFixture(t)
	r := PublicShowcaseCharacterReader{OwnerComposite: &b}

	if _, err := (PublicShowcaseCharacterReader{}).HeroTx(ctx, scope, href); !errors.Is(err, ErrPublicShowcaseCharacterRequest) {
		t.Fatalf("nil dependency err=%v", err)
	}
	if _, err := r.HeroTx(ctx, CoherentReadScope{}, href); !errors.Is(err, ErrInvalidCoherentReadScope) {
		t.Fatalf("invalid scope err=%v", err)
	}
	if _, err := r.HeroTx(ctx, scope, character.HeroRef{}); err == nil {
		t.Fatal("invalid Hero ref accepted")
	}

	pb, pref := petCompositeFixture(t)
	pr := PublicShowcaseCharacterReader{OwnerComposite: &pb}
	if _, err := (PublicShowcaseCharacterReader{}).PetTx(ctx, scope, pref); !errors.Is(err, ErrPublicShowcaseCharacterRequest) {
		t.Fatalf("nil Pet dependency err=%v", err)
	}
	if _, err := pr.PetTx(ctx, CoherentReadScope{}, pref); !errors.Is(err, ErrInvalidCoherentReadScope) {
		t.Fatalf("invalid Pet scope err=%v", err)
	}
	if _, err := pr.PetTx(ctx, scope, character.PetRef{}); err == nil {
		t.Fatal("invalid Pet ref accepted")
	}
}

func TestPublicShowcasePropagatesBaseAndCoherenceFailures(t *testing.T) {
	ctx := context.Background()
	scope := ca83CoherentScope(t)
	b, ref := heroCompositeFixture(t)
	r := PublicShowcaseCharacterReader{OwnerComposite: &b}

	hard := errors.New("base storage failure")
	b.HeroBase = heroBaseErrFake{err: hard}
	if _, err := r.HeroTx(ctx, scope, ref); !errors.Is(err, hard) {
		t.Fatalf("base err=%v", err)
	}

	b, ref = heroCompositeFixture(t)
	r.OwnerComposite = &b
	base := b.HeroBase.(heroBaseFake)
	base.v.Ref.PartnerID++
	b.HeroBase = base
	if _, err := r.HeroTx(ctx, scope, ref); !errors.Is(err, ErrOwnedCompositeCoherence) {
		t.Fatalf("reference mismatch err=%v", err)
	}

	b, ref = heroCompositeFixture(t)
	r.OwnerComposite = &b
	eq := b.HeroEquipment.(heroEquipFake)
	eq.v.Value.StateVersion++
	b.HeroEquipment = eq
	if _, err := r.HeroTx(ctx, scope, ref); !errors.Is(err, ErrOwnedCompositeCoherence) {
		t.Fatalf("provider coherence err=%v", err)
	}
}

func TestPublicShowcasePreservesOptionalProviderDispositionAndErrors(t *testing.T) {
	ctx := context.Background()
	scope := ca83CoherentScope(t)

	b, ref := heroCompositeFixture(t)
	b.HeroEquipment, b.HeroPractice, b.HeroAppearance = nil, nil, nil
	got, err := (PublicShowcaseCharacterReader{OwnerComposite: &b}).HeroTx(ctx, scope, ref)
	if err != nil {
		t.Fatal(err)
	}
	if got.Equipment.Disposition != ProviderUnavailableUnqualified || got.Practice.Disposition != ProviderUnavailableUnqualified || got.Appearance.Disposition != ProviderUnavailableUnqualified {
		t.Fatalf("unqualified dispositions=%+v", got)
	}

	b, ref = heroCompositeFixture(t)
	b.HeroEquipment = heroEquipFake{v: ProviderObservation[RawEquipmentState]{Disposition: ProviderExplicitlyInactiveOrAbsent}}
	b.HeroPractice = heroPracticeFake{v: ProviderObservation[PracticeContribution]{Disposition: ProviderExplicitlyInactiveOrAbsent}}
	b.HeroAppearance = heroAppearanceFake{v: ProviderObservation[HeroAppearanceContribution]{Disposition: ProviderExplicitlyInactiveOrAbsent}}
	got, err = (PublicShowcaseCharacterReader{OwnerComposite: &b}).HeroTx(ctx, scope, ref)
	if err != nil {
		t.Fatal(err)
	}
	if got.Equipment.Disposition != ProviderExplicitlyInactiveOrAbsent || got.Practice.Disposition != ProviderExplicitlyInactiveOrAbsent || got.Appearance.Disposition != ProviderExplicitlyInactiveOrAbsent {
		t.Fatalf("inactive dispositions=%+v", got)
	}

	b, ref = heroCompositeFixture(t)
	hard := errors.New("equipment read failure")
	b.HeroEquipment = heroEquipFake{err: hard}
	if _, err := (PublicShowcaseCharacterReader{OwnerComposite: &b}).HeroTx(ctx, scope, ref); !errors.Is(err, hard) {
		t.Fatalf("hard provider err=%v", err)
	}

	b, ref = heroCompositeFixture(t)
	b.HeroEquipment = heroEquipFake{v: ProviderObservation[RawEquipmentState]{Disposition: ProviderRequiredButUnavailable}}
	if _, err := (PublicShowcaseCharacterReader{OwnerComposite: &b}).HeroTx(ctx, scope, ref); err == nil {
		t.Fatal("consumer requiredness accepted")
	}
}

func TestPublicShowcasePersistentIdentityDoesNotCollapseToTableID(t *testing.T) {
	scope := ca83CoherentScope(t)
	ctx := context.Background()

	h1 := character.HeroRef{PlayerID: 1, PartnerID: 71}
	h2 := character.HeroRef{PlayerID: 1, PartnerID: 72}
	hb := OwnedCompositeBuilder{HeroBase: heroBaseByIDFake{byID: map[int64]HeroBaseObservation{
		71: {Ref: h1, TableID: 11001, OriginTableID: 11001, Kind: character.NormalHero, Star: 2, Level: 3, Color: 5, CreationContentRevision: ca83rev, StateVersion: 9},
		72: {Ref: h2, TableID: 11001, OriginTableID: 11001, Kind: character.NormalHero, Star: 2, Level: 3, Color: 5, CreationContentRevision: ca83rev, StateVersion: 9},
	}}}
	hr := PublicShowcaseCharacterReader{OwnerComposite: &hb}
	got1, err := hr.HeroTx(ctx, scope, h1)
	if err != nil {
		t.Fatal(err)
	}
	got2, err := hr.HeroTx(ctx, scope, h2)
	if err != nil {
		t.Fatal(err)
	}
	if got1.Base.TableID != got2.Base.TableID || got1.Base.Ref == got2.Base.Ref || got1.Base.Ref != h1 || got2.Base.Ref != h2 {
		t.Fatalf("Hero identity collapsed: first=%+v second=%+v", got1.Base, got2.Base)
	}

	p1 := character.PetRef{PlayerID: 1, PetID: 81}
	p2 := character.PetRef{PlayerID: 1, PetID: 82}
	pb := OwnedCompositeBuilder{PetBase: petBaseByIDFake{byID: map[int64]PetBaseObservation{
		81: {Ref: p1, TableID: 21001, OriginTableID: 21001, Star: 2, Level: 3, Color: 5, Skills: character.DefaultPetSkillLevels(), CreationContentRevision: ca83rev, StateVersion: 12},
		82: {Ref: p2, TableID: 21001, OriginTableID: 21001, Star: 2, Level: 3, Color: 5, Skills: character.DefaultPetSkillLevels(), CreationContentRevision: ca83rev, StateVersion: 12},
	}}}
	pr := PublicShowcaseCharacterReader{OwnerComposite: &pb}
	pet1, err := pr.PetTx(ctx, scope, p1)
	if err != nil {
		t.Fatal(err)
	}
	pet2, err := pr.PetTx(ctx, scope, p2)
	if err != nil {
		t.Fatal(err)
	}
	if pet1.Base.TableID != pet2.Base.TableID || pet1.Base.Ref == pet2.Base.Ref || pet1.Base.Ref != p1 || pet2.Base.Ref != p2 {
		t.Fatalf("Pet identity collapsed: first=%+v second=%+v", pet1.Base, pet2.Base)
	}
}

func TestPublicShowcaseReturnedNestedStateIsDefensivelyCopied(t *testing.T) {
	scope := ca83CoherentScope(t)
	b, ref := heroCompositeFixture(t)

	pr := b.HeroPractice.(heroPracticeFake)
	pr.v.Value.Contributions = []PracticeContributionEntry{{AttrType: 1, Value: 10}}
	b.HeroPractice = pr
	ap := b.HeroAppearance.(heroAppearanceFake)
	expires := time.Unix(100, 0).UTC()
	ap.v.Value.Appearance.Skins = []QualifiedSkinEntitlement{{ModelID: 2, ExpiresAt: &expires}}
	ap.v.Value.Appearance.LIVE = []QualifiedLIVEState{{ModelID: 3}}
	b.HeroAppearance = ap

	r := PublicShowcaseCharacterReader{OwnerComposite: &b}
	first, err := r.HeroTx(context.Background(), scope, ref)
	if err != nil {
		t.Fatal(err)
	}
	first.Equipment.Value.Slots[0].TemplateID = 999
	first.Practice.Value.Contributions[0].Value = 999
	first.Appearance.Value.Appearance.Skins[0].ModelID = 999
	*first.Appearance.Value.Appearance.Skins[0].ExpiresAt = time.Unix(999, 0).UTC()
	first.Appearance.Value.Appearance.LIVE[0].ModelID = 999

	fresh, err := r.HeroTx(context.Background(), scope, ref)
	if err != nil {
		t.Fatal(err)
	}
	if fresh.Equipment.Value.Slots[0].TemplateID == 999 || fresh.Practice.Value.Contributions[0].Value == 999 || fresh.Appearance.Value.Appearance.Skins[0].ModelID == 999 || fresh.Appearance.Value.Appearance.Skins[0].ExpiresAt.Unix() == 999 || fresh.Appearance.Value.Appearance.LIVE[0].ModelID == 999 {
		t.Fatalf("fresh read aliased prior facet mutation: %+v", fresh)
	}
	origEq := b.HeroEquipment.(heroEquipFake).v.Value.Slots[0].TemplateID
	origPractice := b.HeroPractice.(heroPracticeFake).v.Value.Contributions[0].Value
	origAppearance := b.HeroAppearance.(heroAppearanceFake).v.Value.Appearance
	if origEq == 999 || origPractice == 999 || origAppearance.Skins[0].ModelID == 999 || origAppearance.Skins[0].ExpiresAt.Unix() == 999 || origAppearance.LIVE[0].ModelID == 999 {
		t.Fatal("provider fixture aliased returned facet")
	}
}
