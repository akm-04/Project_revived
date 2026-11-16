package leaguestore

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	app "gxb.local/backend/v2/internal/application/championsleague"
	d "gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func checkPayloadGolden(t *testing.T, table, column string, decode func(raw []byte) any) {
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

func TestPayloadGoldenLeagueStore(t *testing.T) {
	checkPayloadGolden(t, "league_competitions", "payload", func(raw []byte) any {
		var value d.Root
		decodeGolden(t, "league_competitions", raw, &value)
		return value
	})
	checkPayloadGolden(t, "league_players", "payload", func(raw []byte) any {
		var value d.Player
		decodeGolden(t, "league_players", raw, &value)
		return value
	})
	checkPayloadGolden(t, "league_matches", "payload", func(raw []byte) any {
		var value d.Match
		decodeGolden(t, "league_matches", raw, &value)
		return value
	})
	checkPayloadGolden(t, "league_settlements", "payload", func(raw []byte) any {
		var value d.Settlement
		decodeGolden(t, "league_settlements", raw, &value)
		return value
	})
	checkPayloadGolden(t, "league_cosmetic_origins", "payload", func(raw []byte) any {
		var value app.OriginAward
		decodeGolden(t, "league_cosmetic_origins", raw, &value)
		return value
	})
}
