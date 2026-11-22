package otabuild

import (
	"archive/zip"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/domain/otarelease"
)

const syntheticStockBackend = "local class = {}\n\nreturn var_0_1\n"

const syntheticOverlay = "local enabled = __GXB_HTTP_POLL__\n-- GXB_HTTP_POLL marker\n"

type fixture struct {
	baseline   string
	clientTree string
	updates    string
	staging    string
}

func newFixture(t *testing.T) *fixture {
	t.Helper()
	root := t.TempDir()
	fixture := &fixture{
		baseline:   filepath.Join(root, "baseline"),
		clientTree: filepath.Join(root, "client"),
		updates:    filepath.Join(root, "updates", "code"),
		staging:    filepath.Join(root, "staging"),
	}
	for _, directory := range []string{fixture.baseline, filepath.Join(fixture.clientTree, "src"), filepath.Join(fixture.clientTree, "patches")} {
		if err := os.MkdirAll(directory, 0o755); err != nil {
			t.Fatalf("create %s: %v", directory, err)
		}
	}
	return fixture
}

func (fixture *fixture) addStock(t *testing.T, clientPath string, content []byte) {
	t.Helper()
	for _, prefix := range []string{"assets/src_32/", "assets/src_64/"} {
		writeTestFile(t, filepath.Join(fixture.baseline, filepath.FromSlash(prefix+clientPath)), content)
	}
}

func (fixture *fixture) addSource(t *testing.T, clientPath string, content []byte) {
	t.Helper()
	writeTestFile(t, filepath.Join(fixture.clientTree, "src", filepath.FromSlash(clientPath)), content)
}

func (fixture *fixture) addPatch(t *testing.T, name, target string, stock []byte, definition map[string]any, overlay string) {
	t.Helper()
	directory := filepath.Join(fixture.clientTree, "patches", name)
	definition["target"] = target
	if _, pinned := definition["stock_sha256"]; !pinned {
		definition["stock_sha256"] = sha256Hex(stock)
	}
	writeTestFile(t, filepath.Join(directory, "overlay.lua"), []byte(overlay))
	encoded, err := json.Marshal(definition)
	if err != nil {
		t.Fatalf("encode patch definition: %v", err)
	}
	writeTestFile(t, filepath.Join(directory, "patch.json"), encoded)
}

func writeTestFile(t *testing.T, path string, content []byte) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("create directory for %s: %v", path, err)
	}
	if err := os.WriteFile(path, content, 0o644); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}

func (fixture *fixture) input(version string) Input {
	return Input{
		Lane:          "code",
		Version:       version,
		StockBaseline: fixture.baseline,
		ClientTree:    fixture.clientTree,
		UpdatesDir:    fixture.updates,
		StagingDir:    fixture.staging,
	}
}

func (fixture *fixture) build(t *testing.T, input Input) otarelease.BuildRequest {
	t.Helper()
	request, err := Build(context.Background(), input)
	if err != nil {
		t.Fatalf("Build: %v", err)
	}
	return request
}

func standardPatch() map[string]any {
	return map[string]any{
		"kind":          "insert_before_final_return",
		"anchor":        "return var_0_1",
		"insert":        "overlay.lua",
		"substitutions": map[string]string{"__GXB_HTTP_POLL__": "true"},
	}
}

func TestPatchInsertsBeforeFinalReturn(t *testing.T) {
	fixture := newFixture(t)
	stock := []byte(syntheticStockBackend)
	fixture.addStock(t, "app/common/network/Backend.lua", stock)
	fixture.addPatch(t, "backend_http_poll", "app/common/network/Backend.lua", stock, standardPatch(), syntheticOverlay)

	request := fixture.build(t, fixture.input("1.631.2"))
	assembled := readAssembled(t, fixture.updates, request)
	want := "local class = {}\n\nlocal enabled = true\n-- GXB_HTTP_POLL marker\n\nreturn var_0_1\n"
	for _, entry := range []string{"src_32/app/common/network/Backend.lua", "src_64/app/common/network/Backend.lua"} {
		if got := zipEntry(t, assembled, entry); string(got) != want {
			t.Fatalf("%s:\n got %q\nwant %q", entry, got, want)
		}
	}
	if len(packageVolumes(t, request)) == 0 {
		t.Fatal("no package volume")
	}
	if _, err := request.Release(); err != nil {
		t.Fatalf("row validation: %v", err)
	}
}

