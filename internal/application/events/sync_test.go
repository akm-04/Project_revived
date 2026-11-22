package events

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	domainevents "gxb.local/backend/v2/internal/domain/events"
	otadomain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type syncMemoryStore struct {
	Store
	definitions map[string]DefinitionRecord
	conflicts   map[string]string
}

func syncStoreKey(activityID, revision int64) string {
	body, _ := json.Marshal([]int64{activityID, revision})
	return string(body)
}

func newSyncMemoryStore() *syncMemoryStore {
	return &syncMemoryStore{definitions: map[string]DefinitionRecord{}, conflicts: map[string]string{}}
}

func (store *syncMemoryStore) DefinitionTx(_ context.Context, _ tx.Queryer, activityID, revision int64) (*DefinitionRecord, error) {
	record, found := store.definitions[syncStoreKey(activityID, revision)]
	if !found {
		return nil, nil
	}
	return &record, nil
}

func (store *syncMemoryStore) InsertDefinitionTx(_ context.Context, _ tx.Tx, record DefinitionRecord, _ string, _ time.Time) error {
	key := syncStoreKey(record.ActivityID, record.Revision)
	if _, exists := store.definitions[key]; exists {
		return ErrRevisionExists
	}
	store.definitions[key] = record
	return nil
}

func (store *syncMemoryStore) RecordDefinitionConflictTx(_ context.Context, _ tx.Tx, activityID, revision int64, sha256 string, _ time.Time) error {
	store.conflicts[syncStoreKey(activityID, revision)] = sha256
	return nil
}

func (store *syncMemoryStore) ClearDefinitionConflictTx(_ context.Context, _ tx.Tx, activityID, revision int64) error {
	delete(store.conflicts, syncStoreKey(activityID, revision))
	return nil
}

type syncMemoryAudit struct {
	rows map[string]*operator.Record
}

func newSyncMemoryAudit() *syncMemoryAudit {
	return &syncMemoryAudit{rows: map[string]*operator.Record{}}
}

func (audit *syncMemoryAudit) ClaimTx(_ context.Context, _ tx.Tx, command operator.Command, at time.Time) (*operator.Record, error) {
	if record, found := audit.rows[command.Envelope.SemanticKey]; found {
		return record, nil
	}
	audit.rows[command.Envelope.SemanticKey] = &operator.Record{SemanticKey: command.Envelope.SemanticKey, ModuleCommand: command.ModuleCommand, PayloadSHA256: command.PayloadSHA256, State: operator.StateAccepted, CreatedAt: at}
	return nil, nil
}

func (audit *syncMemoryAudit) RetryFailedTx(_ context.Context, _ tx.Tx, semanticKey string) error {
	record, found := audit.rows[semanticKey]
	if !found || record.State != operator.StateFailed {
		return errors.New("no FAILED row")
	}
	record.State = operator.StateAccepted
	return nil
}

func (audit *syncMemoryAudit) FinishTx(_ context.Context, _ tx.Tx, semanticKey, state string, result json.RawMessage, _ time.Time) error {
	record, found := audit.rows[semanticKey]
	if !found || record.State != operator.StateAccepted {
		return errors.New("command row is not ACCEPTED")
	}
	record.State, record.Result = state, result
	return nil
}

func (audit *syncMemoryAudit) ReadTx(_ context.Context, _ tx.Queryer, semanticKey string) (*operator.Record, error) {
	return audit.rows[semanticKey], nil
}

type syncGifts struct{}

func (syncGifts) GiftTx(context.Context, tx.Queryer, int64) ([]domainevents.RewardLine, bool, error) {
	return nil, false, nil
}

type syncCatalogue struct{}

func (syncCatalogue) CheckRewardsTx(context.Context, tx.Queryer, []domainevents.RewardLine) error {
	return nil
}

type syncCoverage struct{ covered bool }

func (coverage syncCoverage) Covers(context.Context, otadomain.CoversRequest) (otadomain.CoversResult, error) {
	if coverage.covered {
		return otadomain.CoversResult{Status: otadomain.CoversCovered}, nil
	}
	return otadomain.CoversResult{Status: otadomain.CoversMissing, MissingClientPaths: []string{"windows/activities/1099/main.csb"}}, nil
}

type syncContent struct{ revision string }

func (content syncContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return content.revision, nil
}

