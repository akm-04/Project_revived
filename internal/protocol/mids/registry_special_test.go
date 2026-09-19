package mids

import "testing"

func TestUpdateScenePlaneMIDsAreKnownHTTPOrdinary(t *testing.T) {
	for _, mid := range []uint16{MIDVersionCheck, MIDCenterDiscovery} {
		d, ok := Lookup(mid)
		if !ok || d.Transport != HTTP || d.Direction != C2S || d.Encoding != Ordinary {
			t.Fatalf("mid=%d descriptor=%+v ok=%v", mid, d, ok)
		}
	}
	if got := Aliases(MIDCenterDiscovery); len(got) != 1 || got[0] != "CENTER_DISCOVERY" {
		t.Fatalf("aliases=%v", got)
	}
}
