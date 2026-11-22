//go:build postgres

package campaign

import (
	"context"
	"encoding/json"
	"os"
	"slices"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/eventstore"
	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	appevents "gxb.local/backend/v2/internal/application/events"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	domainevents "gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	otadomain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	e2NormalNode int64 = 2100001
	e2SuperNode  int64 = 100019
)

func e2Pool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I11A_E2_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_E2_DSN required (ops/testing/fresh_db.sh i11ae2)")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

type e2Coverage struct{}

func (e2Coverage) Covers(context.Context, otadomain.CoversRequest) (otadomain.CoversResult, error) {
	return otadomain.CoversResult{Status: otadomain.CoversCovered}, nil
}

func e2Bus(t *testing.T, pool *pg.Pool) operator.Bus {
	t.Helper()
	hooks, err := appevents.NewHookRegistry(domainevents.HookCampaignDropMultiplier)
	if err != nil {
		t.Fatal(err)
	}
	commands := appevents.Commands{Store: eventstore.Store{}, Coverage: e2Coverage{}, Gifts: eventstore.ContentGifts{}, Catalogue: eventstore.ContentCatalogue{}, Hooks: hooks}
	return operator.Bus{Runner: tx.Runner{DB: pool}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: commands.Handlers()}
}

func e2Command(t *testing.T, name string, revision *int64, payload any) operator.Command {
	t.Helper()
	key, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(name, operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "i11a e2 native", SemanticKey: key.String(), ExpectedRevision: revision}, raw)
	if err != nil {
		t.Fatal(err)
	}
	return command
}

func e2Execute(t *testing.T, bus operator.Bus, command operator.Command) operator.Outcome {
	t.Helper()
	outcome, err := bus.Execute(context.Background(), command)
	if err != nil {
		t.Fatalf("%s: %v", command.ModuleCommand, err)
	}
	if outcome.State != operator.StateApplied {
		t.Fatalf("%s: %s %s", command.ModuleCommand, outcome.State, outcome.Result)
	}
	return outcome
}

func e2Schedule(t *testing.T, bus operator.Bus, activityID int64, start time.Time) appevents.OccurrenceView {
	t.Helper()
	payload := map[string]any{"activity_id": activityID, "logical_server_ids": []int64{1}, "duration": "3d", "start": start.UTC().Format(time.RFC3339)}
	outcome := e2Execute(t, bus, e2Command(t, "events.schedule", nil, payload))
	var result struct {
		Occurrences []appevents.OccurrenceView `json:"occurrences"`
	}
	if err := json.Unmarshal(outcome.Result, &result); err != nil || len(result.Occurrences) != 1 {
		t.Fatalf("schedule result %s: %v", outcome.Result, err)
	}
	return result.Occurrences[0]
}

func e2EndNow(t *testing.T, bus operator.Bus, occurrence appevents.OccurrenceView) {
	t.Helper()
	revision := occurrence.Revision
	e2Execute(t, bus, e2Command(t, "events.end_now", &revision, map[string]any{"occurrence_id": occurrence.ID}))
}

// e2DropHooks mirrors the production adapter over the events read.
type e2DropHooks struct{ Events appevents.Service }

func (hooks e2DropHooks) DropHooksTx(ctx context.Context, q tx.Queryer, server int64, at time.Time) ([]DropHook, error) {
	raw, err := hooks.Events.ActiveModifiers(ctx, q, server, at, domainevents.HookCampaignDropMultiplier)
	if err != nil {
		return nil, err
	}
	out := make([]DropHook, 0, len(raw))
	for _, payload := range raw {
		var hook domainevents.Hook
		if err := json.Unmarshal(payload, &hook); err != nil {
			return nil, err
		}
		out = append(out, DropHook{Scope: hook.Scope, ItemKinds: hook.ItemKinds, Multiplier: hook.Multiplier})
	}
	return out, nil
}

type e2Awakening struct{}

func (e2Awakening) FreezeAwakeningCampaignTx(_ context.Context, _ tx.Queryer, pid identity.PlayerID, campaign, kind int64, formation []int64, pet int64, _ bool) (objective.AwakeCampaignContext, error) {
	return objective.AwakeCampaignContext{Player: int64(pid), Campaign: campaign, Type: kind, Formation: append([]int64{}, formation...), Pet: pet, Drops: []objective.AwakeFrozenDrop{}}, nil
}

