package profile

import (
	"strings"
	"testing"
)

func TestModerationUnicodeLimitsAndSourceTraversal(t *testing.T) {
	for _, tc := range []struct{ in, want string }{{"good bad ok", "good**** ok"}, {"b a d", "*****"}, {"badder", "***der"}, {"BAD", "BAD"}, {"😀bad😀", "😀***😀"}, {" ba d", "*****"}, {"", ""}} {
		got, e := ModerateIntro(tc.in, []string{"bad", "badder"})
		if e != nil || got != tc.want {
			t.Fatalf("%q => %q %v want%q", tc.in, got, e, tc.want)
		}
	}
	for _, s := range []string{strings.Repeat("😀", 41), string([]byte{255}), "nul\x00"} {
		if _, e := ModerateIntro(s, []string{"bad"}); e == nil {
			t.Fatalf("invalid intro accepted %q", s)
		}
	}
	s := strings.Repeat("😀", 40)
	if got, e := ModerateIntro(s, []string{"bad"}); e != nil || got != s {
		t.Fatalf("scalar boundary %v", e)
	}
}
