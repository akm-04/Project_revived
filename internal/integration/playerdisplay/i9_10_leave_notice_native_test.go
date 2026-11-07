//go:build postgres

package playerdisplay_test

import (
	"fmt"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	il "gxb.local/backend/v2/internal/application/illusion"
	da "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

// TestI9_10LeaveDoesNotLookLikeAKick checks the removal frame provenance in both
// Adventure families: only kicked players and players the room closed on get it.
func TestI9_10LeaveDoesNotLookLikeAKick(t *testing.T) {
	t.Run("illusion", func(t *testing.T) {
		p := pool(t)
		server := rankingServer(t, p)
		clock := illusionTime(t)
		mode := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
		a, _ := illusionTeamOwner(t, p, server, 10001002)
		b, _ := illusionTeamOwner(t, p, server, 10001003)
		c, _ := illusionTeamOwner(t, p, server, 10001004)
		roomID := illusionTeamRoom(t, mode, a, b, c)
		if _, err := mode.ExitRoom(ctx, b, op()); err != nil {
			t.Fatal("mate exit", err)
		}
		if removed := illusionRemoved(t, p, roomID); len(removed) != 0 {
			t.Fatalf("a voluntary member leave sent %v", removed)
		}
		if _, err := mode.ExitRoom(ctx, a, op()); err != nil {
			t.Fatal("owner exit", err)
		}
		removed := illusionRemoved(t, p, roomID)
		if containsPlayer(removed, a.PlayerID) || containsPlayer(removed, b.PlayerID) {
			t.Fatalf("the room sent a removal frame to a player who left: %v", removed)
		}
		if !containsPlayer(removed, c.PlayerID) {
			t.Fatalf("a member of the closed room got no removal frame: %v", removed)
		}

		// A kick does send the frame.
		roomID = illusionTeamRoom(t, mode, a, b, c)
		if _, err := mode.RemovePlayer(ctx, a, b.PlayerID, op()); err != nil {
			t.Fatal("kick", err)
		}
		if removed = illusionRemoved(t, p, roomID); !containsPlayer(removed, b.PlayerID) {
			t.Fatalf("a kicked member got no removal frame: %v", removed)
		}
	})

	t.Run("adventure", func(t *testing.T) {
		p := pool(t)
		server := rankingServer(t, p)
		a, _ := adventureOwner(t, p, server, 100, 10001001)
		b, _ := adventureOwner(t, p, server, 100, 10001002)
		c, _ := adventureOwner(t, p, server, 100, 10001003)
		clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
		mode := adventureTestMode(t, p, clock, adventureOpponents{})
		opContext := opPinned(installed(t, p))
		opContext.StartedAt = clock.at
		for index, member := range []identity.ActorContext{a, b, c} {
			putAdventureOccurrence(t, p, member.PlayerID, da.EventIllusion, da.IllusionHiddenBoss, clock.at, clock.at.Add(2*time.Hour), fmt.Sprintf("leave-%d", index))
		}
		roomID := adventureCoopRoom(t, mode, opContext, a, b, c)
		if _, err := mode.ExitCoop(ctx, b, opContext); err != nil {
			t.Fatal("member exit", err)
		}
		if removed := adventureRemoved(t, mode, roomID); len(removed) != 0 {
			t.Fatalf("a voluntary member leave sent %v", removed)
		}
		if _, err := mode.ExitCoop(ctx, a, opContext); err != nil {
			t.Fatal("owner exit", err)
		}
		removed := adventureRemoved(t, mode, roomID)
		if containsPlayer(removed, a.PlayerID) || containsPlayer(removed, b.PlayerID) {
			t.Fatalf("the room sent a removal frame to a player who left: %v", removed)
		}
		if !containsPlayer(removed, c.PlayerID) {
			t.Fatalf("a member of the closed room got no removal frame: %v", removed)
		}

		roomID = adventureCoopRoom(t, mode, opContext, a, b, c)
		if _, err := mode.RemoveCoop(ctx, a, b.PlayerID, opContext); err != nil {
			t.Fatal("kick", err)
		}
		if removed = adventureRemoved(t, mode, roomID); !containsPlayer(removed, b.PlayerID) {
			t.Fatalf("a kicked member got no removal frame: %v", removed)
		}
	})
}

func illusionTeamRoom(t *testing.T, mode il.Mode, members ...identity.ActorContext) int64 {
	t.Helper()
	created, err := mode.CreateRoom(ctx, members[0], op())
	if err != nil {
		t.Fatal("create room", err)
	}
	roomID := illusionRoomID(t, created)
	for _, member := range members[1:] {
		if _, err = mode.EnterRoom(ctx, member, roomID, op()); err != nil {
			t.Fatal("join", err)
		}
	}
	return roomID
}

func adventureCoopRoom(t *testing.T, mode appadventure.Mode, opContext operation.Context, members ...identity.ActorContext) int64 {
	t.Helper()
	created, err := mode.CreateCoop(ctx, members[0], opContext)
	if err != nil {
		t.Fatal("create coop", err)
	}
	roomID := adventureRoomIDFrom(created)
	for _, member := range members[1:] {
		if _, err = mode.EnterCoop(ctx, member, roomID, opContext); err != nil {
			t.Fatal("join", err)
		}
	}
	return roomID
}

func containsPlayer(players []identity.PlayerID, player identity.PlayerID) bool {
	for _, candidate := range players {
		if candidate == player {
			return true
		}
	}
	return false
}

func illusionRemoved(t *testing.T, p *pg.Pool, roomID int64) []identity.PlayerID {
	t.Helper()
	reader := stockruntime.IllusionRoomNoticeReader{Store: sharedroomstore.Store{}, Directory: i4store.PlayerDirectoryReader{}, Queryer: p}
	notice, found, err := reader.ReadRoomNotice(ctx, fmt.Sprint(roomID))
	if err != nil || !found {
		t.Fatalf("518 read %v %v", found, err)
	}
	return notice.Removed
}

func adventureRemoved(t *testing.T, mode appadventure.Mode, roomID int64) []identity.PlayerID {
	t.Helper()
	notice, found, err := mode.ReadRoomNotice(ctx, fmt.Sprint(roomID))
	if err != nil || !found {
		t.Fatalf("room notice read %v %v", found, err)
	}
	removed := make([]identity.PlayerID, 0, len(notice.Removed))
	for _, body := range notice.Removed {
		removed = append(removed, body.Player)
	}
	return removed
}
