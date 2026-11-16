package topfloor

import (
	"testing"
	"time"

	d "gxb.local/backend/v2/internal/domain/topfloor"
)

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
