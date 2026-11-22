package otabuild

import (
	"archive/zip"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"testing"

	apprelease "gxb.local/backend/v2/internal/application/otarelease"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
)

func (fixture *fixture) addCatalog(t *testing.T, rows []catalogRow) {
	t.Helper()
	encoded, err := json.Marshal(rows)
	if err != nil {
		t.Fatalf("encode catalog: %v", err)
	}
	for _, prefix := range []string{stockPrefix32, stockPrefix64} {
		writeTestFile(t, filepath.Join(fixture.baseline, filepath.FromSlash(prefix+"version.json")), encoded)
	}
}

func (fixture *fixture) assetsInput(version, resPath string) Input {
	input := fixture.input(version)
	input.Lane = "assets"
	input.UpdatesDir = filepath.Join(filepath.Dir(fixture.updates), "assets")
	input.ResPath = resPath
	return input
}

func assetRow(catalogPath, md5 string, size int64) catalogRow {
	return catalogRow{Path: catalogPath, MD5: md5, Size: size, Force: 0}
}

func assetResFile(t *testing.T, resPath, relative string, content []byte) {
	t.Helper()
	writeTestFile(t, filepath.Join(resPath, filepath.FromSlash(relative)), content)
}

func TestAssetsExactMismatchAndMissing(t *testing.T) {
	fixture := newFixture(t)
	resPath := t.TempDir()
	exact := []byte("exact asset bytes")
	mismatched := []byte("wrong asset bytes")
	assetResFile(t, resPath, "res/web/images/exact.png", exact)
	assetResFile(t, resPath, "res/web/images/mismatch.png", mismatched)
	rows := []catalogRow{
		assetRow("res/web/images/exact.png", md5Hex(exact), int64(len(exact))),
		assetRow("res/web/images/mismatch.png", md5Hex([]byte("expected bytes")), int64(len(mismatched))),
		assetRow("res/web/images/missing.png", md5Hex([]byte("missing bytes")), 13),
	}
	fixture.addCatalog(t, rows)

	result := fixture.buildResult(t, fixture.assetsInput("1.631.1", resPath))
	if result.Report.Considered != 3 || result.Report.Exact != 1 || result.Report.Missing != 1 || result.Report.Mismatching != 1 {
		t.Fatalf("report = %+v", result.Report)
	}
	if result.Report.Considered != result.Report.Exact+result.Report.Missing+result.Report.Mismatching {
		t.Fatalf("collection counts do not add up: %+v", result.Report)
	}
	if result.Report.LazySupplied+result.Report.LazyRetained != result.Report.LazyConsidered {
		t.Fatalf("lazy counts do not add up: %+v", result.Report)
	}
	if result.Report.PhysicalBytes != int64(len(exact)) {
		t.Fatalf("physical bytes = %d", result.Report.PhysicalBytes)
	}
	assembled := readAssembled(t, fixture.assetsInput("1.631.1", resPath).UpdatesDir, result.Request)
	for _, file := range zipEntries(t, assembled) {
		if file.Method != zip.Store {
			t.Fatalf("%s is not stored", file.Name)
		}
	}
	if got := zipEntry(t, assembled, "res/images/exact.png"); !bytes.Equal(got, exact) {
		t.Fatal("exact asset was not shipped at its writable alias")
	}
	for _, file := range zipEntries(t, assembled) {
		if file.Name == "res/images/mismatch.png" {
			t.Fatal("a mismatching file was shipped")
		}
	}
}

func TestAssetsEveryCandidateForm(t *testing.T) {
	fixture := newFixture(t)
	resPath := t.TempDir()
	cases := map[string]string{
		"a.png": "res/web/images/a.png",
		"b.png": "web/images/b.png",
		"c.png": "res/images/c.png",
		"d.png": "images/d.png",
	}
	rows := make([]catalogRow, 0, len(cases))
	for name, relative := range cases {
		content := []byte("asset " + name)
		assetResFile(t, resPath, relative, content)
		rows = append(rows, assetRow("res/web/images/"+name, md5Hex(content), int64(len(content))))
	}
	fixture.addCatalog(t, rows)

	result := fixture.buildResult(t, fixture.assetsInput("1.631.1", resPath))
	if result.Report.Exact != len(cases) {
		t.Fatalf("report = %+v", result.Report)
	}
	input := fixture.assetsInput("1.631.1", resPath)
	assembled := readAssembled(t, input.UpdatesDir, result.Request)
	for name := range cases {
		if got := zipEntry(t, assembled, "res/images/"+name); !bytes.Equal(got, []byte("asset "+name)) {
			t.Fatalf("%s was not found through its candidate form", name)
		}
	}
}

