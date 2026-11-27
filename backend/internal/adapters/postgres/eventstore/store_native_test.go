//go:build postgres

package eventstore_test

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"reflect"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/eventstore"
	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	appevents "gxb.local/backend/v2/internal/application/events"
	"gxb.local/backend/v2/internal/application/operator"
	eventscontent "gxb.local/backend/v2/internal/content/events"
	domainevents "gxb.local/backend/v2/internal/domain/events"
	otadomain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func e1Pool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I11A_E1_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_E1_DSN required (ops/testing/fresh_db.sh e1)")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

type fakeCoverage struct{}

func (fakeCoverage) Covers(context.Context, otadomain.CoversRequest) (otadomain.CoversResult, error) {
	return otadomain.CoversResult{Status: otadomain.CoversCovered}, nil
}

type missingCoverage struct{}

func (missingCoverage) Covers(context.Context, otadomain.CoversRequest) (otadomain.CoversResult, error) {
	return otadomain.CoversResult{Status: otadomain.CoversMissing, MissingClientPaths: []string{"windows/activities/1084/main.csb"}}, nil
}

type fakeGifts struct{}

func (fakeGifts) GiftTx(context.Context, tx.Queryer, int64) ([]domainevents.RewardLine, bool, error) {
	return nil, false, nil
}

type fakeCatalogue struct{}

func (fakeCatalogue) CheckRewardsTx(context.Context, tx.Queryer, []domainevents.RewardLine) error {
	return nil
}

type fakeContentRevision struct{ revision string }

func (content *fakeContentRevision) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return content.revision, nil
}

func e1BusFrom(t *testing.T, pool *pg.Pool, coverage appevents.Coverage) operator.Bus {
	t.Helper()
	hooks, err := appevents.NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	commands := appevents.Commands{Store: eventstore.Store{}, Coverage: coverage, Gifts: fakeGifts{}, Catalogue: fakeCatalogue{}, Hooks: hooks}
	return operator.Bus{Runner: tx.Runner{DB: pool}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: commands.Handlers()}
}

func e1Bus(t *testing.T, pool *pg.Pool) operator.Bus {
	return e1BusFrom(t, pool, fakeCoverage{})
}

func e1Command(t *testing.T, name string, revision *int64, scope string, payload any) operator.Command {
	t.Helper()
	key, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(name, operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: scope, Reason: "i11a e1 native", SemanticKey: key.String(), ExpectedRevision: revision}, raw)
	if err != nil {
		t.Fatal(err)
	}
	return command
}

func e1Execute(t *testing.T, bus operator.Bus, command operator.Command) operator.Outcome {
	t.Helper()
	outcome, err := bus.Execute(context.Background(), command)
	if err != nil {
		t.Fatalf("%s: %v", command.ModuleCommand, err)
	}
	return outcome
}

func e1Code(t *testing.T, outcome operator.Outcome) string {
	t.Helper()
	var refusal struct {
		Code string `json:"error_code"`
	}
	if err := json.Unmarshal(outcome.Result, &refusal); err != nil {
		t.Fatalf("result %s: %v", outcome.Result, err)
	}
	return refusal.Code
}

func e1DefinitionJSON(activityID, revision, amount int64) string {
	return `{"activity_id":` + strconv.FormatInt(activityID, 10) + `,"revision":` + strconv.FormatInt(revision, 10) +
		`,"archetype":"TIERED_CLAIM","client_requirements":{},"default_days":-1,"tiers":[{"id":1,"requirement":{"kind":"player_level","value":10},"choices":[{"lines":[{"kind":"item","item_id":50001003,"amount":` +
		strconv.FormatInt(amount, 10) + `}]}]}]}`
}

func e1Deploy(t *testing.T, bus operator.Bus, activityID, revision, amount int64) {
	t.Helper()
	outcome := e1Execute(t, bus, e1Command(t, "events.definition.deploy", nil, "global", json.RawMessage(e1DefinitionJSON(activityID, revision, amount))))
	if outcome.State != operator.StateApplied {
		t.Fatalf("deploy %d/%d: %s %s", activityID, revision, outcome.State, outcome.Result)
	}
}

func e1Schedule(t *testing.T, bus operator.Bus, activityID int64, start, duration string) appevents.OccurrenceView {
	return e1ScheduleOn(t, bus, 1, activityID, start, duration)
}

func e1ScheduleOn(t *testing.T, bus operator.Bus, server, activityID int64, start, duration string) appevents.OccurrenceView {
	t.Helper()
	payload := map[string]any{"activity_id": activityID, "logical_server_ids": []int64{server}, "duration": duration, "start": start}
	outcome := e1Execute(t, bus, e1Command(t, "events.schedule", nil, "global", payload))
	if outcome.State != operator.StateApplied {
		t.Fatalf("schedule %d: %s %s", activityID, outcome.State, outcome.Result)
	}
	var result struct {
		Occurrences []appevents.OccurrenceView `json:"occurrences"`
	}
	if err := json.Unmarshal(outcome.Result, &result); err != nil || len(result.Occurrences) != 1 {
		t.Fatalf("schedule result %s: %v", outcome.Result, err)
	}
	return result.Occurrences[0]
}

func e1Mutate(t *testing.T, bus operator.Bus, name string, occurrenceID, revision int64, extra map[string]any) operator.Outcome {
	t.Helper()
	payload := map[string]any{"occurrence_id": occurrenceID}
	for key, value := range extra {
		payload[key] = value
	}
	return e1Execute(t, bus, e1Command(t, name, &revision, "global", payload))
}

func decodeOccurrenceView(t *testing.T, outcome operator.Outcome) appevents.OccurrenceView {
	t.Helper()
	var view appevents.OccurrenceView
	if err := json.Unmarshal(outcome.Result, &view); err != nil {
		t.Fatalf("occurrence view %s: %v", outcome.Result, err)
	}
	return view
}

