package guildbroadcast

import (
	"strings"
	"testing"
)

func TestLiteralStockByteWalk(t *testing.T) {
	for _, c := range []struct {
		s    string
		want int
	}{{"ASCII", 5}, {"中", 2}, {"\u0800", 2}, {"\u1000", 2}, {"\u2000", 2}, {"😀", 3}, {"\U00040000", 1}, {"\U00100000", 1}, {"e\u0301", 2}, {"", 0}} {
		got, e := TextHalfUnits(c.s)
		if e != nil || got != c.want {
			t.Fatalf("%q got %d %v want %d", c.s, got, e, c.want)
		}
	}
	if _, e := TextHalfUnits(string([]byte{0xf0, 0x80})); e == nil {
		t.Fatal("invalid UTF8 accepted")
	}
}
func TestStockBoundsAndPreservedText(t *testing.T) {
	for _, c := range []struct {
		r     Request
		valid bool
	}{{Request{strings.Repeat("a", 20), strings.Repeat("a", 200)}, true}, {Request{strings.Repeat("中", 10), strings.Repeat("中", 100)}, true}, {Request{strings.Repeat("😀", 6), "body"}, true}, {Request{strings.Repeat("😀", 7), "body"}, false}, {Request{strings.Repeat("\U00040000", 20), "body"}, true}, {Request{strings.Repeat("\U00040000", 21), "body"}, false}, {Request{" ", "\n"}, true}, {Request{"", "body"}, false}, {Request{"a", strings.Repeat("b", 201)}, false}} {
		if (c.r.Validate() == nil) != c.valid {
			t.Fatalf("bounds %+v valid=%v", c.r, c.valid)
		}
	}
}

func TestPostgresRepresentabilityBoundaryPreservesLiteralWalk(t *testing.T) {
	if n, e := TextHalfUnits("\x00"); e != nil || n != 1 {
		t.Fatal(n, e)
	}
	for _, r := range []Request{{Title: "a\x00", Content: "body"}, {Title: "title", Content: "b\x00"}} {
		if r.Validate() == nil {
			t.Fatal("NUL admitted before PostgreSQL")
		}
	}
	if e := (Request{Title: " \t", Content: "\r\n"}).Validate(); e != nil {
		t.Fatal("other whitespace changed", e)
	}
}
