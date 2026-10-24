package client

import (
	"crypto/md5"
	"database/sql"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"encoding/xml"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	lua "github.com/yuin/gopher-lua"
)

// fileSystem is cocos FileUtils for one virtual install: reads resolve through the stock search paths over the device storage
// and the APK assets; writes stay inside the device storage.
type fileSystem struct {
	assetRoot   string
	deviceRoot  string
	searchPaths []string
	unreadable  map[string]bool
	databases   []*sql.DB
}

func newFileSystem(assetRoot, deviceRoot string) (*fileSystem, error) {
	assets, err := filepath.Abs(assetRoot)
	if err != nil {
		return nil, err
	}
	device, err := filepath.Abs(deviceRoot)
	if err != nil {
		return nil, err
	}
	for _, directory := range []string{"support", "documents", "writable"} {
		if err := os.MkdirAll(filepath.Join(device, directory), 0o755); err != nil {
			return nil, err
		}
	}
	return &fileSystem{assetRoot: assets, deviceRoot: device, unreadable: map[string]bool{}}, nil
}

// replaceFile writes a new file in place of path, so a file hard-linked from the shared update tree is never written through.
func replaceFile(path string, content []byte) error {
	if err := os.Remove(path); err != nil && !errors.Is(err, fs.ErrNotExist) {
		return err
	}
	return os.WriteFile(path, content, 0o644)
}

// linkTree hard-links every file of source into target (the stock xyd.versionUpdatePath), keeping files already there; device
// writes go through replaceFile, rename or remove, none of which change the shared tree.
func linkTree(source, target string) error {
	return filepath.WalkDir(source, func(path string, entry fs.DirEntry, err error) error {
		if err != nil || entry.IsDir() {
			return err
		}
		relative, err := filepath.Rel(source, path)
		if err != nil {
			return err
		}
		destination := filepath.Join(target, relative)
		if err := os.MkdirAll(filepath.Dir(destination), 0o755); err != nil {
			return err
		}
		if err := os.Link(path, destination); err != nil && !errors.Is(err, fs.ErrExist) {
			return err
		}
		return nil
	})
}

func (files *fileSystem) close() {
	for _, database := range files.databases {
		database.Close()
	}
}

func (files *fileSystem) unreadableList() []string {
	list := make([]string, 0, len(files.unreadable))
	for path := range files.unreadable {
		list = append(list, path)
	}
	sort.Strings(list)
	return list
}

func (files *fileSystem) resolve(path string) (string, bool) {
	if filepath.IsAbs(path) {
		_, err := os.Stat(path)
		return path, err == nil
	}
	var candidates []string
	for _, searchPath := range files.searchPaths {
		if !filepath.IsAbs(searchPath) {
			searchPath = filepath.Join(files.assetRoot, searchPath)
		}
		candidates = append(candidates, filepath.Join(searchPath, path))
	}
	candidates = append(candidates, filepath.Join(files.assetRoot, path))
	for _, candidate := range candidates {
		if _, err := os.Stat(candidate); err == nil {
			return candidate, true
		}
	}
	return path, false
}

// writable refuses any path outside the device storage, so stock deletes and renames can never reach the inputs.
func (files *fileSystem) writable(path string) (string, error) {
	absolute, err := filepath.Abs(path)
	if err != nil {
		return "", err
	}
	if absolute != files.deviceRoot && !strings.HasPrefix(absolute, files.deviceRoot+string(filepath.Separator)) {
		return "", fmt.Errorf("write outside the device storage: %s", path)
	}
	return absolute, nil
}

func (files *fileSystem) read(path string) ([]byte, bool) {
	resolved, ok := files.resolve(path)
	if !ok {
		files.unreadable[path] = true
		return nil, false
	}
	content, err := os.ReadFile(resolved)
	if err != nil {
		files.unreadable[path] = true
		return nil, false
	}
	return content, true
}

