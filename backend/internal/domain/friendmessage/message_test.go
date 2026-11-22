package friendmessage

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestOrdinaryFiniteWire(t *testing.T) {
	valid := []string{`{"message":"hello","msgType":0}`, `{"message":1,"msgType":1}`, `{"message":1e0,"msgType":1.0,"selectType":0e0}`, `{"message":"hello","msgType":0,"selectType":1}`, `{"message":1,"msgType":1,"selectType":1}`, `{"message":"\ud83d\ude03","msgType":0}`, `{"message":"` + strings.Repeat("界", 140) + `","msgType":0}`,
		`{"message":"hello","msgType":0,"selectType":2,"roomID":0}`, `{"message":"hello","msgType":0,"selectType":3,"roomID":0}`, `{"message":1,"msgType":1,"selectType":4,"roomID":12345}`}
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
	bad := []string{`{"msg":"hello","msgType":0}`, `{"message":"","msgType":0}`, `{"message":"hello","msgType":2}`, `{"message":"hello","msgType":"0"}`, `{"message":"hello","msgType":false}`, `{"message":"hello","msgType":0,"msgType":0}`, `{"message":"hello","msgType":0,"roomID":"1"}`, `{"message":"hello","msgType":0,"roomID":1.5}`, `{"message":"hello","msgType":0,"roomID":-1}`, `{"message":"hello","msgType":0,"unknown":1}`, `{"message":"hello","msgType":0,"selectType":7}`, `{"message":{},"msgType":0}`, `{"message":[],"msgType":0}`, `{"message":null,"msgType":0}`, `{"message":"\ud800","msgType":0}`, `{"message":"\udc00","msgType":0}`, `{"message":1e-400,"msgType":1}`, `{"message":1e401,"msgType":1}`, `{"message":"1","msgType":1}`, `{"message":0,"msgType":1}`, `{"message":"` + strings.Repeat("界", 141) + `","msgType":0}`, `{"message":"` + string([]byte{255}) + `","msgType":0}`, `{"message":"` + strings.Repeat("x", 2048) + `","msgType":0}`}
	for _, raw := range bad {
		if m, e := Decode(raw); e == nil {
			t.Fatalf("accepted invalid %q %+v", raw, m)
		}
	}
	if _, e := ExactInteger(json.Number(strings.Repeat("0", 65))); e == nil {
		t.Fatal("numeric token cap")
	}
	room, e := Decode(`{"message":"team","msgType":0,"selectType":1}`)
	if e != nil || room.SelectType != SelectIllusion {
		t.Fatal("room select type", room, e)
	}
	canonical, e := room.Canonical()
	if e != nil || canonical != `{"msgType":0,"message":"team","selectType":1}` {
		t.Fatalf("room canonical %q %v", canonical, e)
	}
	ordinary, e := Decode(`{"message":"plain","msgType":0}`)
	if e != nil {
		t.Fatal(e)
	}
	if canonical, e = ordinary.Canonical(); e != nil || canonical != `{"msgType":0,"message":"plain"}` {
		t.Fatalf("ordinary canonical %q %v", canonical, e)
	}
}

// TestRoomChatRoomID names A-182: the stock group-chat windows send a fourth
// roomID key (GroupChatNewWnd.lua:156, GroupChatWnd.lua:156), including the
// window's 0 default for Occult and Adventure Illusion.
func TestRoomChatRoomID(t *testing.T) {
	zero, err := Decode(`{"message":"team","msgType":0,"selectType":2,"roomID":0}`)
	if err != nil || zero.RoomID != 0 || !zero.HasRoomID || zero.SelectType != SelectOccult {
		t.Fatalf("zero roomID %+v %v", zero, err)
	}
	canonical, err := zero.Canonical()
	if err != nil || canonical != `{"msgType":0,"message":"team","selectType":2,"roomID":0}` {
		t.Fatalf("zero canonical %q %v", canonical, err)
	}
	if again, err := Decode(canonical); err != nil || again != zero {
		t.Fatalf("zero roundtrip %+v %v", again, err)
	}
	positive, err := Decode(`{"message":"team","msgType":0,"selectType":4,"roomID":987654321}`)
	if err != nil || positive.RoomID != 987654321 || !positive.HasRoomID {
		t.Fatalf("positive roomID %+v %v", positive, err)
	}
	if canonical, err = positive.Canonical(); err != nil || canonical != `{"msgType":0,"message":"team","selectType":4,"roomID":987654321}` {
		t.Fatalf("positive canonical %q %v", canonical, err)
	}
	if _, err := Decode(`{"message":"team","msgType":0,"selectType":3,"roomID":"7"}`); err == nil {
		t.Fatal("a string roomID was accepted")
	}
	if _, err := Decode(`{"message":"team","msgType":0,"selectType":3,"roomID":7.5}`); err == nil {
		t.Fatal("a fractional roomID was accepted")
	}
	if _, err := Decode(`{"message":"team","msgType":0,"selectType":3,"roomID":-7}`); err == nil {
		t.Fatal("a negative roomID was accepted")
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
