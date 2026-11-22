package otarelease

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"sort"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	commandSHA = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	commandMD5 = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
)

type noTx struct{}

func (noTx) QueryRow(context.Context, string, ...any) tx.Row { return noRow{} }
func (noTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return nil, errors.New("unused fake transaction")
}
func (noTx) Commit(context.Context) error   { return nil }
func (noTx) Rollback(context.Context) error { return nil }

type noRow struct{}

func (noRow) Scan(...any) error { return errors.New("unused fake transaction") }

type fakeStore struct {
	releases    map[string]*domain.RawRelease
	activations []ActivationRow
	nextID      int64
	builtBy     map[string]string
}

func newFakeStore() *fakeStore {
	return &fakeStore{releases: map[string]*domain.RawRelease{}, builtBy: map[string]string{}}
}

func (store *fakeStore) ReleaseTx(_ context.Context, _ tx.Queryer, version string) (*domain.RawRelease, error) {
	row, found := store.releases[version]
	if !found {
		return nil, nil
	}
	copy := *row
	return &copy, nil
}

func (store *fakeStore) LockLaneTx(_ context.Context, _ tx.Tx, lane domain.Lane) ([]domain.RawRelease, error) {
	rows := make([]domain.RawRelease, 0)
	for _, row := range store.releases {
		if row.Lane == string(lane) {
			rows = append(rows, *row)
		}
	}
	sort.Slice(rows, func(left, right int) bool { return rows[left].Version < rows[right].Version })
	return rows, nil
}

func (store *fakeStore) ActiveRevisionTx(context.Context, tx.Queryer) (int64, error) {
	return store.nextID, nil
}

func (store *fakeStore) InsertBuildTx(_ context.Context, _ tx.Tx, release domain.Release, commandKey string, _ time.Time) error {
	packageFiles, err := json.Marshal(release.Volumes)
	if err != nil {
		return err
	}
	manifest, err := json.Marshal(map[string]any{"files": release.Manifest})
	if err != nil {
		return err
	}
	store.releases[release.Version.String()] = &domain.RawRelease{
		Version: release.Version.String(), Lane: string(release.Lane), State: string(domain.StateBuilt),
		PackageFiles: packageFiles, TotalSize: release.TotalSize, MD5: release.MD5, SHA256: release.SHA256, Manifest: manifest,
	}
	store.builtBy[release.Version.String()] = commandKey
	return nil
}

func (store *fakeStore) SupersedeLaneTx(_ context.Context, _ tx.Tx, lane domain.Lane, _ time.Time) ([]string, error) {
	var versions []string
	for _, row := range store.releases {
		if row.Lane == string(lane) && row.State == string(domain.StateActive) {
			row.State = string(domain.StateSuperseded)
			versions = append(versions, row.Version)
		}
	}
	sort.Strings(versions)
	return versions, nil
}

func (store *fakeStore) ActivateTx(_ context.Context, _ tx.Tx, version, _ string, _ time.Time) error {
	row, found := store.releases[version]
	if !found || row.State != string(domain.StateBuilt) {
		return errors.New("not built")
	}
	row.State = string(domain.StateActive)
	return nil
}

func (store *fakeStore) WithdrawTx(_ context.Context, _ tx.Tx, version string, _ time.Time) error {
	row, found := store.releases[version]
	if !found || row.State != string(domain.StateActive) {
		return errors.New("not active")
	}
	row.State = string(domain.StateWithdrawn)
	return nil
}

func (store *fakeStore) InsertActivationTx(_ context.Context, _ tx.Tx, activation ActivationRow) (int64, error) {
	store.nextID++
	store.activations = append(store.activations, activation)
	return store.nextID, nil
}

func buildPayload(t *testing.T, version, lane string, size int64) domain.BuildRequest {
	t.Helper()
	var request domain.BuildRequest
	packageFiles, err := json.Marshal([]domain.PackageVolume{{Name: version + "-" + commandSHA[:12] + ".zip.001", Size: size, MD5: commandMD5, SHA256: commandSHA}})
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := json.Marshal(map[string]any{"files": []domain.ManifestEntry{{Path: "src_64/app/a.lua", Size: 1, MD5: commandMD5}}})
	if err != nil {
		t.Fatal(err)
	}
	request = domain.BuildRequest{Version: version, Lane: lane, PackageFiles: packageFiles, TotalSize: size, MD5: commandMD5, SHA256: commandSHA, Manifest: manifest}
	return request
}

