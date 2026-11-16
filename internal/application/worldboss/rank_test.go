package worldboss

import (
	"context"
	"testing"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type profileDirectory map[int64]playerdirectory.Profile

func (d profileDirectory) ProfileTx(_ context.Context, _ tx.Queryer, playerID identity.PlayerID) (playerdirectory.Profile, bool, error) {
	profile, found := d[int64(playerID)]
	return profile, found, nil
}

type recordingGuilds struct {
	names map[int64]string
	calls [][]identity.PlayerID
}

func (g *recordingGuilds) GuildNamesTx(_ context.Context, _ tx.Queryer, _ identity.LogicalServerID, players []identity.PlayerID) (map[identity.PlayerID]string, error) {
	g.calls = append(g.calls, append([]identity.PlayerID(nil), players...))
	out := make(map[identity.PlayerID]string, len(players))
	for _, playerID := range players {
		if name, found := g.names[int64(playerID)]; found {
			out[playerID] = name
		}
	}
	return out, nil
}

func TestBossRankRowsCarryGuildName(t *testing.T) {
	ranks := []d.RankEntry{{PlayerID: 11, TotalHurt: 500}, {PlayerID: 22, TotalHurt: 100}}
	guilds := &recordingGuilds{names: map[int64]string{11: "Guild"}}
	mode := Mode{
		Store:     rankStore{ranks: ranks},
		Directory: profileDirectory{11: {PlayerID: 11, Name: "member", Level: 90}, 22: {PlayerID: 22, Name: "guildless", Level: 90}},
		Guilds:    guilds,
	}
	body, err := mode.projectBoard(context.Background(), identity.ActorContext{PlayerID: 11, LogicalServerID: 1}, d.Board{LogicalServerID: 1, Generation: 1, BossID: d.FirstBossID}, map[int64]playerdirectory.Profile{})
	if err != nil {
		t.Fatal(err)
	}
	infos, ok := body["infos"].([]map[string]any)
	if !ok || len(infos) != 2 {
		t.Fatalf("infos %#v", body["infos"])
	}
	rows := map[int64]map[string]any{}
	for _, row := range infos {
		rows[row["player_id"].(int64)] = row
	}
	if got, present := rows[11]["guild_name"]; !present || got != "Guild" {
		t.Fatalf("member guild_name %#v present=%v want %q", got, present, "Guild")
	}
	if got, present := rows[22]["guild_name"]; !present || got != "" {
		t.Fatalf("guildless guild_name %#v present=%v want \"\"", got, present)
	}
	if len(guilds.calls) != 1 || len(guilds.calls[0]) != 2 || guilds.calls[0][0] != 11 || guilds.calls[0][1] != 22 {
		t.Fatalf("guild reads %#v want one batch of the shown players", guilds.calls)
	}
}
