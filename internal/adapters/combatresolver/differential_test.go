package combatresolver

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"maps"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"slices"
	"strconv"
	"strings"
	"testing"
	"time"

	lua "github.com/yuin/gopher-lua"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/combat"
)

// I8-2A: GopherLua against the fallback Lua 5.1 adapter (bundled LuaJIT
// 2.1.0-beta3, -joff) over the same corpus, input and entropy tape.
// GXB_LUAJIT names the interpreter; the gate is not run without it.

func luajitBinary(t *testing.T) string {
	path := os.Getenv("GXB_LUAJIT")
	if path == "" {
		t.Skip("GXB_LUAJIT unset: LuaJIT differential oracle not run")
	}
	return path
}

func token(b *bytes.Buffer, s string) { fmt.Fprintf(b, "%d:%s", len(s), s) }

func number(f float64) string { return strconv.FormatFloat(f, 'g', -1, 64) }

func luaString(b *bytes.Buffer, s string) {
	b.WriteByte('"')
	for i := 0; i < len(s); i++ {
		c := s[i]
		switch {
		case c == '"' || c == '\\':
			b.WriteByte('\\')
			b.WriteByte(c)
		case c < 32 || c >= 127:
			fmt.Fprintf(b, "\\%03d", c)
		default:
			b.WriteByte(c)
		}
	}
	b.WriteByte('"')
}

// luaLiteral writes a GopherLua value as LuaJIT source with exact numbers.
func luaLiteral(b *bytes.Buffer, v lua.LValue) error {
	switch x := v.(type) {
	case lua.LBool:
		b.WriteString(strconv.FormatBool(bool(x)))
	case lua.LNumber:
		b.WriteString("(" + number(float64(x)) + ")")
	case lua.LString:
		luaString(b, string(x))
	case *lua.LTable:
		b.WriteByte('{')
		var failure error
		x.ForEach(func(k, item lua.LValue) {
			if failure != nil {
				return
			}
			b.WriteByte('[')
			if failure = luaLiteral(b, k); failure != nil {
				return
			}
			b.WriteString("]=")
			if failure = luaLiteral(b, item); failure == nil {
				b.WriteString(",\n")
			}
		})
		b.WriteByte('}')
		return failure
	default:
		return fmt.Errorf("input value type %s", v.Type())
	}
	return nil
}

// exportCorpus writes modules, decoded tables and the adapter sources the
// oracle reads, in the shapes the GopherLua seams hand to the engine.
func exportCorpus(t *testing.T, corpus *combatcorpus.Corpus) string {
	dir := t.TempDir()
	for _, sub := range []string{"modules", "tables"} {
		if err := os.Mkdir(filepath.Join(dir, sub), 0o755); err != nil {
			t.Fatal(err)
		}
	}
	index := &bytes.Buffer{}
	for _, record := range corpus.Manifest().Modules {
		source, _ := corpus.Module(record.Name)
		token(index, record.Name)
		writeFile(t, filepath.Join(dir, "modules", record.Name+".lua"), []byte(source))
	}
	writeFile(t, filepath.Join(dir, "modules.idx"), index.Bytes())
	for _, record := range corpus.Manifest().Tables {
		table, err := corpus.Table(record.Name)
		if err != nil {
			t.Fatal(err)
		}
		writeFile(t, filepath.Join(dir, "tables", record.Name+".tbl"), tableTokens(t, table))
	}
	writeFile(t, filepath.Join(dir, "bootstrap.lua"), []byte(bootstrapLua))
	writeFile(t, filepath.Join(dir, "transforms.lua"), []byte(transformsLua))
	writeFile(t, filepath.Join(dir, "driver.lua"), []byte(driverLua))
	return dir
}