func TestDeployIdempotentAndImmutable(t *testing.T) {
	bus := e1Bus(t, e1Pool(t))
	definition := json.RawMessage(e1DefinitionJSON(1098, 1, 2))
	first := e1Execute(t, bus, e1Command(t, "events.definition.deploy", nil, "global", definition))
	if first.State != operator.StateApplied {
		t.Fatalf("deploy: %s %s", first.State, first.Result)
	}
	var created struct {
		Created bool `json:"created"`
	}
	if err := json.Unmarshal(first.Result, &created); err != nil || !created.Created {
		t.Fatalf("first deploy must create: %s %v", first.Result, err)
	}
	second := e1Execute(t, bus, e1Command(t, "events.definition.deploy", nil, "global", definition))
	var replay struct {
		Created bool `json:"created"`
	}
	if err := json.Unmarshal(second.Result, &replay); err != nil || replay.Created {
		t.Fatalf("same body must be idempotent: %s %v", second.Result, err)
	}
	changed := e1Execute(t, bus, e1Command(t, "events.definition.deploy", nil, "global", json.RawMessage(e1DefinitionJSON(1098, 1, 3))))
	if changed.State != operator.StateRefused || e1Code(t, changed) != appevents.CodeRevisionExists {
		t.Fatalf("another body must be refused EVENT_REVISION_EXISTS: %s %s", changed.State, changed.Result)
	}
	successor := e1Execute(t, bus, e1Command(t, "events.definition.deploy", nil, "global", json.RawMessage(e1DefinitionJSON(1098, 2, 3))))
	if successor.State != operator.StateApplied {
		t.Fatalf("revision 2: %s %s", successor.State, successor.Result)
	}
}

func TestReplayedCommandKeyReturnsStoredResult(t *testing.T) {
	bus := e1Bus(t, e1Pool(t))
	command := e1Command(t, "events.definition.deploy", nil, "global", json.RawMessage(e1DefinitionJSON(1072, 1, 2)))
	first := e1Execute(t, bus, command)
	if first.State != operator.StateApplied || first.Replayed {
		t.Fatalf("first: %+v", first)
	}
	second := e1Execute(t, bus, command)
	var firstResult, secondResult any
	if err := json.Unmarshal(first.Result, &firstResult); err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal(second.Result, &secondResult); err != nil {
		t.Fatal(err)
	}
	if second.State != operator.StateApplied || !second.Replayed || !reflect.DeepEqual(firstResult, secondResult) {
		t.Fatalf("replay: %+v first %s", second, first.Result)
	}
}

func TestGiftUnsupportedRefused(t *testing.T) {
	bus := e1Bus(t, e1Pool(t))
	payload := json.RawMessage(`{"activity_id":1073,"revision":1,"archetype":"TIERED_CLAIM","client_requirements":{},"tiers":[{"id":1,"requirement":{"kind":"player_level","value":10},"choices":[{"gift_id":90001428}]}]}`)
	outcome := e1Execute(t, bus, e1Command(t, "events.definition.deploy", nil, "global", payload))
	if outcome.State != operator.StateRefused || e1Code(t, outcome) != appevents.CodeGiftUnsupported {
		t.Fatalf("missing gift row must be EVENT_GIFT_UNSUPPORTED: %s %s", outcome.State, outcome.Result)
	}
}

func TestScheduleOverlapAndLifecycle(t *testing.T) {
	bus := e1Bus(t, e1Pool(t))
	e1Deploy(t, bus, 1080, 1, 2)
	start := time.Now().UTC().Add(48 * time.Hour).Format(time.RFC3339)
	scheduled := e1Schedule(t, bus, 1080, start, "3d")
	if scheduled.State != string(domainevents.PhaseScheduled) || scheduled.Revision != 1 || scheduled.EndsAt == nil {
		t.Fatalf("scheduled = %+v", scheduled)
	}
	if scheduled.ClaimUntil == nil || scheduled.ClaimUntil.Sub(*scheduled.EndsAt) != 24*time.Hour {
		t.Fatalf("the claim window must come from the seeded settings row: %+v", scheduled)
	}
	overlapPayload := map[string]any{"activity_id": 1080, "logical_server_ids": []int64{1}, "duration": "1d", "start": start}
	overlap := e1Execute(t, bus, e1Command(t, "events.schedule", nil, "global", overlapPayload))
	if overlap.State != operator.StateRefused || e1Code(t, overlap) != appevents.CodeOverlap {
		t.Fatalf("overlap must be EVENT_OVERLAP: %s %s", overlap.State, overlap.Result)
	}
	staleCancel := e1Mutate(t, bus, "events.cancel", scheduled.ID, 99, nil)
	if staleCancel.State != operator.StateRefused || e1Code(t, staleCancel) != appevents.CodeStale {
		t.Fatalf("stale cancel must be EVENT_STALE: %s %s", staleCancel.State, staleCancel.Result)
	}
	cancelled := e1Mutate(t, bus, "events.cancel", scheduled.ID, 1, nil)
	if cancelled.State != operator.StateApplied {
		t.Fatalf("cancel: %s %s", cancelled.State, cancelled.Result)
	}
	if view := decodeOccurrenceView(t, cancelled); view.State != string(domainevents.PhaseCancelled) || view.Revision != 2 {
		t.Fatalf("cancelled view = %+v", view)
	}
	again := e1Schedule(t, bus, 1080, start, "3d")
	if again.ID == scheduled.ID {
		t.Fatal("a cancelled occurrence must not block a new one")
	}
	setPermanent := e1Mutate(t, bus, "events.set_permanent", again.ID, 1, nil)
	if setPermanent.State != operator.StateApplied {
		t.Fatalf("set_permanent: %s %s", setPermanent.State, setPermanent.Result)
	}
	if view := decodeOccurrenceView(t, setPermanent); view.EndsAt != nil || view.ClaimUntil != nil || view.Revision != 2 {
		t.Fatalf("permanent view = %+v", view)
	}
	permanentExtend := e1Mutate(t, bus, "events.extend", again.ID, 2, map[string]any{"duration": "1d"})
	if permanentExtend.State != operator.StateRefused || e1Code(t, permanentExtend) != appevents.CodeStateInvalid {
		t.Fatalf("extend permanent must be EVENT_STATE_INVALID: %s %s", permanentExtend.State, permanentExtend.Result)
	}
}

