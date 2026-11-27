//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterbirth"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/eventstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/activitydirectory"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	appevents "gxb.local/backend/v2/internal/application/events"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	domevents "gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/domain/identity"
	otadomain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/projection/hero"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type eventsCoverage struct{}

func (eventsCoverage) Covers(context.Context, otadomain.CoversRequest) (otadomain.CoversResult, error) {
	return otadomain.CoversResult{Status: otadomain.CoversCovered}, nil
}

type eventServices struct {
	claims      appevents.ClaimService
	choiceGrant appevents.ChoiceGrant
	activity    stockruntime.ActivityDispatcher
}

func eventFixture(t *testing.T, p *postgres.Pool, a identity.ActorContext) eventServices {
	t.Helper()
	content := contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	receipts := kernelstore.Store{}
	privileges := privilegeProvider(p)
	i5svc := appi5.Service{Runner: runner, Store: values, Content: content, Privileges: privileges,
		Functions: appi5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{},
		Backpack: values, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: p},
		RedeemSecret: []byte("i11a-events-claim-fixture-key-000000000")}
	heroDB := characterstore.Store{Queryer: p}
	heroSvc := apphero.Service{AcquisitionStore: heroDB, Acquisition: content,
		CollectionAdmission: apphero.CatalogCollectionAdmission{Content: content},
		FreshFacets:         characterbirth.FreshHeroFacets(), Content: content, Progression: content,
		ProgressionStore: heroDB, Economy: appi5.HeroProgressionDebiter{Store: values, Content: content}}
	choiceGrant := appevents.ChoiceGrant{HeroContent: content, Heroes: heroSvc, Fragments: content, Grants: i5svc, HeroWire: hero.StockHero}
	claims := appevents.ClaimService{
		Runner: runner, Store: eventstore.Store{}, Fence: values, Players: i4store.PlayerRootLocker{},
		Levels: i4store.PlayerDirectoryReader{}, Content: content, ChoiceGrant: choiceGrant,
	}
	authority := playtestAuthority{a}
	registrations := appevents.ActivityRegistrations(eventstore.Store{}, p)
	registry, err := activitydirectory.NewRegistry(registrations, nil)
	if err != nil {
		t.Fatal(err)
	}
	runtime := activitydirectory.Runtime{Directory: activitydirectory.Directory{Registry: registry}, Time: postgres.AuthoritativeTime{Queryer: p}}
	return eventServices{
		claims:      claims,
		choiceGrant: choiceGrant,
		activity:    stockruntime.ActivityDispatcher{Authority: authority, Service: runtime, Reads: runner, Levels: i4store.PlayerDirectoryReader{}},
	}
}

func deployRookieGift(t *testing.T, p *postgres.Pool) {
	t.Helper()
	raw, err := os.ReadFile("../../../internal/content/events/definitions/1071.json")
	if err != nil {
		t.Fatal(err)
	}
	hooks, err := appevents.NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	commands := appevents.Commands{Store: eventstore.Store{}, Coverage: eventsCoverage{}, Gifts: eventstore.ContentGifts{}, Catalogue: eventstore.ContentCatalogue{}, Hooks: hooks}
	bus := operator.Bus{Runner: tx.Runner{DB: p}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: commands.Handlers()}
	key, _ := ids.NewUUID()
	command, err := operator.NewCommand("events.definition.deploy", operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "i11a e3 claim native", SemanticKey: key.String()}, json.RawMessage(raw))
	if err != nil {
		t.Fatal(err)
	}
	outcome, err := bus.Execute(ctx, command)
	if err != nil || outcome.State != operator.StateApplied {
		t.Fatalf("deploy 1071: %v %s %s", err, outcome.State, outcome.Result)
	}
	definition, err := (eventstore.Store{}).DefinitionTx(ctx, p, 1071, 1)
	if err != nil || definition == nil {
		t.Fatalf("deployed definition: %v", err)
	}
	if len(definition.Body.Tiers) != 5 {
		t.Fatalf("tiers = %d, want the client's five", len(definition.Body.Tiers))
	}
	tier := definition.Body.Tiers[0]
	if len(tier.Choices) != 1 || len(tier.Choices[0].Lines) != 3 {
		t.Fatalf("gift 90001428 must expand to two items and mana, got %+v", tier.Choices)
	}
}

func schedulePermanent(t *testing.T, p *postgres.Pool, activityID int64, start time.Time) {
	t.Helper()
	hooks, err := appevents.NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	commands := appevents.Commands{Store: eventstore.Store{}, Coverage: eventsCoverage{}, Gifts: eventstore.ContentGifts{}, Catalogue: eventstore.ContentCatalogue{}, Hooks: hooks}
	bus := operator.Bus{Runner: tx.Runner{DB: p}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: commands.Handlers()}
	payload, _ := json.Marshal(map[string]any{"activity_id": activityID, "logical_server_ids": []int64{1}, "duration": "permanent", "start": start.UTC().Format(time.RFC3339)})
	key, _ := ids.NewUUID()
	command, err := operator.NewCommand("events.schedule", operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "i11a e3 claim native", SemanticKey: key.String()}, json.RawMessage(payload))
	if err != nil {
		t.Fatal(err)
	}
	outcome, err := bus.Execute(ctx, command)
	if err != nil || outcome.State != operator.StateApplied {
		t.Fatalf("schedule 1071: %v %s %s", err, outcome.State, outcome.Result)
	}
}

