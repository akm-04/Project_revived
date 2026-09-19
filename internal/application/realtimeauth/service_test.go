package realtimeauth

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/ids"
)

type fakeAuthority struct {
	actor identity.ActorContext
	err   error
}

func (f fakeAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return f.actor, f.err
}

type fakeGuild struct {
	id int64
	ok bool
}

func (f fakeGuild) GuildRoom(context.Context, identity.ActorContext) (int64, bool, error) {
	return f.id, f.ok, nil
}

type fakeEndpoints struct{}

func (fakeEndpoints) EndpointFor(context.Context, domainrt.PhysicalRole) (Endpoint, error) {
	return Endpoint{Host: "127.0.0.1", Port: 19090}, nil
}

func testActor(t *testing.T) identity.ActorContext {
	u, _ := ids.ParseUUID("22222222-2222-4222-8222-222222222222")
	cid, _ := identity.ContextIDFrom(u)
	return identity.ActorContext{ContextID: cid, LogicalServerID: 2, PlayerID: 200001}
}

func TestAuthorizeDerivesRoleFromCanonicalActorAndRoom(t *testing.T) {
	s := Service{Authority: fakeAuthority{actor: testActor(t)}, Guilds: fakeGuild{id: 77, ok: true}, Endpoints: fakeEndpoints{}}
	for _, tc := range []struct {
		room int64
		want domainrt.PhysicalRole
	}{{2, domainrt.World}, {99999, domainrt.Service}, {77, domainrt.Guild}} {
		got, err := s.Authorize(context.Background(), Claims{Bearer: "b", Region: 2, RoomID: tc.room}, time.Now())
		if err != nil {
			t.Fatal(err)
		}
		if got.Domain.Role != tc.want {
			t.Fatalf("room %d role=%s want=%s", tc.room, got.Domain.Role, tc.want)
		}
	}
}
func TestAuthorizeRejectsForgedRegionAndRoom(t *testing.T) {
	s := Service{Authority: fakeAuthority{actor: testActor(t)}, Guilds: fakeGuild{id: 77, ok: true}}
	if _, err := s.Authorize(context.Background(), Claims{Bearer: "b", Region: 1, RoomID: 1}, time.Now()); !errors.Is(err, ErrRegionMismatch) {
		t.Fatalf("err=%v", err)
	}
	if _, err := s.Authorize(context.Background(), Claims{Bearer: "b", Region: 2, RoomID: 88}, time.Now()); !errors.Is(err, domainrt.ErrRoomNotAuthorized) {
		t.Fatalf("err=%v", err)
	}
}

func TestAuthorizeFreshGuildAdmissionRechecksCurrentMembership(t *testing.T) {
	guilds := &fakeGuild{id: 2_000_001, ok: true}
	s := Service{Authority: fakeAuthority{actor: testActor(t)}, Guilds: guilds, Endpoints: fakeEndpoints{}}
	now := time.Unix(1_700_000_000, 0).UTC()

	got, err := s.Authorize(context.Background(), Claims{Bearer: "b", Region: 2, RoomID: guilds.id}, now)
	if err != nil {
		t.Fatal(err)
	}
	if got.Domain.Role != domainrt.Guild {
		t.Fatalf("initial role=%s want=%s", got.Domain.Role, domainrt.Guild)
	}

	// Model a committed leave/kick/dissolve before a fresh/reconnect TCP_LOGIN.
	// Admission must use current canonical membership rather than a prior MID192 result.
	guilds.ok = false
	if _, err := s.Authorize(context.Background(), Claims{Bearer: "b", Region: 2, RoomID: guilds.id}, now.Add(time.Second)); !errors.Is(err, domainrt.ErrRoomNotAuthorized) {
		t.Fatalf("removed member guild admission err=%v", err)
	}

	// Removing Guild membership must not disturb the independent WORLD/SERVICE roles.
	for _, tc := range []struct {
		room int64
		want domainrt.PhysicalRole
	}{{2, domainrt.World}, {domainrt.ServiceRoomID, domainrt.Service}} {
		got, err := s.Authorize(context.Background(), Claims{Bearer: "b", Region: 2, RoomID: tc.room}, now.Add(2*time.Second))
		if err != nil {
			t.Fatalf("room %d: %v", tc.room, err)
		}
		if got.Domain.Role != tc.want {
			t.Fatalf("room %d role=%s want=%s", tc.room, got.Domain.Role, tc.want)
		}
	}
}
