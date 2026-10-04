package stockruntime

import (
	"context"
	"errors"
	"net"
	"sort"
	"sync"

	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/protocol/limits"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

var (
	ErrRealtimeSessionRetired = errors.New("realtime session handle retired")
	ErrInvalidRealtimeSession = errors.New("invalid realtime session registration")
)

type registryKey struct {
	Context identity.ContextID
	Role    domainrt.PhysicalRole
}

type playerRoleKey struct {
	Player identity.PlayerID
	Role   domainrt.PhysicalRole
}

type roomRoleKey struct {
	Room int64
	Role domainrt.PhysicalRole
}

// SessionMetadata is the immutable admission/liveness snapshot attached to one
// physical realtime socket generation. It is routing evidence only; canonical
// gameplay and identity truth remain with their existing owners.
type SessionMetadata struct {
	AccountID              identity.AccountID
	AccountUID             identity.AccountUID
	SessionID              identity.SessionID
	ContextID              identity.ContextID
	LogicalServerID        identity.LogicalServerID
	PlayerID               identity.PlayerID
	ContextGeneration      int64
	SessionLivenessVersion int64
	ContextLivenessVersion int64
	PhysicalRole           domainrt.PhysicalRole
	RoomID                 int64
	RegistryGeneration     uint64
}

func (m SessionMetadata) valid() bool {
	return !m.AccountID.UUID().IsZero() && m.AccountUID.Valid() && !m.SessionID.UUID().IsZero() &&
		!m.ContextID.UUID().IsZero() && m.LogicalServerID.Valid() && m.PlayerID.Valid() &&
		m.ContextGeneration > 0 && m.SessionLivenessVersion > 0 && m.ContextLivenessVersion > 0 &&
		m.PhysicalRole.Valid() && m.RoomID > 0 && m.RegistryGeneration > 0
}

type registrySession struct {
	meta   SessionMetadata
	writer *connWriter
	conn   net.Conn

	lifecycle sync.Mutex
	retired   bool
}

// SessionHandle is an immutable feature-facing publication capability. It never
// exposes net.Conn or permits construction of another writer. A snapshotted
// handle remains safe across replacement: once retirement linearizes, new Send
// calls fail with ErrRealtimeSessionRetired.
type SessionHandle struct{ session *registrySession }

func (h SessionHandle) Valid() bool { return h.session != nil && h.session.meta.valid() }
func (h SessionHandle) Metadata() (SessionMetadata, bool) {
	if !h.Valid() {
		return SessionMetadata{}, false
	}
	return h.session.meta, true
}
func (h SessionHandle) RegistryGeneration() uint64 {
	if h.session == nil {
		return 0
	}
	return h.session.meta.RegistryGeneration
}
func (h SessionHandle) Send(ctx context.Context, frame wireRT.Frame, cfg limits.Config) error {
	if h.session == nil || h.session.writer == nil {
		return ErrRealtimeSessionRetired
	}
	s := h.session
	// The lifecycle mutex protects only admission into the existing writer
	// queue. It is deliberately released before waiting for conn.Write so that
	// retirement can close the private socket and interrupt blocked I/O.
	s.lifecycle.Lock()
	if s.retired {
		s.lifecycle.Unlock()
		return ErrRealtimeSessionRetired
	}
	done, err := s.writer.enqueue(ctx, frame, cfg)
	s.lifecycle.Unlock()
	if err != nil {
		return err
	}
	return s.writer.await(ctx, done)
}

func (s *registrySession) retire() {
	if s == nil {
		return
	}
	s.lifecycle.Lock()
	if s.retired {
		s.lifecycle.Unlock()
		return
	}
	s.retired = true
	s.lifecycle.Unlock()

	// Closing the socket first interrupts an in-progress/blocked writer. The
	// writer owns every conn.Write; the registry only owns private teardown.
	if s.conn != nil {
		_ = s.conn.Close()
	}
	if s.writer != nil {
		s.writer.Close()
	}
}

// ConnectionRegistry is the process-local I4 index of admitted physical
// realtime sockets. The authoritative primary identity remains context+role;
// secondary indices are delivery projections and never collapse all contexts
// for one player into a global winner.
type ConnectionRegistry struct {
	mu       sync.Mutex
	next     uint64
	by       map[registryKey]*registrySession
	byPlayer map[playerRoleKey]map[uint64]*registrySession
	byRoom   map[roomRoleKey]map[uint64]*registrySession
}

func NewConnectionRegistry() *ConnectionRegistry {
	return &ConnectionRegistry{
		by:       make(map[registryKey]*registrySession),
		byPlayer: make(map[playerRoleKey]map[uint64]*registrySession),
		byRoom:   make(map[roomRoleKey]map[uint64]*registrySession),
	}
}

// Replace installs the newest generation for context+physical-role. Registry
// mutation and index removal occur under r.mu; socket/writer teardown occurs
// only after that mutex is released.
func (r *ConnectionRegistry) Replace(admission domainrt.Admission, writer *connWriter) (SessionHandle, error) {
	if r == nil || writer == nil || writer.conn == nil || !admission.Role.Valid() || admission.RoomID <= 0 {
		return SessionHandle{}, ErrInvalidRealtimeSession
	}
	a := admission.Actor
	if a.AccountID.UUID().IsZero() || !a.AccountUID.Valid() || a.SessionID.UUID().IsZero() || a.ContextID.UUID().IsZero() ||
		!a.LogicalServerID.Valid() || !a.PlayerID.Valid() || a.ContextGeneration <= 0 || a.SessionLivenessVersion <= 0 || a.ContextLivenessVersion <= 0 {
		return SessionHandle{}, ErrInvalidRealtimeSession
	}

	key := registryKey{Context: a.ContextID, Role: admission.Role}
	var old *registrySession

	r.mu.Lock()
	r.next++
	s := &registrySession{meta: SessionMetadata{
		AccountID: a.AccountID, AccountUID: a.AccountUID, SessionID: a.SessionID, ContextID: a.ContextID,
		LogicalServerID: a.LogicalServerID, PlayerID: a.PlayerID, ContextGeneration: a.ContextGeneration,
		SessionLivenessVersion: a.SessionLivenessVersion, ContextLivenessVersion: a.ContextLivenessVersion,
		PhysicalRole: admission.Role, RoomID: admission.RoomID, RegistryGeneration: r.next,
	}, writer: writer, conn: writer.conn}
	old = r.by[key]
	if old != nil {
		r.removeIndicesLocked(old)
	}
	r.by[key] = s
	r.addIndicesLocked(s)
	r.mu.Unlock()

	if old != nil && old != s {
		old.retire()
	}
	return SessionHandle{session: s}, nil
}

// Remove deletes only the exact generation represented by h. A stale ServeConn
// defer cannot remove a newer replacement for the same context+role.
func (r *ConnectionRegistry) Remove(h SessionHandle) {
	if r == nil || h.session == nil {
		return
	}
	s := h.session
	key := registryKey{Context: s.meta.ContextID, Role: s.meta.PhysicalRole}
	removed := false
	r.mu.Lock()
	if cur := r.by[key]; cur == s && cur.meta.RegistryGeneration == s.meta.RegistryGeneration {
		delete(r.by, key)
		r.removeIndicesLocked(s)
		removed = true
	}
	r.mu.Unlock()
	if removed {
		s.retire()
	}
}

func (r *ConnectionRegistry) ByPlayerRole(playerID identity.PlayerID, role domainrt.PhysicalRole) []SessionHandle {
	if r == nil || !playerID.Valid() || !role.Valid() {
		return nil
	}
	r.mu.Lock()
	out := snapshotSessions(r.byPlayer[playerRoleKey{Player: playerID, Role: role}])
	r.mu.Unlock()
	return out
}

func (r *ConnectionRegistry) ByRoomRole(roomID int64, role domainrt.PhysicalRole) []SessionHandle {
	if r == nil || roomID <= 0 || !role.Valid() {
		return nil
	}
	r.mu.Lock()
	out := snapshotSessions(r.byRoom[roomRoleKey{Room: roomID, Role: role}])
	r.mu.Unlock()
	return out
}

func (r *ConnectionRegistry) addIndicesLocked(s *registrySession) {
	pk := playerRoleKey{Player: s.meta.PlayerID, Role: s.meta.PhysicalRole}
	if r.byPlayer[pk] == nil {
		r.byPlayer[pk] = make(map[uint64]*registrySession)
	}
	r.byPlayer[pk][s.meta.RegistryGeneration] = s
	rk := roomRoleKey{Room: s.meta.RoomID, Role: s.meta.PhysicalRole}
	if r.byRoom[rk] == nil {
		r.byRoom[rk] = make(map[uint64]*registrySession)
	}
	r.byRoom[rk][s.meta.RegistryGeneration] = s
}

func (r *ConnectionRegistry) removeIndicesLocked(s *registrySession) {
	pk := playerRoleKey{Player: s.meta.PlayerID, Role: s.meta.PhysicalRole}
	if bucket := r.byPlayer[pk]; bucket != nil {
		delete(bucket, s.meta.RegistryGeneration)
		if len(bucket) == 0 {
			delete(r.byPlayer, pk)
		}
	}
	rk := roomRoleKey{Room: s.meta.RoomID, Role: s.meta.PhysicalRole}
	if bucket := r.byRoom[rk]; bucket != nil {
		delete(bucket, s.meta.RegistryGeneration)
		if len(bucket) == 0 {
			delete(r.byRoom, rk)
		}
	}
}

func snapshotSessions(in map[uint64]*registrySession) []SessionHandle {
	if len(in) == 0 {
		return nil
	}
	gens := make([]uint64, 0, len(in))
	for gen := range in {
		gens = append(gens, gen)
	}
	sort.Slice(gens, func(i, j int) bool { return gens[i] < gens[j] })
	out := make([]SessionHandle, 0, len(gens))
	for _, gen := range gens {
		out = append(out, SessionHandle{session: in[gen]})
	}
	return out
}