func TestPatchRefusals(t *testing.T) {
	missingAnchor := []byte("local class = {}\n")
	twiceAnchor := []byte("return var_0_1\nreturn var_0_1\n")
	cases := map[string]struct {
		stock      []byte
		definition func([]byte) map[string]any
		want       error
	}{
		"wrong stock hash": {syntheticStockBackendBytes(), func(stock []byte) map[string]any {
			definition := standardPatch()
			definition["stock_sha256"] = strings.Repeat("0", 64)
			return definition
		}, ErrStockHashMismatch},
		"unknown kind": {syntheticStockBackendBytes(), func(stock []byte) map[string]any {
			definition := standardPatch()
			definition["kind"] = "rewrite_everything"
			return definition
		}, ErrPatchKind},
		"unknown field": {syntheticStockBackendBytes(), func(stock []byte) map[string]any {
			definition := standardPatch()
			definition["script"] = "apply.py"
			return definition
		}, ErrInvalidPatch},
		"anchor missing": {missingAnchor, func(stock []byte) map[string]any {
			return standardPatch()
		}, ErrPatchAnchor},
		"anchor twice": {twiceAnchor, func(stock []byte) map[string]any {
			return standardPatch()
		}, ErrPatchAnchor},
	}
	for name, testCase := range cases {
		t.Run(name, func(t *testing.T) {
			fixture := newFixture(t)
			fixture.addStock(t, "app/common/network/Backend.lua", testCase.stock)
			fixture.addPatch(t, "backend_http_poll", "app/common/network/Backend.lua", testCase.stock, testCase.definition(testCase.stock), syntheticOverlay)
			_, err := Build(context.Background(), fixture.input("1.631.2"))
			if !errors.Is(err, testCase.want) {
				t.Fatalf("error = %v, want %v", err, testCase.want)
			}
			assertEmptyDirectory(t, fixture.staging)
		})
	}
}

func syntheticStockBackendBytes() []byte { return []byte(syntheticStockBackend) }

func TestAbiMismatchRefused(t *testing.T) {
	fixture := newFixture(t)
	stock := []byte(syntheticStockBackend)
	fixture.addStock(t, "app/common/network/Backend.lua", stock)
	writeTestFile(t, filepath.Join(fixture.baseline, "assets/src_32/app/common/network/Backend.lua"), []byte("different\n"))
	fixture.addPatch(t, "backend_http_poll", "app/common/network/Backend.lua", stock, standardPatch(), syntheticOverlay)

	_, err := Build(context.Background(), fixture.input("1.631.2"))
	if !errors.Is(err, ErrAbiMismatch) {
		t.Fatalf("error = %v, want %v", err, ErrAbiMismatch)
	}
}

func TestUpdateSceneRefused(t *testing.T) {
	for _, name := range []string{"UpdateScene.lua", "UpdateScene_64.lua"} {
		t.Run(name, func(t *testing.T) {
			fixture := newFixture(t)
			fixture.addSource(t, name, []byte("return true\n"))
			_, err := Build(context.Background(), fixture.input("1.631.2"))
			if !errors.Is(err, ErrUpdateSceneForbidden) {
				t.Fatalf("error = %v, want %v", err, ErrUpdateSceneForbidden)
			}
		})
	}
}