func TestAssetsCollisionRefused(t *testing.T) {
	fixture := newFixture(t)
	resPath := t.TempDir()
	content := []byte("asset")
	assetResFile(t, resPath, "res/web/images/one.png", content)
	rows := []catalogRow{
		assetRow("res/web/images/one.png", md5Hex(content), int64(len(content))),
		assetRow("res/web/images/one.png", md5Hex(content), int64(len(content))),
	}
	fixture.addCatalog(t, rows)
	if _, err := Build(context.Background(), fixture.assetsInput("1.631.1", resPath)); !errors.Is(err, ErrAssetCollision) {
		t.Fatalf("error = %v, want %v", err, ErrAssetCollision)
	}
}

func TestAssetsSrc32DifferenceRefused(t *testing.T) {
	fixture := newFixture(t)
	resPath := t.TempDir()
	content := []byte("asset")
	assetResFile(t, resPath, "res/web/images/one.png", content)
	fixture.addCatalog(t, []catalogRow{assetRow("res/web/images/one.png", md5Hex(content), int64(len(content)))})
	writeTestFile(t, filepath.Join(fixture.baseline, filepath.FromSlash(stockPrefix32+"version.json")), []byte("[]"))

	if _, err := Build(context.Background(), fixture.assetsInput("1.631.1", resPath)); !errors.Is(err, ErrAbiMismatch) {
		t.Fatalf("error = %v, want %v", err, ErrAbiMismatch)
	}
}

func TestAssetsZeroExactRefused(t *testing.T) {
	fixture := newFixture(t)
	resPath := t.TempDir()
	fixture.addCatalog(t, []catalogRow{assetRow("res/web/images/missing.png", md5Hex([]byte("x")), 1)})
	if _, err := Build(context.Background(), fixture.assetsInput("1.631.1", resPath)); !errors.Is(err, ErrNoExactAssets) {
		t.Fatalf("error = %v, want %v", err, ErrNoExactAssets)
	}
}

