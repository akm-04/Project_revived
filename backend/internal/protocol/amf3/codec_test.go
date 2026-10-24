package amf3

import (
	"encoding/hex"
	"errors"
	"math"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/protocol/limits"
)

const tcpLoginPayloadHex = "0a0b010b746f6b656e06176c6f63616c5f746f6b656e0d726567696f6e0540684000000000000f726f6f6d5f696405406840000000000001"

func TestTCPLoginPayloadGoldenDecodeReencode(t *testing.T) {
	b, _ := hex.DecodeString(tcpLoginPayloadHex)
	v, err := Decode(b, limits.Default())
	if err != nil {
		t.Fatal(err)
	}
	o, ok := v.(*Object)
	if !ok {
		t.Fatalf("type %T", v)
	}
	want := []Property{{"token", "local_token"}, {"region", 194.0}, {"room_id", 194.0}}
	if !reflect.DeepEqual(o.Properties, want) {
		t.Fatalf("decoded=%#v", o.Properties)
	}
	enc, err := Encode(o)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(enc, b) {
		t.Fatalf("reencode\n got %x\nwant %x", enc, b)
	}
}

func TestAcceptedMarkersAndRejectedProfileMarkers(t *testing.T) {
	cases := [][]byte{{0x00}, {0x01}, {0x02}, {0x03}, {0x04, 0x01}, {0x05, 0, 0, 0, 0, 0, 0, 0, 0}, {0x06, 0x01}, {0x09, 0x01, 0x01}, {0x0a, 0x0b, 0x01, 0x01}}
	for _, b := range cases {
		if _, err := Decode(b, limits.Default()); err != nil {
			t.Fatalf("%x: %v", b, err)
		}
	}
	for _, m := range []byte{0x07, 0x08, 0x0b, 0x11} {
		_, err := Decode([]byte{m}, limits.Default())
		if !errors.Is(err, ErrUnsupported) {
			t.Fatalf("marker %02x err=%v", m, err)
		}
	}
}

func TestStringReferenceAndInvalidReference(t *testing.T) {
	// Dense array ["x","x"], second string uses reference index 0.
	b := []byte{0x09, 0x05, 0x01, 0x06, 0x03, 'x', 0x06, 0x00}
	v, err := Decode(b, limits.Default())
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(v, []any{"x", "x"}) {
		t.Fatalf("%#v", v)
	}
	_, err = Decode([]byte{0x06, 0x00}, limits.Default())
	if !errors.Is(err, ErrMalformed) {
		t.Fatalf("err=%v", err)
	}
}

func TestIntegerSignedBoundaryAndDoublePolicy(t *testing.T) {
	for _, v := range []int32{-268435456, -1, 0, 1, 268435455} {
		b, err := EncodeInteger(v)
		if err != nil {
			t.Fatal(err)
		}
		got, err := Decode(b, limits.Default())
		if err != nil {
			t.Fatal(err)
		}
		if got != v {
			t.Fatalf("%d -> %v", v, got)
		}
	}
	b, err := Encode(7)
	if err != nil {
		t.Fatal(err)
	}
	if len(b) != 9 || b[0] != 0x05 {
		t.Fatalf("ordinary number not AMF3 double: %x", b)
	}
	if _, err := Encode(math.Inf(1)); !errors.Is(err, ErrMalformed) {
		t.Fatalf("err=%v", err)
	}
}

func TestBudgetStopsDeepObjects(t *testing.T) {
	cfg := limits.Default()
	cfg.AMFDepth = 2
	v := &Object{Properties: []Property{{Name: "a", Value: &Object{Properties: []Property{{Name: "b", Value: &Object{}}}}}}}
	b, err := Encode(v)
	if err != nil {
		t.Fatal(err)
	}
	_, err = Decode(b, cfg)
	if !errors.Is(err, ErrBudget) {
		t.Fatalf("err=%v", err)
	}
}

func FuzzDecodeBounded(f *testing.F) {
	b, _ := hex.DecodeString(tcpLoginPayloadHex)
	f.Add(b)
	f.Add([]byte{0x0a, 0x0b, 0x01, 0x01})
	f.Add([]byte{0x07})
	cfg := limits.Default()
	f.Fuzz(func(t *testing.T, b []byte) {
		if len(b) > limits.NativeFramePayloadMax {
			b = b[:limits.NativeFramePayloadMax]
		}
		_, _ = Decode(b, cfg)
	})
}

