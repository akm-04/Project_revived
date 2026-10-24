package client

import (
	"bytes"
	"compress/zlib"
	"database/sql"
	"encoding/json"
	"fmt"
	"math"
	"sort"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	lua "github.com/yuin/gopher-lua"
	_ "modernc.org/sqlite"
)

// installClock makes os.time() read the virtual clock; os.time(table) keeps its calendar conversion.
func installClock(state *lua.LState, now func() time.Time) {
	system := state.GetField(state.GetGlobal("os"), "time").(*lua.LFunction)
	state.SetField(state.GetGlobal("os"), "time", state.NewFunction(func(state *lua.LState) int {
		if state.GetTop() == 0 {
			state.Push(lua.LNumber(now().Unix()))
			return 1
		}
		state.Push(system)
		state.Push(state.Get(1))
		state.Call(1, 1)
		return 1
	}))
}

func loadSocket(state *lua.LState, now func() time.Time) int {
	module := state.GetGlobal("__proxy")
	state.Push(module)
	state.Push(lua.LString("socket"))
	state.Call(1, 1)
	socket := state.Get(-1).(*lua.LTable)
	socket.RawSetString("gettime", state.NewFunction(func(state *lua.LState) int {
		state.Push(lua.LNumber(float64(now().UnixNano()) / float64(time.Second)))
		return 1
	}))
	return 1
}

// installBit is LuaJIT's global bit library (the subset stock calls): operands and results are signed 32-bit.
func installBit(state *lua.LState) {
	module := state.NewTable()
	binaryOperation := func(operation func(left, right uint32) uint32) lua.LGFunction {
		return func(state *lua.LState) int {
			result := toBit(state.CheckNumber(1))
			for index := 2; index <= state.GetTop(); index++ {
				result = operation(result, toBit(state.CheckNumber(index)))
			}
			state.Push(lua.LNumber(int32(result)))
			return 1
		}
	}
	module.RawSetString("band", state.NewFunction(binaryOperation(func(left, right uint32) uint32 { return left & right })))
	module.RawSetString("bor", state.NewFunction(binaryOperation(func(left, right uint32) uint32 { return left | right })))
	module.RawSetString("bxor", state.NewFunction(binaryOperation(func(left, right uint32) uint32 { return left ^ right })))
	module.RawSetString("lshift", state.NewFunction(binaryOperation(func(left, right uint32) uint32 { return left << (right & 31) })))
	module.RawSetString("rshift", state.NewFunction(binaryOperation(func(left, right uint32) uint32 { return left >> (right & 31) })))
	module.RawSetString("bnot", state.NewFunction(func(state *lua.LState) int {
		state.Push(lua.LNumber(int32(^toBit(state.CheckNumber(1)))))
		return 1
	}))
	state.SetGlobal("bit", module)
	state.SetField(state.GetField(state.GetGlobal("package"), "loaded"), "bit", module)
}

func toBit(number lua.LNumber) uint32 {
	return uint32(int64(math.Floor(float64(number))))
}

// loadZlib is lua-zlib's deflate stream: zlib.deflate()(data, "finish") returns the whole zlib stream.
func loadZlib(state *lua.LState) int {
	module := state.NewTable()
	module.RawSetString("deflate", state.NewFunction(func(state *lua.LState) int {
		state.Push(state.NewFunction(func(state *lua.LState) int {
			var buffer bytes.Buffer
			writer := zlib.NewWriter(&buffer)
			if _, err := writer.Write([]byte(state.CheckString(1))); err != nil {
				state.RaiseError("deflate: %v", err)
			}
			if err := writer.Close(); err != nil {
				state.RaiseError("deflate: %v", err)
			}
			state.Push(lua.LString(buffer.String()))
			state.Push(lua.LTrue)
			return 2
		}))
		return 1
	}))
	state.Push(module)
	return 1
}

var jsonNull = &lua.LUserData{}

