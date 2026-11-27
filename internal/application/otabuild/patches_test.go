package otabuild

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

func replacePatch(anchor string) map[string]any {
	return map[string]any{
		"kind":   "replace_exact",
		"anchor": anchor,
		"insert": "overlay.lua",
	}
}

func TestReplaceExact(t *testing.T) {
	const target = "app/example/Feature.lua"
	const base = "local a = 1\nlocal keep = true\nreturn a\n"
	cases := map[string]struct {
		stock      string
		anchor     string
		overlay    string
		want       string
		wantError  error
		substitute bool
	}{
		"replaces once":  {stock: base, anchor: "local a = 1\n", overlay: "local a = 2\n", want: "local a = 2\nlocal keep = true\nreturn a\n"},
		"deletes":        {stock: base, anchor: "local a = 1\n", overlay: "", want: "local keep = true\nreturn a\n"},
		"anchor missing": {stock: base, anchor: "local b = 1\n", overlay: "local b = 2\n", wantError: ErrPatchAnchor},
		"anchor twice":   {stock: "local a = 1\nlocal a = 1\n", anchor: "local a = 1\n", overlay: "local a = 2\n", wantError: ErrPatchAnchor},
		"substitutes":    {stock: base, anchor: "local a = 1\n", overlay: "local a = __VALUE__\r\n", want: "local a = 2\nlocal keep = true\nreturn a\n", substitute: true},
		"keeps bom and normalizes crlf": {
			stock:   "\xef\xbb\xbflocal a = 1\r\nlocal keep = true\r\n",
			anchor:  "local a = 1\n",
			overlay: "local a = 2\r\n",
			want:    "\xef\xbb\xbflocal a = 2\nlocal keep = true\n",
		},
	}
	for name, testCase := range cases {
		t.Run(name, func(t *testing.T) {
			fixture := newFixture(t)
			stock := []byte(testCase.stock)
			fixture.addStock(t, target, stock)
			definition := replacePatch(testCase.anchor)
			if testCase.substitute {
				definition["substitutions"] = map[string]string{"__VALUE__": "2"}
			}
			fixture.addPatch(t, "feature_change", target, stock, definition, testCase.overlay)
			if testCase.wantError != nil {
				if _, err := Build(context.Background(), fixture.input("1.631.2")); !errors.Is(err, testCase.wantError) {
					t.Fatalf("error = %v, want %v", err, testCase.wantError)
				}
				return
			}
			request := fixture.build(t, fixture.input("1.631.2"))
			assembled := readAssembled(t, fixture.updates, request)
			if got := string(zipEntry(t, assembled, "src_64/"+target)); got != testCase.want {
				t.Fatalf("got %q, want %q", got, testCase.want)
			}
		})
	}
}

func TestEmptyOverlayOnlyForReplaceExact(t *testing.T) {
	fixture := newFixture(t)
	stock := []byte(syntheticStockBackend)
	fixture.addStock(t, "app/common/network/Backend.lua", stock)
	fixture.addPatch(t, "backend_http_poll", "app/common/network/Backend.lua", stock, standardPatch(), "")
	if _, err := Build(context.Background(), fixture.input("1.631.2")); !errors.Is(err, ErrInvalidPatch) {
		t.Fatalf("error = %v, want %v", err, ErrInvalidPatch)
	}
}

