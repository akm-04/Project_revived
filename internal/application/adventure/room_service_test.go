package adventure

import (
	"context"
	"testing"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type memberDirectory map[int64]playerdirectory.Profile

func (d memberDirectory) ProfileTx(_ context.Context, _ tx.Queryer, playerID identity.PlayerID) (playerdirectory.Profile, bool, error) {
	profile, found := d[int64(playerID)]
	return profile, found, nil
}

type guildNameRead struct {
	server  identity.LogicalServerID
	players []identity.PlayerID
}

type memberGuilds struct {
	names map[int64]string
	reads []guildNameRead
}

func (g *memberGuilds) GuildNamesTx(_ context.Context, _ tx.Queryer, server identity.LogicalServerID, players []identity.PlayerID) (map[identity.PlayerID]string, error) {
	g.reads = append(g.reads, guildNameRead{server: server, players: append([]identity.PlayerID(nil), players...)})
	out := make(map[identity.PlayerID]string, len(players))
	for _, player := range players {
		if name, found := g.names[int64(player)]; found {
			out[player] = name
		}
	}
	return out, nil
}

// DL-ae2d4926, DL-8cea9147: a room member row carries the same directory
// projection the illusion and occult rooms send, plus the guild name.
func TestRoomMemberInfosCarryGuildAndConquer(t *testing.T) {
	room := sharedroom.Room{LogicalServerID: 5, Seats: []sharedroom.Seat{
		{Index: 0, Player: 11, Stage: sharedroom.SeatSeated},
		{Index: 1, Player: 22, Stage: sharedroom.SeatSeated},
	}}
	guilds := &memberGuilds{names: map[int64]string{11: "Guild"}}
	mode := Mode{
		Directory: memberDirectory{
			11: {PlayerID: 11, Name: "member", Level: 40, AvatarID: 110001001, ConquerLevel: 7, ConquerLoopID: 3},
			22: {PlayerID: 22, Name: "guildless", Level: 41, AvatarID: 110001001, ConquerLevel: 5, ConquerLoopID: 2},
		},
		Guilds: guilds,
	}
	_, infos, err := mode.roomMembers(context.Background(), nil, room, map[identity.PlayerID]int64{11: 500, 22: 600})
	if err != nil {
		t.Fatal(err)
	}
	if len(infos) != 2 {
		t.Fatalf("member infos %#v", infos)
	}
	member, _ := infos[0].(map[string]any)
	if member["guild_name"] != "Guild" || member["conquer_lev"] != int64(7) || member["conquer_loop_id"] != int64(3) {
		t.Fatalf("member row %#v want guild name, conquer 7/3", member)
	}
	if member["force"] != int64(500) || member["lev"] != int64(40) {
		t.Fatalf("member row lost its existing projection %#v", member)
	}
	guildless, _ := infos[1].(map[string]any)
	if got, present := guildless["guild_name"]; !present || got != "" {
		t.Fatalf("guildless row %#v want guild_name %q", guildless, "")
	}
	if guildless["conquer_lev"] != int64(5) || guildless["conquer_loop_id"] != int64(2) {
		t.Fatalf("guildless row conquer %#v", guildless)
	}
	if len(guilds.reads) != 1 || guilds.reads[0].server != 5 {
		t.Fatalf("guild reads %#v want one batch for the room server", guilds.reads)
	}
	if got := guilds.reads[0].players; len(got) != 2 || got[0] != 11 || got[1] != 22 {
		t.Fatalf("guild read players %#v want one batch of both members", got)
	}
}