func TestExtendAndEndNow(t *testing.T) {
	bus := e1Bus(t, e1Pool(t))
	e1Deploy(t, bus, 1081, 1, 2)
	e1Deploy(t, bus, 1085, 1, 2)
	future := time.Now().UTC().Add(48 * time.Hour)
	timed := e1Schedule(t, bus, 1081, future.Format(time.RFC3339), "3d")
	originalEnd := *timed.EndsAt
	extended := e1Mutate(t, bus, "events.extend", timed.ID, 1, map[string]any{"duration": "1d"})
	if extended.State != operator.StateApplied {
		t.Fatalf("extend: %s %s", extended.State, extended.Result)
	}
	if view := decodeOccurrenceView(t, extended); !view.EndsAt.Equal(originalEnd.Add(24*time.Hour)) || view.Revision != 2 {
		t.Fatalf("extended view = %+v", view)
	}
	stale := e1Mutate(t, bus, "events.extend", timed.ID, 1, map[string]any{"duration": "1d"})
	if stale.State != operator.StateRefused || e1Code(t, stale) != appevents.CodeStale {
		t.Fatalf("stale extend: %s %s", stale.State, stale.Result)
	}

	past := time.Now().UTC().Add(-time.Hour)
	running := e1Schedule(t, bus, 1085, past.Format(time.RFC3339), "1d")
	if running.State != string(domainevents.PhaseRunning) {
		t.Fatalf("running = %+v", running)
	}
	ended := e1Mutate(t, bus, "events.end_now", running.ID, 1, nil)
	if ended.State != operator.StateApplied {
		t.Fatalf("end_now: %s %s", ended.State, ended.Result)
	}
	if view := decodeOccurrenceView(t, ended); view.State != string(domainevents.PhaseClaimWindow) || view.Revision != 2 {
		t.Fatalf("ended view = %+v", view)
	}
	repeat := e1Mutate(t, bus, "events.end_now", running.ID, 1, nil)
	if repeat.State != operator.StateRefused || e1Code(t, repeat) != appevents.CodeStale {
		t.Fatalf("stale end_now: %s %s", repeat.State, repeat.Result)
	}
}

func TestConcurrentOverlapRefused(t *testing.T) {
	pool := e1Pool(t)
	bus := e1Bus(t, pool)
	e1Deploy(t, bus, 1082, 1, 2)
	start := time.Now().UTC().Add(72 * time.Hour).Format(time.RFC3339)
	payload := map[string]any{"activity_id": 1082, "logical_server_ids": []int64{1}, "duration": "3d", "start": start}

	results := make([]operator.Outcome, 2)
	errs := make([]error, 2)
	started := make(chan struct{})
	var wait sync.WaitGroup
	for index := 0; index < 2; index++ {
		wait.Add(1)
		go func(slot int) {
			defer wait.Done()
			<-started
			results[slot], errs[slot] = bus.Execute(context.Background(), e1Command(t, "events.schedule", nil, "global", payload))
		}(index)
	}
	close(started)
	wait.Wait()

	applied, refused := 0, 0
	for index, result := range results {
		if errs[index] != nil {
			t.Fatalf("concurrent schedule: %v", errs[index])
		}
		switch result.State {
		case operator.StateApplied:
			applied++
		case operator.StateRefused:
			if code := e1Code(t, result); code != appevents.CodeOverlap {
				t.Fatalf("loser code = %s, want EVENT_OVERLAP", code)
			}
			refused++
		default:
			t.Fatalf("unexpected state %s", result.State)
		}
	}
	if applied != 1 || refused != 1 {
		t.Fatalf("applied=%d refused=%d, want exactly one of each", applied, refused)
	}
}

func seedPlayer(t *testing.T, pool *pg.Pool, playerID int64, uid string) {
	t.Helper()
	ctx := context.Background()
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO accounts(account_id,status,account_uid,created_at)
		VALUES(gen_random_uuid(),'ACTIVE',$1,now()) ON CONFLICT (account_uid) DO NOTHING`, uid); err != nil {
		t.Fatalf("seed account: %v", err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)
		SELECT $1,account_id,1,now(),'e1-native' FROM accounts WHERE account_uid=$2 ON CONFLICT (player_id) DO NOTHING`, playerID, uid); err != nil {
		t.Fatalf("seed player: %v", err)
	}
}

func TestClaimUniqueUnderConcurrentInserts(t *testing.T) {
	pool := e1Pool(t)
	bus := e1Bus(t, pool)
	e1Deploy(t, bus, 1083, 1, 2)
	occurrence := e1Schedule(t, bus, 1083, time.Now().UTC().Add(-time.Hour).Format(time.RFC3339), "3d")

	ctx := context.Background()
	const playerID int64 = 100001
	seedPlayer(t, pool, playerID, "e1-claim-test")

	insert := func() (bool, error) {
		transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
		if err != nil {
			return false, err
		}
		defer func() { _ = transaction.Rollback(ctx) }()
		_, inserted, err := (appevents.ClaimLedger{Store: eventstore.Store{}}).InsertClaimTx(ctx, transaction, appevents.Claim{PlayerID: playerID, OccurrenceID: occurrence.ID, Tier: 1, Period: "once", Choice: 1, ClaimedAt: time.Now().UTC(), GrantReceipt: "receipt"})
		if err != nil {
			return false, err
		}
		if err := transaction.Commit(ctx); err != nil {
			return false, err
		}
		return inserted, nil
	}

	inserted := make([]bool, 2)
	errs := make([]error, 2)
	started := make(chan struct{})
	var wait sync.WaitGroup
	for index := 0; index < 2; index++ {
		wait.Add(1)
		go func(slot int) {
			defer wait.Done()
			<-started
			inserted[slot], errs[slot] = insert()
		}(index)
	}
	close(started)
	wait.Wait()

	winners := 0
	for index := range inserted {
		if errs[index] != nil {
			t.Fatalf("concurrent claim %d: %v", index, errs[index])
		}
		if inserted[index] {
			winners++
		}
	}
	if winners != 1 {
		t.Fatalf("exactly one concurrent insert must win, got %d", winners)
	}
	claims, err := (eventstore.Store{}).ClaimsForPlayerTx(ctx, pool, playerID, occurrence.ID, appevents.DefaultClaimsLimit)
	if err != nil || len(claims) != 1 || claims[0].Choice != 1 {
		t.Fatalf("stored claims = %+v, %v", claims, err)
	}
}

