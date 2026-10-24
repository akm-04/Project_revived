package player

import (
	"testing"
	"time"
)

func TestDisplayExpiryTupleAndName(t *testing.T) {
	at := time.Unix(1000, 0).UTC()
	start := time.Unix(100, 0).UTC()
	a := Cosmetic{Family: "avatar", ID: 110001002, Icon: 10002004, Type: 1, Days: 1}
	if a.ValidateAvatarTuple(a.ID, 1) == nil || a.ValidateAvatarTuple(a.Icon, 2) == nil || a.ValidateAvatarTuple(a.Icon, 1) != nil {
		t.Fatal("catalog/icon/category conflation")
	}
	end, e := a.EndTime(&start, 0)
	if e != nil || end != 86500 || EligibleAt(end, time.Unix(end, 0)) || !EligibleAt(end, time.Unix(end-1, 0)) {
		t.Fatal(end, e)
	}
	if end, e = a.EndTime(nil, 0); e != nil || end != 0 {
		t.Fatal("source qualified absent-start branch")
	}
	a.Days = 0
	if _, e = a.EndTime(&start, 0); e == nil {
		t.Fatal("invalid avatar duration")
	}
	a.Family = "frame"
	if end, e = a.EndTime(&start, 0); e != nil || end != 0 {
		t.Fatal("frame own permanent branch")
	}
	a.Family = "title"
	if end, e = a.EndTime(nil, -1); e != nil || !EligibleAt(end, at) {
		t.Fatal("permanent title")
	}
	p := DisplayCatalog{Words: []string{"bad"}}
	for _, n := range []string{"a", "badname", "\xffa", "x\x00y", "abcdefghijklmnopq"} {
		if p.ValidateName(n) == nil {
			t.Fatal(n)
		}
	}
	if p.ValidateName("名字") != nil {
		t.Fatal("UTF8 codepoint length")
	}
}
