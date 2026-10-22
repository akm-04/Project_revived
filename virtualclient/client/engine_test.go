package client

import (
	"os"
	"path/filepath"
	"testing"
	"time"

	lua "github.com/yuin/gopher-lua"
)

// engine builds a client over a synthetic source tree (skipping the src_64 pin) so the engine model can be checked alone.
func engine(t *testing.T, source string, assets map[string]string) *Client {
	t.Helper()
	root := t.TempDir()
	sourceRoot, assetRoot := filepath.Join(root, "src"), filepath.Join(root, "assets")
	write := func(path, content string) {
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	write(filepath.Join(sourceRoot, "names.lua"), source)
	for path, content := range assets {
		write(filepath.Join(assetRoot, path), content)
	}
	files, err := newFileSystem(assetRoot, filepath.Join(root, "device"))
	if err != nil {
		t.Fatal(err)
	}
	client := &Client{options: Options{SourceRoot: sourceRoot, Log: os.Stderr, Start: time.Unix(0, 0)}, state: lua.NewState(), files: files}
	client.network = newNetwork("", &client.report, func() float64 { return client.clock.Seconds() })
	if err := client.install(); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(client.Close)
	return client
}

func run(t *testing.T, client *Client, script string) {
	t.Helper()
	if err := client.state.DoString(script); err != nil {
		t.Fatal(err)
	}
}

func expect(t *testing.T, client *Client, path string, want lua.LValue) {
	t.Helper()
	if got := client.Global(path); got.String() != want.String() || got.Type() != want.Type() {
		t.Errorf("%s = %v (%s), want %v (%s)", path, got, got.Type(), want, want.Type())
	}
}

func TestSourceNames(t *testing.T) {
	client := engine(t, `node:hide() view:exportMethods_({"bar"}) node:bar() xyd.lazyFileManager = {} if xyd.other == 1 then end`, nil)
	run(t, client, `result = {hide = __native.methods.hide, bar = __native.methods.bar, lazy = __native.assigned.lazyFileManager,
		other = __native.assigned.other, xydLazy = xyd.lazyFileManager, xydOther = xyd.other ~= nil}`)
	expect(t, client, "result.hide", lua.LTrue)
	expect(t, client, "result.bar", lua.LNil)
	expect(t, client, "result.lazy", lua.LTrue)
	expect(t, client, "result.other", lua.LNil)
	expect(t, client, "result.xydLazy", lua.LNil)
	expect(t, client, "result.xydOther", lua.LTrue)
}

func TestNativeHelpers(t *testing.T) {
	client := engine(t, ``, nil)
	run(t, client, `
		local cjson = require("cjson")
		result = {
			hex = tonumber("0x0000ff", 16), plainHex = tonumber("ff", 16), decimal = tonumber("12"),
			base64 = cc.Crypto:decodeBase64("aGk=\n"), notBase64 = cc.Crypto:decodeBase64("%%%") == nil,
			json = cjson.decode('{"a":[1,2]}').a[2], band = bit.band(36864, 32768),
		}
		local node = cc.Node:create()
		node:setContentSize(4, 5)
		node:setName("layer")
		local copy = node:clone()
		result.cloneWidth, result.cloneName = copy:getContentSize().width, copy:getName()`)
	expect(t, client, "result.hex", lua.LNumber(255))
	expect(t, client, "result.plainHex", lua.LNumber(255))
	expect(t, client, "result.decimal", lua.LNumber(12))
	expect(t, client, "result.base64", lua.LString("hi"))
	expect(t, client, "result.notBase64", lua.LTrue)
	expect(t, client, "result.json", lua.LNumber(2))
	expect(t, client, "result.band", lua.LNumber(32768))
	expect(t, client, "result.cloneWidth", lua.LNumber(4))
	expect(t, client, "result.cloneName", lua.LString("layer"))
}

const skeletonJSON = `{"skeleton": {"spine": "2.1.27"}, "bones": [{"name": "root"}, {"name": "hit_point", "parent": "root", "x": 3, "y": -2}],
	"animations": {"gongji01": {"bones": {"root": {"rotate": [{"time": 0, "angle": 0}, {"time": 1.0, "angle": 5}]}},
		"events": [{"time": 0.5, "name": "hit"}]}, "idle": {"slots": {}}}}`

func TestSpineSkeleton(t *testing.T) {
	client := engine(t, ``, map[string]string{"skeletons/hero.json": skeletonJSON})
	run(t, client, `
		seen = {}
		local scene = cc.Scene:create()
		cc.Director:getInstance():runWithScene(scene)
		hero = sp.SkeletonAnimation:create("skeletons/hero.json", "skeletons/hero.atlas", 1)
		scene:addChild(hero)
		hero:registerSpineEventHandler(function(event) table.insert(seen, event.type .. ":" .. (event.eventData and event.eventData.name or event.animation) .. ":" .. event.loopCount) end, sp.EventType.ANIMATION_EVENT)
		hero:registerSpineEventHandler(function(event) table.insert(seen, event.type .. ":" .. event.animation .. ":" .. event.loopCount) end, sp.EventType.ANIMATION_COMPLETE)
		hero:setAnimation(0, "gongji01", false)
		result = {has = hero:hasAnimation("gongji01"), hasNot = hero:hasAnimation("gongji09")}
		result.boneX, result.boneY = hero:getBonePosition("hit_point")
		missing = sp.SkeletonAnimation:create("skeletons/none.json", "", 1)
		result.missingHas = missing:hasAnimation("idle")`)
	if err := client.Run(2*time.Second, nil); err != nil {
		t.Fatal(err)
	}
	run(t, client, `
		result.once = table.concat(seen, ",")
		seen = {}
		getmetatable(sp.SkeletonAnimation).setTimeScale(hero, 2)
		hero:setAnimation(0, "gongji01", true)`)
	if err := client.Run(1100*time.Millisecond, nil); err != nil {
		t.Fatal(err)
	}
	run(t, client, `result.looped = table.concat(seen, ",")`)
	expect(t, client, "result.has", lua.LTrue)
	expect(t, client, "result.hasNot", lua.LFalse)
	expect(t, client, "result.boneX", lua.LNumber(3))
	expect(t, client, "result.boneY", lua.LNumber(-2))
	expect(t, client, "result.missingHas", lua.LFalse)
	expect(t, client, "result.once", lua.LString("event:hit:0,complete:gongji01:1"))
	expect(t, client, "result.looped", lua.LString("event:hit:0,complete:gongji01:1,event:hit:1,complete:gongji01:2"))
	if client.Report().Missing["sp.SkeletonAnimation.create:skeletons/none.json:unreadable"] != 1 {
		t.Errorf("missing skeleton not reported: %v", client.Report().Missing)
	}
}

func TestUpdateTreeIsNotWrittenThrough(t *testing.T) {
	root := t.TempDir()
	tree, device := filepath.Join(root, "tree"), filepath.Join(root, "device")
	shared := filepath.Join(tree, "res", "web", "a.json")
	if err := os.MkdirAll(filepath.Dir(shared), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(shared, []byte("tree"), 0o644); err != nil {
		t.Fatal(err)
	}
	for range 2 {
		if err := linkTree(tree, device); err != nil {
			t.Fatal(err)
		}
	}
	if err := replaceFile(filepath.Join(device, "res", "web", "a.json"), []byte("device")); err != nil {
		t.Fatal(err)
	}
	if content, _ := os.ReadFile(shared); string(content) != "tree" {
		t.Fatalf("shared tree file now %q", content)
	}
}