// loadJSON is the lua-cjson 2.1 surface stock uses: encode, decode and null. Object keys are sorted so payloads are deterministic.
func loadJSON(state *lua.LState) int {
	module := state.NewTable()
	module.RawSetString("null", jsonNull)
	module.RawSetString("encode", state.NewFunction(func(state *lua.LState) int {
		var buffer strings.Builder
		if err := encodeJSON(&buffer, state.CheckAny(1), 0); err != nil {
			state.RaiseError("%v", err)
		}
		state.Push(lua.LString(buffer.String()))
		return 1
	}))
	module.RawSetString("decode", state.NewFunction(func(state *lua.LState) int {
		decoder := json.NewDecoder(strings.NewReader(state.CheckString(1)))
		decoder.UseNumber()
		var value any
		if err := decoder.Decode(&value); err != nil {
			state.RaiseError("Expected value but found invalid token: %v", err)
		}
		state.Push(toLua(state, value))
		return 1
	}))
	state.Push(module)
	return 1
}

func toLua(state *lua.LState, value any) lua.LValue {
	switch typed := value.(type) {
	case nil:
		return jsonNull
	case bool:
		return lua.LBool(typed)
	case json.Number:
		number, _ := strconv.ParseFloat(string(typed), 64)
		return lua.LNumber(number)
	case float64:
		return lua.LNumber(typed)
	case string:
		return lua.LString(typed)
	case []any:
		table := state.NewTable()
		for _, item := range typed {
			table.Append(toLua(state, item))
		}
		return table
	case map[string]any:
		table := state.NewTable()
		for key, item := range typed {
			table.RawSetString(key, toLua(state, item))
		}
		return table
	}
	return lua.LNil
}

func encodeJSON(buffer *strings.Builder, value lua.LValue, depth int) error {
	if depth > 1000 {
		return fmt.Errorf("Cannot serialise, excessive nesting (%d)", depth)
	}
	switch typed := value.(type) {
	case *lua.LNilType:
		buffer.WriteString("null")
	case lua.LBool:
		buffer.WriteString(strconv.FormatBool(bool(typed)))
	case lua.LNumber:
		return encodeNumber(buffer, float64(typed))
	case lua.LString:
		encodeString(buffer, string(typed))
	case *lua.LUserData:
		if typed != jsonNull {
			return fmt.Errorf("Cannot serialise userdata: type not supported")
		}
		buffer.WriteString("null")
	case *lua.LTable:
		return encodeTable(buffer, typed, depth)
	default:
		return fmt.Errorf("Cannot serialise %s: type not supported", value.Type())
	}
	return nil
}

func encodeNumber(buffer *strings.Builder, number float64) error {
	if math.IsNaN(number) || math.IsInf(number, 0) {
		return fmt.Errorf("Cannot serialise number: must not be NaN or Inf")
	}
	buffer.WriteString(strconv.FormatFloat(number, 'g', 14, 64))
	return nil
}

func encodeString(buffer *strings.Builder, text string) {
	buffer.WriteByte('"')
	for index := 0; index < len(text); index++ {
		character := text[index]
		switch character {
		case '"':
			buffer.WriteString(`\"`)
		case '\\':
			buffer.WriteString(`\\`)
		case '/':
			buffer.WriteString(`\/`)
		case '\n':
			buffer.WriteString(`\n`)
		case '\r':
			buffer.WriteString(`\r`)
		case '\t':
			buffer.WriteString(`\t`)
		case '\b':
			buffer.WriteString(`\b`)
		case '\f':
			buffer.WriteString(`\f`)
		default:
			if character < 0x20 || character == 0x7f {
				fmt.Fprintf(buffer, `\u%04x`, character)
				continue
			}
			buffer.WriteByte(character)
		}
	}
	buffer.WriteByte('"')
}

