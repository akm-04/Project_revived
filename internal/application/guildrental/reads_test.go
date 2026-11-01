package guildrental

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
)

func TestRentCountHashesVisibleRows(t *testing.T) {
	row := Row{Offer: guild.RentalOffer{Lender: identity.PlayerID(7), Kind: guild.RentalHero, Unit: 31}, Price: 2000, CanRent: true, HaveRent: false}
	base := rentCount(guild.RentalHero, 1, []Row{row})
	if base == 0 {
		t.Fatal("rent_count must be nonzero")
	}
	if again := rentCount(guild.RentalHero, 1, []Row{row}); again != base {
		t.Fatal("rent_count must be stable", base, again)
	}
	for name, changed := range map[string]Row{
		"price":     {Offer: row.Offer, Price: 3000, CanRent: true},
		"can_rent":  {Offer: row.Offer, Price: 2000, CanRent: false},
		"have_rent": {Offer: row.Offer, Price: 2000, CanRent: true, HaveRent: true},
	} {
		if got := rentCount(guild.RentalHero, 1, []Row{changed}); got == base {
			t.Fatal("rent_count must change with", name)
		}
	}
	if got := rentCount(guild.RentalPet, 1, []Row{row}); got == base {
		t.Fatal("rent_count must change with the rent type")
	}
	if got := rentCount(guild.RentalHero, 2, []Row{row}); got == base {
		t.Fatal("rent_count must change with the campaign type")
	}
	if empty := rentCount(guild.RentalHero, 0, nil); empty == 0 || empty != rentCount(guild.RentalHero, 0, []Row{}) {
		t.Fatal("empty list must still hash to a stable nonzero key", empty)
	}
}
