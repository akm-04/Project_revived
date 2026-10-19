// Package combatresolver executes the pinned source battle engine for one frozen
// snapshot inside the isolated worker process. It has no database, network,
// filesystem, subprocess or wall-clock access: os.time is the frozen decision
// instant and math.random is the attempt entropy stream.
package combatresolver

import (
	"bytes"
	_ "embed"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"

	lua "github.com/yuin/gopher-lua"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/combat"
)

//go:embed bootstrap.lua
var bootstrapLua string

//go:embed driver.lua
var driverLua string

// SparseArrayLimit is the qualified VM profile for sparse numeric source IDs.
const SparseArrayLimit = 65536

// CollectionAttrTypes is the attr-type range of NormalHero.getWhiteAlbumForce's #albumAttr loop.
const CollectionAttrTypes = 49

// ErrDeterministic marks failures that rerunning identical inputs reproduces.
var ErrDeterministic = errors.New("combat resolver: deterministic failure")

type Result struct {
	Outcome        combat.Outcome
	Report         []byte
	EntropyDraws   uint64
	EntropyReseeds uint64
}

type machine struct {
	state  *lua.LState
	corpus *combatcorpus.Corpus
	stream *combat.Stream
}

func deterministic(format string, args ...any) error {
	return fmt.Errorf("%w: %s", ErrDeterministic, fmt.Sprintf(format, args...))
}

// Resolve runs one fight. Every returned error wraps ErrDeterministic; a crash,
// timeout or resource kill never returns and is classified by the launcher.
func Resolve(corpus *combatcorpus.Corpus, snapshot combat.Snapshot, root [32]byte) (Result, error) {
	m, err := newMachine(corpus, snapshot, root)
	if err != nil {
		return Result{}, err
	}
	defer m.state.Close()
	if err = m.run(driverLua, "combat driver"); err != nil {
		return Result{}, err
	}
	output, ok := m.state.GetGlobal("combat_output").(*lua.LTable)
	if !ok {
		return Result{}, deterministic("battle produced no output")
	}
	report, ok := output.RawGetString("report").(lua.LString)
	star, okStar := output.RawGetString("star").(lua.LNumber)
	frames, okFrames := output.RawGetString("frames").(lua.LNumber)
	if !ok || !okStar || !okFrames || len(report) == 0 {
		return Result{}, deterministic("battle output shape")
	}
	return Result{
		Outcome:        combat.Outcome{Star: int64(star), Frames: int64(frames), TimedOut: lua.LVAsBool(output.RawGetString("timed_out")), ReportError: lua.LVAsBool(output.RawGetString("report_error"))},
		Report:         []byte(report),
		EntropyDraws:   m.stream.Draws,
		EntropyReseeds: m.stream.Reseeds,
	}, nil
}

// EvaluateActors returns each actor's VM battle totals (getBattleAttr for attr
// types 1..49) after setupBattleAttrInfo, for the 3B differential oracle.
func EvaluateActors(corpus *combatcorpus.Corpus, snapshot combat.Snapshot) ([]map[int]float64, error) {
	m, err := newMachine(corpus, snapshot, [32]byte{1})
	if err != nil {
		return nil, err
	}
	defer m.state.Close()
	if err = m.run(`combat_totals=combat_evaluate_actors()`, "combat totals"); err != nil {
		return nil, err
	}
	rows, ok := m.state.GetGlobal("combat_totals").(*lua.LTable)
	if !ok {
		return nil, deterministic("totals shape")
	}
	out := []map[int]float64{}
	for i := 1; i <= rows.Len(); i++ {
		row := map[int]float64{}
		rows.RawGetInt(i).(*lua.LTable).ForEach(func(k, v lua.LValue) { row[int(k.(lua.LNumber))] = float64(v.(lua.LNumber)) })
		out = append(out, row)
	}
	return out, nil
}

func (m *machine) run(code, name string) (err error) {
	defer func() {
		if r := recover(); r != nil {
			err = deterministic("%s panic: %v", name, r)
		}
	}()
	fn, err := m.state.Load(strings.NewReader(code), name)
	if err != nil {
		return deterministic("%s load: %v", name, err)
	}
	m.state.Push(fn)
	if err = m.state.PCall(0, 0, nil); err != nil {
		return deterministic("%s: %v", name, err)
	}
	return nil
}

