// Runs a Lua 5.1 test with a cjson module backed by encoding/json. The runner is
// test infrastructure only: it gives the Lua adapter the same encode/decode and
// null-sentinel contract the client's cjson provides.
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"

	lua "github.com/yuin/gopher-lua"
)

type cjsonNull struct{}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: cjson_runner <test.lua>")
		os.Exit(2)
	}
	state := lua.NewState()
	defer state.Close()
	null := state.NewUserData()
	null.Value = cjsonNull{}
	cjson := state.NewTable()
	cjson.RawSetString("null", null)
	cjson.RawSetString("encode", state.NewFunction(func(state *lua.LState) int {
		value, err := toGo(state.Get(1), null)
		if err != nil {
			state.RaiseError("%v", err)
			return 0
		}
		data, err := json.Marshal(value)
		if err != nil {
			state.RaiseError("%v", err)
			return 0
		}
		state.Push(lua.LString(data))
		return 1
	}))
	cjson.RawSetString("decode", state.NewFunction(func(state *lua.LState) int {
		decoder := json.NewDecoder(strings.NewReader(state.CheckString(1)))
		decoder.UseNumber()
		var raw any
		if err := decoder.Decode(&raw); err != nil {
			state.RaiseError("%v", err)
			return 0
		}
		state.Push(fromGo(state, raw, null))
		return 1
	}))
	state.SetGlobal("cjson", cjson)
	if err := state.DoString(`package.preload["cjson"] = function() return cjson end`); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	if err := state.DoFile(os.Args[1]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func toGo(value lua.LValue, null *lua.LUserData) (any, error) {
	switch typed := value.(type) {
	case *lua.LNilType:
		return nil, nil
	case lua.LBool:
		return bool(typed), nil
	case lua.LNumber:
		return float64(typed), nil
	case lua.LString:
		return string(typed), nil
	case *lua.LUserData:
		if typed == null {
			return nil, nil
		}
		return nil, fmt.Errorf("unsupported userdata")
	case *lua.LTable:
		count := 0
		array := true
		typed.ForEach(func(key, _ lua.LValue) {
			count++
			number, ok := key.(lua.LNumber)
			if !ok || float64(number) != float64(int64(number)) || int64(number) < 1 || int64(number) > int64(count) {
				array = false
			}
		})
		if array && count > 0 {
			out := make([]any, count)
			for index := 1; index <= count; index++ {
				item, err := toGo(typed.RawGetInt(index), null)
				if err != nil {
					return nil, err
				}
				out[index-1] = item
			}
			return out, nil
		}
		out := make(map[string]any, count)
		var convertError error
		typed.ForEach(func(key, item lua.LValue) {
			if convertError != nil {
				return
			}
			name, ok := key.(lua.LString)
			if !ok {
				convertError = fmt.Errorf("object key must be a string")
				return
			}
			converted, err := toGo(item, null)
			if err != nil {
				convertError = err
				return
			}
			out[string(name)] = converted
		})
		return out, convertError
	}
	return nil, fmt.Errorf("unsupported value %T", value)
}

func fromGo(state *lua.LState, value any, null *lua.LUserData) lua.LValue {
	switch typed := value.(type) {
	case nil:
		return null
	case bool:
		return lua.LBool(typed)
	case string:
		return lua.LString(typed)
	case json.Number:
		number, err := typed.Float64()
		if err != nil {
			return lua.LNil
		}
		return lua.LNumber(number)
	case float64:
		return lua.LNumber(typed)
	case []any:
		table := state.NewTable()
		for _, item := range typed {
			table.Append(fromGo(state, item, null))
		}
		return table
	case map[string]any:
		table := state.NewTable()
		for key, item := range typed {
			table.RawSetString(key, fromGo(state, item, null))
		}
		return table
	}
	return lua.LNil
}
