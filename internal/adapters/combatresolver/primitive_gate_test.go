package combatresolver

import (
	"maps"
	"regexp"
	"slices"
	"testing"

	lua "github.com/yuin/gopher-lua"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/combat"
)

// H-55: qualifiedPrimitives is the reviewed library surface the corpus names.
// true entries exist in the resolver VM and are covered by the LuaJIT
// differential; false entries are absent there and fail closed if reached.
// A corpus update naming anything else blocks the rules profile.
var qualifiedPrimitives = map[string]bool{
	"debug.getlocal": false, "io.close": false, "io.exists": false, "io.filesize": false, "io.open": false, "io.pathinfo": false,
	"io.readfile": false, "io.writefile": false, "os.date": false, "os.difftime": false,
	"math.abs": true, "math.angle2radian": true, "math.atan2": true, "math.ceil": true, "math.cos": true, "math.floor": true,
	"math.fmod": true, "math.log": true, "math.max": true, "math.min": true, "math.newrandomseed": true, "math.pi": true,
	"math.pow": true, "math.radian2angle": true, "math.random": true, "math.randomseed": true, "math.round": true, "math.sin": true,
	"math.sqrt": true, "os.clock": true, "os.time": true, "package.loaded": true, "package.preload": true,
	"string._htmlspecialchars_set": true, "string.byte": true, "string.char": true, "string.find": true, "string.format": true,
	"string.formatnumberthousands": true, "string.gsub": true, "string.htmlspecialchars": true, "string.len": true,
	"string.lower": true, "string.ltrim": true, "string.match": true, "string.nl2br": true, "string.restorehtmlspecialchars": true,
	"string.rtrim": true, "string.split": true, "string.sub": true, "string.text2html": true, "string.trim": true,
	"string.ucfirst": true, "string.upper": true, "string.urldecode": true, "string.urlencode": true, "string.utf8len": true,
	"table.concat": true, "table.filter": true, "table.indexof": true, "table.insert": true, "table.insertto": true,
	"table.keyof": true, "table.keys": true, "table.map": true, "table.merge": true, "table.nums": true, "table.remove": true,
	"table.removebyvalue": true, "table.sort": true, "table.unique": true, "table.values": true, "table.walk": true,
}

var primitiveReference = regexp.MustCompile(`\b(?:(string|math|table|os|io|debug|coroutine|bit|bit32|jit|ffi|package|utf8)\s*\.\s*([A-Za-z_]\w*)|(goto)\s+[A-Za-z_])`)

func referencedPrimitives(sources map[string]string) []string {
	out := map[string]bool{}
	for _, source := range sources {
		for _, match := range primitiveReference.FindAllStringSubmatch(source, -1) {
			if match[3] != "" {
				out[match[3]] = true
				continue
			}
			out[match[1]+"."+match[2]] = true
		}
	}
	return slices.Sorted(maps.Keys(out))
}

func unqualifiedPrimitives(sources map[string]string) []string {
	return slices.DeleteFunc(referencedPrimitives(sources), func(name string) bool {
		_, qualified := qualifiedPrimitives[name]
		return qualified
	})
}

func TestCorpusPrimitivesAreQualified(t *testing.T) {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	sources := map[string]string{}
	for _, record := range corpus.Manifest().Modules {
		sources[record.Name], _ = corpus.Module(record.Name)
	}
	if missing := unqualifiedPrimitives(sources); len(missing) > 0 {
		t.Fatalf("unqualified Lua primitives block the rules profile: %v", missing)
	}
	if referenced := referencedPrimitives(sources); !slices.Equal(referenced, slices.Sorted(maps.Keys(qualifiedPrimitives))) {
		t.Fatalf("qualified inventory lists primitives the corpus no longer names; referenced %v", referenced)
	}
	s := templateSnapshot(t, []combat.Actor{TemplateHero(t, 10001001, 1, 1, 1)}, []combat.Actor{TemplateHero(t, 10001002, 1, 1, 1)})
	m, err := newMachine(corpus, s, [32]byte{1})
	if err != nil {
		t.Fatal(err)
	}
	defer m.state.Close()
	for name, want := range qualifiedPrimitives {
		resolved := m.state.DoString("primitive_probe = "+name) == nil && m.state.GetGlobal("primitive_probe") != lua.LNil
		if resolved != want {
			t.Errorf("%s resolves %v in the VM, inventory says %v", name, resolved, want)
		}
	}
	update := map[string]string{"source update": "local mask = bit.band(1, 2)\n::retry:: goto retry"}
	if got := unqualifiedPrimitives(update); !slices.Equal(got, []string{"bit.band", "goto"}) {
		t.Fatalf("gate missed an unsupported primitive: %v", got)
	}
}