// encodeTable follows cjson: a table whose keys are exactly 1..n is an array, an empty table is an object.
func encodeTable(buffer *strings.Builder, table *lua.LTable, depth int) error {
	length, count, array := 0, 0, true
	table.ForEach(func(key, _ lua.LValue) {
		count++
		number, ok := key.(lua.LNumber)
		if !ok || float64(number) != math.Trunc(float64(number)) || number < 1 {
			array = false
			return
		}
		length = max(length, int(number))
	})
	if array && count > 0 && length == count {
		buffer.WriteByte('[')
		for index := 1; index <= length; index++ {
			if index > 1 {
				buffer.WriteByte(',')
			}
			if err := encodeJSON(buffer, table.RawGetInt(index), depth+1); err != nil {
				return err
			}
		}
		buffer.WriteByte(']')
		return nil
	}
	type member struct {
		key   string
		value lua.LValue
	}
	var members []member
	var failure error
	table.ForEach(func(key, value lua.LValue) {
		switch typed := key.(type) {
		case lua.LString:
			members = append(members, member{string(typed), value})
		case lua.LNumber:
			members = append(members, member{strconv.FormatFloat(float64(typed), 'g', 14, 64), value})
		default:
			failure = fmt.Errorf("Cannot serialise %s: table key must be a number or string", key.Type())
		}
	})
	if failure != nil {
		return failure
	}
	sort.Slice(members, func(left, right int) bool { return members[left].key < members[right].key })
	buffer.WriteByte('{')
	for index, member := range members {
		if index > 0 {
			buffer.WriteByte(',')
		}
		encodeString(buffer, member.key)
		buffer.WriteByte(':')
		if err := encodeJSON(buffer, member.value, depth+1); err != nil {
			return err
		}
	}
	buffer.WriteByte('}')
	return nil
}

// SQLite result codes lsqlite3 exposes.
const (
	sqliteOK    = 0
	sqliteError = 1
	sqliteRow   = 100
	sqliteDone  = 101
)

type statement struct {
	database  *sql.DB
	query     string
	arguments []any
}

// loadSQLite is the lsqlite3 subset stock storage uses: open, OK, db:exec/isopen/prepare/close and stmt:bind_values/step/reset/nrows.
func (files *fileSystem) loadSQLite(state *lua.LState) int {
	module := state.NewTable()
	for name, code := range map[string]int{"OK": sqliteOK, "ERROR": sqliteError, "ROW": sqliteRow, "DONE": sqliteDone} {
		module.RawSetString(name, lua.LNumber(code))
	}
	statementMethods := state.NewTable()
	statementMethods.RawSetString("bind_values", state.NewFunction(func(state *lua.LState) int {
		current := checkStatement(state)
		current.arguments = current.arguments[:0]
		for index := 2; index <= state.GetTop(); index++ {
			current.arguments = append(current.arguments, sqlValue(state.Get(index)))
		}
		state.Push(lua.LNumber(sqliteOK))
		return 1
	}))
	statementMethods.RawSetString("step", state.NewFunction(func(state *lua.LState) int {
		current := checkStatement(state)
		if current.reads() {
			rows, err := current.database.Query(current.query, current.arguments...)
			if err != nil {
				state.Push(lua.LNumber(sqliteError))
				return 1
			}
			defer rows.Close()
			if rows.Next() {
				state.Push(lua.LNumber(sqliteRow))
				return 1
			}
			state.Push(lua.LNumber(sqliteDone))
			return 1
		}
		if _, err := current.database.Exec(current.query, current.arguments...); err != nil {
			state.Push(lua.LNumber(sqliteError))
			return 1
		}
		state.Push(lua.LNumber(sqliteDone))
		return 1
	}))
	statementMethods.RawSetString("reset", state.NewFunction(func(state *lua.LState) int {
		state.Push(lua.LNumber(sqliteOK))
		return 1
	}))
	statementMethods.RawSetString("finalize", state.NewFunction(func(state *lua.LState) int {
		state.Push(lua.LNumber(sqliteOK))
		return 1
	}))
	statementMethods.RawSetString("nrows", state.NewFunction(func(state *lua.LState) int {
		current := checkStatement(state)
		rows, err := readRows(state, current.database, current.query, current.arguments)
		if err != nil {
			state.RaiseError("nrows: %v", err)
		}
		position := 0
		state.Push(state.NewFunction(func(state *lua.LState) int {
			if position >= len(rows) {
				state.Push(lua.LNil)
				return 1
			}
			position++
			state.Push(rows[position-1])
			return 1
		}))
		return 1
	}))
	statementMetatable := state.NewTable()
	statementMetatable.RawSetString("__index", statementMethods)

	databaseMethods := state.NewTable()
	databaseMethods.RawSetString("isopen", state.NewFunction(func(state *lua.LState) int {
		state.Push(lua.LBool(checkDatabase(state) != nil))
		return 1
	}))
	databaseMethods.RawSetString("exec", state.NewFunction(func(state *lua.LState) int {
		if _, err := checkDatabase(state).Exec(state.CheckString(2)); err != nil {
			state.Push(lua.LNumber(sqliteError))
			return 1
		}
		state.Push(lua.LNumber(sqliteOK))
		return 1
	}))
	databaseMethods.RawSetString("prepare", state.NewFunction(func(state *lua.LState) int {
		userdata := state.NewUserData()
		userdata.Value = &statement{database: checkDatabase(state), query: state.CheckString(2)}
		state.SetMetatable(userdata, statementMetatable)
		state.Push(userdata)
		return 1
	}))
	databaseMethods.RawSetString("close", state.NewFunction(func(state *lua.LState) int {
		state.Push(lua.LNumber(sqliteOK))
		return 1
	}))
	databaseMetatable := state.NewTable()
	databaseMetatable.RawSetString("__index", databaseMethods)

	module.RawSetString("open", state.NewFunction(func(state *lua.LState) int {
		path, err := files.writable(state.CheckString(1))
		if err != nil {
			state.RaiseError("lsqlite3.open: %v", err)
		}
		database, err := sql.Open("sqlite", path)
		if err != nil {
			state.RaiseError("lsqlite3.open: %v", err)
		}
		database.SetMaxOpenConns(1)
		files.databases = append(files.databases, database)
		userdata := state.NewUserData()
		userdata.Value = database
		state.SetMetatable(userdata, databaseMetatable)
		state.Push(userdata)
		return 1
	}))
	state.Push(module)
	return 1
}