// rootWithVolumes writes every volume file of the requests under a temporary
// OTA root so the size check passes.
func rootWithVolumes(t *testing.T, requests ...domain.BuildRequest) string {
	t.Helper()
	root := t.TempDir()
	for _, request := range requests {
		var volumes []domain.PackageVolume
		if err := json.Unmarshal(request.PackageFiles, &volumes); err != nil {
			t.Fatal(err)
		}
		directory := filepath.Join(root, "updates", request.Lane)
		if err := os.MkdirAll(directory, 0o755); err != nil {
			t.Fatal(err)
		}
		for _, volume := range volumes {
			if err := os.WriteFile(filepath.Join(directory, volume.Name), make([]byte, volume.Size), 0o644); err != nil {
				t.Fatal(err)
			}
		}
	}
	return root
}

func refusalCode(t *testing.T, err error) string {
	t.Helper()
	var refusal *operator.Refusal
	if !errors.As(err, &refusal) {
		t.Fatalf("err is not a refusal: %v", err)
	}
	return refusal.Code
}

func TestRegisterBuildRules(t *testing.T) {
	ctx := context.Background()
	at := time.Unix(1000, 0).UTC()
	existing := buildPayload(t, "1.631.5", "code", 2000)
	store := newFakeStore()
	commands := Commands{Store: store, Root: rootWithVolumes(t, existing)}
	if _, err := commands.RegisterBuild(ctx, noTx{}, "cmd-active", existing, at); err != nil {
		t.Fatal(err)
	}
	store.releases["1.631.5"].State = string(domain.StateActive)

	if _, err := commands.RegisterBuild(ctx, noTx{}, "cmd-equal", existing, at); refusalCode(t, err) != CodeVersionExists {
		t.Fatalf("equal number err=%v", err)
	}
	lower := buildPayload(t, "1.631.4", "code", 2000)
	if _, err := commands.RegisterBuild(ctx, noTx{}, "cmd-lower", lower, at); refusalCode(t, err) != CodeRollbackRequired {
		t.Fatalf("lower without rollback err=%v", err)
	}
	lower.Rollback = true
	commands.Root = rootWithVolumes(t, lower)
	result, err := commands.RegisterBuild(ctx, noTx{}, "cmd-rollback", lower, at)
	if err != nil {
		t.Fatal(err)
	}
	if !result.Rollback || result.Warning != domain.RollbackWarning || store.releases["1.631.4"].State != string(domain.StateBuilt) || store.builtBy["1.631.4"] != "cmd-rollback" {
		t.Fatalf("rollback result=%+v", result)
	}
	if _, err := commands.RegisterBuild(ctx, noTx{}, "cmd-bad", domain.BuildRequest{Version: "1.631.6"}, at); refusalCode(t, err) != CodePayloadInvalid {
		t.Fatalf("bad row err=%v", err)
	}
}

func TestRegisterBuildRefusesMissingVolume(t *testing.T) {
	request := buildPayload(t, "1.631.2", "code", 4096)
	commands := Commands{Store: newFakeStore(), Root: t.TempDir()}
	_, err := commands.RegisterBuild(context.Background(), noTx{}, "cmd", request, time.Unix(1000, 0).UTC())
	if refusalCode(t, err) != CodeVolumeMissing {
		t.Fatalf("err=%v", err)
	}
	commands.Root = ""
	if _, err := commands.RegisterBuild(context.Background(), noTx{}, "cmd", request, time.Unix(1000, 0).UTC()); refusalCode(t, err) != CodeRootUnavailable {
		t.Fatalf("unset root err=%v", err)
	}
}

