package stockruntime

import (
	"context"
	"errors"
	"net"
	"sync"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

type mutableGuildBinding struct {
	mu      sync.RWMutex
	binding app.GuildBinding
	ok      bool
}

func (g *mutableGuildBinding) CurrentGuildBinding(context.Context, identity.ActorContext) (app.GuildBinding, bool, error) {
	g.mu.RLock()
	defer g.mu.RUnlock()
	return g.binding, g.ok, nil
}
func (g *mutableGuildBinding) setJoinEventID(id int64) {
	g.mu.Lock()
	g.binding.JoinEventID = id
	g.mu.Unlock()
}

func TestEstablishedGuildSocketFailsLivenessAfterJoinIncarnationChanges(t *testing.T) {
	serverConn, client := net.Pipe()
	defer client.Close()
	guilds := &mutableGuildBinding{binding: app.GuildBinding{GuildID: 77, JoinEventID: 10}, ok: true}
	actor := fullActorForPresence(t)
	actor.LogicalServerID = 1
	policy := DefaultRealtimePolicy()
	policy.LivenessInterval = 20 * time.Millisecond
	policy.LivenessQueryTimeout = time.Second
	s := RealtimeServer{
		Auth:   app.Service{Authority: fullRTAuthority{actor}, Guilds: guilds, Endpoints: rtEndpoint{}},
		Limits: limits.Default(), Policy: policy, Registry: NewConnectionRegistry(),
	}
	done := make(chan error, 1)
	go func() { done <- s.ServeConn(context.Background(), serverConn) }()
	login, _ := rt.EncodeFrame(rt.Frame{MID: mids.MIDTCPLogin, Params: &amf3.Object{Properties: []amf3.Property{{Name: "token", Value: "x"}, {Name: "region", Value: 1.0}, {Name: "room_id", Value: 77.0}}}})
	if _, err := client.Write(login); err != nil {
		t.Fatal(err)
	}
	buf := make([]byte, 1024)
	_ = client.SetReadDeadline(time.Now().Add(time.Second))
	if _, err := client.Read(buf); err != nil {
		t.Fatal(err)
	}
	guilds.setJoinEventID(11) // leave/rejoin or other new membership incarnation
	_ = client.SetReadDeadline(time.Time{})
	select {
	case err := <-done:
		if !errors.Is(err, app.ErrGuildBindingStale) {
			t.Fatalf("err=%v", err)
		}
	case <-time.After(time.Second):
		t.Fatal("stale GUILD socket survived liveness interval")
	}
}
