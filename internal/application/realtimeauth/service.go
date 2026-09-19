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
	ErrEmptyBearer    = errors.New("empty gameplay bearer")
	ErrRegionMismatch = errors.New("realtime region does not match live gameplay context")
	ErrNoEndpoint     = errors.New("realtime endpoint unavailable")
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

// GuildMembershipPort is an authority seam only. I4 does not create Guild
// domain state; later Guild work can implement this port from canonical state.
type GuildMembershipPort interface {
	GuildRoom(context.Context, identity.ActorContext) (int64, bool, error)
}

type Endpoint struct {
	Host string
	Port int
}

type EndpointPort interface {
	EndpointFor(context.Context, domainrt.PhysicalRole) (Endpoint, error)
}

type Admission struct {
	Domain   domainrt.Admission
	Endpoint Endpoint
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
	if s.Guilds != nil {
		id, ok, err := s.Guilds.GuildRoom(ctx, actor)
		if err != nil {
			return Admission{}, err
		}
		if ok {
			guildID = id
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
	return Admission{Domain: d, Endpoint: endpoint}, nil
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
