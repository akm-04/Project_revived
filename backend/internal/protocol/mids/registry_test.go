package mids

import "testing"

func TestGeneratedCatalogAndSourceRouting(t *testing.T) {
	if CurrentSourceSHA256 != "026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af" {
		t.Fatal(CurrentSourceSHA256)
	}
	if CurrentUniqueMIDCount < 1200 {
		t.Fatalf("unique=%d", CurrentUniqueMIDCount)
	}
	for _, m := range []uint16{279, 2484, 535, 774, 1412, 1570, 2515} {
		d, ok := Lookup(m)
		if !ok || d.Encoding != ZlibMultipart || d.Transport != HTTP {
			t.Fatalf("%d %#v", m, d)
		}
	}
	if d, _ := Lookup(1844); d.Encoding != UploadMultipart {
		t.Fatalf("%#v", d)
	}
	if d, _ := Lookup(MIDTCPLogin); d.Transport != TCP || d.Direction != C2S {
		t.Fatalf("%#v", d)
	}
	if d, _ := Lookup(MIDChatRoomEntered); d.Transport != TCP || d.Direction != S2C {
		t.Fatalf("%#v", d)
	}
	if IsRealtimeNumber(32771) != true || IsGMNumber(36864) != true {
		t.Fatal("source bitmask classification")
	}
}
