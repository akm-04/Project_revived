package otarelease

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	stateSHA = "1111111111111111111111111111111111111111111111111111111111111111"
	stateMD5 = "22222222222222222222222222222222"
)

func stateRelease(version string, lane domain.Lane) domain.Release {
	parsed, err := domain.ParseVersion(version)
	if err != nil {
		panic(err)
	}
	return domain.Release{
		Version: parsed,
		Lane:    lane,
		State:   domain.StateBuilt,
		Volumes: []domain.PackageVolume{{
			Name: version + "-" + stateSHA[:12] + ".zip.001", Size: 1000, MD5: stateMD5, SHA256: stateSHA,
		}},
		TotalSize: 1000,
		MD5:       stateMD5,
		SHA256:    stateSHA,
		Manifest:  []domain.ManifestEntry{{Path: "src_64/app/a.lua", Size: 1, MD5: stateMD5}},
	}
}

func publishStateRelease(t *testing.T, store *StateFile, version string, lane domain.Lane, at time.Time) int64 {
	t.Helper()
	release := stateRelease(version, lane)
	if err := store.InsertBuildTx(context.Background(), nil, release, "command-"+version, at); err != nil {
		t.Fatal(err)
	}
	if _, err := store.SupersedeLaneTx(context.Background(), nil, lane, at); err != nil {
		t.Fatal(err)
	}
	if err := store.ActivateTx(context.Background(), nil, version, "command-"+version, at); err != nil {
		t.Fatal(err)
	}
	releaseID, err := store.ReleaseTx(context.Background(), nil, version)
	if err != nil || releaseID == nil {
		t.Fatalf("release %s missing: %v", version, err)
	}
	activationID, err := store.InsertActivationTx(context.Background(), nil, ActivationRow{
		ReleaseID: releaseID.ID, Version: version, Action: "PUBLISH", CommandKey: "command-" + version, At: at,
	})
	if err != nil {
		t.Fatal(err)
	}
	return activationID
}

func TestStateFileSurvivesANewInstance(t *testing.T) {
	root := t.TempDir()
	at := time.Now().UTC().Truncate(time.Microsecond)
	first := NewStateFile(root)
	activationID := publishStateRelease(t, first, "1.631.2", domain.LaneCode, at)

	// A restored database starts a new process: the release must still be live.
	second := NewStateFile(root)
	rows, err := second.ListActiveTx(context.Background(), nil)
	if err != nil || len(rows) != 1 || rows[0].Version != "1.631.2" || rows[0].State != string(domain.StateActive) {
		t.Fatalf("active rows after restart = %+v err=%v", rows, err)
	}
	exists, lane, state, err := second.ReleaseStatusTx(context.Background(), nil, "1.631.2")
	if err != nil || !exists || lane != string(domain.LaneCode) || state != string(domain.StateActive) {
		t.Fatalf("release status = %v %q %q err=%v", exists, lane, state, err)
	}
	revision, err := second.ActiveRevisionTx(context.Background(), nil)
	if err != nil || revision != activationID {
		t.Fatalf("revision = %d want %d err=%v", revision, activationID, err)
	}
}

