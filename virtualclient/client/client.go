// Package client runs the unmodified stock src_64 Lua headless against a real backend (I85_HARNESS_BOUNDARY_V1).
package client

import (
	"bytes"
	"crypto/sha256"
	"database/sql"
	_ "embed"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"

	lua "github.com/yuin/gopher-lua"
)

// PinnedSourceDigest identifies the stock src_64 tree of APK 1.631.0 (work/client_baseline/base-apk-lua-decompiled-plaintext.zip):
// sha256 over the sorted "path\x00sha256(file)\n" lines of its 4370 files.
const PinnedSourceDigest = "5ad9ee3a4b51169e1a1d124168d675db91a960a30acd980c6f94bd28a415870e"

const (
	androidPlatform = 3
	versionName     = "1.631.0"
	packageName     = "com.carolgames.gxb"
	frameDelta      = time.Second / 30
)

//go:embed prelude.lua
var prelude string

// gopher-lua stores integer keys below MaxArrayIndex in the array part and pads it with nils up to the key, so stock tables keyed
// by item ids in the tens of millions (HeroTable id_to_egg_) would allocate gigabytes; LuaJIT hashes sparse keys. Stock sequences
// stay far below this bound.
func init() { lua.MaxArrayIndex = 1 << 17 }

// Options locate the stock inputs and the backend one run talks to.
type Options struct {
	SourceRoot string // stock src_64, checked against PinnedSourceDigest
	AssetRoot  string // APK assets directory holding res/
	DeviceRoot string // writable device storage for this virtual install (support, documents, databases)
	// BackendOrigin replaces the stock hard-coded origins, as the app_repack URL patch does on a rebuilt APK.
	BackendOrigin string
	SID           string
	LoginToken    string
	// RememberedRegion makes this a returning device: stock storage already holds the region the player chose before, so
	// LoginWindow skips the fresh-install region pick (H07: stock takes the fourth-newest region, an honest directory has two).
	RememberedRegion Region
	// UpdateTree is a gxb-asset-tree output: an updated client, its verified lazy assets already in the stock update directory.
	UpdateTree string
	Start      time.Time
	Log        io.Writer
}

// Report is the evidence one run leaves: what the stock client did and every native it reached that the harness does not implement.
type Report struct {
	SourceDigest string             `json:"source_digest"`
	VirtualTime  float64            `json:"virtual_seconds"`
	Scenes       []SceneEntry       `json:"scenes"`
	Requests     []Exchange         `json:"requests"`
	LuaErrors    []string           `json:"lua_errors"`
	Missing      map[string]float64 `json:"missing_natives"`
	Unreadable   []string           `json:"unreadable_files"`
	SDKCalls     []string           `json:"sdk_calls"`
	Exited       bool               `json:"exited"`
	Proxies      float64            `json:"proxies_created"`
}

type Region struct {
	ID   int
	Name string
}

type SceneEntry struct {
	Name string  `json:"name"`
	At   float64 `json:"at_virtual_seconds"`
}

type Client struct {
	options Options
	state   *lua.LState
	clock   time.Duration
	files   *fileSystem
	network *network
	frame   *lua.LFunction
	report  Report
}

func New(options Options) (*Client, error) {
	digest, err := SourceDigest(options.SourceRoot)
	if err != nil {
		return nil, err
	}
	if digest != PinnedSourceDigest {
		return nil, fmt.Errorf("src_64 at %s is not the pinned stock tree: %s", options.SourceRoot, digest)
	}
	if options.Log == nil {
		options.Log = io.Discard
	}
	if options.Start.IsZero() {
		options.Start = time.Now()
	}
	files, err := newFileSystem(options.AssetRoot, options.DeviceRoot)
	if err != nil {
		return nil, err
	}
	if options.UpdateTree != "" {
		if err := linkTree(options.UpdateTree, filepath.Join(files.deviceRoot, "support", packageName)); err != nil {
			return nil, fmt.Errorf("update tree: %w", err)
		}
	}
	if options.RememberedRegion.ID > 0 {
		if err := rememberRegion(filepath.Join(files.deviceRoot, "documents", "game.db"), options.SID, options.RememberedRegion); err != nil {
			return nil, err
		}
	}
	client := &Client{options: options, state: lua.NewState(), files: files, report: Report{SourceDigest: digest}}
	client.network = newNetwork(options.BackendOrigin, &client.report, func() float64 { return client.clock.Seconds() })
	if err := client.install(); err != nil {
		client.Close()
		return nil, err
	}
	return client, nil
}

