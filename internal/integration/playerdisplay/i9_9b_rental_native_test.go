//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"testing"
	"time"

	appcampaign "gxb.local/backend/v2/internal/application/campaign"
	appgodstrial "gxb.local/backend/v2/internal/application/godstrial"
	appmarch "gxb.local/backend/v2/internal/application/march"
	md "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/domain/modes"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildrentalread"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/workplacestore"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/guildcore"
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

func TestI9_9BProductionUnitsForceMatchesPlace(t *testing.T) {
	f := newRentalFixture(t)
	production := guildrentalread.Units{Stats: rawBirthStats(f.pool), Content: contentstore.Store{Queryer: f.pool},
		Now: func(c context.Context, q tx.Queryer) (time.Time, error) {
			return (postgres.AuthoritativeTime{Queryer: q}).Now(c)
		}}
	svc := f.service
	svc.Units = production
	if err := svc.Place(ctx, f.lender, guild.RentalHero, f.hero, opPinned(f.revision)); err != nil {
		t.Fatal("production place", err)
	}
	tr, err := f.pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	unit, found, err := production.UnitTx(ctx, tr, f.lender.PlayerID, guild.RentalHero, f.hero)
	if err != nil || !found {
		t.Fatal("production unit read", err, found)
	}
	stored := scalar(t, f.pool, `SELECT force FROM guild_rental_offers WHERE lender_id=$1 AND kind='HERO' AND unit_id=$2`, int64(f.lender.PlayerID), f.hero)
	if unit.Force <= 0 || unit.Force != stored {
		t.Fatalf("units force %d stored %d", unit.Force, stored)
	}
}

