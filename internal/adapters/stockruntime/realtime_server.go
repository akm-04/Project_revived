package stockruntime

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"sync"
	"time"

	app "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

var (
	ErrRealtimeNotAuthenticated = errors.New("realtime socket not authenticated")
	ErrUnsupportedRealtimeMID   = errors.New("realtime MID outside implemented surface")
	ErrMalformedHeartbeat       = errors.New("malformed stock heartbeat")
)

// ClientFrameDispatcher is the minimal post-auth extension seam. Heartbeat is
// always handled by the foundation runtime first; later I7 feature routing may
// handle other client MIDs without creating another socket writer.
type ClientFrameDispatcher interface {
	HandleClientFrame(context.Context, app.Admission, wireRT.Frame) ([]wireRT.Frame, error)
}

type RealtimeServer struct {
	Auth       app.Service
	Limits     limits.Config
	Policy     RealtimePolicy
	Tracker    *lobby.BootTracker
	Registry   *ConnectionRegistry
	Admission  *AdmissionLimiter
	Dispatcher ClientFrameDispatcher
}

type registryKey struct {
	Context string
	Role    domainrt.PhysicalRole
}

type registryEntry struct {
	Conn net.Conn
	ID   uint64
}

type ConnectionRegistry struct {
	mu   sync.Mutex
	next uint64
	by   map[registryKey]registryEntry
}

