package realtime

import (
	"encoding/hex"
	"errors"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
)

const tcpLoginFrameHex = "000000388003000000000a0b010b746f6b656e06176c6f63616c5f746f6b656e0d726567696f6e0540684000000000000f726f6f6d5f696405406840000000000001"

func TestTCPLoginExactFrameGolden(t *testing.T) {
	want, _ := hex.DecodeString(tcpLoginFrameHex)
	obj := &amf3.Object{Properties: []amf3.Property{{Name: "token", Value: "local_token"}, {Name: "region", Value: 194.0}, {Name: "room_id", Value: 194.0}}}
	got, err := EncodeFrame(Frame{MID: mids.MIDTCPLogin, Sequence: 0, Params: obj})
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %x\nwant %x", got, want)
	}
}

func TestFragmentAtEveryByteAndCoalescing(t *testing.T) {
	frame, _ := hex.DecodeString(tcpLoginFrameHex)
	cfg := limits.Default()
	for split := 0; split <= len(frame); split++ {
		d, _ := NewStreamDecoder(cfg)
		a, e := d.Feed(frame[:split])
		if e != nil {
			t.Fatal(e)
		}
		if len(a) != 0 && split < len(frame) {
			t.Fatalf("split=%d early frame", split)
		}
		b, e := d.Feed(frame[split:])
		if e != nil {
			t.Fatal(e)
		}
		if len(a)+len(b) != 1 {
			t.Fatalf("split=%d count=%d", split, len(a)+len(b))
		}
	}
	d, _ := NewStreamDecoder(cfg)
	out, e := d.Feed(append(append([]byte{}, frame...), frame...))
	if e != nil {
		t.Fatal(e)
	}
	if len(out) != 2 {
		t.Fatalf("coalesced=%d", len(out))
	}
}

func TestOversizeHeaderRejected(t *testing.T) {
	d, _ := NewStreamDecoder(limits.Default())
	_, err := d.Feed([]byte{0, 1, 0, 1})
	if !errors.Is(err, ErrFrameTooLarge) {
		t.Fatalf("err=%v", err)
	}
}

func TestGateAndQueue(t *testing.T) {
	g, err := NewGate(World)
	if err != nil {
		t.Fatal(err)
	}
	if err := g.ObserveClientFrame(Frame{MID: 1, Params: &amf3.Object{}}); !errors.Is(err, ErrPreauthMID) {
		t.Fatalf("err=%v", err)
	}
	g, _ = NewGate(Service)
	if err := g.ObserveClientFrame(Frame{MID: mids.MIDTCPLogin, Params: &amf3.Object{}}); err != nil {
		t.Fatal(err)
	}
	if g.Authenticated() {
		t.Fatal("syntactic TCP_LOGIN must not establish authority")
	}
	g.MarkAuthenticated()
	if !g.Authenticated() {
		t.Fatal("adapter admission did not mark gate authenticated")
	}
	if err := g.ObserveClientFrame(Frame{MID: mids.MIDChatRoomEntered, Params: &amf3.Object{}}); !errors.Is(err, ErrWrongDirection) {
		t.Fatalf("err=%v", err)
	}
	q, _ := NewWriteQueue(1, 100)
	if err := q.Push(make([]byte, 50)); err != nil {
		t.Fatal(err)
	}
	if err := q.Push([]byte{1}); !errors.Is(err, ErrQueueFull) {
		t.Fatalf("err=%v", err)
	}
	x, ok := q.Pop()
	if !ok || len(x) != 50 || q.Bytes() != 0 {
		t.Fatal("queue accounting")
	}
}

func FuzzStreamDecoder(f *testing.F) {
	b, _ := hex.DecodeString(tcpLoginFrameHex)
	f.Add(b)
	f.Add([]byte{0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
	cfg := limits.Default()
	f.Fuzz(func(t *testing.T, b []byte) {
		if len(b) > 2*(limits.NativeFramePayloadMax+HeaderBytes) {
			b = b[:2*(limits.NativeFramePayloadMax+HeaderBytes)]
		}
		d, _ := NewStreamDecoder(cfg)
		_, _ = d.Feed(b)
	})
}

func TestEncodeFrameWithConfigEnforcesAMFOutputBudget(t *testing.T) {
	cfg := limits.Default()
	cfg.AMFOutputBytes = 8
	_, err := EncodeFrameWithConfig(Frame{MID: mids.MIDSocketHeartbeat, Params: map[string]any{"payload": "0123456789"}}, cfg)
	if !errors.Is(err, amf3.ErrBudget) {
		t.Fatalf("err=%v", err)
	}
}
