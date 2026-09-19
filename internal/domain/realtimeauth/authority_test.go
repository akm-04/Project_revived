package realtimeauth

import (
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

func actor(t *testing.T) identity.ActorContext {
	t.Helper()
	u := func() ids.UUID {
		x, err := ids.ParseUUID("11111111-1111-4111-8111-111111111111")
		if err != nil {
			t.Fatal(err)
		}
		return x
	}
	cid, _ := identity.ContextIDFrom(u())
	return identity.ActorContext{ContextID: cid, LogicalServerID: 2, PlayerID: 200001}
}

func TestAuthorizeRoomStockRoles(t *testing.T) {
	a := actor(t)
	if _, err := AuthorizeRoom(a, World, 2, 0); err != nil {
		t.Fatal(err)
	}
	if _, err := AuthorizeRoom(a, Service, ServiceRoomID, 0); err != nil {
		t.Fatal(err)
	}
	if _, err := AuthorizeRoom(a, Guild, 77, 77); err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct {
		role        PhysicalRole
		room, guild int64
	}{{World, 1, 0}, {Service, 2, 0}, {Guild, 77, 0}, {Guild, 88, 77}} {
		if _, err := AuthorizeRoom(a, tc.role, tc.room, tc.guild); !errors.Is(err, ErrRoomNotAuthorized) {
			t.Fatalf("%+v err=%v", tc, err)
		}
	}
}

func TestTeamIsNotPhysicalRole(t *testing.T) {
	if PhysicalRole("TEAM").Valid() {
		t.Fatal("TEAM became a physical socket role")
	}
}
