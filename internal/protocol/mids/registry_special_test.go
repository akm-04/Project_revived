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

func TestI7A2SourceProvenRealtimePushDescriptorOverrides(t *testing.T) {
	for _, mid := range []uint16{MIDChatFromPlayer, MIDChatFromFriend, MIDChatMessage, MIDWorldNotice, MIDPlayerNotice, MIDForceReload, MIDGuildBroadcast} {
		d, ok := Lookup(mid)
		if !ok || d.Transport != TCP || d.Direction != S2C || d.Encoding != AMF3 || d.Status != ResearchedUnimplemented {
			t.Fatalf("mid=%d descriptor=%+v ok=%v", mid, d, ok)
		}
	}
	if d, ok := Lookup(MIDSendChatMessage); !ok || d.Transport != TCP || d.Direction != C2S || d.Encoding != AMF3 {
		t.Fatalf("MID32782 descriptor=%+v ok=%v", d, ok)
	}
}