func (client *Client) Close() {
	client.state.Close()
	client.files.close()
}

func (client *Client) now() time.Time {
	return client.options.Start.Add(client.clock)
}

func (client *Client) install() error {
	state := client.state
	state.SetGlobal("print", state.NewFunction(client.print))
	installClock(state, client.now)
	installBit(state)
	state.PreloadModule("cjson", loadJSON)
	state.PreloadModule("lsqlite3", client.files.loadSQLite)
	state.PreloadModule("zlib", loadZlib)
	state.PreloadModule("socket", func(state *lua.LState) int { return loadSocket(state, client.now) })
	installLoader(state, client.options.SourceRoot)

	native := state.NewTable()
	native.RawSetString("platform", lua.LNumber(androidPlatform))
	native.RawSetString("versionName", lua.LString(versionName))
	native.RawSetString("packageName", lua.LString(packageName))
	native.RawSetString("sid", lua.LString(client.options.SID))
	native.RawSetString("loginToken", lua.LString(client.options.LoginToken))
	native.RawSetString("files", client.files.table(state))
	native.RawSetString("defaults", state.NewFunction(client.files.loadDefaults))
	native.RawSetString("saveDefaults", state.NewFunction(client.files.saveDefaults))
	native.RawSetString("md5File", state.NewFunction(client.files.md5File))
	native.RawSetString("md5", state.NewFunction(md5Text))
	native.RawSetString("decodeBase64", state.NewFunction(decodeBase64))
	native.RawSetString("layout", state.NewFunction(client.files.loadLayout))
	native.RawSetString("skeleton", state.NewFunction(client.files.loadSkeleton))
	native.RawSetString("imageSize", state.NewFunction(client.files.loadImageSize))
	native.RawSetString("atlasFrames", state.NewFunction(client.files.loadAtlasFrames))
	native.RawSetString("httpRequest", state.NewFunction(client.network.create))
	methods, assigned, fields, err := sourceNames(state, client.options.SourceRoot)
	if err != nil {
		return err
	}
	native.RawSetString("methods", methods)
	native.RawSetString("assigned", assigned)
	native.RawSetString("fields", fields)
	state.SetGlobal("__native", native)
	if err := state.DoString(prelude); err != nil {
		return fmt.Errorf("engine prelude: %w", err)
	}
	harness := state.GetGlobal("__vc").(*lua.LTable)
	client.frame = harness.RawGetString("frame").(*lua.LFunction)
	return nil
}

func (client *Client) print(state *lua.LState) int {
	parts := make([]string, 0, state.GetTop())
	for index := 1; index <= state.GetTop(); index++ {
		parts = append(parts, state.ToStringMeta(state.Get(index)).String())
	}
	fmt.Fprintf(client.options.Log, "[%9.3f] %s\n", client.clock.Seconds(), strings.Join(parts, "\t"))
	return 0
}

// Boot runs stock main_64.lua the way the engine does: errors go through __G__TRACKBACK__.
func (client *Client) Boot() error {
	invoke := client.state.GetGlobal("__vc").(*lua.LTable).RawGetString("invoke")
	boot := client.state.NewFunction(func(state *lua.LState) int {
		state.Push(state.GetGlobal("require"))
		state.Push(lua.LString("main_64"))
		state.Call(1, 0)
		return 0
	})
	return client.state.CallByParam(lua.P{Fn: invoke, NRet: 0, Protect: true}, boot)
}

// Run advances the virtual clock frame by frame; HTTP requests started in a frame complete, in order, before the next one.
func (client *Client) Run(duration time.Duration, stop func(*Client) bool) error {
	for end := client.clock + duration; client.clock < end; {
		client.clock += frameDelta
		if err := client.state.CallByParam(lua.P{Fn: client.frame, NRet: 0, Protect: true}, lua.LNumber(client.clock.Seconds()), lua.LNumber(frameDelta.Seconds())); err != nil {
			return fmt.Errorf("engine frame at %s: %w", client.clock, err)
		}
		client.network.complete(client.state)
		if stop != nil && stop(client) {
			return nil
		}
	}
	return nil
}

