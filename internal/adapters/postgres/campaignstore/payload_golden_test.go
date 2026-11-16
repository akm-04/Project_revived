package campaignstore

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/modes"
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

func TestPayloadGoldenCampaignStore(t *testing.T) {
	checkPayloadGolden(t, "campaign_players", "pending_items", func(raw []byte) any {
		var items []d.Item
		decodeGolden(t, "campaign_players", raw, &items)
		return items
	})
	checkPayloadGolden(t, "campaign_players", "chapter_claims", func(raw []byte) any {
		var claims map[int64]int64
		decodeGolden(t, "campaign_players", raw, &claims)
		return claims
	})
	checkPayloadGolden(t, "campaign_players", "story_claims", func(raw []byte) any {
		var claims map[int64]json.RawMessage
		decodeGolden(t, "campaign_players", raw, &claims)
		return claims
	})
	checkPayloadGolden(t, "campaign_players", "trial_wins", func(raw []byte) any {
		var wins map[int64]modes.Counter
		decodeGolden(t, "campaign_players", raw, &wins)
		return wins
	})
}