func newMachine(corpus *combatcorpus.Corpus, snapshot combat.Snapshot, root [32]byte) (*machine, error) {
	if snapshot.CorpusID != corpus.ID() || snapshot.SourceArchiveSHA256 != corpus.SourceArchiveSHA256() || snapshot.Validate() != nil {
		return nil, deterministic("snapshot does not match the embedded corpus")
	}
	lua.MaxArrayIndex = SparseArrayLimit
	state := lua.NewState(lua.Options{SkipOpenLibs: true})
	m := &machine{state: state, corpus: corpus, stream: combat.NewStream(root)}
	for _, lib := range []struct {
		name string
		open lua.LGFunction
	}{{lua.LoadLibName, lua.OpenPackage}, {lua.BaseLibName, lua.OpenBase}, {lua.TabLibName, lua.OpenTable}, {lua.StringLibName, lua.OpenString}, {lua.MathLibName, lua.OpenMath}, {lua.CoroutineLibName, lua.OpenCoroutine}} {
		state.Push(state.NewFunction(lib.open))
		state.Push(lua.LString(lib.name))
		state.Call(1, 0)
	}
	pkg := state.GetGlobal("package").(*lua.LTable)
	loaders := state.GetField(pkg, "loaders").(*lua.LTable)
	for i := loaders.Len(); i >= 2; i-- {
		loaders.RawSetInt(i, lua.LNil)
	}
	preload := state.GetField(pkg, "preload").(*lua.LTable)
	for _, record := range corpus.Manifest().Modules {
		name := record.Name
		state.SetField(preload, name, state.NewFunction(func(l *lua.LState) int {
			source, _ := corpus.Module(name)
			fn, err := l.Load(strings.NewReader(strings.TrimPrefix(source, "\ufeff")), name)
			if err != nil {
				l.RaiseError("%s", err)
				return 0
			}
			l.Push(fn)
			l.Call(0, 1)
			return 1
		}))
	}
	parser := state.NewTable()
	state.SetField(parser, "parse", state.NewFunction(m.parseTable))
	parserModule := state.NewFunction(func(l *lua.LState) int { l.Push(parser); return 1 })
	state.SetField(preload, "lib.battle.app.common.tables.TableParser", parserModule)
	state.SetField(preload, "app.common.tables.TableParser", parserModule)
	m.installEntropy(snapshot)
	state.SetGlobal("combat_json_encode", state.NewFunction(func(l *lua.LState) int {
		v, err := toJSON(l.CheckAny(1), 0)
		if err != nil {
			l.RaiseError("%s", err)
			return 0
		}
		raw, err := json.Marshal(v)
		if err != nil {
			l.RaiseError("%s", err)
			return 0
		}
		l.Push(lua.LString(raw))
		return 1
	}))
	input, err := inputTable(state, snapshot)
	if err != nil {
		state.Close()
		return nil, err
	}
	state.SetGlobal("combat_input", input)
	if err = m.run(bootstrapLua, "combat bootstrap"); err != nil {
		state.Close()
		return nil, err
	}
	return m, nil
}