// Tap is a touch began and ended at (x, y) in design coordinates, dispatched through the engine's touch listeners.
func (client *Client) Tap(x, y float64) error {
	tap := client.state.GetGlobal("__vc").(*lua.LTable).RawGetString("tap")
	return client.state.CallByParam(lua.P{Fn: tap, NRet: 1, Protect: true}, lua.LNumber(x), lua.LNumber(y))
}

// TapNode taps the centre of the visible node at a name path such as "last_login_panel/server", the last one drawn when several match.
func (client *Client) TapNode(path string) error {
	tap := client.state.GetGlobal("__vc").(*lua.LTable).RawGetString("tapNode")
	return client.state.CallByParam(lua.P{Fn: tap, NRet: 1, Protect: true}, lua.LString(path))
}

// Call runs a scenario chunk as an engine callback: a Lua error in it, or in stock code it calls, takes the stock
// __G__TRACKBACK__ path (errorlog, upload) and lands in the report, as an error in a touch handler would.
func (client *Client) Call(chunk string) error {
	function, err := client.state.LoadString(chunk)
	if err != nil {
		return err
	}
	invoke := client.state.GetGlobal("__vc").(*lua.LTable).RawGetString("invoke")
	return client.state.CallByParam(lua.P{Fn: invoke, NRet: 0, Protect: true}, function)
}

// rememberRegion writes the meta row stock Meta:persist leaves after a region was chosen, in stock's own schema.
func rememberRegion(path, sid string, region Region) error {
	database, err := sql.Open("sqlite", path)
	if err != nil {
		return err
	}
	defer database.Close()
	if _, err := database.Exec(`CREATE TABLE IF NOT EXISTS meta (id INT NOT NULL PRIMARY KEY, sid TEXT NOT NULL, regionID INT NOT NULL,
		regionName TEXT NOT NULL, playerID INT NOT NULL DEFAULT 0, playerName TEXT NOT NULL)`); err != nil {
		return err
	}
	_, err = database.Exec(`INSERT OR REPLACE INTO meta (id, sid, regionID, regionName, playerID, playerName) VALUES (0, ?, ?, ?, 0, '')`, sid, region.ID, region.Name)
	return err
}

// InScene reports whether the stock client has entered a scene of that class name.
func (client *Client) InScene(name string) bool {
	for _, scene := range client.Report().Scenes {
		if scene.Name == name {
			return true
		}
	}
	return false
}

// Global reads a stock Lua global path such as "xyd.selfPlayer.playerID_".
func (client *Client) Global(path string) lua.LValue {
	value := lua.LValue(client.state.G.Global)
	for _, key := range strings.Split(path, ".") {
		table, ok := value.(*lua.LTable)
		if !ok {
			return lua.LNil
		}
		value = table.RawGetString(key)
	}
	return value
}

func (client *Client) Report() Report {
	report := client.report
	report.VirtualTime = client.clock.Seconds()
	report.Unreadable = client.files.unreadableList()
	engine := client.state.GetGlobal("__vc").(*lua.LTable).RawGetString("report").(*lua.LTable)
	report.Missing = map[string]float64{}
	engine.RawGetString("missing").(*lua.LTable).ForEach(func(key, value lua.LValue) {
		report.Missing[key.String()] = float64(value.(lua.LNumber))
	})
	engine.RawGetString("scenes").(*lua.LTable).ForEach(func(_, value lua.LValue) {
		scene := value.(*lua.LTable)
		report.Scenes = append(report.Scenes, SceneEntry{Name: scene.RawGetString("name").String(), At: float64(scene.RawGetString("at").(lua.LNumber))})
	})
	engine.RawGetString("errors").(*lua.LTable).ForEach(func(_, value lua.LValue) {
		report.LuaErrors = append(report.LuaErrors, value.String())
	})
	engine.RawGetString("sdk").(*lua.LTable).ForEach(func(_, value lua.LValue) {
		report.SDKCalls = append(report.SDKCalls, value.(*lua.LTable).RawGetString("method").String())
	})
	report.Exited = engine.RawGetString("exited") != lua.LNil
	report.Proxies = float64(engine.RawGetString("proxies").(lua.LNumber))
	return report
}

