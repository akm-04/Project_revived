//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/missioninputs"
	d "gxb.local/backend/v2/internal/domain/heroassets"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type i911aClock struct{ at time.Time }

func (c *i911aClock) Now(context.Context) (time.Time, error) { return c.at.UTC(), nil }

func i911aComposition(p *postgres.Pool, a identity.ActorContext) stockruntime.HeroAssetsComposition {
	return i911aCompositionAt(p, a, postgres.AuthoritativeTime{Queryer: p})
}

func i911aCompositionAt(p *postgres.Pool, a identity.ActorContext, authority gen.TimeAuthority) stockruntime.HeroAssetsComposition {
	cs := contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	receipts := kernelstore.Store{}
	privileges := privilegeProvider(p)
	i5svc := appi5.Service{Runner: runner, Store: values, Content: cs, Privileges: privileges, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: p}}
	return stockruntime.NewHeroAssetsComposition(stockruntime.HeroAssetsDependencies{
		Timed:       gen.TimedRunner{Binder: gen.Binder{Time: authority}, Runner: runner},
		Fresh:       p,
		Content:     cs,
		Values:      values,
		Privileges:  privileges,
		I5:          i5svc,
		Receipts:    receipts,
		ReceiptRead: kernelstore.Reader{Queryer: p},
		Authority:   playtestAuthority{a},
	})
}

func i911aDispatch(t *testing.T, dispatcher httpedge.Dispatcher, a identity.ActorContext, mid uint16, params map[string]any, o operation.Context) httpedge.Response {
	t.Helper()
	request := playtestRequest(a, mid, params)
	request.Envelope.Operation = o
	return dispatcher.Dispatch(ctx, request)
}

func i911aSetScalar(t *testing.T, p *postgres.Pool, a identity.ActorContext, key string, amount int64) {
	t.Helper()
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,$2,$3,1,clock_timestamp()-interval '1 hour') ON CONFLICT(player_id,resource_key) DO UPDATE SET amount=excluded.amount,updated_at=excluded.updated_at`, int64(a.PlayerID), key, amount)
}

func i911aScalar(t *testing.T, p *postgres.Pool, a identity.ActorContext, key string) int64 {
	t.Helper()
	var amount int64
	if err := p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key=$2`, int64(a.PlayerID), key).Scan(&amount); err != nil {
		t.Fatal(err)
	}
	return amount
}

func i911aSetSkillPoint(t *testing.T, p *postgres.Pool, a identity.ActorContext, amount int64) {
	t.Helper()
	exec(t, p, `UPDATE player_temporal_resources SET stored_amount=$2,regen_anchor_at=NULL,state_version=state_version+1,updated_at=clock_timestamp() WHERE player_id=$1 AND resource_key='skill_point'`, int64(a.PlayerID), amount)
}

func i911aSkillPoint(t *testing.T, p *postgres.Pool, a identity.ActorContext) int64 {
	t.Helper()
	var amount int64
	if err := p.QueryRow(ctx, `SELECT stored_amount FROM player_temporal_resources WHERE player_id=$1 AND resource_key='skill_point'`, int64(a.PlayerID)).Scan(&amount); err != nil {
		t.Fatal(err)
	}
	return amount
}

func i911aSkillTime(t *testing.T, p *postgres.Pool, a identity.ActorContext) int64 {
	t.Helper()
	var anchor *time.Time
	if err := p.QueryRow(ctx, `SELECT regen_anchor_at FROM player_temporal_resources WHERE player_id=$1 AND resource_key='skill_point'`, int64(a.PlayerID)).Scan(&anchor); err != nil {
		t.Fatal(err)
	}
	if anchor == nil {
		return 0
	}
	return anchor.UTC().Unix()
}

func i911aSetBuySkillCounter(t *testing.T, p *postgres.Pool, a identity.ActorContext, period, used int64) {
	t.Helper()
	exec(t, p, `INSERT INTO daily_consumption_players(player_id,counts,updated_at)VALUES($1,jsonb_build_object('1003',jsonb_build_object('Period',$2::bigint,'Used',$3::bigint)),clock_timestamp()) ON CONFLICT(player_id) DO UPDATE SET counts=excluded.counts,updated_at=excluded.updated_at`, int64(a.PlayerID), period, used)
}

func i911aStack(t *testing.T, p *postgres.Pool, a identity.ActorContext, itemID, quantity int64) {
	t.Helper()
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,$3,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour') ON CONFLICT(player_id,item_id) DO UPDATE SET quantity=excluded.quantity,updated_at=excluded.updated_at`, int64(a.PlayerID), itemID, quantity)
}

