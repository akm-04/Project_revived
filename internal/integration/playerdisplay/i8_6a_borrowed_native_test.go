//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/combatstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	combat "gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const fixtureRentalCapability = "FIXTURE_GUILD_RENTAL_V1"

type rentalOffer struct {
	lender   identity.PlayerID
	kind     d.ActorKind
	identity int64
}

// fixtureLender is the I8 test lending capability (D22g): a fixed offer table
// and the stock rent_need_mana cost debited from the borrower through I5.
type fixtureLender struct {
	offers map[rentalOffer]int64
	values i5.CrossOwner
}

func (l fixtureLender) LendTx(c context.Context, t tx.Tx, scope ca.CoherentReadScope, loan combat.Loan) (d.Provenance, error) {
	cost, offered := l.offers[rentalOffer{loan.Lender, loan.Kind, loan.Identity}]
	if !offered {
		return d.Provenance{}, d.ErrLoanRefused
	}
	if _, err := l.values.DebitScalarTx(c, t, loan.Borrower, "mana", cost, scope.ObservedAt); err != nil {
		return d.Provenance{}, fmt.Errorf("%w: %w", d.ErrLoanRefused, err)
	}
	return d.Provenance{Capability: fixtureRentalCapability, Reference: fmt.Sprintf("%s/%d/%d", loan.Kind, loan.Lender, loan.Identity)}, nil
}

type borrowFixture struct {
	pool     *pg.Pool
	rev      string
	service  combat.Service
	borrower identity.ActorContext
	lender   identity.ActorContext
	own      int64
	hero     int64
	pet      int64
}

const heroRent, petRent = 3000, 2000

// newBorrowFixture: a lender with a genuine Hero and Pet offered for rent and a
// borrower with its own Hero and mana, both built by producer commands.
func newBorrowFixture(t *testing.T) borrowFixture {
	pool := pool(t)
	server := rankingServer(t, pool)
	f := borrowFixture{pool: pool}
	f.lender, f.rev = genuinePlayer(t, pool, server)
	f.borrower, _ = genuinePlayer(t, pool, server)
	cs := contentstore.Store{Queryer: pool}
	def := must(cs.HeroNormalSummonTx(ctx, pool, f.rev, genuineHeroTable))(t, "summon policy")
	heroes := genuineHeroService(pool)
	for _, a := range []identity.ActorContext{f.lender, f.borrower} {
		grantGenuine(t, pool, a, f.rev, "resources", genuineResources(t, pool, f.rev, []int64{genuineHeroTable}))
	}
	f.hero = must(heroes.SummonNormal(ctx, f.lender, genuineHeroTable, int64(def.Template.FragmentItemID), def.FragmentCount, op()))(t, "lender summon").PartnerID
	f.own = must(heroes.SummonNormal(ctx, f.borrower, genuineHeroTable, int64(def.Template.FragmentItemID), def.FragmentCount, op()))(t, "borrower summon").PartnerID
	egg := must(cs.PetAcquisitionTx(ctx, pool, f.rev, genuinePetTable))(t, "pet policy").EggItemID
	grantGenuine(t, pool, f.lender, f.rev, "pet egg", []grant.Line{{Kind: grant.StackItem, ItemID: egg, Amount: 1}})
	pets := genuinePetService(pool)
	f.pet = must(pets.Summon(ctx, f.lender, genuinePetTable, op()))(t, "pet summon").PetID
	must(pets.CleanCD(ctx, f.lender, f.pet, op()))(t, "pet hatch")
	f.service = combatService(t, pool)
	f.service.Inputs.Lending = fixtureLender{values: i5.CrossOwner{Store: i5store.Store{Queryer: pool}}, offers: map[rentalOffer]int64{
		{f.lender.PlayerID, d.HeroActor, f.hero}: heroRent, {f.lender.PlayerID, d.PetActor, f.pet}: petRent}}
	return f
}

func (f borrowFixture) locator(scope string) d.Locator {
	return d.Locator{DomainKind: "i8-6a-fixture-mode", AuthorityScope: scope, DomainLocator: fmt.Sprint(f.borrower.PlayerID)}
}

// request fights the borrower's Hero beside the rented Hero and Pet.
func (f borrowFixture) request(scope string) combat.StartRequest {
	locator := f.locator(scope)
	return combat.StartRequest{Actor: f.borrower, Locator: locator, GenerationRef: "fixture-generation-1", StartFingerprint: fingerprint(locator.AuthorityScope + locator.DomainLocator),
		Battle: combat.BattleRequest{CampaignType: 1,
			TeamA:  []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: f.borrower.PlayerID, Identity: f.own}, {Origin: d.Borrowed, Kind: d.HeroActor, Player: f.lender.PlayerID, Identity: f.hero}},
			PetsA:  []combat.Participant{{Origin: d.Borrowed, Kind: d.PetActor, Player: f.lender.PlayerID, Identity: f.pet}},
			WavesB: [][]combat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}
}