func TestDecodeRejectsSealedTraitCountBeforeAllocation(t *testing.T) {
	cfg := limits.Default()
	cfg.AMFProperties = 2
	// Inline object + inline dynamic trait, sealed count 3. The payload ends at
	// the trait header intentionally: budget rejection must occur before any
	// sealed-name allocation/read.
	ti := uint32(3<<3 | 4 | 1)
	h, err := writeU29(ti<<1 | 1)
	if err != nil {
		t.Fatal(err)
	}
	b := append([]byte{0x0a}, h...)
	_, err = Decode(b, cfg)
	if !errors.Is(err, ErrBudget) {
		t.Fatalf("sealed-count err=%v", err)
	}
}

func TestEncodeWithConfigBoundsOutputAndContainers(t *testing.T) {
	cfg := limits.Default()
	cfg.AMFOutputBytes = 8
	if _, err := EncodeWithConfig("0123456789", cfg); !errors.Is(err, ErrBudget) {
		t.Fatalf("output err=%v", err)
	}
	cfg = limits.Default()
	cfg.AMFArrayElements = 1
	if _, err := EncodeWithConfig([]any{1, 2}, cfg); !errors.Is(err, ErrBudget) {
		t.Fatalf("array err=%v", err)
	}
	cfg = limits.Default()
	cfg.AMFProperties = 1
	if _, err := EncodeWithConfig(map[string]any{"a": 1, "b": 2}, cfg); !errors.Is(err, ErrBudget) {
		t.Fatalf("property err=%v", err)
	}
}

func TestEncodeRejectsCyclesAndDepth(t *testing.T) {
	m := map[string]any{}
	m["self"] = m
	if _, err := Encode(m); !errors.Is(err, ErrUnsupported) {
		t.Fatalf("map cycle err=%v", err)
	}
	s := []any{nil}
	s[0] = s
	if _, err := Encode(s); !errors.Is(err, ErrUnsupported) {
		t.Fatalf("slice cycle err=%v", err)
	}
	o := &Object{}
	o.Properties = []Property{{Name: "self", Value: o}}
	if _, err := Encode(o); !errors.Is(err, ErrUnsupported) {
		t.Fatalf("object cycle err=%v", err)
	}
	cfg := limits.Default()
	cfg.AMFDepth = 2
	deep := &Object{Properties: []Property{{Name: "a", Value: &Object{Properties: []Property{{Name: "b", Value: 1}}}}}}
	if _, err := EncodeWithConfig(deep, cfg); !errors.Is(err, ErrBudget) {
		t.Fatalf("depth err=%v", err)
	}
}

func TestEncodeExactIntegerPolicyIsSymmetric(t *testing.T) {
	const exact = int64(1 << 53)
	for _, v := range []any{exact, -exact, uint64(1 << 53)} {
		if _, err := Encode(v); err != nil {
			t.Fatalf("exact %v: %v", v, err)
		}
	}
	for _, v := range []any{exact + 1, -exact - 1, uint64(1<<53) + 1} {
		if _, err := Encode(v); !errors.Is(err, ErrMalformed) {
			t.Fatalf("inexact %v err=%v", v, err)
		}
	}
	if _, err := EncodeInteger(268435456); !errors.Is(err, ErrMalformed) {
		t.Fatalf("amf integer positive overflow err=%v", err)
	}
	if _, err := EncodeInteger(-268435457); !errors.Is(err, ErrMalformed) {
		t.Fatalf("amf integer negative overflow err=%v", err)
	}
}

func TestEncodeReferenceAndStringBudgets(t *testing.T) {
	cfg := limits.Default()
	cfg.AMFReferences = 1
	if _, err := EncodeWithConfig([]any{"a", "b"}, cfg); !errors.Is(err, ErrBudget) {
		t.Fatalf("reference err=%v", err)
	}
	cfg = limits.Default()
	cfg.AMFStringBytes = 2
	if _, err := EncodeWithConfig([]any{"ab", "c"}, cfg); !errors.Is(err, ErrBudget) {
		t.Fatalf("string budget err=%v", err)
	}
}

func FuzzEncodeBounded(f *testing.F) {
	f.Add("x", int64(1))
	f.Add("", int64(0))
	f.Fuzz(func(t *testing.T, s string, n int64) {
		if len(s) > 4096 {
			s = s[:4096]
		}
		_, _ = Encode(map[string]any{"s": s, "n": n})
	})
}