func i911aStackQuantity(t *testing.T, p *postgres.Pool, a identity.ActorContext, itemID int64) int64 {
	t.Helper()
	var quantity int64
	if err := p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), itemID).Scan(&quantity); err != nil {
		t.Fatal(err)
	}
	return quantity
}

func i911aBody(t *testing.T, body map[string]any) string {
	t.Helper()
	raw, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	return string(raw)
}

func i911aExpect(t *testing.T, response httpedge.Response, status int, code int64) {
	t.Helper()
	if response.HTTPStatus != status {
		t.Fatalf("status %d want %d body %#v cause %v", response.HTTPStatus, status, response.Body, response.Cause)
	}
	if code != 0 && response.Body["error_code"] != code {
		t.Fatalf("code %v want %d body %#v", response.Body["error_code"], code, response.Body)
	}
}

// i911aCommittedState fingerprints every row a refused skill-level request must
// leave byte-identical: the mission root, the hero, the balances and the receipts.
func i911aCommittedState(t *testing.T, p *postgres.Pool, a identity.ActorContext, partner int64) string {
	t.Helper()
	var state string
	err := p.QueryRow(ctx, `
SELECT
 COALESCE((SELECT row_to_json(r)::text FROM player_mission_roots r WHERE r.player_id=$1),'root:absent')
 || '|' || COALESCE((SELECT row_to_json(h)::text FROM player_heroes h WHERE h.player_id=$1 AND h.partner_id=$2),'hero:absent')
 || '|' || COALESCE((SELECT jsonb_agg(to_jsonb(b) ORDER BY b.resource_key)::text FROM player_currency_balances b WHERE b.player_id=$1),'[]')
 || '|' || COALESCE((SELECT jsonb_agg(to_jsonb(r) ORDER BY r.resource_key)::text FROM player_temporal_resources r WHERE r.player_id=$1),'[]')
 || '|' || COALESCE((SELECT jsonb_agg(to_jsonb(x) ORDER BY x.receipt_id)::text FROM gxb_operation_receipts x WHERE x.owner_key=$1::text),'[]')`,
		int64(a.PlayerID), partner).Scan(&state)
	if err != nil {
		t.Fatal(err)
	}
	return state
}

func TestI9I11ANativeNewPlayerStartsAtSkillCap(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	actor := privilegeActor(t, database, revision)
	if point := i911aSkillPoint(t, database, actor); point != 10 {
		t.Fatalf("new player skill_point %d, want the VIP0 natural cap 10", point)
	}
	var anchor *time.Time
	if err := database.QueryRow(ctx, `SELECT regen_anchor_at FROM player_temporal_resources WHERE player_id=$1 AND resource_key='skill_point'`, int64(actor.PlayerID)).Scan(&anchor); err != nil {
		t.Fatal(err)
	}
	if anchor != nil {
		t.Fatalf("full skill bar anchor %v, want the paused sentinel", anchor)
	}
}

