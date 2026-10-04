package realtimeauth

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
)

var (
	ErrEmptyBearer       = errors.New("empty gameplay bearer")
	ErrRegionMismatch    = errors.New("realtime region does not match live gameplay context")
	ErrNoEndpoint        = errors.New("realtime endpoint unavailable")
	ErrGuildBindingStale = errors.New("realtime guild membership incarnation is no longer current")
)

type Claims struct {
	Bearer string
	Region int64
	RoomID int64
}

type GameplayAuthorityPort interface {
	ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error)
}

// GameplayLivenessPort revalidates a previously admitted actor without retaining
// or replaying the raw gameplay bearer on the realtime connection.
type GameplayLivenessPort interface {
	ValidateActor(context.Context, identity.ActorContext, time.Time) error
}

// GuildBinding is the canonical I6C membership incarnation needed by a GUILD
// realtime socket. JoinEventID is the non-reused same-Guild JOIN event identity;
// membership_version is deliberately not used as an incarnation fence.
type GuildBinding struct {
	GuildID     int64
	JoinEventID int64
}

func (b GuildBinding) Valid() bool { return b.GuildID > 0 && b.JoinEventID > 0 }

// GuildMembershipPort is a read-only authority seam into canonical I6C Guild
// membership state. Realtime never mutates Guild ownership.
type GuildMembershipPort interface {
	CurrentGuildBinding(context.Context, identity.ActorContext) (GuildBinding, bool, error)
}

type Endpoint struct {
	Host string
	Port int
}

type EndpointPort interface {
	EndpointFor(context.Context, domainrt.PhysicalRole) (Endpoint, error)
}

type Admission struct {
	Domain       domainrt.Admission
	Endpoint     Endpoint
	GuildBinding *GuildBinding
}

type Service struct {
	Authority GameplayAuthorityPort
	Guilds    GuildMembershipPort
	Endpoints EndpointPort
}

func (s Service) Authorize(ctx context.Context, c Claims, now time.Time) (Admission, error) {
	if s.Authority == nil {
		return Admission{}, errors.New("gameplay authority port required")
	}
	if c.Bearer == "" {
		return Admission{}, ErrEmptyBearer
	}
	actor, err := s.Authority.ResolveGameplayBearer(ctx, c.Bearer, now)
	if err != nil {
		return Admission{}, err
	}
	if c.Region != int64(actor.LogicalServerID) {
		return Admission{}, fmt.Errorf("%w: claimed=%d canonical=%d", ErrRegionMismatch, c.Region, actor.LogicalServerID)
	}

	guildID := int64(0)
	var guildBinding *GuildBinding
	// WORLD and SERVICE are independent of Guild availability. Only a room that
	// is not one of those canonical rooms needs the I6C binding read.
	if c.RoomID != int64(actor.LogicalServerID) && c.RoomID != domainrt.ServiceRoomID && s.Guilds != nil {
		binding, ok, err := s.Guilds.CurrentGuildBinding(ctx, actor)
		if err != nil {
			return Admission{}, err
		}
		if ok && binding.Valid() {
			guildID = binding.GuildID
			b := binding
			guildBinding = &b
		}
	}
	role := classifyRoom(actor, c.RoomID, guildID)
	if !role.Valid() {
		return Admission{}, domainrt.ErrRoomNotAuthorized
	}
	d, err := domainrt.AuthorizeRoom(actor, role, c.RoomID, guildID)
	if err != nil {
		return Admission{}, err
	}
	var endpoint Endpoint
	if s.Endpoints != nil {
		endpoint, err = s.Endpoints.EndpointFor(ctx, role)
		if err != nil {
			return Admission{}, err
		}
		if endpoint.Host == "" || endpoint.Port <= 0 || endpoint.Port > 65535 {
			return Admission{}, ErrNoEndpoint
		}
	}
	return Admission{Domain: d, Endpoint: endpoint, GuildBinding: guildBinding}, nil
}

func (s Service) Discover(ctx context.Context, c Claims, now time.Time) (Admission, error) {
	if s.Endpoints == nil {
		return Admission{}, ErrNoEndpoint
	}
	return s.Authorize(ctx, c, now)
}

func (s Service) ValidateActor(ctx context.Context, actor identity.ActorContext, now time.Time) error {
	live, ok := s.Authority.(GameplayLivenessPort)
	if !ok {
		return errors.New("gameplay authority does not provide liveness fencing")
	}
	return live.ValidateActor(ctx, actor, now)
}

// ValidateAdmission revalidates an established physical socket without keeping
// the raw bearer. WORLD/SERVICE need only I4 actor liveness. GUILD additionally
// requires the exact I6C JOIN incarnation observed at admission.
func (s Service) ValidateAdmission(ctx context.Context, admitted Admission, now time.Time) error {
	if err := s.ValidateActor(ctx, admitted.Domain.Actor, now); err != nil {
		return err
	}
	if admitted.Domain.Role != domainrt.Guild {
		return nil
	}
	if s.Guilds == nil || admitted.GuildBinding == nil || !admitted.GuildBinding.Valid() {
		return ErrGuildBindingStale
	}
	current, ok, err := s.Guilds.CurrentGuildBinding(ctx, admitted.Domain.Actor)
	if err != nil {
		return err
	}
	if !ok || !current.Valid() || current != *admitted.GuildBinding {
		return ErrGuildBindingStale
	}
	return nil
}

func classifyRoom(actor identity.ActorContext, roomID, guildID int64) domainrt.PhysicalRole {
	switch {
	case roomID == int64(actor.LogicalServerID):
		return domainrt.World
	case roomID == domainrt.ServiceRoomID:
		return domainrt.Service
	case guildID > 0 && roomID == guildID:
		return domainrt.Guild
	default:
		return ""
	}
}
