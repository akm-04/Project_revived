package charactersavedpreset

import (
	"context"
	"testing"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type ca76PresetHeroAppearanceState struct {
	currentSkinID  int64
	illusionSkinID int64
	ownedSkins     []int64
}

type ca76PresetHeroOwner struct {
	state ca76PresetHeroAppearanceState
}

func (o *ca76PresetHeroOwner) HeroReferenceLockKey(r character.HeroRef) (lockkey.Key, error) {
	return characterasset.HeroReferenceLockKey(r)
}

func (o *ca76PresetHeroOwner) LockHeroReferenceKeyTx(context.Context, tx.Tx, lockkey.Key, character.HeroRef) error {
	return nil
}

type ca76PresetPetAppearanceState struct {
	activeStyle int64
	ownedStyles []int64
}

type ca76PresetPetOwner struct {
	state ca76PresetPetAppearanceState
}

func (o *ca76PresetPetOwner) PetReferenceLockKey(r character.PetRef) (lockkey.Key, error) {
	return characterasset.PetReferenceLockKey(r)
}

func (o *ca76PresetPetOwner) LockPetReferenceKeyTx(context.Context, tx.Tx, lockkey.Key, character.PetRef) error {
	return nil
}

func TestCA76SavedPresetMutationPreservesCA7AppearanceState(t *testing.T) {
	current := aggregateVersion(7, 5, presetLane(7, "A", []int64{1}, 8))
	st := &presetMutationStore{reads: []character.SavedPresetAggregate{current, current}}
	db := &presetTestDB{}
	rr := &presetReceipts{}
	heroOwner := &ca76PresetHeroOwner{state: ca76PresetHeroAppearanceState{
		currentSkinID: 40002006, illusionSkinID: character.DefaultIllusionSkinID, ownedSkins: []int64{40002006, 40002007},
	}}
	petOwner := &ca76PresetPetOwner{state: ca76PresetPetAppearanceState{
		activeStyle: 50001376, ownedStyles: []int64{50001374, 50001376},
	}}
	beforeHero := ca76PresetHeroAppearanceState{currentSkinID: heroOwner.state.currentSkinID, illusionSkinID: heroOwner.state.illusionSkinID, ownedSkins: append([]int64(nil), heroOwner.state.ownedSkins...)}
	beforePet := ca76PresetPetAppearanceState{activeStyle: petOwner.state.activeStyle, ownedStyles: append([]int64(nil), petOwner.state.ownedStyles...)}

	svc := mutationServiceFor(db, st, &presetFence{}, heroOwner, petOwner, rr)
	out, err := svc.Replace(context.Background(), presetTestActor(t), Command{
		TeamString: "2", TeamNameString: "B", PetPresent: true, PetString: "9",
	}, presetTestOp(t, "86868686-8686-4686-8686-868686868686"))
	if err != nil {
		t.Fatal(err)
	}
	if !out.Mutated || out.StateVersion != 6 || len(st.replacements) != 1 {
		t.Fatalf("out=%+v replacements=%d", out, len(st.replacements))
	}
	if heroOwner.state.currentSkinID != beforeHero.currentSkinID || heroOwner.state.illusionSkinID != beforeHero.illusionSkinID || len(heroOwner.state.ownedSkins) != len(beforeHero.ownedSkins) {
		t.Fatalf("CA5 mutation changed Hero CA7 appearance state before=%+v after=%+v", beforeHero, heroOwner.state)
	}
	for i := range beforeHero.ownedSkins {
		if heroOwner.state.ownedSkins[i] != beforeHero.ownedSkins[i] {
			t.Fatalf("CA5 mutation changed Hero CA7 entitlements before=%+v after=%+v", beforeHero, heroOwner.state)
		}
	}
	if petOwner.state.activeStyle != beforePet.activeStyle || len(petOwner.state.ownedStyles) != len(beforePet.ownedStyles) {
		t.Fatalf("CA5 mutation changed Pet CA7 appearance state before=%+v after=%+v", beforePet, petOwner.state)
	}
	for i := range beforePet.ownedStyles {
		if petOwner.state.ownedStyles[i] != beforePet.ownedStyles[i] {
			t.Fatalf("CA5 mutation changed Pet CA7 entitlements before=%+v after=%+v", beforePet, petOwner.state)
		}
	}
}
