package client

import (
	"bytes"
	"image"
	_ "image/jpeg"
	_ "image/png"
	"regexp"
	"strconv"

	lua "github.com/yuin/gopher-lua"
)

// shortcut: only TexturePacker format 2 frame dicts (every atlas on the device and in the update tree); add formats 0/1/3 if one ships.
var atlasFrame = regexp.MustCompile(`<key>([^<]+)</key>\s*<dict>\s*<key>frame</key>(?s:.*?)<key>sourceSize</key>\s*<string>\{(\d+),\s*(\d+)\}</string>`)

// loadImageSize answers the pixel size of an image file from its header, or nothing when the file is not on the device.
func (files *fileSystem) loadImageSize(state *lua.LState) int {
	data, ok := files.read(state.CheckString(1))
	if !ok {
		return 0
	}
	config, _, err := image.DecodeConfig(bytes.NewReader(data))
	if err != nil {
		return 0
	}
	state.Push(lua.LNumber(config.Width))
	state.Push(lua.LNumber(config.Height))
	return 2
}

// loadAtlasFrames answers an atlas plist's frames as name -> {width, height} (the untrimmed sourceSize a sprite takes), or nothing.
func (files *fileSystem) loadAtlasFrames(state *lua.LState) int {
	data, ok := files.read(state.CheckString(1))
	if !ok {
		return 0
	}
	frames := state.NewTable()
	for _, match := range atlasFrame.FindAllSubmatch(data, -1) {
		width, _ := strconv.Atoi(string(match[2]))
		height, _ := strconv.Atoi(string(match[3]))
		size := state.NewTable()
		size.RawSetString("width", lua.LNumber(width))
		size.RawSetString("height", lua.LNumber(height))
		frames.RawSetString(string(match[1]), size)
	}
	state.Push(frames)
	return 1
}
