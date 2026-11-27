//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/awakeningbattle"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	pet "gxb.local/backend/v2/internal/application/characterpet"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
)

type unqualifiedAwakening struct{ publicstats.Awakening }

func (a unqualifiedAwakening) RawAwakeningTx(c context.Context, sc ca.CoherentReadScope, ref character.HeroRef) (publicstats.AwakeningObservation, error) {
	out, err := a.Awakening.RawAwakeningTx(c, sc, ref)
	out.ProducerReference = "LEGACY_INFERRED_STAGE"
	return out, err
}

type rejectedBloodCompletion struct{ i5.AwakeningBloodPort }

func (r rejectedBloodCompletion) CompleteAwakeningBloodTx(context.Context, tx.Tx, identity.PlayerID, objective.AwakeInstance) (map[string]any, error) {
	return nil, errors.New("injected mission completion failure")
}

func i94AwakeningOwners(p *pg.Pool) (i5.Service, hero.Service) {
	store := characterstore.Store{Queryer: p}
	content := contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	heroes := ownerSummoner(p)
	heroes.Awakening = struct {
		characterstore.Store
		characterstore.RawAwakeningStore
	}{Store: store}
	heroes.AwakeningPositions = &hero.AwakeningPositionResolver{Raw: characterstore.RawAwakeningStore{}, Content: content, Queryer: p}
	heroes.Equipment = content
	heroes.MaterialCosts = i5.MaterialCostDebiter{Store: values, Content: content}
	owner := i5.Service{CharacterFunctions: characterstore.FunctionPrerequisites{Store: store, Content: content}, Runner: runner, Store: values, Content: content, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.LevelFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, MissionFresh: p, MissionTime: pg.AuthoritativeTime{Queryer: p}, Missions: &i5.MissionMaterializer{Store: values, Catalog: content}}
	owner.Awakening = &i5.AwakeningRuntime{Store: values, Content: content, Heroes: heroes, Pets: pet.Service{Store: store, Awakening: store, Equipment: content}, Stacks: values, Costs: heroes.MaterialCosts}
	return owner, heroes
}

// bloodNativeFixture is the qualified stage-2 Blood occurrence shared by the
// Blood natives: the owner hero is awakened to raw stage 2 with its gear.
type bloodNativeFixture struct {
	actor   identity.ActorContext
	ref     character.HeroRef
	owner   i5.Service
	heroes  hero.Service
	fight   combat.Service
	content contentstore.Store
	values  i5store.Store
}

// bloodFixtureSpec selects one Blood mission chain and the hero table it starts on.
type bloodFixtureSpec struct {
	first, second       int64
	table               int64
	color               int64
	baseItem, bloodItem int64
}

var bloodFixture2001 = bloodFixtureSpec{first: 2001001, second: 2001002, table: 11001001, color: 15, baseItem: 20001185, bloodItem: 21001001}
var bloodFixtureAnnie = bloodFixtureSpec{first: 2013001, second: 2013002, table: 11001013, color: 16, baseItem: 20001190, bloodItem: 21001019}

func newBloodNativeFixture(t *testing.T, p *pg.Pool) bloodNativeFixture {
	return newBloodNativeFixtureFor(t, p, bloodFixture2001)
}

func newBloodFixtureBase(t *testing.T, p *pg.Pool, spec bloodFixtureSpec) (bloodNativeFixture, string) {
	t.Helper()
	actor, rev, ref := combatOwner(t, p, rankingServer(t, p))
	content := contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	// Declared awakened/progression/equipment fixture; ordinary origin and progression are qualified separately.
	exec(t, p, `UPDATE player_heroes SET table_id=$3,level=100,color=$4,equip_1=1,equip_2=1,equip_3=1,equip_4=1,equip_5=1,equip_6=1 WHERE player_id=$1 AND partner_id=$2`, int64(actor.PlayerID), ref.PartnerID, spec.table, spec.color)
	// This older explicit Character fixture also needs the production function-state owner for D359.
	exec(t, p, `INSERT INTO player_function_state_owners(player_id,state_version,updated_at) VALUES($1,1,clock_timestamp()) ON CONFLICT DO NOTHING`, int64(actor.PlayerID))
	owner, heroes := i94AwakeningOwners(p)
	heroes.AwakeningEquipment = &owner
	return bloodNativeFixture{actor: actor, ref: ref, owner: owner, heroes: heroes, content: content, values: values}, rev
}