func TestPublishSupersedesTheLaneAndKeepsCatalogSideBySide(t *testing.T) {
	ctx := context.Background()
	at := time.Unix(1000, 0).UTC()
	first := buildPayload(t, "1.631.5", "code", 2000)
	second := buildPayload(t, "1.631.6", "code", 2000)
	catalogOne := buildPayload(t, "1.631.7", "catalog", 2000)
	catalogTwo := buildPayload(t, "1.631.8", "catalog", 2000)
	store := newFakeStore()
	commands := Commands{Store: store, Root: rootWithVolumes(t, first, second, catalogOne, catalogTwo)}
	for _, request := range []domain.BuildRequest{first, second, catalogOne, catalogTwo} {
		if _, err := commands.RegisterBuild(ctx, noTx{}, "cmd-"+request.Version, request, at); err != nil {
			t.Fatal(err)
		}
	}
	revision := int64(0)
	activation, err := commands.Publish(ctx, noTx{}, "cmd-publish-1", &revision, "1.631.5", at)
	if err != nil || activation.State != string(domain.StateActive) || activation.ActivationID != 1 {
		t.Fatalf("publish=%+v err=%v", activation, err)
	}
	revision = 1
	activation, err = commands.Publish(ctx, noTx{}, "cmd-publish-2", &revision, "1.631.6", at)
	if err != nil || len(activation.Superseded) != 1 || activation.Superseded[0] != "1.631.5" {
		t.Fatalf("second publish=%+v err=%v", activation, err)
	}
	if store.releases["1.631.5"].State != string(domain.StateSuperseded) || store.releases["1.631.6"].State != string(domain.StateActive) {
		t.Fatalf("code states=%s/%s", store.releases["1.631.5"].State, store.releases["1.631.6"].State)
	}
	revision = 2
	if _, err := commands.Publish(ctx, noTx{}, "cmd-publish-3", &revision, "1.631.7", at); err != nil {
		t.Fatal(err)
	}
	revision = 3
	activation, err = commands.Publish(ctx, noTx{}, "cmd-publish-4", &revision, "1.631.8", at)
	if err != nil || len(activation.Superseded) != 0 {
		t.Fatalf("catalog publish=%+v err=%v", activation, err)
	}
	if store.releases["1.631.7"].State != string(domain.StateActive) || store.releases["1.631.8"].State != string(domain.StateActive) {
		t.Fatalf("catalog states=%s/%s", store.releases["1.631.7"].State, store.releases["1.631.8"].State)
	}
}

func TestPublishRefusesNonBuiltAndStaleRevision(t *testing.T) {
	ctx := context.Background()
	at := time.Unix(1000, 0).UTC()
	request := buildPayload(t, "1.631.2", "code", 2000)
	store := newFakeStore()
	commands := Commands{Store: store, Root: rootWithVolumes(t, request)}
	if _, err := commands.RegisterBuild(ctx, noTx{}, "cmd", request, at); err != nil {
		t.Fatal(err)
	}
	store.releases["1.631.2"].State = string(domain.StateActive)
	revision := int64(0)
	if _, err := commands.Publish(ctx, noTx{}, "cmd", &revision, "1.631.2", at); refusalCode(t, err) != CodeStateInvalid {
		t.Fatalf("non-built err=%v", err)
	}
	store.releases["1.631.2"].State = string(domain.StateBuilt)
	store.nextID = 4
	stale := int64(3)
	_, err := commands.Publish(ctx, noTx{}, "cmd", &stale, "1.631.2", at)
	var refusal *operator.Refusal
	if !errors.As(err, &refusal) || refusal.Code != operator.CodeRevisionStale {
		t.Fatalf("stale err=%v", err)
	}
	detail, ok := refusal.Detail.(map[string]int64)
	if !ok || detail["current_revision"] != 4 {
		t.Fatalf("stale detail=%#v", refusal.Detail)
	}
	if _, err := commands.Publish(ctx, noTx{}, "cmd", nil, "1.631.2", at); refusalCode(t, err) != CodeRevisionRequired {
		t.Fatalf("missing revision err=%v", err)
	}
	if _, err := commands.Publish(ctx, noTx{}, "cmd", &revision, "9.9.9", at); refusalCode(t, err) != CodeReleaseUnknown {
		t.Fatalf("unknown release err=%v", err)
	}
}

func TestWithdrawOnlyActive(t *testing.T) {
	ctx := context.Background()
	at := time.Unix(1000, 0).UTC()
	request := buildPayload(t, "1.631.2", "code", 2000)
	store := newFakeStore()
	commands := Commands{Store: store, Root: rootWithVolumes(t, request)}
	if _, err := commands.RegisterBuild(ctx, noTx{}, "cmd", request, at); err != nil {
		t.Fatal(err)
	}
	revision := int64(0)
	if _, err := commands.Withdraw(ctx, noTx{}, "cmd", &revision, "1.631.2", at); refusalCode(t, err) != CodeStateInvalid {
		t.Fatalf("built withdraw err=%v", err)
	}
	store.releases["1.631.2"].State = string(domain.StateActive)
	store.nextID = 1
	revision = 1
	activation, err := commands.Withdraw(ctx, noTx{}, "cmd-withdraw", &revision, "1.631.2", at)
	if err != nil || activation.Action != "WITHDRAW" || activation.State != string(domain.StateWithdrawn) || store.releases["1.631.2"].State != string(domain.StateWithdrawn) {
		t.Fatalf("withdraw=%+v err=%v", activation, err)
	}
}
