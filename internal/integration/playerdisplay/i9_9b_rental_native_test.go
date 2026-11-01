//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/workplacestore"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/guildrental"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/workplace"
	"gxb.local/backend/v2/internal/content/guildrentalpolicy"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"

	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// rentalUnits is the I9-9B fixture port: level comes from the production
// character store and Force is a stable fixture number so the price arithmetic
// is observable. Production binds the publicstats-owned reader instead.
type rentalUnits struct{}

func (rentalUnits) UnitTx(_ context.Context, q tx.Queryer, owner identity.PlayerID, kind guild.RentalKind, unit int64) (guildrental.Unit, bool, error) {
	if kind == guild.RentalHero {
		h, err := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, q, owner, unit)
		if errors.Is(err, kernelstore.ErrNoRows) {
			return guildrental.Unit{}, false, nil
		}
		return guildrental.Unit{Level: h.Level, Force: h.Level * 1000}, err == nil, err
	}
	p, err := (characterstore.Store{}).ReadPetByIDTx(ctx, q, owner, unit)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return guildrental.Unit{}, false, nil
	}
	return guildrental.Unit{Level: p.Level, Force: p.Level * 1000}, err == nil, err
}

type productionLevels struct{}

func (productionLevels) LevelTx(_ context.Context, q tx.Queryer, pid identity.PlayerID) (int64, error) {
	p, err := (i5store.Store{}).ReadProgressionTx(ctx, q, pid)
	return p.Level, err
}

func guildrentalPolicy(p guildrentalpolicy.Policy) guildrental.Policy {
	modes := map[int64]guildrental.ModeRule{}
	for _, mode := range p.Modes {
		rule := guildrental.ModeRule{Enabled: mode.Enabled}
		if mode.StarCap > 0 {
			rule.StarCap = mode.StarCap
		}
		for _, kind := range mode.CampaignTypes {
			modes[kind] = rule
		}
	}
	vip := map[int64]guildrental.VIPLimit{}
	for _, row := range p.VIPLimits {
		vip[row.VIP] = guildrental.VIPLimit{Lend: row.Lend, LevelUp: row.LevelUp}
	}
	return guildrental.Policy{Money: guild.RentalMoney{PriceForceDivisor: p.Money.PriceForceDivisor, PriceFloorMana: p.Money.PriceFloorMana,
		HourlyInterestForceDivisor: p.Money.HourlyInterestForceDivisor, RecallMinimumSeconds: p.Money.RecallMinimumSeconds, LevelUpCeiling: p.Money.LevelUpCeiling},
		Modes: modes, VIP: vip, Departure: guildrental.DepartureMail{Sender: p.Departure.Sender, Title: p.Departure.Title, Body: p.Departure.Body}}
}

func rentalService(t *testing.T, p *postgres.Pool) guildrental.Service {
	t.Helper()
	artifact := must(guildrentalpolicy.LoadBuiltin())(t, "rental policy")
	values := activityOwner(p)
	return guildrental.Service{
		Runner: tx.Runner{DB: p}, Store: guildstore.Store{Queryer: p}, Units: rentalUnits{}, Levels: productionLevels{},
		Workplace: workplace.Mode{Store: workplacestore.Store{}}, Privileges: appi5.BaselinePrivilegeProvider{},
		Values: values, Costs: appi5.MaterialCostDebiter{Store: i5store.Store{Queryer: p}, Content: contentstore.Store{Queryer: p}},
		Facts: appi5.ObjectiveFacts{Owner: values, Open: i5store.Store{Queryer: p}}, Mail: appi5.SettlementMail{Store: i5store.Store{Queryer: p}},
		Fence: i5store.Store{Queryer: p}, Players: i4store.PlayerRootLocker{}, Content: contentstore.Store{Queryer: p}, Policy: guildrentalPolicy(artifact.Policy),
	}
}

type rentalFixture struct {
	pool      *postgres.Pool
	revision  string
	service   guildrental.Service
	combat    combatAlias
	lender    identity.ActorContext
	borrower  identity.ActorContext
	offers    guild.ID
	hero      int64
	second    int64
	third     int64
	pet       int64
	petLender identity.ActorContext
}

type combatAlias = appcombat.Service