func (files *fileSystem) table(state *lua.LState) *lua.LTable {
	directory := func(name string) lua.LGFunction {
		return func(state *lua.LState) int {
			state.Push(lua.LString(filepath.Join(files.deviceRoot, name) + "/"))
			return 1
		}
	}
	readText := func(state *lua.LState) int {
		content, _ := files.read(state.CheckString(1))
		state.Push(lua.LString(content))
		return 1
	}
	boolean := func(state *lua.LState, err error) int {
		state.Push(lua.LBool(err == nil))
		return 1
	}
	functions := map[string]lua.LGFunction{
		"getStringFromFile": readText,
		"getDataFromFile":   readText,
		"isFileExist": func(state *lua.LState) int {
			resolved, ok := files.resolve(state.CheckString(1))
			info, err := os.Stat(resolved)
			state.Push(lua.LBool(ok && err == nil && !info.IsDir()))
			return 1
		},
		"isDirectoryExist": func(state *lua.LState) int {
			resolved, ok := files.resolve(state.CheckString(1))
			info, err := os.Stat(resolved)
			state.Push(lua.LBool(ok && err == nil && info.IsDir()))
			return 1
		},
		"fullPathForFilename": func(state *lua.LState) int {
			resolved, _ := files.resolve(state.CheckString(1))
			state.Push(lua.LString(resolved))
			return 1
		},
		"getFileSize": func(state *lua.LState) int {
			resolved, _ := files.resolve(state.CheckString(1))
			info, err := os.Stat(resolved)
			if err != nil {
				state.Push(lua.LNumber(0))
				return 1
			}
			state.Push(lua.LNumber(info.Size()))
			return 1
		},
		"getSupportPath":  directory("support"),
		"getDocumentPath": directory("documents"),
		"getWritablePath": directory("writable"),
		"createDirectory": func(state *lua.LState) int {
			path, err := files.writable(state.CheckString(1))
			if err == nil {
				err = os.MkdirAll(path, 0o755)
			}
			return boolean(state, err)
		},
		"removeFile": func(state *lua.LState) int {
			path, err := files.writable(state.CheckString(1))
			if err == nil {
				err = os.Remove(path)
			}
			return boolean(state, err)
		},
		"removeDirectory": func(state *lua.LState) int {
			path, err := files.writable(state.CheckString(1))
			if err == nil {
				err = os.RemoveAll(path)
			}
			return boolean(state, err)
		},
		"renameFile": func(state *lua.LState) int {
			from, to := state.CheckString(1), state.CheckString(2)
			if state.GetTop() >= 3 {
				from, to = filepath.Join(from, to), filepath.Join(from, state.CheckString(3))
			}
			source, err := files.writable(from)
			if err != nil {
				return boolean(state, err)
			}
			target, err := files.writable(to)
			if err == nil {
				err = os.Rename(source, target)
			}
			return boolean(state, err)
		},
		"writeStringToFile": func(state *lua.LState) int {
			path, err := files.writable(state.CheckString(2))
			if err == nil {
				err = replaceFile(path, []byte(state.CheckString(1)))
			}
			return boolean(state, err)
		},
		"setSearchPaths": func(state *lua.LState) int {
			files.searchPaths = nil
			state.CheckTable(1).ForEach(func(_, value lua.LValue) {
				files.searchPaths = append(files.searchPaths, value.String())
			})
			return 0
		},
		"addSearchPath": func(state *lua.LState) int {
			path := state.CheckString(1)
			if state.ToBool(2) {
				files.searchPaths = append([]string{path}, files.searchPaths...)
				return 0
			}
			files.searchPaths = append(files.searchPaths, path)
			return 0
		},
		"getSearchPaths": func(state *lua.LState) int {
			list := state.NewTable()
			for _, path := range files.searchPaths {
				list.Append(lua.LString(path))
			}
			state.Push(list)
			return 1
		},
		"getValueMapFromFile": func(state *lua.LState) int {
			content, ok := files.read(state.CheckString(1))
			if !ok {
				state.Push(state.NewTable())
				return 1
			}
			value, err := plistValue(state, content)
			if err != nil {
				state.RaiseError("plist %s: %v", state.CheckString(1), err)
			}
			state.Push(value)
			return 1
		},
	}
	table := state.NewTable()
	for name, function := range functions {
		table.RawSetString(name, state.NewFunction(function))
	}
	return table
}

func (files *fileSystem) defaultsPath() string {
	return filepath.Join(files.deviceRoot, "UserDefault.json")
}