func (e2Awakening) SettleAwakeningCampaignTx(context.Context, tx.Tx, identity.PlayerID, objective.AwakeCampaignContext, int64, int64, bool) ([]objective.AwakeFrozenDrop, map[string]any, error) {
	return nil, nil, nil
}

// e2Combat draws the production START package so the test sees the frozen items.
type e2Combat struct {
	Combat
	items []d.Item
	seed  [32]byte
}

func (combatant *e2Combat) StartTx(_ context.Context, _ tx.Tx, _ ca.CoherentReadScope, request combat.StartRequest) (combat.Started, error) {
	drawn, err := request.Package(cd.NewStream(combatant.seed))
	if err != nil {
		return combat.Started{}, err
	}
	if pkg, ok := drawn.(awakeningStartPackage); ok {
		combatant.items = pkg.Items
	} else if items, ok := drawn.([]d.Item); ok {
		combatant.items = items
	}
	return combat.Started{}, nil
}

func (combatant *e2Combat) AttestSummaryTx(context.Context, tx.Tx, combat.SummaryRequest) (combat.SummaryAttested, error) {
	return combat.SummaryAttested{}, nil
}

func (combatant *e2Combat) BorrowedTx(context.Context, tx.Tx, cd.Locator) (bool, error) {
	return false, nil
}

type e2Fence struct{}

func (e2Fence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

type e2Functions struct{}

func (e2Functions) ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error) {
	return player.FunctionEligibility{}, false, nil
}

type e2Directory struct{}

func (e2Directory) ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return playerdirectory.Profile{Level: 100}, true, nil
}

type e2Heroes struct{}

func (e2Heroes) LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error) {
	return character.Hero{}, nil
}

func (e2Heroes) ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error) {
	return nil, nil
}

type e2HeroExp struct{}

func (e2HeroExp) ApplyDormEXPLockedTx(context.Context, tx.Tx, character.HeroRef, int64, int64, string, time.Time) (character.Hero, bool, error) {
	return character.Hero{}, false, nil
}

type e2Energy struct{}

func (e2Energy) DebitTemporalTx(context.Context, tx.Tx, identity.PlayerID, string, int64, operation.Context) (economy.TemporalState, error) {
	return economy.TemporalState{}, nil
}

func (e2Energy) TemporalBalanceTx(context.Context, tx.Tx, identity.PlayerID, string, operation.Context) (int64, error) {
	return 1000, nil
}

type e2Grants struct{}

func (e2Grants) SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error) {
	return i5.GrantResult{}, nil
}

type e2Stages struct{}

func (e2Stages) OpenStageFunctionsTx(context.Context, tx.Tx, identity.PlayerID, string, int64, time.Time) ([]int64, error) {
	return nil, nil
}

type e2Facts struct{}

func (e2Facts) PrepareTx(ctx context.Context, _ tx.Tx, _ identity.PlayerID, _ gen.TimedOperation) (context.Context, error) {
	return ctx, nil
}

func (e2Facts) RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error {
	return nil
}

type e2Privileges struct{}

func (e2Privileges) SnapshotTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (i5.PrivilegeSnapshot, error) {
	return i5.PrivilegeSnapshot{VIPLevel: 0}, nil
}

type e2Costs struct{}

func (e2Costs) DebitMaterialCostTx(context.Context, tx.Tx, identity.PlayerID, i5.MaterialCost, operation.Context) (i5.MaterialDebitResult, error) {
	return i5.MaterialDebitResult{}, nil
}

type e2Progression struct{}

func (e2Progression) ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error) {
	return player.Progression{Level: 100}, nil
}

type e2Receipts struct{}

func (e2Receipts) PutTx(context.Context, tx.Tx, receipt.Receipt) (receipt.PutResult, error) {
	return receipt.PutResult{}, nil
}

func (e2Receipts) FindTx(context.Context, tx.Queryer, receipt.Identity) (receipt.Receipt, bool, error) {
	return receipt.Receipt{}, false, nil
}

type e2ReceiptRead struct{}

func (e2ReceiptRead) Find(context.Context, receipt.Identity) (receipt.Receipt, bool, error) {
	return receipt.Receipt{}, false, nil
}