func tableTokens(t *testing.T, table *combatcorpus.Table) []byte {
	b := &bytes.Buffer{}
	token(b, table.Kind)
	if table.Kind == "INDEXED" {
		token(b, strconv.Itoa(len(table.Keys)))
		for _, field := range slices.Sorted(maps.Keys(table.Keys)) {
			token(b, field)
			token(b, strconv.Itoa(table.Keys[field]))
		}
	}
	token(b, strconv.Itoa(len(table.Rows)))
	for _, raw := range table.Rows {
		if table.Kind == "INDEXED" {
			var values []string
			if err := json.Unmarshal(raw, &values); err != nil {
				t.Fatal(err)
			}
			token(b, strconv.Itoa(len(values)))
			for _, v := range values {
				token(b, v)
			}
			continue
		}
		var fields map[string]string
		if err := json.Unmarshal(raw, &fields); err != nil {
			t.Fatal(err)
		}
		token(b, strconv.Itoa(len(fields)))
		for _, k := range slices.Sorted(maps.Keys(fields)) {
			token(b, k)
			token(b, fields[k])
		}
	}
	return b.Bytes()
}

func writeFile(t *testing.T, path string, data []byte) {
	if err := os.WriteFile(path, data, 0o644); err != nil {
		t.Fatal(err)
	}
}

// recordTape wraps the entropy functions so every call and its result is
// replayed to the oracle in order.
func recordTape(m *machine) *bytes.Buffer {
	tape := &bytes.Buffer{}
	mathTable := m.state.GetGlobal("math").(*lua.LTable)
	for _, op := range []string{"random", "randomseed"} {
		original := m.state.GetField(mathTable, op).(*lua.LFunction).GFunction
		m.state.SetField(mathTable, op, m.state.NewFunction(func(l *lua.LState) int {
			args := make([]string, l.GetTop())
			for i := range args {
				args[i] = number(float64(l.ToNumber(i + 1)))
			}
			results := original(l)
			token(tape, op)
			token(tape, strconv.Itoa(len(args)))
			for _, a := range args {
				token(tape, a)
			}
			result := "0"
			if results == 1 {
				result = number(float64(l.Get(-1).(lua.LNumber)))
			}
			token(tape, result)
			return results
		}))
	}
	return tape
}

type oracleOutcome struct {
	Error       string  `json:"error"`
	Divergence  string  `json:"divergence"`
	TapeUsed    int     `json:"tape_used"`
	TapeSize    int     `json:"tape_size"`
	Star        float64 `json:"star"`
	Frames      float64 `json:"frames"`
	TimedOut    bool    `json:"timed_out"`
	ReportError bool    `json:"report_error"`
}

func runOracle(t *testing.T, dir, mode string) time.Duration {
	started := time.Now()
	cmd := exec.Command(luajitBinary(t), "-joff", filepath.Join(mustAbs(t, "testdata"), "luajit_oracle.lua"), dir, mode)
	cmd.Env = []string{}
	output, err := cmd.CombinedOutput()
	if err != nil && mode == "fight" {
		t.Fatalf("oracle: %v\n%s", err, output)
	}
	return time.Since(started)
}

func mustAbs(t *testing.T, path string) string {
	abs, err := filepath.Abs(path)
	if err != nil {
		t.Fatal(err)
	}
	return abs
}

func writeInput(t *testing.T, dir string, s combat.Snapshot) {
	state := lua.NewState(lua.Options{SkipOpenLibs: true})
	defer state.Close()
	input, err := inputTable(state, s)
	if err != nil {
		t.Fatal(err)
	}
	b := bytes.NewBufferString("return ")
	if err = luaLiteral(b, input); err != nil {
		t.Fatal(err)
	}
	writeFile(t, filepath.Join(dir, "input.lua"), b.Bytes())
}