func refusalCode(t *testing.T, err error) string {
	t.Helper()
	var refusal *operator.Refusal
	if !errors.As(err, &refusal) {
		t.Fatalf("want a refusal, got %v", err)
	}
	return refusal.Code
}

func TestClaimReplayAnswersSameTier(t *testing.T) {
	pool := e1Pool(t)
	bus := e1Bus(t, pool)
	e1Deploy(t, bus, 1092, 1, 2)
	occurrence := e1Schedule(t, bus, 1092, time.Now().UTC().Add(-time.Hour).Format(time.RFC3339), "3d")
	const playerID int64 = 100002
	seedPlayer(t, pool, playerID, "e1-claim-tier")

	ctx := context.Background()
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = transaction.Rollback(ctx) }()
	ledger := appevents.ClaimLedger{Store: eventstore.Store{}}
	claim := func(tier int64, choice int, receipt string) (appevents.Claim, bool) {
		row, inserted, err := ledger.InsertClaimTx(ctx, transaction, appevents.Claim{PlayerID: playerID, OccurrenceID: occurrence.ID, Tier: tier, Period: "once", Choice: choice, ClaimedAt: time.Now().UTC(), GrantReceipt: receipt})
		if err != nil {
			t.Fatal(err)
		}
		return row, inserted
	}
	if _, inserted := claim(1, 1, "tier-one"); !inserted {
		t.Fatal("tier 1 must insert")
	}
	if _, inserted := claim(2, 2, "tier-two"); !inserted {
		t.Fatal("tier 2 must insert")
	}
	replay, inserted := claim(2, 3, "tier-two-replay")
	if inserted {
		t.Fatal("the repeated tier 2 key must not insert")
	}
	if replay.Tier != 2 || replay.Choice != 2 || replay.GrantReceipt != "tier-two" {
		t.Fatalf("replay answered another tier: %+v", replay)
	}
}

func TestExtendAndSetPermanentRefuseOverlap(t *testing.T) {
	pool := e1Pool(t)
	bus := e1Bus(t, pool)
	e1Deploy(t, bus, 1093, 1, 2)
	e1Deploy(t, bus, 1094, 1, 2)
	ctx := context.Background()
	store := eventstore.Store{}
	base := time.Now().UTC().Add(2 * time.Hour)

	first := e1ScheduleOn(t, bus, 1, 1093, base.Format(time.RFC3339), "1d")
	later := e1ScheduleOn(t, bus, 1, 1093, base.Add(72*time.Hour).Format(time.RFC3339), "1d")
	extended := e1Mutate(t, bus, "events.extend", first.ID, 1, map[string]any{"duration": "7d"})
	if extended.State != operator.StateRefused || e1Code(t, extended) != appevents.CodeOverlap {
		t.Fatalf("extend into a later occurrence must be EVENT_OVERLAP: %s %s", extended.State, extended.Result)
	}
	unchanged, err := store.OccurrenceTx(ctx, pool, first.ID)
	if err != nil {
		t.Fatal(err)
	}
	if unchanged.Revision != 1 || unchanged.EndsAt == nil || !unchanged.EndsAt.Equal(*first.EndsAt) {
		t.Fatalf("the refused extend changed the row: %+v", unchanged)
	}
	other, err := store.OccurrenceTx(ctx, pool, later.ID)
	if err != nil || other.Revision != 1 {
		t.Fatalf("the other row changed: %+v %v", other, err)
	}

	permanentCandidate := e1ScheduleOn(t, bus, 1, 1094, base.Format(time.RFC3339), "1d")
	permanentLater := e1ScheduleOn(t, bus, 1, 1094, base.Add(72*time.Hour).Format(time.RFC3339), "1d")
	madePermanent := e1Mutate(t, bus, "events.set_permanent", permanentCandidate.ID, 1, nil)
	if madePermanent.State != operator.StateRefused || e1Code(t, madePermanent) != appevents.CodeOverlap {
		t.Fatalf("set_permanent into a later occurrence must be EVENT_OVERLAP: %s %s", madePermanent.State, madePermanent.Result)
	}
	unchangedPermanent, err := store.OccurrenceTx(ctx, pool, permanentCandidate.ID)
	if err != nil {
		t.Fatal(err)
	}
	if unchangedPermanent.Revision != 1 || unchangedPermanent.EndsAt == nil {
		t.Fatalf("the refused set_permanent changed the row: %+v", unchangedPermanent)
	}
	if _, err := store.OccurrenceTx(ctx, pool, permanentLater.ID); err != nil {
		t.Fatal(err)
	}
}

