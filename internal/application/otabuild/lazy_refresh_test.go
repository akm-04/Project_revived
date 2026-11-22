package otabuild

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"

	apprelease "gxb.local/backend/v2/internal/application/otarelease"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
)

type lazyRefreshCase struct {
	fixture *fixture
	input   Input
	resPath string
}

func newLazyRefreshCase(t *testing.T, rows []catalogRow, delivered []resSidecarEntry) lazyRefreshCase {
	t.Helper()
	fixture := newFixture(t)
	fixture.addSource(t, "app/example/Feature.lua", []byte("return {}\n"))
	fixture.addCatalog(t, rows)
	sidecarPath := filepath.Join(t.TempDir(), "active.zip.res.json")
	encoded, err := json.Marshal(resSidecarDocument{Entries: delivered})
	if err != nil {
		t.Fatal(err)
	}
	writeTestFile(t, sidecarPath, encoded)
	resPath := t.TempDir()
	input := fixture.input("1.631.2")
	input.LazyRefresh = true
	input.AssetsSidecar = sidecarPath
	input.ResPath = resPath
	return lazyRefreshCase{fixture: fixture, input: input, resPath: resPath}
}

func readLazyMap(t *testing.T, updatesDirectory string, request domain.BuildRequest) map[string]string {
	t.Helper()
	assembled := readAssembled(t, updatesDirectory, request)
	var lazyMap map[string]string
	if err := json.Unmarshal(zipEntry(t, assembled, lazyFileMember), &lazyMap); err != nil {
		t.Fatal(err)
	}
	return lazyMap
}

