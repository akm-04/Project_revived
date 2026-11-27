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
	baseline    string
	stockSource string
	clientTree  string
	updates     string
	staging     string
}

func newFixture(t *testing.T) *fixture {
	t.Helper()
	root := t.TempDir()
	fixture := &fixture{
		baseline:    filepath.Join(root, "baseline"),
		stockSource: filepath.Join(root, "stock"),
		clientTree:  filepath.Join(root, "client"),
		updates:     filepath.Join(root, "updates", "code"),
		staging:     filepath.Join(root, "staging"),
	}
	for _, directory := range []string{fixture.baseline, fixture.stockSource, filepath.Join(fixture.clientTree, "src"), filepath.Join(fixture.clientTree, "patches")} {
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
	writeTestFile(t, filepath.Join(fixture.stockSource, filepath.FromSlash(clientPath)), content)
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
		StockSource:   fixture.stockSource,
		ClientTree:    fixture.clientTree,
		UpdatesDir:    fixture.updates,
		StagingDir:    fixture.staging,
	}
}

func (fixture *fixture) build(t *testing.T, input Input) otarelease.BuildRequest {
	t.Helper()
	return fixture.buildResult(t, input).Request
}

func (fixture *fixture) buildResult(t *testing.T, input Input) Result {
	t.Helper()
	result, err := Build(context.Background(), input)
	if err != nil {
		t.Fatalf("Build: %v", err)
	}
	return result
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

func TestPatchReadsDecompiledStockSource(t *testing.T) {
	fixture := newFixture(t)
	stock := []byte(syntheticStockBackend)
	fixture.addStock(t, "app/common/network/Backend.lua", stock)
	// The APK's ABI trees hold different LuaJIT bytecode; the patch pins the
	// decompiled source, so the build ignores them.
	writeTestFile(t, filepath.Join(fixture.baseline, "assets/src_32/app/common/network/Backend.lua"), []byte("\x1bLJ\x02bytecode-32"))
	writeTestFile(t, filepath.Join(fixture.baseline, "assets/src_64/app/common/network/Backend.lua"), []byte("\x1bLJ\x02bytecode-64"))
	fixture.addPatch(t, "backend_http_poll", "app/common/network/Backend.lua", stock, standardPatch(), syntheticOverlay)

	request := fixture.build(t, fixture.input("1.631.2"))
	assembled := readAssembled(t, fixture.updates, request)
	want := "local class = {}\n\nlocal enabled = true\n-- GXB_HTTP_POLL marker\n\nreturn var_0_1\n"
	for _, entry := range []string{"src_32/app/common/network/Backend.lua", "src_64/app/common/network/Backend.lua"} {
		if got := zipEntry(t, assembled, entry); string(got) != want {
			t.Fatalf("%s:\n got %q\nwant %q", entry, got, want)
		}
	}
}

func TestPatchRequiresStockSource(t *testing.T) {
	fixture := newFixture(t)
	stock := []byte(syntheticStockBackend)
	fixture.addStock(t, "app/common/network/Backend.lua", stock)
	fixture.addPatch(t, "backend_http_poll", "app/common/network/Backend.lua", stock, standardPatch(), syntheticOverlay)

	input := fixture.input("1.631.2")
	input.StockSource = ""
	if _, err := Build(context.Background(), input); !errors.Is(err, ErrInvalidInput) {
		t.Fatalf("error = %v, want %v", err, ErrInvalidInput)
	}
}

func TestPatchMissingStockSourceFileRefused(t *testing.T) {
	fixture := newFixture(t)
	stock := []byte(syntheticStockBackend)
	fixture.addStock(t, "app/common/network/Backend.lua", stock)
	fixture.addPatch(t, "backend_http_poll", "app/common/network/Backend.lua", stock, standardPatch(), syntheticOverlay)
	if err := os.Remove(filepath.Join(fixture.stockSource, "app", "common", "network", "Backend.lua")); err != nil {
		t.Fatal(err)
	}

	if _, err := Build(context.Background(), fixture.input("1.631.2")); err == nil {
		t.Fatal("a patch without its stock source file built")
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
	row := func(value string) string {
		return "{\"web_api_url\", \"" + value + "\"}"
	}
	evil := "https://evil.example/engine"
	cases := map[string]struct {
		file    string
		content []byte
		origins map[string]string
		want    error
	}{
		"matching origin passes":                  {"data/tables/misc.lua", misc(origin), map[string]string{"web_api_url": origin}, nil},
		"misc1 matching origin passes":            {"data/tables/misc1.lua", misc(origin), map[string]string{"web_api_url": origin}, nil},
		"changed origin refused":                  {"data/tables/misc.lua", misc("https://evil.example/engine"), map[string]string{"web_api_url": origin}, ErrOriginMismatch},
		"empty origins refused":                   {"data/tables/misc.lua", misc(origin), map[string]string{}, ErrOriginsMissing},
		"missing origin row refused":              {"data/tables/misc.lua", []byte("return {\n\trows = {\n\t\t{\"other_key\", \"value\"}\n\t}\n}\n"), map[string]string{"web_api_url": origin}, ErrOriginMismatch},
		"duplicate origin rows refused":           {"data/tables/misc.lua", []byte("return {\n\trows = {\n\t\t" + row(origin) + ",\n\t\t" + row(evil) + "\n\t}\n}\n"), map[string]string{"web_api_url": origin}, ErrOriginMismatch},
		"duplicate identical rows refused":        {"data/tables/misc.lua", []byte("return {\n\trows = {\n\t\t" + row(origin) + ",\n\t\t" + row(origin) + "\n\t}\n}\n"), map[string]string{"web_api_url": origin}, ErrOriginMismatch},
		"line-commented good row refused":         {"data/tables/misc.lua", []byte("return {\n\trows = {\n\t\t-- " + row(origin) + ",\n\t\t" + row(evil) + "\n\t}\n}\n"), map[string]string{"web_api_url": origin}, ErrOriginMismatch},
		"block-commented good row refused":        {"data/tables/misc.lua", []byte("return {\n\t--[[ " + row(origin) + " ]]\n\trows = {\n\t\t" + row(evil) + "\n\t}\n}\n"), map[string]string{"web_api_url": origin}, ErrOriginMismatch},
		"long-bracket commented good row refused": {"data/tables/misc.lua", []byte("return {\n\t--[==[ " + row(origin) + " ]==]\n\trows = {\n\t\t" + row(evil) + "\n\t}\n}\n"), map[string]string{"web_api_url": origin}, ErrOriginMismatch},
		"double dash inside a string passes":      {"data/tables/misc.lua", []byte("return {\n\trows = {\n\t\t" + row("https://good--example/engine") + "\n\t}\n}\n"), map[string]string{"web_api_url": "https://good--example/engine"}, nil},
		"case-folded carrier path passes":         {"Data/Tables/Misc.lua", misc(origin), map[string]string{"web_api_url": origin}, nil},
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
	const volumeByteLimit int64 = 2048

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
	input := fixture.input("1.631.2")
	input.VolumeByteLimit = volumeByteLimit
	request := fixture.build(t, input)
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
		onDisk, err := os.ReadFile(filepath.Join(fixture.updates, volume.Name))
		if err != nil {
			t.Fatalf("read volume %s: %v", volume.Name, err)
		}
		if int64(len(onDisk)) != volume.Size || md5Hex(onDisk) != volume.MD5 || sha256Hex(onDisk) != volume.SHA256 {
			t.Fatalf("volume %s hashes or size disagree with disk", volume.Name)
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

	rebuilt := fixture.build(t, fixture.input("1.631.2"))
	if rebuilt.SHA256 != request.SHA256 || rebuilt.MD5 != request.MD5 {
		t.Fatal("the identical retry produced another package")
	}

	existing := filepath.Join(fixture.updates, packageVolumes(t, request)[0].Name)
	before, err := os.ReadFile(existing)
	if err != nil {
		t.Fatalf("read existing artifact: %v", err)
	}
	tampered := append([]byte("x"), before[1:]...)
	if err := os.WriteFile(existing, tampered, 0o644); err != nil {
		t.Fatalf("tamper existing artifact: %v", err)
	}
	if _, err := Build(context.Background(), fixture.input("1.631.2")); !errors.Is(err, ErrTargetExists) {
		t.Fatalf("rebuild error = %v, want %v", err, ErrTargetExists)
	}
	after, err := os.ReadFile(existing)
	if err != nil {
		t.Fatalf("read existing artifact: %v", err)
	}
	if !bytes.Equal(after, tampered) {
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

func TestAssetsLaneRefusedWithoutResPath(t *testing.T) {
	fixture := newFixture(t)
	fixture.addSource(t, "app/example/Feature.lua", []byte("return {}\n"))
	input := fixture.input("1.631.1")
	input.Lane = "assets"
	if _, err := Build(context.Background(), input); !errors.Is(err, ErrResPathMissing) {
		t.Fatalf("error = %v, want %v", err, ErrResPathMissing)
	}
}

func TestEmptyPackageRefused(t *testing.T) {
	fixture := newFixture(t)
	if _, err := Build(context.Background(), fixture.input("1.631.2")); !errors.Is(err, ErrEmptyPackage) {
		t.Fatalf("error = %v, want %v", err, ErrEmptyPackage)
	}
}

func TestOptInStockBaselineGolden(t *testing.T) {
	stockSource := os.Getenv("GXB_STOCK_SOURCE")
	if stockSource == "" {
		t.Skip("GXB_STOCK_SOURCE not set")
	}
	const target = "app/common/network/Backend.lua"
	stock, err := os.ReadFile(filepath.Join(stockSource, filepath.FromSlash(target)))
	if err != nil {
		t.Fatalf("read stock Backend.lua: %v", err)
	}
	overlay, err := os.ReadFile(filepath.Join("..", "..", "..", "client", "ota", "patches", "backend_http_poll", "backend_http_poll_overlay.lua"))
	if err != nil {
		t.Fatalf("read the backend_http_poll overlay: %v", err)
	}
	golden, err := os.ReadFile(filepath.Join("testdata", "backend_http_poll_golden.lua"))
	if err != nil {
		t.Fatalf("read golden fixture: %v", err)
	}
	// One patch on its target must stay byte-identical to the retired generator;
	// the shipped tree chains the league patches after it.
	fixture := newFixture(t)
	fixture.addStock(t, target, stock)
	fixture.addPatch(t, "backend_http_poll", target, stock, standardPatch(), string(overlay))
	request := fixture.build(t, fixture.input("1.631.2"))
	assembled := readAssembled(t, fixture.updates, request)
	for _, entry := range []string{"src_32/" + target, "src_64/" + target} {
		if got := zipEntry(t, assembled, entry); !bytes.Equal(got, golden) {
			t.Fatalf("%s does not equal the golden fixture", entry)
		}
	}
}

// The pinned base APK's web_api_url; both stock carriers carry it.
const stockWebAPIURL = "http://203.74.199.17:9000/api/v1"

func TestOptInStockOriginCarrier(t *testing.T) {
	baseline := os.Getenv("GXB_STOCK_BASELINE")
	if baseline == "" {
		t.Skip("GXB_STOCK_BASELINE not set")
	}
	stock, closeStock, err := openBaseline(baseline)
	if err != nil {
		t.Fatalf("open baseline: %v", err)
	}
	defer closeStock()
	for _, name := range []string{"misc.lua", "misc1.lua"} {
		content, err := stock.read(stockPrefix64 + "data/tables/" + name)
		if err != nil {
			t.Fatalf("read %s: %v", name, err)
		}
		if err := checkOriginGuard(map[string][]byte{"data/tables/" + name: content}, map[string]string{"web_api_url": stockWebAPIURL}); err != nil {
			t.Fatalf("%s: %v", name, err)
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
	if _, err := planVolumeSizes(maxTotalBytes, 99_000_000); !errors.Is(err, ErrVolumeLimit) {
		t.Fatalf("total at 2^31-1 error = %v, want %v", err, ErrVolumeLimit)
	}
	if _, err := planVolumeSizes(maxTotalBytes+1, 99_000_000); !errors.Is(err, ErrVolumeLimit) {
		t.Fatalf("oversize total error = %v", err)
	}
	if _, err := planVolumeSizes(maxTotalBytes-1, 99_000_000); err != nil {
		t.Fatalf("total under 2^31-1 error = %v", err)
	}
}

func TestSameFilesystemHelper(t *testing.T) {
	root := t.TempDir()
	left := filepath.Join(root, "left")
	right := filepath.Join(root, "right")
	for _, directory := range []string{left, right} {
		if err := os.MkdirAll(directory, 0o755); err != nil {
			t.Fatalf("create %s: %v", directory, err)
		}
	}
	same, err := sameFilesystem(left, right)
	if err != nil {
		t.Fatalf("sameFilesystem: %v", err)
	}
	if !same {
		t.Fatal("two directories under one temp root are on different filesystems")
	}
}

func TestDifferentFilesystemsRefused(t *testing.T) {
	second, err := os.MkdirTemp("/dev/shm", "l4b-staging-")
	if err != nil {
		t.Skipf("no second filesystem available: %v", err)
	}
	t.Cleanup(func() { os.RemoveAll(second) })

	fixture := newFixture(t)
	fixture.addSource(t, "app/example/Feature.lua", []byte("return {}\n"))
	same, err := sameFilesystem(second, filepath.Dir(fixture.baseline))
	if err != nil {
		t.Fatalf("sameFilesystem: %v", err)
	}
	if same {
		t.Skip("the test host cannot make two filesystems")
	}
	input := fixture.input("1.631.2")
	input.StagingDir = second
	if _, err := Build(context.Background(), input); !errors.Is(err, ErrInvalidInput) {
		t.Fatalf("error = %v, want %v", err, ErrInvalidInput)
	}
}

func TestPatchSymlinkRefused(t *testing.T) {
	fixture := newFixture(t)
	stock := []byte(syntheticStockBackend)
	fixture.addStock(t, "app/common/network/Backend.lua", stock)
	fixture.addSource(t, "app/example/Feature.lua", []byte("return {}\n"))
	realPatch := filepath.Join(t.TempDir(), "real_patch")
	writeTestFile(t, filepath.Join(realPatch, "overlay.lua"), []byte("-- patched\n"))
	encoded, err := json.Marshal(standardPatch())
	if err != nil {
		t.Fatalf("encode patch definition: %v", err)
	}
	writeTestFile(t, filepath.Join(realPatch, "patch.json"), encoded)
	if err := os.Symlink(realPatch, filepath.Join(fixture.clientTree, "patches", "backend_http_poll")); err != nil {
		t.Skipf("symlinks unsupported: %v", err)
	}
	if _, err := Build(context.Background(), fixture.input("1.631.2")); !errors.Is(err, ErrInvalidPatch) {
		t.Fatalf("error = %v, want %v", err, ErrInvalidPatch)
	}
}

func TestPatchStrayFileRefused(t *testing.T) {
	fixture := newFixture(t)
	fixture.addSource(t, "app/example/Feature.lua", []byte("return {}\n"))
	writeTestFile(t, filepath.Join(fixture.clientTree, "patches", "notes.txt"), []byte("not a patch\n"))
	if _, err := Build(context.Background(), fixture.input("1.631.2")); !errors.Is(err, ErrInvalidPatch) {
		t.Fatalf("error = %v, want %v", err, ErrInvalidPatch)
	}
}

func TestPatchTrailingDataRefused(t *testing.T) {
	path := filepath.Join(t.TempDir(), "patch.json")
	document := map[string]any{
		"target":       "app/example/Feature.lua",
		"stock_sha256": strings.Repeat("0", 64),
		"kind":         "insert_before_final_return",
		"anchor":       "return var_0_1",
		"insert":       "overlay.lua",
	}
	encoded, err := json.Marshal(document)
	if err != nil {
		t.Fatalf("encode patch definition: %v", err)
	}
	encoded = append(encoded, []byte("\n{\"kind\":\"evil\"}")...)
	writeTestFile(t, path, encoded)
	if _, err := readPatchDefinition(path); !errors.Is(err, ErrInvalidPatch) {
		t.Fatalf("error = %v, want %v", err, ErrInvalidPatch)
	}
}

func TestCommitVolumesRollsBack(t *testing.T) {
	previousRename := renameFile
	t.Cleanup(func() { renameFile = previousRename })

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

	calls := 0
	renameFile = func(oldPath, newPath string) error {
		calls++
		if calls == 2 {
			return errors.New("injected rename failure")
		}
		return os.Rename(oldPath, newPath)
	}
	rollbackInput := fixture.input("1.631.2")
	rollbackInput.VolumeByteLimit = 2048
	if _, err := Build(context.Background(), rollbackInput); err == nil {
		t.Fatal("build succeeded despite the injected rename failure")
	}
	entries, err := os.ReadDir(fixture.updates)
	if err != nil {
		t.Fatalf("read updates: %v", err)
	}
	if len(entries) != 0 {
		t.Fatalf("a failed commit left %d entries behind", len(entries))
	}
	renameFile = os.Rename
	fixture.build(t, fixture.input("1.631.2"))
}

func TestInterruptedBuildCleaned(t *testing.T) {
	fixture := newFixture(t)
	fixture.addSource(t, "app/example/Feature.lua", []byte("return {}\n"))
	marker := "1.631.2-aaaaaaaaaaaa.incomplete"
	partial := "1.631.2-aaaaaaaaaaaa.zip.001"
	writeTestFile(t, filepath.Join(fixture.updates, marker), []byte(partial+"\n"))
	writeTestFile(t, filepath.Join(fixture.updates, partial), []byte("partial volume\n"))
	writeTestFile(t, filepath.Join(fixture.staging, "build-crashed", "package.zip"), []byte("scratch\n"))

	fixture.build(t, fixture.input("1.631.2"))
	for _, leftover := range []string{filepath.Join(fixture.updates, marker), filepath.Join(fixture.updates, partial)} {
		if _, err := os.Lstat(leftover); !errors.Is(err, os.ErrNotExist) {
			t.Fatalf("%s survived the startup sweep", leftover)
		}
	}
	assertEmptyDirectory(t, fixture.staging)
}

// TestRemovedPatchRestoresItsStockFile proves the revert set: a file the first
// release shipped through a patch is put back from stock once the patch is
// removed, because the client keeps files a later release does not contain.
func TestRemovedPatchRestoresItsStockFile(t *testing.T) {
	fixture := newFixture(t)
	stock := []byte(syntheticStockBackend)
	fixture.addStock(t, "app/common/network/Backend.lua", stock)
	fixture.addSource(t, "app/example/Feature.lua", []byte("return {}\n"))
	fixture.addPatch(t, "backend_http_poll", "app/common/network/Backend.lua", stock, standardPatch(), syntheticOverlay)

	first := fixture.build(t, fixture.input("1.631.2"))
	priorPaths := manifestPaths(t, first)
	if err := os.RemoveAll(filepath.Join(fixture.clientTree, "patches", "backend_http_poll")); err != nil {
		t.Fatal(err)
	}

	input := fixture.input("1.631.3")
	input.PriorPaths = priorPaths
	result := fixture.buildResult(t, input)
	assembled := readAssembled(t, fixture.updates, result.Request)
	for _, entry := range []string{"src_32/app/common/network/Backend.lua", "src_64/app/common/network/Backend.lua"} {
		if got := zipEntry(t, assembled, entry); !bytes.Equal(got, stock) {
			t.Fatalf("%s is not the stock file", entry)
		}
	}
	if result.Report.Reverted != 1 || !sampleContains(result.Report.RevertedSample, "app/common/network/Backend.lua") {
		t.Fatalf("report = %+v", result.Report)
	}
	if result.Report.Unrevertable != 0 {
		t.Fatalf("unrevertable = %v", result.Report.UnrevertableSample)
	}
}

// TestPriorPathWithoutStockIsReported proves a prior path our tree added (no
// stock file) is reported unrevertable and does not fail the build, while the
// generated lazy and catalog members are never treated as revertable.
func TestPriorPathWithoutStockIsReported(t *testing.T) {
	fixture := newFixture(t)
	fixture.addSource(t, "app/example/Feature.lua", []byte("return {}\n"))

	input := fixture.input("1.631.2")
	input.PriorPaths = []string{"src_64/app/generated/Added.lua", "lazyFile.json", "src_32/version.json"}
	result := fixture.buildResult(t, input)
	if result.Report.Unrevertable != 1 || !sampleContains(result.Report.UnrevertableSample, "app/generated/Added.lua") {
		t.Fatalf("report = %+v", result.Report)
	}
	if result.Report.Reverted != 0 {
		t.Fatalf("reverted = %v", result.Report.RevertedSample)
	}
}

func manifestPaths(t *testing.T, request otarelease.BuildRequest) []string {
	t.Helper()
	var document struct {
		Files []otarelease.ManifestEntry `json:"files"`
	}
	if err := json.Unmarshal(request.Manifest, &document); err != nil {
		t.Fatalf("decode manifest: %v", err)
	}
	paths := make([]string, len(document.Files))
	for index, entry := range document.Files {
		paths[index] = entry.Path
	}
	return paths
}

func sampleContains(paths []string, want string) bool {
	for _, path := range paths {
		if path == want {
			return true
		}
	}
	return false
}

func padVolume(number int) string {
	return fmt.Sprintf("%03d", number)
}