func checkDatabase(state *lua.LState) *sql.DB {
	database, ok := state.CheckUserData(1).Value.(*sql.DB)
	if !ok {
		state.ArgError(1, "sqlite database expected")
	}
	return database
}

func checkStatement(state *lua.LState) *statement {
	current, ok := state.CheckUserData(1).Value.(*statement)
	if !ok {
		state.ArgError(1, "sqlite statement expected")
	}
	return current
}

func (current *statement) reads() bool {
	verb := strings.ToUpper(strings.Fields(current.query + " x")[0])
	return verb == "SELECT" || verb == "PRAGMA" || verb == "WITH"
}

func sqlValue(value lua.LValue) any {
	switch typed := value.(type) {
	case lua.LNumber:
		number := float64(typed)
		if number == math.Trunc(number) && math.Abs(number) < 1<<53 {
			return int64(number)
		}
		return number
	case lua.LString:
		return string(typed)
	case lua.LBool:
		if typed {
			return int64(1)
		}
		return int64(0)
	}
	return nil
}

func readRows(state *lua.LState, database *sql.DB, query string, arguments []any) ([]*lua.LTable, error) {
	rows, err := database.Query(query, arguments...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	columns, err := rows.Columns()
	if err != nil {
		return nil, err
	}
	var tables []*lua.LTable
	for rows.Next() {
		values := make([]any, len(columns))
		pointers := make([]any, len(columns))
		for index := range values {
			pointers[index] = &values[index]
		}
		if err := rows.Scan(pointers...); err != nil {
			return nil, err
		}
		table := state.NewTable()
		for index, column := range columns {
			table.RawSetString(column, sqlToLua(values[index]))
		}
		tables = append(tables, table)
	}
	return tables, rows.Err()
}

func sqlToLua(value any) lua.LValue {
	switch typed := value.(type) {
	case int64:
		return lua.LNumber(typed)
	case float64:
		return lua.LNumber(typed)
	case string:
		return lua.LString(typed)
	case []byte:
		if utf8.Valid(typed) {
			return lua.LString(typed)
		}
		return lua.LString(string(typed))
	}
	return lua.LNil
}
