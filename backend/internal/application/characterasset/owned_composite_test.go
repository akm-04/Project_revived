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

const ca83rev = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

type heroBaseFake struct{ v HeroBaseObservation }

func (f heroBaseFake) HeroBaseObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64) (HeroBaseObservation, error) {
	return f.v, nil
}

type petBaseFake struct{ v PetBaseObservation }

func (f petBaseFake) PetBaseObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64) (PetBaseObservation, error) {
	return f.v, nil
}

type heroEquipFake struct {
	v   ProviderObservation[RawEquipmentState]
	err error
}

func (f heroEquipFake) HeroEquipmentObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64, string) (ProviderObservation[RawEquipmentState], error) {
	return f.v, f.err
}

type petEquipFake struct {
	v   ProviderObservation[RawEquipmentState]
	err error
}

func (f petEquipFake) PetEquipmentObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64, string) (ProviderObservation[RawEquipmentState], error) {
	return f.v, f.err
}

type heroPracticeFake struct {
	v   ProviderObservation[PracticeContribution]
	err error
}

func (f heroPracticeFake) HeroPracticeObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64, string) (ProviderObservation[PracticeContribution], error) {
	return f.v, f.err
}

type petPracticeFake struct {
	v   ProviderObservation[PracticeContribution]
	err error
}

func (f petPracticeFake) PetPracticeObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64, string) (ProviderObservation[PracticeContribution], error) {
	return f.v, f.err
}

type heroAppearanceFake struct {
	v   ProviderObservation[HeroAppearanceContribution]
	err error
}

func (f heroAppearanceFake) HeroAppearanceObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64, string, time.Time) (ProviderObservation[HeroAppearanceContribution], error) {
	return f.v, f.err
}

type petAppearanceFake struct {
	v   ProviderObservation[PetAppearanceContribution]
	err error
}

func (f petAppearanceFake) PetAppearanceObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64, string, time.Time) (ProviderObservation[PetAppearanceContribution], error) {
	return f.v, f.err
}

type savedFake struct{ v SavedPresetReferenceState }

func (f savedFake) SavedPresetReferenceStateTx(context.Context, tx.Queryer, identity.PlayerID) (SavedPresetReferenceState, error) {
	return f.v, nil
}