func TestI9I11ANativeSkillPointBuyOrdinalResetClampAndRefusals(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	actorVIP := privilegeActor(t, database, revision)
	if _, err := privilegeService(database, database).ImportManual(ctx, authority(), importQ(actorVIP, uuid().String(), 300), op()); err != nil {
		t.Fatal(err)
	}
	snapshot, err := privilegeProvider(database).SnapshotTx(ctx, database, actorVIP.PlayerID, time.Now())
	if err != nil || snapshot.VIPLevel != 2 {
		t.Fatalf("fixture VIP level %d, %v", snapshot.VIPLevel, err)
	}
	composition := i911aComposition(database, actorVIP)
	dispatcher := composition.Dispatcher
	i911aSetScalar(t, database, actorVIP, "crystal", 100000)
	i911aSetSkillPoint(t, database, actorVIP, 10)

	first := i911aDispatch(t, dispatcher, actorVIP, 99, map[string]any{}, op())
	i911aExpect(t, first, http.StatusOK, 0)
	if first.Body["buy_skill_times"] != int64(1) || first.Body["skill_point"] != int64(20) || first.Body["skill_time"] != int64(0) {
		t.Fatalf("first buy %#v", first.Body)
	}
	if got := i911aScalar(t, database, actorVIP, "crystal"); got != 99990 {
		t.Fatalf("crystal after first buy %d", got)
	}
	replayOp := op()
	second := i911aDispatch(t, dispatcher, actorVIP, 99, map[string]any{}, replayOp)
	i911aExpect(t, second, http.StatusOK, 0)
	replay := i911aDispatch(t, dispatcher, actorVIP, 99, map[string]any{}, replayOp)
	if replay.HTTPStatus != http.StatusOK || i911aBody(t, replay.Body) != i911aBody(t, second.Body) || i911aScalar(t, database, actorVIP, "crystal") != 99970 {
		t.Fatalf("replay charged again: second %#v replay %#v crystal %d", second.Body, replay.Body, i911aScalar(t, database, actorVIP, "crystal"))
	}
	third := i911aDispatch(t, dispatcher, actorVIP, 99, map[string]any{}, op())
	i911aExpect(t, third, http.StatusOK, 0)
	if third.Body["buy_skill_times"] != int64(3) || i911aScalar(t, database, actorVIP, "crystal") != 99950 {
		t.Fatalf("third buy %#v crystal %d", third.Body, i911aScalar(t, database, actorVIP, "crystal"))
	}

	today := modes.Day(time.Now())
	i911aSetBuySkillCounter(t, database, actorVIP, today-1, 9)
	reset := i911aDispatch(t, dispatcher, actorVIP, 99, map[string]any{}, op())
	i911aExpect(t, reset, http.StatusOK, 0)
	if reset.Body["buy_skill_times"] != int64(1) || i911aScalar(t, database, actorVIP, "crystal") != 99940 {
		t.Fatalf("05:00 reset %#v crystal %d", reset.Body, i911aScalar(t, database, actorVIP, "crystal"))
	}
	detail := map[string]any{"17": map[string]any{}}
	if err := composition.Bootstrap.OverlayMID1(ctx, database, actorVIP, false, time.Now(), detail); err != nil {
		t.Fatal(err)
	}
	if detail["17"].(map[string]any)["buy_skill_times"] != int64(1) {
		t.Fatalf("MID 1 counter projection %#v", detail)
	}

	i911aSetBuySkillCounter(t, database, actorVIP, today, 329)
	clamp := i911aDispatch(t, dispatcher, actorVIP, 99, map[string]any{}, op())
	i911aExpect(t, clamp, http.StatusOK, 0)
	if clamp.Body["buy_skill_times"] != int64(330) || i911aScalar(t, database, actorVIP, "crystal") != 99640 {
		t.Fatalf("ordinal 330 %#v crystal %d", clamp.Body, i911aScalar(t, database, actorVIP, "crystal"))
	}
	i911aSetBuySkillCounter(t, database, actorVIP, today, 330)
	beyond := i911aDispatch(t, dispatcher, actorVIP, 99, map[string]any{}, op())
	i911aExpect(t, beyond, http.StatusOK, 0)
	if beyond.Body["buy_skill_times"] != int64(331) || i911aScalar(t, database, actorVIP, "crystal") != 99340 {
		t.Fatalf("ordinal clamp %#v crystal %d", beyond.Body, i911aScalar(t, database, actorVIP, "crystal"))
	}

	i911aSetScalar(t, database, actorVIP, "crystal", 5)
	i911aExpect(t, i911aDispatch(t, dispatcher, actorVIP, 99, map[string]any{}, op()), http.StatusConflict, 20005)

	noVIP := privilegeActor(t, database, revision)
	noVIPDispatcher := i911aComposition(database, noVIP).Dispatcher
	i911aExpect(t, i911aDispatch(t, noVIPDispatcher, noVIP, 99, map[string]any{}, op()), http.StatusConflict, unproven)
}

func i911aCounterRow(t *testing.T, p *postgres.Pool, a identity.ActorContext) (string, time.Time) {
	t.Helper()
	var counts string
	var updated time.Time
	if err := p.QueryRow(ctx, `SELECT counts::text,updated_at FROM daily_consumption_players WHERE player_id=$1`, int64(a.PlayerID)).Scan(&counts, &updated); err != nil {
		t.Fatal(err)
	}
	return counts, updated
}

