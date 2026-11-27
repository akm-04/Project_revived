package otarelease

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	domain "gxb.local/backend/v2/internal/domain/otarelease"
)

// S1 item 2: status, lookup and MID 2 read releases.json with no database
// transaction and no Runner.DB at all.
func TestReleaseReadsNeedNoDatabase(t *testing.T) {
	root := t.TempDir()
	at := time.Now().UTC().Truncate(time.Microsecond)
	store := NewStateFile(root)
	publishStateRelease(t, store, "1.631.2", domain.LaneCode, at)
	volumeDirectory := filepath.Join(root, "updates", string(domain.LaneCode))
	if err := os.MkdirAll(volumeDirectory, 0o755); err != nil {
		t.Fatal(err)
	}
	volume := stateRelease("1.631.2", domain.LaneCode).Volumes[0]
	if err := os.WriteFile(filepath.Join(volumeDirectory, volume.Name), make([]byte, volume.Size), 0o644); err != nil {
		t.Fatal(err)
	}

	service := Service{Store: store, PublicEngineURL: "https://engine.example"}
	plan, err := service.Plan(context.Background(), domain.PlanRequest{ClientVersion: "1.631.0", AppVersion: domain.StockAppVersion})
	if err != nil {
		t.Fatal(err)
	}
	if len(plan.Descriptors) != 1 || plan.Descriptors[0].Version != "1.631.2" {
		t.Fatalf("plan=%+v", plan.Descriptors)
	}
	if _, err := service.ActiveRows(context.Background()); err != nil {
		t.Fatal(err)
	}
	if active, err := service.ActiveRelease(context.Background()); err != nil || active.CodeVersion == nil || active.CodeVersion.String() != "1.631.2" {
		t.Fatalf("active=%+v err=%v", active, err)
	}
	if err := service.StartupCheck(context.Background(), root); err != nil {
		t.Fatalf("startup check without a database: %v", err)
	}
	lookup := ReleaseLookup{Store: store}
	existence, err := lookup.Exists(context.Background(), "1.631.2")
	if err != nil || !existence.Exists || existence.State != string(domain.StateActive) {
		t.Fatalf("lookup=%+v err=%v", existence, err)
	}
}

// S1 item 1: an unusable settings file is reported in ota.status, and the
// status read itself needs no database.
func TestStatusReadsTheFileWithoutADatabaseAndReportsInvalidSettings(t *testing.T) {
	store := NewStateFile(t.TempDir())
	at := time.Now().UTC().Truncate(time.Microsecond)
	publishStateRelease(t, store, "1.631.2", domain.LaneCode, at)
	live := NewSettingsValue(domain.DefaultSettings())
	live.MarkInvalid()
	service := StatusService{Store: store, Live: live}
	status, err := service.Status(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if !status.SettingsInvalid {
		t.Fatal("ota.status did not report the invalid settings file")
	}
	if status.Active.Code == nil || *status.Active.Code != "1.631.2" {
		t.Fatalf("active=%+v", status.Active)
	}
	if len(status.Served) != 0 || len(status.Misses) != 0 {
		t.Fatalf("ledger telemetry was not empty without a database: %+v", status)
	}
}