func (f borrowFixture) snapshot(t *testing.T, attempt d.Attempt) ([]byte, d.Snapshot) {
	t.Helper()
	raw := must((combatstore.Store{}).ReadSnapshotTx(ctx, f.pool, attempt.SnapshotHash))(t, "snapshot")
	return raw, must(d.DecodeSnapshot(raw, attempt.SnapshotHash))(t, "decode")
}

func (f borrowFixture) attempts(t *testing.T) int64 {
	return scalar(t, f.pool, `SELECT count(*) FROM combat_attempts WHERE domain_kind='i8-6a-fixture-mode' AND domain_locator=$1`, fmt.Sprint(f.borrower.PlayerID))
}

func (f borrowFixture) heroVersion(t *testing.T) int64 {
	return scalar(t, f.pool, `SELECT state_version FROM player_heroes WHERE player_id=$1 AND partner_id=$2`, int64(f.lender.PlayerID), f.hero)
}

func (f borrowFixture) petVersion(t *testing.T) int64 {
	return scalar(t, f.pool, `SELECT state_version FROM player_pets WHERE player_id=$1 AND pet_id=$2`, int64(f.lender.PlayerID), f.pet)
}

// H-40, H-07, H-08 and cost once through the fixture lending capability.
func TestI8_6ABorrowedActorsNative(t *testing.T) {
	f := newBorrowFixture(t)
	s := f.service
	mana := libraryAmount(t, f.pool, f.borrower, "mana")
	borrowerHeroes := scalar(t, f.pool, `SELECT count(*) FROM player_heroes WHERE player_id=$1`, int64(f.borrower.PlayerID))

	// B6-01: the rented Hero and Pet freeze in the lender's own view with the
	// capability provenance; the rent is paid once and a replay pays nothing.
	request := f.request("borrowed")
	started := must(fixtureStart(t, s, f.rev, request, f.pool))(t, "borrowed START")
	raw, snapshot := f.snapshot(t, started.Attempt)
	hero, pet := snapshot.Battle.TeamA[1], snapshot.Battle.PetsA[0]
	for _, a := range []d.Actor{hero, pet} {
		if a.Origin != d.Borrowed || a.Player != int64(f.lender.PlayerID) || a.Provenance == nil || a.Provenance.Capability != fixtureRentalCapability || a.OwnerStateVersion <= 0 || len(a.BattleTotals) == 0 {
			t.Fatalf("B6-01 borrowed actor %+v", a)
		}
	}
	if snapshot.Battle.TeamA[0].Origin != d.OwnedSelf || len(snapshot.Players) != 2 || hero.OwnerStateVersion != f.heroVersion(t) {
		t.Fatal("B6-01 players or lender view", snapshot.Players)
	}
	if got := libraryAmount(t, f.pool, f.borrower, "mana"); got != mana-heroRent-petRent {
		t.Fatal("B6-01 rent", mana, got)
	}
	again := must(fixtureStart(t, s, f.rev, request, f.pool))(t, "replay")
	if !again.Replayed || again.Attempt.ID != started.Attempt.ID || libraryAmount(t, f.pool, f.borrower, "mana") != mana-heroRent-petRent {
		t.Fatal("B6-01 replay must not rent again")
	}
	if scalar(t, f.pool, `SELECT count(*) FROM player_heroes WHERE player_id=$1`, int64(f.borrower.PlayerID)) != borrowerHeroes ||
		scalar(t, f.pool, `SELECT count(*) FROM player_pets WHERE player_id=$1`, int64(f.borrower.PlayerID)) != 0 {
		t.Fatal("B6-01 the borrower must never own the rented actors")
	}

	// B6-02 (H-40): fake rent ids, a self loan, a borrowed enemy, two rented
	// Heroes and an unaffordable rent all refuse START with zero writes.
	mana = libraryAmount(t, f.pool, f.borrower, "mana")
	before := f.attempts(t)
	refusals := map[string]struct {
		mutate func(*combat.StartRequest)
		want   error
	}{
		"unoffered hero": {func(r *combat.StartRequest) { r.Battle.TeamA[1].Identity = f.hero + 1000 }, d.ErrLoanRefused},
		"fake lender":    {func(r *combat.StartRequest) { r.Battle.PetsA[0].Player = f.lender.PlayerID + 1000000 }, d.ErrLoanRefused},
		"self loan": {func(r *combat.StartRequest) {
			r.Battle.TeamA[1] = combat.Participant{Origin: d.Borrowed, Kind: d.HeroActor, Player: f.borrower.PlayerID, Identity: f.own}
		}, d.ErrInvalid},
		"borrowed enemy": {func(r *combat.StartRequest) {
			r.Battle.WavesB[0] = append(r.Battle.WavesB[0], r.Battle.TeamA[1])
			r.Battle.TeamA = r.Battle.TeamA[:1]
		}, d.ErrInvalid},
		"two rented heroes": {func(r *combat.StartRequest) { r.Battle.TeamA = append(r.Battle.TeamA, r.Battle.TeamA[1]) }, d.ErrInvalid},
	}
	for name, refusal := range refusals {
		r := f.request("refused-" + name)
		r.Battle.TeamA = append([]combat.Participant{}, r.Battle.TeamA...)
		refusal.mutate(&r)
		if _, err := fixtureStart(t, s, f.rev, r, f.pool); !errors.Is(err, refusal.want) {
			t.Fatal("B6-02", name, err)
		}
	}
	poor := s
	poor.Inputs.Lending = fixtureLender{values: i5.CrossOwner{Store: i5store.Store{Queryer: f.pool}}, offers: map[rentalOffer]int64{{f.lender.PlayerID, d.HeroActor, f.hero}: mana + 1, {f.lender.PlayerID, d.PetActor, f.pet}: petRent}}
	if _, err := fixtureStart(t, poor, f.rev, f.request("refused-unaffordable"), f.pool); !errors.Is(err, d.ErrLoanRefused) {
		t.Fatal("B6-02 unaffordable", err)
	}
	if f.attempts(t) != before || libraryAmount(t, f.pool, f.borrower, "mana") != mana {
		t.Fatal("B6-02 a refused loan wrote", f.attempts(t), before, libraryAmount(t, f.pool, f.borrower, "mana"))
	}

	// B6-03: without a lending capability BORROWED is unavailable.
	closed := s
	closed.Inputs.Lending = nil
	if _, err := fixtureStart(t, closed, f.rev, f.request("no-capability"), f.pool); !errors.Is(err, d.ErrProviderUnavailable) {
		t.Fatal("B6-03", err)
	}

	// B6-04 (H-07) and B6-05 (H-08): lender Hero and Pet progress after START;
	// the attempt resolves and settles from the frozen snapshot, and settlement
	// leaves the lender untouched.
	heroes, pets := genuineHeroService(f.pool), genuinePetService(f.pool)
	must(heroes.UseExpItems(ctx, f.lender, f.hero, []i5.HeroExpItemDebit{{ItemID: heroExpItem, Count: 5}}, op()))(t, "lender hero exp")
	must(pets.UseExpItems(ctx, f.lender, f.pet, []i5.PetExpItemDebit{{ItemID: petExpItem, Count: 5}}, op()))(t, "lender pet exp")
	heroVersion, petVersion := f.heroVersion(t), f.petVersion(t)
	if heroVersion == hero.OwnerStateVersion {
		t.Fatal("B6-04 lender edit did not advance the hero")
	}
	resolved := must(s.Resolve(ctx, op(), started.Attempt.ID))(t, "resolve")
	stored, _ := f.snapshot(t, started.Attempt)
	if string(stored) != string(raw) || resolved.Resolution.SnapshotHash != started.Attempt.SnapshotHash {
		t.Fatal("B6-04 frozen snapshot changed")
	}
	settled := must(fixtureTerminal(t, s, f.pool, f.borrower, request.Locator, "i8-6a-receipt", f.pool, opPinned(f.rev)))(t, "terminal")
	if settled.Attempt.State != d.Terminal || f.heroVersion(t) != heroVersion || f.petVersion(t) != petVersion {
		t.Fatal("B6-05 settlement touched the lender")
	}
	fresh := must(fixtureStart(t, s, f.rev, f.request("after-edit"), f.pool))(t, "fresh START")
	if _, after := f.snapshot(t, fresh.Attempt); after.Battle.TeamA[1].OwnerStateVersion != heroVersion {
		t.Fatal("B6-04 a new START must freeze the edited lender hero")
	}
}

