package client

import (
	"bytes"
	"encoding/binary"
	"image"
	"image/png"
	"os"
	"path/filepath"
	"strings"
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
	client := engine(t, `node:hide() view:exportMethods_({"bar"}) node:bar() xyd.lazyFileManager = {} if xyd.other == 1 then end
local alias = xyd
alias.isArenaBattle = true
function window.loop(arg_8_0) arg_8_0.count = arg_8_0.count or 0 arg_8_0.onTick = function() end end
list:count() window:onTick()`, nil)
	run(t, client, `result = {hide = __native.methods.hide, bar = __native.methods.bar, lazy = __native.assigned.lazyFileManager,
		other = __native.assigned.other, xydLazy = xyd.lazyFileManager, xydOther = xyd.other ~= nil, aliased = xyd.isArenaBattle}
		local plain, instance = cc.Node:create(), cc.Node:create()
		instance.class = {}
		result.plainCount = plain.count ~= nil
		result.instanceCount = instance.count
		result.instanceTick = instance.onTick ~= nil`)
	expect(t, client, "result.hide", lua.LTrue)
	expect(t, client, "result.bar", lua.LNil)
	expect(t, client, "result.lazy", lua.LTrue)
	expect(t, client, "result.other", lua.LNil)
	expect(t, client, "result.xydLazy", lua.LNil)
	expect(t, client, "result.xydOther", lua.LTrue)
	expect(t, client, "result.aliased", lua.LNil)
	expect(t, client, "result.plainCount", lua.LTrue)
	expect(t, client, "result.instanceCount", lua.LNil)
	expect(t, client, "result.instanceTick", lua.LTrue)
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

func TestWidgetNativeMethodsAndOverflowErrors(t *testing.T) {
	client := engine(t, ``, nil)
	run(t, client, `
		function ccui.Widget.setTouchEnabled(widget, enabled)
			tolua.getcfunction(widget, "setTouchEnabled")(widget, enabled)
		end
		local widget = ccui.Layout:create()
		widget:setTouchEnabled(true)
		result = {touch = widget:isTouchEnabled()}
		local function deep() return deep() + 1 end
		result.ok = __vc.invoke(deep)
		result.errors = #__vc.report.errors`)
	expect(t, client, "result.touch", lua.LTrue)
	expect(t, client, "result.ok", lua.LFalse)
	expect(t, client, "result.errors", lua.LNumber(1))
}

func TestNodePauseSuspendsUpdates(t *testing.T) {
	client := engine(t, ``, nil)
	run(t, client, `
		local scene, model = cc.Scene:create(), cc.Node:create()
		scene:addChild(model)
		cc.Director:getInstance():runWithScene(scene)
		result = {ticks = 0}
		model:scheduleUpdateWithPriorityLua(function() result.ticks = result.ticks + 1 end, 0)
		__vc.frame(0, 0.1)
		__vc.frame(0.1, 0.1)
		local before = result.ticks
		getmetatable(cc.Node).pause(model)
		__vc.frame(0.2, 0.1)
		result.paused = result.ticks - before
		getmetatable(cc.Node).resume(model)
		__vc.frame(0.3, 0.1)
		result.resumed = result.ticks - before`)
	expect(t, client, "result.paused", lua.LNumber(0))
	expect(t, client, "result.resumed", lua.LNumber(1))
}

const atlasPlist = `<plist version="1.0"><dict><key>frames</key><dict>
	<key>icons/line.png</key><dict><key>frame</key><string>{{1,1},{8,2}}</string><key>rotated</key><true/><key>sourceSize</key><string>{9,3}</string></dict>
	</dict></dict></plist>`

func TestSpriteTextureSizes(t *testing.T) {
	var picture bytes.Buffer
	if err := png.Encode(&picture, image.NewRGBA(image.Rect(0, 0, 7, 5))); err != nil {
		t.Fatal(err)
	}
	client := engine(t, ``, map[string]string{"icons/atlas.plist": atlasPlist, "panel/line.png": picture.String()})
	run(t, client, `
		local cache = cc.SpriteFrameCache:getInstance()
		result = {before = cache:getSpriteFrame("icons/line.png") == nil}
		cache:addSpriteFrames("icons/atlas.plist")
		local framed = cc.Sprite:createWithSpriteFrame(cache:getSpriteFrame("icons/line.png"))
		local file = cc.Sprite:create("panel/line.png")
		local scaled = ccui.Scale9Sprite:create(cc.rect(1, 1, 1, 1), "#icons/line.png")
		result.framedWidth, result.fileWidth, result.fileHeight = framed:getContentSize().width, file:getContentSize().width, file:getContentSize().height
		result.scaledHeight = scaled:getContentSize().height
		result.missing = cc.Sprite:create("panel/absent.png") == nil`)
	expect(t, client, "result.before", lua.LTrue)
	expect(t, client, "result.framedWidth", lua.LNumber(9))
	expect(t, client, "result.fileWidth", lua.LNumber(7))
	expect(t, client, "result.fileHeight", lua.LNumber(5))
	expect(t, client, "result.scaledHeight", lua.LNumber(3))
	expect(t, client, "result.missing", lua.LTrue)
}

// minimalLayout is a CSParseBinary flatbuffer by hand: textures ["a.plist"] (root field 1) and a "Node" tree (root field 3).
func minimalLayout() string {
	buffer := make([]byte, 73)
	put16 := func(position int, value uint16) { binary.LittleEndian.PutUint16(buffer[position:], value) }
	put32 := func(position int, value uint32) { binary.LittleEndian.PutUint32(buffer[position:], value) }
	put32(0, 16)
	for index, value := range []uint16{12, 12, 0, 4, 0, 8} {
		put16(4+2*index, value)
	}
	put32(16, 12)
	put32(20, 8)
	put32(24, 20)
	put32(28, 1)
	put32(32, 20)
	for index, value := range []uint16{6, 8, 4} {
		put16(36+2*index, value)
	}
	put32(44, 8)
	put32(48, 16)
	put32(52, 7)
	copy(buffer[56:], "a.plist")
	put32(64, 4)
	copy(buffer[68:], "Node")
	return string(buffer)
}

func TestLayoutLoadsItsAtlases(t *testing.T) {
	plist := strings.Replace(atlasPlist, "icons/line.png", "layout/tab.png", 1)
	client := engine(t, ``, map[string]string{"a.csb": minimalLayout(), "a.plist": plist})
	run(t, client, `
		local cache = cc.SpriteFrameCache:getInstance()
		result = {before = cache:getSpriteFrame("layout/tab.png") == nil}
		cc.CSLoader:createNode("a.csb")
		result.after = cache:getSpriteFrame("layout/tab.png") ~= nil`)
	expect(t, client, "result.before", lua.LTrue)
	expect(t, client, "result.after", lua.LTrue)
}
