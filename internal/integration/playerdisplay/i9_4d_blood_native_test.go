//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/awakeningbattle"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	pet "gxb.local/backend/v2/internal/application/characterpet"
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
	owner := i5.Service{Runner: runner, Store: values, Content: content, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.LevelFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, MissionFresh: p, MissionTime: pg.AuthoritativeTime{Queryer: p}, Missions: &i5.MissionMaterializer{Store: values, Catalog: content}}
	owner.Awakening = &i5.AwakeningRuntime{Store: values, Content: content, Heroes: heroes, Pets: pet.Service{Store: store, Awakening: store, Equipment: content}, Stacks: values, Costs: heroes.MaterialCosts}
	return owner, heroes
}

func TestI9_4DBloodRealCombatAttemptAndTerminal(t *testing.T) {
	p := pool(t)
	actor, rev, ref := combatOwner(t, p, rankingServer(t, p))
	store := characterstore.Store{Queryer: p}
	content := contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	// Declared awakened/progression/equipment fixture; ordinary origin and progression are qualified separately.
	exec(t, p, `UPDATE player_heroes SET table_id=11001001,level=100,color=15,equip_1=1,equip_2=1,equip_3=1,equip_4=1,equip_5=1,equip_6=1 WHERE player_id=$1 AND partner_id=$2`, int64(actor.PlayerID), ref.PartnerID)
	owner, heroes := i94AwakeningOwners(p)
	heroes.AwakeningEquipment = &owner
	if _, e := owner.ChangeAwakening(ctx, actor, "open", 2001001, 2, op()); e != nil {
		t.Fatal(e)
	}
	// Resource fixture uses the canonical grant owner; it is not a genuine event/material drop.
	fixture := op()
	if _, e := owner.SettleGrant(ctx, actor, grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "i94-fixture", Operation: "blood-gear", BusinessKey: fixture.ID.String(), Occurrence: fixture.ID.String(), PolicyVersion: "i94-fixture-v1"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 21001001, Amount: 1}}}, fixture); e != nil {
		t.Fatal(e)
	}
	var slot int64
	for n := int64(1); n <= 6; n++ {
		pos, e := content.HeroEquipmentPositionTx(ctx, p, rev, 11001001, 15, n)
		if e != nil {
			t.Fatal(e)
		}
		if pos.ItemID == 20001185 {
			slot = n
		}
	}
	if _, e := heroes.EquipItem(ctx, actor, ref.PartnerID, slot, op()); e != nil {
		t.Fatal(e)
	}
	if _, e := owner.ChangeAwakening(ctx, actor, "claim", 2001001, 2, op()); e != nil {
		t.Fatal(e)
	}
	fight := combatService(t, p)
	stats := rawBirthStats(p)
	owned := statOwned(p)
	owned.HeroEquipment = hero.CA8EquipmentObservationAdapter{Reader: hero.EquipmentStateReader{Store: store, Content: content, Awakening: heroes.AwakeningPositions}}
	stats.Owned = owned
	fight.Inputs.Stats = stats
	fight.Inputs.Heroes = characterstore.HeroBootstrapProjection{Content: content, Awakening: heroes, AwakeningPositions: heroes.AwakeningPositions, Library: libraryService(p, p), Dorm: dormService(p, p), Book: bookService(p, p), Course: courseService(p, p), Inscription: inscriptionService(p, p), Element: elementService(p, p), Spirit: spiritService(p, p), Evolution: evolutionService(p, p)}
	mode := awakeningbattle.Mode{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Fresh: p, Content: content, Fence: values, Heroes: heroes, Missions: owner, Combat: fight, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
	absent, e := mode.Result(ctx, actor, 2001002, 20, op())
	if e != nil || absent["error_code"] != int64(1) {
		t.Fatal("unstarted result", absent, e)
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
	root, err := values.ReadAwakeningTx(ctx, p, actor.PlayerID)
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
	if _, e = mode.Result(ctx, actor, 2001002, 20, terminal); e != nil {
		t.Fatal("exact result replay", e)
	}
	if _, e = mode.Result(ctx, actor, 2001002, 20, op()); e != nil {
		t.Fatal("terminal drain", e)
	}
	if _, e = owner.ChangeAwakening(ctx, actor, "claim", 2001002, 2, op()); e != nil {
		t.Fatal(e)
	}
	raw, e := (characterstore.RawAwakeningStore{}).ReadRawAwakeningBirthTx(ctx, p, ref)
	if e != nil || raw.RawStage != 3 {
		t.Fatal(raw, e)
	}
}