func TestI9I11ANativeSkillPointBuyResetBoundaryAndReadDoesNotWrite(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	actor := privilegeActor(t, database, revision)
	if _, err := privilegeService(database, database).ImportManual(ctx, authority(), importQ(actor, uuid().String(), 300), op()); err != nil {
		t.Fatal(err)
	}
	catalog, err := (contentstore.Store{Queryer: database}).DailyBuyInputsTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	costTen, err := d.SkillPointBuyCost(catalog, 10)
	if err != nil {
		t.Fatal(err)
	}
	costOne, err := d.SkillPointBuyCost(catalog, 1)
	if err != nil {
		t.Fatal(err)
	}

	// The frozen decision times must not precede the privilege row this test
	// just imported, so the compared boundary lies ahead of the wall clock.
	currentDay := modes.Day(time.Now().UTC())
	offset := int64(2)
	for modes.DayBegins(currentDay + offset).Add(-time.Minute).Before(time.Now().UTC().Add(time.Minute)) {
		offset++
	}
	boundary := modes.DayBegins(currentDay + offset)
	clock := &i911aClock{at: boundary.Add(-time.Minute)}
	composition := i911aCompositionAt(database, actor, clock)
	dispatcher := composition.Dispatcher
	i911aSetScalar(t, database, actor, "crystal", 100000)
	i911aSetSkillPoint(t, database, actor, 10)
	i911aSetBuySkillCounter(t, database, actor, modes.Day(clock.at), 9)

	before := i911aDispatch(t, dispatcher, actor, 99, map[string]any{}, op())
	i911aExpect(t, before, http.StatusOK, 0)
	if before.Body["buy_skill_times"] != int64(10) || i911aScalar(t, database, actor, "crystal") != 100000-costTen {
		t.Fatalf("04:59 reply %#v crystal %d, want ordinal 10 and cost %d", before.Body, i911aScalar(t, database, actor, "crystal"), costTen)
	}
	countsBeforeRead, updatedBeforeRead := i911aCounterRow(t, database, actor)
	detailBefore := map[string]any{"17": map[string]any{}}
	if err := composition.Bootstrap.OverlayMID1(ctx, database, actor, false, clock.at, detailBefore); err != nil {
		t.Fatal(err)
	}
	if detailBefore["17"].(map[string]any)["buy_skill_times"] != int64(10) {
		t.Fatalf("MID 17 at 04:59 projected %#v", detailBefore)
	}
	if counts, updated := i911aCounterRow(t, database, actor); counts != countsBeforeRead || !updated.Equal(updatedBeforeRead) {
		t.Fatalf("MID 17 read wrote the counter row: %q %v -> %q %v", countsBeforeRead, updatedBeforeRead, counts, updated)
	}

	clock.at = boundary
	after := i911aDispatch(t, dispatcher, actor, 99, map[string]any{}, op())
	i911aExpect(t, after, http.StatusOK, 0)
	if after.Body["buy_skill_times"] != int64(1) || i911aScalar(t, database, actor, "crystal") != 100000-costTen-costOne {
		t.Fatalf("05:00 reply %#v crystal %d, want ordinal 1 and cost %d", after.Body, i911aScalar(t, database, actor, "crystal"), costOne)
	}
	countsAfterRead, updatedAfterRead := i911aCounterRow(t, database, actor)
	detailAfter := map[string]any{"17": map[string]any{}}
	if err := composition.Bootstrap.OverlayMID1(ctx, database, actor, false, clock.at, detailAfter); err != nil {
		t.Fatal(err)
	}
	if detailAfter["17"].(map[string]any)["buy_skill_times"] != int64(1) {
		t.Fatalf("MID 17 at 05:00 projected %#v", detailAfter)
	}
	if counts, updated := i911aCounterRow(t, database, actor); counts != countsAfterRead || !updated.Equal(updatedAfterRead) {
		t.Fatalf("MID 17 read wrote the counter row: %q %v -> %q %v", countsAfterRead, updatedAfterRead, counts, updated)
	}
}

func TestI9I11ANativeSkillPointItemOverCapStackAndReplay(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	actor := privilegeActor(t, database, revision)
	composition := i911aComposition(database, actor)
	dispatcher := composition.Dispatcher

	i911aSetSkillPoint(t, database, actor, 10)
	i911aStack(t, database, actor, 50001538, 5)
	useOp := op()
	use := i911aDispatch(t, dispatcher, actor, 90, map[string]any{"item_id": int64(50001538), "item_num": int64(2)}, useOp)
	i911aExpect(t, use, http.StatusOK, 0)
	if use.Body["skill_point"] != int64(30) || use.Body["skill_time"] != int64(0) || i911aSkillPoint(t, database, actor) != 30 || i911aStackQuantity(t, database, actor, 50001538) != 3 {
		t.Fatalf("over-cap use %#v point %d stack %d", use.Body, i911aSkillPoint(t, database, actor), i911aStackQuantity(t, database, actor, 50001538))
	}
	replay := i911aDispatch(t, dispatcher, actor, 90, map[string]any{"item_id": int64(50001538), "item_num": int64(2)}, useOp)
	if replay.HTTPStatus != http.StatusOK || i911aBody(t, replay.Body) != i911aBody(t, use.Body) || i911aStackQuantity(t, database, actor, 50001538) != 3 {
		t.Fatalf("replay consumed again: %#v stack %d point %d", replay, i911aStackQuantity(t, database, actor, 50001538), i911aSkillPoint(t, database, actor))
	}
	i911aExpect(t, i911aDispatch(t, dispatcher, actor, 90, map[string]any{"item_id": int64(50001538), "item_num": int64(4)}, op()), http.StatusConflict, 40002)
	if i911aStackQuantity(t, database, actor, 50001538) != 3 {
		t.Fatal("exhaustion changed the stack")
	}
	i911aExpect(t, i911aDispatch(t, dispatcher, actor, 90, map[string]any{"item_id": int64(7), "item_num": int64(1)}, op()), http.StatusConflict, unproven)
}