func (s eventServices) rewardFor(a identity.ActorContext) stockruntime.ActivityRewardDispatcher {
	return stockruntime.ActivityRewardDispatcher{Authority: playtestAuthority{a}, Service: s.claims}
}

func (s eventServices) activityFor(a identity.ActorContext) stockruntime.ActivityDispatcher {
	dispatcher := s.activity
	dispatcher.Authority = playtestAuthority{a}
	return dispatcher
}

func claimResponse(services eventServices, a identity.ActorContext, tier, choice int64) httpedge.Response {
	return services.rewardFor(a).Dispatch(ctx, claimRequest(a, tier, choice))
}

func claimRequest(a identity.ActorContext, tier, choice int64) httpedge.DispatchRequest {
	return claimRequestFor(a, 1071, tier, choice)
}

func claimRequestFor(a identity.ActorContext, activityID, tier, choice int64) httpedge.DispatchRequest {
	return playtestRequest(a, 231, map[string]any{"activity_id": activityID, "award_id": tier, "sub_award_id": choice})
}

func dispatchAwards(t *testing.T, services eventServices, a identity.ActorContext, tier, choice int64) (httpedge.Response, []byte) {
	t.Helper()
	response := claimResponse(services, a, tier, choice)
	if response.HTTPStatus != http.StatusOK {
		return response, nil
	}
	raw, err := json.Marshal(response.Body["awards"])
	if err != nil {
		t.Fatal(err)
	}
	return response, raw
}

func claimTier(t *testing.T, services eventServices, a identity.ActorContext, tier, choice int64) []byte {
	t.Helper()
	return claimActivityTier(t, services, a, 1071, tier, choice)
}

func claimActivityTier(t *testing.T, services eventServices, a identity.ActorContext, activityID, tier, choice int64) []byte {
	t.Helper()
	response := services.rewardFor(a).Dispatch(ctx, claimRequestFor(a, activityID, tier, choice))
	if response.HTTPStatus != http.StatusOK {
		t.Fatalf("claim activity %d tier %d/%d: %d %#v", activityID, tier, choice, response.HTTPStatus, response.Body)
	}
	raw, err := json.Marshal(response.Body["awards"])
	if err != nil {
		t.Fatal(err)
	}
	return raw
}

func requireClaimRefused(t *testing.T, response httpedge.Response) {
	t.Helper()
	if response.HTTPStatus != http.StatusConflict || response.Body["error_code"] != int64(35028) {
		t.Fatalf("want 409/35028, got %d %#v", response.HTTPStatus, response.Body)
	}
}

func TestRookieLevelGiftClaims(t *testing.T) {
	p := pool(t)
	installed(t, p)
	deployRookieGift(t, p)
	a := bornActor(t, p)
	exec(t, p, `UPDATE player_directory_profiles SET lev=50 WHERE player_id=$1`, int64(a.PlayerID))
	services := eventFixture(t, p, a)

	requireClaimRefused(t, claimResponse(services, a, 1, 1))

	schedulePermanent(t, p, 1071, time.Now().UTC().Add(-time.Hour))

	listResponse := services.activityFor(a).Dispatch(ctx, playtestRequest(a, 229, map[string]any{}))
	if listResponse.HTTPStatus != http.StatusOK {
		t.Fatalf("229: %d %#v", listResponse.HTTPStatus, listResponse.Body)
	}
	rows, ok := listResponse.Body["list"].([]any)
	if !ok || len(rows) != 1 {
		t.Fatalf("229 list = %#v", listResponse.Body)
	}
	projected := rows[0].(map[string]any)
	if projected["table_id"] != int64(1071) || projected["days"] != int64(-1) {
		t.Fatalf("1071 row = %#v", projected)
	}
	details := projected["details"].(map[string]any)
	if details["is_awards"] != "0|0|0|0|0" || details["end_time"] != int64(2147483647) {
		t.Fatalf("permanent projection = %#v", details)
	}
	before := activityRow(t, services, a)
	if before != "0|0|0|0|0" {
		t.Fatalf("before claim is_awards = %q", before)
	}
	awards := claimTier(t, services, a, 1, 1)
	var first []map[string]any
	if err := json.Unmarshal(awards, &first); err != nil {
		t.Fatal(err)
	}
	assertManaAward(t, first, 20000)
	assertItemAward(t, first, 50001003, 2)
	if after := activityRow(t, services, a); after != "1|0|0|0|0" {
		t.Fatalf("after claim is_awards = %q", after)
	}

	stackAfterFirst := stackQuantity(t, p, a.PlayerID, 50001003)
	replay := claimTier(t, services, a, 1, 1)
	if !bytes.Equal(awards, replay) {
		t.Fatalf("replay answered another body: %s vs %s", awards, replay)
	}
	if got := stackQuantity(t, p, a.PlayerID, 50001003); got != stackAfterFirst {
		t.Fatalf("replay granted again: %d -> %d", stackAfterFirst, got)
	}
	requireClaimRefused(t, claimResponse(services, a, 1, 2))

	for tier := int64(2); tier <= 5; tier++ {
		rows := claimTier(t, services, a, tier, 1)
		var decoded []map[string]any
		if err := json.Unmarshal(rows, &decoded); err != nil {
			t.Fatal(err)
		}
		if !hasPartnerAward(decoded) {
			t.Fatalf("tier %d must grant its hero: %s", tier, rows)
		}
	}
	if got := stackQuantity(t, p, a.PlayerID, 50001003); got != 17 {
		t.Fatalf("50001003 = %d, want 17", got)
	}
	if got := stackQuantity(t, p, a.PlayerID, 50001006); got != 15 {
		t.Fatalf("50001006 = %d, want 15", got)
	}
	if got := scalarAmount(t, p, a, "mana"); got != 870000 {
		t.Fatalf("mana = %d, want 870000", got)
	}
	if got := activityRow(t, services, a); got != "1|1|1|1|1" {
		t.Fatalf("all claimed is_awards = %q", got)
	}
	requireClaimRefused(t, claimResponse(services, a, 99, 1))
	requireClaimRefused(t, claimResponse(services, a, 1, 4))

	weak := bornActor(t, p)
	exec(t, p, `UPDATE player_directory_profiles SET lev=10 WHERE player_id=$1`, int64(weak.PlayerID))
	requireClaimRefused(t, claimResponse(services, weak, 2, 1))

	concurrent := bornActor(t, p)
	exec(t, p, `UPDATE player_directory_profiles SET lev=50 WHERE player_id=$1`, int64(concurrent.PlayerID))
	responses := make([]httpedge.Response, 2)
	var wait sync.WaitGroup
	for index := range responses {
		wait.Add(1)
		go func(slot int) {
			defer wait.Done()
			responses[slot] = claimResponse(services, concurrent, 1, 1)
		}(index)
	}
	wait.Wait()
	for index, response := range responses {
		if response.HTTPStatus != http.StatusOK {
			t.Fatalf("concurrent claim %d: %d %#v", index, response.HTTPStatus, response.Body)
		}
	}
	if got := stackQuantity(t, p, concurrent.PlayerID, 50001003); got != 2 {
		t.Fatalf("concurrent claims granted %d, want one tier's 2", got)
	}
}