// differential resolves one fight under both engines and requires the same
// canonical report bytes, outcome and full tape consumption.
func differential(t *testing.T, dir string, corpus *combatcorpus.Corpus, s combat.Snapshot, root [32]byte) {
	m, err := newMachine(corpus, s, root)
	if err != nil {
		t.Fatal(err)
	}
	defer m.state.Close()
	if m.stream.Draws != 0 || m.stream.Reseeds != 0 {
		t.Fatal("bootstrap consumed entropy before the tape recorder")
	}
	tape := recordTape(m)
	started := time.Now()
	gopher, err := m.resolve()
	if err != nil {
		t.Fatal(err)
	}
	gopherTime := time.Since(started)
	writeInput(t, dir, s)
	writeFile(t, filepath.Join(dir, "tape.tok"), tape.Bytes())
	oracleTime := runOracle(t, dir, "fight")
	var outcome oracleOutcome
	if err = json.Unmarshal(readFile(t, filepath.Join(dir, "luajit_outcome.json")), &outcome); err != nil {
		t.Fatal(err)
	}
	if outcome.Error != "" || outcome.Divergence != "" {
		t.Fatalf("oracle failed: %s %s", outcome.Error, outcome.Divergence)
	}
	draws := int(gopher.EntropyDraws)
	t.Logf("gopher %s luajit -joff %s; outcome %+v; tape %d/%d; draws %d reseeds %d; report %s",
		gopherTime.Round(time.Millisecond), oracleTime.Round(time.Millisecond), gopher.Outcome, outcome.TapeUsed, outcome.TapeSize, draws, gopher.EntropyReseeds, combat.ReportHash(gopher.Report))
	if outcome.TapeUsed != outcome.TapeSize {
		t.Errorf("oracle consumed %d of %d tape entries", outcome.TapeUsed, outcome.TapeSize)
	}
	want := combat.Outcome{Star: int64(outcome.Star), Frames: int64(outcome.Frames), TimedOut: outcome.TimedOut, ReportError: outcome.ReportError}
	if gopher.Outcome != want {
		t.Errorf("outcome gopher %+v luajit %+v", gopher.Outcome, want)
	}
	var oracleReport any
	if err = json.Unmarshal(readFile(t, filepath.Join(dir, "luajit_report.json")), &oracleReport); err != nil {
		t.Fatal(err)
	}
	canonical, err := json.Marshal(oracleReport)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(canonical, gopher.Report) {
		var gopherReport any
		_ = json.Unmarshal(gopher.Report, &gopherReport)
		t.Errorf("report differs at %s", firstDifference("$", gopherReport, oracleReport))
	}
}

func readFile(t *testing.T, path string) []byte {
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	return data
}

func firstDifference(path string, a, b any) string {
	if reflect.DeepEqual(a, b) {
		return ""
	}
	am, aMap := a.(map[string]any)
	bm, bMap := b.(map[string]any)
	if aMap && bMap {
		for _, k := range slices.Sorted(maps.Keys(am)) {
			if found := firstDifference(path+"."+k, am[k], bm[k]); found != "" {
				return found
			}
		}
		for _, k := range slices.Sorted(maps.Keys(bm)) {
			if _, ok := am[k]; !ok {
				return fmt.Sprintf("%s.%s: gopher absent, luajit %v", path, k, bm[k])
			}
		}
	}
	as, aSlice := a.([]any)
	bs, bSlice := b.([]any)
	if aSlice && bSlice && len(as) == len(bs) {
		for i := range as {
			if found := firstDifference(fmt.Sprintf("%s[%d]", path, i), as[i], bs[i]); found != "" {
				return found
			}
		}
	}
	return fmt.Sprintf("%s: gopher %.300v luajit %.300v", path, a, b)
}

func templatePet(t testing.TB, tableID int64) combat.Actor {
	params, err := combat.CanonicalJSON(map[string]any{"player_id": 0, "pet_id": tableID, "table_id": tableID, "star": 3, "lev": 20, "color": 2, "skills": []any{1, 1, 1, 1, 1}})
	if err != nil {
		t.Fatal(err)
	}
	corpus, _ := combatcorpus.Load()
	class, _, _ := corpus.FighterClass("pet", tableID)
	return combat.Actor{Origin: combat.Template, Kind: combat.PetActor, Identity: tableID, TableID: tableID, FighterClass: class, Params: params}
}

