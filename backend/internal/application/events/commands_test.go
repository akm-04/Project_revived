package events

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/domain/events"
	otadomain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestParseDuration(t *testing.T) {
	cases := map[string]time.Duration{
		"1d": 24 * time.Hour, "3d": 72 * time.Hour, "7d": 7 * 24 * time.Hour,
		"14d": 14 * 24 * time.Hour, "30d": 30 * 24 * time.Hour, "36h": 36 * time.Hour, "1h": time.Hour,
	}
	for text, want := range cases {
		got, err := ParseDuration(text)
		if err != nil || got.Permanent || got.Span != want {
			t.Fatalf("%s: got %+v err %v", text, got, err)
		}
	}
	permanent, err := ParseDuration("permanent")
	if err != nil || !permanent.Permanent {
		t.Fatalf("permanent: %+v %v", permanent, err)
	}
	for _, text := range []string{"", "0d", "2d", "0h", "8761h", "-1h", "1.5h", "3 days"} {
		if _, err := ParseDuration(text); !errors.Is(err, ErrInvalidDuration) {
			t.Fatalf("%q must be refused, got %v", text, err)
		}
	}
}

func TestNextDayBoundary(t *testing.T) {
	now := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)
	want := time.Date(2026, 11, 22, 21, 0, 0, 0, time.UTC)
	if got := NextDayBoundary(now); !got.Equal(want) {
		t.Fatalf("got %s want %s", got, want)
	}
	boundary := want
	if got := NextDayBoundary(boundary); !got.Equal(boundary.Add(24 * time.Hour)) {
		t.Fatalf("at the boundary got %s", got)
	}
}

func TestHookGate(t *testing.T) {
	definition := events.Definition{ActivityID: 1008, Revision: 1, Archetype: events.ArchetypeRuleModifier, Hooks: []events.Hook{{Kind: events.HookCampaignDropMultiplier, Scope: "normal", ItemKinds: []int64{1}, Multiplier: 2}}}
	empty, err := NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	refusal := hookGate(definition, empty)
	if refusal == nil || refusal.Code != CodeHookUnbuilt {
		t.Fatalf("empty registry must refuse EVENT_HOOK_UNBUILT, got %+v", refusal)
	}
	registered, err := NewHookRegistry(events.HookCampaignDropMultiplier)
	if err != nil {
		t.Fatal(err)
	}
	if refusal := hookGate(definition, registered); refusal != nil {
		t.Fatalf("registered hook must pass, got %+v", refusal)
	}
}

func TestCoverageGateListsMissingPaths(t *testing.T) {
	coverage := otadomain.CoversResult{
		Status:             otadomain.CoversMissing,
		MissingClientPaths: []string{"windows/activities/1071/main_grow_up.csb"},
		MissingLazyAssets:  []otadomain.LazyAsset{{Path: "images/activities/1071.png", MD5: "0123456789abcdef0123456789abcdef"}},
		MissingCodeVersion: "1.631.9",
	}
	refusal := coverageGate(coverage)
	if refusal == nil || refusal.Code != CodeClientContentMissed {
		t.Fatalf("got %+v", refusal)
	}
	encoded, err := json.Marshal(refusal.Detail)
	if err != nil {
		t.Fatal(err)
	}
	var detail struct {
		ClientPaths []string `json:"missing_client_paths"`
		Assets      []struct {
			Path string `json:"path"`
		} `json:"missing_lazy_assets"`
		CodeVersion string `json:"missing_code_version"`
	}
	if err := json.Unmarshal(encoded, &detail); err != nil {
		t.Fatal(err)
	}
	if len(detail.ClientPaths) != 1 || len(detail.Assets) != 1 || detail.Assets[0].Path != "images/activities/1071.png" || detail.CodeVersion != "1.631.9" {
		t.Fatalf("detail lost the missing lists: %s", encoded)
	}
	if coverageGate(otadomain.CoversResult{Status: otadomain.CoversCovered}) != nil {
		t.Fatal("COVERED must pass")
	}
}