func (m *machine) installEntropy(snapshot combat.Snapshot) {
	state := m.state
	math := state.GetGlobal("math").(*lua.LTable)
	state.SetField(math, "random", state.NewFunction(func(l *lua.LState) int {
		var value int64
		var err error
		switch l.GetTop() {
		case 0:
			l.Push(lua.LNumber(m.stream.Float()))
			return 1
		case 1:
			value, err = m.stream.Between(1, float64(l.CheckNumber(1)))
		case 2:
			value, err = m.stream.Between(float64(l.CheckNumber(1)), float64(l.CheckNumber(2)))
		default:
			err = combat.ErrRandomRange
		}
		if err != nil {
			l.RaiseError("%s", err)
			return 0
		}
		l.Push(lua.LNumber(value))
		return 1
	}))
	state.SetField(math, "randomseed", state.NewFunction(func(l *lua.LState) int {
		if err := m.stream.Reseed(float64(l.CheckNumber(1))); err != nil {
			l.RaiseError("%s", err)
		}
		return 0
	}))
	osTime := snapshot.OSTime()
	clock := state.NewTable()
	state.SetField(clock, "time", state.NewFunction(func(l *lua.LState) int {
		if l.GetTop() != 0 {
			l.RaiseError("COMBAT_ADAPTER_OS_TIME_ARGUMENTS_UNSUPPORTED")
			return 0
		}
		l.Push(lua.LNumber(osTime))
		return 1
	}))
	// Virtual CPU clock: the only source use reseeds a fighter-local stream.
	state.SetField(clock, "clock", state.NewFunction(func(l *lua.LState) int { l.Push(lua.LNumber(0)); return 1 }))
	state.SetGlobal("combat_os", clock)
}

// parseTable is the server TableParser seam: INDEXED rows go to the callback
// with their keys in ascending row-ID order, NAMED rows alone in source order.
func (m *machine) parseTable(l *lua.LState) int {
	name := strings.TrimSuffix(l.CheckString(1), ".lua")
	callback := l.CheckFunction(2)
	table, err := m.corpus.Table(name)
	if err != nil {
		l.RaiseError("%s", err)
		return 0
	}
	var keys lua.LValue = lua.LNil
	if table.Kind == "INDEXED" {
		k := l.NewTable()
		for field, index := range table.Keys {
			k.RawSetString(field, lua.LNumber(index))
		}
		keys = k
	}
	for _, raw := range table.Rows {
		row, err := decodeRow(l, table.Kind, raw)
		if err != nil {
			l.RaiseError("table %s: %s", name, err)
			return 0
		}
		l.Push(callback)
		l.Push(row)
		args := 1
		if table.Kind == "INDEXED" {
			l.Push(keys)
			args = 2
		}
		l.Call(args, 0)
	}
	return 0
}

func decodeRow(l *lua.LState, kind string, raw json.RawMessage) (*lua.LTable, error) {
	t := l.NewTable()
	if kind == "INDEXED" {
		var values []string
		if err := json.Unmarshal(raw, &values); err != nil {
			return nil, err
		}
		for i, v := range values {
			t.RawSetInt(i+1, lua.LString(v))
		}
		return t, nil
	}
	var fields map[string]string
	if err := json.Unmarshal(raw, &fields); err != nil {
		return nil, err
	}
	for k, v := range fields {
		t.RawSetString(k, lua.LString(v))
	}
	return t, nil
}

func fromJSON(l *lua.LState, raw json.RawMessage) (lua.LValue, error) {
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.UseNumber()
	var v any
	if err := decoder.Decode(&v); err != nil {
		return nil, err
	}
	return luaValue(l, v)
}

func luaValue(l *lua.LState, v any) (lua.LValue, error) {
	switch x := v.(type) {
	case nil:
		return lua.LNil, nil
	case bool:
		return lua.LBool(x), nil
	case string:
		return lua.LString(x), nil
	case json.Number:
		f, err := strconv.ParseFloat(string(x), 64)
		return lua.LNumber(f), err
	case []any:
		t := l.NewTable()
		for i, item := range x {
			value, err := luaValue(l, item)
			if err != nil {
				return nil, err
			}
			t.RawSetInt(i+1, value)
		}
		return t, nil
	case map[string]any:
		t := l.NewTable()
		for k, item := range x {
			value, err := luaValue(l, item)
			if err != nil {
				return nil, err
			}
			t.RawSetString(k, value)
		}
		return t, nil
	}
	return nil, deterministic("unsupported params value %T", v)
}

func actorList(l *lua.LState, actors []combat.Actor) (*lua.LTable, error) {
	list := l.NewTable()
	for _, a := range actors {
		params, err := fromJSON(l, a.Params)
		if err != nil {
			return nil, deterministic("actor params: %v", err)
		}
		row := l.NewTable()
		row.RawSetString("kind", lua.LString(a.Kind))
		row.RawSetString("player", lua.LNumber(a.Player))
		row.RawSetString("params", params)
		list.Append(row)
	}
	return list, nil
}