func eventOperatorBus(t *testing.T, p *postgres.Pool) operator.Bus {
	t.Helper()
	hooks, err := appevents.NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	commands := appevents.Commands{Store: eventstore.Store{}, Coverage: eventsCoverage{}, Gifts: eventstore.ContentGifts{}, Catalogue: eventstore.ContentCatalogue{}, Hooks: hooks}
	return operator.Bus{Runner: tx.Runner{DB: p}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: commands.Handlers()}
}

func scheduleOccurrence(t *testing.T, p *postgres.Pool, server, activityID int64, start time.Time, duration string) appevents.OccurrenceView {
	t.Helper()
	payload, _ := json.Marshal(map[string]any{"activity_id": activityID, "logical_server_ids": []int64{server}, "duration": duration, "start": start.UTC().Format(time.RFC3339)})
	key, _ := ids.NewUUID()
	command, err := operator.NewCommand("events.schedule", operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "i11a e3 claim native", SemanticKey: key.String()}, json.RawMessage(payload))
	if err != nil {
		t.Fatal(err)
	}
	outcome, err := eventOperatorBus(t, p).Execute(ctx, command)
	if err != nil || outcome.State != operator.StateApplied {
		t.Fatalf("schedule %d: %v %s %s", activityID, err, outcome.State, outcome.Result)
	}
	var result struct {
		Occurrences []appevents.OccurrenceView `json:"occurrences"`
	}
	if err := json.Unmarshal(outcome.Result, &result); err != nil || len(result.Occurrences) != 1 {
		t.Fatalf("schedule result %s: %v", outcome.Result, err)
	}
	return result.Occurrences[0]
}

func endNowOccurrence(t *testing.T, p *postgres.Pool, occurrence appevents.OccurrenceView) {
	t.Helper()
	payload, _ := json.Marshal(map[string]any{"occurrence_id": occurrence.ID})
	revision := occurrence.Revision
	key, _ := ids.NewUUID()
	command, err := operator.NewCommand("events.end_now", operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "i11a e3 claim native", SemanticKey: key.String(), ExpectedRevision: &revision}, json.RawMessage(payload))
	if err != nil {
		t.Fatal(err)
	}
	outcome, err := eventOperatorBus(t, p).Execute(ctx, command)
	if err != nil || outcome.State != operator.StateApplied {
		t.Fatalf("end_now: %v %s %s", err, outcome.State, outcome.Result)
	}
}

func activityList(t *testing.T, services eventServices, a identity.ActorContext) []any {
	t.Helper()
	response := services.activityFor(a).Dispatch(ctx, playtestRequest(a, 229, map[string]any{}))
	if response.HTTPStatus != http.StatusOK {
		t.Fatalf("229: %d %#v", response.HTTPStatus, response.Body)
	}
	rows, ok := response.Body["list"].([]any)
	if !ok {
		t.Fatalf("229 list = %#v", response.Body)
	}
	return rows
}

