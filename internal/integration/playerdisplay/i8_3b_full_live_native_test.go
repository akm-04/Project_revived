//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/combatresolver"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/combatstore"
	"gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/conquerstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/elementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/inscriptionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/rankingstore"
	"gxb.local/backend/v2/internal/adapters/postgres/spiritstore"
	book "gxb.local/backend/v2/internal/application/bookskill"
	boot "gxb.local/backend/v2/internal/application/bootstrap"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	pet "gxb.local/backend/v2/internal/application/characterpet"
	"gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
	dorm "gxb.local/backend/v2/internal/application/dormhouse"
	element "gxb.local/backend/v2/internal/application/elementequipment"
	gen "gxb.local/backend/v2/internal/application/generation"
	evolution "gxb.local/backend/v2/internal/application/heroevolution"
	"gxb.local/backend/v2/internal/application/i5"
	inscription "gxb.local/backend/v2/internal/application/inscription"
	library "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/content/combatcorpus"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
)

// I8-3B genuine content: the Normal Hero, its permanent skin item, the Function
// 38 starter egg's Pet and the hero EXP item the owner levels with.
const (
	genuineHeroTable = 10001001
	genuineSkinItem  = 50001409
	genuinePetTable  = 10030001
	heroExpItem      = 50005182
	petExpItem       = 50001089
	evolutionStone   = 40001001
)

