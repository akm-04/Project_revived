package client

import (
	"encoding/binary"
	"errors"
	"math"

	lua "github.com/yuin/gopher-lua"
)

// Cocos Studio 2.x .csb is a FlatBuffers CSParseBinary. Field indexes below are the CSParseBinary schema's.
const (
	binaryTextures = 1
	binaryNodeTree = 3

	treeClass    = 0
	treeChildren = 1
	treeOptions  = 2

	optionsData        = 0
	widgetNodeOptions  = 0
	widgetName         = 0
	widgetVisible      = 4
	widgetTag          = 6
	widgetPosition     = 7
	widgetSize         = 11
	widgetTouchEnabled = 15
	textOptionsContent = 4
)

var errLayout = errors.New("malformed csb")

type flatBuffer []byte

func (buffer flatBuffer) uint32At(offset int) (int, error) {
	if offset < 0 || offset+4 > len(buffer) {
		return 0, errLayout
	}
	return int(binary.LittleEndian.Uint32(buffer[offset:])), nil
}

// field returns the absolute position of a table's field, or 0 when the field is absent.
func (buffer flatBuffer) field(table, index int) (int, error) {
	if table <= 0 || table+4 > len(buffer) {
		return 0, errLayout
	}
	vtable := table - int(int32(binary.LittleEndian.Uint32(buffer[table:])))
	if vtable < 0 || vtable+4 > len(buffer) {
		return 0, errLayout
	}
	size := int(binary.LittleEndian.Uint16(buffer[vtable:]))
	entry := vtable + 4 + 2*index
	if entry+2 > vtable+size || entry+2 > len(buffer) {
		return 0, nil
	}
	offset := int(binary.LittleEndian.Uint16(buffer[entry:]))
	if offset == 0 {
		return 0, nil
	}
	return table + offset, nil
}

// reference follows an offset field (table, string or vector); 0 when absent.
func (buffer flatBuffer) reference(table, index int) (int, error) {
	position, err := buffer.field(table, index)
	if err != nil || position == 0 {
		return 0, err
	}
	offset, err := buffer.uint32At(position)
	return position + offset, err
}

func (buffer flatBuffer) text(table, index int) (string, error) {
	position, err := buffer.reference(table, index)
	if err != nil || position == 0 {
		return "", err
	}
	return buffer.stringAt(position)
}

func (buffer flatBuffer) stringAt(position int) (string, error) {
	length, err := buffer.uint32At(position)
	if err != nil || position+4+length > len(buffer) {
		return "", errLayout
	}
	return string(buffer[position+4 : position+4+length]), nil
}

// texts reads a vector of strings; empty when the field is absent.
func (buffer flatBuffer) texts(table, index int) ([]string, error) {
	vector, err := buffer.reference(table, index)
	if err != nil || vector == 0 {
		return nil, err
	}
	count, err := buffer.uint32At(vector)
	if err != nil {
		return nil, err
	}
	var texts []string
	for element := vector + 4; element < vector+4+4*count; element += 4 {
		offset, err := buffer.uint32At(element)
		if err != nil {
			return nil, err
		}
		text, err := buffer.stringAt(element + offset)
		if err != nil {
			return nil, err
		}
		texts = append(texts, text)
	}
	return texts, nil
}

func (buffer flatBuffer) floats(table, index int) (float64, float64, bool) {
	position, err := buffer.field(table, index)
	if err != nil || position == 0 || position+8 > len(buffer) {
		return 0, 0, false
	}
	first := math.Float32frombits(binary.LittleEndian.Uint32(buffer[position:]))
	second := math.Float32frombits(binary.LittleEndian.Uint32(buffer[position+4:]))
	return float64(first), float64(second), true
}

