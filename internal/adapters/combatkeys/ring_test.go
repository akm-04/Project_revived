package combatkeys

import (
	"strings"
	"testing"
)

func TestParse(t *testing.T) {
	a, b := strings.Repeat("ab", 32), strings.Repeat("cd", 32)
	r, err := Parse("old="+a+", new="+b, "new")
	if err != nil {
		t.Fatal(err)
	}
	if v, k, err := r.Current(); err != nil || v != "new" || len(k) != 32 {
		t.Fatal("current", v, err)
	}
	if _, err = r.Key("old"); err != nil {
		t.Fatal("retired key must stay readable")
	}
	if _, err = r.Key("gone"); err == nil {
		t.Fatal("missing version must fail closed")
	}
	for _, bad := range [][2]string{{"x=" + a[:62], "x"}, {"x=" + a, "y"}, {"x=" + a + ",x=" + b, "x"}, {"", ""}} {
		if _, err = Parse(bad[0], bad[1]); err == nil {
			t.Fatal("accepted", bad)
		}
	}
}