func TestClaimSeesEndedOccurrence(t *testing.T) {
	pool := e1Pool(t)
	bus := e1Bus(t, pool)
	e1Deploy(t, bus, 1095, 1, 2)
	occurrence := e1Schedule(t, bus, 1095, time.Now().UTC().Add(-3*time.Hour).Format(time.RFC3339), "1d")
	const playerID int64 = 100003
	seedPlayer(t, pool, playerID, "e1-claim-ended")
	ctx := context.Background()

	at := time.Now().UTC()
	sealed, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	var lockedID int64
	if err := sealed.QueryRow(ctx, `SELECT id FROM event_occurrences WHERE id=$1 FOR UPDATE`, occurrence.ID).Scan(&lockedID); err != nil {
		t.Fatalf("lock occurrence: %v", err)
	}
	if _, err := sealed.Exec(ctx, `UPDATE event_occurrences SET ends_at=$2,claim_until=$3,revision=revision+1 WHERE id=$1`, occurrence.ID, at.Add(-2*time.Hour), at.Add(-time.Hour)); err != nil {
		t.Fatalf("end occurrence: %v", err)
	}
	if err := sealed.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	claiming, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = claiming.Rollback(ctx) }()
	_, _, err = (appevents.ClaimLedger{Store: eventstore.Store{}}).InsertClaimTx(ctx, claiming, appevents.Claim{PlayerID: playerID, OccurrenceID: occurrence.ID, Tier: 1, Period: "once", Choice: 1, ClaimedAt: at, GrantReceipt: "ended"})
	if code := refusalCode(t, err); code != appevents.CodeStateInvalid {
		t.Fatalf("code = %s, want %s", code, appevents.CodeStateInvalid)
	}
	claims, err := (eventstore.Store{}).ClaimsForPlayerTx(ctx, pool, playerID, occurrence.ID, appevents.DefaultClaimsLimit)
	if err != nil || len(claims) != 0 {
		t.Fatalf("a refused claim must not insert: %+v %v", claims, err)
	}
}

func TestScheduleRefusesUnknownServer(t *testing.T) {
	pool := e1Pool(t)
	bus := e1Bus(t, pool)
	e1Deploy(t, bus, 1096, 1, 2)
	ctx := context.Background()
	var unknown int64
	if err := pool.Raw().QueryRow(ctx, `SELECT COALESCE(MAX(logical_server_id),0)+1000 FROM logical_servers`).Scan(&unknown); err != nil {
		t.Fatal(err)
	}
	payload := map[string]any{"activity_id": 1096, "logical_server_ids": []int64{unknown}, "duration": "1d", "start": time.Now().UTC().Add(24 * time.Hour).Format(time.RFC3339)}
	outcome := e1Execute(t, bus, e1Command(t, "events.schedule", nil, "global", payload))
	if outcome.State != operator.StateRefused || e1Code(t, outcome) != appevents.CodeServerUnknown {
		t.Fatalf("unknown server must be EVENT_SERVER_UNKNOWN: %s %s", outcome.State, outcome.Result)
	}
}

func TestOccurrenceShowCountsEveryClaim(t *testing.T) {
	pool := e1Pool(t)
	bus := e1Bus(t, pool)
	e1Deploy(t, bus, 1097, 1, 2)
	occurrence := e1Schedule(t, bus, 1097, time.Now().UTC().Add(-time.Hour).Format(time.RFC3339), "3d")
	const playerID int64 = 100004
	seedPlayer(t, pool, playerID, "e1-claim-count")
	ctx := context.Background()

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = transaction.Rollback(ctx) }()
	ledger := appevents.ClaimLedger{Store: eventstore.Store{}}
	for tier := int64(1); tier <= 3; tier++ {
		if _, _, err := ledger.InsertClaimTx(ctx, transaction, appevents.Claim{PlayerID: playerID, OccurrenceID: occurrence.ID, Tier: tier, Period: "once", Choice: 1, ClaimedAt: time.Now().UTC(), GrantReceipt: "count"}); err != nil {
			t.Fatal(err)
		}
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	outcome := e1Execute(t, bus, e1Command(t, "events.occurrence.show", nil, "global", map[string]any{"occurrence_id": occurrence.ID, "limit": 1}))
	if outcome.State != operator.StateApplied {
		t.Fatalf("occurrence.show: %s %s", outcome.State, outcome.Result)
	}
	var shown struct {
		ClaimCount int `json:"claim_count"`
		Truncated  bool
		Claims     []appevents.ClaimView `json:"claims"`
	}
	if err := json.Unmarshal(outcome.Result, &shown); err != nil {
		t.Fatal(err)
	}
	if shown.ClaimCount != 3 || !shown.Truncated || len(shown.Claims) != 1 {
		t.Fatalf("claim_count must count every claim, not the page: %s", outcome.Result)
	}
}