// genuinePlayer creates the shared identity rows (I4 MID1 shapes, directory at
// level 1) and runs the production MID1 persistence contributor list; every
// later owner fact is written by a producer command or the I5 grant owner.
func genuinePlayer(t *testing.T, p *pg.Pool, server identity.LogicalServerID) (identity.ActorContext, string) {
	t.Helper()
	rev := installed(t, p)
	account, session, context := uuid(), uuid(), uuid()
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	var pid int64
	if err = tr.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=$1 RETURNING next_player_id-1`, int64(server)).Scan(&pid); err != nil {
		t.Fatal(err)
	}
	for _, row := range []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, []any{account.String(), account.String()}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,$3,clock_timestamp(),'i8-3b-genuine')`, []any{pid, account.String(), int64(server)}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'i8-3b-genuine',clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, []any{session.String(), account.String()}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1,$2,$3,$4,$5,1,clock_timestamp())`, []any{context.String(), session.String(), account.String(), int64(server), pid}},
		{`INSERT INTO player_directory_profiles(player_id,name,lev,vip,avatar_id,avatar_frame_id,conquer_lev,conquer_loop_id,state_version,created_at,updated_at)VALUES($1,'',1,0,110001001,0,0,1,1,clock_timestamp(),clock_timestamp())`, []any{pid}},
	} {
		if _, err = tr.Exec(ctx, row.sql, row.args...); err != nil {
			t.Fatal(err)
		}
	}
	accountID, _ := identity.AccountIDFrom(account)
	sessionID, _ := identity.SessionIDFrom(session)
	contextID, _ := identity.ContextIDFrom(context)
	o := opPinned(rev)
	o.StartedAt = time.Now().UTC().Add(-time.Minute)
	b := logicalserver.BootstrapContext{AccountID: accountID, SessionID: sessionID, LogicalServerID: server, PlayerID: identity.PlayerID(pid), Operation: o, BootstrapProfileVersion: "I8_3B_GENUINE_FIXTURE"}
	cs := contentstore.Store{Queryer: p}
	privileges := commerceprivilege.Provider{Store: commerceprivilegestore.Store{}, Content: cs}
	for _, c := range []boot.CharacterBootstrapPersistenceContributor{i5store.PlayerCoreBootstrapContributor{}, i5store.EconomyOwnerBootstrapContributor{Content: cs, Privileges: privileges},
		characterstore.BootstrapContributor{}, characterstore.PetBootstrapContributor{}, characterstore.SavedPresetBootstrapContributor{}, characterstore.PracticeBootstrapContributor{},
		librarystore.BootstrapContributor{}, achievementstore.BootstrapContributor{Revision: rev}, rankingstore.BootstrapContributor{}, dormstore.BootstrapContributor{Revision: rev},
		bookstore.BootstrapContributor{Revision: rev}, coursestore.BootstrapContributor{Revision: rev}, inscriptionstore.BootstrapContributor{Revision: rev}, i5store.InscriptionCertificateBootstrap{},
		elementstore.BootstrapContributor{Revision: rev}, spiritstore.BootstrapContributor{Revision: rev}, conquerstore.BootstrapContributor{Revision: rev}} {
		if err = c.PersistCharacterBootstrap(ctx, tr, b); err != nil {
			t.Fatal(c.Name(), err)
		}
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	return identity.ActorContext{AccountID: accountID, AccountUID: identity.AccountUID(account.String()), SessionID: sessionID, ContextID: contextID, LogicalServerID: server, PlayerID: identity.PlayerID(pid),
		ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}, rev
}

// genuineGrants is the production I5 composition (cmd/gxb-api main_postgres).
func genuineGrants(p *pg.Pool) i5.Service {
	cs := contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p, StackUsage: dorm.FurnitureUsage{Owner: dormstore.Store{}, Content: cs}}
	return i5.Service{Runner: tx.Runner{DB: p}, Store: values, Content: cs, Privileges: commerceprivilege.Provider{Store: commerceprivilegestore.Store{}, Content: cs}, Functions: i5.PetStarterFunctionAnnouncements{},
		Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i8-3b-native-fixture-only-secret-00")}
}

// grantGenuine settles acquisition through the I5 owner. D16(c): only line
// kinds production already settles; the source is a labelled fixture.
func grantGenuine(t *testing.T, p *pg.Pool, a identity.ActorContext, rev, name string, lines []grant.Line) {
	t.Helper()
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	o := opPinned(rev)
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i8-3b-fixture", Operation: "actual-I5-acquisition", BusinessKey: fmt.Sprintf("%d/%s", a.PlayerID, name), Occurrence: o.ID.String(), PolicyVersion: "i8-3b-fixture-v1"}, Lines: lines}
	if _, err = genuineGrants(p).SettleGrantTx(ctx, tr, a, plan, o, i5.GrantTxOptions{}); err != nil {
		t.Fatal(name, err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

// genuineHeroService is the production Hero composition (cmd/gxb-api main_postgres).
func genuineHeroService(p *pg.Pool) hero.Service {
	runner := tx.Runner{DB: p}
	store, content := characterstore.Store{Queryer: p}, contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p, StackUsage: dorm.FurnitureUsage{Owner: dormstore.Store{}, Content: contentstore.Store{Queryer: p}}}
	grants := genuineGrants(p)
	return hero.Service{FreshFacets: hero.FreshFacetChain{librarystore.Store{}, dormstore.Store{}, coursestore.Store{}, inscriptionstore.Store{}, elementstore.Store{}, spiritstore.Store{}, characterstore.EvolutionStore{}, characterstore.RawAwakeningStore{}},
		Runner: runner, Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Store: store, Fencer: values, Content: content, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p},
		ProgressionStore: store, Progression: content, Economy: i5.HeroProgressionDebiter{Store: values, Content: content}, Backpack: values, AcquisitionStore: store, Acquisition: content,
		MaterialCosts: i5.MaterialCostDebiter{Store: values, Content: content}, PlayerLevel: i5.CrossOwner{Store: values}, CollectionAdmission: hero.CatalogCollectionAdmission{Content: content},
		Equipment: content, EquipmentResources: i5.HeroEquipmentResourceDebiter{Store: values, Content: content}, Fumo: content, Promotion: content, PromotionResources: grants, StrictRestoration: grants,
		MaxHeroColorPolicy: i5.PreservationMaxHeroColorProvider{}, RestorationModifier: ca.IdentityRestorationModifier{}, RosterProjection: content, AppearanceStore: store, Appearance: content,
		AppearanceMutationStore: store, AppearanceMutationContent: content, LIVEMutationStore: store}
}

// genuinePetService is the production Pet composition (cmd/gxb-api main_postgres).
func genuinePetService(p *pg.Pool) pet.Service {
	runner := tx.Runner{DB: p}
	store, content := characterstore.Store{Queryer: p}, contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p, StackUsage: dorm.FurnitureUsage{Owner: dormstore.Store{}, Content: contentstore.Store{Queryer: p}}}
	grants := genuineGrants(p)
	return pet.Service{Runner: runner, Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Store: store, Fencer: values, Content: content, Progression: content,
		Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Acquisition: i5.PetAcquisitionDebiter{Store: values, Content: content}, MaterialCosts: i5.MaterialCostDebiter{Store: values, Content: content},
		Scalar: i5.CrossOwner{Store: values}, PetExp: i5.PetExpDebiter{Store: values, Content: content}, Equipment: content, EquipmentResources: i5.HeroEquipmentResourceDebiter{Store: values, Content: content},
		Promotion: content, PromotionResources: grants, StrictRestoration: grants, RestorationModifier: ca.IdentityRestorationModifier{}, AppearanceStore: store, Appearance: content, AppearanceMutationStore: store}
}

func must[T any](value T, err error) func(t *testing.T, step string) T {
	return func(t *testing.T, step string) T {
		t.Helper()
		if err != nil {
			t.Fatal(step, err)
		}
		return value
	}
}

// genuineResources lists what the producer commands below consume: summon
// fragments, star fragments, EXP items, every ordinary equipment item for
// colours 1..16, and the library, book, element, evolution and pet inputs.
func genuineResources(t *testing.T, p *pg.Pool, rev string, tables []int64) []grant.Line {
	t.Helper()
	cs := contentstore.Store{Queryer: p}
	stacks := map[int64]int64{heroExpItem: 200, genuineSkinItem: 1, 50005013: 20, 50001112: 1, 140001001: 20, 20001413: 1, 50001886: 10, evolutionStone: 100, petExpItem: 100}
	for _, table := range tables {
		def := must(cs.HeroNormalSummonTx(ctx, p, rev, table))(t, "summon policy")
		stacks[def.Template.FragmentItemID] += def.FragmentCount
		if table == genuineHeroTable {
			stacks[def.Template.FragmentItemID] += 70
		}
	}
	for color := int64(1); color <= 16; color++ {
		for slot := int64(1); slot <= 6; slot++ {
			pos := must(cs.HeroEquipmentPositionTx(ctx, p, rev, genuineHeroTable, color, slot))(t, "equipment position")
			if pos.OrdinaryEligible {
				stacks[int64(pos.ItemID)]++
			}
		}
	}
	lines := []grant.Line{}
	for item, amount := range stacks {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: item, Amount: amount})
	}
	for _, key := range []string{"mana", "crystal", "magic_dust", "magic_liquid", "magic_energy", "magic_exp"} {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: key, Amount: 100000000})
	}
	return lines
}

// I8-3B: an owned Normal Hero and Pet built only by genuine producers freeze a
// schema 2 snapshot whose VM totals equal the 3B composition for every active
// producer. Super, positive Inscription, Spirit, Course and Dorm have no origin
// available now and stay at their genuine birth observations (D16).
func TestI8_3BGenuineFullLiveOwnedSnapshotNative(t *testing.T) {
	pool := pool(t)
	a, rev := genuinePlayer(t, pool, rankingServer(t, pool))
	rule := must((contentstore.Store{}).ResolveProgressionPolicyTx(ctx, pool, rev))(t, "progression")
	grantGenuine(t, pool, a, rev, "player-level", []grant.Line{{Kind: grant.PlayerExp, Amount: rule.Rows[98].TotalExp}})
	if level := must((i5store.Store{}).ReadProgressionTx(ctx, pool, a.PlayerID))(t, "level"); level.Level != 100 {
		t.Fatal("genuine Player100 EXP grant", level)
	}
	tables := []int64{genuineHeroTable}
	for table := int64(10001002); len(tables) < 15; table++ {
		tables = append(tables, table)
	}
	grantGenuine(t, pool, a, rev, "resources", genuineResources(t, pool, rev, tables))

	heroes := genuineHeroService(pool)
	cs := contentstore.Store{Queryer: pool}
	girls := []int64{}
	for _, table := range tables {
		def := must(cs.HeroNormalSummonTx(ctx, pool, rev, table))(t, "summon policy")
		h := must(heroes.SummonNormal(ctx, a, table, int64(def.Template.FragmentItemID), def.FragmentCount, op()))(t, "summon")
		girls = append(girls, h.PartnerID)
	}
	main := girls[0]
	for star := 0; star < 2; star++ {
		if err := heroes.Evolve(ctx, a, main, op()); err != nil {
			t.Fatal("star", err)
		}
	}
	must(heroes.UseExpItems(ctx, a, main, []i5.HeroExpItemDebit{{ItemID: heroExpItem, Count: 193}}, op()))(t, "hero exp")
	for color := 1; color < 16; color++ {
		must(heroes.OneKeyEquip(ctx, a, main, op()))(t, "one-key equip")
		must(heroes.PowerUpHero(ctx, a, main, op()))(t, "promotion")
	}
	must(heroes.OneKeyEquip(ctx, a, main, op()))(t, "colour 16 equip")
	must(heroes.SkinOn(ctx, a, main, genuineSkinItem, op()))(t, "skin unlock")
	must(heroes.SkinOn(ctx, a, main, genuineSkinItem, op()))(t, "skin wear")

	libraries := libraryService(pool, pool)
	for range 20 {
		must(libraries.Command(ctx, a, library.Command{Family: library.Gift, PartnerID: main, Value: 50005013}, op()))(t, "gift")
	}
	must(libraries.Command(ctx, a, library.Command{Family: library.Gift, PartnerID: main, Value: 50001112}, op()))(t, "ring")
	must(libraries.Command(ctx, a, library.Command{Family: library.Feed, PartnerID: main, Value: 1}, op()))(t, "feed")
	must(libraries.Command(ctx, a, library.Command{Family: library.Save, PartnerID: main}, op()))(t, "feed save")

	books := bookService(pool, pool)
	for _, c := range []book.Command{{Family: book.Compose, ItemID: 130001001, Amount: 1}, {Family: book.Start, Type: 1}, {Family: book.Speed, Type: 1}, {Family: book.Confirm, Type: 1},
		{Family: book.Start, Type: 3}, {Family: book.Speed, Type: 3}, {Family: book.Confirm, Type: 3}, {Family: book.Learn, SkillID: 10010001}, {Family: book.ConfirmSkill}} {
		must(books.Command(ctx, a, c, op()))(t, fmt.Sprint("book ", c.Family))
	}
	must(elementService(pool, pool).Command(ctx, a, element.Command{Family: element.Equip, PartnerID: main, EquipID: 7, Position: 2}, op()))(t, "element")
	must(evolutionService(pool, pool).Command(ctx, a, evolution.Command{Family: evolution.Allocate, PartnerID: main, AttrID: 4, Amount: 20, CostItem: evolutionStone}, op()))(t, "evolution")

	conquer := conquerMode(t, pool)
	must(conquer.Info(ctx, a, op()))(t, "conquer info")
	catalog := must(cs.ConquerModeCatalogTx(ctx, pool, rev))(t, "conquer catalog")
	for _, mission := range catalog.Missions[:20] {
		for team := int64(1); team <= mission.Teams; team++ {
			conquerWin(t, conquer, a, mission.ID, team, girls[team*2:team*2+2], 1, 1)
		}
	}

	pets := genuinePetService(pool)
	owned := must(pets.Summon(ctx, a, genuinePetTable, op()))(t, "pet summon")
	must(pets.CleanCD(ctx, a, owned.PetID, op()))(t, "pet hatch")
	if err := pets.SetShow(ctx, a, owned.PetID, op()); err != nil {
		t.Fatal("pet show", err)
	}
	must(pets.UseExpItems(ctx, a, owned.PetID, []i5.PetExpItemDebit{{ItemID: petExpItem, Count: 20}}, op()))(t, "pet exp")

	// 2F recheck: no genuine Hero reaches raw stage 3, so the production port stays fail-closed (D16(b)).
	if _, err := (characterstore.InscriptionHeroPort{Store: characterstore.Store{Queryer: pool}}).InscriptionEligibilityTx(ctx, pool, a.PlayerID, main, rev, time.Now().UTC()); !errors.Is(err, inscription.ErrUnavailable) {
		t.Fatal("2F eligibility recheck", err)
	}

	s := combatService(t, pool)
	locator := d.Locator{DomainKind: "i8-3b-fixture-mode", AuthorityScope: "genuine-full-live", DomainLocator: fmt.Sprint(a.PlayerID)}
	started := must(fixtureStart(t, s, rev, combat.StartRequest{Actor: a, Locator: locator, GenerationRef: "g", StartFingerprint: fingerprint("i8-3b-genuine"), Battle: combat.BattleRequest{CampaignType: 1,
		TeamA:  []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: a.PlayerID, Identity: main}},
		PetsA:  []combat.Participant{{Origin: d.OwnedSelf, Kind: d.PetActor, Player: a.PlayerID, Identity: owned.PetID}},
		WavesB: [][]combat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}, pool))(t, "start")
	raw := must((combatstore.Store{}).ReadSnapshotTx(ctx, pool, started.Attempt.SnapshotHash))(t, "snapshot")
	snapshot := must(d.DecodeSnapshot(raw, started.Attempt.SnapshotHash))(t, "decode")
	if snapshot.ProducerProfile != d.ProducerProfileID {
		t.Fatal("producer profile", snapshot.ProducerProfile)
	}
	var params map[string]any
	decoder := json.NewDecoder(bytes.NewReader(snapshot.Battle.TeamA[0].Params))
	decoder.UseNumber()
	if err := decoder.Decode(&params); err != nil {
		t.Fatal(err)
	}
	genuine := map[string]string{"color": "16", "lev": "100", "star": "3", "current_skin_id": "40001001", "is_married": "1", "conquer_lev": "20", "twice_awake_stage": "0"}
	for key, want := range genuine {
		if got := fmt.Sprint(params[key]); got != want {
			t.Errorf("frozen %s %s, want %s", key, got, want)
		}
	}
	for _, key := range []string{"element_equips", "evo_attr_points", "feed_attrs", "skin_ids"} {
		if encoded, _ := json.Marshal(params[key]); string(encoded) == "[]" || string(encoded) == "{}" || string(encoded) == "null" {
			t.Errorf("frozen %s is default: %s", key, encoded)
		}
	}
	t.Logf("genuine birth defaults (forward-bound origins): courses %v house_id %v spirit_equip %v inscript_items %v", params["courses"], params["house_id"], params["spirit_equip"], params["inscript_items"])
	if encoded, _ := json.Marshal(params["skill_book_info"]); string(encoded) != `{"10010001":1}` {
		t.Errorf("learned book not frozen: %s", encoded)
	}

	corpus, _ := combatcorpus.Load()
	totals := must(combatresolver.EvaluateActors(corpus, snapshot))(t, "VM totals")
	for i, actor := range append(append([]d.Actor{}, snapshot.Battle.TeamA...), snapshot.Battle.PetsA...) {
		var facet struct {
			Model string      `json:"model"`
			Total [49]float64 `json:"total"`
		}
		if err := json.Unmarshal(actor.BattleTotals, &facet); err != nil {
			t.Fatal(err)
		}
		mismatches := 0
		for attr := 1; attr <= 49; attr++ {
			vm, oracle := totals[i][attr], facet.Total[attr-1]
			if math.Abs(vm-oracle) > 1e-6*math.Max(1, math.Abs(oracle)) {
				mismatches++
				t.Errorf("A05 %s %s table %d attr %d: VM %v 3B %v", facet.Model, actor.Kind, actor.TableID, attr, vm, oracle)
			}
		}
		t.Logf("A05 %s %s table %d: %d/49 attributes equal (hp VM %v)", facet.Model, actor.Kind, actor.TableID, 49-mismatches, totals[i][1])
	}
	resolved := must(s.Resolve(ctx, op(), started.Attempt.ID))(t, "resolve")
	t.Logf("genuine snapshot %s outcome %+v report %s", started.Attempt.SnapshotHash, resolved.Resolution.Outcome, resolved.Resolution.ReportSHA256)
	if path := os.Getenv("GXB_I8_3B_SNAPSHOT_OUT"); path != "" {
		if err := os.WriteFile(path, raw, 0o644); err != nil {
			t.Fatal(err)
		}
	}
}