func sortedKeys(lazyMap map[string]string) []string {
	keys := make([]string, 0, len(lazyMap))
	for key := range lazyMap {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func readCodeSidecar(t *testing.T, updatesDirectory string, request domain.BuildRequest) map[string]resSidecarEntry {
	t.Helper()
	name := request.Version + "-" + request.SHA256[:12] + ".zip.res.json"
	content, err := os.ReadFile(filepath.Join(updatesDirectory, name))
	if err != nil {
		t.Fatalf("code res sidecar: %v", err)
	}
	var document resSidecarDocument
	if err := json.Unmarshal(content, &document); err != nil {
		t.Fatal(err)
	}
	rows := map[string]resSidecarEntry{}
	for _, row := range document.Entries {
		rows[row.Path] = row
	}
	return rows
}

// TestLazyRefreshKeepsOnlyUndeliveredCatalogueRows is OA-8 items 1-3: the code
// lazyFile.json carries a marker for every force=0 catalogue row the ACTIVE
// assets release did not deliver; a delivered row and a force=1 row never get
// one; a recovered undelivered row carries the recovered md5 and size.
func TestLazyRefreshKeepsOnlyUndeliveredCatalogueRows(t *testing.T) {
	deliveredContent := []byte("delivered")
	recoveredContent := []byte("recovered bytes with another md5")
	missingMD5 := strings.Repeat("b", 32)
	rows := []catalogRow{
		assetRow("res/web/images/delivered.png", md5Hex(deliveredContent), int64(len(deliveredContent))),
		assetRow("res/web/images/recovered.png", strings.Repeat("c", 32), 4),
		assetRow("res/web/images/missing.png", missingMD5, 7),
		{Path: "res/web/images/forced.png", MD5: strings.Repeat("d", 32), Size: 9, Force: 1},
	}
	delivered := []resSidecarEntry{
		{Path: "web/images/delivered.png", MD5: md5Hex(deliveredContent), Size: int64(len(deliveredContent))},
	}
	testCase := newLazyRefreshCase(t, rows, delivered)
	assetResFile(t, testCase.resPath, "web/images/delivered.png", deliveredContent)
	assetResFile(t, testCase.resPath, "web/images/recovered.png", recoveredContent)

	result := testCase.fixture.buildResult(t, testCase.input)
	lazyMap := readLazyMap(t, testCase.fixture.updates, result.Request)
	wantKeys := []string{
		"__lazy__res___web___images___missing.png",
		"__lazy__res___web___images___recovered.png",
	}
	if got := sortedKeys(lazyMap); strings.Join(got, ",") != strings.Join(wantKeys, ",") {
		t.Fatalf("lazy keys = %v, want %v", got, wantKeys)
	}
	if _, marked := lazyMap["__lazy__res___web___images___delivered.png"]; marked {
		t.Fatal("a delivered row kept a lazy marker")
	}
	if _, marked := lazyMap["__lazy__res___web___images___forced.png"]; marked {
		t.Fatal("a force=1 row got a lazy marker")
	}
	recoveredValue := lazyValueOf(t, lazyMap, "__lazy__res___web___images___recovered.png")
	if recoveredValue.Path != "res/web/images/recovered.png" || recoveredValue.MD5 != md5Hex(recoveredContent) || recoveredValue.Size != int64(len(recoveredContent)) {
		t.Fatalf("recovered lazy value = %+v", recoveredValue)
	}
	missingValue := lazyValueOf(t, lazyMap, "__lazy__res___web___images___missing.png")
	if missingValue.MD5 != missingMD5 || missingValue.Size != 7 {
		t.Fatalf("missing lazy value = %+v", missingValue)
	}

	sidecar := readCodeSidecar(t, testCase.fixture.updates, result.Request)
	if len(sidecar) != 2 {
		t.Fatalf("code sidecar rows = %v", sidecar)
	}
	if sidecar["web/images/recovered.png"].MD5 != md5Hex(recoveredContent) || sidecar["web/images/recovered.png"].Size != int64(len(recoveredContent)) {
		t.Fatalf("recovered sidecar row = %+v", sidecar["web/images/recovered.png"])
	}
	if sidecar["web/images/missing.png"].MD5 != missingMD5 || sidecar["web/images/missing.png"].Size != 7 {
		t.Fatalf("missing sidecar row = %+v", sidecar["web/images/missing.png"])
	}
	if _, shipped := sidecar["web/images/delivered.png"]; shipped {
		t.Fatal("a delivered row reached the code sidecar")
	}
	if result.Report.LazyConsidered != 3 || result.Report.LazySupplied != 1 || result.Report.LazyRetained != 2 {
		t.Fatalf("report = %+v", result.Report)
	}
}

// TestCodeReleaseServesRecoveredUndeliveredMarker is OA-8 item 4: the code
// release's /res index serves the recovered undelivered file at the marker md5.
func TestCodeReleaseServesRecoveredUndeliveredMarker(t *testing.T) {
	recoveredContent := []byte("recovered bytes")
	rows := []catalogRow{assetRow("res/web/images/recovered.png", strings.Repeat("c", 32), 4)}
	delivered := []resSidecarEntry{{Path: "web/images/delivered.png", MD5: strings.Repeat("d", 32), Size: 5}}
	testCase := newLazyRefreshCase(t, rows, delivered)
	assetResFile(t, testCase.resPath, "web/images/recovered.png", recoveredContent)

	result := testCase.fixture.buildResult(t, testCase.input)
	lazyValue := lazyValueOf(t, readLazyMap(t, testCase.fixture.updates, result.Request), "__lazy__res___web___images___recovered.png")
	if lazyValue.MD5 != md5Hex(recoveredContent) {
		t.Fatalf("marker md5 = %s, want %s", lazyValue.MD5, md5Hex(recoveredContent))
	}

	var volumes []domain.PackageVolume
	if err := json.Unmarshal(result.Request.PackageFiles, &volumes); err != nil {
		t.Fatal(err)
	}
	raw := domain.RawRelease{
		Version:      result.Request.Version,
		Lane:         result.Request.Lane,
		State:        string(domain.StateActive),
		PackageFiles: result.Request.PackageFiles,
		TotalSize:    result.Request.TotalSize,
		MD5:          result.Request.MD5,
		SHA256:       result.Request.SHA256,
		Manifest:     result.Request.Manifest,
	}
	settings := domain.DefaultSettings()
	settings.ResPath = testCase.resPath
	serving := &apprelease.Serving{
		Load:     func(context.Context) ([]domain.RawRelease, error) { return []domain.RawRelease{raw}, nil },
		Root:     filepath.Dir(filepath.Dir(testCase.fixture.updates)),
		Settings: apprelease.NewSettingsValue(settings),
	}
	if err := serving.Refresh(context.Background()); err != nil {
		t.Fatalf("refresh: %v", err)
	}
	file, _, _, found, err := serving.OpenResource(context.Background(), "recovered.png."+lazyValue.MD5)
	if err != nil || !found {
		t.Fatalf("the code release did not serve the recovered row: %v", err)
	}
	defer file.Close()
	content, err := io.ReadAll(file)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(content, recoveredContent) {
		t.Fatalf("served content = %q", content)
	}
}

// TestLazyRefreshRefusesUnusableDelivery is OA-8 item 3's fail-closed rule.
func TestLazyRefreshRefusesUnusableDelivery(t *testing.T) {
	delivered := []resSidecarEntry{{Path: "web/images/delivered.png", MD5: strings.Repeat("d", 32), Size: 5}}
	rows := []catalogRow{assetRow("res/web/images/delivered.png", strings.Repeat("d", 32), 5)}

	t.Run("missing catalogue", func(t *testing.T) {
		fixture := newFixture(t)
		fixture.addSource(t, "app/example/Feature.lua", []byte("return {}\n"))
		sidecarPath := filepath.Join(t.TempDir(), "active.zip.res.json")
		encoded, err := json.Marshal(resSidecarDocument{Entries: delivered})
		if err != nil {
			t.Fatal(err)
		}
		writeTestFile(t, sidecarPath, encoded)
		input := fixture.input("1.631.2")
		input.LazyRefresh = true
		input.AssetsSidecar = sidecarPath
		input.ResPath = t.TempDir()
		if _, err := Build(context.Background(), input); !errors.Is(err, ErrCatalogInvalid) {
			t.Fatalf("error = %v, want %v", err, ErrCatalogInvalid)
		}
	})

	t.Run("missing delivered sidecar", func(t *testing.T) {
		testCase := newLazyRefreshCase(t, rows, delivered)
		if err := os.Remove(testCase.input.AssetsSidecar); err != nil {
			t.Fatal(err)
		}
		if _, err := Build(context.Background(), testCase.input); !errors.Is(err, ErrNoExactAssets) {
			t.Fatalf("error = %v, want %v", err, ErrNoExactAssets)
		}
	})

	t.Run("empty delivered sidecar", func(t *testing.T) {
		testCase := newLazyRefreshCase(t, rows, nil)
		if _, err := Build(context.Background(), testCase.input); !errors.Is(err, ErrNoExactAssets) {
			t.Fatalf("error = %v, want %v", err, ErrNoExactAssets)
		}
	})

	t.Run("no undelivered row", func(t *testing.T) {
		testCase := newLazyRefreshCase(t, rows, delivered)
		if _, err := Build(context.Background(), testCase.input); !errors.Is(err, ErrCatalogInvalid) {
			t.Fatalf("error = %v, want %v", err, ErrCatalogInvalid)
		}
	})
}

// TestLazyRefreshReadsStockCatalog proves the agent's stock_catalog reaches the
// code-lane lazy refresh when the baseline carries no version.json.
func TestLazyRefreshReadsStockCatalog(t *testing.T) {
	missingMD5 := strings.Repeat("b", 32)
	rows := []catalogRow{assetRow("res/web/images/missing.png", missingMD5, 7)}
	delivered := []resSidecarEntry{{Path: "web/images/delivered.png", MD5: strings.Repeat("d", 32), Size: 5}}
	testCase := newLazyRefreshCase(t, nil, delivered)

	catalogDirectory := t.TempDir()
	encoded, err := json.Marshal(rows)
	if err != nil {
		t.Fatal(err)
	}
	for _, prefix := range []string{stockPrefix32, stockPrefix64} {
		writeTestFile(t, filepath.Join(catalogDirectory, filepath.FromSlash(prefix+"version.json")), encoded)
	}
	testCase.input.StockCatalog = catalogDirectory
	result := testCase.fixture.buildResult(t, testCase.input)
	lazyValue := lazyValueOf(t, readLazyMap(t, testCase.fixture.updates, result.Request), "__lazy__res___web___images___missing.png")
	if lazyValue.MD5 != missingMD5 || lazyValue.Size != 7 {
		t.Fatalf("lazy value = %+v", lazyValue)
	}
}