func TestActiveModifiersRead(t *testing.T) {
	pool := e1Pool(t)
	bus := e1Bus(t, pool)
	definition := json.RawMessage(`{"activity_id":1990,"revision":1,"archetype":"RULE_MODIFIER","client_requirements":{},"hooks":[{"hook":"campaign.drop_multiplier","scope":"normal","item_kinds":[1],"multiplier":2}]}`)
	deployed := e1Execute(t, bus, e1Command(t, "events.definition.deploy", nil, "global", definition))
	if deployed.State != operator.StateApplied {
		t.Fatalf("deploy: %s %s", deployed.State, deployed.Result)
	}
	ctx := context.Background()
	now := time.Now().UTC()
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO event_occurrences(logical_server_id,activity_id,definition_revision,starts_at,ends_at,claim_until,source,revision,created_at)
		VALUES(1,1990,1,$1,$2,$3,'CYCLE',1,$4)`, now.Add(-time.Hour), now.Add(time.Hour), now.Add(2*time.Hour), now); err != nil {
		t.Fatal(err)
	}
	service := appevents.Service{Store: eventstore.Store{}}
	hooks, err := service.ActiveModifiers(ctx, pool, 1, now, "campaign.drop_multiplier")
	if err != nil {
		t.Fatal(err)
	}
	if len(hooks) != 1 || !json.Valid(hooks[0]) {
		t.Fatalf("hooks = %+v", hooks)
	}
	var hook struct {
		Kind       string `json:"hook"`
		Multiplier int64  `json:"multiplier"`
	}
	if err := json.Unmarshal(hooks[0], &hook); err != nil || hook.Kind != "campaign.drop_multiplier" || hook.Multiplier != 2 {
		t.Fatalf("hook = %s %v", hooks[0], err)
	}
}

func TestContentAdaptersExpandShippedRookieGift(t *testing.T) {
	pool := e1Pool(t)
	hooks, err := appevents.NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	commands := appevents.Commands{Store: eventstore.Store{}, Coverage: fakeCoverage{}, Gifts: eventstore.ContentGifts{}, Catalogue: eventstore.ContentCatalogue{}, Hooks: hooks}
	bus := operator.Bus{Runner: tx.Runner{DB: pool}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: commands.Handlers()}
	definition, err := os.ReadFile("../../../../internal/content/events/definitions/1071.json")
	if err != nil {
		t.Fatal(err)
	}
	outcome := e1Execute(t, bus, e1Command(t, "events.definition.deploy", nil, "global", json.RawMessage(definition)))
	if outcome.State != operator.StateApplied {
		t.Fatalf("shipped 1071 definition must deploy: %s %s", outcome.State, outcome.Result)
	}
	stored, err := (eventstore.Store{}).DefinitionTx(context.Background(), pool, 1071, 1)
	if err != nil || stored == nil {
		t.Fatalf("stored definition: %v", err)
	}
	if len(stored.Body.Tiers) != 5 || len(stored.Body.Tiers[1].Choices) != 3 {
		t.Fatalf("expanded tiers = %+v", stored.Body.Tiers)
	}
	lines := stored.Body.Tiers[1].Choices[0].Lines
	heroLines := 0
	for _, line := range lines {
		if line.Kind == domainevents.RewardKindHero {
			heroLines++
		}
	}
	if heroLines != 1 || len(lines) != 3 {
		t.Fatalf("gift 90001429 must expand to a hero, an item and mana, got %+v", lines)
	}
}

func TestScheduleRefusedWhenCoverageMissing(t *testing.T) {
	bus := e1BusFrom(t, e1Pool(t), missingCoverage{})
	e1Deploy(t, bus, 1084, 1, 2)
	payload := map[string]any{"activity_id": 1084, "logical_server_ids": []int64{1}, "duration": "3d"}
	outcome := e1Execute(t, bus, e1Command(t, "events.schedule", nil, "global", payload))
	if outcome.State != operator.StateRefused || e1Code(t, outcome) != appevents.CodeClientContentMissed {
		t.Fatalf("missing coverage must be EVENT_CLIENT_CONTENT_MISSING: %s %s", outcome.State, outcome.Result)
	}
	var refusal struct {
		Detail struct {
			ClientPaths []string `json:"missing_client_paths"`
		} `json:"detail"`
	}
	if err := json.Unmarshal(outcome.Result, &refusal); err != nil || len(refusal.Detail.ClientPaths) != 1 || refusal.Detail.ClientPaths[0] != "windows/activities/1084/main.csb" {
		t.Fatalf("detail lost the missing list: %s %v", outcome.Result, err)
	}
}

func TestOccurrenceListPagedAndFiltered(t *testing.T) {
	pool := e1Pool(t)
	bus := e1Bus(t, pool)
	e1Deploy(t, bus, 1088, 1, 2)
	e1Deploy(t, bus, 1089, 1, 2)
	first := e1ScheduleOn(t, bus, 3, 1088, time.Now().UTC().Add(24*time.Hour).Format(time.RFC3339), "3d")
	second := e1ScheduleOn(t, bus, 3, 1089, time.Now().UTC().Add(48*time.Hour).Format(time.RFC3339), "3d")
	service := appevents.Service{Runner: tx.Runner{DB: pool}, Operations: operation.Factory{Clock: clock.System{}}, Store: eventstore.Store{}, Clock: clock.System{}}
	ctx := context.Background()

	page, err := service.List(ctx, appevents.OccurrenceFilter{LogicalServerID: 3, Limit: 1})
	if err != nil {
		t.Fatal(err)
	}
	if len(page.Occurrences) != 1 || page.NextCursor == "" {
		t.Fatalf("first page = %+v", page)
	}
	if page.Occurrences[0].ID != second.ID {
		t.Fatalf("newest start must come first, got %d want %d", page.Occurrences[0].ID, second.ID)
	}
	cursor, err := appevents.ParseOccurrenceCursor(page.NextCursor)
	if err != nil {
		t.Fatal(err)
	}
	next, err := service.List(ctx, appevents.OccurrenceFilter{LogicalServerID: 3, Limit: 1, Cursor: cursor})
	if err != nil {
		t.Fatal(err)
	}
	if len(next.Occurrences) != 1 || next.Occurrences[0].ID != first.ID {
		t.Fatalf("second page = %+v", next)
	}
	running := domainevents.PhaseRunning
	empty, err := service.List(ctx, appevents.OccurrenceFilter{LogicalServerID: 3, Limit: 10, Phase: &running})
	if err != nil {
		t.Fatal(err)
	}
	if len(empty.Occurrences) != 0 {
		t.Fatalf("no RUNNING occurrence expected, got %+v", empty.Occurrences)
	}
	if _, err := service.List(ctx, appevents.OccurrenceFilter{LogicalServerID: 0}); err == nil {
		t.Fatal("a missing server must be refused")
	}
}

func TestSettingsClaimWindowTunable(t *testing.T) {
	pool := e1Pool(t)
	bus := e1Bus(t, pool)
	e1Deploy(t, bus, 1091, 1, 2)
	ctx := context.Background()
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO event_cycle_settings(logical_server_id,claim_window_hours,updated_at) VALUES(2,2,now()) ON CONFLICT (logical_server_id) DO UPDATE SET claim_window_hours=2`); err != nil {
		t.Fatal(err)
	}
	payload := map[string]any{"activity_id": 1091, "logical_server_ids": []int64{2}, "duration": "1d", "start": time.Now().UTC().Add(24 * time.Hour).Format(time.RFC3339)}
	outcome := e1Execute(t, bus, e1Command(t, "events.schedule", nil, "global", payload))
	if outcome.State != operator.StateApplied {
		t.Fatalf("schedule server 2: %s %s", outcome.State, outcome.Result)
	}
	var result struct {
		Occurrences []appevents.OccurrenceView `json:"occurrences"`
	}
	if err := json.Unmarshal(outcome.Result, &result); err != nil || len(result.Occurrences) != 1 {
		t.Fatalf("schedule result %s: %v", outcome.Result, err)
	}
	view := result.Occurrences[0]
	if view.EndsAt == nil || view.ClaimUntil == nil || view.ClaimUntil.Sub(*view.EndsAt) != 2*time.Hour {
		t.Fatalf("claim window must use the settings row, got %+v", view)
	}
}