func syncCommands(store Store, audit operator.Store, hooks HookRegistry, coverage Coverage) Commands {
	return Commands{Store: store, Audit: audit, Hooks: hooks, Gifts: syncGifts{}, Catalogue: syncCatalogue{}, Coverage: coverage, Content: syncContent{revision: "content-1"}}
}

func syncDefinition(activityID, revision, defaultDays int64) []byte {
	body, _ := json.Marshal(map[string]any{"activity_id": activityID, "revision": revision, "archetype": "DISPLAY", "client_requirements": map[string]any{}, "default_days": defaultDays})
	return body
}

func TestSyncFilesDeploysThenIsIdempotent(t *testing.T) {
	hooks, err := NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	store := newSyncMemoryStore()
	commands := syncCommands(store, newSyncMemoryAudit(), hooks, syncCoverage{covered: true})
	at := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)
	files := []DefinitionFile{{Name: "1099.json", Body: syncDefinition(1099, 1, 3)}}

	first, err := commands.SyncFiles(context.Background(), stubTx{}, at, files)
	if err != nil || len(first) != 1 || first[0].Outcome != SyncDeployed {
		t.Fatalf("first sync = %+v %v", first, err)
	}
	second, err := commands.SyncFiles(context.Background(), stubTx{}, at.Add(time.Hour), files)
	if err != nil || len(second) != 1 || second[0].Outcome != SyncUnchanged {
		t.Fatalf("second sync = %+v %v", second, err)
	}
	if len(store.definitions) != 1 {
		t.Fatalf("definitions = %+v", store.definitions)
	}
}

func TestSyncFilesConflictKeepsStoredBody(t *testing.T) {
	hooks, err := NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	store := newSyncMemoryStore()
	commands := syncCommands(store, newSyncMemoryAudit(), hooks, syncCoverage{covered: true})
	at := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)
	original := syncDefinition(1099, 1, 3)
	if _, err := commands.SyncFiles(context.Background(), stubTx{}, at, []DefinitionFile{{Name: "1099.json", Body: original}}); err != nil {
		t.Fatal(err)
	}
	changed := syncDefinition(1099, 1, 9)
	results, err := commands.SyncFiles(context.Background(), stubTx{}, at.Add(time.Hour), []DefinitionFile{{Name: "1099.json", Body: changed}})
	if err != nil || len(results) != 1 || results[0].Outcome != SyncConflict {
		t.Fatalf("conflict sync = %+v %v", results, err)
	}
	stored := store.definitions[syncStoreKey(1099, 1)]
	if stored.Body.DefaultDays != 3 {
		t.Fatalf("stored body was overwritten: %+v", stored.Body)
	}
	if store.conflicts[syncStoreKey(1099, 1)] == "" {
		t.Fatal("the conflicting sha was not recorded")
	}
	if _, err := commands.SyncFiles(context.Background(), stubTx{}, at.Add(2*time.Hour), []DefinitionFile{{Name: "1099.json", Body: changed}}); err != nil {
		t.Fatal(err)
	}
	if store.conflicts[syncStoreKey(1099, 1)] == "" {
		t.Fatal("a repeated conflict must stay recorded")
	}
}

func TestSyncFilesRejectsInvalidFileAndKeepsOperatorRevision(t *testing.T) {
	hooks, err := NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	store := newSyncMemoryStore()
	operatorDeployed := DefinitionRecord{ActivityID: 1099, Revision: 2, Body: domainevents.Definition{ActivityID: 1099, Revision: 2, Archetype: domainevents.ArchetypeDisplay}, SHA256: "abc"}
	store.definitions[syncStoreKey(1099, 2)] = operatorDeployed
	commands := syncCommands(store, newSyncMemoryAudit(), hooks, syncCoverage{covered: true})
	at := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)

	results, err := commands.SyncFiles(context.Background(), stubTx{}, at, []DefinitionFile{
		{Name: "broken.json", Body: []byte(`{"activity_id":`)},
		{Name: "1099.json", Body: syncDefinition(1099, 1, 3)},
	})
	if err != nil || len(results) != 2 {
		t.Fatalf("results = %+v %v", results, err)
	}
	if results[0].Outcome != SyncInvalid || results[1].Outcome != SyncDeployed {
		t.Fatalf("outcomes = %+v", results)
	}
	if store.definitions[syncStoreKey(1099, 2)].Revision != 2 {
		t.Fatal("an operator-deployed revision absent from the files must stay")
	}
}