func NewConnectionRegistry() *ConnectionRegistry {
	return &ConnectionRegistry{by: make(map[registryKey]registryEntry)}
}
func (r *ConnectionRegistry) Replace(key registryKey, conn net.Conn) uint64 {
	if r == nil {
		return 0
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	r.next++
	id := r.next
	if old, ok := r.by[key]; ok && old.Conn != nil && old.Conn != conn {
		_ = old.Conn.Close()
	}
	r.by[key] = registryEntry{Conn: conn, ID: id}
	return id
}
func (r *ConnectionRegistry) Remove(key registryKey, id uint64) {
	if r == nil || id == 0 {
		return
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	if cur, ok := r.by[key]; ok && cur.ID == id {
		delete(r.by, key)
	}
}

func (s RealtimeServer) runtimeConfig() (limits.Config, RealtimePolicy, error) {
	cfg := s.Limits
	if cfg.RealtimeBufferedBytes == 0 {
		cfg = limits.Default()
	}
	if err := cfg.Validate(); err != nil {
		return limits.Config{}, RealtimePolicy{}, err
	}
	p := s.Policy
	if p.MaxConnections == 0 {
		p = DefaultRealtimePolicy()
	}
	if err := p.Validate(); err != nil {
		return limits.Config{}, RealtimePolicy{}, err
	}
	return cfg, p, nil
}

func (s RealtimeServer) ServeConn(ctx context.Context, conn net.Conn) error {
	if conn == nil {
		return errors.New("nil realtime connection")
	}
	cfg, policy, err := s.runtimeConfig()
	if err != nil {
		return err
	}
	lease, err := s.Admission.AcquirePreauth()
	if err != nil {
		return err
	}
	defer lease.Release()
	dec, err := wireRT.NewStreamDecoder(cfg)
	if err != nil {
		return err
	}
	writer, err := newConnWriter(ctx, conn, cfg, policy.WriteTimeout)
	if err != nil {
		return err
	}
	defer writer.Close()

	buf := make([]byte, 8192)
	var gate *wireRT.Gate
	roleKey := ""
	var admitted *app.Admission
	var regKey registryKey
	var regID uint64
	var sessionTag, contextTag, connectionTag string
	defer func() {
		if s.Tracker != nil && contextTag != "" && roleKey != "" {
			_ = s.Tracker.Record(lobby.BootEvent{Kind: lobby.BootClientClosed, Phase: lobby.PhaseClientState, At: time.Now().UTC(), Key: roleKey, SessionTag: sessionTag, ContextTag: contextTag, ConnectionTag: connectionTag})
		}
		if s.Registry != nil {
			s.Registry.Remove(regKey, regID)
		}
	}()

	handshakeDeadline := time.Now().Add(policy.HandshakeTimeout) // absolute; never extended by partial reads
	var lastClientActivity time.Time
	var nextLiveness time.Time
	for {
		if err := ctx.Err(); err != nil {
			return err
		}
		if admitted == nil {
			_ = conn.SetReadDeadline(handshakeDeadline)
		} else {
			idleDeadline := lastClientActivity.Add(policy.ClientIdleTimeout)
			deadline := idleDeadline
			if nextLiveness.Before(deadline) {
				deadline = nextLiveness
			}
			_ = conn.SetReadDeadline(deadline)
		}
		n, readErr := conn.Read(buf)
		now := time.Now().UTC()
		if n > 0 {
			frames, err := dec.Feed(buf[:n])
			if err != nil {
				return err
			}
			for _, f := range frames {
				if gate == nil {
					claims, err := wireRT.ParseTCPLogin(f)
					if err != nil {
						return err
					}
					authCtx, cancel := context.WithTimeout(ctx, policy.AuthQueryTimeout)
					admission, err := s.Auth.Authorize(authCtx, app.Claims{Bearer: claims.Token, Region: claims.Region, RoomID: claims.RoomID}, now)
					cancel()
					if err != nil {
						return err
					}
					pr := protocolRole(admission.Domain.Role)
					gate, err = wireRT.NewGate(pr)
					if err != nil {
						return err
					}
					if err = gate.ObserveClientFrame(f); err != nil {
						return err
					}
					if err = lease.Promote(); err != nil {
						return err
					}
					gate.MarkAuthenticated()
					roleKey = string(admission.Domain.Role)
					copyAdmission := admission
					admitted = &copyAdmission
					lastClientActivity = now
					nextLiveness = now.Add(policy.LivenessInterval)
					regKey = registryKey{Context: admission.Domain.Actor.ContextID.UUID().String(), Role: admission.Domain.Role}
					if s.Registry != nil {
						regID = s.Registry.Replace(regKey, conn)
					}
					if s.Tracker != nil {
						sessionTag, contextTag = s.Tracker.CorrelationTags(admission.Domain.Actor.SessionID.UUID().String(), admission.Domain.Actor.ContextID.UUID().String())
						connectionTag = s.Tracker.NewConnectionTag()
					}
					s.record(lobby.BootEvent{MID: mids.MIDTCPLogin, Kind: lobby.BootTCPLogin, Phase: lobby.PhaseClientRequestObserved, At: now, Key: roleKey, SessionTag: sessionTag, ContextTag: contextTag, ConnectionTag: connectionTag})
					s.record(lobby.BootEvent{Kind: lobby.BootClientConnected, Phase: lobby.PhaseClientState, At: now, Key: roleKey, SessionTag: sessionTag, ContextTag: contextTag, ConnectionTag: connectionTag})
					ack := wireRT.Frame{MID: mids.MIDChatRoomEntered, Sequence: 0, Params: &amf3.Object{Properties: []amf3.Property{{Name: "room_id", Value: float64(admission.Domain.RoomID)}}}}
					if err = writer.Send(ctx, ack, cfg); err != nil {
						return err
					}
					s.record(lobby.BootEvent{MID: mids.MIDChatRoomEntered, Kind: lobby.BootRoomEntered, Phase: lobby.PhaseTransportWriteRecorded, At: time.Now().UTC(), Key: roleKey, SessionTag: sessionTag, ContextTag: contextTag, ConnectionTag: connectionTag})
					continue
				}
				if admitted == nil {
					return ErrRealtimeNotAuthenticated
				}
				if !now.Before(nextLiveness) {
					if err := s.validateLive(ctx, policy.LivenessQueryTimeout, admitted.Domain.Actor, now); err != nil {
						return err
					}
					nextLiveness = now.Add(policy.LivenessInterval)
				}
				if err := gate.ObserveClientFrame(f); err != nil {
					return err
				}
				lastClientActivity = now
				switch f.MID {
				case mids.MIDSocketHeartbeat:
					if err := validateHeartbeat(f.Params); err != nil {
						return err
					}
					s.record(lobby.BootEvent{MID: mids.MIDSocketHeartbeat, Kind: lobby.BootHeartbeat, Phase: lobby.PhaseClientRequestObserved, At: now, Key: roleKey, SessionTag: sessionTag, ContextTag: contextTag, ConnectionTag: connectionTag})
				default:
					if s.Dispatcher == nil {
						return fmt.Errorf("%w: %d", ErrUnsupportedRealtimeMID, f.MID)
					}
					out, err := s.Dispatcher.HandleClientFrame(ctx, *admitted, f)
					if err != nil {
						return err
					}
					for _, response := range out {
						if err := writer.Send(ctx, response, cfg); err != nil {
							return err
						}
					}
				}
			}
		}
		if readErr != nil {
			if errors.Is(readErr, io.EOF) {
				return nil
			}
			if ne, ok := readErr.(net.Error); ok && ne.Timeout() {
				if admitted == nil {
					return readErr
				}
				now = time.Now().UTC()
				if !now.Before(lastClientActivity.Add(policy.ClientIdleTimeout)) {
					return ErrRealtimeClientIdle
				}
				if !now.Before(nextLiveness) {
					if err := s.validateLive(ctx, policy.LivenessQueryTimeout, admitted.Domain.Actor, now); err != nil {
						return err
					}
					nextLiveness = now.Add(policy.LivenessInterval)
				}
				continue
			}
			return readErr
		}
	}
}

func (s RealtimeServer) validateLive(ctx context.Context, timeout time.Duration, actor identity.ActorContext, now time.Time) error {
	queryCtx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	return s.Auth.ValidateActor(queryCtx, actor, now)
}

func (s RealtimeServer) record(e lobby.BootEvent) {
	if s.Tracker != nil {
		_ = s.Tracker.Record(e)
	}
}
func protocolRole(r domainrt.PhysicalRole) wireRT.Role {
	switch r {
	case domainrt.World:
		return wireRT.World
	case domainrt.Guild:
		return wireRT.Guild
	default:
		return wireRT.Service
	}
}
func validateHeartbeat(v any) error {
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return ErrMalformedHeartbeat
	}
	m, err := o.StrictMap()
	if err != nil || len(m) != 0 {
		return ErrMalformedHeartbeat
	}
	return nil
}
