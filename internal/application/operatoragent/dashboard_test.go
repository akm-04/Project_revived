package operatoragent

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
)

type fakeDashboardBackend struct {
	status BackendStatus
}

func (backend fakeDashboardBackend) Start(bool, string) error { return nil }
func (backend fakeDashboardBackend) Stop() error              { return nil }
func (backend fakeDashboardBackend) Status() BackendStatus    { return backend.status }

type fakeVersionSource struct {
	info operator.VersionInfo
	err  error
}

func (source fakeVersionSource) Version(context.Context) (operator.VersionInfo, error) {
	return source.info, source.err
}

type fakeDashboardOperator struct {
	replies map[string]string
	errs    map[string]error
}

func (client fakeDashboardOperator) Command(context.Context, OperatorRequest) (BackendResponse, error) {
	return BackendResponse{}, errors.New("no command expected")
}

func (client fakeDashboardOperator) Version(context.Context) (operator.VersionInfo, error) {
	return operator.VersionInfo{}, errors.New("no version expected")
}

func (client fakeDashboardOperator) Read(_ context.Context, name, _ string) (BackendResponse, error) {
	if err := client.errs[name]; err != nil {
		return BackendResponse{}, err
	}
	body, found := client.replies[name]
	if !found {
		return BackendResponse{Status: 409, Body: []byte(`{"error_code":"NO_SUCH_READ"}`)}, nil
	}
	return BackendResponse{Status: 200, Body: []byte(body)}, nil
}

type fakeSettingsSource struct {
	values AgentSettingsValues
	err    error
}

func (fake fakeSettingsSource) Values() (AgentSettingsValues, error) { return fake.values, fake.err }

func fixedClock() time.Time { return time.Unix(10_000, 0).UTC() }

func TestDashboardSummaryFoldsEverySection(t *testing.T) {
	backend := fakeDashboardBackend{status: BackendStatus{Running: true, PID: 42, State: "running"}}
	version := operator.VersionInfo{BackendVersion: stringPtr("v0.167.0"), GitCommit: stringPtr("abc")}
	client := fakeDashboardOperator{replies: map[string]string{
		"server.list": `{"servers":[{"server_id":1,"name":"Alpha","open":true,"online_count":7}]}`,
		"events.list": `{"occurrences":[{"id":9,"logical_server_id":1,"activity_id":1008,"state":"RUNNING","starts_at":"2026-11-22T00:00:00Z"},{"id":10,"logical_server_id":1,"activity_id":1009,"state":"SCHEDULED","starts_at":"2026-11-23T00:00:00Z"}]}`,
		"ota.status":  `{"active":{"code":"1.631.2","assets":"1.631.1","catalog":[]},"served":[{"hits":3},{"hits":4}],"misses":[{"hits":2}]}`,
	}}
	backups := t.TempDir()
	at := fixedClock()
	writeSnapshot(t, backups, "20260101T000000.000000000Z-manual", BackupKindManual, at.Add(-90*time.Second), "x")
	summary := Dashboard{
		Backend:    backend,
		Operator:   client,
		Version:    fakeVersionSource{info: version},
		PublicURLs: PublicURLs{PublicRoleSDK: "https://sdk.example"},
		Settings: fakeSettingsSource{values: AgentSettingsValues{
			ServerURL:  "https://game.example",
			PublicURLs: PublicURLs{PublicRoleSDK: "https://sdk.example", PublicRoleAPI: "https://game.example"},
			ResPath:    "/srv/res",
			BackupPath: "/srv/backups",
		}},
		Backups: BackupService{Directory: backups},
		Now:     func() time.Time { return at },
	}.Summary(context.Background())
	if !summary.Backend.Running || summary.Backend.PID != 42 {
		t.Fatalf("backend = %+v", summary.Backend)
	}
	if !summary.API.Reachable || summary.API.PingMilliseconds == nil || *summary.API.PingMilliseconds != 0 {
		t.Fatalf("api = %+v", summary.API)
	}
	if summary.Version == nil || *summary.Version.GitCommit != "abc" {
		t.Fatalf("version = %+v", summary.Version)
	}
	if len(summary.Servers) != 1 || summary.Servers[0].OnlineCount != 7 {
		t.Fatalf("servers = %+v", summary.Servers)
	}
	if len(summary.Events) != 1 || summary.Events[0].ID != 9 {
		t.Fatalf("events = %+v", summary.Events)
	}
	if summary.OTA.Code == nil || *summary.OTA.Code != "1.631.2" || summary.OTA.Assets == nil || *summary.OTA.Assets != "1.631.1" {
		t.Fatalf("ota = %+v", summary.OTA)
	}
	if summary.Assets.ServedPaths != 2 || summary.Assets.ServedHits != 7 || summary.Assets.MissingPaths != 1 || summary.Assets.MissingHits != 2 {
		t.Fatalf("assets = %+v", summary.Assets)
	}
	if summary.DBSnapshot.AgeSeconds == nil || *summary.DBSnapshot.AgeSeconds != 90 || summary.DBSnapshot.Status != "ok" {
		t.Fatalf("snapshot = %+v", summary.DBSnapshot)
	}
	if summary.CloudflareMetrics != CloudflareMetricsNotInV2 {
		t.Fatalf("cloudflare = %q", summary.CloudflareMetrics)
	}
	if summary.Settings == nil || summary.Settings.ResPath != "/srv/res" || summary.Settings.BackupPath != "/srv/backups" {
		t.Fatalf("settings = %+v", summary.Settings)
	}
	if summary.PublicURLs[PublicRoleSDK] != "https://sdk.example" || summary.PublicURLs[PublicRoleAPI] != "https://game.example" {
		t.Fatalf("public urls = %v", summary.PublicURLs)
	}
}