func inputTable(l *lua.LState, s combat.Snapshot) (*lua.LTable, error) {
	in := l.NewTable()
	in.RawSetString("os_time", lua.LNumber(s.OSTime()))
	in.RawSetString("campaign_type", lua.LNumber(s.Battle.CampaignType))
	in.RawSetString("battle_id", lua.LNumber(s.Battle.BattleID))
	scenePlayer := int64(0)
	for _, a := range s.Battle.TeamA {
		if a.Player > 0 {
			scenePlayer = a.Player
			break
		}
	}
	in.RawSetString("scene_player", lua.LNumber(scenePlayer))
	for name, actors := range map[string][]combat.Actor{"team_a": s.Battle.TeamA, "pets_a": s.Battle.PetsA, "pets_b": s.Battle.PetsB} {
		list, err := actorList(l, actors)
		if err != nil {
			return nil, err
		}
		in.RawSetString(name, list)
	}
	waves := l.NewTable()
	for _, wave := range s.Battle.WavesB {
		list, err := actorList(l, wave)
		if err != nil {
			return nil, err
		}
		waves.Append(list)
	}
	in.RawSetString("waves_b", waves)
	players := l.NewTable()
	for _, p := range s.Players {
		album := l.NewTable()
		for attr := 1; attr <= CollectionAttrTypes; attr++ {
			album.RawSetInt(attr, lua.LNumber(0))
		}
		for k, v := range p.CollectionHundredths {
			attr, err := strconv.Atoi(k)
			if err != nil || attr < 1 || attr > CollectionAttrTypes {
				return nil, deterministic("collection attr type %q", k)
			}
			album.RawSetInt(attr, lua.LNumber(float64(v)/100))
		}
		books := l.NewTable()
		for k, v := range p.ExclusiveBooks {
			id, err := strconv.ParseInt(k, 10, 64)
			if err != nil {
				return nil, deterministic("exclusive book %q", k)
			}
			books.RawSetInt(int(id), lua.LNumber(v))
		}
		row := l.NewTable()
		row.RawSetString("album", album)
		row.RawSetString("books", books)
		players.RawSetInt(int(p.Player), row)
	}
	in.RawSetString("players", players)
	return in, nil
}

// toJSON is the cjson.encode seam: sequences become arrays, other tables
// objects with stringified keys; non-finite numbers and functions are refused.
func toJSON(v lua.LValue, depth int) (any, error) {
	if depth > 64 {
		return nil, deterministic("report nesting too deep")
	}
	switch x := v.(type) {
	case *lua.LNilType:
		return nil, nil
	case lua.LBool:
		return bool(x), nil
	case lua.LString:
		return string(x), nil
	case lua.LNumber:
		f := float64(x)
		if math.IsNaN(f) || math.IsInf(f, 0) {
			return nil, deterministic("non-finite report number")
		}
		return f, nil
	case *lua.LTable:
		count, maxIndex, sequence := 0, 0, true
		x.ForEach(func(k, _ lua.LValue) {
			count++
			n, ok := k.(lua.LNumber)
			if !ok || n < 1 || float64(n) != math.Trunc(float64(n)) {
				sequence = false
				return
			}
			if int(n) > maxIndex {
				maxIndex = int(n)
			}
		})
		if sequence && count > 0 && maxIndex == count {
			out := make([]any, count)
			for i := 1; i <= count; i++ {
				item, err := toJSON(x.RawGetInt(i), depth+1)
				if err != nil {
					return nil, err
				}
				out[i-1] = item
			}
			return out, nil
		}
		out := map[string]any{}
		var failure error
		x.ForEach(func(k, item lua.LValue) {
			if failure != nil {
				return
			}
			key := k.String()
			if _, duplicate := out[key]; duplicate {
				failure = deterministic("report key collision %q", key)
				return
			}
			value, err := toJSON(item, depth+1)
			if err != nil {
				failure = err
				return
			}
			out[key] = value
		})
		return out, failure
	}
	return nil, deterministic("report value type %s", v.Type())
}
