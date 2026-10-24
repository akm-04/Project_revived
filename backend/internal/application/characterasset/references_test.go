package characterasset

import (
	"errors"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
)

func mustKey(t *testing.T, k lockkey.Key, err error) lockkey.Key {
	t.Helper()
	if err != nil {
		t.Fatal(err)
	}
	return k
}

func TestReferenceLockRanksAndCompositeIdentityOrdering(t *testing.T) {
	if character.HeroInstanceLockRank != 410 || character.PetInstanceLockRank != 430 || SavedPresetRootLockRank != 440 {
		t.Fatalf("rank drift hero=%d pet=%d preset=%d", character.HeroInstanceLockRank, character.PetInstanceLockRank, SavedPresetRootLockRank)
	}
	p := identity.PlayerID(7)
	h2k, h2err := HeroReferenceLockKey(character.HeroRef{PlayerID: p, PartnerID: 2})
	h2 := mustKey(t, h2k, h2err)
	h10k, h10err := HeroReferenceLockKey(character.HeroRef{PlayerID: p, PartnerID: 10})
	h10 := mustKey(t, h10k, h10err)
	petk, peterr := PetReferenceLockKey(character.PetRef{PlayerID: p, PetID: 1})
	pet := mustKey(t, petk, peterr)
	rootk, rooterr := SavedPresetRootLockKey(p)
	root := mustKey(t, rootk, rooterr)
	if !(lockkey.Compare(h2, h10) < 0 && lockkey.Compare(h10, pet) < 0 && lockkey.Compare(pet, root) < 0) {
		t.Fatalf("unexpected canonical order: h2/h10=%d h10/pet=%d pet/root=%d", lockkey.Compare(h2, h10), lockkey.Compare(h10, pet), lockkey.Compare(pet, root))
	}
	otherk, othererr := HeroReferenceLockKey(character.HeroRef{PlayerID: 8, PartnerID: 2})
	other := mustKey(t, otherk, othererr)
	if lockkey.Compare(h2, other) == 0 {
		t.Fatal("same local Hero id under different players collapsed")
	}
}

func TestReferenceLockKeyRoundTripsAndRejectsFamilyMismatch(t *testing.T) {
	h := character.HeroRef{PlayerID: 7, PartnerID: 10}
	hkk, hkerr := HeroReferenceLockKey(h)
	hk := mustKey(t, hkk, hkerr)
	if got, err := HeroReferenceFromLockKey(hk); err != nil || got != h {
		t.Fatalf("Hero round trip got=%+v err=%v", got, err)
	}
	p := character.PetRef{PlayerID: 7, PetID: 10}
	pkk, pkerr := PetReferenceLockKey(p)
	pk := mustKey(t, pkk, pkerr)
	if got, err := PetReferenceFromLockKey(pk); err != nil || got != p {
		t.Fatalf("Pet round trip got=%+v err=%v", got, err)
	}
	if _, err := HeroReferenceFromLockKey(pk); err == nil {
		t.Fatal("Pet key accepted as Hero key")
	}
	if _, err := PetReferenceFromLockKey(hk); err == nil {
		t.Fatal("Hero key accepted as Pet key")
	}
	rootk, rooterr := SavedPresetRootLockKey(7)
	root := mustKey(t, rootk, rooterr)
	if got, err := SavedPresetRootPlayerFromLockKey(root); err != nil || got != 7 {
		t.Fatalf("root round trip got=%d err=%v", got, err)
	}
	if _, err := SavedPresetRootLockKey(0); err == nil {
		t.Fatal("invalid player accepted for root key")
	}
}

func TestCanonicalReferenceGuardPlansRejectAmbiguityAndSort(t *testing.T) {
	kak, kaerr := SavedPresetRootLockKey(7)
	ka := mustKey(t, kak, kaerr)
	kbk, kberr := SavedPresetRootLockKey(8)
	kb := mustKey(t, kbk, kberr)
	got, err := CanonicalizeReferenceGuardPlans([]ReferenceGuardPlan{
		{ProviderID: "z-provider", Locks: []lockkey.Key{kb}},
		{ProviderID: "a-provider", Locks: []lockkey.Key{ka}},
	})
	if err != nil {
		t.Fatal(err)
	}
	if []string{got.Providers[0].ProviderID, got.Providers[1].ProviderID}[0] != "a-provider" || got.Providers[1].ProviderID != "z-provider" {
		t.Fatalf("provider ordering=%v", []string{got.Providers[0].ProviderID, got.Providers[1].ProviderID})
	}
	wantLocks, _ := lockkey.Canonical([]lockkey.Key{ka, kb})
	if !reflect.DeepEqual(got.Locks, wantLocks) {
		t.Fatalf("locks=%v want=%v", got.Locks, wantLocks)
	}
	cases := []struct {
		name  string
		plans []ReferenceGuardPlan
	}{
		{"none", nil},
		{"blank provider", []ReferenceGuardPlan{{ProviderID: "", Locks: []lockkey.Key{ka}}}},
		{"empty absence plan", []ReferenceGuardPlan{{ProviderID: "p", Locks: nil}}},
		{"duplicate provider", []ReferenceGuardPlan{{ProviderID: "p", Locks: []lockkey.Key{ka}}, {ProviderID: "p", Locks: []lockkey.Key{kb}}}},
		{"duplicate lock across providers", []ReferenceGuardPlan{{ProviderID: "p1", Locks: []lockkey.Key{ka}}, {ProviderID: "p2", Locks: []lockkey.Key{ka}}}},
		{"duplicate lock within provider", []ReferenceGuardPlan{{ProviderID: "p", Locks: []lockkey.Key{ka, ka}}}},
		{"malformed key", []ReferenceGuardPlan{{ProviderID: "p", Locks: []lockkey.Key{{}}}}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if _, err := CanonicalizeReferenceGuardPlans(tc.plans); !errors.Is(err, ErrInvalidReferenceGuard) {
				t.Fatalf("err=%v want %v", err, ErrInvalidReferenceGuard)
			}
		})
	}
}

func TestValidateReferenceGuardPlanBindsProviderIdentity(t *testing.T) {
	kk, kerr := SavedPresetRootLockKey(7)
	k := mustKey(t, kk, kerr)
	plan := ReferenceGuardPlan{ProviderID: "ca5.saved-presets", Locks: []lockkey.Key{k}}
	if err := ValidateReferenceGuardPlan("ca5.saved-presets", plan); err != nil {
		t.Fatal(err)
	}
	if err := ValidateReferenceGuardPlan("other", plan); !errors.Is(err, ErrInvalidReferenceGuard) {
		t.Fatalf("mismatched provider err=%v", err)
	}
}