func TestI9_9BBorrowedTableCollisionRefunds(t *testing.T) {
	f := newRentalFixture(t)
	op := opPinned(f.revision)
	if err := f.service.Place(ctx, f.lender, guild.RentalHero, f.hero, op); err != nil {
		t.Fatal("place", err)
	}
	definition := must(contentstore.Store{Queryer: f.pool}.HeroNormalSummonTx(ctx, f.pool, f.revision, genuineHeroTable))(t, "summon policy")
	owned := must(genuineHeroService(f.pool).SummonNormal(ctx, f.borrower, genuineHeroTable, int64(definition.Template.FragmentItemID), definition.FragmentCount, op))(t, "borrower summon")
	locator := d.Locator{DomainKind: "i9-9b-rental", AuthorityScope: fmt.Sprint(f.borrower.LogicalServerID), DomainLocator: fmt.Sprint(f.borrower.PlayerID) + "/collision"}
	request := appcombat.StartRequest{Actor: f.borrower, Locator: locator, GenerationRef: "gen-collision", StartFingerprint: fingerprint(locator.AuthorityScope + locator.DomainLocator),
		Battle: appcombat.BattleRequest{CampaignType: 1,
			TeamA: []appcombat.Participant{
				{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: f.borrower.PlayerID, Identity: owned.PartnerID},
				{Origin: d.Borrowed, Kind: d.HeroActor, Player: f.lender.PlayerID, Identity: f.hero},
			},
			WavesB: [][]appcombat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}
	mana := libraryAmount(t, f.pool, f.borrower, "mana")
	if _, err := fixtureStart(t, f.combat, f.revision, request, f.pool); !errors.Is(err, d.ErrLoanRefused) {
		t.Fatal("C11 rule 12 collision", err)
	}
	if got := libraryAmount(t, f.pool, f.borrower, "mana"); got != mana {
		t.Fatalf("C11 collision charged %d -> %d", mana, got)
	}
}

func loanMarchReport(r md.Run, borrower, lender int64, formation []int64, loan int64, win bool) appmarch.Result {
	q := appmarch.Result{Report: d.Report{Win: win, Formation: formation, Allies: []d.ActorStatus{}, Enemies: []d.ActorStatus{}}}
	for _, unit := range formation {
		if unit > 0 {
			q.Report.Allies = append(q.Report.Allies, d.ActorStatus{Player: borrower, Identity: unit, HP: 1, MP: 345})
		}
	}
	q.Report.Allies = append(q.Report.Allies, d.ActorStatus{Player: lender, Identity: loan, HP: 1, MP: 345})
	for key, row := range r.Enemies[r.Passed].Heroes {
		if fmt.Sprint(row["health"]) == "2" {
			continue
		}
		unit, _ := strconv.ParseInt(key, 10, 64)
		hp := float64(0)
		if !win {
			hp = 3
		}
		q.Report.Enemies = append(q.Report.Enemies, d.ActorStatus{Identity: unit, HP: hp, MP: 100})
	}
	return q
}

// C12: a March run keeps its borrowed girl after the lender recalls, charges
// once, refuses a different rent mid-run and starts a reset run without a loan.
func TestI9_9BMarchRunHoldsBorrowedGirl(t *testing.T) {
	f := newRentalFixture(t)
	op := opPinned(f.revision)
	if err := f.service.Place(ctx, f.lender, guild.RentalHero, f.second, op); err != nil {
		t.Fatal("place", err)
	}
	compositeLevel(t, f.pool, f.borrower, f.revision, 65)
	own := bornHero(t, f.pool, f.borrower, f.revision, genuineHeroTable, 1)
	m := marchMode(t, f.pool)
	m.Combat = f.combat
	m.Stats = f.combat.Inputs.Stats
	m.Roster = f.combat.Inputs.Heroes
	if _, err := m.Load(ctx, f.borrower, opPinned(f.revision)); err != nil {
		t.Fatal("load", err)
	}
	formation := []int64{own.PartnerID}
	fight := appmarch.Fight{Formation: formation, RentPlayer: int64(f.lender.PlayerID), RentUnit: f.second}
	mana := libraryAmount(t, f.pool, f.borrower, "mana")
	if _, err := m.Start(ctx, f.borrower, fight, opPinned(f.revision)); err != nil {
		t.Fatal("start with loan", err)
	}
	r := marchRecord(t, f.pool, f.borrower)
	if r.Loan == nil || r.Loan.Unit != f.second || r.Loan.Player != int64(f.lender.PlayerID) {
		t.Fatalf("loan not stored: %+v", r.Loan)
	}
	charged := mana - libraryAmount(t, f.pool, f.borrower, "mana")
	if charged <= 0 {
		t.Fatal("first loan not charged", charged)
	}
	if _, err := m.Result(ctx, f.borrower, loanMarchReport(r, int64(f.borrower.PlayerID), int64(f.lender.PlayerID), formation, f.second, true), opPinned(f.revision)); err != nil {
		t.Fatal("result", err)
	}
	if _, err := m.Chest(ctx, f.borrower, 1, opPinned(f.revision)); err != nil {
		t.Fatal("chest", err)
	}
	exec(t, f.pool, `UPDATE guild_rental_offers SET rent_time=rent_time-interval '2 hours' WHERE lender_id=$1 AND kind='HERO' AND unit_id=$2`, int64(f.lender.PlayerID), f.second)
	if _, _, err := f.service.Recall(ctx, f.lender, guild.RentalHero, f.second, opPinned(f.revision)); err != nil {
		t.Fatal("recall", err)
	}
	held := libraryAmount(t, f.pool, f.borrower, "mana")
	if _, err := m.Start(ctx, f.borrower, appmarch.Fight{Formation: formation, RentPlayer: int64(f.lender.PlayerID), RentUnit: f.third}, opPinned(f.revision)); !errors.Is(err, md.ErrRefused) {
		t.Fatal("different rent mid-run accepted", err)
	}
	if _, err := m.Start(ctx, f.borrower, fight, opPinned(f.revision)); err != nil {
		t.Fatal("start held loan after recall", err)
	}
	if got := libraryAmount(t, f.pool, f.borrower, "mana"); got != held {
		t.Fatalf("held loan charged again %d -> %d", held, got)
	}
	r = marchRecord(t, f.pool, f.borrower)
	if _, leaked := r.Heroes[strconv.FormatInt(f.second, 10)]; r.Loan == nil || leaked || r.Loan.Health != 1 {
		t.Fatalf("held loan lost or leaked into self_list: %+v", r)
	}
	if _, err := m.Reset(ctx, f.borrower, opPinned(f.revision)); err != nil {
		t.Fatal("reset", err)
	}
	if r := marchRecord(t, f.pool, f.borrower); r.Loan != nil {
		t.Fatal("loan survived reset", r.Loan)
	}
}

// C13: a winning campaign fight with a BORROWED attacker settles at the mode's
// star cap from the frozen origin, while the client reported three.
func TestI9_9BCampaignBorrowedStarCap(t *testing.T) {
	f := newRentalFixture(t)
	op := opPinned(f.revision)
	if err := f.service.Place(ctx, f.lender, guild.RentalHero, f.second, op); err != nil {
		t.Fatal("place", err)
	}
	own := bornHero(t, f.pool, f.borrower, f.revision, genuineHeroTable, 1)
	m := campaignMode(t, f.pool)
	m.Combat = f.combat
	m.StarCaps = map[int64]int64{1: 2}
	team := []int64{own.PartnerID}
	report := func(fight appcampaign.Fight, result appcampaign.Result) map[string]any {
		t.Helper()
		if _, err := m.Fight(ctx, f.borrower, fight, op); err != nil {
			t.Fatal("campaign start", err)
		}
		settled, err := m.Result(ctx, f.borrower, result, op)
		if err != nil {
			t.Fatal("campaign result", err)
		}
		return settled.Body
	}
	borrowed := report(appcampaign.Fight{CampaignID: 100001, Type: 1, Formation: team, RentPlayer: int64(f.lender.PlayerID), RentFormation: f.second},
		appcampaign.Result{CampaignID: 100001, Type: 1, Star: 3, Formation: team})
	if star := fmt.Sprint(campaignRow(t, borrowed["campaigns"], 100001)["star"]); star != "2" {
		t.Fatalf("C13 borrowed win star %s", star)
	}
	owned := report(appcampaign.Fight{CampaignID: 100001, Type: 1, Formation: team},
		appcampaign.Result{CampaignID: 100001, Type: 1, Star: 3, Formation: team})
	if star := fmt.Sprint(campaignRow(t, owned["campaigns"], 100001)["star"]); star != "3" {
		t.Fatalf("C13 owned win star %s", star)
	}
	uncapped := campaignMode(t, f.pool)
	uncapped.Combat = f.combat
	if _, err := uncapped.Fight(ctx, f.borrower, appcampaign.Fight{CampaignID: 100001, Type: 1, Formation: team, RentPlayer: int64(f.lender.PlayerID), RentFormation: f.second}, op); err != nil {
		t.Fatal("uncapped start", err)
	}
	settled, err := uncapped.Result(ctx, f.borrower, appcampaign.Result{CampaignID: 100001, Type: 1, Star: 3, Formation: team}, op)
	if err != nil {
		t.Fatal("uncapped result", err)
	}
	if star := fmt.Sprint(campaignRow(t, settled.Body["campaigns"], 100001)["star"]); star != "3" {
		t.Fatalf("C13 uncapped star %s", star)
	}
}

// C17: with the Gods Trial borrow row on, START accepts a BORROWED actor.
func TestI9_9BGodsTrialBorrowedStart(t *testing.T) {
	f := newRentalFixture(t)
	op := opPinned(f.revision)
	rental := f.service
	policyCopy := rental.Policy
	policyCopy.Modes = map[int64]guildrental.ModeRule{}
	for kind, rule := range rental.Policy.Modes {
		policyCopy.Modes[kind] = rule
	}
	policyCopy.Modes[79] = guildrental.ModeRule{Enabled: true}
	rental.Policy = policyCopy
	f.combat.Inputs.Lending = rental
	if err := rental.Place(ctx, f.lender, guild.RentalHero, f.second, op); err != nil {
		t.Fatal("place", err)
	}
	compositeLevel(t, f.pool, f.borrower, f.revision, 100)
	own := bornHero(t, f.pool, f.borrower, f.revision, genuineHeroTable, 1)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	for dayOfWeek(clock.at) > 5 {
		clock.at = clock.at.Add(24 * time.Hour)
	}
	s := godsTrialMode(t, f.pool, clock)
	s.Combat = f.combat
	s.Rules = f.combat.Rules
	exec(t, f.pool, `UPDATE player_temporal_resources SET stored_amount=180,regen_anchor_at=NULL WHERE player_id=$1 AND resource_key='spirit_energy'`, int64(f.borrower.PlayerID))
	campaign := int64(dayOfWeek(clock.at))*1000 + 1
	if _, err := s.Start(ctx, f.borrower, appgodstrial.Fight{Campaign: campaign, Formation: []int64{own.PartnerID}, RentPlayer: int64(f.lender.PlayerID), RentUnit: f.second}, op); err != nil {
		t.Fatal("C17 Gods Trial borrowed START", err)
	}
}

func dayOfWeek(at time.Time) int64 {
	return (modes.Day(at)+3)%7 + 1
}

// rentalDeparture prepares a lender (the fixture's borrower) with one borrowed
// offer and one idle offer, so a departure proves the paid mail and the silent close.
func rentalDeparture(t *testing.T) (rentalFixture, guildcore.Service, int64, int64, int64) {
	t.Helper()
	f := newRentalFixture(t)
	revision := f.revision
	borrowed := bornHero(t, f.pool, f.borrower, revision, genuineHeroTable, 1)
	idle := bornHero(t, f.pool, f.borrower, revision, 10001002, 2)
	if err := f.service.Place(ctx, f.borrower, guild.RentalHero, borrowed.PartnerID, opPinned(revision)); err != nil {
		t.Fatal("place borrowed offer", err)
	}
	if err := f.service.Place(ctx, f.borrower, guild.RentalHero, idle.PartnerID, opPinned(revision)); err != nil {
		t.Fatal("place idle offer", err)
	}
	locator := d.Locator{DomainKind: "i9-9b-rental", AuthorityScope: fmt.Sprint(f.lender.LogicalServerID), DomainLocator: fmt.Sprint(f.lender.PlayerID) + "/departure"}
	request := appcombat.StartRequest{Actor: f.lender, Locator: locator, GenerationRef: "gen-departure", StartFingerprint: fingerprint(locator.AuthorityScope + locator.DomainLocator),
		Battle: appcombat.BattleRequest{CampaignType: 1,
			TeamA:  []appcombat.Participant{{Origin: d.Borrowed, Kind: d.HeroActor, Player: f.borrower.PlayerID, Identity: borrowed.PartnerID}},
			WavesB: [][]appcombat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}
	if _, err := fixtureStart(t, f.combat, revision, request, f.pool); err != nil {
		t.Fatal("borrower lends", err)
	}
	exec(t, f.pool, `UPDATE guild_rental_offers SET rent_time=rent_time-interval '2 hours' WHERE lender_id=$1 AND kind='HERO' AND unit_id=$2`, int64(f.borrower.PlayerID), borrowed.PartnerID)
	rentAward := scalar(t, f.pool, `SELECT rent_award FROM guild_rental_offers WHERE lender_id=$1 AND kind='HERO' AND unit_id=$2`, int64(f.borrower.PlayerID), borrowed.PartnerID)
	force := scalar(t, f.pool, `SELECT force FROM guild_rental_offers WHERE lender_id=$1 AND kind='HERO' AND unit_id=$2`, int64(f.borrower.PlayerID), borrowed.PartnerID)
	now, err := (postgres.AuthoritativeTime{Queryer: f.pool}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	appendActivity(t, f.pool, f.borrower, modes.Day(now), 600)
	core := guildCoreService(t, f.pool)
	core.Rental = f.service
	return f, core, rentAward, force, borrowed.PartnerID
}

func assertRentalDeparture(t *testing.T, f rentalFixture, lender identity.PlayerID, rentAward, force, vitalityBefore int64) {
	t.Helper()
	if scalar(t, f.pool, `SELECT count(*) FROM guild_rental_offers WHERE lender_id=$1`, int64(lender)) != 0 {
		t.Fatal("C15 offers remain after departure")
	}
	if scalar(t, f.pool, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='GUILD_RENTAL_DEPARTURE'`, int64(lender)) != 1 {
		t.Fatal("C15 must mail exactly the paid offer")
	}
	want := rentAward + force*2/100
	if got := scalar(t, f.pool, `SELECT a.amount FROM mail_attachments a JOIN mail_records m ON m.mail_uuid=a.mail_uuid WHERE m.recipient_player_id=$1 AND m.source_kind='GUILD_RENTAL_DEPARTURE'`, int64(lender)); got != want {
		t.Fatalf("C15 mail amount %d want %d", got, want)
	}
	if got := guildVitality(t, f.pool, f.offers); got != vitalityBefore+600 {
		t.Fatalf("C5 activity settle vitality %d want %d", got, vitalityBefore+600)
	}
}

func TestI9_9BDepartureClosesRentals(t *testing.T) {
	t.Run("leave", func(t *testing.T) {
		f, core, rentAward, force, _ := rentalDeparture(t)
		before := guildVitality(t, f.pool, f.offers)
		if _, err := core.Leave(ctx, f.borrower, op()); err != nil {
			t.Fatal("leave", err)
		}
		assertRentalDeparture(t, f, f.borrower.PlayerID, rentAward, force, before)
	})
	t.Run("kick", func(t *testing.T) {
		f, core, rentAward, force, _ := rentalDeparture(t)
		before := guildVitality(t, f.pool, f.offers)
		if _, err := core.Kick(ctx, f.lender, f.borrower.PlayerID, op()); err != nil {
			t.Fatal("kick", err)
		}
		assertRentalDeparture(t, f, f.borrower.PlayerID, rentAward, force, before)
	})
	t.Run("dissolve", func(t *testing.T) {
		f := newRentalFixture(t)
		op := opPinned(f.revision)
		if err := f.service.Place(ctx, f.lender, guild.RentalHero, f.hero, op); err != nil {
			t.Fatal("place paid offer", err)
		}
		if err := f.service.Place(ctx, f.lender, guild.RentalHero, f.second, op); err != nil {
			t.Fatal("place idle offer", err)
		}
		locator := d.Locator{DomainKind: "i9-9b-rental", AuthorityScope: fmt.Sprint(f.borrower.LogicalServerID), DomainLocator: fmt.Sprint(f.borrower.PlayerID) + "/dissolve"}
		request := appcombat.StartRequest{Actor: f.borrower, Locator: locator, GenerationRef: "gen-dissolve", StartFingerprint: fingerprint(locator.AuthorityScope + locator.DomainLocator),
			Battle: appcombat.BattleRequest{CampaignType: 1,
				TeamA:  []appcombat.Participant{{Origin: d.Borrowed, Kind: d.HeroActor, Player: f.lender.PlayerID, Identity: f.hero}},
				WavesB: [][]appcombat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}
		if _, err := fixtureStart(t, f.combat, f.revision, request, f.pool); err != nil {
			t.Fatal("borrow paid offer", err)
		}
		exec(t, f.pool, `UPDATE guild_rental_offers SET rent_time=rent_time-interval '2 hours' WHERE lender_id=$1 AND unit_id=$2`, int64(f.lender.PlayerID), f.hero)
		rentAward := scalar(t, f.pool, `SELECT rent_award FROM guild_rental_offers WHERE lender_id=$1 AND unit_id=$2`, int64(f.lender.PlayerID), f.hero)
		force := scalar(t, f.pool, `SELECT force FROM guild_rental_offers WHERE lender_id=$1 AND unit_id=$2`, int64(f.lender.PlayerID), f.hero)
		exec(t, f.pool, `DELETE FROM guild_memberships WHERE guild_id=$1 AND player_id<>$2`, int64(f.offers), int64(f.lender.PlayerID))
		core := guildCoreService(t, f.pool)
		core.Rental = f.service
		if _, err := core.Dissolve(ctx, f.lender, op); err != nil {
			t.Fatal("dissolve", err)
		}
		if scalar(t, f.pool, `SELECT count(*) FROM guild_rental_offers WHERE lender_id=$1`, int64(f.lender.PlayerID)) != 0 {
			t.Fatal("C15 offer remains after dissolve")
		}
		if scalar(t, f.pool, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='GUILD_RENTAL_DEPARTURE'`, int64(f.lender.PlayerID)) != 1 {
			t.Fatal("C15 dissolve must mail only the paid offer")
		}
		if got := scalar(t, f.pool, `SELECT a.amount FROM mail_attachments a JOIN mail_records m ON m.mail_uuid=a.mail_uuid WHERE m.recipient_player_id=$1 AND m.source_kind='GUILD_RENTAL_DEPARTURE'`, int64(f.lender.PlayerID)); got != rentAward+force*2/100 {
			t.Fatalf("C15 dissolve mail amount %d", got)
		}
	})
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