func ca83CoherentScope(t *testing.T) CoherentReadScope {
	t.Helper()
	s, err := NewCoherentReadScope(ca8Scope(tx.RepeatableRead), ca83rev, time.Unix(50, 0).UTC())
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func heroCompositeFixture(t *testing.T) (OwnedCompositeBuilder, character.HeroRef) {
	t.Helper()
	ref := character.HeroRef{PlayerID: 1, PartnerID: 7}
	base := HeroBaseObservation{Ref: ref, TableID: 11001, OriginTableID: 11001, Kind: character.NormalHero, Star: 2, Level: 3, Exp: 4, Color: 5, CreationContentRevision: ca83rev, StateVersion: 9}
	eq := RawEquipmentState{Family: "HERO", OwnerID: 7, StateVersion: 9, Slots: []RawEquipmentSlot{{Slot: 1, TemplateID: 1001}}}
	pr := PracticeContribution{Family: PracticeFamilyHero, OwnerID: 7, TableID: 11001, StateVersion: 9, ContentRevision: ca83rev, Reducer: PracticeReducerHeroAdditive}
	ap := HeroAppearanceContribution{OwnerID: 7, TableID: 11001, OriginTableID: 11001, ContentRevision: ca83rev, Appearance: EffectiveHeroAppearance{OwnerStateVersion: 9, ObservedAt: time.Unix(50, 0).UTC(), CurrentSkinID: 0, IllusionSkinID: -1}}
	return OwnedCompositeBuilder{
		HeroBase:       heroBaseFake{base},
		HeroEquipment:  heroEquipFake{v: ProviderObservation[RawEquipmentState]{Disposition: ProviderQualifiedActive, Value: eq}},
		HeroPractice:   heroPracticeFake{v: ProviderObservation[PracticeContribution]{Disposition: ProviderQualifiedActive, Value: pr}},
		HeroAppearance: heroAppearanceFake{v: ProviderObservation[HeroAppearanceContribution]{Disposition: ProviderQualifiedActive, Value: ap}},
	}, ref
}

func petCompositeFixture(t *testing.T) (OwnedCompositeBuilder, character.PetRef) {
	t.Helper()
	ref := character.PetRef{PlayerID: 1, PetID: 8}
	base := PetBaseObservation{Ref: ref, TableID: 21001, OriginTableID: 21001, Star: 2, Level: 3, Exp: 4, Color: 5, Skills: character.DefaultPetSkillLevels(), Birthday: 10, CreationContentRevision: ca83rev, StateVersion: 12}
	eq := RawEquipmentState{Family: "PET", OwnerID: 8, StateVersion: 12, Slots: []RawEquipmentSlot{{Slot: 1, TemplateID: 2001}}}
	pr := PracticeContribution{Family: PracticeFamilyPet, OwnerID: 8, TableID: 21001, StateVersion: 12, ContentRevision: ca83rev, Reducer: PracticeReducerPetSourceOverwrite}
	ap := PetAppearanceContribution{OwnerID: 8, TableID: 21001, OriginTableID: 21001, ContentRevision: ca83rev, Appearance: EffectivePetAppearance{OwnerStateVersion: 12, ObservedAt: time.Unix(50, 0).UTC()}}
	return OwnedCompositeBuilder{
		PetBase:       petBaseFake{base},
		PetEquipment:  petEquipFake{v: ProviderObservation[RawEquipmentState]{Disposition: ProviderQualifiedActive, Value: eq}},
		PetPractice:   petPracticeFake{v: ProviderObservation[PracticeContribution]{Disposition: ProviderQualifiedActive, Value: pr}},
		PetAppearance: petAppearanceFake{v: ProviderObservation[PetAppearanceContribution]{Disposition: ProviderQualifiedActive, Value: ap}},
	}, ref
}

func TestOwnedHeroAndPetCompositeSuccess(t *testing.T) {
	s := ca83CoherentScope(t)
	hb, href := heroCompositeFixture(t)
	h, err := hb.OwnedHeroTx(context.Background(), s, href)
	if err != nil {
		t.Fatal(err)
	}
	if h.Origin != ActorOriginOwned || h.Equipment.Disposition != ProviderQualifiedActive || h.Practice.Disposition != ProviderQualifiedActive || h.Appearance.Disposition != ProviderQualifiedActive {
		t.Fatalf("hero=%+v", h)
	}
	pb, pref := petCompositeFixture(t)
	p, err := pb.OwnedPetTx(context.Background(), s, pref)
	if err != nil {
		t.Fatal(err)
	}
	if p.Origin != ActorOriginOwned || p.Base.Birthday != 10 {
		t.Fatalf("pet=%+v", p)
	}
}

func TestOwnedHeroCompositeRejectsEveryCoherenceMismatch(t *testing.T) {
	s := ca83CoherentScope(t)
	cases := map[string]func(*OwnedCompositeBuilder){
		"equipment_version": func(b *OwnedCompositeBuilder) {
			f := b.HeroEquipment.(heroEquipFake)
			f.v.Value.StateVersion++
			b.HeroEquipment = f
		},
		"equipment_owner": func(b *OwnedCompositeBuilder) {
			f := b.HeroEquipment.(heroEquipFake)
			f.v.Value.OwnerID++
			b.HeroEquipment = f
		},
		"practice_version": func(b *OwnedCompositeBuilder) {
			f := b.HeroPractice.(heroPracticeFake)
			f.v.Value.StateVersion++
			b.HeroPractice = f
		},
		"practice_table": func(b *OwnedCompositeBuilder) {
			f := b.HeroPractice.(heroPracticeFake)
			f.v.Value.TableID++
			b.HeroPractice = f
		},
		"practice_revision": func(b *OwnedCompositeBuilder) {
			f := b.HeroPractice.(heroPracticeFake)
			f.v.Value.ContentRevision = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
			b.HeroPractice = f
		},
		"appearance_version": func(b *OwnedCompositeBuilder) {
			f := b.HeroAppearance.(heroAppearanceFake)
			f.v.Value.Appearance.OwnerStateVersion++
			b.HeroAppearance = f
		},
		"appearance_table": func(b *OwnedCompositeBuilder) {
			f := b.HeroAppearance.(heroAppearanceFake)
			f.v.Value.TableID++
			b.HeroAppearance = f
		},
		"appearance_origin": func(b *OwnedCompositeBuilder) {
			f := b.HeroAppearance.(heroAppearanceFake)
			f.v.Value.OriginTableID++
			b.HeroAppearance = f
		},
		"appearance_revision": func(b *OwnedCompositeBuilder) {
			f := b.HeroAppearance.(heroAppearanceFake)
			f.v.Value.ContentRevision = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
			b.HeroAppearance = f
		},
		"appearance_time": func(b *OwnedCompositeBuilder) {
			f := b.HeroAppearance.(heroAppearanceFake)
			f.v.Value.Appearance.ObservedAt = f.v.Value.Appearance.ObservedAt.Add(time.Second)
			b.HeroAppearance = f
		},
	}
	for name, mutate := range cases {
		t.Run(name, func(t *testing.T) {
			b, ref := heroCompositeFixture(t)
			mutate(&b)
			if _, err := b.OwnedHeroTx(context.Background(), s, ref); !errors.Is(err, ErrOwnedCompositeCoherence) {
				t.Fatalf("err=%v", err)
			}
		})
	}
}

func TestOwnedCompositeProviderUnavailableAndRequirednessBoundary(t *testing.T) {
	s := ca83CoherentScope(t)
	b, ref := heroCompositeFixture(t)
	b.HeroEquipment, b.HeroPractice, b.HeroAppearance = nil, nil, nil
	got, err := b.OwnedHeroTx(context.Background(), s, ref)
	if err != nil {
		t.Fatal(err)
	}
	if got.Equipment.Disposition != ProviderUnavailableUnqualified || got.Practice.Disposition != ProviderUnavailableUnqualified || got.Appearance.Disposition != ProviderUnavailableUnqualified {
		t.Fatalf("got=%+v", got)
	}

	b, ref = heroCompositeFixture(t)
	f := b.HeroEquipment.(heroEquipFake)
	f.v.Disposition = ProviderRequiredButUnavailable
	f.v.Value = RawEquipmentState{}
	b.HeroEquipment = f
	if _, err := b.OwnedHeroTx(context.Background(), s, ref); err == nil {
		t.Fatal("consumer requiredness accepted by CA8-3")
	}

	b, ref = heroCompositeFixture(t)
	hard := errors.New("storage failure")
	b.HeroEquipment = heroEquipFake{err: hard}
	if _, err := b.OwnedHeroTx(context.Background(), s, ref); !errors.Is(err, hard) {
		t.Fatalf("hard err=%v", err)
	}
}

func TestSavedPresetReferenceExportPreservesDuplicatesOrderEmptyAndDeepCopy(t *testing.T) {
	s := ca83CoherentScope(t)
	h1 := character.HeroRef{PlayerID: 1, PartnerID: 7}
	h2 := character.HeroRef{PlayerID: 1, PartnerID: 8}
	p := character.PetRef{PlayerID: 1, PetID: 9}
	state := SavedPresetReferenceState{PlayerID: 1, StateVersion: 22, Loadouts: []SavedPresetReferenceLoadout{{Heroes: []character.HeroRef{h1, h2, h1}, Pet: &p}}}
	b := OwnedCompositeBuilder{SavedPresets: savedFake{state}}
	got, err := b.SavedPresetReferencesTx(context.Background(), s, 1)
	if err != nil {
		t.Fatal(err)
	}
	if got.StateVersion != 22 || len(got.Loadouts) != 1 || len(got.Loadouts[0].Heroes) != 3 || got.Loadouts[0].Heroes[0] != h1 || got.Loadouts[0].Heroes[2] != h1 {
		t.Fatalf("got=%+v", got)
	}
	got.Loadouts[0].Heroes[0].PartnerID = 99
	got.Loadouts[0].Pet.PetID = 99
	if state.Loadouts[0].Heroes[0].PartnerID != 7 || state.Loadouts[0].Pet.PetID != 9 {
		t.Fatal("saved state aliased")
	}

	empty := SavedPresetReferenceState{PlayerID: 1, StateVersion: 23}
	b.SavedPresets = savedFake{empty}
	if got, err = b.SavedPresetReferencesTx(context.Background(), s, 1); err != nil || len(got.Loadouts) != 0 {
		t.Fatalf("empty got=%+v err=%v", got, err)
	}
}

func TestOwnedCompositeReturnsDeepCopies(t *testing.T) {
	s := ca83CoherentScope(t)
	b, ref := heroCompositeFixture(t)
	f := b.HeroAppearance.(heroAppearanceFake)
	expires := time.Unix(100, 0).UTC()
	f.v.Value.Appearance.Skins = []QualifiedSkinEntitlement{{ModelID: 2, ExpiresAt: &expires}}
	f.v.Value.Appearance.LIVE = []QualifiedLIVEState{{ModelID: 3}}
	b.HeroAppearance = f
	got, err := b.OwnedHeroTx(context.Background(), s, ref)
	if err != nil {
		t.Fatal(err)
	}
	got.Equipment.Value.Slots[0].TemplateID = 999
	got.Appearance.Value.Appearance.Skins[0].ModelID = 999
	*got.Appearance.Value.Appearance.Skins[0].ExpiresAt = time.Unix(999, 0)
	origE := b.HeroEquipment.(heroEquipFake).v.Value.Slots[0].TemplateID
	origS := b.HeroAppearance.(heroAppearanceFake).v.Value.Appearance.Skins[0]
	if origE == 999 || origS.ModelID == 999 || origS.ExpiresAt.Unix() == 999 {
		t.Fatal("composite aliases provider state")
	}
}
