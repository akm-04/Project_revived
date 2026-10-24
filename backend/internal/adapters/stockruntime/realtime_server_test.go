package stockruntime

import (
	"context"
	"net"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

type rtAuthority struct{ actor identity.ActorContext }

func (r rtAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return r.actor, nil
}

type rtEndpoint struct{}

func (rtEndpoint) EndpointFor(context.Context, domainrt.PhysicalRole) (app.Endpoint, error) {
	return app.Endpoint{Host: "127.0.0.1", Port: 19090}, nil
}
func actorForRT(t *testing.T) identity.ActorContext {
	u, _ := ids.ParseUUID("44444444-4444-4444-8444-444444444444")
	c, _ := identity.ContextIDFrom(u)
	return identity.ActorContext{ContextID: c, LogicalServerID: 1, PlayerID: 100001}
}
func TestRealtimeTCPLoginAckAndHeartbeatNoEcho(t *testing.T) {
	server, client := net.Pipe()
	defer client.Close()
	s := RealtimeServer{Auth: app.Service{Authority: rtAuthority{actorForRT(t)}, Endpoints: rtEndpoint{}}, Limits: limits.Default()}
	done := make(chan error, 1)
	go func() { done <- s.ServeConn(context.Background(), server) }()
	login, _ := rt.EncodeFrame(rt.Frame{MID: mids.MIDTCPLogin, Params: &amf3.Object{Properties: []amf3.Property{{Name: "token", Value: "x"}, {Name: "region", Value: 1.0}, {Name: "room_id", Value: 1.0}}}})
	if _, err := client.Write(login); err != nil {
		t.Fatal(err)
	}
	buf := make([]byte, 1024)
	_ = client.SetReadDeadline(time.Now().Add(time.Second))
	n, err := client.Read(buf)
	if err != nil {
		t.Fatal(err)
	}
	dec, _ := rt.NewStreamDecoder(limits.Default())
	frames, err := dec.Feed(buf[:n])
	if err != nil || len(frames) != 1 {
		t.Fatalf("frames=%d err=%v", len(frames), err)
	}
	if frames[0].MID != mids.MIDChatRoomEntered {
		t.Fatalf("mid=%d", frames[0].MID)
	}
	hb, _ := rt.EncodeFrame(rt.Frame{MID: mids.MIDSocketHeartbeat, Params: &amf3.Object{}})
	if _, err := client.Write(hb); err != nil {
		t.Fatal(err)
	}
	_ = client.SetReadDeadline(time.Now().Add(30 * time.Millisecond))
	if n, err := client.Read(buf); err == nil || n != 0 {
		t.Fatalf("heartbeat unexpectedly echoed n=%d err=%v", n, err)
	}
	_ = client.Close()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("server did not exit")
	}
}
