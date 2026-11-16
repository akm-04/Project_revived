package arenastore

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func checkPayloadGolden[T any](t *testing.T, table, column string, decode func(raw []byte) T) {
	t.Helper()
	directory := filepath.Join("testdata", "payloads", table+"."+column)
	raw, err := os.ReadFile(filepath.Join(directory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	got, err := json.MarshalIndent(decode(raw), "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	got = append(got, '\n')
	want, err := os.ReadFile(filepath.Join(directory, "v0.expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(got, want) {
		t.Fatalf("%s.%s golden mismatch\n got: %s\nwant: %s", table, column, got, want)
	}
}

func decodeGolden[T any](t *testing.T, table string, raw []byte, value *T) {
	t.Helper()
	if err := payload.Decode(table, 0, raw, value); err != nil {
		t.Fatal(err)
	}
}

// recommendFormation mirrors the anonymous defense shape read by
// HeroRecommendSourceTx, the second decode site of arena_players.defense.
type recommendFormation struct {
	Heroes []int64 `json:"heroes"`
	Pet    int64   `json:"pet"`
}

func TestPayloadGoldenArenaPlayers(t *testing.T) {
	checkPayloadGolden(t, "arena_players", "defense", func(raw []byte) any {
		var value d.Lineup
		decodeGolden(t, "arena_players", raw, &value)
		return value
	})
	checkPayloadGolden(t, "arena_players", "defense", func(raw []byte) any {
		var value recommendFormation
		decodeGolden(t, "arena_players", raw, &value)
		return value
	})
	checkPayloadGolden(t, "arena_players", "missions", func(raw []byte) any {
		var value []d.MissionSlot
		decodeGolden(t, "arena_players", raw, &value)
		return value
	})
	checkPayloadGolden(t, "arena_players", "awards", func(raw []byte) any {
		var value []d.Award
		decodeGolden(t, "arena_players", raw, &value)
		return value
	})
	checkPayloadGolden(t, "arena_players", "recent_offers", func(raw []byte) any {
		var value []d.Offer
		decodeGolden(t, "arena_players", raw, &value)
		return value
	})
}

func TestPayloadGoldenArenaMatches(t *testing.T) {
	checkPayloadGolden(t, "arena_matches", "defense_heroes", func(raw []byte) any {
		var value []d.Fighter
		decodeGolden(t, "arena_matches", raw, &value)
		return value
	})
	checkPayloadGolden(t, "arena_matches", "formation", func(raw []byte) any {
		var value []d.Fighter
		decodeGolden(t, "arena_matches", raw, &value)
		return value
	})
	checkPayloadGolden(t, "arena_matches", "outcome", func(raw []byte) any {
		var value d.Outcome
		decodeGolden(t, "arena_matches", raw, &value)
		return value
	})
}

func TestPayloadGoldenArenaCasualEntries(t *testing.T) {
	checkPayloadGolden(t, "arena_casual_entries", "payload", func(raw []byte) any {
		var value d.CasualEntry
		decodeGolden(t, "arena_casual_entries", raw, &value)
		return value
	})
}

func TestPayloadGoldenArenaCasualSessions(t *testing.T) {
	checkPayloadGolden(t, "arena_casual_sessions", "payload", func(raw []byte) any {
		var value d.CasualSession
		decodeGolden(t, "arena_casual_sessions", raw, &value)
		return value
	})
}

func TestPayloadGoldenArenaFriendInvitations(t *testing.T) {
	checkPayloadGolden(t, "arena_friend_invitations", "payload", func(raw []byte) any {
		var value d.FriendInvitation
		decodeGolden(t, "arena_friend_invitations", raw, &value)
		return value
	})
}

func TestPayloadGoldenArenaTournamentPeriods(t *testing.T) {
	checkPayloadGolden(t, "arena_tournament_periods", "payload", func(raw []byte) any {
		var value d.TournamentPeriod
		decodeGolden(t, "arena_tournament_periods", raw, &value)
		return value
	})
}

func TestPayloadGoldenArenaTournamentRooms(t *testing.T) {
	checkPayloadGolden(t, "arena_tournament_rooms", "payload", func(raw []byte) any {
		var value d.TournamentRoom
		decodeGolden(t, "arena_tournament_rooms", raw, &value)
		return value
	})
}
