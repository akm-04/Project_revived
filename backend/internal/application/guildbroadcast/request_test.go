package guildbroadcast

import (
	"encoding/json"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"testing"
	"unicode/utf8"
)

func TestStrictRawStockRequest(t *testing.T) {
	good := []byte(`{"title":" a ","content":"e\u0301"}`)
	r, e := DecodeRequest(good)
	if e != nil || r.Title != " a " || r.Content != "e\u0301" {
		t.Fatal(r, e)
	}
	for _, raw := range []string{`{"title":"a","title":"b","content":"c"}`, `{"title":"a","\u0074itle":"b","content":"c"}`, `{"title":"a","content":"b","extra":1}`, `{"title":1,"content":"b"}`, `{"title":null,"content":"b"}`, `{"title":{},"content":"b"}`, `{"title":"a"}`, `{"title":"\ud800","content":"b"}`, `{"title":"a","content":"b"} {}`, `[]`, `{"title":"` + string([]byte{0xff}) + `","content":"b"}`} {
		if _, e := DecodeRequest([]byte(raw)); e == nil {
			t.Fatalf("accepted invalid raw %q", raw)
		}
	}
}
func FuzzDecodePreservesSourceText(f *testing.F) {
	f.Add("a", "b")
	f.Add("😀", "e\u0301")
	f.Add("\U00040000", "中")
	f.Fuzz(func(t *testing.T, title, body string) {
		if !utf8.ValidString(title) || !utf8.ValidString(body) {
			return
		}
		want := gb.Request{Title: title, Content: body}
		raw, e := json.Marshal(want)
		if e != nil {
			t.Fatal(e)
		}
		got, e := DecodeRequest(raw)
		if want.Validate() == nil {
			if e != nil || got != want {
				t.Fatalf("valid text changed: %q %q %v", title, body, e)
			}
		} else if e == nil {
			t.Fatal("invalid text accepted")
		}
	})
}