func newBloodNativeFixtureFor(t *testing.T, p *pg.Pool, spec bloodFixtureSpec) bloodNativeFixture {
	t.Helper()
	// The same open -> equip -> claim order the stock client drives through 2738, 54 and 161.
	fixture, rev := newBloodFixtureBase(t, p, spec)
	actor, ref, owner, heroes, content := fixture.actor, fixture.ref, fixture.owner, fixture.heroes, fixture.content
	if _, e := owner.ChangeAwakening(ctx, actor, "open", spec.first, 2, op()); e != nil {
		t.Fatal(e)
	}
	// Resource fixture uses the canonical grant owner; it is not a genuine event/material drop.
	fixtureOperation := op()
	if _, e := owner.SettleGrant(ctx, actor, grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "i94-fixture", Operation: "blood-gear", BusinessKey: fixtureOperation.ID.String(), Occurrence: fixtureOperation.ID.String(), PolicyVersion: "i94-fixture-v1"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: spec.bloodItem, Amount: 1}}}, fixtureOperation); e != nil {
		t.Fatal(e)
	}
	var slot int64
	for n := int64(1); n <= 6; n++ {
		pos, e := content.HeroEquipmentPositionTx(ctx, p, rev, spec.table, spec.color, n)
		if e != nil {
			t.Fatal(e)
		}
		if pos.ItemID == character.EquipmentTemplateID(spec.baseItem) {
			slot = n
		}
	}
	if _, e := heroes.EquipItem(ctx, actor, ref.PartnerID, slot, op()); e != nil {
		t.Fatal(e)
	}
	if _, e := owner.ChangeAwakening(ctx, actor, "claim", spec.first, 2, op()); e != nil {
		t.Fatal(e)
	}
	fight := combatService(t, p)
	stats := rawBirthStats(p)
	owned := statOwned(p)
	owned.HeroEquipment = hero.CA8EquipmentObservationAdapter{Reader: hero.EquipmentStateReader{Store: characterstore.Store{Queryer: p}, Content: content, Awakening: heroes.AwakeningPositions}}
	stats.Owned = owned
	fight.Inputs.Stats = stats
	fight.Inputs.Heroes = characterstore.HeroBootstrapProjection{Content: content, Awakening: heroes, AwakeningPositions: heroes.AwakeningPositions, Library: libraryService(p, p), Dorm: dormService(p, p), Book: bookService(p, p), Course: courseService(p, p), Inscription: inscriptionService(p, p), Element: elementService(p, p), Spirit: spiritService(p, p), Evolution: evolutionService(p, p)}
	fixture.fight = fight
	return fixture
}

func (f bloodNativeFixture) mode(p *pg.Pool, clock gen.TimeAuthority) awakeningbattle.Mode {
	return awakeningbattle.Mode{Timed: gen.TimedRunner{Binder: gen.Binder{Time: clock}, Runner: tx.Runner{DB: p}}, Fresh: p, Content: f.content, Fence: f.values, Heroes: f.heroes, Missions: f.owner, Combat: f.fight, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, BattleCounts: battleCountObserver(p)}
}