// layoutTable reads a .csb into the node description the engine model builds nodes from:
// {class, name, tag, visible, touch, text, x, y, width, height, children}.
func layoutTable(state *lua.LState, data []byte) (*lua.LTable, error) {
	buffer := flatBuffer(data)
	root, err := buffer.uint32At(0)
	if err != nil {
		return nil, err
	}
	tree, err := buffer.reference(root, binaryNodeTree)
	if err != nil || tree == 0 {
		return nil, errLayout
	}
	description, err := buffer.node(state, tree, 0)
	if err != nil {
		return nil, err
	}
	// The sprite-frame atlases (plists) the layout uses; CSLoader adds them to the SpriteFrameCache before building the nodes.
	textures, err := buffer.texts(root, binaryTextures)
	if err != nil {
		return nil, err
	}
	atlases := state.NewTable()
	for _, texture := range textures {
		atlases.Append(lua.LString(texture))
	}
	description.RawSetString("textures", atlases)
	return description, nil
}

func (buffer flatBuffer) node(state *lua.LState, tree, depth int) (*lua.LTable, error) {
	if depth > 64 {
		return nil, errLayout
	}
	class, err := buffer.text(tree, treeClass)
	if err != nil {
		return nil, err
	}
	description := state.NewTable()
	description.RawSetString("class", lua.LString(class))
	if err := buffer.describe(description, tree, class); err != nil {
		return nil, err
	}
	children := state.NewTable()
	vector, err := buffer.reference(tree, treeChildren)
	if err != nil {
		return nil, err
	}
	if vector != 0 {
		count, err := buffer.uint32At(vector)
		if err != nil {
			return nil, err
		}
		for index := 0; index < count; index++ {
			element := vector + 4 + 4*index
			offset, err := buffer.uint32At(element)
			if err != nil {
				return nil, err
			}
			child, err := buffer.node(state, element+offset, depth+1)
			if err != nil {
				return nil, err
			}
			children.Append(child)
		}
	}
	description.RawSetString("children", children)
	return description, nil
}

func (buffer flatBuffer) describe(description *lua.LTable, tree int, class string) error {
	options, err := buffer.reference(tree, treeOptions)
	if err != nil || options == 0 {
		return err
	}
	data, err := buffer.reference(options, optionsData)
	if err != nil || data == 0 {
		return err
	}
	widget := data
	if class != "Node" {
		if widget, err = buffer.reference(data, widgetNodeOptions); err != nil || widget == 0 {
			return err
		}
	}
	name, err := buffer.text(widget, widgetName)
	if err != nil {
		return err
	}
	description.RawSetString("name", lua.LString(name))
	if position, _ := buffer.field(widget, widgetTag); position != 0 && position+4 <= len(buffer) {
		description.RawSetString("tag", lua.LNumber(int32(binary.LittleEndian.Uint32(buffer[position:]))))
	}
	description.RawSetString("visible", lua.LTrue)
	if position, _ := buffer.field(widget, widgetVisible); position != 0 && position < len(buffer) {
		description.RawSetString("visible", lua.LBool(buffer[position] != 0))
	}
	if position, _ := buffer.field(widget, widgetTouchEnabled); position != 0 && position < len(buffer) && buffer[position] != 0 {
		description.RawSetString("touch", lua.LTrue)
	}
	if x, y, ok := buffer.floats(widget, widgetPosition); ok {
		description.RawSetString("x", lua.LNumber(x))
		description.RawSetString("y", lua.LNumber(y))
	}
	if width, height, ok := buffer.floats(widget, widgetSize); ok {
		description.RawSetString("width", lua.LNumber(width))
		description.RawSetString("height", lua.LNumber(height))
	}
	if class == "Text" {
		content, err := buffer.text(data, textOptionsContent)
		if err != nil {
			return err
		}
		description.RawSetString("text", lua.LString(content))
	}
	return nil
}

// loadLayout is native.layout(path): the node description of a .csb on the search paths, or nil, message.
func (files *fileSystem) loadLayout(state *lua.LState) int {
	data, ok := files.read(state.CheckString(1))
	if !ok {
		state.Push(lua.LNil)
		state.Push(lua.LString("unreadable"))
		return 2
	}
	description, err := layoutTable(state, data)
	if err != nil {
		state.Push(lua.LNil)
		state.Push(lua.LString(err.Error()))
		return 2
	}
	state.Push(description)
	return 1
}