func TestOriginGuard(t *testing.T) {
	const origin = "https://engine.example/engine"
	misc := func(value string) []byte {
		return []byte("return {\n\tkeys = {\"key\",\"value\",\"parse\",\"desc\"},\n\trows = {\n\t\t{\n\t\t\t\"web_api_url\",\n\t\t\t\"" + value + "\",\n\t\t\t\"1\",\n\t\t\t\"NA\"\n\t\t}\n\t}\n}\n")
	}
	cases := map[string]struct {
		file    string
		content []byte
		origins map[string]string
		want    error
	}{
		"matching origin passes":       {"data/tables/misc.lua", misc(origin), map[string]string{"web_api_url": origin}, nil},
		"misc1 matching origin passes": {"data/tables/misc1.lua", misc(origin), map[string]string{"web_api_url": origin}, nil},
		"changed origin refused":       {"data/tables/misc.lua", misc("https://evil.example/engine"), map[string]string{"web_api_url": origin}, ErrOriginMismatch},
		"empty origins refused":        {"data/tables/misc.lua", misc(origin), map[string]string{}, ErrOriginsMissing},
		"missing origin row refused":   {"data/tables/misc.lua", []byte("return {\n\trows = {\n\t\t{\"other_key\", \"value\"}\n\t}\n}\n"), map[string]string{"web_api_url": origin}, ErrOriginMismatch},
	}
	for name, testCase := range cases {
		t.Run(name, func(t *testing.T) {
			fixture := newFixture(t)
			fixture.addSource(t, testCase.file, testCase.content)
			input := fixture.input("1.631.2")
			input.Origins = testCase.origins
			_, err := Build(context.Background(), input)
			if testCase.want == nil {
				if err != nil {
					t.Fatalf("Build: %v", err)
				}
				return
			}
			if !errors.Is(err, testCase.want) {
				t.Fatalf("error = %v, want %v", err, testCase.want)
			}
		})
	}
}

func TestDeterministicBuild(t *testing.T) {
	fixture := newFixture(t)
	fixture.addSource(t, "app/example/Feature.lua", []byte("return { value = 1 }\n"))
	first := fixture.build(t, fixture.input("1.631.2"))
	firstBytes := readAssembled(t, fixture.updates, first)
	fixture.updates = filepath.Join(t.TempDir(), "updates")
	second := fixture.build(t, fixture.input("1.631.3"))
	secondBytes := readAssembled(t, fixture.updates, second)

	if !bytes.Equal(firstBytes, secondBytes) {
		t.Fatal("two builds of the same input produced different bytes")
	}
	if first.MD5 != second.MD5 || first.SHA256 != second.SHA256 {
		t.Fatalf("digests differ: %s/%s vs %s/%s", first.MD5, first.SHA256, second.MD5, second.SHA256)
	}
}

func TestVolumeSplit(t *testing.T) {
	previousLimit := volumeByteLimit
	volumeByteLimit = 2048
	t.Cleanup(func() { volumeByteLimit = previousLimit })

	fixture := newFixture(t)
	large := make([]byte, 20000)
	state := uint32(2463534242)
	for index := range large {
		state ^= state << 13
		state ^= state >> 17
		state ^= state << 5
		large[index] = byte(state)
	}
	fixture.addSource(t, "app/example/Large.lua", large)
	request := fixture.build(t, fixture.input("1.631.2"))
	volumes := packageVolumes(t, request)

	if len(volumes) < 2 {
		t.Fatalf("volumes = %d, want a split", len(volumes))
	}
	var total int64
	for index, volume := range volumes {
		want := "1.631.2-" + request.SHA256[:12] + ".zip." + padVolume(index+1)
		if volume.Name != want {
			t.Fatalf("volume %d is %q, want %q", index, volume.Name, want)
		}
		if volume.Size <= 0 || volume.Size > volumeByteLimit {
			t.Fatalf("volume %d size %d is outside the cap", index, volume.Size)
		}
		if int64(float32(volume.Size)) != volume.Size {
			t.Fatalf("volume %d size %d is not float32-exact", index, volume.Size)
		}
		total += volume.Size
	}
	if total != request.TotalSize {
		t.Fatalf("volume sizes total %d, result %d", total, request.TotalSize)
	}
	assembled := readAssembled(t, fixture.updates, request)
	if got := md5Hex(assembled); got != request.MD5 {
		t.Fatalf("assembled md5 %s, result %s", got, request.MD5)
	}
	if got := sha256Hex(assembled); got != request.SHA256 {
		t.Fatalf("assembled sha256 %s, result %s", got, request.SHA256)
	}
	entries := zipEntries(t, assembled)
	if len(entries) != 2 {
		t.Fatalf("zip entries = %d, want 2", len(entries))
	}
}

