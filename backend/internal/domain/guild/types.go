package guild

import (
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

type ID int64

type Role int16

const (
	Member Role = iota
	Leader
	Deputy
)

func (r Role) Valid() bool { return r == Member || r == Leader || r == Deputy }

type ApplyType int16

const (
	ApplyByApplication ApplyType = iota
	ApplyImmediate
	ApplyClosed
)

func (a ApplyType) Valid() bool { return a >= ApplyByApplication && a <= ApplyClosed }

type Guild struct {
	ID              ID
	LogicalServerID identity.LogicalServerID
	Name            string
	Icon            int64
	IconFrame       int64
	Description     string
	ApplyType       ApplyType
	MinAllowLevel   int64
	Vitality        int64
	PolicyRevision  string
	StateVersion    int64
	CreatedAt       time.Time
	UpdatedAt       time.Time
	RetiredAt       *time.Time
}

func (g Guild) Validate() error {
	if g.ID <= 0 || !g.LogicalServerID.Valid() {
		return errors.New("guild identity required")
	}
	if int64(g.ID)/1_000_000 != int64(g.LogicalServerID) {
		return errors.New("guild id/logical server mismatch")
	}
	if g.Name == "" || g.Icon <= 0 || g.IconFrame < 0 || !g.ApplyType.Valid() || g.MinAllowLevel <= 0 || g.Vitality < 0 || g.PolicyRevision == "" || g.StateVersion <= 0 || g.CreatedAt.IsZero() || g.UpdatedAt.IsZero() {
		return errors.New("invalid guild")
	}
	if g.RetiredAt != nil && g.RetiredAt.IsZero() {
		return errors.New("invalid retired_at")
	}
	return nil
}

type Membership struct {
	PlayerID          identity.PlayerID
	GuildID           ID
	Role              Role
	JoinedAt          time.Time
	MembershipVersion int64
	StateVersion      int64
	UpdatedAt         time.Time
}

func (m Membership) Validate() error {
	if !m.PlayerID.Valid() || m.GuildID <= 0 || !m.Role.Valid() || m.JoinedAt.IsZero() || m.MembershipVersion <= 0 || m.StateVersion <= 0 || m.UpdatedAt.IsZero() {
		return errors.New("invalid guild membership")
	}
	return nil
}

type Application struct {
	GuildID      ID
	PlayerID     identity.PlayerID
	Generation   int64
	CreatedAt    time.Time
	StateVersion int64
}

func (a Application) Validate() error {
	if a.GuildID <= 0 || !a.PlayerID.Valid() || a.Generation <= 0 || a.CreatedAt.IsZero() || a.StateVersion <= 0 {
		return errors.New("invalid guild application")
	}
	return nil
}

type Invite struct {
	GuildID         ID
	InvitedPlayerID identity.PlayerID
	Generation      int64
	InviterPlayerID identity.PlayerID
	CreatedAt       time.Time
	ExpiresAt       time.Time
	StateVersion    int64
}

func (i Invite) Validate() error {
	if i.GuildID <= 0 || !i.InvitedPlayerID.Valid() || !i.InviterPlayerID.Valid() || i.Generation <= 0 || i.CreatedAt.IsZero() || !i.ExpiresAt.After(i.CreatedAt) || i.StateVersion <= 0 {
		return errors.New("invalid guild invite")
	}
	return nil
}

type MembershipEventKind string

const (
	EventJoin     MembershipEventKind = "JOIN"
	EventLeave    MembershipEventKind = "LEAVE"
	EventKick     MembershipEventKind = "KICK"
	EventDissolve MembershipEventKind = "DISSOLVE"
)

func (k MembershipEventKind) Valid() bool {
	return k == EventJoin || k == EventLeave || k == EventKick || k == EventDissolve
}

type MembershipEvent struct {
	EventID        int64
	PlayerID       identity.PlayerID
	GuildID        ID
	Kind           MembershipEventKind
	OccurredAt     time.Time
	ActorPlayerID  identity.PlayerID
	PolicyRevision string
}

func (e MembershipEvent) Validate() error {
	if !e.PlayerID.Valid() || e.GuildID <= 0 || !e.Kind.Valid() || e.OccurredAt.IsZero() || !e.ActorPlayerID.Valid() || e.PolicyRevision == "" {
		return errors.New("invalid guild membership event")
	}
	return nil
}

func WireID(server identity.LogicalServerID, serial int64) (ID, error) {
	if !server.Valid() || serial < 1 || serial > 999999 {
		return 0, errors.New("invalid guild allocator input")
	}
	id := ID(int64(server)*1_000_000 + serial)
	if int64(id)/1_000_000 != int64(server) {
		return 0, fmt.Errorf("guild id band overflow")
	}
	return id, nil
}
