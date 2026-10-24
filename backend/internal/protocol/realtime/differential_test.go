package realtime

import (
	"encoding/hex"
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/protocol/amf3"
)

type diffFixtureFile struct {
	Fixtures []struct {
		Name     string `json:"name"`
		MID      uint16 `json:"mid"`
		Sequence uint32 `json:"sequence"`
		FrameHex string `json:"frame_hex"`
	} `json:"fixtures"`
}

func TestPass353DifferentialFixturesExact(t *testing.T) {
	p := filepath.Join("..", "..", "..", "testdata", "wire", "pass435_pass353_realtime_differential.json")
	b, err := os.ReadFile(p)
	if err != nil {
		t.Fatal(err)
	}
	var f diffFixtureFile
	if err := json.Unmarshal(b, &f); err != nil {
		t.Fatal(err)
	}
	if len(f.Fixtures) != 5 {
		t.Fatalf("fixtures=%d", len(f.Fixtures))
	}
	for _, x := range f.Fixtures {
		want, err := hex.DecodeString(x.FrameHex)
		if err != nil {
			t.Fatal(err)
		}
		params := fixtureObject(t, x.Name)
		got, err := EncodeFrame(Frame{MID: x.MID, Sequence: x.Sequence, Params: params})
		if err != nil {
			t.Fatalf("%s: %v", x.Name, err)
		}
		if !reflect.DeepEqual(got, want) {
			t.Fatalf("%s mismatch\n got %x\nwant %x", x.Name, got, want)
		}
	}
}

func fixtureObject(t *testing.T, name string) *amf3.Object {
	t.Helper()
	switch name {
	case "tcp_login":
		return &amf3.Object{Properties: []amf3.Property{{Name: "token", Value: "local_token"}, {Name: "region", Value: 194.0}, {Name: "room_id", Value: 194.0}}}
	case "chat_room_entered":
		return &amf3.Object{Properties: []amf3.Property{{Name: "room_id", Value: 194.0}}}
	case "heartbeat":
		return &amf3.Object{}
	case "string_reference_object":
		return &amf3.Object{Properties: []amf3.Property{{Name: "left", Value: "repeat"}, {Name: "right", Value: "repeat"}}}
	case "array_payload":
		return &amf3.Object{Properties: []amf3.Property{{Name: "items", Value: []any{1.0, "x", true, nil}}}}
	default:
		t.Fatalf("unknown fixture %q", name)
		return nil
	}
}