func TestAssetsLazyMapGolden(t *testing.T) {
	fixture := newFixture(t)
	resPath := t.TempDir()
	supplied := []byte("supplied")
	assetResFile(t, resPath, "res/web/d.png", supplied)
	rows := []catalogRow{
		{Path: "res/web/a.png", MD5: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", Size: 1, Force: 1},
		{Path: "res/web/b.png", MD5: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", Size: 10, Force: 0},
		{Path: "res/web/c.png", MD5: "cccccccccccccccccccccccccccccccc", Size: 20, Force: 0, Version: json.RawMessage("7")},
		{Path: "res/web/d.png", MD5: md5Hex(supplied), Size: int64(len(supplied)), Force: 0},
		{Path: "data/foo.lua", MD5: "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", Size: 40, Force: 0},
		{Path: "", MD5: "ffffffffffffffffffffffffffffffff", Size: 50, Force: 0},
		{Path: "res/web/e.png", MD5: "11111111111111111111111111111111", Size: 60, Force: 2},
		{Path: "res/web/f.png", MD5: "22222222222222222222222222222222", Size: 70, Force: 0, Version: json.RawMessage("null")},
		{Path: "res/web/g.png", MD5: "33333333333333333333333333333333", Size: 80, Force: 0, Version: json.RawMessage(`"v1"`)},
		{Path: `res/web/h\i.png`, MD5: "44444444444444444444444444444444", Size: 90, Force: 0},
		{Path: "res/web/j\u2028.png", MD5: "55555555555555555555555555555555", Size: 100, Force: 0},
	}
	fixture.addCatalog(t, rows)

	result := fixture.buildResult(t, fixture.assetsInput("1.631.1", resPath))
	assembled := readAssembled(t, fixture.assetsInput("1.631.1", resPath).UpdatesDir, result.Request)
	golden, err := os.ReadFile(filepath.Join("testdata", "lazy_map_golden.json"))
	if err != nil {
		t.Fatalf("read golden: %v", err)
	}
	if got := zipEntry(t, assembled, lazyFileMember); !bytes.Equal(got, golden) {
		t.Fatalf("lazyFile.json differs from the V1 golden:\n got %s\nwant %s", got, golden)
	}
	if result.Report.LazyConsidered != 9 || result.Report.LazySupplied != 1 || result.Report.LazyRetained != 8 {
		t.Fatalf("lazy report = %+v", result.Report)
	}
}

func TestAssetsSidecarReadByServingIndex(t *testing.T) {
	fixture := newFixture(t)
	resPath := t.TempDir()
	content := []byte("sidecar asset")
	assetResFile(t, resPath, "res/web/images/served.png", content)
	fixture.addCatalog(t, []catalogRow{assetRow("res/web/images/served.png", md5Hex(content), int64(len(content)))})

	updatesRoot := t.TempDir()
	input := fixture.assetsInput("1.631.1", resPath)
	input.UpdatesDir = filepath.Join(updatesRoot, "updates", "assets")
	input.StagingDir = filepath.Join(updatesRoot, "staging")
	result := fixture.buildResult(t, input)

	var volumes []domain.PackageVolume
	if err := json.Unmarshal(result.Request.PackageFiles, &volumes); err != nil {
		t.Fatalf("package files: %v", err)
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
	settings.ResPath = resPath
	serving := &apprelease.Serving{
		Load:     func(context.Context) ([]domain.RawRelease, error) { return []domain.RawRelease{raw}, nil },
		Root:     updatesRoot,
		Settings: apprelease.NewSettingsValue(settings),
	}
	if err := serving.Refresh(context.Background()); err != nil {
		t.Fatalf("refresh: %v", err)
	}
	url, err := serving.ResDownloadURL(context.Background())
	if err != nil || url == "" {
		t.Fatalf("res index was not read by the serving loader: %q %v", url, err)
	}
	file, _, _, ok, err := serving.OpenResource(context.Background(), "served.png."+md5Hex(content))
	if err != nil || !ok {
		t.Fatalf("the sidecar did not serve its asset: %v", err)
	}
	file.Close()
}

func TestAssetsDeterministicAndIdempotent(t *testing.T) {
	fixture := newFixture(t)
	resPath := t.TempDir()
	content := []byte("deterministic asset")
	assetResFile(t, resPath, "res/web/images/one.png", content)
	fixture.addCatalog(t, []catalogRow{assetRow("res/web/images/one.png", md5Hex(content), int64(len(content)))})

	first := fixture.buildResult(t, fixture.assetsInput("1.631.1", resPath))
	firstBytes := readAssembled(t, fixture.assetsInput("1.631.1", resPath).UpdatesDir, first.Request)

	secondRoot := t.TempDir()
	secondInput := fixture.assetsInput("1.631.1", resPath)
	secondInput.UpdatesDir = filepath.Join(secondRoot, "updates", "assets")
	secondInput.StagingDir = filepath.Join(secondRoot, "staging")
	second := fixture.buildResult(t, secondInput)
	if !bytes.Equal(firstBytes, readAssembled(t, secondInput.UpdatesDir, second.Request)) {
		t.Fatal("two asset builds of the same input produced different bytes")
	}

	fixture.buildResult(t, fixture.assetsInput("1.631.1", resPath))
	sidecarName := first.Request.Version + "-" + first.Request.SHA256[:12] + ".zip.res.json"
	sidecarPath := filepath.Join(fixture.assetsInput("1.631.1", resPath).UpdatesDir, sidecarName)
	if _, err := os.Stat(sidecarPath); err != nil {
		t.Fatalf("res sidecar: %v", err)
	}
	if err := os.WriteFile(sidecarPath, []byte("different\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if _, err := Build(context.Background(), fixture.assetsInput("1.631.1", resPath)); !errors.Is(err, ErrTargetExists) {
		t.Fatalf("a changed sidecar was not refused: %v", err)
	}
}
