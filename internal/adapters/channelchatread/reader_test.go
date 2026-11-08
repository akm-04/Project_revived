package channelchatread

import (
	ar "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"testing"
	"time"
)

func TestShareableRoomRequiresOpenFreeSeatAndSeatedSender(t *testing.T) {
	at := time.Unix(1000, 0)
	owner := identity.PlayerID(100001)
	room, e := sharedroom.NewRoom(identity.LogicalServerID(1), "illusion", 1, 3, owner, at.Add(time.Hour), []byte(`{}`), at)
	if e != nil {
		t.Fatal(e)
	}
	admission := func(player identity.PlayerID, server identity.LogicalServerID) ar.Admission {
		return ar.Admission{Domain: domainrt.Admission{Actor: identity.ActorContext{PlayerID: player, LogicalServerID: server}}}
	}
	if !shareableRoom(room, admission(owner, 1)) {
		t.Fatal("owner in open room must be shareable")
	}
	closed := room
	closed.Status = sharedroom.StatusClosed
	closed.ClosedAt = &at
	if shareableRoom(closed, admission(owner, 1)) {
		t.Fatal("closed room shared")
	}
	full := room
	full.Capacity = 1
	if shareableRoom(full, admission(owner, 1)) {
		t.Fatal("full room shared")
	}
	if shareableRoom(room, admission(identity.PlayerID(100002), 1)) {
		t.Fatal("non-member shared")
	}
	if shareableRoom(room, admission(owner, 2)) {
		t.Fatal("foreign server room shared")
	}
}