func TestPatchChainOrderAndStockPin(t *testing.T) {
	const target = "app/example/Feature.lua"
	const stockText = "local value = 1\nlocal keep = true\nreturn value\n"
	stock := []byte(stockText)

	t.Run("later patch applies to the previous output", func(t *testing.T) {
		fixture := newFixture(t)
		fixture.addStock(t, target, stock)
		fixture.addPatch(t, "a_first", target, stock, replacePatch("local value = 1\n"), "local value = 2\n")
		fixture.addPatch(t, "b_second", target, stock, replacePatch("local value = 2\n"), "local value = 3\n")

		request := fixture.build(t, fixture.input("1.631.2"))
		assembled := readAssembled(t, fixture.updates, request)
		want := "local value = 3\nlocal keep = true\nreturn value\n"
		if got := string(zipEntry(t, assembled, "src_64/"+target)); got != want {
			t.Fatalf("got %q, want %q", got, want)
		}
	})

	t.Run("a later patch alone cannot find its anchor", func(t *testing.T) {
		fixture := newFixture(t)
		fixture.addStock(t, target, stock)
		fixture.addPatch(t, "b_second", target, stock, replacePatch("local value = 2\n"), "local value = 3\n")

		if _, err := Build(context.Background(), fixture.input("1.631.2")); !errors.Is(err, ErrPatchAnchor) {
			t.Fatalf("error = %v, want %v", err, ErrPatchAnchor)
		}
	})

	t.Run("every patch pins the same stock sha256", func(t *testing.T) {
		fixture := newFixture(t)
		fixture.addStock(t, target, stock)
		fixture.addPatch(t, "a_first", target, stock, replacePatch("local value = 1\n"), "local value = 2\n")
		wrong := replacePatch("local value = 2\n")
		wrong["stock_sha256"] = strings.Repeat("0", 64)
		fixture.addPatch(t, "b_second", target, stock, wrong, "local value = 3\n")

		if _, err := Build(context.Background(), fixture.input("1.631.2")); !errors.Is(err, ErrStockHashMismatch) {
			t.Fatalf("error = %v, want %v", err, ErrStockHashMismatch)
		}
	})

	t.Run("a source file on a patched target is still a duplicate", func(t *testing.T) {
		fixture := newFixture(t)
		fixture.addStock(t, target, stock)
		fixture.addSource(t, target, []byte("return true\n"))
		fixture.addPatch(t, "a_first", target, stock, replacePatch("local value = 1\n"), "local value = 2\n")

		if _, err := Build(context.Background(), fixture.input("1.631.2")); !errors.Is(err, ErrDuplicatePath) {
			t.Fatalf("error = %v, want %v", err, ErrDuplicatePath)
		}
	})
}

// The decompiled stock tree the patch pins read (I11A_1_PLAN "L5 decisions").
const realDecompiledStockSource = "/home/akm/Chatgpt/EOL_Game/inputs/Recovered_assets/New_Client/Decompiled_Lua/src_64"

func realClientTree() string {
	return filepath.Join("..", "..", "..", "client", "ota")
}

func TestRealStockClientPatches(t *testing.T) {
	if _, err := os.Stat(realDecompiledStockSource); err != nil {
		t.Skipf("decompiled stock source absent: %s", realDecompiledStockSource)
	}
	root := t.TempDir()
	result, err := Build(context.Background(), Input{
		Lane:          "code",
		Version:       "1.631.2",
		StockBaseline: realDecompiledStockSource,
		StockSource:   realDecompiledStockSource,
		ClientTree:    realClientTree(),
		UpdatesDir:    filepath.Join(root, "updates", "code"),
		StagingDir:    filepath.Join(root, "staging"),
	})
	if err != nil {
		t.Fatalf("Build: %v", err)
	}
	updates := filepath.Join(root, "updates", "code")
	assembled := readAssembled(t, updates, result.Request)
	expected := realStockExpected(t)
	for target, want := range expected {
		for _, prefix := range []string{"src_32/", "src_64/"} {
			got := zipEntry(t, assembled, prefix+target)
			if string(got) != want {
				t.Fatalf("%s%s differs from stock with the intended hunk:\n%s", prefix, target, firstDifference(got, []byte(want)))
			}
		}
	}
	t.Run("parses with the bundled Lua 5.1 parser", func(t *testing.T) {
		parser := luaParserPath()
		if parser == "" {
			t.Skip("no Lua parser: set GXB_LUAJIT or provide .toolchain/bin/luajit")
		}
		for target := range expected {
			for _, prefix := range []string{"src_32/", "src_64/"} {
				path := filepath.Join(t.TempDir(), filepath.Base(target))
				writeTestFile(t, path, zipEntry(t, assembled, prefix+target))
				command := exec.Command(parser, "-joff", "-e", `assert(loadfile(os.getenv("GXB_LUA_PARSE_FILE")))`)
				command.Env = append(os.Environ(), "GXB_LUA_PARSE_FILE="+path)
				output, err := command.CombinedOutput()
				if err != nil {
					t.Fatalf("%s%s does not parse: %v\n%s", prefix, target, err, output)
				}
			}
		}
	})
}