func TestLuaJITDifferential(t *testing.T) {
	luajitBinary(t)
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	dir := exportCorpus(t, corpus)
	root := sha256.Sum256([]byte("i8-2a-differential-root"))
	hero := func(id int64) combat.Actor { return TemplateHero(t, id, 3, 20, 2) }
	t.Run("H-17 load proof", func(t *testing.T) {
		loadProof(t, dir, corpus)
	})
	t.Run("table.sort tie order", func(t *testing.T) {
		sortTieOrder(t, corpus)
	})
	t.Run("H-18 basic fight", func(t *testing.T) {
		s := templateSnapshot(t, []combat.Actor{hero(10001001), hero(10001040)}, []combat.Actor{hero(10001002)})
		differential(t, dir, corpus, s, root)
	})
	t.Run("H-19 time-seeded random target fighters", func(t *testing.T) {
		// Lvlingqi and Change reseed from os.time()+timeSeed_; Fububanzang from os.clock().
		s := templateSnapshot(t, []combat.Actor{hero(10001122), hero(10001042)}, []combat.Actor{hero(10001070), hero(10001002)})
		differential(t, dir, corpus, s, root)
	})
	t.Run("H-20 template pet fight", func(t *testing.T) {
		s := templateSnapshot(t, []combat.Actor{hero(10001001)}, []combat.Actor{hero(10001002)})
		s.Battle.PetsA, s.Battle.PetsB = []combat.Actor{templatePet(t, 10010001)}, []combat.Actor{templatePet(t, 10020001)}
		differential(t, dir, corpus, s, root)
	})
	t.Run("mirror match sort ties", func(t *testing.T) {
		team := []combat.Actor{hero(10001001), hero(10001040), hero(10001002), hero(10001122), hero(10001042)}
		s := templateSnapshot(t, team, team)
		differential(t, dir, corpus, s, root)
	})
	t.Run("SUPER_ARENA round", func(t *testing.T) {
		s := templateSnapshot(t, []combat.Actor{hero(10001001)}, []combat.Actor{hero(10001002)})
		s.Battle.CampaignType, s.Battle.BattleID = 65, 114001
		s.Battle.Context = &combat.BattleContext{Transform: "SUPER_ARENA_ROUND_V1"}
		differential(t, dir, corpus, s, root)
	})
	t.Run("REGION_ARENA battle with season awards", func(t *testing.T) {
		award := func(id int64, transform string) combat.Actor {
			a := hero(id)
			a.Transform = json.RawMessage(transform)
			return a
		}
		s := templateSnapshot(t, []combat.Actor{award(10001001, `{"arena_add_star":2,"arena_awake":1}`), hero(10001040)},
			[]combat.Actor{award(10001002, `{"arena_add_star":3,"arena_awake":1}`), hero(10001070)})
		s.Battle.CampaignType, s.Battle.BattleID = 45, 111001
		s.Battle.PetsA, s.Battle.PetsB = []combat.Actor{templatePet(t, 10010001)}, []combat.Actor{templatePet(t, 10020001)}
		s.Battle.Context = &combat.BattleContext{Transform: "REGION_ARENA_SEASON_AWARDS_V1"}
		differential(t, dir, corpus, s, root)
	})
	t.Run("I8-3B genuine owned fight", func(t *testing.T) {
		// Frozen on R2 by TestI8_3BGenuineFullLiveOwnedSnapshotNative (GXB_I8_3B_SNAPSHOT_OUT).
		raw := readFile(t, filepath.Join("testdata", "i8_3b_owned_snapshot.json"))
		sum := sha256.Sum256(raw)
		s, err := combat.DecodeSnapshot(raw, hex.EncodeToString(sum[:]))
		if err != nil {
			t.Fatal(err)
		}
		differential(t, dir, corpus, s, root)
	})
	t.Run("H-20 I8-6A borrowed Hero and Pet", func(t *testing.T) {
		_, borrowed := borrowedGenuine(t)
		differential(t, dir, corpus, borrowed, root)
	})
}

