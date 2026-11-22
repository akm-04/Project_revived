package otabuild

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
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

const (
	realAgreeLine        = "\tvar_89_2:getChildByName(\"agree_btn\"):getChildByName(\"agree_text\"):setString(var_0_1:translation(\"AGREE\"))"
	realRefuseLine       = "\tvar_89_2:getChildByName(\"refuse_btn\"):getChildByName(\"refuse_text\"):setString(var_0_1:translation(\"REFUSE\"))"
	realDrinkLine        = "\tcc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.DRINK_NOTIF, handler(arg_2_0, arg_2_0.updateGuildNotif))"
	realGuildDotListener = "\tcc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.LEAGUE_CHAT_SESSION_CLOSED, function()\n" +
		"\t\targ_2_0.guild:loadSelfGuild(function()\n" +
		"\t\t\targ_2_0:updateGuildNotif(nil)\n" +
		"\t\tend)\n" +
		"\tend)"

	realCloseLeagueRoomStock = "function var_0_1.closeLeagueRoom(arg_6_0)\n" +
		"\tif arg_6_0.leagueSocket_ ~= nil then\n" +
		"\t\targ_6_0.leagueSocket_:close()\n" +
		"\n" +
		"\t\targ_6_0.leagueSocket_ = nil\n" +
		"\t\targ_6_0.leagueChatRoomID_ = nil\n" +
		"\n" +
		"\t\treturn\n" +
		"\tend\n" +
		"end"
	realCloseLeagueRoomPatched = "function var_0_1.closeLeagueRoom(arg_6_0)\n" +
		"\tif arg_6_0.leagueSocket_ ~= nil then\n" +
		"\t\targ_6_0.leagueSocket_:close()\n" +
		"\t\targ_6_0.leagueSocket_ = nil\n" +
		"\tend\n" +
		"\targ_6_0.leagueChatRoomID_ = nil\n" +
		"end"

	realLeagueRetryStock = "\t\telse\n" +
		"\t\t\tprint(\"enter league error\")\n" +
		"\t\t\tvar_0_0.performWithDelayGlobal(function()\n" +
		"\t\t\t\targ_9_0:enterLeagueRoom()\n" +
		"\t\t\tend, var_0_5)\n" +
		"\t\tend"
	realLeagueRetryPatched = "\t\telse\n" +
		"\t\t\tprint(\"enter league error\")\n" +
		"\t\t\tif arg_10_1 and arg_10_1.error_code and arg_10_1.error_code ~= 35033 then\n" +
		"\t\t\t\targ_9_0:closeLeagueRoom()\n" +
		"\t\t\t\treturn\n" +
		"\t\t\tend\n" +
		"\t\t\tvar_0_0.performWithDelayGlobal(function()\n" +
		"\t\t\t\targ_9_0:enterLeagueRoom()\n" +
		"\t\t\tend, var_0_5)\n" +
		"\t\tend"
)

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

func realStockExpected(t *testing.T) map[string]string {
	t.Helper()
	readStock := func(clientPath string) string {
		content, err := os.ReadFile(filepath.Join(realDecompiledStockSource, filepath.FromSlash(clientPath)))
		if err != nil {
			t.Fatalf("read stock %s: %v", clientPath, err)
		}
		return normalizeNewlines(content)
	}
	social := replaceOnce(t, readStock("app/windows/SocialSystemWindow.lua"), realAgreeLine+"\n", "")
	social = replaceOnce(t, social, realRefuseLine+"\n", "")
	bottom := replaceOnce(t, readStock("app/windows/MainSceneBottomWindow.lua"), realDrinkLine+"\n", realDrinkLine+"\n"+realGuildDotListener+"\n")
	selfPlayer := replaceOnce(t, readStock("app/model/SelfPlayer.lua"),
		"\targ_9_0.funcIDs = arg_9_1.params.func_ids\n",
		"\targ_9_0.funcIDs = arg_9_1.params.func_ids\n\n\targ_9_0:initABtest()\n\targ_9_0:getAbtestGroupByKey(xyd.tables.abtest:uniqueKey(xyd.Abtests.N7GSO))\n")
	lazyManagerOverlay, err := os.ReadFile(filepath.Join(realClientTree(), "patches", "lazy_marker_reconcile", "overlay.lua"))
	if err != nil {
		t.Fatalf("read the lazy_marker_reconcile overlay: %v", err)
	}
	lazyManager := replaceOnce(t, readStock("lazyFileManager.lua"),
		"\t\targ_1_0.changeCount = 0\n\tend,",
		normalizeNewlines(lazyManagerOverlay))
	return map[string]string{
		"app/windows/SocialSystemWindow.lua":    social,
		"app/windows/MainSceneBottomWindow.lua": bottom,
		"app/model/SelfPlayer.lua":              selfPlayer,
		"app/common/network/Backend.lua":        expectedBackendOutput(t, readStock("app/common/network/Backend.lua")),
		"lazyFileManager.lua":                   lazyManager,
	}
}

func expectedBackendOutput(t *testing.T, stock string) string {
	t.Helper()
	stock = replaceOnce(t, stock, realCloseLeagueRoomStock, realCloseLeagueRoomPatched)
	stock = replaceOnce(t, stock, realLeagueRetryStock, realLeagueRetryPatched)
	overlay, err := os.ReadFile(filepath.Join(realClientTree(), "patches", "backend_http_poll", "backend_http_poll_overlay.lua"))
	if err != nil {
		t.Fatalf("read the backend_http_poll overlay: %v", err)
	}
	block := strings.ReplaceAll(normalizeNewlines(overlay), "__GXB_HTTP_POLL__", "true")
	anchor := "\nreturn var_0_1"
	index := strings.LastIndex(stock, anchor)
	if index < 0 {
		t.Fatal("stock Backend.lua has no final return anchor")
	}
	return stock[:index] + "\n" + strings.TrimRight(block, "\n") + "\n\nreturn var_0_1" + stock[index+len(anchor):]
}

func replaceOnce(t *testing.T, content, old, replacement string) string {
	t.Helper()
	if count := strings.Count(content, old); count != 1 {
		t.Fatalf("stock text %q appears %d times, want once", old, count)
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