func e1SyncFiles(t *testing.T, pool *pg.Pool, commands appevents.Commands, files []appevents.DefinitionFile) []appevents.SyncResult {
	t.Helper()
	at := time.Now().UTC()
	op, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	profile := tx.Profile{Name: "event-sync-native", AcquireTimeout: time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 20 * time.Second, TransactionTimeout: 60 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 120 * time.Second}
	var results []appevents.SyncResult
	_, err = (tx.Runner{DB: pool}).Run(context.Background(), op, profile, tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		loaded, syncErr := commands.SyncFiles(ctx, scope.Tx, at, files)
		if syncErr == nil {
			results = loaded
		}
		return syncErr
	})
	if err != nil {
		t.Fatal(err)
	}
	return results
}

func TestDefinitionSyncIsIdempotentAndKeepsStoredRevision(t *testing.T) {
	pool := e1Pool(t)
	hooks, err := appevents.NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	commands := appevents.Commands{Store: eventstore.Store{}, Coverage: fakeCoverage{}, Gifts: fakeGifts{}, Catalogue: fakeCatalogue{}, Hooks: hooks, Audit: operatorstore.Store{}, Content: &fakeContentRevision{revision: strings.Repeat("a", 64)}}
	activityID := int64(1195)
	original := []byte(`{"activity_id":1195,"revision":1,"archetype":"DISPLAY","client_requirements":{},"default_days":3}`)
	files := []appevents.DefinitionFile{{Name: "1195.json", Body: original}}

	first := e1SyncFiles(t, pool, commands, files)
	if len(first) != 1 || first[0].Outcome != appevents.SyncDeployed {
		t.Fatalf("first sync = %+v", first)
	}
	stored, err := (eventstore.Store{}).DefinitionTx(context.Background(), pool, activityID, 1)
	if err != nil || stored == nil {
		t.Fatalf("stored definition = %v %v", stored, err)
	}
	second := e1SyncFiles(t, pool, commands, files)
	if len(second) != 1 || second[0].Outcome != appevents.SyncUnchanged {
		t.Fatalf("second sync = %+v", second)
	}
	afterSecond, err := (eventstore.Store{}).DefinitionTx(context.Background(), pool, activityID, 1)
	if err != nil || afterSecond == nil || !afterSecond.DeployedAt.Equal(stored.DeployedAt) {
		t.Fatalf("the second sync must not rewrite the row: %v %v", afterSecond, err)
	}

	changed := []byte(`{"activity_id":1195,"revision":1,"archetype":"DISPLAY","client_requirements":{},"default_days":9}`)
	conflict := e1SyncFiles(t, pool, commands, []appevents.DefinitionFile{{Name: "1195.json", Body: changed}})
	if len(conflict) != 1 || conflict[0].Outcome != appevents.SyncConflict {
		t.Fatalf("conflict sync = %+v", conflict)
	}
	kept, err := (eventstore.Store{}).DefinitionTx(context.Background(), pool, activityID, 1)
	if err != nil || kept == nil || kept.Body.DefaultDays != 3 {
		t.Fatalf("the conflicting body must not overwrite the stored revision: %v %v", kept, err)
	}
	rows, err := (eventstore.Store{}).ListDefinitionsTx(context.Background(), pool, activityID, 10)
	if err != nil || len(rows) != 1 || rows[0].SyncConflictSHA256 == "" {
		t.Fatalf("list must carry the conflict sha: %+v %v", rows, err)
	}

	bus := e1BusFrom(t, pool, fakeCoverage{})
	e1Deploy(t, bus, activityID, 2, 1)
	if again := e1SyncFiles(t, pool, commands, files); len(again) != 1 || again[0].Outcome != appevents.SyncUnchanged {
		t.Fatalf("sync after an operator deploy = %+v", again)
	}
	latest, err := (eventstore.Store{}).LatestDefinitionTx(context.Background(), pool, activityID)
	if err != nil || latest == nil || latest.Revision != 2 {
		t.Fatalf("an operator-deployed revision absent from the files must stay: %v %v", latest, err)
	}
}

func TestDefinitionReloadDeploysShippedFilesThroughTheBus(t *testing.T) {
	pool := e1Pool(t)
	hooks, err := appevents.NewHookRegistry(domainevents.HookCampaignDropMultiplier)
	if err != nil {
		t.Fatal(err)
	}
	commands := appevents.Commands{Store: eventstore.Store{}, Coverage: fakeCoverage{}, Gifts: eventstore.ContentGifts{}, Catalogue: eventstore.ContentCatalogue{}, Hooks: hooks, Audit: operatorstore.Store{}, Content: &fakeContentRevision{revision: strings.Repeat("a", 64)}, Shipped: e1ShippedFiles(t)}
	bus := operator.Bus{Runner: tx.Runner{DB: pool}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: commands.Handlers()}
	outcome := e1Execute(t, bus, e1Command(t, "events.definition.reload", nil, "global", map[string]any{}))
	if outcome.State != operator.StateApplied {
		t.Fatalf("reload: %s %s", outcome.State, outcome.Result)
	}
	var first struct {
		Definitions []appevents.SyncResult `json:"definitions"`
	}
	if err := json.Unmarshal(outcome.Result, &first); err != nil || len(first.Definitions) == 0 {
		t.Fatalf("reload result %s: %v", outcome.Result, err)
	}
	deployed := map[int64]string{}
	for _, result := range first.Definitions {
		if result.Outcome != appevents.SyncDeployed && result.Outcome != appevents.SyncUnchanged {
			t.Fatalf("first reload %s: %+v", result.File, result)
		}
		deployed[result.ActivityID] = result.Outcome
	}
	if deployed[1008] != appevents.SyncDeployed || deployed[1071] == "" {
		t.Fatalf("shipped definitions were not deployed: %+v", deployed)
	}
	again := e1Execute(t, bus, e1Command(t, "events.definition.reload", nil, "global", map[string]any{}))
	if again.State != operator.StateApplied {
		t.Fatalf("second reload: %s %s", again.State, again.Result)
	}
	var second struct {
		Definitions []appevents.SyncResult `json:"definitions"`
	}
	if err := json.Unmarshal(again.Result, &second); err != nil {
		t.Fatalf("second reload result %s: %v", again.Result, err)
	}
	for _, result := range second.Definitions {
		if result.Outcome != appevents.SyncUnchanged {
			t.Fatalf("second reload %s: %+v", result.File, result)
		}
	}
}

