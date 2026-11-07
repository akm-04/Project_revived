//go:build postgres

package playerdisplay_test

import (
	"math"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/publicstats"
	da "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TestI9_10TeamWindowsShowBest15Force checks the prepare windows' AP field:
// Fantasy's master_id_info.force and Sophia's member_infos[].force are the
// player's best-15 hero force, not the picked-hero sum or zero.
func TestI9_10TeamWindowsShowBest15Force(t *testing.T) {
	t.Run("illusion", func(t *testing.T) {
		p := pool(t)
		server := rankingServer(t, p)
		clock := illusionTime(t)
		mode := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
		a, _ := illusionTeamOwner(t, p, server, 10001002, 10001003)
		b, _ := illusionTeamOwner(t, p, server, 10001004)
		created, err := mode.CreateRoom(ctx, a, op())
		if err != nil {
			t.Fatal("create", err)
		}
		master, _ := created["master_id_info"].(map[string]any)
		if master["force"] != int64(3000) {
			t.Fatalf("the creation window master force is %v, want the three-hero best-15 3000", master["force"])
		}
		entered, err := mode.EnterRoom(ctx, b, illusionRoomID(t, created), op())
		if err != nil {
			t.Fatal("enter", err)
		}
		mate, _ := entered["mate_1_info"].(map[string]any)
		if mate["force"] != int64(2000) {
			t.Fatalf("the entering mate force is %v, want the two-hero best-15 2000", mate["force"])
		}
	})

	t.Run("adventure", func(t *testing.T) {
		p := pool(t)
		server := rankingServer(t, p)
		a, _ := adventureOwner(t, p, server, 100, 10001001, 10001002)
		b, _ := adventureOwner(t, p, server, 100, 10001003, 10001004)
		clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
		mode := adventureTestMode(t, p, clock, adventureOpponents{})
		opContext := opPinned(installed(t, p))
		opContext.StartedAt = clock.at
		for index, member := range []identity.ActorContext{a, b} {
			putAdventureOccurrence(t, p, member.PlayerID, da.EventIllusion, da.IllusionHiddenBoss, clock.at, clock.at.Add(2*time.Hour), "force-"+string(rune('a'+index)))
		}
		created, err := mode.CreateCoop(ctx, a, opContext)
		if err != nil {
			t.Fatal("create coop", err)
		}
		roomID := adventureRoomIDFrom(created)
		master := roomMemberInfo(t, created, a.PlayerID)
		if want := bestHeroForce(t, p, mode, a.PlayerID, clock.at); master["force"] != want {
			t.Fatalf("the creation window master force is %v, want %d", master["force"], want)
		}
		entered, err := mode.EnterCoop(ctx, b, roomID, opContext)
		if err != nil {
			t.Fatal("enter coop", err)
		}
		mate := roomMemberInfo(t, entered, b.PlayerID)
		if want := bestHeroForce(t, p, mode, b.PlayerID, clock.at); mate["force"] != want {
			t.Fatalf("the entering mate force is %v, want %d", mate["force"], want)
		}
	})
}

func roomMemberInfo(t *testing.T, body map[string]any, player identity.PlayerID) map[string]any {
	t.Helper()
	info, ok := body["room_info"].(map[string]any)
	if !ok {
		t.Fatalf("room_info %#v", body)
	}
	rows, ok := info["member_infos"].([]any)
	if !ok {
		t.Fatalf("member_infos %#v", info)
	}
	for _, raw := range rows {
		row, ok := raw.(map[string]any)
		if ok && row["player_id"] == int64(player) {
			return row
		}
	}
	t.Fatalf("member %d missing from %#v", player, rows)
	return nil
}

// bestHeroForce recomputes the same public force independently of the mode
// projection, so the assertion is a value, not a non-zero existence check.
func bestHeroForce(t *testing.T, p *pg.Pool, mode appadventure.Mode, player identity.PlayerID, at time.Time) int64 {
	t.Helper()
	revision := installed(t, p)
	opContext := opPinned(revision)
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: tr, Operation: opContext, Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead}}, revision, at)
	if err != nil {
		t.Fatal(err)
	}
	detail := map[string]any{}
	if err = mode.Heroes.OverlayMID1(ctx, tr, identity.ActorContext{PlayerID: player}, false, at, detail); err != nil {
		t.Fatal(err)
	}
	body, _ := detail["49"].(map[string]any)
	rows, _ := body["heros"].(map[string]any)
	total := int64(0)
	for key := range rows {
		partnerID, err := strconv.ParseInt(key, 10, 64)
		if err != nil {
			t.Fatal(err)
		}
		result, err := mode.Stats.HeroTx(ctx, scope, character.HeroRef{PlayerID: player, PartnerID: partnerID}, publicstats.View{Kind: publicstats.Self, Viewer: player})
		if err != nil {
			t.Fatal(err)
		}
		total += int64(math.Round(result.Stats.Force))
	}
	return total
}
