package ids

import (
	"bytes"
	"testing"
)

func TestUUIDRoundTripAndVersionBits(t *testing.T) {
	id, err := NewUUIDFrom(bytes.NewReader(make([]byte, 16)))
	if err != nil {
		t.Fatal(err)
	}
	if id[6]>>4 != 4 {
		t.Fatalf("version=%x", id[6]>>4)
	}
	if id[8]>>6 != 2 {
		t.Fatalf("variant=%x", id[8]>>6)
	}
	got, err := ParseUUID(id.String())
	if err != nil {
		t.Fatal(err)
	}
	if got != id {
		t.Fatalf("round trip mismatch")
	}
}