func TestScopedServers(t *testing.T) {
	if _, err := scopedServers([]int64{1, 2}, "global"); err != nil {
		t.Fatalf("global: %v", err)
	}
	if _, err := scopedServers([]int64{2}, "server:1"); err == nil {
		t.Fatal("a server-scoped command must not schedule another server")
	}
	servers, err := scopedServers([]int64{1, 1, 1}, "server:1")
	if err != nil || len(servers) != 1 {
		t.Fatalf("dedupe: %v %v", servers, err)
	}
	if _, err := scopedServers(nil, "global"); err == nil {
		t.Fatal("an empty server list must be refused")
	}
	if _, err := scopedServers([]int64{1}, "team:1"); err == nil {
		t.Fatal("an invalid scope must be refused")
	}
}

func TestScheduleStart(t *testing.T) {
	now := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)
	got, err := scheduleStart("", now)
	if err != nil || !got.Equal(time.Date(2026, 11, 22, 21, 0, 0, 0, time.UTC)) {
		t.Fatalf("default start %s %v", got, err)
	}
	custom := "2026-12-01T05:00:00+08:00"
	got, err = scheduleStart(custom, now)
	if err != nil || !got.Equal(time.Date(2026, 11, 30, 21, 0, 0, 0, time.UTC)) {
		t.Fatalf("custom start %s %v", got, err)
	}
	if _, err := scheduleStart("tomorrow", now); err == nil {
		t.Fatal("a non-RFC3339 start must be refused")
	}
}

func TestRefusalCodes(t *testing.T) {
	if stale(7).Code != CodeStale {
		t.Fatal("stale revision must use EVENT_STALE")
	}
	if requireRevision(nil, 1) == nil || requireRevision(int64Ptr(1), 1) != nil || requireRevision(int64Ptr(2), 1) == nil {
		t.Fatal("revision check is wrong")
	}
	if overlapRefusal(1, 2).Code != CodeOverlap {
		t.Fatal("overlap must use EVENT_OVERLAP")
	}
	if refuse := operator.Refuse(CodeGiftUnsupported, "x", nil); refuse.Code != CodeGiftUnsupported {
		t.Fatal("gift refusal code")
	}
}

func int64Ptr(value int64) *int64 { return &value }

type stubTx struct{}

func (stubTx) QueryRow(context.Context, string, ...any) tx.Row { return nil }
func (stubTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return nil, nil
}
func (stubTx) Commit(context.Context) error   { return nil }
func (stubTx) Rollback(context.Context) error { return nil }

func handlerScope(at time.Time) tx.Scope {
	return tx.Scope{Tx: stubTx{}, Operation: operation.Context{StartedAt: at}}
}

func handlerCommand(t *testing.T, name string, payload string) operator.Command {
	t.Helper()
	command, err := operator.NewCommand(name, operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "unit test", SemanticKey: "unit-" + name}, json.RawMessage(payload))
	if err != nil {
		t.Fatal(err)
	}
	return command
}

func refusalOf(t *testing.T, err error) *operator.Refusal {
	t.Helper()
	var refusal *operator.Refusal
	if !errors.As(err, &refusal) {
		t.Fatalf("want a refusal, got %v", err)
	}
	return refusal
}

func TestScheduleHandlerRefusesNonPositiveActivity(t *testing.T) {
	commands := Commands{}
	command := handlerCommand(t, "events.schedule", `{"activity_id":0,"logical_server_ids":[1],"duration":"1d"}`)
	_, err := commands.scheduleHandler(context.Background(), handlerScope(time.Now().UTC()), command)
	if refusal := refusalOf(t, err); refusal.Code != CodePayloadInvalid {
		t.Fatalf("code = %s, want %s", refusal.Code, CodePayloadInvalid)
	}
}

func TestDefinitionListRefusesNegativeActivity(t *testing.T) {
	commands := Commands{}
	command := handlerCommand(t, "events.definition.list", `{"activity_id":-1}`)
	_, err := commands.definitionListHandler(context.Background(), handlerScope(time.Now().UTC()), command)
	if refusal := refusalOf(t, err); refusal.Code != CodePayloadInvalid {
		t.Fatalf("code = %s, want %s", refusal.Code, CodePayloadInvalid)
	}
}