// installLoader resolves stock requires from src_64 ahead of package.path: stock files carry a UTF-8 BOM and some requires keep
// the ".lua" suffix (cocos FileUtils tolerates both, gopher-lua does neither).
func installLoader(state *lua.LState, root string) {
	loaders := state.GetField(state.GetGlobal("package"), "loaders").(*lua.LTable)
	loaders.Insert(1, state.NewFunction(func(state *lua.LState) int {
		name := strings.ReplaceAll(strings.TrimSuffix(state.CheckString(1), ".lua"), ".", "/")
		for _, candidate := range []string{name + ".lua", name + "/init.lua"} {
			source, err := os.ReadFile(filepath.Join(root, candidate))
			if err != nil {
				continue
			}
			chunk, err := state.Load(bytes.NewReader(bytes.TrimPrefix(source, []byte("\xef\xbb\xbf"))), candidate)
			if err != nil {
				state.RaiseError("%s: %v", candidate, err)
			}
			state.Push(chunk)
			return 1
		}
		state.Push(lua.LString("\n\tno stock file " + name))
		return 1
	}))
}

var (
	methodCall     = regexp.MustCompile(`:([A-Za-z_][A-Za-z0-9_]*)\s*[("{]`)
	exportedList   = regexp.MustCompile(`exportMethods_\(\{([^}]*)\}`)
	exportedMethod = regexp.MustCompile(`"([A-Za-z_][A-Za-z0-9_]*)"`)
	xydAlias       = regexp.MustCompile(`(?m)^local ([A-Za-z_][A-Za-z0-9_]*) = xyd\s*$`)
	selfField      = regexp.MustCompile(`\barg_[0-9]+_0\.([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^=\s][A-Za-z]*)`)
)

// xydAssignment matches stock setting an xyd field directly or through a file-local alias (BattleCreate: local var_0_12 = xyd).
func xydAssignment(source []byte) *regexp.Regexp {
	receivers := []string{"xyd"}
	for _, alias := range xydAlias.FindAllSubmatch(source, -1) {
		receivers = append(receivers, string(alias[1]))
	}
	return regexp.MustCompile(`\b(?:` + strings.Join(receivers, "|") + `)\.([A-Za-z_][A-Za-z0-9_]*)\s*=[^=]`)
}

// sourceNames reads three name sets from src_64. methods: the names stock calls with ":", the only keys an engine object answers
// for; names a stock component exports are Lua methods (Component.exportMethods_ installs them only where the target lacks the
// key). assigned: the xyd fields stock Lua sets itself (directly or through an alias), absent from the native xyd table until stock assigns them.
// fields: the names stock sets as data on a method's self (arg_N_0); on a class instance built over an engine object they live in the
// tolua peer, so they read nil until set (NewBattleLoadingWindow counts with self.count = self.count or 0).
func sourceNames(state *lua.LState, root string) (*lua.LTable, *lua.LTable, *lua.LTable, error) {
	methods, assigned, fields := state.NewTable(), state.NewTable(), state.NewTable()
	var exported []string
	err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err != nil || entry.IsDir() || !strings.HasSuffix(path, ".lua") {
			return err
		}
		source, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		for _, match := range methodCall.FindAllSubmatch(source, -1) {
			methods.RawSetString(string(match[1]), lua.LTrue)
		}
		for _, match := range xydAssignment(source).FindAllSubmatch(source, -1) {
			assigned.RawSetString(string(match[1]), lua.LTrue)
		}
		for _, match := range selfField.FindAllSubmatch(source, -1) {
			if string(match[2]) != "function" {
				fields.RawSetString(string(match[1]), lua.LTrue)
			}
		}
		for _, list := range exportedList.FindAllSubmatch(source, -1) {
			for _, name := range exportedMethod.FindAllSubmatch(list[1], -1) {
				exported = append(exported, string(name[1]))
			}
		}
		return nil
	})
	for _, name := range exported {
		methods.RawSetString(name, lua.LNil)
	}
	return methods, assigned, fields, err
}

// SourceDigest hashes a src_64 tree the way PinnedSourceDigest was computed.
func SourceDigest(root string) (string, error) {
	var lines []string
	err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err != nil || entry.IsDir() {
			return err
		}
		content, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		relative, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		sum := sha256.Sum256(content)
		lines = append(lines, filepath.ToSlash(relative)+"\x00"+hex.EncodeToString(sum[:])+"\n")
		return nil
	})
	if err != nil {
		return "", err
	}
	if len(lines) == 0 {
		return "", errors.New("empty src_64 tree: " + root)
	}
	sort.Strings(lines)
	sum := sha256.Sum256([]byte(strings.Join(lines, "")))
	return hex.EncodeToString(sum[:]), nil
}
