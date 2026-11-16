//go:build postgres

package playerdisplay_test

import (
	"fmt"
	"testing"
	"time"

	d "gxb.local/backend/v2/internal/domain/adventure"
)

func memberInfoRow(t *testing.T, roomInfo map[string]any, playerID int64) map[string]any {
	t.Helper()
	infos, ok := roomInfo["member_infos"].([]any)
	if !ok {
		t.Fatalf("member_infos %#v", roomInfo["member_infos"])
	}
	for _, raw := range infos {
		row, ok := raw.(map[string]any)
		if ok && row["player_id"] == playerID {
			return row
		}
	}
	t.Fatalf("member_infos lacks player %d: %#v", playerID, infos)
	return nil
}

func assertAdventureMemberRow(t *testing.T, row map[string]any, guildName string, conquerLevel, conquerLoop int64) {
	t.Helper()
	if got, present := row["guild_name"]; !present || got != guildName {
		t.Fatalf("guild_name %#v present=%v want %q", got, present, guildName)
	}
	if row["conquer_lev"] != conquerLevel || row["conquer_loop_id"] != conquerLoop {
		t.Fatalf("conquer %#v/%#v want %d/%d", row["conquer_lev"], row["conquer_loop_id"], conquerLevel, conquerLoop)
	}
}

// DL-8cea9147, DL-ae2d4926: the stock AdventureDefensePlayerInfoWindow reads
// guild_name, conquer_lev and conquer_loop_id from a room member_infos row.
func TestClosureB3AdventureRoomMemberInfoNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	owner, _ := adventureOwner(t, p, server, 11, 10001001)
	member, _ := adventureOwner(t, p, server, 11, 10001002)
	guildID := guildFixture(t, p, owner)
	var guildName string
	if err := p.QueryRow(ctx, `SELECT name FROM guilds WHERE guild_id=$1`, int64(guildID)).Scan(&guildName); err != nil {
		t.Fatal(err)
	}
	exec(t, p, `UPDATE player_directory_profiles SET conquer_lev=7,conquer_loop_id=3 WHERE player_id=$1`, int64(owner.PlayerID))
	exec(t, p, `UPDATE player_directory_profiles SET conquer_lev=5,conquer_loop_id=2 WHERE player_id=$1`, int64(member.PlayerID))

	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	opContext := opPinned(installed(t, p))
	opContext.StartedAt = clock.at
	now := clock.at
	putAdventureOccurrence(t, p, owner.PlayerID, d.EventDefense, 0, now, now.Add(time.Hour), "closure-b3-defense")
	info, err := mode.Info(ctx, owner, d.EventDefense, opContext)
	if err != nil {
		t.Fatal(err)
	}
	roomID := adventureRoomID(t, info)
	putAdventureOccurrence(t, p, member.PlayerID, d.EventDefense, 0, now, now.Add(time.Hour), "closure-b3-defense-member")
	joined, err := mode.EnterDefense(ctx, member, roomID, opContext)
	if err != nil {
		t.Fatal(err)
	}
	roomInfo, _ := joined["room_info"].(map[string]any)
	assertAdventureMemberRow(t, memberInfoRow(t, roomInfo, int64(owner.PlayerID)), guildName, 7, 3)
	assertAdventureMemberRow(t, memberInfoRow(t, roomInfo, int64(member.PlayerID)), "", 5, 2)

	notice, found, err := mode.ReadRoomNotice(ctx, fmt.Sprint(roomID))
	if err != nil || !found {
		t.Fatal("room notice", found, err)
	}
	for _, body := range notice.Seated {
		if body.Player != owner.PlayerID {
			continue
		}
		noticeRoom, ok := body.Body["room_info"].(map[string]any)
		if !ok {
			t.Fatalf("notice room_info %#v", body.Body)
		}
		assertAdventureMemberRow(t, memberInfoRow(t, noticeRoom, int64(owner.PlayerID)), guildName, 7, 3)
		return
	}
	t.Fatal("room notice lacks the owner's seated body")
}