func newRentalFixture(t *testing.T) rentalFixture {
	t.Helper()
	p := pool(t)
	server := nativeServer(t, p)
	f := rentalFixture{pool: p}
	f.lender, f.revision = genuinePlayer(t, p, server)
	f.borrower, _ = genuinePlayer(t, p, server)
	f.service = rentalService(t, p)
	f.offers = guildFixture(t, p, f.lender, f.borrower)
	cs := contentstore.Store{Queryer: p}
	tables := []int64{genuineHeroTable, 10001002, 10001003}
	heroes := genuineHeroService(p)
	grantGenuine(t, p, f.lender, f.revision, "resources", genuineResources(t, p, f.revision, tables))
	grantGenuine(t, p, f.borrower, f.revision, "resources", genuineResources(t, p, f.revision, []int64{genuineHeroTable}))
	partners := make([]int64, 0, 3)
	for index, table := range tables {
		def := must(cs.HeroNormalSummonTx(ctx, p, f.revision, table))(t, "summon policy")
		_ = index
		partners = append(partners, must(heroes.SummonNormal(ctx, f.lender, table, int64(def.Template.FragmentItemID), def.FragmentCount, op()))(t, "lender summon").PartnerID)
	}
	f.hero, f.second, f.third = partners[0], partners[1], partners[2]
	egg := must(cs.PetAcquisitionTx(ctx, p, f.revision, genuinePetTable))(t, "pet policy").EggItemID
	f.petLender, _ = genuinePlayer(t, p, server)
	grantGenuine(t, p, f.petLender, f.revision, "pet egg", []grant.Line{{Kind: grant.StackItem, ItemID: egg, Amount: 1}})
	exec(t, p, `INSERT INTO guild_memberships(player_id,guild_id,role,joined_at,membership_version,state_version,updated_at)VALUES($1,$2,0,clock_timestamp(),1,1,clock_timestamp())`, int64(f.petLender.PlayerID), int64(f.offers))
	pets := genuinePetService(p)
	f.pet = must(pets.Summon(ctx, f.petLender, genuinePetTable, op()))(t, "pet summon").PetID
	must(pets.CleanCD(ctx, f.petLender, f.pet, op()))(t, "pet hatch")
	f.combat = combatService(t, p)
	f.combat.Inputs.Lending = f.service
	return f
}

