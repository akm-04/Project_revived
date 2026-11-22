package otarelease

import (
	"bytes"
	"context"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
	"testing"

	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const servingSHA = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

func md5Hex(data []byte) string {
	sum := md5.Sum(data)
	return hex.EncodeToString(sum[:])
}

func servingRow(t *testing.T, version string, lane domain.Lane, volumeSize int64, manifestPaths []string) domain.RawRelease {
	t.Helper()
	name := version + "-" + servingSHA[:12] + ".zip.001"
	volumes, err := json.Marshal([]domain.PackageVolume{{Name: name, Size: volumeSize, MD5: md5Hex([]byte("volume")), SHA256: servingSHA}})
	if err != nil {
		t.Fatal(err)
	}
	files := make([]domain.ManifestEntry, 0, len(manifestPaths))
	for _, manifestPath := range manifestPaths {
		files = append(files, domain.ManifestEntry{Path: manifestPath, Size: 1, MD5: md5Hex([]byte(manifestPath))})
	}
	manifest, err := json.Marshal(map[string]any{"files": files})
	if err != nil {
		t.Fatal(err)
	}
	return domain.RawRelease{
		Version: version, Lane: string(lane), State: string(domain.StateActive),
		PackageFiles: volumes, TotalSize: volumeSize, MD5: md5Hex([]byte("zip")), SHA256: servingSHA, Manifest: manifest,
	}
}

func volumeName(version string) string {
	return version + "-" + servingSHA[:12] + ".zip.001"
}

type servingFixture struct {
	root     string
	res      string
	rows     []domain.RawRelease
	ledger   *Ledger
	captures *captureLedgerStore
	serving  *Serving
	asset    []byte
	assetKey string
}

type captureLedgerStore struct {
	served []ServedCount
	misses []MissRecord
}

func (c *captureLedgerStore) FlushTx(_ context.Context, _ tx.Tx, served []ServedCount, misses []MissRecord) error {
	c.served = append(c.served, served...)
	c.misses = append(c.misses, misses...)
	return nil
}

type fakeTag int64

func (t fakeTag) RowsAffected() int64 { return int64(t) }

type fakeRow struct{}

func (fakeRow) Scan(...any) error { return errors.New("unexpected query") }

type fakeTx struct{}

func (fakeTx) QueryRow(context.Context, string, ...any) tx.Row             { return fakeRow{} }
func (fakeTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return fakeTag(0), nil }
func (fakeTx) Commit(context.Context) error                                { return nil }
func (fakeTx) Rollback(context.Context) error                              { return nil }

type fakeDB struct{}

func (fakeDB) Begin(context.Context, tx.Options) (tx.Tx, error) { return fakeTx{}, nil }

func newServingFixture(t *testing.T, release domain.RawRelease, asset []byte) servingFixture {
	t.Helper()
	root := t.TempDir()
	res := t.TempDir()
	releasePath := filepath.Join(root, "updates", string(domain.Lane(release.Lane)))
	if err := os.MkdirAll(releasePath, 0o755); err != nil {
		t.Fatal(err)
	}
	volume, err := os.OpenFile(filepath.Join(releasePath, volumeName(release.Version)), os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		t.Fatal(err)
	}
	size := release.TotalSize
	if _, err := volume.Write(bytes.Repeat([]byte("v"), int(size))); err != nil {
		volume.Close()
		t.Fatal(err)
	}
	volume.Close()
	assetPath := filepath.Join(res, "res", "web", "a.png")
	if err := os.MkdirAll(filepath.Dir(assetPath), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(assetPath, asset, 0o644); err != nil {
		t.Fatal(err)
	}
	sidecar := map[string]any{"entries": []resAsset{
		{Path: "res/web/a.png", MD5: md5Hex(asset), Size: int64(len(asset))},
		{Path: "res/web/a.png", MD5: md5Hex([]byte("wrong")), Size: int64(len(asset))},
	}}
	data, err := json.Marshal(sidecar)
	if err != nil {
		t.Fatal(err)
	}
	base := strings.TrimSuffix(volumeName(release.Version), ".001")
	if err := os.WriteFile(filepath.Join(releasePath, base+".res.json"), data, 0o644); err != nil {
		t.Fatal(err)
	}
	captures := &captureLedgerStore{}
	ledger := NewLedger(tx.Runner{DB: fakeDB{}}, operation.Factory{Clock: clock.System{}}, captures)
	rows := []domain.RawRelease{release}
	return servingFixture{
		root: root, res: res, rows: rows, ledger: ledger, captures: captures,
		serving: &Serving{
			Load: func(context.Context) ([]domain.RawRelease, error) { return rows, nil },
			Root: root, Settings: NewSettingsValue(domain.Settings{LazyFetch: domain.LazyFetchOn, ResPath: res}),
			PublicEngineURL: "https://engine.example", Ledger: ledger,
		},
		asset: asset, assetKey: "a.png." + md5Hex(asset),
	}
}

func TestServingOpenVolumeOnlyServesActiveNames(t *testing.T) {
	fixture := newServingFixture(t, servingRow(t, "1.631.1", domain.LaneAssets, 12, []string{"src_64/app/a.lua"}), []byte("asset"))
	file, _, servable, err := fixture.serving.OpenVolume(context.Background(), "assets", volumeName("1.631.1"))
	if err != nil || !servable {
		t.Fatalf("servable=%v err=%v", servable, err)
	}
	data, err := io.ReadAll(file)
	file.Close()
	if err != nil || len(data) != 12 {
		t.Fatalf("data len=%d err=%v", len(data), err)
	}
	for _, test := range []struct{ lane, name string }{
		{"code", volumeName("1.631.1")},
		{"assets", "../settings.json"},
		{"assets", "other.zip.001"},
		{"unknown", volumeName("1.631.1")},
	} {
		if _, _, servable, err := fixture.serving.OpenVolume(context.Background(), test.lane, test.name); err != nil || servable {
			t.Fatalf("%s/%s servable=%v err=%v", test.lane, test.name, servable, err)
		}
	}
}

func TestServingOpenResourceHitMissAndMismatch(t *testing.T) {
	fixture := newServingFixture(t, servingRow(t, "1.631.1", domain.LaneAssets, 12, []string{"src_64/app/a.lua"}), []byte("asset"))
	file, _, resourcePath, servable, err := fixture.serving.OpenResource(context.Background(), fixture.assetKey)
	if err != nil || !servable || resourcePath != "res/web/a.png" {
		t.Fatalf("servable=%v path=%q err=%v", servable, resourcePath, err)
	}
	data, err := io.ReadAll(file)
	file.Close()
	if err != nil || string(data) != "asset" {
		t.Fatalf("data=%q err=%v", data, err)
	}

	if _, _, _, servable, err := fixture.serving.OpenResource(context.Background(), "unknown.png."+md5Hex([]byte("x"))); err != nil || servable {
		t.Fatalf("unknown key servable=%v err=%v", servable, err)
	}
	if _, _, _, servable, err := fixture.serving.OpenResource(context.Background(), "a.png."+md5Hex([]byte("wrong"))); err != nil || servable {
		t.Fatalf("mismatched key servable=%v err=%v", servable, err)
	}
	if _, _, _, servable, _ := fixture.serving.OpenResource(context.Background(), fixture.assetKey); !servable {
		t.Fatal("second hit failed")
	}
	if err := fixture.ledger.Flush(context.Background()); err != nil {
		t.Fatal(err)
	}
	if len(fixture.captures.served) != 1 || fixture.captures.served[0].Path != "res/web/a.png" || fixture.captures.served[0].Hits != 2 {
		t.Fatalf("served=%+v", fixture.captures.served)
	}
	if len(fixture.captures.misses) != 2 {
		t.Fatalf("misses=%+v", fixture.captures.misses)
	}
	foundMismatch := false
	for _, miss := range fixture.captures.misses {
		if miss.Path == "res/web/a.png" && miss.MD5 == md5Hex([]byte("wrong")) {
			foundMismatch = true
		}
	}
	if !foundMismatch {
		t.Fatalf("mismatch miss not recorded: %+v", fixture.captures.misses)
	}
}

func TestServingMissLogsOncePerPath(t *testing.T) {
	fixture := newServingFixture(t, servingRow(t, "1.631.1", domain.LaneAssets, 12, []string{"src_64/app/a.lua"}), []byte("asset"))
	var output bytes.Buffer
	previous := log.Writer()
	log.SetOutput(&output)
	defer log.SetOutput(previous)
	for range 3 {
		if _, _, _, servable, _ := fixture.serving.OpenResource(context.Background(), "missing.png."+md5Hex([]byte("x"))); servable {
			t.Fatal("missing resource served")
		}
	}
	if got := strings.Count(output.String(), "ota asset miss:"); got != 1 {
		t.Fatalf("miss log lines=%d:\n%s", got, output.String())
	}
	if err := fixture.ledger.Flush(context.Background()); err != nil {
		t.Fatal(err)
	}
	if len(fixture.captures.misses) != 1 || fixture.captures.misses[0].Hits != 3 {
		t.Fatalf("misses=%+v", fixture.captures.misses)
	}
}

func TestServingResDownloadURLRules(t *testing.T) {
	codeOnly := newServingFixture(t, servingRow(t, "1.631.2", domain.LaneCode, 12, []string{"src_64/app/a.lua"}), []byte("asset"))
	codeOnly.serving.Settings = NewSettingsValue(domain.Settings{LazyFetch: domain.LazyFetchAuto, ResPath: codeOnly.res})
	if url, err := codeOnly.serving.ResDownloadURL(context.Background()); err != nil || url != "" {
		t.Fatalf("auto without assets url=%q err=%v", url, err)
	}
	assets := newServingFixture(t, servingRow(t, "1.631.1", domain.LaneAssets, 12, []string{"src_64/app/a.lua"}), []byte("asset"))
	assets.serving.Settings = NewSettingsValue(domain.Settings{LazyFetch: domain.LazyFetchAuto, ResPath: assets.res})
	if url, err := assets.serving.ResDownloadURL(context.Background()); err != nil || url != "https://engine.example/res/" {
		t.Fatalf("auto with assets url=%q err=%v", url, err)
	}
	off := NewSettingsValue(domain.Settings{LazyFetch: domain.LazyFetchOff, ResPath: assets.res})
	assets.serving.Settings = off
	if url, err := assets.serving.ResDownloadURL(context.Background()); err != nil || url != "" {
		t.Fatalf("off url=%q err=%v", url, err)
	}
	noPath := NewSettingsValue(domain.Settings{LazyFetch: domain.LazyFetchOn, ResPath: ""})
	assets.serving.Settings = noPath
	if url, err := assets.serving.ResDownloadURL(context.Background()); err != nil || url != "" {
		t.Fatalf("no res_path url=%q err=%v", url, err)
	}
}

func TestServingResDownloadURLRequiresIndexAndReadablePath(t *testing.T) {
	assets := newServingFixture(t, servingRow(t, "1.631.1", domain.LaneAssets, 12, []string{"src_64/app/a.lua"}), []byte("asset"))
	assets.serving.Settings = NewSettingsValue(domain.Settings{LazyFetch: domain.LazyFetchAuto, ResPath: assets.res})
	if url, err := assets.serving.ResDownloadURL(context.Background()); err != nil || url != "https://engine.example/res/" {
		t.Fatalf("with sidecar url=%q err=%v", url, err)
	}

	sidecar := filepath.Join(assets.root, "updates", "assets", strings.TrimSuffix(volumeName("1.631.1"), ".001")+".res.json")
	if err := os.Remove(sidecar); err != nil {
		t.Fatal(err)
	}
	if err := assets.serving.Refresh(context.Background()); err != nil {
		t.Fatal(err)
	}
	if url, err := assets.serving.ResDownloadURL(context.Background()); err != nil || url != "" {
		t.Fatalf("missing sidecar url=%q err=%v", url, err)
	}

	moved := newServingFixture(t, servingRow(t, "1.631.2", domain.LaneAssets, 12, []string{"src_64/app/a.lua"}), []byte("asset"))
	moved.serving.Settings = NewSettingsValue(domain.Settings{LazyFetch: domain.LazyFetchAuto, ResPath: moved.res})
	if err := os.Rename(moved.res, moved.res+"-moved"); err != nil {
		t.Fatal(err)
	}
	if err := moved.serving.Refresh(context.Background()); err != nil {
		t.Fatal(err)
	}
	if url, err := moved.serving.ResDownloadURL(context.Background()); err != nil || url != "" {
		t.Fatalf("moved res_path url=%q err=%v", url, err)
	}
}

func TestServingOpenResourceRefusesWhenLazyFetchIsOff(t *testing.T) {
	fixture := newServingFixture(t, servingRow(t, "1.631.1", domain.LaneAssets, 12, []string{"src_64/app/a.lua"}), []byte("asset"))
	fixture.serving.Settings = NewSettingsValue(domain.Settings{LazyFetch: domain.LazyFetchOff, ResPath: fixture.res})
	if _, _, _, servable, err := fixture.serving.OpenResource(context.Background(), fixture.assetKey); err != nil || servable {
		t.Fatalf("lazy_fetch off served the asset: servable=%v err=%v", servable, err)
	}
}

func TestServingVerifiedMD5EvictsOneEntryAndKeepsHits(t *testing.T) {
	fixture := newServingFixture(t, servingRow(t, "1.631.1", domain.LaneAssets, 12, []string{"src_64/app/a.lua"}), []byte("asset"))
	assetPath := filepath.Join(fixture.res, "res", "web", "a.png")
	file, err := os.Open(assetPath)
	if err != nil {
		t.Fatal(err)
	}
	defer file.Close()
	info, err := file.Stat()
	if err != nil {
		t.Fatal(err)
	}
	serving := fixture.serving
	serving.md5Cache = map[md5CacheKey]string{}
	for index := range maxMD5CacheEntries {
		serving.md5Cache[md5CacheKey{path: fmt.Sprintf("filler-%d", index)}] = "filler"
	}
	want := md5Hex(fixture.asset)
	if got, err := serving.verifiedMD5(file, assetPath, info); err != nil || got != want {
		t.Fatalf("first digest=%q err=%v want=%q", got, err, want)
	}
	if len(serving.md5Cache) != maxMD5CacheEntries {
		t.Fatalf("cache cleared wholesale: entries=%d want=%d", len(serving.md5Cache), maxMD5CacheEntries)
	}
	if again, err := serving.verifiedMD5(file, assetPath, info); err != nil || again != want {
		t.Fatalf("cached digest=%q err=%v want=%q", again, err, want)
	}
	if len(serving.md5Cache) != maxMD5CacheEntries {
		t.Fatalf("hit changed the cache size: entries=%d", len(serving.md5Cache))
	}
}

func TestServingOpenResourceRejectsSymlinkEscape(t *testing.T) {
	fixture := newServingFixture(t, servingRow(t, "1.631.1", domain.LaneAssets, 12, []string{"src_64/app/a.lua"}), []byte("asset"))
	secret := []byte("outside-the-res-folder")
	outsideDirectory := t.TempDir()
	outsidePath := filepath.Join(outsideDirectory, "secret.png")
	if err := os.WriteFile(outsidePath, secret, 0o644); err != nil {
		t.Fatal(err)
	}
	linkPath := filepath.Join(fixture.res, "res", "web", "escape.png")
	if err := os.Symlink(outsidePath, linkPath); err != nil {
		t.Fatal(err)
	}
	sidecar, err := json.Marshal(map[string]any{"entries": []resAsset{{Path: "res/web/escape.png", MD5: md5Hex(secret), Size: int64(len(secret))}}})
	if err != nil {
		t.Fatal(err)
	}
	sidecarPath := filepath.Join(fixture.root, "updates", "assets", strings.TrimSuffix(volumeName("1.631.1"), ".001")+".res.json")
	if err := os.WriteFile(sidecarPath, sidecar, 0o644); err != nil {
		t.Fatal(err)
	}
	if err := fixture.serving.Refresh(context.Background()); err != nil {
		t.Fatal(err)
	}
	if _, _, _, servable, err := fixture.serving.OpenResource(context.Background(), "escape.png."+md5Hex(secret)); err != nil || servable {
		t.Fatalf("symlink escape served: servable=%v err=%v", servable, err)
	}
}

func TestServingCovers(t *testing.T) {
	fixture := newServingFixture(t, servingRow(t, "1.631.2", domain.LaneCode, 12, []string{"src_64/app/a.lua"}), []byte("asset"))
	covered := domain.CoversRequest{
		ClientPaths:    []string{"src_64/app/a.lua"},
		LazyAssets:     []domain.LazyAsset{{Path: "res/web/a.png", MD5: md5Hex(fixture.asset)}},
		MinCodeVersion: "1.631.1",
	}
	result, err := fixture.serving.Covers(context.Background(), covered)
	if err != nil || result.Status != domain.CoversCovered {
		t.Fatalf("covered result=%+v err=%v", result, err)
	}
	missingPath := covered
	missingPath.ClientPaths = []string{"src_64/app/missing.lua"}
	if result, err = fixture.serving.Covers(context.Background(), missingPath); err != nil || result.Status != domain.CoversMissing || len(result.MissingClientPaths) != 1 {
		t.Fatalf("missing path result=%+v err=%v", result, err)
	}
	missingAsset := covered
	missingAsset.LazyAssets = []domain.LazyAsset{{Path: "res/web/missing.png", MD5: md5Hex([]byte("missing"))}}
	if result, err = fixture.serving.Covers(context.Background(), missingAsset); err != nil || len(result.MissingLazyAssets) != 1 {
		t.Fatalf("missing asset result=%+v err=%v", result, err)
	}
	tooOld := covered
	tooOld.MinCodeVersion = "1.632.0"
	if result, err = fixture.serving.Covers(context.Background(), tooOld); err != nil || result.MissingCodeVersion != "1.632.0" {
		t.Fatalf("code too old result=%+v err=%v", result, err)
	}
}

func TestVerifyActiveVolumes(t *testing.T) {
	fixture := newServingFixture(t, servingRow(t, "1.631.1", domain.LaneAssets, 12, []string{"src_64/app/a.lua"}), []byte("asset"))
	releases, err := domain.ParseReleases(fixture.rows)
	if err != nil {
		t.Fatal(err)
	}
	if err := VerifyActiveVolumes(releases, fixture.root); err != nil {
		t.Fatal(err)
	}
	missing := filepath.Join(fixture.root, "updates", "assets", volumeName("1.631.1"))
	if err := os.Remove(missing); err != nil {
		t.Fatal(err)
	}
	err = VerifyActiveVolumes(releases, fixture.root)
	if err == nil || !strings.Contains(err.Error(), "1.631.1") || !strings.Contains(err.Error(), volumeName("1.631.1")) {
		t.Fatalf("missing volume err=%v", err)
	}
	sizeRow := fixture.rows[0]
	volumes, _ := json.Marshal([]domain.PackageVolume{{Name: volumeName("1.631.1"), Size: 11, MD5: md5Hex([]byte("volume")), SHA256: servingSHA}})
	sizeRow.PackageFiles = volumes
	sizeRow.TotalSize = 11
	shorterReleases, err := domain.ParseReleases([]domain.RawRelease{sizeRow})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(missing, bytes.Repeat([]byte("v"), 12), 0o644); err != nil {
		t.Fatal(err)
	}
	err = VerifyActiveVolumes(shorterReleases, fixture.root)
	if err == nil || !strings.Contains(err.Error(), "registered 11") {
		t.Fatalf("size mismatch err=%v", err)
	}
}