// loadDefaults returns the persisted cc.UserDefault map of this install.
func (files *fileSystem) loadDefaults(state *lua.LState) int {
	table := state.NewTable()
	content, err := os.ReadFile(files.defaultsPath())
	if errors.Is(err, os.ErrNotExist) {
		state.Push(table)
		return 1
	}
	if err != nil {
		state.RaiseError("user defaults: %v", err)
	}
	var values map[string]any
	if err := json.Unmarshal(content, &values); err != nil {
		state.RaiseError("user defaults: %v", err)
	}
	for key, value := range values {
		table.RawSetString(key, toLua(state, value))
	}
	state.Push(table)
	return 1
}

func (files *fileSystem) saveDefaults(state *lua.LState) int {
	values := map[string]any{}
	state.CheckTable(1).ForEach(func(key, value lua.LValue) {
		switch typed := value.(type) {
		case lua.LBool:
			values[key.String()] = bool(typed)
		case lua.LNumber:
			values[key.String()] = float64(typed)
		default:
			values[key.String()] = value.String()
		}
	})
	content, err := json.MarshalIndent(values, "", " ")
	if err == nil {
		err = os.WriteFile(files.defaultsPath(), content, 0o644)
	}
	if err != nil {
		state.RaiseError("user defaults: %v", err)
	}
	return 0
}

func (files *fileSystem) md5File(state *lua.LState) int {
	resolved, ok := files.resolve(state.CheckString(1))
	if !ok {
		state.Push(lua.LString(""))
		return 1
	}
	file, err := os.Open(resolved)
	if err != nil {
		state.Push(lua.LString(""))
		return 1
	}
	defer file.Close()
	hash := md5.New()
	if _, err := io.Copy(hash, file); err != nil {
		state.Push(lua.LString(""))
		return 1
	}
	state.Push(lua.LString(hex.EncodeToString(hash.Sum(nil))))
	return 1
}

func md5Text(state *lua.LState) int {
	sum := md5.Sum([]byte(state.CheckString(1)))
	if state.ToBool(2) {
		state.Push(lua.LString(sum[:]))
		return 1
	}
	state.Push(lua.LString(hex.EncodeToString(sum[:])))
	return 1
}

// decodeBase64 is cc.Crypto:decodeBase64: nil when the text is not base64.
func decodeBase64(state *lua.LState) int {
	text := strings.NewReplacer("\r", "", "\n", "").Replace(state.CheckString(1))
	decoded, err := base64.StdEncoding.DecodeString(text)
	if err != nil {
		state.Push(lua.LNil)
		return 1
	}
	state.Push(lua.LString(decoded))
	return 1
}

// plistValue converts an Apple property list to Lua; top-level dictionaries are merged, as stock infos.xml (one dict per key) needs.
func plistValue(state *lua.LState, content []byte) (lua.LValue, error) {
	decoder := xml.NewDecoder(strings.NewReader(string(content)))
	decoder.Strict = false
	root := state.NewTable()
	type frame struct {
		table *lua.LTable
		array bool
		key   string
	}
	var stack []*frame
	var text strings.Builder
	store := func(value lua.LValue) {
		if len(stack) == 0 {
			return
		}
		top := stack[len(stack)-1]
		if top.array {
			top.table.Append(value)
			return
		}
		top.table.RawSetString(top.key, value)
	}
	for {
		token, err := decoder.Token()
		if errors.Is(err, io.EOF) {
			return root, nil
		}
		if err != nil {
			return nil, err
		}
		switch element := token.(type) {
		case xml.StartElement:
			text.Reset()
			switch element.Name.Local {
			case "dict", "array":
				if len(stack) == 0 {
					stack = append(stack, &frame{table: root, array: element.Name.Local == "array"})
					continue
				}
				child := &frame{table: state.NewTable(), array: element.Name.Local == "array"}
				store(child.table)
				stack = append(stack, child)
			case "true", "false":
				store(lua.LBool(element.Name.Local == "true"))
			}
		case xml.CharData:
			text.Write(element)
		case xml.EndElement:
			value := text.String()
			switch element.Name.Local {
			case "dict", "array":
				if len(stack) > 0 {
					stack = stack[:len(stack)-1]
				}
			case "key":
				if len(stack) > 0 {
					stack[len(stack)-1].key = value
				}
			case "string", "date", "data":
				store(lua.LString(value))
			case "integer", "real":
				number, err := strconv.ParseFloat(strings.TrimSpace(value), 64)
				if err != nil {
					return nil, err
				}
				store(lua.LNumber(number))
			}
		}
	}
}