func e2ItemCounts(items []d.Item) map[int64]int64 {
	counts := map[int64]int64{}
	for _, item := range items {
		counts[item.ItemID] += item.Num
	}
	return counts
}

func e2Start(t *testing.T, pool *pg.Pool, mode Mode, actor identity.ActorContext, view view, node d.Node, record d.Record, at time.Time) []d.Item {
	t.Helper()
	operationContext := operation.Context{ID: ids.UUID{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}, StartedAt: at, EntropySeed: [32]byte{9, 8, 7}}
	_, err := (tx.Runner{DB: pool}).Run(context.Background(), operationContext, ModeProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, scope tx.Scope) error {
		timed, e := gen.NewTimedOperation(scope.Operation, at)
		if e != nil {
			return e
		}
		_, e = mode.start(c, gen.TimedScope{Tx: scope.Tx, Operation: timed, Attempt: 1, Options: scope.Options}, actor, view, node, record, nil, Fight{CampaignID: node.ID, Type: node.Type})
		return e
	})
	if err != nil {
		t.Fatalf("START %d: %v", node.ID, err)
	}
	return mode.Combat.(*e2Combat).items
}

func e2SweepMode(pool *pg.Pool, content contentstore.Store) Mode {
	return Mode{
		Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: pool}}, Runner: tx.Runner{DB: pool}},
		Fresh: pool, Store: campaignstore.Store{}, Content: content,
		Drops:       e2DropHooks{Events: appevents.Service{Store: eventstore.Store{}}},
		Fence:       e2Fence{},
		Functions:   e2Functions{},
		Directory:   e2Directory{},
		Heroes:      e2Heroes{},
		HeroExp:     e2HeroExp{},
		Combat:      &e2Combat{},
		Energy:      e2Energy{},
		Grants:      e2Grants{},
		Stages:      e2Stages{},
		Facts:       e2Facts{},
		Receipts:    e2Receipts{},
		ReceiptRead: e2ReceiptRead{},
		Privileges:  e2Privileges{},
		Costs:       e2Costs{},
		Progression: e2Progression{},
	}
}

func e2RunSweep(t *testing.T, mode Mode, playerID identity.PlayerID) map[int64]int64 {
	t.Helper()
	node, found := e2CatalogNode(t, mode, e2NormalNode)
	if !found {
		t.Fatalf("normal node %d missing", e2NormalNode)
	}
	at := time.Now().UTC()
	sweepOperation := operation.Context{ID: ids.UUID{4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4}, StartedAt: at, EntropySeed: [32]byte{5, 5, 5}}
	out, err := mode.Sweep(context.Background(), identity.ActorContext{PlayerID: playerID, LogicalServerID: 1}, Sweep{CampaignID: node.ID, Type: d.Normal, Count: 1, Kind: 1}, sweepOperation)
	if err != nil {
		t.Fatalf("sweep: %v", err)
	}
	rows, ok := out["items"].([][]d.Item)
	if !ok || len(rows) != 1 {
		t.Fatalf("sweep items = %T %+v", out["items"], out["items"])
	}
	return e2ItemCounts(rows[0])
}

func e2CatalogNode(t *testing.T, mode Mode, id int64) (d.Node, bool) {
	t.Helper()
	revision, err := mode.Content.ActiveRevision(context.Background(), mode.Fresh)
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := mode.Content.CampaignCatalogTx(context.Background(), mode.Fresh, revision)
	if err != nil {
		t.Fatal(err)
	}
	return catalog.Node(id)
}

func e2SeedChain(t *testing.T, pool *pg.Pool, catalog d.Catalog, playerID identity.PlayerID, target int64) {
	t.Helper()
	at := time.Now().UTC()
	operationContext := operation.Context{ID: ids.UUID{2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2}, StartedAt: at}
	_, err := (tx.Runner{DB: pool}).Run(context.Background(), operationContext, ModeProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, scope tx.Scope) error {
		store := campaignstore.Store{}
		record, e := store.LockTx(c, scope.Tx, playerID, at)
		if e != nil {
			return e
		}
		changed := []int64{}
		for _, id := range catalog.Chain(d.Normal) {
			changed = append(changed, id)
			record.Progress.Nodes[id] = d.NodeState{CampaignID: id, Star: 3}
			if id == target {
				break
			}
		}
		return store.SaveTx(c, scope.Tx, playerID, record, changed, at)
	})
	if err != nil {
		t.Fatal(err)
	}
}

