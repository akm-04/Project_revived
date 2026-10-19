package combatcorpus

import "testing"

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
