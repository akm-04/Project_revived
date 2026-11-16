package oneononestore

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/oneonone"
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

func TestPayloadGoldenOneOnOneStore(t *testing.T) {
	checkPayloadGolden(t, "one_on_one_players", "teams", func(raw []byte) any {
		var value []d.Team
		decodeGolden(t, "one_on_one_players", raw, &value)
		return value
	})
	checkPayloadGolden(t, "one_on_one_players", "offered", func(raw []byte) any {
		var value []identity.PlayerID
		decodeGolden(t, "one_on_one_players", raw, &value)
		return value
	})
	checkPayloadGolden(t, "one_on_one_players", "candidates", func(raw []byte) any {
		var value []identity.PlayerID
		decodeGolden(t, "one_on_one_players", raw, &value)
		return value
	})
	checkPayloadGolden(t, "one_on_one_players", "offer_snapshot", func(raw []byte) any {
		var value *d.OfferSnapshot
		decodeGolden(t, "one_on_one_players", raw, &value)
		return value
	})
	checkPayloadGolden(t, "one_on_one_matches", "attack_teams", func(raw []byte) any {
		var value []d.Team
		decodeGolden(t, "one_on_one_matches", raw, &value)
		return value
	})
	checkPayloadGolden(t, "one_on_one_matches", "defense_teams", func(raw []byte) any {
		var value []d.Team
		decodeGolden(t, "one_on_one_matches", raw, &value)
		return value
	})
	checkPayloadGolden(t, "one_on_one_matches", "outcome", func(raw []byte) any {
		var value *d.Outcome
		decodeGolden(t, "one_on_one_matches", raw, &value)
		return value
	})
}
