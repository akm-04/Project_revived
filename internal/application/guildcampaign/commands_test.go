package guildcampaign

import (
	"testing"

	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
)

func TestIsRetryReplaysWhileAnotherMemberHoldsTheCopy(t *testing.T) {
	copy := d.Copy{HolderID: 2, HolderStage: d.StageFight, SettledBy: 1, SettledIndex: 2}
	if !isRetry(copy, identity.PlayerID(1), 2) {
		t.Fatal("retry of the member's last settled wave stopped while another member holds the copy")
	}
	if isRetry(copy, identity.PlayerID(2), 2) {
		t.Fatal("another member's result replayed as the holder's")
	}
	if isRetry(copy, identity.PlayerID(1), 1) {
		t.Fatal("a different wave replayed")
	}
	copy.HolderID = 1
	if isRetry(copy, identity.PlayerID(1), 2) {
		t.Fatal("a new fight by the same member replayed the last result")
	}
	copy.HolderID = 0
	if !isRetry(copy, identity.PlayerID(1), 2) {
		t.Fatal("retry of the member's last settled wave stopped on a free copy")
	}
}

func TestClampWavesMarksRecordedRowsAndKeepsDead(t *testing.T) {
	waves := map[int64][]EnemyRow{1: {
		{TableID: 1},
		{TableID: 2},
		{TableID: 3},
	}}
	waves = clampWaves(waves, 1, []ResultEnemy{
		{HeroID: 1, HP: 700, Index: 1},
		{HeroID: 2, HP: 500, Index: 1},
		{HeroID: 99, HP: 100, Index: 1},
	}, false)
	if rows := waves[1]; rows[0].Health != 1 || rows[0].HP != 700 {
		t.Fatalf("damaged row health=%d hp=%d, want health=1 hp=700", rows[0].Health, rows[0].HP)
	}
	if rows := waves[1]; rows[1].Health != 1 || rows[1].HP != 500 {
		t.Fatalf("damaged row health=%d hp=%d, want health=1 hp=500", rows[1].Health, rows[1].HP)
	}
	if rows := waves[1]; rows[2].Health != 0 || rows[2].HP != 0 {
		t.Fatalf("untouched row health=%d hp=%d, want health=0 hp=0", rows[2].Health, rows[2].HP)
	}

	waves = clampWaves(waves, 1, []ResultEnemy{
		{HeroID: 1, HP: 300, Index: 1},
		{HeroID: 2, HP: 0, Index: 1},
	}, false)
	if rows := waves[1]; rows[0].Health != 1 || rows[0].HP != 300 {
		t.Fatalf("known HP did not fall: health=%d hp=%d", rows[0].Health, rows[0].HP)
	}
	if rows := waves[1]; rows[1].Health != 1 || rows[1].HP != 0 {
		t.Fatalf("dead row health=%d hp=%d, want health=1 hp=0", rows[1].Health, rows[1].HP)
	}

	waves = clampWaves(waves, 1, []ResultEnemy{{HeroID: 2, HP: 900, Index: 1}}, false)
	if rows := waves[1]; rows[1].Health != 1 || rows[1].HP != 0 {
		t.Fatalf("dead row revived: health=%d hp=%d", rows[1].Health, rows[1].HP)
	}
}