// TestClaimWindowVisibilityAndReplay covers the CLAIM_WINDOW occurrence after
// end_now (EA-7): MID 229 projects it, a claim inside claim_until succeeds, a
// new claim after claim_until is refused, and the stored reply still replays.
func TestClaimWindowVisibilityAndReplay(t *testing.T) {
	p := pool(t)
	installed(t, p)
	deployRookieGift(t, p)
	a := bornActorOn(t, p, 2)
	exec(t, p, `UPDATE player_directory_profiles SET lev=50 WHERE player_id=$1`, int64(a.PlayerID))
	services := eventFixture(t, p, a)

	occurrence := scheduleOccurrence(t, p, int64(a.LogicalServerID), 1071, time.Now().UTC().Add(-time.Hour), "1d")
	endNowOccurrence(t, p, occurrence)
	if rows := activityList(t, services, a); len(rows) != 1 {
		t.Fatalf("229 must project the CLAIM_WINDOW row: %#v", rows)
	}
	awards := claimTier(t, services, a, 1, 1)
	var payloadVersion int16
	if err := p.QueryRow(ctx, `SELECT payload_version FROM player_event_claims WHERE player_id=$1 AND tier=1`, int64(a.PlayerID)).Scan(&payloadVersion); err != nil || payloadVersion != 1 {
		t.Fatalf("stored reply version = %d, %v; want payload.Encode's 1", payloadVersion, err)
	}

	exec(t, p, `UPDATE event_occurrences SET ends_at=clock_timestamp()-interval '30 minutes', claim_until=clock_timestamp()-interval '10 minutes', revision=revision+1 WHERE id=$1`, occurrence.ID)
	if rows := activityList(t, services, a); len(rows) != 0 {
		t.Fatalf("229 must drop the ended row: %#v", rows)
	}
	requireClaimRefused(t, claimResponse(services, a, 2, 1))
	replay := claimTier(t, services, a, 1, 1)
	if !bytes.Equal(awards, replay) {
		t.Fatalf("replay after claim_until answered another body: %s vs %s", awards, replay)
	}
}

// TestClaimWithoutStoredReplyRefuses covers a claimed tier whose row carries
// no stored reply (settlement/E4 writes such rows): a permanent state, 409.
func TestClaimWithoutStoredReplyRefuses(t *testing.T) {
	p := pool(t)
	installed(t, p)
	deployRookieGift(t, p)
	a := bornActorOn(t, p, 3)
	exec(t, p, `UPDATE player_directory_profiles SET lev=50 WHERE player_id=$1`, int64(a.PlayerID))
	services := eventFixture(t, p, a)
	scheduleOccurrence(t, p, int64(a.LogicalServerID), 1071, time.Now().UTC().Add(-time.Hour), "permanent")

	claimTier(t, services, a, 1, 1)
	exec(t, p, `UPDATE player_event_claims SET award_body=NULL, payload_version=0 WHERE player_id=$1 AND tier=1`, int64(a.PlayerID))
	requireClaimRefused(t, claimResponse(services, a, 1, 1))
}

// TestClaimChoiceResolution covers EA-7 sub_award_id: absent/zero means the
// single choice, a multi-choice tier needs an explicit valid choice, and only
// a non-numeric parameter is 400 (Activities.lua:132-150; Activity1071.lua:190
// calls getActivityReward2).
func TestClaimChoiceResolution(t *testing.T) {
	p := pool(t)
	installed(t, p)
	deployRookieGift(t, p)
	a := bornActorOn(t, p, 4)
	exec(t, p, `UPDATE player_directory_profiles SET lev=50 WHERE player_id=$1`, int64(a.PlayerID))
	services := eventFixture(t, p, a)
	scheduleOccurrence(t, p, int64(a.LogicalServerID), 1071, time.Now().UTC().Add(-time.Hour), "permanent")

	withoutChoice := func(tier int64) httpedge.Response {
		return services.rewardFor(a).Dispatch(ctx, playtestRequest(a, 231, map[string]any{"activity_id": int64(1071), "award_id": tier}))
	}
	if response := withoutChoice(1); response.HTTPStatus != http.StatusOK {
		t.Fatalf("the one-choice tier must accept an absent choice: %d %#v", response.HTTPStatus, response.Body)
	}
	requireClaimRefused(t, withoutChoice(2))
	requireClaimRefused(t, claimResponse(services, a, 2, 0))
	requireClaimRefused(t, claimResponse(services, a, 2, -1))
	malformedChoice := services.rewardFor(a).Dispatch(ctx, playtestRequest(a, 231, map[string]any{"activity_id": int64(1071), "award_id": int64(2), "sub_award_id": "abc"}))
	if malformedChoice.HTTPStatus != http.StatusBadRequest {
		t.Fatalf("a non-numeric choice must stay 400: %d %#v", malformedChoice.HTTPStatus, malformedChoice.Body)
	}
	claimTier(t, services, a, 2, 2)
}

