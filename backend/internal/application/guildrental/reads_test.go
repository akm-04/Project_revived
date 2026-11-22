package guildrental

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/content/guildrentalpolicy"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
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

type emptyReadStore struct{}

func (emptyReadStore) ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error) {
	return guild.Membership{}, false, nil
}
func (emptyReadStore) ListRentalOffersByGuildTx(context.Context, tx.Queryer, guild.ID, guild.RentalKind, int) ([]guild.RentalOffer, error) {
	return nil, nil
}
func (emptyReadStore) ListLenderRentalOffersTx(context.Context, tx.Queryer, identity.PlayerID, guild.RentalKind, int) ([]guild.RentalOffer, error) {
	return nil, nil
}
func (emptyReadStore) ReadRentalUsesDayTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]guild.RentalUse, error) {
	return nil, nil
}

type emptyReadCharacters struct{}

func (emptyReadCharacters) HeroProjectionTx(context.Context, tx.Queryer, string, time.Time, identity.PlayerID, int64) (HeroProjection, bool, error) {
	return HeroProjection{}, false, nil
}
func (emptyReadCharacters) PetTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, bool, error) {
	return character.Pet{}, false, nil
}

type emptyReadProfiles struct{}

func (emptyReadProfiles) ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return playerdirectory.Profile{}, false, nil
}

type emptyReadLevels struct{}

func (emptyReadLevels) LevelTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error) {
	return 1, nil
}

type emptyReadMana struct{}

func (emptyReadMana) BalanceTx(context.Context, tx.Queryer, identity.PlayerID, string) (int64, bool, error) {
	return 0, true, nil
}

type emptyReadPrivileges struct{}

func (emptyReadPrivileges) SnapshotTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (i5.PrivilegeSnapshot, error) {
	return i5.PrivilegeSnapshot{}, nil
}

type emptyReadContent struct{}

func (emptyReadContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return "rev", nil
}
func (emptyReadContent) HeroExpPolicyTx(context.Context, tx.Queryer, string, int64) ([]character.HeroExpThreshold, error) {
	return nil, nil
}

type emptyReadBeginner struct{}

func (emptyReadBeginner) Begin(context.Context, tx.Options) (tx.Tx, error) { return guardTx{}, nil }

func emptyListReader() Reader {
	now := time.Unix(1700000000, 0).UTC()
	return Reader{
		Runner: tx.Runner{DB: emptyReadBeginner{}}, Store: emptyReadStore{}, Characters: emptyReadCharacters{},
		Profiles: emptyReadProfiles{}, Levels: emptyReadLevels{}, Mana: emptyReadMana{}, Privileges: emptyReadPrivileges{},
		Content: emptyReadContent{},
		Now:     func(context.Context, tx.Queryer) (time.Time, error) { return now, nil },
		Policy: Policy{
			Money:     guild.RentalMoney{PriceForceDivisor: 1000, PriceFloorMana: 1000, HourlyInterestForceDivisor: 100, RecallMinimumSeconds: 1800, LevelUpCeiling: 5},
			Modes:     map[int64]ModeRule{1: {Enabled: true}, 67: {Enabled: false}, 99: {Enabled: false}},
			VIP:       map[int64]VIPLimit{0: {Lend: 2, LevelUp: 0}},
			Departure: DepartureMail{Sender: "guild", Title: "rental", Body: "closed"},
		},
	}
}

// TestGuildOffersEmptyListsUseTheRowHash covers both early-empty answers: a
// disabled requested type and a caller without a guild. Their cache identity is
// the same kind/type/empty-rows hash a materialized empty list uses, so a stale
// client list is never keyed by one shared literal (C6).
func TestGuildOffersEmptyListsUseTheRowHash(t *testing.T) {
	reader := emptyListReader()
	actor := identity.ActorContext{LogicalServerID: 1, PlayerID: 9}
	op := operation.Context{StartedAt: time.Unix(1700000000, 0).UTC()}
	for _, requestedType := range []int64{67, 99} {
		list, err := reader.GuildOffers(context.Background(), actor, guild.RentalHero, requestedType, op)
		if err != nil {
			t.Fatal("disabled type", requestedType, err)
		}
		if want := countForTest(t, guild.RentalHero, requestedType, nil); list.RentCount != want || list.RentCount == 1 {
			t.Fatalf("disabled type %d rent_count %d want %d", requestedType, list.RentCount, want)
		}
		if len(list.Rows) != 0 {
			t.Fatalf("disabled type %d rows %v", requestedType, list.Rows)
		}
	}
	first, err := reader.GuildOffers(context.Background(), actor, guild.RentalHero, 1, op)
	if err != nil {
		t.Fatal("guildless type 1", err)
	}
	if want := countForTest(t, guild.RentalHero, 1, nil); first.RentCount != want || first.RentCount == 1 {
		t.Fatalf("guildless type 1 rent_count %d want %d", first.RentCount, want)
	}
	second, err := reader.GuildOffers(context.Background(), actor, guild.RentalHero, 2, op)
	if err != nil {
		t.Fatal("guildless type 2", err)
	}
	if second.RentCount == first.RentCount {
		t.Fatalf("guildless list key ignores the requested type: %d", first.RentCount)
	}
}

