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
	fixture       *fixture
	input         Input
	recoveredPath string
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
	recoveredPath := t.TempDir()
	input := fixture.input("1.631.2")
	input.LazyRefresh = true
	input.AssetsSidecar = sidecarPath
	input.RecoveredResPath = recoveredPath
	return lazyRefreshCase{fixture: fixture, input: input, recoveredPath: recoveredPath}
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
	assetResFile(t, testCase.recoveredPath, "web/images/delivered.png", deliveredContent)
	assetResFile(t, testCase.recoveredPath, "web/images/recovered.png", recoveredContent)

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
	if result.Report.LazyConsidered != 3 || result.Report.LazySupplied != 1 || result.Report.LazyRetained != 2 || result.Report.LazyRecovered != 1 {
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
	assetResFile(t, testCase.recoveredPath, "web/images/recovered.png", recoveredContent)

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
	settings.RecoveredResPath = testCase.recoveredPath
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

// TestLazyRefreshRejectsCatalogueBackslashPath is A-220's full-Build
// regression: a backslash extra-catalogue row used to be normalized only after
// validation, so the ZIP committed a traversal lazy marker. The build must now
// refuse before any artifact is committed.
func TestLazyRefreshRejectsCatalogueBackslashPath(t *testing.T) {
	digest := strings.Repeat("a", 32)
	testCase := newLazyRefreshCase(t,
		[]catalogRow{assetRow("res/web/images/delivered.png", digest, 5)},
		[]resSidecarEntry{{Path: "web/images/delivered.png", MD5: digest, Size: 5}},
	)
	content := []byte("audit")
	name := `..\outside.ogg`
	if err := os.MkdirAll(filepath.Join(testCase.recoveredPath, "web"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(testCase.recoveredPath, "web", name), content, 0o600); err != nil {
		t.Fatal(err)
	}
	row := "path,md5,size\nres/web/" + name + "," + md5Hex(content) + ",5\n"
	if err := os.WriteFile(filepath.Join(testCase.recoveredPath, extraCatalogueFile), []byte(row), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := Build(context.Background(), testCase.input); !errors.Is(err, ErrCatalogInvalid) {
		t.Fatalf("Build accepted a malformed extra catalogue: %v", err)
	}
	if entries, err := os.ReadDir(testCase.fixture.updates); err == nil && len(entries) > 0 {
		t.Fatalf("a refused build committed updates: %v", entries)
	}
}

// TestLazyRefreshResolvesRecoveredOnlyUnderRecoveredResPath is OA-9 item 1: a
// file present only under res_path is not recovered, so its marker keeps the
// catalogue md5 and the report counts no recovered row.
func TestLazyRefreshResolvesRecoveredOnlyUnderRecoveredResPath(t *testing.T) {
	catalogMD5 := strings.Repeat("a", 32)
	rows := []catalogRow{assetRow("res/web/images/original.png", catalogMD5, 3)}
	delivered := []resSidecarEntry{{Path: "web/images/delivered.png", MD5: strings.Repeat("d", 32), Size: 5}}
	testCase := newLazyRefreshCase(t, rows, delivered)
	testCase.input.ResPath = t.TempDir()
	assetResFile(t, testCase.input.ResPath, "web/images/original.png", []byte("res_path bytes with another md5"))

	result := testCase.fixture.buildResult(t, testCase.input)
	if result.Report.LazyRecovered != 0 {
		t.Fatalf("a res_path file counted as recovered: %+v", result.Report)
	}
	lazyValue := lazyValueOf(t, readLazyMap(t, testCase.fixture.updates, result.Request), "__lazy__res___web___images___original.png")
	if lazyValue.MD5 != catalogMD5 || lazyValue.Size != 3 {
		t.Fatalf("lazy value = %+v, want the catalogue row", lazyValue)
	}
	sidecar := readCodeSidecar(t, testCase.fixture.updates, result.Request)
	if sidecar["web/images/original.png"].MD5 != catalogMD5 {
		t.Fatalf("code sidecar row = %+v", sidecar["web/images/original.png"])
	}
}

// TestLazyRefreshWithoutRecoveredResPathBuildsWithZeroRecovered is OA-9 item 3:
// an empty recovered_res_path still builds and reports recovered 0.
func TestLazyRefreshWithoutRecoveredResPathBuildsWithZeroRecovered(t *testing.T) {
	catalogMD5 := strings.Repeat("b", 32)
	rows := []catalogRow{assetRow("res/web/images/missing.png", catalogMD5, 7)}
	delivered := []resSidecarEntry{{Path: "web/images/delivered.png", MD5: strings.Repeat("d", 32), Size: 5}}
	testCase := newLazyRefreshCase(t, rows, delivered)
	testCase.input.RecoveredResPath = ""

	result := testCase.fixture.buildResult(t, testCase.input)
	if result.Report.LazyRecovered != 0 || result.Report.LazyRetained != 1 {
		t.Fatalf("report = %+v", result.Report)
	}
	lazyValue := lazyValueOf(t, readLazyMap(t, testCase.fixture.updates, result.Request), "__lazy__res___web___images___missing.png")
	if lazyValue.MD5 != catalogMD5 || lazyValue.Size != 7 {
		t.Fatalf("lazy value = %+v", lazyValue)
	}
}

// TestLazyRefreshRefusesMissingRecoveredResPath is OA-9 item 3: a set but
// unusable recovered_res_path is a typed refusal, not a silent empty recovery.
func TestLazyRefreshRefusesMissingRecoveredResPath(t *testing.T) {
	rows := []catalogRow{assetRow("res/web/images/missing.png", strings.Repeat("b", 32), 7)}
	delivered := []resSidecarEntry{{Path: "web/images/delivered.png", MD5: strings.Repeat("d", 32), Size: 5}}
	testCase := newLazyRefreshCase(t, rows, delivered)
	testCase.input.RecoveredResPath = filepath.Join(t.TempDir(), "missing")
	if _, err := Build(context.Background(), testCase.input); !errors.Is(err, ErrRecoveredResPathMissing) {
		t.Fatalf("error = %v, want %v", err, ErrRecoveredResPathMissing)
	}
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

// TestLazyRefreshShipsRefreshedCatalogue is the silent-patch route for a
// recovered file whose bytes differ from the stock catalogue: the client builds
// every lazy URL from version.json and verifies the download against it, so the
// release must carry the recovered md5 and size in both ABI copies.
func TestLazyRefreshShipsRefreshedCatalogue(t *testing.T) {
	recoveredContent := []byte("recovered bytes")
	recoveredPath := "res/web/windows/awake_hero_wnd/awake_hero.csb"
	untouchedMD5 := strings.Repeat("b", 32)
	rows := []catalogRow{
		assetRow(recoveredPath, strings.Repeat("a", 32), 856),
		assetRow("res/web/images/keep.png", untouchedMD5, 7),
		{Path: "src_64/app/example/Feature.lua", MD5: strings.Repeat("e", 32), Size: 12, Force: 1},
	}
	delivered := []resSidecarEntry{{Path: "web/images/delivered.png", MD5: strings.Repeat("d", 32), Size: 5}}
	testCase := newLazyRefreshCase(t, rows, delivered)
	assetResFile(t, testCase.recoveredPath, "web/windows/awake_hero_wnd/awake_hero.csb", recoveredContent)

	result := testCase.fixture.buildResult(t, testCase.input)
	assembled := readAssembled(t, testCase.fixture.updates, result.Request)

	seen := map[string][]catalogRow{}
	for _, prefix := range []string{"src_32/", "src_64/"} {
		var catalog []catalogRow
		if err := json.Unmarshal(zipEntry(t, assembled, prefix+catalogMember), &catalog); err != nil {
			t.Fatalf("%s%s: %v", prefix, catalogMember, err)
		}
		seen[prefix] = catalog
	}

	if !bytes.Equal(zipEntry(t, assembled, "src_32/"+catalogMember), zipEntry(t, assembled, "src_64/"+catalogMember)) {
		t.Fatal("the two ABI catalogues differ")
	}

	byPath := map[string]catalogRow{}
	for _, row := range seen["src_64/"] {
		byPath[row.Path] = row
	}
	recovered, found := byPath[recoveredPath]
	if !found {
		t.Fatalf("%s is missing from the shipped catalogue", recoveredPath)
	}
	if recovered.MD5 != md5Hex(recoveredContent) || recovered.Size != int64(len(recoveredContent)) {
		t.Fatalf("recovered row = %s/%d, want %s/%d", recovered.MD5, recovered.Size, md5Hex(recoveredContent), len(recoveredContent))
	}
	untouched, found := byPath["res/web/images/keep.png"]
	if !found || untouched.MD5 != untouchedMD5 || untouched.Size != 7 {
		t.Fatalf("untouched row = %+v", untouched)
	}
	forced, found := byPath["src_64/app/example/Feature.lua"]
	if !found || forced.Force != 1 || forced.MD5 != strings.Repeat("e", 32) {
		t.Fatalf("force row = %+v", forced)
	}

	lazyValue := lazyValueOf(t, readLazyMap(t, testCase.fixture.updates, result.Request),
		"__lazy__res___web___windows___awake_hero_wnd___awake_hero.csb")
	if lazyValue.MD5 != recovered.MD5 || lazyValue.Size != recovered.Size {
		t.Fatalf("lazy marker %s/%d does not match the catalogue %s/%d", lazyValue.MD5, lazyValue.Size, recovered.MD5, recovered.Size)
	}
}