func TestStateFileStatusDerivesTheNextVersion(t *testing.T) {
	store := NewStateFile(t.TempDir())
	at := time.Now().UTC().Truncate(time.Microsecond)
	publishStateRelease(t, store, "1.631.3", domain.LaneCode, at)
	publishStateRelease(t, store, "1.631.1", domain.LaneAssets, at)
	if err := store.InsertBuildTx(context.Background(), nil, stateRelease("1.631.9", domain.LaneCatalog), "command-catalog", at); err != nil {
		t.Fatal(err)
	}

	snapshot, err := store.ReadStatusTx(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	status, err := foldStatus(snapshot)
	if err != nil {
		t.Fatal(err)
	}
	if status.NextVersion != "1.631.10" {
		t.Fatalf("next version = %q, want 1.631.10", status.NextVersion)
	}
	if status.Active.Code == nil || *status.Active.Code != "1.631.3" || status.Active.Assets == nil || *status.Active.Assets != "1.631.1" {
		t.Fatalf("active = %+v", status.Active)
	}
	if len(status.Built) != 1 || status.Built[0].Version != "1.631.9" {
		t.Fatalf("built = %+v", status.Built)
	}
	if len(status.Activations) != 2 || status.Revision == 0 {
		t.Fatalf("activations = %+v revision=%d", status.Activations, status.Revision)
	}
}

func TestStateFileAssetsGuard(t *testing.T) {
	store := NewStateFile(t.TempDir())
	at := time.Now().UTC().Truncate(time.Microsecond)
	publishStateRelease(t, store, "1.631.2", domain.LaneCode, at)
	active, err := store.HasActiveAssets()
	if err != nil || active {
		t.Fatalf("code release counted as assets: %v %v", active, err)
	}
	publishStateRelease(t, store, "1.631.1", domain.LaneAssets, at)
	active, err = store.HasActiveAssets()
	if err != nil || !active {
		t.Fatalf("assets release not seen: %v %v", active, err)
	}
}

func TestStateFileWritesAtomically(t *testing.T) {
	root := t.TempDir()
	store := NewStateFile(root)
	if err := store.InsertBuildTx(context.Background(), nil, stateRelease("1.631.2", domain.LaneCode), "command", time.Now()); err != nil {
		t.Fatal(err)
	}
	entries, err := os.ReadDir(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 1 || entries[0].Name() != releaseStateFileName {
		t.Fatalf("folder after one write = %v", entries)
	}
}

type fixedStateExporter struct {
	document StateDocument
	calls    int
}

func (exporter *fixedStateExporter) ExportStateTx(context.Context, tx.Queryer) (StateDocument, error) {
	exporter.calls++
	return exporter.document, nil
}

func TestStateFileSeedsOnceFromTheDatabase(t *testing.T) {
	root := t.TempDir()
	store := NewStateFile(root)
	at := time.Now().UTC().Truncate(time.Microsecond)
	document := StateDocument{
		Releases: []StoredRelease{{
			RawRelease: domain.RawRelease{ID: 4, Version: "1.631.2", Lane: string(domain.LaneAssets), State: string(domain.StateActive)},
			BuiltAt:    &at,
		}},
		Activations: []StoredActivation{{ID: 7, ReleaseID: 4, Version: "1.631.2", Action: "PUBLISH", CommandKey: "seed", At: at}},
	}
	exporter := &fixedStateExporter{document: document}
	seeded, err := store.Seed(context.Background(), tx.Runner{DB: fakeDB{}}, exporter)
	if err != nil || !seeded || exporter.calls != 1 {
		t.Fatalf("seed = %v err=%v calls=%d", seeded, err, exporter.calls)
	}
	if active, err := store.HasActiveAssets(); err != nil || !active {
		t.Fatalf("seeded assets missing: %v %v", active, err)
	}
	// A second start sees the file and never re-reads the database.
	again, err := store.Seed(context.Background(), tx.Runner{DB: fakeDB{}}, &fixedStateExporter{})
	if err != nil || again {
		t.Fatalf("second seed = %v err=%v", again, err)
	}
	if _, err := os.Stat(filepath.Join(root, releaseStateFileName)); err != nil {
		t.Fatal(err)
	}
}

func TestCommandsWorkOnTheReleaseFile(t *testing.T) {
	root := t.TempDir()
	directory := filepath.Join(root, "updates", "code")
	if err := os.MkdirAll(directory, 0o755); err != nil {
		t.Fatal(err)
	}
	volumeName := "1.631.2-" + stateSHA[:12] + ".zip.001"
	if err := os.WriteFile(filepath.Join(directory, volumeName), make([]byte, 1000), 0o644); err != nil {
		t.Fatal(err)
	}
	packageFiles, err := json.Marshal([]domain.PackageVolume{{Name: volumeName, Size: 1000, MD5: stateMD5, SHA256: stateSHA}})
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := json.Marshal(map[string]any{"files": []domain.ManifestEntry{{Path: "src_64/app/a.lua", Size: 1, MD5: stateMD5}}})
	if err != nil {
		t.Fatal(err)
	}
	request := domain.BuildRequest{Version: "1.631.2", Lane: "code", PackageFiles: packageFiles, TotalSize: 1000, MD5: stateMD5, SHA256: stateSHA, Manifest: manifest}
	commands := Commands{Store: NewStateFile(root), Root: root}
	at := time.Now().UTC().Truncate(time.Microsecond)
	if _, err := commands.RegisterBuild(context.Background(), fakeTx{}, "build-key", request, at); err != nil {
		t.Fatal(err)
	}
	activation, err := commands.Publish(context.Background(), fakeTx{}, "publish-key", new(int64), "1.631.2", at.Add(time.Second))
	if err != nil {
		t.Fatal(err)
	}
	if activation.State != string(domain.StateActive) || activation.ActivationID == 0 {
		t.Fatalf("activation = %+v", activation)
	}
	restarted := NewStateFile(root)
	rows, err := restarted.ListActiveTx(context.Background(), nil)
	if err != nil || len(rows) != 1 || rows[0].Version != "1.631.2" {
		t.Fatalf("active after restart = %+v err=%v", rows, err)
	}
	if _, err := domain.ParseReleases(rows); err != nil {
		t.Fatalf("the stored release does not parse after a restart: %v", err)
	}
}

func TestCommandRetryReplaysTheRecordedReply(t *testing.T) {
	root := t.TempDir()
	directory := filepath.Join(root, "updates", "code")
	if err := os.MkdirAll(directory, 0o755); err != nil {
		t.Fatal(err)
	}
	volumeName := "1.631.2-" + stateSHA[:12] + ".zip.001"
	if err := os.WriteFile(filepath.Join(directory, volumeName), make([]byte, 1000), 0o644); err != nil {
		t.Fatal(err)
	}
	packageFiles, err := json.Marshal([]domain.PackageVolume{{Name: volumeName, Size: 1000, MD5: stateMD5, SHA256: stateSHA}})
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := json.Marshal(map[string]any{"files": []domain.ManifestEntry{{Path: "src_64/app/a.lua", Size: 1, MD5: stateMD5}}})
	if err != nil {
		t.Fatal(err)
	}
	request := domain.BuildRequest{Version: "1.631.2", Lane: "code", PackageFiles: packageFiles, TotalSize: 1000, MD5: stateMD5, SHA256: stateSHA, Manifest: manifest}
	payload, err := json.Marshal(request)
	if err != nil {
		t.Fatal(err)
	}
	at := time.Now().UTC().Truncate(time.Microsecond)
	commands := Commands{Store: NewStateFile(root), Root: root}
	scope := tx.Scope{Tx: fakeTx{}, Operation: operation.Context{StartedAt: at}}
	build := operator.Command{Envelope: operator.Envelope{SemanticKey: "build-key"}, Payload: payload}
	firstBuild, err := commands.registerBuildHandler(context.Background(), scope, build)
	if err != nil {
		t.Fatal(err)
	}
	secondBuild, err := commands.registerBuildHandler(context.Background(), scope, build)
	if err != nil {
		t.Fatal(err)
	}
	firstJSON, _ := json.Marshal(firstBuild)
	secondJSON, _ := json.Marshal(secondBuild)
	if string(firstJSON) != string(secondJSON) {
		t.Fatalf("retried build = %s, want %s", secondJSON, firstJSON)
	}
	document, err := commands.Store.(*StateFile).Load()
	if err != nil || len(document.Releases) != 1 {
		t.Fatalf("releases after a retried build = %+v err=%v", document.Releases, err)
	}

	revision := int64(0)
	publish := operator.Command{Envelope: operator.Envelope{SemanticKey: "publish-key", ExpectedRevision: &revision}, Payload: json.RawMessage(`{"version":"1.631.2"}`)}
	firstPublish, err := commands.publishHandler(context.Background(), scope, publish)
	if err != nil {
		t.Fatal(err)
	}
	secondPublish, err := commands.publishHandler(context.Background(), scope, publish)
	if err != nil {
		t.Fatal(err)
	}
	firstJSON, _ = json.Marshal(firstPublish)
	secondJSON, _ = json.Marshal(secondPublish)
	if string(firstJSON) != string(secondJSON) {
		t.Fatalf("retried publish = %s, want %s", secondJSON, firstJSON)
	}
	document, err = commands.Store.(*StateFile).Load()
	if err != nil || len(document.Activations) != 1 {
		t.Fatalf("activations after a retried publish = %+v err=%v", document.Activations, err)
	}
}

func TestStateFileRollbackReuseHidesTheReplacedRow(t *testing.T) {
	store := NewStateFile(t.TempDir())
	at := time.Now().UTC().Truncate(time.Microsecond)
	if err := store.InsertBuildTx(context.Background(), nil, stateRelease("1.631.2", domain.LaneCode), "first", at); err != nil {
		t.Fatal(err)
	}
	row, err := store.ReleaseTx(context.Background(), nil, "1.631.2")
	if err != nil || row == nil {
		t.Fatalf("first row = %+v err=%v", row, err)
	}
	if err := store.ReuseBuildTx(context.Background(), nil, row.ID, stateRelease("1.631.2", domain.LaneCode), "second", at.Add(time.Second)); err != nil {
		t.Fatal(err)
	}
	exists, _, state, err := store.ReleaseStatusTx(context.Background(), nil, "1.631.2")
	if err != nil || !exists || state != string(domain.StateBuilt) {
		t.Fatalf("reused release = %v %q err=%v", exists, state, err)
	}
	document, err := store.Load()
	if err != nil {
		t.Fatal(err)
	}
	replaced := 0
	for _, release := range document.Releases {
		if release.State == string(domain.StateReplaced) {
			replaced++
		}
	}
	if replaced != 1 || len(document.Releases) != 2 {
		t.Fatalf("document = %+v", document.Releases)
	}
}
