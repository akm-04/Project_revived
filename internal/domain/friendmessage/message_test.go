package friendmessage

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestOrdinaryFiniteWire(t *testing.T) {
	valid := []string{`{"message":"hello","msgType":0}`, `{"message":1,"msgType":1}`, `{"message":1e0,"msgType":1.0,"selectType":0e0}`, `{"message":"\ud83d\ude03","msgType":0}`, `{"message":"` + strings.Repeat("界", 140) + `","msgType":0}`}
	for _, raw := range valid {
		m, e := Decode(raw)
		if e != nil {
			t.Fatal(raw, e)
		}
		canonical, e := m.Canonical()
		if e != nil {
			t.Fatal(e)
		}
		again, e := Decode(canonical)
		if e != nil || again != m {
			t.Fatal("roundtrip", m, again, e)
		}
	}
	bad := []string{`{"msg":"hello","msgType":0}`, `{"message":"","msgType":0}`, `{"message":"hello","msgType":2}`, `{"message":"hello","msgType":"0"}`, `{"message":"hello","msgType":false}`, `{"message":"hello","msgType":0,"msgType":0}`, `{"message":"hello","msgType":0,"roomID":1}`, `{"message":"hello","msgType":0,"selectType":1}`, `{"message":{},"msgType":0}`, `{"message":[],"msgType":0}`, `{"message":null,"msgType":0}`, `{"message":"\ud800","msgType":0}`, `{"message":"\udc00","msgType":0}`, `{"message":1e-400,"msgType":1}`, `{"message":1e401,"msgType":1}`, `{"message":"1","msgType":1}`, `{"message":0,"msgType":1}`, `{"message":"` + strings.Repeat("界", 141) + `","msgType":0}`, `{"message":"` + string([]byte{255}) + `","msgType":0}`, `{"message":"` + strings.Repeat("x", 2048) + `","msgType":0}`}
	for _, raw := range bad {
		if m, e := Decode(raw); e == nil {
			t.Fatalf("accepted invalid %q %+v", raw, m)
		}
	}
	if _, e := ExactInteger(json.Number(strings.Repeat("0", 65))); e == nil {
		t.Fatal("numeric token cap")
	}
}
func FuzzPrivatePayload(f *testing.F) {
	for _, s := range []string{`{"message":"ok","msgType":0}`, `{"message":1,"msgType":1}`, `{"message":"\ud800","msgType":0}`} {
		f.Add(s)
	}
	f.Fuzz(func(t *testing.T, s string) {
		m, e := Decode(s)
		if e != nil {
			return
		}
		canonical, e := m.Canonical()
		if e != nil {
			t.Fatal(e)
		}
		next, e := Decode(canonical)
		if e != nil || next != m {
			t.Fatal("unstable private normalization")
		}
	})
}