func (f rentalFixture) borrow(t *testing.T, scope string, campaignType int64, hero, pet int64) (appcombat.Started, error) {
	t.Helper()
	locator := d.Locator{DomainKind: "i9-9b-rental", AuthorityScope: fmt.Sprint(f.borrower.LogicalServerID), DomainLocator: fmt.Sprint(f.borrower.PlayerID) + "/" + scope}
	request := appcombat.StartRequest{Actor: f.borrower, Locator: locator, GenerationRef: "gen-" + scope, StartFingerprint: fingerprint(locator.AuthorityScope + locator.DomainLocator),
		Battle: appcombat.BattleRequest{CampaignType: campaignType,
			WavesB: [][]appcombat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}
	if hero > 0 {
		request.Battle.TeamA = []appcombat.Participant{{Origin: d.Borrowed, Kind: d.HeroActor, Player: f.lender.PlayerID, Identity: hero}}
	}
	if pet > 0 {
		request.Battle.PetsA = []appcombat.Participant{{Origin: d.Borrowed, Kind: d.PetActor, Player: f.lender.PlayerID, Identity: pet}}
	}
	return fixtureStart(t, f.combat, f.revision, request, f.pool)
}

func (f rentalFixture) borrowBoth(t *testing.T, scope string, campaignType int64, hero int64, heroLender identity.PlayerID, pet int64, petLender identity.PlayerID) (appcombat.Started, error) {
	t.Helper()
	locator := d.Locator{DomainKind: "i9-9b-rental", AuthorityScope: fmt.Sprint(f.borrower.LogicalServerID), DomainLocator: fmt.Sprint(f.borrower.PlayerID) + "/" + scope}
	request := appcombat.StartRequest{Actor: f.borrower, Locator: locator, GenerationRef: "gen-" + scope, StartFingerprint: fingerprint(locator.AuthorityScope + locator.DomainLocator),
		Battle: appcombat.BattleRequest{CampaignType: campaignType,
			TeamA:  []appcombat.Participant{{Origin: d.Borrowed, Kind: d.HeroActor, Player: heroLender, Identity: hero}},
			PetsA:  []appcombat.Participant{{Origin: d.Borrowed, Kind: d.PetActor, Player: petLender, Identity: pet}},
			WavesB: [][]appcombat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}
	return fixtureStart(t, f.combat, f.revision, request, f.pool)
}

func TestI9_9BRentalNative(t *testing.T) {
	f := newRentalFixture(t)
	op := opPinned(f.revision)
	place := func(kind guild.RentalKind, unit int64) error { return f.service.Place(ctx, f.lender, kind, unit, op) }

	// C8: placement owns the unit, refuses a duplicate and enforces the VIP 0 cap of two girls.
	if err := place(guild.RentalHero, f.hero); err != nil {
		t.Fatal("C8 place", err)
	}
	if err := place(guild.RentalHero, f.hero); !errors.Is(err, guildrental.ErrAlreadyOffered) {
		t.Fatal("C8 duplicate", err)
	}
	if err := place(guild.RentalHero, f.second); err != nil {
		t.Fatal("C8 second", err)
	}
	if err := place(guild.RentalHero, f.third); !errors.Is(err, guildrental.ErrCapReached) {
		t.Fatal("C8 cap", err)
	}

	// C4: a disabled borrow mode refuses at START through Lending.
	if _, err := f.borrow(t, "gods", 79, f.second, 0); !errors.Is(err, d.ErrLoanRefused) {
		t.Fatal("C4 disabled mode", err)
	}

	// C11: VIP 0 gives no rent level-up, so a level 50 unit is above the level 1 borrower.
	exec(t, f.pool, `UPDATE player_heroes SET level=50 WHERE player_id=$1 AND partner_id=$2`, int64(f.lender.PlayerID), f.second)
	if _, err := f.borrow(t, "level", 1, f.second, 0); !errors.Is(err, d.ErrLoanRefused) {
		t.Fatal("C11 level gate", err)
	}
	exec(t, f.pool, `UPDATE player_heroes SET level=1 WHERE player_id=$1 AND partner_id=$2`, int64(f.lender.PlayerID), f.second)

	// C3 and C16: one paid borrow debits mana once and adds the offer's rent_award.
	mana := libraryAmount(t, f.pool, f.borrower, "mana")
	price := int64(1000)
	_, err := f.borrow(t, "one", 1, f.hero, 0)
	if err != nil {
		t.Fatal("C3 lend", err)
	}
	if got := libraryAmount(t, f.pool, f.borrower, "mana"); got != mana-price {
		t.Fatalf("C3 debit once: %d -> %d", mana, got)
	}
	if award := scalar(t, f.pool, `SELECT rent_award FROM guild_rental_offers WHERE lender_id=$1 AND kind='HERO' AND unit_id=$2`, int64(f.lender.PlayerID), f.hero); award != price {
		t.Fatal("C3 rent_award", award)
	}

	// C3: a replay of the same START charges nothing.
	again, err := f.borrow(t, "one", 1, f.hero, 0)
	if err != nil || !again.Replayed || libraryAmount(t, f.pool, f.borrower, "mana") != mana-price {
		t.Fatal("C3 replay charged", err, libraryAmount(t, f.pool, f.borrower, "mana"))
	}
	// C10: the same unit again the same day is free.
	if _, err := f.borrow(t, "reuse", 1, f.hero, 0); err != nil || libraryAmount(t, f.pool, f.borrower, "mana") != mana-price {
		t.Fatal("C10 same unit reused", err)
	}
	// C10: a different unit from that lender the same day is refused.
	if _, err := f.borrow(t, "second", 1, f.second, 0); !errors.Is(err, d.ErrLoanRefused) {
		t.Fatal("C10 second unit", err)
	}

	// C9: recall before 1800 s is refused; a backdated recall pays interest and award.
	if _, _, err := f.service.Recall(ctx, f.lender, guild.RentalHero, f.hero, op); !errors.Is(err, guildrental.ErrRecallTooEarly) {
		t.Fatal("C9 early recall", err)
	}
	exec(t, f.pool, `UPDATE guild_rental_offers SET rent_time=rent_time-interval '2 hours' WHERE lender_id=$1 AND kind='HERO' AND unit_id=$2`, int64(f.lender.PlayerID), f.hero)
	before := libraryAmount(t, f.pool, f.lender, "mana")
	interest, rentAward, err := f.service.Recall(ctx, f.lender, guild.RentalHero, f.hero, op)
	if err != nil || interest <= 0 || rentAward != price || libraryAmount(t, f.pool, f.lender, "mana") != before+interest+rentAward {
		t.Fatal("C9 recall payout", err, interest, rentAward)
	}
	if scalar(t, f.pool, `SELECT count(*) FROM guild_rental_offers WHERE lender_id=$1 AND unit_id=$2`, int64(f.lender.PlayerID), f.hero) != 0 {
		t.Fatal("C9 offer not closed")
	}

	// C3: a Hero and a Pet in one battle debit their sum once; a replay charges nothing.
	if err := place(guild.RentalHero, f.hero); err != nil {
		t.Fatal("C8 re-place", err)
	}
	if err := f.service.Place(ctx, f.petLender, guild.RentalPet, f.pet, op); err != nil {
		t.Fatal("C8 pet place", err)
	}
	second := f
	second.borrower, _ = genuinePlayer(t, f.pool, f.lender.LogicalServerID)
	grantGenuine(t, f.pool, second.borrower, f.revision, "resources", genuineResources(t, f.pool, f.revision, []int64{genuineHeroTable}))
	exec(t, f.pool, `INSERT INTO guild_memberships(player_id,guild_id,role,joined_at,membership_version,state_version,updated_at)VALUES($1,$2,0,clock_timestamp(),1,1,clock_timestamp())`, int64(second.borrower.PlayerID), int64(f.offers))
	mana = libraryAmount(t, f.pool, second.borrower, "mana")
	if _, err := second.borrowBoth(t, "both", 1, f.hero, f.lender.PlayerID, f.pet, f.petLender.PlayerID); err != nil {
		t.Fatal("C3 batch lend", err)
	}
	if got := libraryAmount(t, f.pool, second.borrower, "mana"); got != mana-2*price {
		t.Fatalf("C3 batch debit %d -> %d", mana, got)
	}
	if _, err := second.borrowBoth(t, "both", 1, f.hero, f.lender.PlayerID, f.pet, f.petLender.PlayerID); err != nil || libraryAmount(t, f.pool, second.borrower, "mana") != mana-2*price {
		t.Fatal("C3 batch replay charged", err)
	}

	// C15: closing the lender's offers mails each paid offer once and removes them.
	closeTx, err := f.pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err := f.service.CloseLenderOffersTx(ctx, closeTx, f.lender.PlayerID, time.Now().UTC()); err != nil {
		t.Fatal("C15 close", err)
	}
	if err := f.service.CloseLenderOffersTx(ctx, closeTx, f.petLender.PlayerID, time.Now().UTC()); err != nil {
		t.Fatal("C15 close pet lender", err)
	}
	if err := closeTx.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if mail := scalar(t, f.pool, `SELECT count(*) FROM mail_records WHERE recipient_player_id IN ($1,$2) AND source_kind='GUILD_RENTAL_DEPARTURE'`, int64(f.lender.PlayerID), int64(f.petLender.PlayerID)); mail != 2 {
		t.Fatal("C15 mail per paid offer", mail)
	}
	if scalar(t, f.pool, `SELECT count(*) FROM guild_rental_offers WHERE lender_id=$1 OR lender_id=$2`, int64(f.lender.PlayerID), int64(f.petLender.PlayerID)) != 0 {
		t.Fatal("C15 offers remain")
	}
	againTx, err := f.pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer againTx.Rollback(ctx)
	if err := f.service.CloseLenderOffersTx(ctx, againTx, f.lender.PlayerID, time.Now().UTC()); err != nil {
		t.Fatal("C15 close again", err)
	}
	if err := againTx.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if mail := scalar(t, f.pool, `SELECT count(*) FROM mail_records WHERE recipient_player_id IN ($1,$2) AND source_kind='GUILD_RENTAL_DEPARTURE'`, int64(f.lender.PlayerID), int64(f.petLender.PlayerID)); mail != 2 {
		t.Fatal("C15 second close mailed again", mail)
	}
}
