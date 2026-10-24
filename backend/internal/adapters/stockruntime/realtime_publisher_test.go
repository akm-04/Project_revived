package stockruntime

import (
	"context"
	"errors"
	"net"
	"testing"
	"time"

	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

func TestRealtimePublisherValidatesBeforeUsingExistingWriter(t *testing.T) {
	reg, err := wireRT.NewEventRegistry([]wireRT.DirectRegistration{{
		MID: mids.MIDChatFromPlayer, Roles: []wireRT.Role{wireRT.World}, Validate: wireRT.RequireAMF3Object,
	}}, nil)
	if err != nil {
		t.Fatal(err)
	}
	publisher := RealtimePublisher{Registry: reg, Limits: limits.Default()}
	connections := NewConnectionRegistry()
	admission := registryAdmission(t, "33333333-3333-4333-8333-333333333333", 100001, domainrt.World, 1)
	server, client := net.Pipe()
	defer client.Close()
	writer, err := newConnWriter(context.Background(), server, limits.Default(), time.Second)
	if err != nil {
		t.Fatal(err)
	}
	h, err := connections.Replace(admission, writer)
	if err != nil {
		t.Fatal(err)
	}
	defer connections.Remove(h)

	if err := publisher.PublishDirect(context.Background(), h, mids.MIDChatFromFriend, &amf3.Object{}); !errors.Is(err, wireRT.ErrUnknownS2CSchema) {
		t.Fatalf("unregistered publication err=%v", err)
	}

	readDone := make(chan wireRT.Frame, 1)
	readErr := make(chan error, 1)
	go func() {
		buf := make([]byte, 4096)
		n, err := client.Read(buf)
		if err != nil {
			readErr <- err
			return
		}
		dec, _ := wireRT.NewStreamDecoder(limits.Default())
		frames, err := dec.Feed(buf[:n])
		if err != nil || len(frames) != 1 {
			if err == nil {
				err = errors.New("unexpected frame count")
			}
			readErr <- err
			return
		}
		readDone <- frames[0]
	}()
	payload := &amf3.Object{Properties: []amf3.Property{{Name: "player_id", Value: 100001.0}}}
	if err := publisher.PublishDirect(context.Background(), h, mids.MIDChatFromPlayer, payload); err != nil {
		t.Fatal(err)
	}
	select {
	case f := <-readDone:
		if f.MID != mids.MIDChatFromPlayer {
			t.Fatalf("published MID=%d", f.MID)
		}
	case err := <-readErr:
		t.Fatal(err)
	case <-time.After(time.Second):
		t.Fatal("publication not written")
	}
}