func TestSyncFilesReportsAnUnexpandableGiftAsInvalid(t *testing.T) {
	hooks, err := NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	store := newSyncMemoryStore()
	commands := syncCommands(store, newSyncMemoryAudit(), hooks, syncCoverage{covered: true})
	body := []byte(`{"activity_id":1098,"revision":1,"archetype":"TIERED_CLAIM","client_requirements":{},"default_days":-1,"tiers":[{"id":1,"requirement":{"kind":"player_level","value":10},"choices":[{"gift_id":90001428}]}]}`)
	results, err := commands.SyncFiles(context.Background(), stubTx{}, time.Now().UTC(), []DefinitionFile{{Name: "1098.json", Body: body}})
	if err != nil || len(results) != 1 || results[0].Outcome != SyncInvalid || results[0].Error == "" {
		t.Fatalf("results = %+v %v", results, err)
	}
	if len(store.definitions) != 0 {
		t.Fatal("an invalid definition must not be stored")
	}
}

func TestSyncCommandKeyShape(t *testing.T) {
	key := syncCommandKey(domainevents.Definition{ActivityID: 1071, Revision: 2}, "abc", "content-1")
	if key != "sync:1071:2:abc:content-1" {
		t.Fatalf("key = %s", key)
	}
	long := syncCommandKey(domainevents.Definition{ActivityID: 1071, Revision: 2}, "abc", "0123456789abcdef0123456789abcdef")
	if long != "sync:1071:2:abc:0123456789abcdef" {
		t.Fatalf("long content revision must shorten inside the 128-char key limit: %s", long)
	}
}

type readinessStore struct {
	Store
	record DefinitionRecord
}

func (store readinessStore) LatestDefinitionTx(context.Context, tx.Queryer, int64) (*DefinitionRecord, error) {
	record := store.record
	return &record, nil
}

func (store readinessStore) ListDefinitionsTx(context.Context, tx.Queryer, int64, int) ([]DefinitionRecord, error) {
	return []DefinitionRecord{store.record}, nil
}

func TestScheduleAndListAgreeOnAnUnbuiltHook(t *testing.T) {
	at := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)
	definition := domainevents.Definition{
		ActivityID: 1099, Revision: 1, Archetype: domainevents.ArchetypeRuleModifier, DefaultDays: 1,
		Hooks: []domainevents.Hook{{Kind: domainevents.HookCampaignDropMultiplier, Scope: "normal", ItemKinds: []int64{1}, Multiplier: 2}},
	}
	hooks, err := NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	commands := syncCommands(readinessStore{record: DefinitionRecord{ActivityID: 1099, Revision: 1, Body: definition}}, newSyncMemoryAudit(), hooks, syncCoverage{covered: true})

	scheduled, err := commands.scheduleHandler(context.Background(), handlerScope(at), handlerCommand(t, "events.schedule", `{"activity_id":1099,"logical_server_ids":[1],"duration":"1d"}`))
	if refusal := refusalOf(t, err); refusal.Code != CodeHookUnbuilt {
		t.Fatalf("schedule refusal = %s", refusal.Code)
	}
	if result, ok := scheduled.(scheduleResult); ok && len(result.Occurrences) != 0 {
		t.Fatalf("schedule result = %+v", result)
	}
	listed, err := commands.definitionListHandler(context.Background(), handlerScope(at), handlerCommand(t, "events.definition.list", `{}`))
	if err != nil {
		t.Fatal(err)
	}
	result, ok := listed.(definitionListResult)
	if !ok || len(result.Definitions) != 1 || result.Definitions[0].Readiness != ReadinessHookUnbuilt {
		t.Fatalf("list result = %+v", listed)
	}
}

type lazyMissingCoverage struct{}

func (lazyMissingCoverage) Covers(context.Context, otadomain.CoversRequest) (otadomain.CoversResult, error) {
	return otadomain.CoversResult{
		Status:             otadomain.CoversMissing,
		MissingClientPaths: []string{"res/web/windows/activities/1008/1008.csb"},
		MissingLazyAssets:  []otadomain.LazyAsset{{Path: "res/web/images/activities/1008.png"}},
		MissingCodeVersion: "1.631.9",
	}, nil
}

