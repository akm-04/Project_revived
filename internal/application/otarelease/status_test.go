package otarelease

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fakeStatusStore struct {
	snapshot StatusSnapshot
}

func (store fakeStatusStore) ReadStatusTx(context.Context, tx.Queryer) (StatusSnapshot, error) {
	return store.snapshot, nil
}

type failingLedgerReader struct {
	err error
}

func (reader failingLedgerReader) ReadLedgerTx(context.Context, tx.Queryer, int, int) (LedgerStatus, error) {
	return LedgerStatus{}, reader.err
}

// S1 item 4 / L1c item 3: a ledger read failure keeps the file status and says
// the telemetry is unavailable instead of showing empty lists as measured.
func TestStatusKeepsTheFileStatusWhenTheLedgerFails(t *testing.T) {
	service := StatusService{
		Runner:     tx.Runner{DB: fakeDB{}},
		Operations: operation.Factory{Clock: clock.System{}},
		Store:      fakeStatusStore{snapshot: StatusSnapshot{Active: []ActiveRow{{Version: "1.631.2", Lane: "code"}}}},
		Ledger:     failingLedgerReader{err: errors.New("database restored")},
		Live:       NewSettingsValue(domain.DefaultSettings()),
	}
	status, err := service.Status(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if !status.TelemetryUnavailable {
		t.Fatal("ota.status hid the failed ledger read")
	}
	if status.Active.Code == nil || *status.Active.Code != "1.631.2" {
		t.Fatalf("the file status was dropped: %+v", status.Active)
	}
	if len(status.Served) != 0 || len(status.Misses) != 0 {
		t.Fatalf("the failed ledger produced lists: %+v", status)
	}
}

func TestStatusReportsTheEffectiveSettings(t *testing.T) {
	effective := domain.DefaultSettings()
	effective.DownloadBaseSeconds = 12
	effective.VolumeMB = 7
	service := StatusService{
		Runner:     tx.Runner{DB: fakeDB{}},
		Operations: operation.Factory{Clock: clock.System{}},
		Store:      fakeStatusStore{},
		Live:       NewSettingsValue(effective),
	}
	status, err := service.Status(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if status.Settings != effective {
		t.Fatalf("settings=%+v want=%+v", status.Settings, effective)
	}
	if status.Settings.DownloadBaseSeconds != 12 || status.Settings.VolumeMB != 7 {
		t.Fatalf("settings=%+v", status.Settings)
	}
}

func statusVersion(index int) string { return fmt.Sprintf("1.640.%d", index+1) }

func overBoundSnapshot() StatusSnapshot {
	active := make([]ActiveRow, 0, StatusActiveLimit+1)
	for index := 0; index <= StatusActiveLimit; index++ {
		active = append(active, ActiveRow{Version: statusVersion(index), Lane: "catalog"})
	}
	built := make([]BuiltRelease, 0, StatusBuiltLimit+1)
	for index := 0; index <= StatusBuiltLimit; index++ {
		built = append(built, BuiltRelease{Version: statusVersion(index), Lane: "code"})
	}
	activations := make([]ActivationStatus, 0, StatusActivationLimit+1)
	for index := 0; index <= StatusActivationLimit; index++ {
		activations = append(activations, ActivationStatus{ID: int64(index + 1), Version: statusVersion(index)})
	}
	served := make([]ServedCounter, 0, StatusServedLimit+1)
	for index := 0; index <= StatusServedLimit; index++ {
		served = append(served, ServedCounter{Path: fmt.Sprintf("src_64/app/%d.lua", index)})
	}
	misses := make([]AssetMiss, 0, StatusMissesLimit+1)
	for index := 0; index <= StatusMissesLimit; index++ {
		misses = append(misses, AssetMiss{Path: fmt.Sprintf("src_64/missing/%d.lua", index)})
	}
	return StatusSnapshot{Active: active, Built: built, Activations: activations, Served: served, Misses: misses}
}

func TestFoldStatusTruncatesEveryListToItsBound(t *testing.T) {
	status, err := foldStatus(overBoundSnapshot())
	if err != nil {
		t.Fatal(err)
	}
	if !status.Truncated.Active || !status.Truncated.Built || !status.Truncated.Activations || !status.Truncated.Served || !status.Truncated.Misses {
		t.Fatalf("truncated=%+v", status.Truncated)
	}
	if len(status.Active.Catalog) != StatusActiveLimit || len(status.Built) != StatusBuiltLimit || len(status.Activations) != StatusActivationLimit || len(status.Served) != StatusServedLimit || len(status.Misses) != StatusMissesLimit {
		t.Fatalf("lengths active=%d built=%d activations=%d served=%d misses=%d", len(status.Active.Catalog), len(status.Built), len(status.Activations), len(status.Served), len(status.Misses))
	}
}

func TestFoldStatusSummarisesEachLane(t *testing.T) {
	published := time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC)
	builtAt := time.Date(2026, 11, 22, 9, 0, 0, 0, time.UTC)
	status, err := foldStatus(StatusSnapshot{
		Active: []ActiveRow{{Version: "1.631.1", Lane: "assets", TotalSize: 100, PublishedAt: &published}},
		Built:  []BuiltRelease{{Version: "1.631.3", Lane: "code", TotalSize: 200, BuiltAt: builtAt}},
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(status.Lanes) != 3 {
		t.Fatalf("lanes = %+v", status.Lanes)
	}
	byLane := map[string]LaneSummary{}
	for _, lane := range status.Lanes {
		byLane[lane.Lane] = lane
	}
	assets := byLane["assets"]
	if assets.ActiveVersion == nil || *assets.ActiveVersion != "1.631.1" || assets.PublishedAt == nil || !assets.PublishedAt.Equal(published) {
		t.Fatalf("assets lane = %+v", assets)
	}
	code := byLane["code"]
	if code.BuiltVersion == nil || *code.BuiltVersion != "1.631.3" || code.Size != 200 || code.BuiltAt == nil || !code.BuiltAt.Equal(builtAt) {
		t.Fatalf("code lane = %+v", code)
	}
	catalog := byLane["catalog"]
	if catalog.ActiveVersion != nil || catalog.BuiltVersion != nil {
		t.Fatalf("catalog lane = %+v", catalog)
	}
}

func TestFoldStatusReportsNoTruncationAtTheBound(t *testing.T) {
	snapshot := overBoundSnapshot()
	snapshot.Active = snapshot.Active[:StatusActiveLimit]
	snapshot.Built = snapshot.Built[:StatusBuiltLimit]
	snapshot.Activations = snapshot.Activations[:StatusActivationLimit]
	snapshot.Served = snapshot.Served[:StatusServedLimit]
	snapshot.Misses = snapshot.Misses[:StatusMissesLimit]
	status, err := foldStatus(snapshot)
	if err != nil {
		t.Fatal(err)
	}
	if status.Truncated != (TruncatedLists{}) {
		t.Fatalf("truncated=%+v", status.Truncated)
	}
}

// TestNextVersionCountsEveryLaneAndStateNumerically proves G44: the proposed
// number is the highest of any lane and state plus one, compared as numbers.
func TestNextVersionCountsEveryLaneAndStateNumerically(t *testing.T) {
	cases := []struct {
		name     string
		versions []string
		want     string
	}{
		{name: "no release", versions: nil, want: ""},
		{name: "mixed lanes", versions: []string{"1.631.8", "1.631.7", "1.631.6"}, want: "1.631.9"},
		{name: "ten above nine", versions: []string{"1.631.9", "1.631.10", "1.631.2"}, want: "1.631.11"},
		{name: "highest is a replaced or old state", versions: []string{"1.631.3", "1.631.12", "1.631.4"}, want: "1.631.13"},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			status, err := foldStatus(StatusSnapshot{Versions: testCase.versions})
			if err != nil {
				t.Fatal(err)
			}
			if status.NextVersion != testCase.want {
				t.Fatalf("next_version=%q want %q", status.NextVersion, testCase.want)
			}
		})
	}
}