// loadProof requires every corpus module to give the same require outcome
// under both engines in the bootstrap environment, in manifest order.
func loadProof(t *testing.T, dir string, corpus *combatcorpus.Corpus) {
	s := templateSnapshot(t, []combat.Actor{TemplateHero(t, 10001001, 1, 1, 1)}, []combat.Actor{TemplateHero(t, 10001002, 1, 1, 1)})
	m, err := newMachine(corpus, s, [32]byte{1})
	if err != nil {
		t.Fatal(err)
	}
	defer m.state.Close()
	names := m.state.NewTable()
	for _, record := range corpus.Manifest().Modules {
		names.Append(lua.LString(record.Name))
	}
	m.state.SetGlobal("load_names", names)
	if err = m.run(`load_results = {}
for _, name in ipairs(load_names) do load_results[name] = pcall(require, name) end`, "load proof"); err != nil {
		t.Fatal(err)
	}
	gopher := map[string]bool{}
	m.state.GetGlobal("load_results").(*lua.LTable).ForEach(func(k, v lua.LValue) { gopher[k.String()] = lua.LVAsBool(v) })
	writeInput(t, dir, s)
	writeFile(t, filepath.Join(dir, "tape.tok"), nil)
	runOracle(t, dir, "load")
	var luajit map[string]bool
	if err = json.Unmarshal(readFile(t, filepath.Join(dir, "luajit_load.json")), &luajit); err != nil {
		t.Fatal(err)
	}
	loaded, differing := 0, []string{}
	for name, ok := range gopher {
		if ok {
			loaded++
		}
		if luajit[name] != ok {
			differing = append(differing, name)
		}
	}
	slices.Sort(differing)
	t.Logf("modules %d; loaded under both %d; not loadable outside a client scene under both %d", len(gopher), loaded, len(gopher)-loaded-len(differing))
	if len(gopher) != len(corpus.Manifest().Modules) || len(luajit) != len(gopher) || len(differing) > 0 {
		t.Fatalf("load outcome differs for %d modules: %s", len(differing), strings.Join(differing, ", "))
	}
}

// sortTieProbe sorts keys with many ties, by comparator and by default order.
const sortTieProbe = `local out = {}
for n = 2, 64 do
	for modulus = 2, 5 do
		local t, plain = {}, {}
		for i = 1, n do
			t[i] = { k = (i * 7) % modulus, id = i }
			plain[i] = (i * 13) % modulus
		end
		table.sort(t, function(a, b) return a.k < b.k end)
		table.sort(plain)
		local ids = {}
		for i = 1, n do ids[i] = t[i].id end
		out[#out + 1] = table.concat(ids, ",") .. "|" .. table.concat(plain, ",")
	end
end
sort_probe = table.concat(out, ";")`

func sortTieOrder(t *testing.T, corpus *combatcorpus.Corpus) {
	s := templateSnapshot(t, []combat.Actor{TemplateHero(t, 10001001, 1, 1, 1)}, []combat.Actor{TemplateHero(t, 10001002, 1, 1, 1)})
	m, err := newMachine(corpus, s, [32]byte{1})
	if err != nil {
		t.Fatal(err)
	}
	defer m.state.Close()
	if err = m.run(sortTieProbe, "sort probe"); err != nil {
		t.Fatal(err)
	}
	output, err := exec.Command(luajitBinary(t), "-joff", "-e", sortTieProbe+" io.write(sort_probe)").Output()
	if err != nil {
		t.Fatal(err)
	}
	if gopher := m.state.GetGlobal("sort_probe").String(); gopher != string(output) {
		t.Fatal("table.sort order differs from LuaJIT")
	}
}