func TestI9I11ANativeInactiveSlotAndDismissMIDs(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	actor := privilegeActor(t, database, revision)
	dispatcher := stockruntime.InactiveModeDispatcher{Authority: playtestAuthority{actor}}
	for _, mid := range []uint16{64, 66} {
		response := dispatcher.Dispatch(ctx, playtestRequest(actor, mid, map[string]any{}))
		i911aExpect(t, response, http.StatusConflict, unproven)
		if response.Body["error_msg"] != "" {
			t.Fatalf("MID %d error_msg %#v", mid, response.Body["error_msg"])
		}
	}
}

const unproven int64 = 35028

type i911aFactRecorder struct {
	facts []objective.Fact
	err   error
}

func (r *i911aFactRecorder) ObserveTx(_ context.Context, _ tx.Tx, _ operation.Context, facts ...objective.Fact) error {
	if r.err != nil {
		return r.err
	}
	r.facts = append(r.facts, facts...)
	return nil
}

func i911aHeroSkillService(database *postgres.Pool, facts appi5.ObjectiveFacts) apphero.HeroSkillLevelService {
	runner := tx.Runner{DB: database}
	characters := characterstore.Store{Queryer: database}
	content := contentstore.Store{Queryer: database}
	inventory := i5store.Store{Queryer: database}
	return apphero.HeroSkillLevelService{
		Timed:   gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: database}}, Runner: runner},
		Reads:   runner,
		Store:   characters,
		Books:   bookService(database, database),
		Content: content, Players: i4store.PlayerRootLocker{}, Fence: inventory, Receipts: kernelstore.Store{},
		Resources:           appi5.Service{Runner: runner, Store: inventory, Content: content, Privileges: privilegeProvider(database)},
		Points:              inventory,
		Facts:               facts,
		DiscountBasisPoints: 10000,
	}
}

// i911aMissionFacts is the production objective-fact port with the real I5
// mission consumer behind it, as main_postgres wires it.
func i911aMissionFacts(database *postgres.Pool) appi5.ObjectiveFacts {
	characters := characterstore.Store{Queryer: database}
	content := contentstore.Store{Queryer: database}
	inventory := i5store.Store{Queryer: database}
	privileges := privilegeProvider(database)
	owner := appi5.Service{Runner: tx.Runner{DB: database}, Store: inventory, Content: content, Privileges: privileges, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: database}}
	owner.Missions = &appi5.MissionMaterializer{Store: inventory, Catalog: content, Activity: content,
		Observations: missioninputs.Reader{Spending: inventory, Heroes: characters, Progression: inventory,
			Campaigns: campaignstore.Store{}, Privileges: privileges, Books: bookService(database, database)}}
	return appi5.ObjectiveFacts{Owner: owner, Open: inventory}
}

func i911aMissionProgress(t *testing.T, p *postgres.Pool, a identity.ActorContext, objectiveID int64) (int64, bool, bool) {
	t.Helper()
	var progress int64
	var complete bool
	err := p.QueryRow(ctx, `SELECT progress,completed_at IS NOT NULL FROM player_mission_instances WHERE player_id=$1 AND objective_id=$2 AND definition_revision='I9_MISSIONS_V1'`, int64(a.PlayerID), objectiveID).Scan(&progress, &complete)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return 0, false, false
	}
	if err != nil {
		t.Fatal(err)
	}
	return progress, complete, true
}