func TestDecodeMutation(t *testing.T) {
	occurrenceID, groupID, err := decodeMutation([]byte(`{"occurrence_id":7}`))
	if err != nil || occurrenceID != 7 || groupID != 0 {
		t.Fatalf("occurrence: %d %d %v", occurrenceID, groupID, err)
	}
	occurrenceID, groupID, err = decodeMutation([]byte(`{"group_id":9}`))
	if err != nil || occurrenceID != 0 || groupID != 9 {
		t.Fatalf("group: %d %d %v", occurrenceID, groupID, err)
	}
	if _, _, err := decodeMutation([]byte(`{}`)); err == nil {
		t.Fatal("an empty target must be refused")
	}
	if _, _, err := decodeMutation([]byte(`{"occurrence_id":7,"group_id":9}`)); err == nil {
		t.Fatal("both targets must be refused")
	}
	if _, err := decodeOccurrence([]byte(`{"group_id":9}`)); err == nil {
		t.Fatal("cancel must not accept a group id")
	}
}

func TestScheduleHandlerRefusesUnknownScope(t *testing.T) {
	commands := Commands{}
	command := handlerCommand(t, "events.schedule", `{"activity_id":1008,"logical_server_ids":[1],"duration":"1d","scope":"team"}`)
	_, err := commands.scheduleHandler(context.Background(), handlerScope(time.Now().UTC()), command)
	if refusal := refusalOf(t, err); refusal.Code != CodePayloadInvalid {
		t.Fatalf("code = %s, want %s", refusal.Code, CodePayloadInvalid)
	}
}

func TestScheduleGlobalRefusesServerList(t *testing.T) {
	commands := Commands{}
	command := handlerCommand(t, "events.schedule", `{"activity_id":1008,"duration":"1d","scope":"global","logical_server_ids":[1]}`)
	_, err := commands.scheduleHandler(context.Background(), handlerScope(time.Now().UTC()), command)
	if refusal := refusalOf(t, err); refusal.Code != CodePayloadInvalid {
		t.Fatalf("code = %s, want %s", refusal.Code, CodePayloadInvalid)
	}
}

func TestGroupStateFor(t *testing.T) {
	at := time.Date(2026, 11, 23, 12, 0, 0, 0, time.UTC)
	if got := groupStateFor(at.Add(time.Hour), at); got != events.GroupScheduled {
		t.Fatalf("future start state = %s", got)
	}
	if got := groupStateFor(at.Add(-time.Hour), at); got != events.GroupRunning {
		t.Fatalf("started state = %s", got)
	}
}

var errSettingsFault = errors.New("settings read timed out")

type failingSettingsStore struct {
	Store
	occurrence *events.Occurrence
}

func (store failingSettingsStore) LockOccurrenceTx(context.Context, tx.Tx, int64) (*events.Occurrence, error) {
	return store.occurrence, nil
}

func (failingSettingsStore) EnsureSettingsTx(context.Context, tx.Tx, int64, time.Time) (Settings, error) {
	return Settings{}, errSettingsFault
}

func TestEndNowReturnsSettingsFaultRaw(t *testing.T) {
	at := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)
	endsAt := at.Add(time.Hour)
	claimUntil := at.Add(2 * time.Hour)
	occurrence := &events.Occurrence{ID: 9, LogicalServerID: 1, ActivityID: 1071, StartsAt: at.Add(-time.Hour), EndsAt: &endsAt, ClaimUntil: &claimUntil, Revision: 1}
	commands := Commands{Store: failingSettingsStore{occurrence: occurrence}}
	command := handlerCommand(t, "events.end_now", `{"occurrence_id":9}`)
	command.Envelope.ExpectedRevision = int64Ptr(1)
	_, err := commands.endNowHandler(context.Background(), handlerScope(at), command)
	if err == nil || !errors.Is(err, errSettingsFault) {
		t.Fatalf("want the raw settings fault, got %v", err)
	}
	var refusal *operator.Refusal
	if errors.As(err, &refusal) {
		t.Fatalf("a settings fault must not be a refusal: %+v", refusal)
	}
}
