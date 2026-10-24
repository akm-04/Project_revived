package combatcorpus

import (
	"errors"
	"slices"
	"testing"
)

func TestEmbeddedCorpusMatchesManifest(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if len(c.ID()) != 64 || c.SourceArchiveSHA256() != SourceArchiveSHA256 {
		t.Fatal("corpus identity")
	}
	for _, m := range c.Manifest().Modules {
		if _, ok := c.Module(m.Name); !ok {
			t.Fatal("missing module", m.Name)
		}
	}
	for _, record := range c.Manifest().Tables {
		table, err := c.Table(record.Name)
		if err != nil {
			t.Fatal(record.Name, err)
		}
		if table.Kind == "INDEXED" && len(table.Keys) == 0 {
			t.Fatal("indexed table without keys", record.Name)
		}
	}
	if _, err = c.Table("shake"); err == nil {
		t.Fatal("unpinned table served")
	}
}

// FIGHTER_CLASS_REACHABILITY_ADJUDICATION: no fallback; gated awakened rows lack classes.
func TestFighterClassManifest(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	cases := []struct {
		table          string
		id             int64
		class          string
		present, known bool
	}{
		{"partner", 10001001, "Lvmeng", true, true},
		{"partner", 10001040, "Fazheng", true, true},
		{"partner", 11001042, "Change_Awaken", false, true},
		{"partner", 99999999, "", false, false},
		{"pet", 10010001, "", true, true},
		{"bogus", 1, "", false, false},
	}
	for _, x := range cases {
		class, present, known := c.FighterClass(x.table, x.id)
		if present != x.present || known != x.known || (x.class != "" && class != x.class) {
			t.Fatal(x, class, present, known)
		}
	}
}

func TestBattleLineups(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	waves, assist, err := c.BattleLineup(19007)
	if err != nil || len(waves) != 3 || !slices.Equal(waves[0], []int64{80135005, 80135005}) || !slices.Equal(assist, []int64{80136130, 99990002}) {
		t.Fatal("19007", waves, assist, err)
	}
	for _, id := range append(slices.Concat(waves...), assist...) {
		if _, present, known := c.FighterClass("monster", id); !present || !known {
			t.Fatal("monster class", id)
		}
	}
	single, assist, err := c.BattleLineup(10000)
	if err != nil || len(single) != 1 || len(single[0]) != 5 || len(assist) != 0 {
		t.Fatal("10000", single, assist, err)
	}
	repeated, _, err := c.BattleLineup(1017)
	if err != nil || !slices.Equal(repeated[0], []int64{10001066, 10001067, 10001094, 10001034, 10001049}) {
		t.Fatal("1017 keeps the last row", repeated, err)
	}
	if _, _, err = c.BattleLineup(1); !errors.Is(err, ErrUnknownBattle) {
		t.Fatal("unknown fight", err)
	}
}