func TestI9_4DBloodRealCombatAttemptAndTerminal(t *testing.T) {
	p := pool(t)
	f := newBloodNativeFixture(t, p)
	mode := f.mode(p, pg.AuthoritativeTime{Queryer: p})
	actor, ref, owner, fight := f.actor, f.ref, f.owner, f.fight
	absent, e := mode.Result(ctx, actor, 2001002, 20, op())
	if !errors.Is(e, objective.ErrAwakeningRefused) || absent["error_code"] != int64(1) {
		t.Fatal("unstarted result", absent, e)
	}
	dispatcher := stockruntime.AwakeningBloodDispatcher{Authority: playtestAuthority{actor}, Service: mode}
	response := dispatcher.Dispatch(ctx, playtestRequest(actor, 867, map[string]any{"twice_awake_mission": json.Number("2001002"), "incubus_id": json.Number("2001002"), "num": json.Number("20"), "npc_ids": map[string]any{}}))
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(35028) {
		t.Fatalf("unstarted result reached the OK callback: %+v", response)
	}
	// A positive number without the genuine mission producer is not an input.
	badFight := fight
	badFight.Inputs.Awakening = unqualifiedAwakening{fight.Inputs.Awakening}
	badMode := mode
	badMode.Combat = badFight
	if _, err := badMode.Start(ctx, actor, 2001002, op()); !errors.Is(err, d.ErrProviderUnavailable) {
		t.Fatal("unqualified positive producer admitted", err)
	}
	for range 2 {
		if _, e = mode.Start(ctx, actor, 2001002, op()); e != nil {
			t.Fatal(e)
		}
	}
	broken := mode
	broken.Missions = rejectedBloodCompletion{owner}
	if _, err := broken.Result(ctx, actor, 2001002, 20, op()); err == nil {
		t.Fatal("completion failure committed Combat")
	}
	root, err := f.values.ReadAwakeningTx(ctx, p, actor.PlayerID)
	if err != nil || root.Active[1].Complete {
		t.Fatal("failed terminal mutated objective", err)
	}
	terminal := op()
	ambiguous := mode
	ambiguous.Timed.Runner.DB = metricCommitDB{Beginner: p, commit: true}
	body, e := ambiguous.Result(ctx, actor, 2001002, 20, terminal)
	if e != nil || body["twice_awake_mission_"] == nil {
		t.Fatal(body, e)
	}
	if exps, ok := body["exps"].([]any); !ok || len(exps) != 0 || body["old_num"] != float64(0) || body["add_exp"] != float64(0) {
		t.Fatalf("Blood result win-window fields: exps=%#v old_num=%#v add_exp=%#v", body["exps"], body["old_num"], body["add_exp"])
	}
	if got := battleCount(t, p, actor.PlayerID, ref.PartnerID); got != 1 {
		t.Fatalf("Girls Log awakening count = %d, want 1", got)
	}
	if _, e = mode.Result(ctx, actor, 2001002, 20, terminal); e != nil {
		t.Fatal("exact result replay", e)
	}
	if _, e = mode.Result(ctx, actor, 2001002, 20, op()); e != nil {
		t.Fatal("terminal drain", e)
	}
	if got := battleCount(t, p, actor.PlayerID, ref.PartnerID); got != 1 {
		t.Fatalf("Girls Log awakening count after replay and drain = %d, want 1", got)
	}
	drained := dispatcher.Dispatch(ctx, playtestRequest(actor, 867, map[string]any{"twice_awake_mission": json.Number("2001002"), "incubus_id": json.Number("2001002"), "num": json.Number("20"), "npc_ids": map[string]any{}}))
	if exps, ok := drained.Body["exps"].([]any); drained.HTTPStatus != 200 || !ok || len(exps) != 0 || fmt.Sprint(drained.Body["old_num"]) != "0" || fmt.Sprint(drained.Body["add_exp"]) != "0" {
		t.Fatalf("Blood result wire: %+v", drained)
	}
	if _, e = owner.ChangeAwakening(ctx, actor, "claim", 2001002, 2, op()); e != nil {
		t.Fatal(e)
	}
	raw, e := (characterstore.RawAwakeningStore{}).ReadRawAwakeningBirthTx(ctx, p, ref)
	if e != nil || raw.RawStage != 3 {
		t.Fatal(raw, e)
	}
	if count := scalar(t, p, `SELECT count(*) FROM player_function_unlocks WHERE player_id=$1 AND function_id=45`, int64(actor.PlayerID)); count != 1 {
		t.Fatal("blood completion did not open Emblem", count)
	}
}