func deploySingleTier(t *testing.T, p *postgres.Pool, activityID int64) {
	t.Helper()
	raw := []byte(fmt.Sprintf(`{"activity_id":%d,"revision":1,"archetype":"TIERED_CLAIM","client_requirements":{},"default_days":-1,"tiers":[`+
		`{"id":1,"requirement":{"kind":"player_level","value":10},"choices":[{"lines":[{"kind":"item","item_id":50001003,"amount":1}]}]}]}`, activityID))
	key, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand("events.definition.deploy", operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "i11a e4b settlement native", SemanticKey: key.String()}, json.RawMessage(raw))
	if err != nil {
		t.Fatal(err)
	}
	outcome, err := eventOperatorBus(t, p).Execute(ctx, command)
	if err != nil || outcome.State != operator.StateApplied {
		t.Fatalf("deploy %d: %v %s %s", activityID, err, outcome.State, outcome.Result)
	}
}

func settlementJobs(p *postgres.Pool, at time.Time, grant appevents.ChoiceGrant) appevents.Jobs {
	return appevents.Jobs{
		Runner:          tx.Runner{DB: p},
		Operations:      operation.Factory{Clock: clock.Fixed{T: at}},
		Store:           eventstore.Store{},
		Clock:           clock.Fixed{T: at},
		Players:         i4store.EventPlayerSource{},
		Mail:            appi5.SettlementMail{Store: i5store.Store{}},
		Content:         contentstore.Store{Queryer: p},
		ClaimGrant:      grant,
		OccurrenceBatch: 10,
	}
}

