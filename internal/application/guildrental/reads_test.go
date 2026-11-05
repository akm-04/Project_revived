package guildrental

import (
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
)

func TestRentCountHashesVisibleRows(t *testing.T) {
	row := Row{Offer: guild.RentalOffer{Lender: identity.PlayerID(7), Kind: guild.RentalHero, Unit: 31}, Price: 2000, CanRent: true, HaveRent: false}
	base := countForTest(t, guild.RentalHero, 1, []Row{row})
	if base == 0 {
		t.Fatal("rent_count must be nonzero")
	}
	if again := countForTest(t, guild.RentalHero, 1, []Row{row}); again != base {
		t.Fatal("rent_count must be stable", base, again)
	}
	for name, changed := range map[string]Row{
		"price":     {Offer: row.Offer, Price: 3000, CanRent: true},
		"can_rent":  {Offer: row.Offer, Price: 2000, CanRent: false},
		"have_rent": {Offer: row.Offer, Price: 2000, CanRent: true, HaveRent: true},
	} {
		if got := countForTest(t, guild.RentalHero, 1, []Row{changed}); got == base {
			t.Fatal("rent_count must change with", name)
		}
	}
	if got := countForTest(t, guild.RentalPet, 1, []Row{row}); got == base {
		t.Fatal("rent_count must change with the rent type")
	}
	if got := countForTest(t, guild.RentalHero, 2, []Row{row}); got == base {
		t.Fatal("rent_count must change with the campaign type")
	}
	if empty := countForTest(t, guild.RentalHero, 0, nil); empty == 0 || empty != countForTest(t, guild.RentalHero, 0, []Row{}) {
		t.Fatal("empty list must still hash to a stable nonzero key", empty)
	}
}

func TestRentCountTracksDetailAndIgnoresObservationTime(t *testing.T) {
	makeRow := func() Row {
		stage := int64(0)
		return Row{Offer: guild.RentalOffer{Lender: 7, Kind: guild.RentalHero, Unit: 31}, Price: 2000, CanRent: true,
			Hero:       &character.Hero{PartnerID: 31, TableID: 10001001, Level: 50, Exp: 200},
			Appearance: &characterasset.EffectiveHeroAppearance{CurrentSkinID: 40001001, Skins: []characterasset.QualifiedSkinEntitlement{{ModelID: 40001001}}}, TwiceAwakeStage: &stage}
	}
	baseline := countForTest(t, guild.RentalHero, 0, []Row{makeRow()})
	changes := map[string]func(*Row){
		"skin":            func(r *Row) { r.Appearance.CurrentSkinID = 0 },
		"skin expiration": func(r *Row) { at := time.Unix(1700000000, 0); r.Appearance.Skins[0].ExpiresAt = &at },
		"blood awakening": func(r *Row) { *r.TwiceAwakeStage = 2 },
		"experience":      func(r *Row) { r.Hero.Exp++ },
		"equipment":       func(r *Row) { r.Hero.Equipment[0] = 1 },
		"profile":         func(r *Row) { r.Profile.Name = "changed" },
	}
	for name, change := range changes {
		t.Run(name, func(t *testing.T) {
			row := makeRow()
			change(&row)
			if countForTest(t, guild.RentalHero, 0, []Row{row}) == baseline {
				t.Fatal("changed detail retained cached key")
			}
		})
	}
	row := makeRow()
	row.Interest = 999
	row.Appearance.ObservedAt = time.Unix(1700000000, 0)
	row.Appearance.OwnerStateVersion = 50
	row.Hero.UpdatedAt = row.Appearance.ObservedAt
	row.Hero.StateVersion = 50
	if countForTest(t, guild.RentalHero, 0, []Row{row}) != baseline {
		t.Fatal("observation metadata changed key")
	}
	first := makeRow()
	second := makeRow()
	second.Offer.Lender = 8
	second.Offer.Unit = 32
	if countForTest(t, guild.RentalHero, 0, []Row{first, second}) != countForTest(t, guild.RentalHero, 0, []Row{second, first}) {
		t.Fatal("store ordering changed key")
	}
}

func TestRentCountTracksPetDetails(t *testing.T) {
	pet := character.Pet{PetID: 41, Level: 2}
	row := Row{Offer: guild.RentalOffer{Lender: 7, Kind: guild.RentalPet, Unit: 41}, Pet: &pet}
	baseline := countForTest(t, guild.RentalPet, 0, []Row{row})
	pet.Level++
	if countForTest(t, guild.RentalPet, 0, []Row{row}) == baseline {
		t.Fatal("pet level change retained cached key")
	}
}

func countForTest(t *testing.T, kind guild.RentalKind, requestedType int64, rows []Row) int64 {
	t.Helper()
	count, err := rentCount(kind, requestedType, rows)
	if err != nil {
		t.Fatal(err)
	}
	return count
}

func TestRentCountCanonicalizesAppearanceWithoutMutatingOwners(t *testing.T) {
	firstExpiry := time.Unix(1700000000, 0).UTC()
	secondExpiry := firstExpiry.In(time.FixedZone("same instant", 8*60*60))
	first := Row{Offer: guild.RentalOffer{Lender: 7, Kind: guild.RentalHero, Unit: 31}, Appearance: &characterasset.EffectiveHeroAppearance{ObservedAt: firstExpiry, OwnerStateVersion: 5,
		Skins: []characterasset.QualifiedSkinEntitlement{{ModelID: 2, ExpiresAt: &firstExpiry}, {ModelID: 1}}}}
	second := first
	appearance := *first.Appearance
	appearance.Skins = []characterasset.QualifiedSkinEntitlement{{ModelID: 1}, {ModelID: 2, ExpiresAt: &secondExpiry}}
	second.Appearance = &appearance
	if countForTest(t, guild.RentalHero, 0, []Row{first}) != countForTest(t, guild.RentalHero, 0, []Row{second}) {
		t.Fatal("equivalent entitlements changed key")
	}
	if first.Appearance.Skins[0].ModelID != 2 || first.Appearance.OwnerStateVersion != 5 || !first.Appearance.ObservedAt.Equal(firstExpiry) {
		t.Fatal("hashing mutated owner data")
	}
}
