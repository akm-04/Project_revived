//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"net/http"
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
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/application/guildrental"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/workplace"
	"gxb.local/backend/v2/internal/content/guildrentalpolicy"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"

	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
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
		PartnerMissions: libraryService(p, p),
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
	return f.borrowMode(t, scope, campaignType, campaignType, hero, pet)
}

// borrowMode separates the battle content type from the rent-list mode the
// client sent, the split I9_GUILD_RENTAL_V1 C3/C4 requires.
func (f rentalFixture) borrowMode(t *testing.T, scope string, campaignType, rentalMode int64, hero, pet int64) (appcombat.Started, error) {
	t.Helper()
	locator := d.Locator{DomainKind: "EVENT_CENTRE_BOARD", AuthorityScope: fmt.Sprint(f.borrower.LogicalServerID), DomainLocator: fmt.Sprint(f.borrower.PlayerID) + "/" + scope}
	request := appcombat.StartRequest{Mode: d.ModeEventCentreBoard, Actor: f.borrower, Locator: locator, GenerationRef: "gen-" + scope, StartFingerprint: fingerprint(locator.AuthorityScope + locator.DomainLocator),
		Battle: appcombat.BattleRequest{CampaignType: campaignType, RentalMode: rentalMode,
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
	locator := d.Locator{DomainKind: "EVENT_CENTRE_BOARD", AuthorityScope: fmt.Sprint(f.borrower.LogicalServerID), DomainLocator: fmt.Sprint(f.borrower.PlayerID) + "/" + scope}
	request := appcombat.StartRequest{Mode: d.ModeEventCentreBoard, Actor: f.borrower, Locator: locator, GenerationRef: "gen-" + scope, StartFingerprint: fingerprint(locator.AuthorityScope + locator.DomainLocator),
		Battle: appcombat.BattleRequest{CampaignType: campaignType, RentalMode: campaignType,
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

func TestI9_9BGuildOffersProjectHeroDetail(t *testing.T) {
	f := newRentalFixture(t)
	if err := f.service.Place(ctx, f.lender, guild.RentalHero, f.hero, opPinned(f.revision)); err != nil {
		t.Fatal("place", err)
	}
	// Legacy source rows keep their visible level without the cumulative curve;
	// the stock detail window subtracts totalExp(level-1) from the wire exp.
	exec(t, f.pool, `UPDATE player_heroes SET level=100,exp=0,updated_at=clock_timestamp() WHERE player_id=$1 AND partner_id=$2`, int64(f.lender.PlayerID), f.hero)
	content := contentstore.Store{Queryer: f.pool}
	reads := guildrental.Reader{
		Runner: tx.Runner{DB: f.pool}, Store: guildstore.Store{Queryer: f.pool},
		Characters: guildrentalread.Characters{Content: content}, Profiles: guildrentalread.Profiles{}, Levels: guildrentalread.Levels{},
		Mana: guildrentalread.Mana{}, Privileges: appi5.BaselinePrivilegeProvider{},
		Workplace: workplace.Mode{Store: workplacestore.Store{}}, Policy: f.service.Policy, Content: content,
		Now: func(c context.Context, q tx.Queryer) (time.Time, error) {
			return (postgres.AuthoritativeTime{Queryer: q}).Now(c)
		},
	}
	list, err := reads.GuildOffers(ctx, f.borrower, guild.RentalHero, 0, opPinned(f.revision))
	if err != nil {
		t.Fatal("guild offers", err)
	}
	for _, row := range list.Rows {
		if row.Offer.Unit != f.hero {
			continue
		}
		if row.Hero == nil || row.Hero.Level != 100 || row.Hero.Exp != 1844095 {
			t.Fatalf("detail exp lev=%v exp=%v", row.Hero, row.Hero.Exp)
		}
		if row.Appearance == nil || row.Appearance.OwnerStateVersion != row.Hero.StateVersion {
			t.Fatalf("qualified appearance %+v", row.Appearance)
		}
		if row.TwiceAwakeStage == nil || *row.TwiceAwakeStage != 0 {
			t.Fatalf("raw twice-awake stage %v", row.TwiceAwakeStage)
		}
		return
	}
	t.Fatal("lender offer missing from 2768 projection")
}

// TestI9_9BEmptyListCacheKeysNative drives the production Reader and stock 2768
// dispatcher over both early-empty answers: a campaign type with no borrow row and
// a caller without a guild. Each carries the kind/type/empty-rows key a materialized
// empty list uses; one shared literal would let the client keep another type's list.
func TestI9_9BEmptyListCacheKeysNative(t *testing.T) {
	f := newRentalFixture(t)
	reads := rentalReader(f, contentstore.Store{Queryer: f.pool}, authoritativeObservation)
	readOp := opPinned(f.revision)
	outsider, _ := genuinePlayer(t, f.pool, f.borrower.LogicalServerID)
	dispatcher := stockruntime.GuildRentalDispatcher{Authority: rentalFixtureAuthority{"borrower": f.borrower, "outsider": outsider},
		Service: rentalListOnlyPort{Reader: reads}}

	// The guild has no offers here, so this is the materialized empty list key.
	materialized, err := reads.GuildOffers(ctx, f.borrower, guild.RentalHero, 1, readOp)
	if err != nil {
		t.Fatal("materialized empty list", err)
	}
	if materialized.RentCount == 0 || len(materialized.Rows) != 0 {
		t.Fatalf("materialized empty list key %d rows %d", materialized.RentCount, len(materialized.Rows))
	}

	unlistedKeys := map[int64]int64{}
	for _, requestedType := range []int64{67, 99} {
		list, err := reads.GuildOffers(ctx, f.borrower, guild.RentalHero, requestedType, readOp)
		if err != nil {
			t.Fatal("unlisted type", requestedType, err)
		}
		if list.RentCount == 1 || list.RentCount == 0 || len(list.Rows) != 0 {
			t.Fatalf("unlisted type %d key %d rows %d", requestedType, list.RentCount, len(list.Rows))
		}
		again, err := reads.GuildOffers(ctx, f.borrower, guild.RentalHero, requestedType, readOp)
		if err != nil || again.RentCount != list.RentCount {
			t.Fatalf("unlisted type %d key unstable %d %d %v", requestedType, list.RentCount, again.RentCount, err)
		}
		unlistedKeys[requestedType] = list.RentCount
		response := rentalDispatch(t, dispatcher, "borrower", f.borrower, 2768, map[string]any{"campaign_type": requestedType}, readOp)
		nested := response.Body["guild_rent_heroes"].(map[string]any)
		if response.HTTPStatus != http.StatusOK || len(nested["partners"].([]any)) != 0 ||
			response.Body["rent_count"] != list.RentCount || nested["rent_count"] != list.RentCount {
			t.Fatalf("unlisted type %d wire %d %v", requestedType, response.HTTPStatus, response.Body)
		}
	}
	if unlistedKeys[67] == unlistedKeys[99] {
		t.Fatalf("unlisted types share one cache key %d", unlistedKeys[67])
	}

	guildless, err := reads.GuildOffers(ctx, outsider, guild.RentalHero, 1, readOp)
	if err != nil {
		t.Fatal("guildless list", err)
	}
	if guildless.RentCount != materialized.RentCount || len(guildless.Rows) != 0 {
		t.Fatalf("guildless key %d materialized %d", guildless.RentCount, materialized.RentCount)
	}
	otherType, err := reads.GuildOffers(ctx, outsider, guild.RentalHero, 2, readOp)
	if err != nil || otherType.RentCount == guildless.RentCount {
		t.Fatalf("guildless key ignores the type %d %d %v", guildless.RentCount, otherType.RentCount, err)
	}
	response := rentalDispatch(t, dispatcher, "outsider", outsider, 2768, map[string]any{"campaign_type": int64(1)}, readOp)
	nested := response.Body["guild_rent_heroes"].(map[string]any)
	if response.HTTPStatus != http.StatusOK || len(nested["partners"].([]any)) != 0 ||
		response.Body["rent_count"] != guildless.RentCount || nested["rent_count"] != guildless.RentCount {
		t.Fatalf("guildless wire %d %v", response.HTTPStatus, response.Body)
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
	locator := d.Locator{DomainKind: "EVENT_CENTRE_BOARD", AuthorityScope: fmt.Sprint(f.borrower.LogicalServerID), DomainLocator: fmt.Sprint(f.borrower.PlayerID) + "/collision"}
	request := appcombat.StartRequest{Mode: d.ModeEventCentreBoard, Actor: f.borrower, Locator: locator, GenerationRef: "gen-collision", StartFingerprint: fingerprint(locator.AuthorityScope + locator.DomainLocator),
		Battle: appcombat.BattleRequest{CampaignType: 1, RentalMode: 1,
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

// C17: the shipped Gods Trial borrow row lets START accept a BORROWED actor,
// and the loan is charged once through a START/RESULT pair. Resending START and
// settling RESULT never lend a second time.
func TestI9_9BGodsTrialBorrowedStartAndResult(t *testing.T) {
	f := newRentalFixture(t)
	op := opPinned(f.revision)
	if err := f.service.Place(ctx, f.lender, guild.RentalHero, f.second, op); err != nil {
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
	fight := appgodstrial.Fight{Campaign: campaign, Formation: []int64{own.PartnerID}, RentPlayer: int64(f.lender.PlayerID), RentUnit: f.second}
	uses := func() int64 {
		return scalar(t, f.pool, `SELECT count(*) FROM guild_rental_uses WHERE borrower_id=$1 AND lender_id=$2 AND kind='HERO' AND campaign_type=79 AND unit_id=$3`, int64(f.borrower.PlayerID), int64(f.lender.PlayerID), f.second)
	}
	award := func() int64 {
		return scalar(t, f.pool, `SELECT rent_award FROM guild_rental_offers WHERE lender_id=$1 AND kind='HERO' AND unit_id=$2`, int64(f.lender.PlayerID), f.second)
	}
	mana := libraryAmount(t, f.pool, f.borrower, "mana")
	if _, err := s.Start(ctx, f.borrower, fight, op); err != nil {
		t.Fatal("C17 Gods Trial borrowed START", err)
	}
	charged := mana - libraryAmount(t, f.pool, f.borrower, "mana")
	if charged <= 0 || uses() != 1 || award() != charged {
		t.Fatalf("C17 loan charged mana %d uses %d award %d", charged, uses(), award())
	}
	if _, err := s.Start(ctx, f.borrower, fight, op); err != nil {
		t.Fatal("C17 Gods Trial START replay", err)
	}
	if libraryAmount(t, f.pool, f.borrower, "mana") != mana-charged || uses() != 1 {
		t.Fatal("C17 START replay charged the loan again")
	}
	if _, err := s.Result(ctx, f.borrower, appgodstrial.Result{Campaign: campaign, Star: 1, Formation: []int64{own.PartnerID}}, op); err != nil {
		t.Fatal("C17 Gods Trial borrowed RESULT", err)
	}
	if libraryAmount(t, f.pool, f.borrower, "mana") != mana-charged || uses() != 1 || award() != charged {
		t.Fatal("C17 RESULT charged the loan again")
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
	locator := d.Locator{DomainKind: "EVENT_CENTRE_BOARD", AuthorityScope: fmt.Sprint(f.lender.LogicalServerID), DomainLocator: fmt.Sprint(f.lender.PlayerID) + "/departure"}
	request := appcombat.StartRequest{Mode: d.ModeEventCentreBoard, Actor: f.lender, Locator: locator, GenerationRef: "gen-departure", StartFingerprint: fingerprint(locator.AuthorityScope + locator.DomainLocator),
		Battle: appcombat.BattleRequest{CampaignType: 1, RentalMode: 1,
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
		locator := d.Locator{DomainKind: "EVENT_CENTRE_BOARD", AuthorityScope: fmt.Sprint(f.borrower.LogicalServerID), DomainLocator: fmt.Sprint(f.borrower.PlayerID) + "/dissolve"}
		request := appcombat.StartRequest{Mode: d.ModeEventCentreBoard, Actor: f.borrower, Locator: locator, GenerationRef: "gen-dissolve", StartFingerprint: fingerprint(locator.AuthorityScope + locator.DomainLocator),
			Battle: appcombat.BattleRequest{CampaignType: 1, RentalMode: 1,
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

	// C4: a mode with no policy row refuses at START through Lending.
	if _, err := f.borrowMode(t, "unlisted", 8, 67, f.second, 0); !errors.Is(err, d.ErrLoanRefused) {
		t.Fatal("C4 unlisted mode", err)
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

// rentalContent is both the Reader's policy content and the qualified owner
// read's appearance content; production binds the same content store to both.
type rentalContent interface {
	guildrental.Content
	guildrentalread.CharacterContent
}

func authoritativeObservation(c context.Context, q tx.Queryer) (time.Time, error) {
	return (postgres.AuthoritativeTime{Queryer: q}).Now(c)
}

func observationOffset(delta time.Duration) func(context.Context, tx.Queryer) (time.Time, error) {
	return func(c context.Context, q tx.Queryer) (time.Time, error) {
		at, err := authoritativeObservation(c, q)
		return at.Add(delta), err
	}
}

// rentalReader builds the production Reader composition the canonical wiring
// uses: existing owner reads only, no fixture projection DTOs.
func rentalReader(f rentalFixture, content rentalContent, now func(context.Context, tx.Queryer) (time.Time, error)) guildrental.Reader {
	return guildrental.Reader{
		Runner: tx.Runner{DB: f.pool}, Store: guildstore.Store{Queryer: f.pool},
		Characters: guildrentalread.Characters{Content: content}, Profiles: guildrentalread.Profiles{}, Levels: guildrentalread.Levels{},
		Mana: guildrentalread.Mana{}, Privileges: appi5.BaselinePrivilegeProvider{},
		Workplace: workplace.Mode{Store: workplacestore.Store{}}, Policy: f.service.Policy, Content: content, Now: now,
	}
}

// heroExpFailureContent is the production content store with one policy read
// made to fail, so a 621 answer proves the pet path never asks for a Hero curve.
type heroExpFailureContent struct {
	contentstore.Store
}

func (heroExpFailureContent) HeroExpPolicyTx(context.Context, tx.Queryer, string, int64) ([]character.HeroExpThreshold, error) {
	return nil, errors.New("fixture: hero EXP curve unavailable")
}

var errRentalListOnlyPort = errors.New("fixture: rental proof port wires only list reads")

// rentalListOnlyPort forwards GuildOffers to the production Reader. The other
// port methods are unused by 2768/621 and refuse instead of fabricating data.
type rentalListOnlyPort struct {
	Reader guildrental.Reader
}

func (p rentalListOnlyPort) GuildOffers(c context.Context, a identity.ActorContext, kind guild.RentalKind, requestedType int64, op operation.Context) (guildrental.List, error) {
	return p.Reader.GuildOffers(c, a, kind, requestedType, op)
}
func (rentalListOnlyPort) Place(context.Context, identity.ActorContext, guild.RentalKind, int64, operation.Context) error {
	return errRentalListOnlyPort
}
func (rentalListOnlyPort) Recall(context.Context, identity.ActorContext, guild.RentalKind, int64, operation.Context) (int64, int64, error) {
	return 0, 0, errRentalListOnlyPort
}
func (rentalListOnlyPort) OwnOffers(context.Context, identity.ActorContext, guild.RentalKind, operation.Context) ([]guildrental.Row, error) {
	return nil, errRentalListOnlyPort
}
func (rentalListOnlyPort) UsedPartners(context.Context, identity.ActorContext, operation.Context) ([]int64, error) {
	return nil, errRentalListOnlyPort
}

// rentalFixtureAuthority is a test bearer map to the fixture actors. It is not
// the production login proof and does not claim to be.
type rentalFixtureAuthority map[string]identity.ActorContext

func (a rentalFixtureAuthority) ResolveGameplayBearer(_ context.Context, token string, _ time.Time) (identity.ActorContext, error) {
	actor, ok := a[token]
	if !ok {
		return identity.ActorContext{}, errors.New("fixture: unknown bearer")
	}
	return actor, nil
}

func rentalDispatch(t *testing.T, dispatcher stockruntime.GuildRentalDispatcher, bearer string, actor identity.ActorContext, mid uint16, params map[string]any, op operation.Context) httpedge.Response {
	t.Helper()
	return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: op, MID: mid, Params: params,
		Claims: wire.CredentialClaims{Token: bearer, Region: int64(actor.LogicalServerID)}, ReceivedAt: time.Now().UTC()}})
}

func rentalWirePartner(t *testing.T, body map[string]any, unit int64) map[string]any {
	t.Helper()
	nested, ok := body["guild_rent_heroes"].(map[string]any)
	if !ok {
		t.Fatalf("2768 guild_rent_heroes shape %T", body["guild_rent_heroes"])
	}
	partners, ok := nested["partners"].([]any)
	if !ok {
		t.Fatalf("2768 partners shape %T", nested["partners"])
	}
	for _, raw := range partners {
		partner := raw.(map[string]any)
		if partner["partner_id"] == unit {
			return partner
		}
	}
	t.Fatalf("2768 partner %d missing from %v", unit, partners)
	return nil
}

func rentalWirePet(t *testing.T, body map[string]any, unit int64) map[string]any {
	t.Helper()
	pets, ok := body["pets"].([]any)
	if !ok {
		t.Fatalf("621 pets shape %T", body["pets"])
	}
	for _, raw := range pets {
		pet := raw.(map[string]any)
		if pet["pet_id"] == unit {
			return pet
		}
	}
	t.Fatalf("621 pet %d missing from %v", unit, pets)
	return nil
}

func rentalListRow(t *testing.T, list guildrental.List, kind guild.RentalKind, unit int64) guildrental.Row {
	t.Helper()
	for _, row := range list.Rows {
		if row.Offer.Kind == kind && row.Offer.Unit == unit {
			return row
		}
	}
	t.Fatalf("%s row %d missing from projection", kind, unit)
	return guildrental.Row{}
}

func rentalOfferState(t *testing.T, f rentalFixture) string {
	t.Helper()
	return fmt.Sprint(
		scalar(t, f.pool, `SELECT state_version FROM player_heroes WHERE player_id=$1 AND partner_id=$2`, int64(f.lender.PlayerID), f.hero),
		scalar(t, f.pool, `SELECT current_skin_id FROM player_heroes WHERE player_id=$1 AND partner_id=$2`, int64(f.lender.PlayerID), f.hero),
		scalar(t, f.pool, `SELECT exp FROM player_heroes WHERE player_id=$1 AND partner_id=$2`, int64(f.lender.PlayerID), f.hero),
		scalar(t, f.pool, `SELECT count(*) FROM player_hero_skin_entitlements WHERE player_id=$1 AND partner_id=$2`, int64(f.lender.PlayerID), f.hero),
		scalar(t, f.pool, `SELECT count(*) FROM guild_rental_offers WHERE lender_id IN ($1,$2)`, int64(f.lender.PlayerID), int64(f.petLender.PlayerID)),
		scalar(t, f.pool, `SELECT count(*) FROM guild_rental_uses WHERE borrower_id=$1`, int64(f.borrower.PlayerID)),
	)
}

// TestI9_9BProjectionCacheKeyAndWireNative drives the production Reader and
// stock GuildRentalDispatcher over the actual fixture owner rows: an equipped
// and then expired skin, a nonzero raw awakening stage, EXP and equipment
// changes, a stable key across observation times, and the 621 pet path under a
// content owner whose Hero EXP curve read fails.
func TestI9_9BProjectionCacheKeyAndWireNative(t *testing.T) {
	f := newRentalFixture(t)
	rev := f.revision
	readOp := opPinned(rev)
	if err := f.service.Place(ctx, f.lender, guild.RentalHero, f.hero, readOp); err != nil {
		t.Fatal("place hero offer", err)
	}
	if err := f.service.Place(ctx, f.petLender, guild.RentalPet, f.pet, readOp); err != nil {
		t.Fatal("place pet offer", err)
	}
	content := contentstore.Store{Queryer: f.pool}
	reader := rentalReader(f, content, authoritativeObservation)
	dispatcher := stockruntime.GuildRentalDispatcher{Authority: rentalFixtureAuthority{"borrower": f.borrower},
		Service: rentalListOnlyPort{Reader: reader}}

	readHero := func(t *testing.T) (guildrental.List, map[string]any) {
		t.Helper()
		list, err := reader.GuildOffers(ctx, f.borrower, guild.RentalHero, 1, readOp)
		if err != nil {
			t.Fatal("2768 projection", err)
		}
		response := rentalDispatch(t, dispatcher, "borrower", f.borrower, 2768, map[string]any{"campaign_type": int64(1)}, readOp)
		if response.HTTPStatus != http.StatusOK {
			t.Fatalf("2768 wire status %d body %v", response.HTTPStatus, response.Body)
		}
		return list, response.Body
	}

	baseline, baselineBody := readHero(t)
	baselineRow := rentalListRow(t, baseline, guild.RentalHero, f.hero)
	if baselineRow.Hero == nil || baselineRow.Hero.Level != 1 || baselineRow.Appearance == nil ||
		baselineRow.Appearance.CurrentSkinID != 0 || len(baselineRow.Appearance.Skins) != 0 ||
		baselineRow.TwiceAwakeStage == nil || *baselineRow.TwiceAwakeStage != 0 {
		t.Fatalf("baseline real owner projection %+v", baselineRow)
	}
	if !baselineRow.CanRent || baselineRow.HaveRent {
		t.Fatalf("baseline admission can=%v have=%v", baselineRow.CanRent, baselineRow.HaveRent)
	}
	baselinePartner := rentalWirePartner(t, baselineBody, f.hero)
	nestedRentCount, _ := baselineBody["guild_rent_heroes"].(map[string]any)["rent_count"].(int64)
	if baseline.RentCount == 0 || baselineBody["rent_count"] != baseline.RentCount || nestedRentCount != baseline.RentCount ||
		baselinePartner["table_id"] != int64(genuineHeroTable) || baselinePartner["player_id"] != int64(f.lender.PlayerID) ||
		baselinePartner["exp"] != baselineRow.Hero.Exp || baselinePartner["current_skin_id"] != int64(0) ||
		baselinePartner["twice_awake_stage"] != int64(0) || baselinePartner["rent_need_mana"] != baselineRow.Price ||
		baselinePartner["can_rent"] != true || baselinePartner["have_rent"] != false {
		t.Fatalf("baseline wire row %v", baselinePartner)
	}
	if tutors, ok := baselineBody["tutor_rent_heroes"].([]any); !ok || len(tutors) != 0 {
		t.Fatalf("baseline tutor list %v", baselineBody["tutor_rent_heroes"])
	}

	// The borrower grows first so the offered girl can level and keep admission.
	compositeLevel(t, f.pool, f.borrower, rev, 100)
	heroes := genuineHeroService(f.pool)
	must(heroes.UseExpItems(ctx, f.lender, f.hero, []appi5.HeroExpItemDebit{{ItemID: heroExpItem, Count: 5}}, opPinned(rev)))(t, "hero exp")
	experience, experienceBody := readHero(t)
	experienceRow := rentalListRow(t, experience, guild.RentalHero, f.hero)
	if experience.RentCount == baseline.RentCount || !experienceRow.CanRent {
		t.Fatalf("progression key %d baseline %d can=%v", experience.RentCount, baseline.RentCount, experienceRow.CanRent)
	}
	if experienceRow.Hero.Level == baselineRow.Hero.Level && experienceRow.Hero.Exp == baselineRow.Hero.Exp {
		t.Fatalf("progression did not change the projection %+v", experienceRow.Hero)
	}
	if rentalWirePartner(t, experienceBody, f.hero)["exp"] != experienceRow.Hero.Exp ||
		rentalWirePartner(t, experienceBody, f.hero)["lev"] != experienceRow.Hero.Level {
		t.Fatalf("progression wire %v", rentalWirePartner(t, experienceBody, f.hero))
	}

	// A genuine content skin item: SkinOn validates item, model and origin table.
	must(heroes.SkinOn(ctx, f.lender, f.hero, genuineSkinItem, opPinned(rev)))(t, "skin unlock")
	must(heroes.SkinOn(ctx, f.lender, f.hero, genuineSkinItem, opPinned(rev)))(t, "skin wear")
	skinned, skinnedBody := readHero(t)
	skinnedRow := rentalListRow(t, skinned, guild.RentalHero, f.hero)
	skinnedWire := rentalWirePartner(t, skinnedBody, f.hero)
	if skinned.RentCount == experience.RentCount || skinnedRow.Appearance.CurrentSkinID != 40001001 ||
		len(skinnedRow.Appearance.Skins) != 1 || skinnedRow.Appearance.OwnerStateVersion != skinnedRow.Hero.StateVersion {
		t.Fatalf("skin projection %+v", skinnedRow.Appearance)
	}
	if skinnedWire["current_skin_id"] != int64(40001001) || skinnedWire["skin_ids"].(map[string]any)["40001001"] != int64(-1) {
		t.Fatalf("skin wire %v", skinnedWire)
	}

	// The same durable entitlement past its deadline is fixture data; no clock moves.
	exec(t, f.pool, `UPDATE player_hero_skin_entitlements SET expires_at=$3 WHERE player_id=$1 AND partner_id=$2 AND model_id=$4`,
		int64(f.lender.PlayerID), f.hero, time.Now().UTC().Add(-time.Hour), int64(40001001))
	expired, expiredBody := readHero(t)
	expiredRow := rentalListRow(t, expired, guild.RentalHero, f.hero)
	expiredWire := rentalWirePartner(t, expiredBody, f.hero)
	if expired.RentCount == skinned.RentCount || expiredRow.Appearance.CurrentSkinID != 0 || len(expiredRow.Appearance.Skins) != 0 {
		t.Fatalf("expired skin projection %+v", expiredRow.Appearance)
	}
	if expiredWire["current_skin_id"] != int64(0) || len(expiredWire["skin_ids"].(map[string]any)) != 0 {
		t.Fatalf("expired skin wire %v", expiredWire)
	}

	// A valid version-2 awakening facet (nonzero raw stage) through the owner store.
	awakeningTx, err := f.pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer awakeningTx.Rollback(ctx)
	birthStore := characterstore.RawAwakeningStore{}
	birth, err := birthStore.ReadRawAwakeningBirthTx(ctx, awakeningTx, character.HeroRef{PlayerID: f.lender.PlayerID, PartnerID: f.hero})
	if err != nil {
		t.Fatal("raw awakening birth", err)
	}
	birth.Version++
	birth.RawStage = 2
	birth.UpdatedAt = time.Now().UTC()
	birth.ProducerReference = "I9_AWAKENING_MISSIONS_V1/native-proof03"
	if err = birthStore.SaveRawAwakeningTx(ctx, awakeningTx, birth, birth.Version-1); err != nil {
		t.Fatal("raw awakening save", err)
	}
	if err = awakeningTx.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	awakened, awakenedBody := readHero(t)
	awakenedRow := rentalListRow(t, awakened, guild.RentalHero, f.hero)
	if awakened.RentCount == expired.RentCount || awakenedRow.TwiceAwakeStage == nil || *awakenedRow.TwiceAwakeStage != 2 ||
		rentalWirePartner(t, awakenedBody, f.hero)["twice_awake_stage"] != int64(2) {
		t.Fatalf("awakening key %d prev %d stage %v", awakened.RentCount, expired.RentCount, awakenedRow.TwiceAwakeStage)
	}

	// Unchanged real owner state at a different observation time keeps the key and writes nothing.
	before := rentalOfferState(t, f)
	later := rentalReader(f, content, observationOffset(2*time.Hour))
	laterList, err := later.GuildOffers(ctx, f.borrower, guild.RentalHero, 1, readOp)
	if err != nil {
		t.Fatal("future observation read", err)
	}
	if laterList.RentCount != awakened.RentCount {
		t.Fatalf("observation time changed key %d vs %d", laterList.RentCount, awakened.RentCount)
	}
	if after := rentalOfferState(t, f); after != before {
		t.Fatalf("read mutated owner state\nbefore %s\nafter  %s", before, after)
	}

	// The pet path is 621 with a content owner that fails the Hero EXP curve.
	failingContent := heroExpFailureContent{Store: contentstore.Store{Queryer: f.pool}}
	petReader := rentalReader(f, failingContent, authoritativeObservation)
	petDispatcher := stockruntime.GuildRentalDispatcher{Authority: rentalFixtureAuthority{"borrower": f.borrower},
		Service: rentalListOnlyPort{Reader: petReader}}
	basePets, err := petReader.GuildOffers(ctx, f.borrower, guild.RentalPet, 0, readOp)
	if err != nil {
		t.Fatalf("621 pet list under failing Hero curve: %v", err)
	}
	basePetResponse := rentalDispatch(t, petDispatcher, "borrower", f.borrower, 621, map[string]any{"load_place": int64(0)}, readOp)
	if basePetResponse.HTTPStatus != http.StatusOK || basePetResponse.Body["rent_count"] != basePets.RentCount {
		t.Fatalf("621 baseline %d %v", basePetResponse.HTTPStatus, basePetResponse.Body)
	}
	basePetRow := rentalListRow(t, basePets, guild.RentalPet, f.pet)
	basePetWire := rentalWirePet(t, basePetResponse.Body, f.pet)
	if basePetRow.Pet == nil || basePetWire["table_id"] != int64(genuinePetTable) || basePetWire["player_id"] != int64(f.petLender.PlayerID) ||
		basePetWire["lev"] != basePetRow.Pet.Level || basePetWire["exp"] != basePetRow.Pet.Exp {
		t.Fatalf("621 baseline row %v", basePetWire)
	}

	// A real Pet EXP command changes the pet and must change the 621 key.
	grantGenuine(t, f.pool, f.petLender, rev, "pet exp proof", []grant.Line{{Kind: grant.StackItem, ItemID: petExpItem, Amount: 5}})
	pets := genuinePetService(f.pool)
	must(pets.UseExpItems(ctx, f.petLender, f.pet, []appi5.PetExpItemDebit{{ItemID: petExpItem, Count: 1}}, opPinned(rev)))(t, "pet exp")
	changedPets, err := petReader.GuildOffers(ctx, f.borrower, guild.RentalPet, 0, readOp)
	if err != nil {
		t.Fatal("621 changed pet list", err)
	}
	changedPetResponse := rentalDispatch(t, petDispatcher, "borrower", f.borrower, 621, map[string]any{"load_place": int64(0)}, readOp)
	if changedPets.RentCount == basePets.RentCount || changedPetResponse.Body["rent_count"] != changedPets.RentCount {
		t.Fatalf("621 pet detail did not invalidate key %d vs %d", changedPets.RentCount, basePets.RentCount)
	}
	changedPetRow := rentalListRow(t, changedPets, guild.RentalPet, f.pet)
	changedPetWire := rentalWirePet(t, changedPetResponse.Body, f.pet)
	if changedPetRow.Pet.Exp == basePetRow.Pet.Exp && changedPetRow.Pet.Level == basePetRow.Pet.Level {
		t.Fatalf("621 pet command did not change pet %+v", changedPetRow.Pet)
	}
	if changedPetWire["exp"] != changedPetRow.Pet.Exp || changedPetWire["lev"] != changedPetRow.Pet.Level ||
		changedPetWire["table_id"] != int64(genuinePetTable) || changedPetWire["player_id"] != int64(f.petLender.PlayerID) {
		t.Fatalf("621 changed wire %v", changedPetWire)
	}

	// Negative control: the same failing content owner refuses the Hero list.
	heroFailDispatcher := stockruntime.GuildRentalDispatcher{Authority: rentalFixtureAuthority{"borrower": f.borrower},
		Service: rentalListOnlyPort{Reader: rentalReader(f, failingContent, authoritativeObservation)}}
	if failed := rentalDispatch(t, heroFailDispatcher, "borrower", f.borrower, 2768, map[string]any{"campaign_type": int64(1)}, readOp); failed.HTTPStatus != http.StatusInternalServerError || failed.Body["error_code"] != int64(35028) {
		t.Fatalf("2768 failing Hero curve returned %d %v", failed.HTTPStatus, failed.Body)
	}
}