// realStockExpected replays every patch directory the way collectPatches does:
// directory-name order, each patch applying to the previous output for its
// target. The hunks come from patch.json and the overlay files, so a new patch
// directory is covered without editing this test.
func realStockExpected(t *testing.T) map[string]string {
	t.Helper()
	patchesRoot := filepath.Join(realClientTree(), "patches")
	entries, err := os.ReadDir(patchesRoot)
	if err != nil {
		t.Fatalf("read patch directories: %v", err)
	}
	expected := make(map[string]string)
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		directory := filepath.Join(patchesRoot, entry.Name())
		definition, err := readPatchDefinition(filepath.Join(directory, "patch.json"))
		if err != nil {
			t.Fatalf("read %s patch.json: %v", entry.Name(), err)
		}
		base, seen := expected[definition.Target]
		if !seen {
			base = readRealStock(t, definition.Target)
		}
		overlay, err := os.ReadFile(filepath.Join(directory, filepath.FromSlash(definition.Insert)))
		if err != nil {
			t.Fatalf("read %s overlay: %v", entry.Name(), err)
		}
		overlayText := normalizeNewlines(overlay)
		for placeholder, replacement := range definition.Substitutions {
			overlayText = strings.ReplaceAll(overlayText, placeholder, replacement)
		}
		switch definition.Kind {
		case "replace_exact":
			base = replaceOnce(t, base, normalizeNewlines([]byte(definition.Anchor)), overlayText)
		case "insert_before_final_return":
			base = insertBeforeFinalReturnForTest(t, base, normalizeNewlines([]byte(definition.Anchor)), overlayText)
		default:
			t.Fatalf("%s has unhandled kind %q", entry.Name(), definition.Kind)
		}
		expected[definition.Target] = base
	}
	return expected
}

func readRealStock(t *testing.T, clientPath string) string {
	t.Helper()
	content, err := os.ReadFile(filepath.Join(realDecompiledStockSource, filepath.FromSlash(clientPath)))
	if err != nil {
		t.Fatalf("read stock %s: %v", clientPath, err)
	}
	return normalizeNewlines(content)
}

// insertBeforeFinalReturnForTest mirrors patches.go's whitespace handling: the
// overlay goes just before the single final anchor line, with its trailing
// newlines trimmed and a blank line between it and the anchor.
func insertBeforeFinalReturnForTest(t *testing.T, stock, anchor, overlay string) string {
	t.Helper()
	final := regexp.MustCompile(`(\r?\n)` + regexp.QuoteMeta(anchor) + `(\s*)\z`).FindStringSubmatchIndex(stock)
	if final == nil {
		t.Fatalf("stock has no final %q anchor", anchor)
	}
	leading := stock[final[2]:final[3]]
	trailing := stock[final[4]:final[5]]
	return stock[:final[2]] + leading + strings.TrimRight(overlay, "\n") + "\n\n" + anchor + trailing
}

func replaceOnce(t *testing.T, content, old, replacement string) string {
	t.Helper()
	if count := strings.Count(content, old); count != 1 {
		t.Fatalf("text %q appears %d times, want once", old, count)
	}
	return strings.Replace(content, old, replacement, 1)
}

func luaParserPath() string {
	if path := os.Getenv("GXB_LUAJIT"); path != "" {
		return path
	}
	candidate := filepath.Join("..", "..", "..", "..", "..", ".toolchain", "bin", "luajit")
	if info, err := os.Stat(candidate); err == nil && !info.IsDir() {
		return candidate
	}
	return ""
}

// firstDifference names the first differing line so a stock drift is readable.
func firstDifference(got, want []byte) string {
	gotLines := strings.Split(string(got), "\n")
	wantLines := strings.Split(string(want), "\n")
	for index := 0; index < len(gotLines) && index < len(wantLines); index++ {
		if gotLines[index] != wantLines[index] {
			return fmt.Sprintf("line %d:\n got %q\nwant %q", index+1, gotLines[index], wantLines[index])
		}
	}
	return fmt.Sprintf("line counts: got %d, want %d", len(gotLines), len(wantLines))
}