func TestDashboardSummaryAnswersWhileTheBackendIsDown(t *testing.T) {
	summary := Dashboard{
		Backend:  fakeDashboardBackend{status: BackendStatus{Running: false}},
		Operator: fakeDashboardOperator{errs: map[string]error{"server.list": errors.New("down")}},
		Version:  fakeVersionSource{err: errors.New("down")},
		Backups:  BackupService{Directory: filepath.Join(t.TempDir(), "missing")},
		Now:      func() time.Time { return fixedClock() },
	}.Summary(context.Background())
	if summary.API.Reachable {
		t.Fatalf("api = %+v", summary.API)
	}
	if len(summary.Servers) != 0 || len(summary.Events) != 0 {
		t.Fatalf("servers = %+v events = %+v", summary.Servers, summary.Events)
	}
	if len(summary.Errors) != 1 || summary.DBSnapshot.AgeSeconds != nil || summary.DBSnapshot.Status != "no snapshots" {
		t.Fatalf("errors = %+v snapshot = %+v", summary.Errors, summary.DBSnapshot)
	}
	if summary.CloudflareMetrics != CloudflareMetricsNotInV2 {
		t.Fatalf("cloudflare = %q", summary.CloudflareMetrics)
	}
}

// TestDashboardSnapshotAgeSkipsTheDamagedNewestFile proves the age comes from
// the newest VALID manifest, so a partial or tampered dump never counts.
func TestDashboardSnapshotAgeSkipsTheDamagedNewestFile(t *testing.T) {
	directory := t.TempDir()
	at := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)
	writeSnapshot(t, directory, "20260101T000000.000000000Z-manual", BackupKindManual, at.Add(-10*time.Minute), "old")
	writeSnapshot(t, directory, "20260102T000000.000000000Z-manual", BackupKindManual, at.Add(-time.Minute), "new")
	damagedDump := filepath.Join(directory, "20260102T000000.000000000Z-manual"+backupDumpSuffix)
	if err := os.WriteFile(damagedDump, []byte("tampered"), 0o600); err != nil {
		t.Fatal(err)
	}
	summary := Dashboard{
		Backups: BackupService{Directory: directory},
		Now:     func() time.Time { return at },
	}.Summary(context.Background())
	if summary.DBSnapshot.Status != "ok" || summary.DBSnapshot.AgeSeconds == nil || *summary.DBSnapshot.AgeSeconds != 600 {
		t.Fatalf("snapshot = %+v", summary.DBSnapshot)
	}
}

func stringPtr(value string) *string { return &value }