func TestImmutability(t *testing.T) {
	fixture := newFixture(t)
	fixture.addSource(t, "app/example/Feature.lua", []byte("return { value = 1 }\n"))
	request := fixture.build(t, fixture.input("1.631.2"))
	assertEmptyDirectory(t, fixture.staging)

	existing := filepath.Join(fixture.updates, packageVolumes(t, request)[0].Name)
	before, err := os.ReadFile(existing)
	if err != nil {
		t.Fatalf("read existing artifact: %v", err)
	}
	if _, err := Build(context.Background(), fixture.input("1.631.2")); !errors.Is(err, ErrTargetExists) {
		t.Fatalf("rebuild error = %v, want %v", err, ErrTargetExists)
	}
	after, err := os.ReadFile(existing)
	if err != nil {
		t.Fatalf("read existing artifact: %v", err)
	}
	if !bytes.Equal(before, after) {
		t.Fatal("a refused build changed the existing artifact")
	}
	assertEmptyDirectory(t, fixture.staging)
}

func TestRefusedBuildLeavesStagingEmpty(t *testing.T) {
	fixture := newFixture(t)
	fixture.addSource(t, "UpdateScene.lua", []byte("return true\n"))
	if _, err := Build(context.Background(), fixture.input("1.631.2")); !errors.Is(err, ErrUpdateSceneForbidden) {
		t.Fatalf("error = %v, want %v", err, ErrUpdateSceneForbidden)
	}
	assertEmptyDirectory(t, fixture.staging)
}

func TestAssetsLaneRefused(t *testing.T) {
	fixture := newFixture(t)
	fixture.addSource(t, "app/example/Feature.lua", []byte("return {}\n"))
	input := fixture.input("1.631.1")
	input.Lane = "assets"
	if _, err := Build(context.Background(), input); !errors.Is(err, ErrAssetsLaneUnsupported) {
		t.Fatalf("error = %v, want %v", err, ErrAssetsLaneUnsupported)
	}
}

func TestEmptyPackageRefused(t *testing.T) {
	fixture := newFixture(t)
	if _, err := Build(context.Background(), fixture.input("1.631.2")); !errors.Is(err, ErrEmptyPackage) {
		t.Fatalf("error = %v, want %v", err, ErrEmptyPackage)
	}
}

func TestOptInStockBaselineGolden(t *testing.T) {
	baseline := os.Getenv("GXB_STOCK_BASELINE")
	if baseline == "" {
		t.Skip("GXB_STOCK_BASELINE not set")
	}
	golden, err := os.ReadFile(filepath.Join("testdata", "backend_http_poll_golden.lua"))
	if err != nil {
		t.Fatalf("read golden fixture: %v", err)
	}
	root := t.TempDir()
	request, err := Build(context.Background(), Input{
		Lane:          "code",
		Version:       "1.631.2",
		StockBaseline: baseline,
		ClientTree:    filepath.Join("..", "..", "..", "client", "ota"),
		UpdatesDir:    filepath.Join(root, "updates", "code"),
		StagingDir:    filepath.Join(root, "staging"),
	})
	if err != nil {
		t.Fatalf("Build: %v", err)
	}
	assembled := readAssembled(t, filepath.Join(root, "updates", "code"), request)
	for _, entry := range []string{"src_32/app/common/network/Backend.lua", "src_64/app/common/network/Backend.lua"} {
		if got := zipEntry(t, assembled, entry); !bytes.Equal(got, golden) {
			t.Fatalf("%s does not equal the golden fixture", entry)
		}
	}
}

func readAssembled(t *testing.T, updatesDirectory string, request otarelease.BuildRequest) []byte {
	t.Helper()
	volumes := packageVolumes(t, request)
	var assembled []byte
	for _, volume := range volumes {
		content, err := os.ReadFile(filepath.Join(updatesDirectory, volume.Name))
		if err != nil {
			t.Fatalf("read volume %s: %v", volume.Name, err)
		}
		if int64(len(content)) != volume.Size {
			t.Fatalf("volume %s is %d bytes, result says %d", volume.Name, len(content), volume.Size)
		}
		assembled = append(assembled, content...)
	}
	return assembled
}