// B6-06: lender progression races the borrower's START; each START freezes a
// committed lender version (before or after the edit), never a torn one.
func TestI8_6ALenderMutationRacesStartNative(t *testing.T) {
	f := newBorrowFixture(t)
	rule := must((contentstore.Store{}).ResolveProgressionPolicyTx(ctx, f.pool, f.rev))(t, "progression")
	grantGenuine(t, f.pool, f.lender, f.rev, "lender level", []grant.Line{{Kind: grant.PlayerExp, Amount: rule.Rows[98].TotalExp}})
	heroes := genuineHeroService(f.pool)
	for round := range 3 {
		before := f.heroVersion(t)
		var wait sync.WaitGroup
		var started combat.Started
		var startErr, editErr error
		wait.Add(2)
		go func() {
			defer wait.Done()
			started, startErr = fixtureStart(t, f.service, f.rev, f.request(fmt.Sprint("race-", round)), f.pool)
		}()
		go func() {
			defer wait.Done()
			_, editErr = heroes.UseExpItems(ctx, f.lender, f.hero, []i5.HeroExpItemDebit{{ItemID: heroExpItem, Count: 1}}, op())
		}()
		wait.Wait()
		if startErr != nil || editErr != nil {
			t.Fatal("race", round, startErr, editErr)
		}
		after := f.heroVersion(t)
		_, snapshot := f.snapshot(t, started.Attempt)
		if frozen := snapshot.Battle.TeamA[1].OwnerStateVersion; after == before || frozen != before && frozen != after {
			t.Fatal("race froze an uncommitted lender version", round, before, frozen, after)
		}
	}
}