func e1ShippedFiles(t *testing.T) []appevents.DefinitionFile {
	t.Helper()
	embedded, err := eventscontent.Definitions()
	if err != nil {
		t.Fatal(err)
	}
	files := make([]appevents.DefinitionFile, 0, len(embedded))
	for _, file := range embedded {
		files = append(files, appevents.DefinitionFile{Name: file.Name, Body: file.Body})
	}
	return files
}

func TestDefinitionListShowsLatestRevisionAndClearsSupersededConflict(t *testing.T) {
	pool := e1Pool(t)
	hooks, err := appevents.NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	commands := appevents.Commands{Store: eventstore.Store{}, Coverage: fakeCoverage{}, Gifts: fakeGifts{}, Catalogue: fakeCatalogue{}, Hooks: hooks, Audit: operatorstore.Store{}, Content: &fakeContentRevision{revision: strings.Repeat("a", 64)}}
	activityID := int64(1196)
	first := []byte(`{"activity_id":1196,"revision":1,"archetype":"DISPLAY","client_requirements":{},"default_days":3}`)
	conflicting := []byte(`{"activity_id":1196,"revision":1,"archetype":"DISPLAY","client_requirements":{},"default_days":9}`)
	upgraded := []byte(`{"activity_id":1196,"revision":2,"archetype":"DISPLAY","client_requirements":{},"default_days":5}`)

	if results := e1SyncFiles(t, pool, commands, []appevents.DefinitionFile{{Name: "1196.json", Body: first}}); len(results) != 1 || results[0].Outcome != appevents.SyncDeployed {
		t.Fatalf("first sync = %+v", results)
	}
	if results := e1SyncFiles(t, pool, commands, []appevents.DefinitionFile{{Name: "1196.json", Body: conflicting}}); len(results) != 1 || results[0].Outcome != appevents.SyncConflict {
		t.Fatalf("conflicting sync = %+v", results)
	}
	rows, err := (eventstore.Store{}).ListDefinitionsTx(context.Background(), pool, activityID, 10)
	if err != nil || len(rows) != 1 || rows[0].Revision != 1 || rows[0].SyncConflictSHA256 == "" {
		t.Fatalf("latest revision with its conflict = %+v %v", rows, err)
	}

	if results := e1SyncFiles(t, pool, commands, []appevents.DefinitionFile{{Name: "1196.json", Body: upgraded}}); len(results) != 1 || results[0].Outcome != appevents.SyncDeployed {
		t.Fatalf("upgraded sync = %+v", results)
	}
	rows, err = (eventstore.Store{}).ListDefinitionsTx(context.Background(), pool, activityID, 10)
	if err != nil || len(rows) != 1 || rows[0].Revision != 2 || rows[0].SyncConflictSHA256 != "" {
		t.Fatalf("list must show only the latest revision: %+v %v", rows, err)
	}
	var conflicts int
	if err := pool.Raw().QueryRow(context.Background(), `SELECT count(*) FROM event_definition_sync_conflicts WHERE activity_id=$1`, activityID).Scan(&conflicts); err != nil {
		t.Fatal(err)
	}
	if conflicts != 0 {
		t.Fatalf("a good sync must clear the older revision's conflict rows, got %d", conflicts)
	}
}

func TestDefinitionSyncRetriesAfterContentRevisionChange(t *testing.T) {
	pool := e1Pool(t)
	hooks, err := appevents.NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	content := &fakeContentRevision{revision: strings.Repeat("a", 64)}
	commands := appevents.Commands{Store: eventstore.Store{}, Coverage: fakeCoverage{}, Gifts: fakeGifts{}, Catalogue: fakeCatalogue{}, Hooks: hooks, Audit: operatorstore.Store{}, Content: content}
	body := []byte(`{"activity_id":1197,"revision":1,"archetype":"TIERED_CLAIM","client_requirements":{},"default_days":-1,"tiers":[{"id":1,"requirement":{"kind":"player_level","value":10},"choices":[{"gift_id":90001428}]}]}`)
	files := []appevents.DefinitionFile{{Name: "1197.json", Body: body}}

	if results := e1SyncFiles(t, pool, commands, files); len(results) != 1 || results[0].Outcome != appevents.SyncInvalid || results[0].Error == "" {
		t.Fatalf("a gift the content cannot expand must be invalid: %+v", results)
	}
	content.revision = strings.Repeat("b", 64)
	if results := e1SyncFiles(t, pool, commands, files); len(results) != 1 || results[0].Outcome != appevents.SyncInvalid {
		t.Fatalf("the retried sync must run again: %+v", results)
	}

	rows, err := pool.Raw().Query(context.Background(), `SELECT semantic_key FROM operator_commands WHERE semantic_key LIKE 'sync:1197:%' ORDER BY created_at, semantic_key`)
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	keys := make([]string, 0, 2)
	for rows.Next() {
		var key string
		if err := rows.Scan(&key); err != nil {
			t.Fatal(err)
		}
		keys = append(keys, key)
	}
	if err := rows.Err(); err != nil {
		t.Fatal(err)
	}
	sawFirst, sawSecond := false, false
	for _, key := range keys {
		sawFirst = sawFirst || strings.HasSuffix(key, strings.Repeat("a", 16))
		sawSecond = sawSecond || strings.HasSuffix(key, strings.Repeat("b", 16))
	}
	if len(keys) != 2 || !sawFirst || !sawSecond {
		t.Fatalf("each content revision must carry its own sync key, got %+v", keys)
	}
}