func i911aHeroService(database *postgres.Pool) apphero.Service {
	characters := characterstore.Store{Queryer: database}
	content := contentstore.Store{Queryer: database}
	return apphero.Service{Store: characters, AcquisitionStore: characters, Acquisition: content,
		CollectionAdmission: apphero.CatalogCollectionAdmission{Content: content}, Content: content,
		Fencer: i5store.Store{Queryer: database}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: database}}
}

func TestI9I11ANativeSkillUpgradeAdvancesMission10007(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	actor := heroSkillLevelFixture(t, database, revision, 1000000, 10, time.Now().UTC().Add(-time.Hour))
	exec(t, database, `UPDATE player_progression SET level=10 WHERE player_id=$1`, int64(actor.PlayerID))
	exec(t, database, `UPDATE player_heroes SET level=90 WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID))
	exec(t, database, `UPDATE player_temporal_resources SET regen_anchor_at=NULL WHERE player_id=$1 AND resource_key='skill_point'`, int64(actor.PlayerID))
	dispatcher := stockruntime.HeroDispatcher{Authority: playtestAuthority{actor}, Service: i911aHeroService(database), SkillLevels: i911aHeroSkillService(database, i911aMissionFacts(database))}
	params := map[string]any{"partner_id": int64(1), "skill_colors": "1", "skill_counts": "3"}

	upgradeOp := op()
	upgrade := i911aDispatch(t, dispatcher, actor, 39, params, upgradeOp)
	i911aExpect(t, upgrade, http.StatusOK, 0)
	if progress, complete, exists := i911aMissionProgress(t, database, actor, 10007); !exists || progress != 3 || !complete {
		t.Fatalf("mission 10007 after N=3: progress %d complete %v exists %v", progress, complete, exists)
	}

	replay := i911aDispatch(t, dispatcher, actor, 39, params, upgradeOp)
	if replay.HTTPStatus != http.StatusOK {
		t.Fatalf("R6 replay status %d body %#v", replay.HTTPStatus, replay.Body)
	}
	if progress, _, _ := i911aMissionProgress(t, database, actor, 10007); progress != 3 {
		t.Fatalf("R6 replay advanced mission 10007 to %d", progress)
	}

	exec(t, database, `UPDATE player_heroes SET updated_at=clock_timestamp()+interval '1 hour' WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID))
	var forwardStamp time.Time
	if err := database.QueryRow(ctx, `SELECT updated_at FROM player_heroes WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID)).Scan(&forwardStamp); err != nil {
		t.Fatal(err)
	}
	// K3: a decision before the stored hero write is clamped, not refused.
	forward := i911aDispatch(t, dispatcher, actor, 39, map[string]any{"partner_id": int64(1), "skill_colors": "1", "skill_counts": "1"}, op())
	i911aExpect(t, forward, http.StatusOK, 0)
	var clamped time.Time
	if err := database.QueryRow(ctx, `SELECT updated_at FROM player_heroes WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID)).Scan(&clamped); err != nil {
		t.Fatal(err)
	}
	if !clamped.Equal(forwardStamp) {
		t.Fatalf("forward write clamp %v want %v", clamped, forwardStamp)
	}
	if progress, _, _ := i911aMissionProgress(t, database, actor, 10007); progress != 4 {
		t.Fatalf("forward write did not advance mission 10007 to 4: %d", progress)
	}

	exec(t, database, `UPDATE player_heroes SET raw_skill_1=150,state_version=state_version+1,updated_at=clock_timestamp()-interval '1 hour' WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID))
	noChange := i911aDispatch(t, dispatcher, actor, 39, map[string]any{"partner_id": int64(1), "skill_colors": "1", "skill_counts": "1"}, op())
	i911aExpect(t, noChange, http.StatusConflict, unproven)
	if progress, _, _ := i911aMissionProgress(t, database, actor, 10007); progress != 4 {
		t.Fatalf("N=0 plan advanced mission 10007 to %d", progress)
	}
}

func TestI9I11ANativeSkillUpgradeRefusalBodyAndFact107(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	actor := heroSkillLevelFixture(t, database, revision, 1000000, 10, time.Now().UTC().Add(-time.Hour))
	recorder := &i911aFactRecorder{}
	inventory := i5store.Store{Queryer: database}
	facts := appi5.ObjectiveFacts{Owner: appi5.Service{Store: inventory, Receipts: kernelstore.Store{}}, Open: inventory, Observer: recorder}
	service := i911aHeroSkillService(database, facts)
	dispatcher := stockruntime.HeroDispatcher{Authority: playtestAuthority{actor}, Service: i911aHeroService(database), SkillLevels: service}
	exec(t, database, `UPDATE player_temporal_resources SET regen_anchor_at=NULL WHERE player_id=$1 AND resource_key='skill_point'`, int64(actor.PlayerID))

	exec(t, database, `UPDATE player_heroes SET updated_at=clock_timestamp()+interval '1 hour' WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID))
	// K3: a decision before the stored hero write is clamped, not refused.
	forward := i911aDispatch(t, dispatcher, actor, 39, map[string]any{"partner_id": int64(1), "skill_colors": "1", "skill_counts": "1"}, op())
	i911aExpect(t, forward, http.StatusOK, 0)
	if forward.Body["skills"] != "2|1|1|1|1|1" || forward.Body["is_success"] != int64(1) {
		t.Fatalf("MID 39 forward body %#v", forward.Body)
	}
	if len(recorder.facts) != 1 || recorder.facts[0].Kind != "HERO_SKILL_UPGRADED" || recorder.facts[0].Delta != 1 {
		t.Fatalf("forward write facts %#v", recorder.facts)
	}
	// Fixture reset only: the accepted forward-dated write already applied.
	exec(t, database, `UPDATE player_heroes SET raw_skill_1=1,state_version=state_version+1,updated_at=clock_timestamp()-interval '1 hour' WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID))
	exec(t, database, `UPDATE player_temporal_resources SET stored_amount=10,regen_anchor_at=NULL,state_version=state_version+1,updated_at=clock_timestamp() WHERE player_id=$1 AND resource_key='skill_point'`, int64(actor.PlayerID))
	exec(t, database, `UPDATE player_currency_balances SET amount=1000000 WHERE player_id=$1 AND resource_key='mana'`, int64(actor.PlayerID))
	recorder.facts = nil

	upgradeOp := op()
	upgrade := i911aDispatch(t, dispatcher, actor, 39, map[string]any{"partner_id": int64(1), "skill_colors": "1", "skill_counts": "2"}, upgradeOp)
	i911aExpect(t, upgrade, http.StatusOK, 0)
	if upgrade.Body["is_success"] != int64(1) || upgrade.Body["skills"] != "3|1|1|1|1|1" {
		t.Fatalf("MID 39 upgrade %#v", upgrade.Body)
	}
	if len(recorder.facts) != 1 || recorder.facts[0].Kind != "HERO_SKILL_UPGRADED" || recorder.facts[0].Delta != 2 {
		t.Fatalf("fact 107 %#v", recorder.facts)
	}
	replay := i911aDispatch(t, dispatcher, actor, 39, map[string]any{"partner_id": int64(1), "skill_colors": "1", "skill_counts": "2"}, upgradeOp)
	if replay.HTTPStatus != http.StatusOK || len(recorder.facts) != 1 || i911aSkillPoint(t, database, actor) != 8 {
		t.Fatalf("replay emitted fact or charged: %#v point %d", replay.Body, i911aSkillPoint(t, database, actor))
	}

	recorder.err = context.Canceled
	failed := i911aDispatch(t, dispatcher, actor, 39, map[string]any{"partner_id": int64(1), "skill_colors": "1", "skill_counts": "1"}, op())
	if failed.HTTPStatus == http.StatusOK {
		t.Fatalf("observer failure did not roll back: %#v", failed)
	}
	if levels := skillRead(t, database, actor, 1).RawSkills.Levels; levels != [6]int64{3, 1, 1, 1, 1, 1} {
		t.Fatalf("rollback kept levels %v", levels)
	}
	recorder.err = nil

	exec(t, database, `UPDATE player_heroes SET raw_skill_1=2,state_version=state_version+1,updated_at=clock_timestamp()-interval '1 hour' WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID))
	exec(t, database, `UPDATE player_currency_balances SET amount=0 WHERE player_id=$1 AND resource_key='mana'`, int64(actor.PlayerID))
	noMana := i911aDispatch(t, dispatcher, actor, 39, map[string]any{"partner_id": int64(1), "skill_colors": "1", "skill_counts": "1"}, op())
	i911aExpect(t, noMana, http.StatusConflict, 20006)
	if noMana.Body["skills"] != "2|1|1|1|1|1" || noMana.Body["is_success"] != int64(0) || noMana.Body["skill_point"] != int64(8) || noMana.Body["skill_time"] != i911aSkillTime(t, database, actor) {
		t.Fatalf("insufficient-mana refusal body %#v", noMana.Body)
	}
	exec(t, database, `UPDATE player_temporal_resources SET stored_amount=0 WHERE player_id=$1 AND resource_key='skill_point'`, int64(actor.PlayerID))
	bothShort := i911aDispatch(t, dispatcher, actor, 39, map[string]any{"partner_id": int64(1), "skill_colors": "1", "skill_counts": "1"}, op())
	i911aExpect(t, bothShort, http.StatusConflict, 20006)
	exec(t, database, `UPDATE player_currency_balances SET amount=1000000 WHERE player_id=$1 AND resource_key='mana'`, int64(actor.PlayerID))
	noPoints := i911aDispatch(t, dispatcher, actor, 39, map[string]any{"partner_id": int64(1), "skill_colors": "1", "skill_counts": "1"}, op())
	i911aExpect(t, noPoints, http.StatusConflict, unproven)
	if noPoints.Body["skills"] != "2|1|1|1|1|1" || noPoints.Body["is_success"] != int64(0) || noPoints.Body["skill_point"] != int64(0) || noPoints.Body["skill_time"] != i911aSkillTime(t, database, actor) {
		t.Fatalf("insufficient-points refusal body %#v", noPoints.Body)
	}
	exec(t, database, `UPDATE player_temporal_resources SET stored_amount=10 WHERE player_id=$1 AND resource_key='skill_point'`, int64(actor.PlayerID))
	exec(t, database, `UPDATE player_heroes SET raw_skill_1=150,state_version=state_version+1,updated_at=clock_timestamp()-interval '1 hour' WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID))
	noChange := i911aDispatch(t, dispatcher, actor, 39, map[string]any{"partner_id": int64(1), "skill_colors": "1", "skill_counts": "1"}, op())
	i911aExpect(t, noChange, http.StatusConflict, unproven)
	// 10 is the VIP0 natural cap, so the materialized regen anchor is paused (0).
	if noChange.Body["skills"] != "150|1|1|1|1|1" || noChange.Body["is_success"] != int64(0) || noChange.Body["skill_point"] != int64(10) || noChange.Body["skill_time"] != int64(0) {
		t.Fatalf("no-change refusal body %#v", noChange.Body)
	}
}

func TestI9I11ANativeSkillUpgradeRefusalLeavesCommittedState(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	cases := []struct {
		name       string
		mid        uint16
		mana       int64
		points     int64
		anchor     time.Time
		params     map[string]any
		code       int64
		pointValue int64
	}{
		{name: "MID39_insufficient_mana", mid: 39, mana: 0, points: 10, anchor: time.Now().UTC().Add(-time.Hour), params: map[string]any{"partner_id": int64(1), "skill_colors": "1", "skill_counts": "1"}, code: 20006, pointValue: 10},
		{name: "MID53_insufficient_points", mid: 53, mana: 1000000, points: 0, anchor: time.Now().UTC(), params: map[string]any{"partner_id": int64(1), "skill_index": int64(1)}, code: unproven, pointValue: 0},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			actor := heroSkillLevelFixture(t, database, revision, testCase.mana, testCase.points, testCase.anchor)
			dispatcher := stockruntime.HeroDispatcher{Authority: playtestAuthority{actor}, Service: i911aHeroService(database), SkillLevels: i911aHeroSkillService(database, i911aMissionFacts(database))}
			// A root from the previous game day makes the first mission materialization roll over.
			now := time.Now().UTC()
			exec(t, database, `INSERT INTO player_mission_roots(player_id,day,week)VALUES($1,$2,$3) ON CONFLICT(player_id) DO UPDATE SET day=excluded.day,week=excluded.week`, int64(actor.PlayerID), modes.Day(now)-1, modes.WeekStart(now))
			before := i911aCommittedState(t, database, actor, 1)
			response := i911aDispatch(t, dispatcher, actor, testCase.mid, testCase.params, op())
			i911aExpect(t, response, http.StatusConflict, testCase.code)
			if response.Body["skill_point"] != testCase.pointValue {
				t.Fatalf("refusal body %#v", response.Body)
			}
			if _, ok := response.Body["skill_time"]; !ok {
				t.Fatalf("refusal body lacks committed skill_time %#v", response.Body)
			}
			if testCase.mid == 39 && (response.Body["is_success"] != int64(0) || response.Body["skills"] == nil) {
				t.Fatalf("MID 39 refusal body %#v", response.Body)
			}
			if after := i911aCommittedState(t, database, actor, 1); after != before {
				t.Fatalf("refusal changed committed state\nbefore %s\nafter  %s", before, after)
			}
		})
	}
}