// TestSettlementDoesNotPayAClaimedTierTwice covers E4b decision 1: a MID 231
// claim inside the claim window and the settlement job share one claim period,
// so settlement finds the claim and grants nothing a second time.
func TestSettlementDoesNotPayAClaimedTierTwice(t *testing.T) {
	p := pool(t)
	installed(t, p)
	exec(t, p, `DELETE FROM player_event_claims WHERE occurrence_id IN (SELECT id FROM event_occurrences WHERE activity_id=$1)`, int64(2099))
	exec(t, p, `DELETE FROM event_occurrences WHERE activity_id=$1`, int64(2099))
	a := bornActorOn(t, p, 3)
	exec(t, p, `UPDATE player_directory_profiles SET lev=50 WHERE player_id=$1`, int64(a.PlayerID))
	services := eventFixture(t, p, a)
	deploySingleTier(t, p, 2099)
	occurrence := scheduleOccurrence(t, p, int64(a.LogicalServerID), 2099, time.Now().UTC().Add(-25*time.Hour), "1d")
	if occurrence.ClaimUntil == nil || !occurrence.ClaimUntil.After(time.Now().UTC()) {
		t.Fatalf("the occurrence must be in its claim window: %+v", occurrence)
	}
	claimActivityTier(t, services, a, 2099, 1, 1)
	due := occurrence.ClaimUntil.Add(time.Hour)
	stored, err := (eventstore.Store{}).OccurrenceTx(ctx, p, occurrence.ID)
	if err != nil || stored == nil {
		t.Fatalf("read the occurrence: %v", err)
	}
	current, err := (operation.Factory{Clock: clock.Fixed{T: due}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	if err := settlementJobs(p, due, services.choiceGrant).SettleOccurrence(ctx, current, *stored, due); err != nil {
		t.Fatal(err)
	}
	var claims int
	if err := p.QueryRow(ctx, `SELECT COUNT(*) FROM player_event_claims WHERE player_id=$1 AND occurrence_id=$2 AND tier=1`, int64(a.PlayerID), occurrence.ID).Scan(&claims); err != nil {
		t.Fatal(err)
	}
	if claims != 1 {
		t.Fatalf("one claim row expected, got %d", claims)
	}
	var mails int
	if err := p.QueryRow(ctx, `SELECT COUNT(*) FROM mail_records WHERE source_kind=$1 AND recipient_player_id=$2 AND source_key=$3`,
		appevents.SettlementMailSourceKind, int64(a.PlayerID), fmt.Sprintf("%d:%d:1", occurrence.ID, int64(a.PlayerID))).Scan(&mails); err != nil {
		t.Fatal(err)
	}
	if mails != 0 {
		t.Fatalf("a claimed tier must not be mailed again, got %d", mails)
	}
	var settled *time.Time
	if err := p.QueryRow(ctx, `SELECT settled_at FROM event_occurrences WHERE id=$1`, occurrence.ID).Scan(&settled); err != nil {
		t.Fatal(err)
	}
	if settled == nil {
		t.Fatal("the occurrence must be settled after the claim window closes")
	}
}

func activityRow(t *testing.T, services eventServices, a identity.ActorContext) string {
	t.Helper()
	response := services.activityFor(a).Dispatch(ctx, playtestRequest(a, 234, map[string]any{"activity_id": int64(1071)}))
	if response.HTTPStatus != http.StatusOK {
		t.Fatalf("234: %d %#v", response.HTTPStatus, response.Body)
	}
	details, ok := response.Body["details"].(map[string]any)
	if !ok {
		t.Fatalf("234 details = %#v", response.Body)
	}
	value, _ := details["is_awards"].(string)
	return value
}

func assertManaAward(t *testing.T, awards []map[string]any, amount int64) {
	t.Helper()
	for _, award := range awards {
		table, ok := numberValue(award["table_id"])
		if ok && table == -1 && award["mana"] != nil {
			return
		}
	}
	t.Fatalf("no mana award in %#v", awards)
}

func assertItemAward(t *testing.T, awards []map[string]any, itemID, amount int64) {
	t.Helper()
	for _, award := range awards {
		table, tableOK := numberValue(award["table_id"])
		count, countOK := numberValue(award["item_num"])
		if tableOK && countOK && table == float64(itemID) && count == float64(amount) {
			return
		}
	}
	t.Fatalf("no item %d x%d award in %#v", itemID, amount, awards)
}

func hasPartnerAward(awards []map[string]any) bool {
	for _, award := range awards {
		count, ok := numberValue(award["item_num"])
		if award["is_partner"] == true && ok && count == 1 {
			return true
		}
	}
	return false
}

// numberValue reads an award number whether it came from the typed reply or
// from the stored reply decoded through encoding/json.
func numberValue(value any) (float64, bool) {
	switch number := value.(type) {
	case int64:
		return float64(number), true
	case int:
		return float64(number), true
	case float64:
		return number, true
	case json.Number:
		parsed, err := number.Float64()
		return parsed, err == nil
	default:
		return 0, false
	}
}

func scalarAmount(t *testing.T, p *postgres.Pool, a identity.ActorContext, key string) int64 {
	t.Helper()
	var amount int64
	err := p.QueryRow(ctx, `SELECT COALESCE((SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key=$2),0)`, int64(a.PlayerID), key).Scan(&amount)
	if err != nil && !errors.Is(err, kernelstore.ErrNoRows) {
		t.Fatal(err)
	}
	return amount
}

const (
	settlementHeroItem = int64(10001034)
	settlementItem     = int64(50001003)
)

func deployTierDefinition(t *testing.T, p *postgres.Pool, activityID int64, tiers string) {
	t.Helper()
	raw := []byte(fmt.Sprintf(`{"activity_id":%d,"revision":1,"archetype":"TIERED_CLAIM","client_requirements":{},"default_days":-1,"tiers":[%s]}`, activityID, tiers))
	key, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand("events.definition.deploy", operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "i11a e4c settlement native", SemanticKey: key.String()}, json.RawMessage(raw))
	if err != nil {
		t.Fatal(err)
	}
	outcome, err := eventOperatorBus(t, p).Execute(ctx, command)
	if err != nil || outcome.State != operator.StateApplied {
		t.Fatalf("deploy %d: %v %s %s", activityID, err, outcome.State, outcome.Result)
	}
}

func resetEventActivity(t *testing.T, p *postgres.Pool, activityID int64) {
	t.Helper()
	exec(t, p, `DELETE FROM player_event_claims WHERE occurrence_id IN (SELECT id FROM event_occurrences WHERE activity_id=$1)`, activityID)
	exec(t, p, `DELETE FROM event_occurrences WHERE activity_id=$1`, activityID)
	exec(t, p, `DELETE FROM event_definitions WHERE activity_id=$1`, activityID)
}

func readEventOccurrence(t *testing.T, p *postgres.Pool, occurrenceID int64) *domevents.Occurrence {
	t.Helper()
	stored, err := (eventstore.Store{}).OccurrenceTx(ctx, p, occurrenceID)
	if err != nil || stored == nil {
		t.Fatalf("read occurrence %d: %v", occurrenceID, err)
	}
	return stored
}

func settleStoredOccurrence(t *testing.T, p *postgres.Pool, services eventServices, occurrence domevents.Occurrence, at time.Time) {
	t.Helper()
	current, err := (operation.Factory{Clock: clock.Fixed{T: at}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	if err := settlementJobs(p, at, services.choiceGrant).SettleOccurrence(ctx, current, occurrence, at); err != nil {
		t.Fatalf("settle occurrence %d: %v", occurrence.ID, err)
	}
}

func settlementSourceKeyFor(occurrenceID int64, player identity.PlayerID, tier int64) string {
	return fmt.Sprintf("%d:%d:%d", occurrenceID, int64(player), tier)
}

func countSettlementMail(t *testing.T, p *postgres.Pool, player identity.PlayerID, key string) int64 {
	t.Helper()
	return scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind=$2 AND source_key=$3`,
		int64(player), appevents.SettlementMailSourceKind, key)
}

// TestSettlementGrantsAnUnclaimedHeroTierDirectly covers E4c: system mail
// cannot carry a hero, so the tier settles through the MID 231 grant.
func TestSettlementGrantsAnUnclaimedHeroTierDirectly(t *testing.T) {
	p := pool(t)
	installed(t, p)
	server := nativeServer(t, p)
	const activityID = int64(2201)
	resetEventActivity(t, p, activityID)
	a := bornActorOn(t, p, server)
	exec(t, p, `UPDATE player_directory_profiles SET lev=50 WHERE player_id=$1`, int64(a.PlayerID))
	services := eventFixture(t, p, a)
	deployTierDefinition(t, p, activityID, fmt.Sprintf(`{"id":1,"requirement":{"kind":"player_level","value":10},"choices":[{"lines":[{"kind":"hero","item_id":%d,"amount":1}]}]}`, settlementHeroItem))
	occurrence := scheduleOccurrence(t, p, int64(server), activityID, time.Now().UTC().Add(-25*time.Hour), "1d")
	stored := readEventOccurrence(t, p, occurrence.ID)
	settleStoredOccurrence(t, p, services, *stored, stored.ClaimUntil.Add(time.Hour))

	if owned := scalar(t, p, `SELECT count(*) FROM player_heroes WHERE player_id=$1`, int64(a.PlayerID)); owned != 1 {
		t.Fatalf("hero rows = %d, want one", owned)
	}
	if claims := scalar(t, p, `SELECT count(*) FROM player_event_claims WHERE player_id=$1 AND occurrence_id=$2 AND tier=1`, int64(a.PlayerID), occurrence.ID); claims != 1 {
		t.Fatalf("claim rows = %d, want one", claims)
	}
	if mails := scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind=$2`, int64(a.PlayerID), appevents.SettlementMailSourceKind); mails != 0 {
		t.Fatalf("a hero tier must not be mailed, got %d", mails)
	}
	if settled := scalar(t, p, `SELECT count(*) FROM event_occurrences WHERE id=$1 AND settled_at IS NOT NULL`, occurrence.ID); settled != 1 {
		t.Fatal("the occurrence must settle after its hero tier is granted")
	}
}

// TestSettlementConvertsAnOwnedHeroToFragments covers the item-box duplicate
// rule shared with MID 231: a second hero grant becomes its stone.
func TestSettlementConvertsAnOwnedHeroToFragments(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	server := nativeServer(t, p)
	const firstActivity, secondActivity = int64(2202), int64(2203)
	resetEventActivity(t, p, firstActivity)
	resetEventActivity(t, p, secondActivity)
	a := bornActorOn(t, p, server)
	exec(t, p, `UPDATE player_directory_profiles SET lev=50 WHERE player_id=$1`, int64(a.PlayerID))
	services := eventFixture(t, p, a)
	tiers := fmt.Sprintf(`{"id":1,"requirement":{"kind":"player_level","value":10},"choices":[{"lines":[{"kind":"hero","item_id":%d,"amount":1}]}]}`, settlementHeroItem)
	deployTierDefinition(t, p, firstActivity, tiers)
	deployTierDefinition(t, p, secondActivity, tiers)

	first := scheduleOccurrence(t, p, int64(server), firstActivity, time.Now().UTC().Add(-25*time.Hour), "1d")
	firstStored := readEventOccurrence(t, p, first.ID)
	settleStoredOccurrence(t, p, services, *firstStored, firstStored.ClaimUntil.Add(time.Hour))
	second := scheduleOccurrence(t, p, int64(server), secondActivity, time.Now().UTC().Add(-25*time.Hour), "1d")
	secondStored := readEventOccurrence(t, p, second.ID)
	settleStoredOccurrence(t, p, services, *secondStored, secondStored.ClaimUntil.Add(time.Hour))

	if owned := scalar(t, p, `SELECT count(*) FROM player_heroes WHERE player_id=$1`, int64(a.PlayerID)); owned != 1 {
		t.Fatalf("hero rows = %d, want one", owned)
	}
	policy, err := (contentstore.Store{Queryer: p}).HeroNormalSummonTx(ctx, p, revision, settlementHeroItem)
	if err != nil {
		t.Fatal(err)
	}
	fragments, err := (contentstore.Store{Queryer: p}).HeroFragmentsTx(ctx, p, revision, policy.Template.OriginTableID)
	if err != nil {
		t.Fatal(err)
	}
	stone := fragments[0]
	if got := stackQuantity(t, p, a.PlayerID, stone); got != fragments[1] {
		t.Fatalf("stone %d = %d, want %d", stone, got, fragments)
	}
	if claims := scalar(t, p, `SELECT count(*) FROM player_event_claims WHERE player_id=$1 AND occurrence_id IN ($2,$3)`, int64(a.PlayerID), first.ID, second.ID); claims != 2 {
		t.Fatalf("claim rows = %d, want one per occurrence", claims)
	}
	if mails := scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind=$2`, int64(a.PlayerID), appevents.SettlementMailSourceKind); mails != 0 {
		t.Fatalf("hero tiers must not be mailed, got %d", mails)
	}
}

// TestSettlementMailsItemTiersAndGrantsHeroTiers covers E4c's mixed definition:
// the item-only tier keeps system mail, the hero tier grants directly.
func TestSettlementMailsItemTiersAndGrantsHeroTiers(t *testing.T) {
	p := pool(t)
	installed(t, p)
	server := nativeServer(t, p)
	const activityID = int64(2204)
	resetEventActivity(t, p, activityID)
	a := bornActorOn(t, p, server)
	exec(t, p, `UPDATE player_directory_profiles SET lev=50 WHERE player_id=$1`, int64(a.PlayerID))
	services := eventFixture(t, p, a)
	deployTierDefinition(t, p, activityID, fmt.Sprintf(`{"id":1,"requirement":{"kind":"player_level","value":10},"choices":[{"lines":[{"kind":"item","item_id":%d,"amount":3}]}]},{"id":2,"requirement":{"kind":"player_level","value":20},"choices":[{"lines":[{"kind":"hero","item_id":%d,"amount":1}]}]}`, settlementItem, settlementHeroItem))
	occurrence := scheduleOccurrence(t, p, int64(server), activityID, time.Now().UTC().Add(-25*time.Hour), "1d")
	stored := readEventOccurrence(t, p, occurrence.ID)
	settleStoredOccurrence(t, p, services, *stored, stored.ClaimUntil.Add(time.Hour))

	if claims := scalar(t, p, `SELECT count(*) FROM player_event_claims WHERE player_id=$1 AND occurrence_id=$2`, int64(a.PlayerID), occurrence.ID); claims != 2 {
		t.Fatalf("claim rows = %d, want one per tier", claims)
	}
	if mails := countSettlementMail(t, p, a.PlayerID, settlementSourceKeyFor(occurrence.ID, a.PlayerID, 1)); mails != 1 {
		t.Fatalf("item tier mail = %d, want one", mails)
	}
	if mails := countSettlementMail(t, p, a.PlayerID, settlementSourceKeyFor(occurrence.ID, a.PlayerID, 2)); mails != 0 {
		t.Fatalf("hero tier mail = %d, want none", mails)
	}
	if owned := scalar(t, p, `SELECT count(*) FROM player_heroes WHERE player_id=$1 AND table_id=$2`, int64(a.PlayerID), settlementHeroItem); owned != 1 {
		t.Fatalf("hero rows = %d, want one", owned)
	}
	if granted := stackQuantity(t, p, a.PlayerID, settlementItem); granted != 0 {
		t.Fatalf("the item tier must wait in mail, got %d granted", granted)
	}
}

// TestSettlementRerunGrantsNothingMore covers E4c's idempotency: rerunning the
// settlement of the same occurrence changes no ledger, mail or inventory row.
func TestSettlementRerunGrantsNothingMore(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	server := nativeServer(t, p)
	const activityID = int64(2205)
	resetEventActivity(t, p, activityID)
	a := bornActorOn(t, p, server)
	exec(t, p, `UPDATE player_directory_profiles SET lev=50 WHERE player_id=$1`, int64(a.PlayerID))
	services := eventFixture(t, p, a)
	deployTierDefinition(t, p, activityID, fmt.Sprintf(`{"id":1,"requirement":{"kind":"player_level","value":10},"choices":[{"lines":[{"kind":"item","item_id":%d,"amount":3}]}]},{"id":2,"requirement":{"kind":"player_level","value":20},"choices":[{"lines":[{"kind":"hero","item_id":%d,"amount":1}]}]}`, settlementItem, settlementHeroItem))
	occurrence := scheduleOccurrence(t, p, int64(server), activityID, time.Now().UTC().Add(-25*time.Hour), "1d")
	stored := readEventOccurrence(t, p, occurrence.ID)
	at := stored.ClaimUntil.Add(time.Hour)
	settleStoredOccurrence(t, p, services, *stored, at)

	policy, err := (contentstore.Store{Queryer: p}).HeroNormalSummonTx(ctx, p, revision, settlementHeroItem)
	if err != nil {
		t.Fatal(err)
	}
	fragments, err := (contentstore.Store{Queryer: p}).HeroFragmentsTx(ctx, p, revision, policy.Template.OriginTableID)
	if err != nil {
		t.Fatal(err)
	}
	stone := fragments[0]
	claimsBefore := scalar(t, p, `SELECT count(*) FROM player_event_claims WHERE player_id=$1 AND occurrence_id=$2`, int64(a.PlayerID), occurrence.ID)
	mailsBefore := scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind=$2`, int64(a.PlayerID), appevents.SettlementMailSourceKind)
	heroesBefore := scalar(t, p, `SELECT count(*) FROM player_heroes WHERE player_id=$1`, int64(a.PlayerID))
	stonesBefore := stackQuantity(t, p, a.PlayerID, stone)
	itemsBefore := stackQuantity(t, p, a.PlayerID, settlementItem)

	settleStoredOccurrence(t, p, services, *stored, at)

	if claims := scalar(t, p, `SELECT count(*) FROM player_event_claims WHERE player_id=$1 AND occurrence_id=$2`, int64(a.PlayerID), occurrence.ID); claims != claimsBefore {
		t.Fatalf("claims %d -> %d after a rerun", claimsBefore, claims)
	}
	if mails := scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind=$2`, int64(a.PlayerID), appevents.SettlementMailSourceKind); mails != mailsBefore {
		t.Fatalf("mails %d -> %d after a rerun", mailsBefore, mails)
	}
	if heroes := scalar(t, p, `SELECT count(*) FROM player_heroes WHERE player_id=$1`, int64(a.PlayerID)); heroes != heroesBefore {
		t.Fatalf("heroes %d -> %d after a rerun", heroesBefore, heroes)
	}
	if stones := stackQuantity(t, p, a.PlayerID, stone); stones != stonesBefore {
		t.Fatalf("stone %d -> %d after a rerun", stonesBefore, stones)
	}
	if items := stackQuantity(t, p, a.PlayerID, settlementItem); items != itemsBefore {
		t.Fatalf("item %d -> %d after a rerun", itemsBefore, items)
	}
}
