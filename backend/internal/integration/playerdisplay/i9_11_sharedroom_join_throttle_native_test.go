//go:build postgres

package playerdisplay_test

import (
	"errors"
	"testing"

	sharedroom "gxb.local/backend/v2/internal/domain/sharedroom"
)

// TestI9_11SharedRoomJoinThrottleNative proves the 30 s same-room rejoin
// throttle survives the real stores: the seat's joined_at is written by the
// first join, reloaded after the leave, and refused until the throttle expires.
func TestI9_11SharedRoomJoinThrottleNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	clock := illusionTime(t)
	mode := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	owner, _ := illusionTeamOwner(t, p, server, 10001002)
	mate, _ := illusionTeamOwner(t, p, server, 10001003)
	created, err := mode.CreateRoom(ctx, owner, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := illusionRoomID(t, created)
	if _, err = mode.EnterRoom(ctx, mate, roomID, op()); err != nil {
		t.Fatal("first join", err)
	}
	if _, err = mode.ExitRoom(ctx, mate, op()); err != nil {
		t.Fatal("leave", err)
	}
	if _, err = mode.EnterRoom(ctx, mate, roomID, op()); !errors.Is(err, sharedroom.ErrJoinThrottled) {
		t.Fatalf("rejoin inside the throttle: %v", err)
	}
	clock.Set(clock.at.Add(sharedroom.JoinThrottle))
	if _, err = mode.EnterRoom(ctx, mate, roomID, op()); err != nil {
		t.Fatalf("rejoin after the throttle: %v", err)
	}
}
