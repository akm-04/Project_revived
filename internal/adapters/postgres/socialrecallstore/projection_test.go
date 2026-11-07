package socialrecallstore_test

import (
	"context"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/socialrecallstore"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type recallDirectory struct {
	playerdirectory.TxDiscoveryReader
	query   tx.Tx
	players []identity.PlayerID
	missing bool
	foreign bool
}

func (directory *recallDirectory) ProfileTx(_ context.Context, query tx.Tx, player identity.PlayerID) (playerdirectory.Profile, bool, error) {
	directory.query = query
	directory.players = append(directory.players, player)
	if directory.foreign {
		player++
	}
	return playerdirectory.Profile{PlayerID: player, Name: "Recall target", Level: 51}, !directory.missing, nil
}

func TestDoingProjectionUsesBoundedOwnerRowsAndTypedDirectory(t *testing.T) {
	query := &snapshotQueryer{presenceCells: `[{"target_player_id":125002,"started_at":"2026-11-05T11:00:00Z"},{"target_player_id":125003,"started_at":"2026-11-05T10:00:00Z"}]`}
	directory := &recallDirectory{}
	rows, err := (socialrecallstore.DoingProjection{Directory: directory}).DoingRecallTx(context.Background(), query, 125001, strings.Repeat("a", 64), targetAt, 3)
	if err != nil || len(rows) != 2 {
		t.Fatal(rows, err)
	}
	if directory.query != query || len(directory.players) != 2 || directory.players[0] != 125002 || rows[0].PlayerID != 125002 || rows[0].PlayerName != "Recall target" || rows[0].RecallingTime != targetAt.Add(-time.Hour).Unix() {
		t.Fatal(rows, directory)
	}
}
func TestDoingProjectionRefusesCorruptOrUnavailableFacts(t *testing.T) {
	for _, name := range []string{"too-many", "duplicate", "foreign-server", "self", "future", "missing-profile", "foreign-profile", "invalid-revision", "bad-limit"} {
		t.Run(name, func(t *testing.T) {
			query := &snapshotQueryer{presenceCells: `[{"target_player_id":125002,"started_at":"2026-11-05T11:00:00Z"}]`}
			directory := &recallDirectory{}
			limit := 3
			revision := strings.Repeat("a", 64)
			switch name {
			case "too-many":
				limit = 1
				query.presenceCells = `[{"target_player_id":125002,"started_at":"2026-11-05T11:00:00Z"},{"target_player_id":125003,"started_at":"2026-11-05T10:00:00Z"}]`
			case "duplicate":
				query.presenceCells = `[{"target_player_id":125002,"started_at":"2026-11-05T11:00:00Z"},{"target_player_id":125002,"started_at":"2026-11-05T11:00:00Z"}]`
			case "foreign-server":
				query.presenceCells = `[{"target_player_id":225002,"started_at":"2026-11-05T11:00:00Z"}]`
			case "self":
				query.presenceCells = `[{"target_player_id":125001,"started_at":"2026-11-05T11:00:00Z"}]`
			case "future":
				query.presenceCells = `[{"target_player_id":125002,"started_at":"2026-11-05T12:01:00Z"}]`
			case "missing-profile":
				directory.missing = true
			case "foreign-profile":
				directory.foreign = true
			case "invalid-revision":
				revision = "bad"
			case "bad-limit":
				limit = -1
			}
			if _, err := (socialrecallstore.DoingProjection{Directory: directory}).DoingRecallTx(context.Background(), query, 125001, revision, targetAt, limit); err == nil {
				t.Fatal("invalid projection accepted")
			}
		})
	}
	query := &snapshotQueryer{presenceCells: "[]"}
	rows, err := (socialrecallstore.DoingProjection{Directory: &recallDirectory{}}).DoingRecallTx(context.Background(), query, 125001, strings.Repeat("a", 64), targetAt, 3)
	if err != nil || rows == nil || len(rows) != 0 {
		t.Fatal("empty list not preserved", rows, err)
	}
}
