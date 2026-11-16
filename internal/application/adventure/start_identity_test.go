package adventure

import (
	"testing"
	"time"

	cb "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/adventure"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/sharedroom"
)

func TestPVPStartReplayIdentityHoldsOnlyTheStage(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	player := identity.ActorContext{PlayerID: 7, LogicalServerID: 3}
	occurrence := d.Occurrence{PlayerID: player.PlayerID, EventType: d.EventBattle, OccurredAt: at, SourceKey: "pvp-occurrence"}
	enemy := Opponent{PlayerID: 9}
	first := pvpStart(player, occurrence, FightRequest{Formation: []int64{11, 12}}, enemy, at)
	second := pvpStart(player, occurrence, FightRequest{Formation: []int64{12, 13}}, enemy, at)
	if first.StartFingerprint != second.StartFingerprint || first.Locator != second.Locator || first.GenerationRef != second.GenerationRef {
		t.Fatal("a formation change is the same stage: I8_PARENT_CONTRACT_V1 generation_supersede")
	}
	otherOccurrence := occurrence
	otherOccurrence.SourceKey = "next-occurrence"
	if pvpStart(player, otherOccurrence, FightRequest{Formation: []int64{11}}, enemy, at).GenerationRef == first.GenerationRef {
		t.Fatal("another occurrence is a different stage")
	}
	otherPlayer := player
	otherPlayer.PlayerID = 8
	if pvpStart(otherPlayer, occurrence, FightRequest{Formation: []int64{11}}, enemy, at).StartFingerprint == first.StartFingerprint {
		t.Fatal("another player is a different stage")
	}
}

func TestCoopStartReplayIdentityHoldsOnlyTheRoom(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	player := identity.ActorContext{PlayerID: 7, LogicalServerID: 3}
	room := sharedroom.Room{ID: 5, LogicalServerID: 3, Owner: player.PlayerID, Seats: []sharedroom.Seat{
		{Index: 0, Player: player.PlayerID, Stage: sharedroom.SeatSeated},
		{Index: 1, Player: 8, Stage: sharedroom.SeatSeated},
	}}
	first := coopStart(player, room, cb.BattleRequest{TeamA: []cb.Participant{{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: player.PlayerID, Identity: 11}}}, at)
	second := coopStart(player, room, cb.BattleRequest{TeamA: []cb.Participant{{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: player.PlayerID, Identity: 12}}}, at)
	if first.StartFingerprint != second.StartFingerprint {
		t.Fatal("a pick change is the same stage: I8_PARENT_CONTRACT_V1 generation_supersede")
	}
	otherRoom := room
	otherRoom.ID = 6
	if coopStart(player, otherRoom, cb.BattleRequest{}, at).Locator == first.Locator {
		t.Fatal("another room is a different stage")
	}
}
