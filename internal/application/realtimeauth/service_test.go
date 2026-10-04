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
	actor   identity.ActorContext
	err     error
	liveErr error
}

func (f fakeAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return f.actor, f.err
}
func (f fakeAuthority) ValidateActor(context.Context, identity.ActorContext, time.Time) error {
	return f.liveErr
}

type fakeGuild struct {
	binding GuildBinding
	ok      bool
	err     error
}

func (f *fakeGuild) CurrentGuildBinding(context.Context, identity.ActorContext) (GuildBinding, bool, error) {
	return f.binding, f.ok, f.err
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
	s := Service{Authority: fakeAuthority{actor: testActor(t)}, Guilds: &fakeGuild{binding: GuildBinding{GuildID: 77, JoinEventID: 9}, ok: true}, Endpoints: fakeEndpoints{}}
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
	s := Service{Authority: fakeAuthority{actor: testActor(t)}, Guilds: &fakeGuild{binding: GuildBinding{GuildID: 77, JoinEventID: 9}, ok: true}}
	if _, err := s.Authorize(context.Background(), Claims{Bearer: "b", Region: 1, RoomID: 1}, time.Now()); !errors.Is(err, ErrRegionMismatch) {
		t.Fatalf("err=%v", err)
	}
	if _, err := s.Authorize(context.Background(), Claims{Bearer: "b", Region: 2, RoomID: 88}, time.Now()); !errors.Is(err, domainrt.ErrRoomNotAuthorized) {
		t.Fatalf("err=%v", err)
	}
}

func TestAuthorizeFreshGuildAdmissionRechecksCurrentMembership(t *testing.T) {
	guilds := &fakeGuild{binding: GuildBinding{GuildID: 2_000_001, JoinEventID: 90}, ok: true}
	s := Service{Authority: fakeAuthority{actor: testActor(t)}, Guilds: guilds, Endpoints: fakeEndpoints{}}
	now := time.Unix(1_700_000_000, 0).UTC()

	got, err := s.Authorize(context.Background(), Claims{Bearer: "b", Region: 2, RoomID: guilds.binding.GuildID}, now)
	if err != nil {
		t.Fatal(err)
	}
	if got.Domain.Role != domainrt.Guild {
		t.Fatalf("initial role=%s want=%s", got.Domain.Role, domainrt.Guild)
	}

	// Model a committed leave/kick/dissolve before a fresh/reconnect TCP_LOGIN.
	// Admission must use current canonical membership rather than a prior MID192 result.
	guilds.ok = false
	if _, err := s.Authorize(context.Background(), Claims{Bearer: "b", Region: 2, RoomID: guilds.binding.GuildID}, now.Add(time.Second)); !errors.Is(err, domainrt.ErrRoomNotAuthorized) {
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

func TestGuildAdmissionSnapshotsAndRevalidatesJoinIncarnation(t *testing.T) {
	guilds := &fakeGuild{binding: GuildBinding{GuildID: 2_000_001, JoinEventID: 101}, ok: true}
	svc := Service{Authority: fakeAuthority{actor: testActor(t)}, Guilds: guilds, Endpoints: fakeEndpoints{}}
	now := time.Unix(1_700_000_100, 0).UTC()
	admitted, err := svc.Authorize(context.Background(), Claims{Bearer: "b", Region: 2, RoomID: guilds.binding.GuildID}, now)
	if err != nil {
		t.Fatal(err)
	}
	if admitted.GuildBinding == nil || *admitted.GuildBinding != guilds.binding {
		t.Fatalf("binding=%v", admitted.GuildBinding)
	}
	if err := svc.ValidateAdmission(context.Background(), admitted, now.Add(time.Second)); err != nil {
		t.Fatal(err)
	}

	// A role-only change is not represented by a new JOIN event and therefore
	// leaves the incarnation stable. Simulating that means the binding is unchanged.
	if err := svc.ValidateAdmission(context.Background(), admitted, now.Add(2*time.Second)); err != nil {
		t.Fatal(err)
	}

	// Leave->rejoin to the same Guild creates a new non-reused JOIN event ID.
	guilds.binding.JoinEventID++
	if err := svc.ValidateAdmission(context.Background(), admitted, now.Add(3*time.Second)); !errors.Is(err, ErrGuildBindingStale) {
		t.Fatalf("rejoined incarnation err=%v", err)
	}
}

func TestGuildAdmissionLivenessFailsClosedWhenMembershipDisappears(t *testing.T) {
	guilds := &fakeGuild{binding: GuildBinding{GuildID: 2_000_001, JoinEventID: 202}, ok: true}
	svc := Service{Authority: fakeAuthority{actor: testActor(t)}, Guilds: guilds, Endpoints: fakeEndpoints{}}
	admitted, err := svc.Authorize(context.Background(), Claims{Bearer: "b", Region: 2, RoomID: guilds.binding.GuildID}, time.Now())
	if err != nil {
		t.Fatal(err)
	}
	guilds.ok = false
	if err := svc.ValidateAdmission(context.Background(), admitted, time.Now()); !errors.Is(err, ErrGuildBindingStale) {
		t.Fatalf("err=%v", err)
	}
}

func TestWorldAndServiceAdmissionDoNotDependOnGuildRead(t *testing.T) {
	guilds := &fakeGuild{err: errors.New("guild db unavailable")}
	svc := Service{Authority: fakeAuthority{actor: testActor(t)}, Guilds: guilds, Endpoints: fakeEndpoints{}}
	for _, room := range []int64{2, domainrt.ServiceRoomID} {
		if _, err := svc.Authorize(context.Background(), Claims{Bearer: "b", Region: 2, RoomID: room}, time.Now()); err != nil {
			t.Fatalf("room %d depended on Guild read: %v", room, err)
		}
	}
}
