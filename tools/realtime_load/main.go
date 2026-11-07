// Command realtime-load hosts the production HTTP long-poll realtime handler
// with an in-memory authority and chat fan-out for load measurement.
package main

import (
	"context"
	"crypto/sha256"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	app "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

type loadAuthority struct{}

func (loadAuthority) ResolveGameplayBearer(_ context.Context, token string, _ time.Time) (identity.ActorContext, error) {
	sum := sha256.Sum256([]byte(token))
	uuid := func(prefix byte) ids.UUID {
		var value ids.UUID
		copy(value[:], sum[:16])
		value[0] = prefix
		value[6] = value[6]&0x0f | 0x40
		value[8] = value[8]&0x3f | 0x80
		return value
	}
	accountID, _ := identity.AccountIDFrom(uuid(1))
	sessionID, _ := identity.SessionIDFrom(uuid(2))
	contextID, _ := identity.ContextIDFrom(uuid(3))
	player := int64(0)
	for _, b := range sum[16:24] {
		player = player<<8 | int64(b)
	}
	return identity.ActorContext{
		AccountID: accountID, AccountUID: identity.AccountUID(fmt.Sprintf("L%012d", player%1e12)),
		SessionID: sessionID, ContextID: contextID, LogicalServerID: 1, PlayerID: identity.PlayerID(player%1e9 + 1),
		ContextGeneration: 3, SessionLivenessVersion: 4, ContextLivenessVersion: 5,
	}, nil
}

func (loadAuthority) ValidateActor(context.Context, identity.ActorContext, time.Time) error {
	return nil
}

type loadEndpoints struct{}

func (loadEndpoints) EndpointFor(context.Context, domainrt.PhysicalRole) (app.Endpoint, error) {
	return app.Endpoint{Host: "127.0.0.1", Port: 18954}, nil
}

type loadFanout struct {
	registry *stockruntime.ConnectionRegistry
}

func (fanout loadFanout) HandleSessionClientFrame(ctx context.Context, sender stockruntime.SessionHandle, admitted app.Admission, frame wireRT.Frame) ([]wireRT.Frame, error) {
	if frame.MID != mids.MIDSendChatMessage {
		return nil, stockruntime.ErrUnsupportedRealtimeMID
	}
	ingress, err := wireRT.ParseChannelChatIngress(frame.Params)
	if err != nil {
		return nil, err
	}
	handles, ok := fanout.registry.ByRoomRoleBounded(admitted.Domain.RoomID, admitted.Domain.Role, 4096)
	if !ok {
		return nil, stockruntime.ErrInvalidRealtimeSession
	}
	chat := &amf3.Object{Properties: []amf3.Property{
		{Name: "player_id", Value: float64(admitted.Domain.Actor.PlayerID)},
		{Name: "player_name", Value: "load"},
		{Name: "message", Value: ingress.Request.Message},
		{Name: "player_type", Value: float64(0)},
		{Name: "type", Value: float64(0)},
		{Name: "avatar_id", Value: float64(0)},
		{Name: "avatar_frame_id", Value: float64(0)},
		{Name: "lev", Value: float64(1)},
		{Name: "np_info", Value: `{"title_info":"@@@@","bubble_info":"10001@0","conquer_lev":0,"conquer_loop_id":1}`},
	}}
	for _, target := range handles {
		if err := target.Send(ctx, wireRT.Frame{MID: mids.MIDChatMessage, Params: chat}, limits.Default()); err != nil {
			return nil, err
		}
	}
	return nil, nil
}

func main() {
	address := flag.String("addr", "127.0.0.1:38961", "HTTP poll listen address")
	hold := flag.Duration("hold", 2*time.Second, "poll hold timeout")
	idle := flag.Duration("idle", 30*time.Second, "session idle timeout")
	flag.Parse()

	registry := stockruntime.NewConnectionRegistry()
	policy := stockruntime.DefaultRealtimePolicy()
	policy.MaxConnections = 4096
	policy.MaxPreauth = 4096
	policy.MaxEstablished = 4096
	server := stockruntime.RealtimeServer{
		Auth:   app.Service{Authority: loadAuthority{}, Endpoints: loadEndpoints{}},
		Limits: limits.Default(), Policy: policy, Registry: registry,
		SessionDispatcher: loadFanout{registry: registry},
	}
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()
	pollServer, err := stockruntime.NewHTTPPollServer(ctx, server, *idle, *hold)
	if err != nil {
		log.Fatal(err)
	}
	httpServer := &http.Server{Addr: *address, Handler: pollServer.Handler(), ReadHeaderTimeout: 5 * time.Second}
	go func() {
		<-ctx.Done()
		_ = httpServer.Close()
	}()
	log.Printf("realtime-load listening on %s hold=%s idle=%s", *address, *hold, *idle)
	if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
	pollServer.Close()
	os.Exit(0)
}