func TestDefinitionListReportsLazyAssetPathsAndCodeVersion(t *testing.T) {
	at := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)
	definition := domainevents.Definition{ActivityID: 1008, Revision: 1, Archetype: domainevents.ArchetypeRuleModifier, DefaultDays: 1}
	hooks, err := NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	commands := syncCommands(readinessStore{record: DefinitionRecord{ActivityID: 1008, Revision: 1, Body: definition}}, newSyncMemoryAudit(), hooks, lazyMissingCoverage{})

	listed, err := commands.definitionListHandler(context.Background(), handlerScope(at), handlerCommand(t, "events.definition.list", `{}`))
	if err != nil {
		t.Fatal(err)
	}
	result, ok := listed.(definitionListResult)
	if !ok || len(result.Definitions) != 1 {
		t.Fatalf("list result = %+v", listed)
	}
	summary := result.Definitions[0]
	if summary.Readiness != ReadinessClientContentMissing || summary.MissingCodeVersion != "1.631.9" {
		t.Fatalf("summary = %+v", summary)
	}
	paths := map[string]bool{}
	for _, path := range summary.MissingPaths {
		paths[path] = true
	}
	if !paths["res/web/windows/activities/1008/1008.csb"] || !paths["res/web/images/activities/1008.png"] {
		t.Fatalf("missing_paths must carry client and lazy paths: %+v", summary.MissingPaths)
	}
}

func TestSyncFilesRefusesAReusedCommandKey(t *testing.T) {
	hooks, err := NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	store := newSyncMemoryStore()
	audit := newSyncMemoryAudit()
	commands := syncCommands(store, audit, hooks, syncCoverage{covered: true})
	at := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)
	body := syncDefinition(1099, 1, 3)
	definition, err := domainevents.ParseDefinition(body)
	if err != nil {
		t.Fatal(err)
	}
	key := syncCommandKey(definition, fileDigest(body), "content-1")
	audit.rows[key] = &operator.Record{SemanticKey: key, ModuleCommand: "events.definition.deploy", PayloadSHA256: "another-payload", State: operator.StateApplied, Result: json.RawMessage(`{}`)}

	results, err := commands.SyncFiles(context.Background(), stubTx{}, at, []DefinitionFile{{Name: "1099.json", Body: body}})
	if err != nil || len(results) != 1 {
		t.Fatalf("results = %+v %v", results, err)
	}
	if results[0].Outcome != SyncInvalid || !strings.Contains(results[0].Error, operator.CodeKeyReused) {
		t.Fatalf("a reused key must report %s, got %+v", operator.CodeKeyReused, results[0])
	}
	if len(store.definitions) != 0 {
		t.Fatalf("a reused key must not deploy: %+v", store.definitions)
	}
}

func TestSyncFilesKeysByContentRevision(t *testing.T) {
	hooks, err := NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	store := newSyncMemoryStore()
	audit := newSyncMemoryAudit()
	commands := syncCommands(store, audit, hooks, syncCoverage{covered: true})
	at := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)
	files := []DefinitionFile{{Name: "1099.json", Body: syncDefinition(1099, 1, 3)}}

	if first, err := commands.SyncFiles(context.Background(), stubTx{}, at, files); err != nil || first[0].Outcome != SyncDeployed {
		t.Fatalf("first sync = %+v %v", first, err)
	}
	retried := commands
	retried.Content = syncContent{revision: "content-2"}
	if second, err := retried.SyncFiles(context.Background(), stubTx{}, at.Add(time.Hour), files); err != nil || second[0].Outcome != SyncUnchanged {
		t.Fatalf("second sync = %+v %v", second, err)
	}
	if len(audit.rows) != 2 {
		t.Fatalf("a content revision change must build a new command key, rows = %d", len(audit.rows))
	}
}

func TestReloadWithNoShippedFilesRefuses(t *testing.T) {
	hooks, err := NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	commands := syncCommands(newSyncMemoryStore(), newSyncMemoryAudit(), hooks, syncCoverage{covered: true})
	_, err = commands.reloadHandler(context.Background(), handlerScope(time.Now().UTC()), handlerCommand(t, "events.definition.reload", `{}`))
	if refusal := refusalOf(t, err); refusal.Code != CodeDefinitionsNotComposed {
		t.Fatalf("code = %s, want %s", refusal.Code, CodeDefinitionsNotComposed)
	}
}