type listingReadStore struct{ emptyReadStore }

func (listingReadStore) ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error) {
	return guild.Membership{GuildID: 5}, true, nil
}
func (listingReadStore) ListRentalOffersByGuildTx(context.Context, tx.Queryer, guild.ID, guild.RentalKind, int) ([]guild.RentalOffer, error) {
	return []guild.RentalOffer{{Lender: 7, Guild: 5, Kind: guild.RentalHero, Unit: 31, Force: 2000}}, nil
}

type listingCharacters struct{ emptyReadCharacters }

func (listingCharacters) HeroProjectionTx(context.Context, tx.Queryer, string, time.Time, identity.PlayerID, int64) (HeroProjection, bool, error) {
	return HeroProjection{Hero: character.Hero{PartnerID: 31, Level: 1}}, true, nil
}

type listingProfiles struct{ emptyReadProfiles }

func (listingProfiles) ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return playerdirectory.Profile{Name: "lender"}, true, nil
}

type listingContent struct{ emptyReadContent }

func (listingContent) HeroExpPolicyTx(context.Context, tx.Queryer, string, int64) ([]character.HeroExpThreshold, error) {
	return []character.HeroExpThreshold{{Level: 1, TotalExp: 0}}, nil
}

// builtinPolicy is the production embedded policy bound the way cmd/gxb-api
// binds it, so this test fails when the shipped row is disabled.
func builtinPolicy(t *testing.T) Policy {
	t.Helper()
	artifact, err := guildrentalpolicy.LoadBuiltin()
	if err != nil {
		t.Fatal(err)
	}
	modes := map[int64]ModeRule{}
	for _, mode := range artifact.Policy.Modes {
		rule := ModeRule{Enabled: mode.Enabled}
		if mode.StarCap > 0 {
			rule.StarCap = mode.StarCap
		}
		for _, campaignType := range mode.CampaignTypes {
			modes[campaignType] = rule
		}
	}
	vip := map[int64]VIPLimit{}
	for _, row := range artifact.Policy.VIPLimits {
		vip[row.VIP] = VIPLimit{Lend: row.Lend, LevelUp: row.LevelUp}
	}
	return Policy{
		Money:     guild.RentalMoney{PriceForceDivisor: artifact.Policy.Money.PriceForceDivisor, PriceFloorMana: artifact.Policy.Money.PriceFloorMana, HourlyInterestForceDivisor: artifact.Policy.Money.HourlyInterestForceDivisor, RecallMinimumSeconds: artifact.Policy.Money.RecallMinimumSeconds, LevelUpCeiling: artifact.Policy.Money.LevelUpCeiling},
		Modes:     modes,
		VIP:       vip,
		Departure: DepartureMail{Sender: artifact.Policy.Departure.Sender, Title: artifact.Policy.Departure.Title, Body: artifact.Policy.Departure.Body},
	}
}

// TestGuildOffersListsWorldBossAndGodsTrialModes is carry 5: the shipped
// policy enables the World Boss [8] and Gods Trial [79] rows, so 2768 returns
// their offers instead of the early-empty list. Chapter Boss [67] stays absent.
func TestGuildOffersListsWorldBossAndGodsTrialModes(t *testing.T) {
	now := time.Unix(1700000000, 0).UTC()
	reader := Reader{
		Runner: tx.Runner{DB: emptyReadBeginner{}}, Store: listingReadStore{}, Characters: listingCharacters{},
		Profiles: listingProfiles{}, Levels: emptyReadLevels{}, Mana: emptyReadMana{}, Privileges: emptyReadPrivileges{},
		Content: listingContent{},
		Now:     func(context.Context, tx.Queryer) (time.Time, error) { return now, nil },
		Policy:  builtinPolicy(t),
	}
	actor := identity.ActorContext{LogicalServerID: 1, PlayerID: 9}
	op := operation.Context{StartedAt: now}
	for _, requestedType := range []int64{8, 79} {
		list, err := reader.GuildOffers(context.Background(), actor, guild.RentalHero, requestedType, op)
		if err != nil {
			t.Fatal("mode", requestedType, err)
		}
		if len(list.Rows) != 1 || list.Rows[0].Offer.Unit != 31 {
			t.Fatalf("mode %d did not list the offer: %v", requestedType, list.Rows)
		}
	}
	chapterBoss, err := reader.GuildOffers(context.Background(), actor, guild.RentalHero, 67, op)
	if err != nil || len(chapterBoss.Rows) != 0 {
		t.Fatalf("Chapter Boss [67] must stay unlisted: %v %v", chapterBoss.Rows, err)
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
