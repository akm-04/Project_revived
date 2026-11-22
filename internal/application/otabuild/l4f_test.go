package otabuild

import (
	"archive/zip"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"sync"
	"testing"
)

// TestConcurrentBuildsKeepCommittedArtifacts runs two builds on one root; the
// lock serializes them and neither may roll back the other's committed files
// (L4f fix 1).
func TestConcurrentBuildsKeepCommittedArtifacts(t *testing.T) {
	fixture := newFixture(t)
	fixture.addSource(t, "app/example/Feature.lua", []byte("return { value = 1 }\n"))
	input := fixture.input("1.631.2")

	results := make([]Result, 2)
	errs := make([]error, 2)
	var wait sync.WaitGroup
	for index := range 2 {
		wait.Add(1)
		go func(slot int) {
			defer wait.Done()
			results[slot], errs[slot] = Build(context.Background(), input)
		}(index)
	}
	wait.Wait()
	for slot, err := range errs {
		if err != nil {
			t.Fatalf("build %d: %v", slot, err)
		}
	}
	if results[0].Request.SHA256 != results[1].Request.SHA256 {
		t.Fatal("the two builds produced different packages")
	}
	for _, volume := range packageVolumes(t, results[0].Request) {
		matches, err := fileMatches(filepath.Join(fixture.updates, volume.Name), volume.Size, volume.SHA256)
		if err != nil || !matches {
			t.Fatalf("committed volume %s was removed or changed: matches=%v err=%v", volume.Name, matches, err)
		}
	}
}

// TestAssetsUnsafeCatalogPathRefused refuses a catalogue row that would escape
// res/ before any file is collected (L4f fix 3).
func TestAssetsUnsafeCatalogPathRefused(t *testing.T) {
	fixture := newFixture(t)
	resPath := t.TempDir()
	fixture.addCatalog(t, []catalogRow{assetRow("res/web/../../escape.png", md5Hex([]byte("x")), 1)})
	if _, err := Build(context.Background(), fixture.assetsInput("1.631.1", resPath)); !errors.Is(err, ErrCatalogInvalid) {
		t.Fatalf("error = %v, want %v", err, ErrCatalogInvalid)
	}
}

// TestChangedFileRefusedWhileCopying proves the copy re-hashes the bytes it
// ships, so a file changed after collection cannot differ from its manifest
// (L4f fix 4).
func TestChangedFileRefusedWhileCopying(t *testing.T) {
	directory := t.TempDir()
	source := filepath.Join(directory, "asset.bin")
	if err := os.WriteFile(source, []byte("new bytes"), 0o644); err != nil {
		t.Fatal(err)
	}
	entry := packageEntry{path: "res/x.bin", source: source, size: 9, md5: md5Hex([]byte("old bytes"))}
	if _, err := writeAssembled(filepath.Join(directory, "package.zip"), []packageEntry{entry}, zip.Store); !errors.Is(err, ErrBuildIO) {
		t.Fatalf("error = %v, want %v", err, ErrBuildIO)
	}
}

// TestSplitBaselineBuilds builds the assets lane when the catalogue lives in a
// separate stock_catalog source (L4f fix 9).
func TestSplitBaselineBuilds(t *testing.T) {
	fixture := newFixture(t)
	resPath := t.TempDir()
	content := []byte("split catalogue asset")
	assetResFile(t, resPath, "web/images/x.png", content)

	catalog := t.TempDir()
	rows, err := json.Marshal([]catalogRow{assetRow("res/web/images/x.png", md5Hex(content), int64(len(content)))})
	if err != nil {
		t.Fatal(err)
	}
	for _, prefix := range []string{stockPrefix32, stockPrefix64} {
		writeTestFile(t, filepath.Join(catalog, filepath.FromSlash(prefix+"version.json")), rows)
	}

	input := fixture.assetsInput("1.631.1", resPath)
	input.StockCatalog = catalog
	result := fixture.buildResult(t, input)
	if result.Report.Exact != 1 {
		t.Fatalf("report = %+v", result.Report)
	}
	assembled := readAssembled(t, input.UpdatesDir, result.Request)
	if got := zipEntry(t, assembled, "res/images/x.png"); !bytes.Equal(got, content) {
		t.Fatal("the split catalogue asset was not shipped")
	}
}

