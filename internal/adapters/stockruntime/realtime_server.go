package stockruntime

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"time"

	app "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/application/socialpresence"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
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

// PresenceProjection is the narrow I7A-3 adapter seam. Projection failures are
// observable but never become a second gameplay/session authorization gate.
type PresenceProjection interface {
	Admit(context.Context, operation.Context, socialpresence.LeaseRef, time.Duration) error
	Renew(context.Context, operation.Context, socialpresence.LeaseRef, time.Duration) error
	Retire(context.Context, operation.Context, socialpresence.LeaseRef) error
}

type PresenceErrorHandler func(stage string, err error)

type RealtimeServer struct {
	Auth               app.Service
	Limits             limits.Config
	Policy             RealtimePolicy
	Tracker            *lobby.BootTracker
	Registry           *ConnectionRegistry
	Admission          *AdmissionLimiter
	Dispatcher         ClientFrameDispatcher
	Presence           PresenceProjection
	PresenceOperations operation.Factory
	RealtimeOwnerFence int64
	RealtimeInstanceID ids.UUID
	OnPresenceError    PresenceErrorHandler
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
	if s.Presence != nil {
		if s.Registry == nil || s.PresenceOperations.Clock == nil || s.RealtimeOwnerFence <= 0 || s.RealtimeInstanceID.IsZero() {
			return limits.Config{}, RealtimePolicy{}, errors.New("realtime presence integration incomplete")
		}
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
	var regHandle SessionHandle
	var sessionTag, contextTag, connectionTag string
	defer func() {
		if s.Tracker != nil && contextTag != "" && roleKey != "" {
			_ = s.Tracker.Record(lobby.BootEvent{Kind: lobby.BootClientClosed, Phase: lobby.PhaseClientState, At: time.Now().UTC(), Key: roleKey, SessionTag: sessionTag, ContextTag: contextTag, ConnectionTag: connectionTag})
		}
		removedCurrent := false
		if s.Registry != nil {
			removedCurrent = s.Registry.Remove(regHandle)
		}
		if removedCurrent && admitted != nil && s.Presence != nil {
			s.projectPresenceRetire(ctx, policy.LivenessQueryTimeout, regHandle)
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
					if s.Registry != nil {
						regHandle, err = s.Registry.Replace(admission.Domain, writer)
						if err != nil {
							return err
						}
					}
					if s.Presence != nil {
						s.projectPresenceAdmit(ctx, policy.LivenessQueryTimeout, regHandle, policy.ClientIdleTimeout)
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
					if err := s.validateLive(ctx, policy.LivenessQueryTimeout, *admitted, now); err != nil {
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
					if s.Presence != nil {
						s.projectPresenceRenew(ctx, policy.LivenessQueryTimeout, regHandle, policy.ClientIdleTimeout)
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
					if err := s.validateLive(ctx, policy.LivenessQueryTimeout, *admitted, now); err != nil {
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

func (s RealtimeServer) validateLive(ctx context.Context, timeout time.Duration, admitted app.Admission, now time.Time) error {
	queryCtx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	return s.Auth.ValidateAdmission(queryCtx, admitted, now)
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
func (s RealtimeServer) presenceRef(h SessionHandle) (socialpresence.LeaseRef, error) {
	meta, ok := h.Metadata()
	if !ok || s.RealtimeOwnerFence <= 0 || s.RealtimeInstanceID.IsZero() {
		return socialpresence.LeaseRef{}, socialpresence.ErrInvalidLease
	}
	ref := socialpresence.LeaseRef{
		PlayerID: meta.PlayerID, ContextID: meta.ContextID, Role: meta.PhysicalRole,
		RealtimeOwnerFence: s.RealtimeOwnerFence, RealtimeInstanceID: s.RealtimeInstanceID, ConnectionGeneration: meta.RegistryGeneration,
	}
	return ref, ref.Validate()
}

func (s RealtimeServer) newPresenceOperation() (operation.Context, error) {
	return s.PresenceOperations.New(policy.Set{})
}

func (s RealtimeServer) presenceError(stage string, err error) {
	if err != nil && s.OnPresenceError != nil {
		s.OnPresenceError(stage, err)
	}
}

func (s RealtimeServer) projectPresenceAdmit(ctx context.Context, timeout time.Duration, h SessionHandle, ttl time.Duration) {
	ref, err := s.presenceRef(h)
	if err != nil {
		s.presenceError("admit", err)
		return
	}
	op, err := s.newPresenceOperation()
	if err != nil {
		s.presenceError("admit", err)
		return
	}
	qctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	s.presenceError("admit", s.Presence.Admit(qctx, op, ref, ttl))
}

func (s RealtimeServer) projectPresenceRenew(ctx context.Context, timeout time.Duration, h SessionHandle, ttl time.Duration) {
	ref, err := s.presenceRef(h)
	if err != nil {
		s.presenceError("renew", err)
		return
	}
	op, err := s.newPresenceOperation()
	if err != nil {
		s.presenceError("renew", err)
		return
	}
	qctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	s.presenceError("renew", s.Presence.Renew(qctx, op, ref, ttl))
}

func (s RealtimeServer) projectPresenceRetire(ctx context.Context, timeout time.Duration, h SessionHandle) {
	ref, err := s.presenceRef(h)
	if err != nil {
		s.presenceError("retire", err)
		return
	}
	op, err := s.newPresenceOperation()
	if err != nil {
		s.presenceError("retire", err)
		return
	}
	qctx, cancel := context.WithTimeout(context.WithoutCancel(ctx), timeout)
	defer cancel()
	s.presenceError("retire", s.Presence.Retire(qctx, op, ref))
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