func e2Player(t *testing.T, pool *pg.Pool, playerID identity.PlayerID) {
	t.Helper()
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	if _, err = pool.Raw().Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',now())`, account.String(), account.String()); err != nil {
		t.Fatal(err)
	}
	if _, err = pool.Raw().Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,now(),'i11a-e2')`, int64(playerID), account.String()); err != nil {
		t.Fatal(err)
	}
}

func e2ItemKinds(t *testing.T, pool *pg.Pool, store contentstore.Store, revision string, catalog d.Catalog, boxID int64) map[int64]int64 {
	t.Helper()
	box, found := catalog.Box(boxID)
	if !found {
		t.Fatalf("drop box %d missing", boxID)
	}
	ids := make([]int64, 0, len(box.Rows))
	for _, row := range box.Rows {
		ids = append(ids, row[0])
	}
	kinds, err := store.ItemKindsTx(context.Background(), pool, revision, ids)
	if err != nil {
		t.Fatal(err)
	}
	return kinds
}

// e2AssertScaled checks every item against baseline x its largest matching
// multiplier; unlisted kinds (and nil multipliers) must stay unchanged.
func e2AssertScaled(t *testing.T, baseline, actual map[int64]int64, kinds, multipliers map[int64]int64) {
	t.Helper()
	listChanged, unchanged := 0, 0
	for itemID, base := range baseline {
		multiplier := multipliers[kinds[itemID]]
		if multiplier < 1 {
			multiplier = 1
		}
		if multiplier > 1 {
			listChanged++
		} else {
			unchanged++
		}
		if actual[itemID] != base*multiplier {
			t.Fatalf("item %d kind %d: got %d, want baseline %d x %d", itemID, kinds[itemID], actual[itemID], base, multiplier)
		}
	}
	for itemID, got := range actual {
		if _, existed := baseline[itemID]; !existed {
			t.Fatalf("item %d appeared only after the hook: %d", itemID, got)
		}
	}
	if len(multipliers) > 0 && (listChanged == 0 || unchanged == 0) {
		t.Fatalf("the roll must hold both a listed and an unlisted kind: listed=%d unlisted=%d", listChanged, unchanged)
	}
}

// TestCampaignDropMultiplier1008Native proves the shipped 1008 definition
// through the production deploy and schedule commands, then the two fresh drop
// sites (START freeze and sweep) against a RUNNING occurrence.
func TestCampaignDropMultiplier1008Native(t *testing.T) {
	pool := e2Pool(t)
	ctx := context.Background()
	bus := e2Bus(t, pool)
	raw, err := os.ReadFile("../../../content/events/definitions/1008.json")
	if err != nil {
		t.Fatal(err)
	}
	shipped, err := domainevents.ParseDefinition(raw)
	if err != nil {
		t.Fatal(err)
	}
	hooksOfKind := shipped.HooksOfKind(domainevents.HookCampaignDropMultiplier)
	if len(hooksOfKind) != 1 || hooksOfKind[0].Scope != "normal" || hooksOfKind[0].Multiplier != 2 {
		t.Fatalf("shipped 1008 hook = %+v", hooksOfKind)
	}
	if want := []int64{1, 2, 5, 6}; !slices.Equal(hooksOfKind[0].ItemKinds, want) {
		t.Fatalf("shipped 1008 item_kinds = %v, want %v", hooksOfKind[0].ItemKinds, want)
	}
	e2Execute(t, bus, e2Command(t, "events.definition.deploy", nil, json.RawMessage(raw)))
	second := json.RawMessage(`{"activity_id":1090,"revision":1,"archetype":"RULE_MODIFIER","hooks":[{"hook":"campaign.drop_multiplier","scope":"normal","item_kinds":[5],"multiplier":3}],"client_requirements":{},"default_days":3}`)
	e2Execute(t, bus, e2Command(t, "events.definition.deploy", nil, second))

	store := contentstore.Store{}
	revision, err := store.ActiveRevision(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := store.CampaignCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	normal, found := catalog.Node(e2NormalNode)
	if !found || normal.Type != d.Normal {
		t.Fatalf("normal node: %+v %v", normal, found)
	}
	super, found := catalog.Node(e2SuperNode)
	if !found || super.Type != d.Super {
		t.Fatalf("super node: %+v %v", super, found)
	}
	at := time.Now().UTC()
	actor := identity.ActorContext{PlayerID: 190001, LogicalServerID: 1}
	mode := Mode{Content: store, Awakening: e2Awakening{}, Drops: e2DropHooks{Events: appevents.Service{Store: eventstore.Store{}}}, Combat: &e2Combat{seed: [32]byte{7}}}
	currentView := view{catalog: catalog, revision: revision, superOpen: true, day: modes.Day(at)}
	repeat := d.Record{Progress: d.Progress{Nodes: map[int64]d.NodeState{normal.ID: {CampaignID: normal.ID, Star: 2}, super.ID: {CampaignID: super.ID, Star: 2}}}}
	first := d.Record{Progress: d.Progress{Nodes: map[int64]d.NodeState{}}}

	baselineRepeat := e2Start(t, pool, mode, actor, currentView, normal, repeat, at)
	baselineFirst := e2Start(t, pool, mode, actor, currentView, normal, first, at)
	baselineElite := e2Start(t, pool, mode, actor, currentView, super, repeat, at)
	normalKinds := e2ItemKinds(t, pool, store, revision, catalog, normal.RepeatBox)
	superKinds := e2ItemKinds(t, pool, store, revision, catalog, super.RepeatBox)

	// The sweep baseline must also be taken before any occurrence runs; the
	// fixed operation id and entropy keep both sweep rolls on one stream.
	sweepMode := e2SweepMode(pool, store)
	e2Player(t, pool, 190001)
	e2SeedChain(t, pool, catalog, 190001, normal.ID)
	baselineSweep := e2RunSweep(t, sweepMode, 190001)

	start := at.Add(-time.Hour)
	occurrence1008 := e2Schedule(t, bus, 1008, start)
	occurrence1090 := e2Schedule(t, bus, 1090, start)

	largest := e2Start(t, pool, mode, actor, currentView, normal, repeat, at)
	e2AssertScaled(t, e2ItemCounts(baselineRepeat), e2ItemCounts(largest), normalKinds, map[int64]int64{5: 3, 6: 2})

	e2EndNow(t, bus, occurrence1090)
	after1090 := time.Now().UTC().Add(time.Second)
	doubled := e2Start(t, pool, mode, actor, currentView, normal, repeat, after1090)
	e2AssertScaled(t, e2ItemCounts(baselineRepeat), e2ItemCounts(doubled), normalKinds, map[int64]int64{1: 2, 2: 2, 5: 2, 6: 2})

	firstClear := e2Start(t, pool, mode, actor, currentView, normal, first, after1090)
	e2AssertScaled(t, e2ItemCounts(baselineFirst), e2ItemCounts(firstClear), normalKinds, nil)

	elite := e2Start(t, pool, mode, actor, currentView, super, repeat, after1090)
	e2AssertScaled(t, e2ItemCounts(baselineElite), e2ItemCounts(elite), superKinds, nil)

	pending := repeat
	pending.PendingGeneration = generation(normal.Type, normal.ID)
	pending.PendingItems = doubled
	replay := e2Start(t, pool, mode, actor, currentView, normal, pending, after1090)
	if !equalCounts(e2ItemCounts(replay), e2ItemCounts(doubled)) {
		t.Fatalf("pending replay = %+v, frozen was %+v", e2ItemCounts(replay), e2ItemCounts(doubled))
	}

	e2Player(t, pool, 190002)
	e2SeedChain(t, pool, catalog, 190002, normal.ID)
	doubledSweep := e2RunSweep(t, sweepMode, 190002)
	e2AssertScaled(t, baselineSweep, doubledSweep, normalKinds, map[int64]int64{1: 2, 2: 2, 5: 2, 6: 2})

	e2EndNow(t, bus, occurrence1008)
	ended := e2Start(t, pool, mode, actor, currentView, normal, repeat, time.Now().UTC().Add(time.Second))
	e2AssertScaled(t, e2ItemCounts(baselineRepeat), e2ItemCounts(ended), normalKinds, nil)
}

func equalCounts(left, right map[int64]int64) bool {
	if len(left) != len(right) {
		return false
	}
	for itemID, count := range left {
		if right[itemID] != count {
			return false
		}
	}
	return true
}