// TestLazyRefreshRewritesCodeLazyMap proves a recovered file's current md5 and
// size reach the code lazyFile.json and its res sidecar while an unrecovered
// entry keeps its sidecar row (L4f silent lazy refresh).
func TestLazyRefreshRewritesCodeLazyMap(t *testing.T) {
	fixture := newFixture(t)
	fixture.addSource(t, "app/example/Feature.lua", []byte("return {}\n"))
	resPath := t.TempDir()
	recovered := []byte("recovered bytes with a new md5")
	assetResFile(t, resPath, "web/images/a.png", recovered)

	sidecarPath := filepath.Join(t.TempDir(), "active.zip.res.json")
	oldMD5 := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	sidecar := resSidecarDocument{Entries: []resSidecarEntry{
		{Path: "web/images/a.png", MD5: oldMD5, Size: 3},
		{Path: "web/images/b.png", MD5: oldMD5, Size: 7},
	}}
	encoded, err := json.Marshal(sidecar)
	if err != nil {
		t.Fatal(err)
	}
	writeTestFile(t, sidecarPath, encoded)

	input := fixture.input("1.631.2")
	input.LazyRefresh = true
	input.AssetsSidecar = sidecarPath
	input.ResPath = resPath
	result := fixture.buildResult(t, input)
	if result.Report.LazySupplied != 1 || result.Report.LazyRetained != 1 {
		t.Fatalf("report = %+v", result.Report)
	}

	assembled := readAssembled(t, fixture.updates, result.Request)
	var lazyMap map[string]string
	if err := json.Unmarshal(zipEntry(t, assembled, lazyFileMember), &lazyMap); err != nil {
		t.Fatal(err)
	}
	recoveredValue := lazyValueOf(t, lazyMap, "__lazy__res___web___images___a.png")
	if recoveredValue.Path != "res/web/images/a.png" || recoveredValue.MD5 != md5Hex(recovered) || recoveredValue.Size != int64(len(recovered)) {
		t.Fatalf("recovered lazy value = %+v", recoveredValue)
	}
	retainedValue := lazyValueOf(t, lazyMap, "__lazy__res___web___images___b.png")
	if retainedValue.MD5 != oldMD5 || retainedValue.Size != 7 {
		t.Fatalf("retained lazy value = %+v", retainedValue)
	}

	sidecarName := result.Request.Version + "-" + result.Request.SHA256[:12] + ".zip.res.json"
	sidecarBytes, err := os.ReadFile(filepath.Join(fixture.updates, sidecarName))
	if err != nil {
		t.Fatalf("code res sidecar: %v", err)
	}
	var document resSidecarDocument
	if err := json.Unmarshal(sidecarBytes, &document); err != nil {
		t.Fatal(err)
	}
	rows := map[string]resSidecarEntry{}
	for _, row := range document.Entries {
		rows[row.Path] = row
	}
	if rows["web/images/a.png"].MD5 != md5Hex(recovered) {
		t.Fatalf("sidecar recovered row = %+v", rows["web/images/a.png"])
	}
	if rows["web/images/b.png"].MD5 != oldMD5 {
		t.Fatalf("sidecar retained row = %+v", rows["web/images/b.png"])
	}
}

func lazyValueOf(t *testing.T, lazyMap map[string]string, key string) struct {
	Size int64  `json:"size"`
	MD5  string `json:"md5"`
	Path string `json:"path"`
} {
	t.Helper()
	raw, known := lazyMap[key]
	if !known {
		t.Fatalf("lazyFile.json has no %s: %v", key, lazyMap)
	}
	var value struct {
		Size int64  `json:"size"`
		MD5  string `json:"md5"`
		Path string `json:"path"`
	}
	if err := json.Unmarshal([]byte(raw), &value); err != nil {
		t.Fatalf("lazy value %q: %v", raw, err)
	}
	return value
}
