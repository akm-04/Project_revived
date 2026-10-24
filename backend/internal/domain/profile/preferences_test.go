package profile

import (
	"strings"
	"testing"
)

func TestPreferencesSourceBoundsAndCopies(t *testing.T) {
	for _, s := range []string{strings.Repeat("界", 41), "bad\x00", "\xff"} {
		if _, e := Defaults().Apply(Change{Intro: &s}); e == nil {
			t.Fatalf("accepted invalid intro %q", s)
		}
	}
	text := strings.Repeat("界", 40)
	ids := []int64{1011, 1001}
	h := []int16{4, 2}
	p, e := Defaults().Apply(Change{Intro: &text, ShowTypeIDs: &ids, HideSubtypes: &h})
	if e != nil {
		t.Fatal(e)
	}
	ids[0] = 0
	h[0] = 0
	if p.ShowTypeIDs[0] != 1011 || p.HideSubtypes[0] != 2 {
		t.Fatal("alias or canonical order")
	}
	for _, ids := range [][]int64{{1000}, {1012}, {1001, 1001}, {1001, 1002, 1003, 1004, 1005}} {
		if _, e := Defaults().Apply(Change{ShowTypeIDs: &ids}); e == nil {
			t.Fatal(ids)
		}
	}
	for _, h := range [][]int16{{1}, {3}, {2, 2}, {2, 4, 2}} {
		if _, e := Defaults().Apply(Change{HideSubtypes: &h}); e == nil {
			t.Fatal(h)
		}
	}
	p.ShareSwitch = 1
	p.IsFirstTime = 1
	q, e := p.Apply(Change{})
	if e != nil || !p.Equal(q) {
		t.Fatal("flags/no-op")
	}
}
