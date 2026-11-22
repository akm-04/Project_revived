package topfloor

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
)

func TestStartFingerprintIsStageOnly(t *testing.T) {
	player := identity.PlayerID(7)
	base := StartCommand{Formation: []int64{11, 12}, PetID: 3, Enemy: 9}
	for name, mutate := range map[string]func(*StartCommand){
		"formation": func(c *StartCommand) { c.Formation = []int64{12, 11} },
		"pet":       func(c *StartCommand) { c.PetID = 4 },
	} {
		other := base
		mutate(&other)
		if fingerprint(player, base) != fingerprint(player, other) {
			t.Fatalf("a changed %s is the same stage: I8_PARENT_CONTRACT_V1 generation_supersede", name)
		}
	}
	for name, mutate := range map[string]func(*StartCommand){
		"enemy":  func(c *StartCommand) { c.Enemy = 10 },
		"avenge": func(c *StartCommand) { c.Avenge = true },
	} {
		other := base
		mutate(&other)
		if fingerprint(player, base) == fingerprint(player, other) {
			t.Fatalf("%s change must be a different stage", name)
		}
	}
}

func TestForfeited(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	player := d.Player{Fights: 7, Wins: 4, WinStreak: 3, StateVersion: 9, UpdatedAt: at.Add(-time.Hour)}
	next := forfeited(player, at)
	if next.Fights != 8 || next.Wins != 4 || next.WinStreak != 0 {
		t.Fatalf("fights=%d wins=%d streak=%d", next.Fights, next.Wins, next.WinStreak)
	}
	if next.StateVersion != 10 || !next.UpdatedAt.Equal(at) {
		t.Fatalf("version=%d updated=%v", next.StateVersion, next.UpdatedAt)
	}
	if player.Fights != 7 || player.WinStreak != 3 {
		t.Fatal("forfeited must not mutate its input")
	}
}