func packageVolumes(t *testing.T, request otarelease.BuildRequest) []otarelease.PackageVolume {
	t.Helper()
	var volumes []otarelease.PackageVolume
	if err := json.Unmarshal(request.PackageFiles, &volumes); err != nil {
		t.Fatalf("decode package files: %v", err)
	}
	if len(volumes) == 0 {
		t.Fatal("result has no volume")
	}
	return volumes
}

func zipEntries(t *testing.T, assembled []byte) []*zip.File {
	t.Helper()
	reader, err := zip.NewReader(bytes.NewReader(assembled), int64(len(assembled)))
	if err != nil {
		t.Fatalf("open zip: %v", err)
	}
	return reader.File
}

func zipEntry(t *testing.T, assembled []byte, name string) []byte {
	t.Helper()
	for _, file := range zipEntries(t, assembled) {
		if file.Name != name {
			continue
		}
		reader, err := file.Open()
		if err != nil {
			t.Fatalf("open %s: %v", name, err)
		}
		defer reader.Close()
		var buffer bytes.Buffer
		if _, err := buffer.ReadFrom(reader); err != nil {
			t.Fatalf("read %s: %v", name, err)
		}
		return buffer.Bytes()
	}
	t.Fatalf("zip has no %s", name)
	return nil
}

func assertEmptyDirectory(t *testing.T, directory string) {
	t.Helper()
	entries, err := os.ReadDir(directory)
	if errors.Is(err, os.ErrNotExist) {
		return
	}
	if err != nil {
		t.Fatalf("read staging directory: %v", err)
	}
	if len(entries) != 0 {
		t.Fatalf("staging is not empty: %d entries", len(entries))
	}
}

func TestManifestSortedAndHashed(t *testing.T) {
	fixture := newFixture(t)
	fixture.addSource(t, "b.lua", []byte("return 'b'\n"))
	fixture.addSource(t, "a.lua", []byte("return 'a'\n"))
	request := fixture.build(t, fixture.input("1.631.2"))
	var document struct {
		Files []otarelease.ManifestEntry `json:"files"`
	}
	if err := json.Unmarshal(request.Manifest, &document); err != nil {
		t.Fatalf("decode manifest: %v", err)
	}
	contents := map[string]string{
		"src_32/a.lua": "return 'a'\n",
		"src_32/b.lua": "return 'b'\n",
		"src_64/a.lua": "return 'a'\n",
		"src_64/b.lua": "return 'b'\n",
	}
	paths := make([]string, len(document.Files))
	for index, entry := range document.Files {
		paths[index] = entry.Path
		content, known := contents[entry.Path]
		if !known {
			t.Fatalf("unexpected manifest path %q", entry.Path)
		}
		if entry.MD5 != md5Hex([]byte(content)) || entry.Size != int64(len(content)) {
			t.Fatalf("%s has an unexpected md5 or size", entry.Path)
		}
	}
	want := []string{"src_32/a.lua", "src_32/b.lua", "src_64/a.lua", "src_64/b.lua"}
	if strings.Join(paths, ",") != strings.Join(want, ",") {
		t.Fatalf("manifest paths = %v, want %v", paths, want)
	}
}

func TestPlanVolumeSizesProductionCap(t *testing.T) {
	sizes, err := planVolumeSizes(250_000_000, 99_000_000)
	if err != nil {
		t.Fatalf("planVolumeSizes: %v", err)
	}
	var total int64
	for _, size := range sizes {
		if size > 99_000_000 || !isFloat32Exact(size) {
			t.Fatalf("size %d violates the stock limits", size)
		}
		total += size
	}
	if total != 250_000_000 {
		t.Fatalf("total = %d", total)
	}
	if _, err := planVolumeSizes(maxTotalBytes+1, 99_000_000); !errors.Is(err, ErrVolumeLimit) {
		t.Fatalf("oversize total error = %v", err)
	}
}

func padVolume(number int) string {
	return fmt.Sprintf("%03d", number)
}
