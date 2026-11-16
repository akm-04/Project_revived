package topfloorstore

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	d "gxb.local/backend/v2/internal/domain/topfloor"
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

func TestPayloadGoldenTopFloorStore(t *testing.T) {
	checkPayloadGolden(t, "top_floor_fights", "formation", func(raw []byte) any {
		var value []int64
		decodeGolden(t, "top_floor_fights", raw, &value)
		return value
	})
	checkPayloadGolden(t, "top_floor_fights", "outcome", func(raw []byte) any {
		var value *d.Outcome
		decodeGolden(t, "top_floor_fights", raw, &value)
		return value
	})
	checkPayloadGolden(t, "top_floor_offer_snapshots", "offers", func(raw []byte) any {
		var value []d.Ranked
		decodeGolden(t, "top_floor_offer_snapshots", raw, &value)
		return value
	})
	checkPayloadGolden(t, "top_floor_players", "defense", func(raw []byte) any {
		var value []int64
		decodeGolden(t, "top_floor_players", raw, &value)
		return value
	})
	checkPayloadGolden(t, "top_floor_players", "offered", func(raw []byte) any {
		var value []d.Occupant
		decodeGolden(t, "top_floor_players", raw, &value)
		return value
	})
	checkPayloadGolden(t, "top_floor_task_fights", "payload", func(raw []byte) any {
		var value d.TaskModeFight
		decodeGolden(t, "top_floor_task_fights", raw, &value)
		return value
	})
	checkPayloadGolden(t, "top_floor_task_players", "payload", func(raw []byte) any {
		var value d.TaskModePlayer
		decodeGolden(t, "top_floor_task_players", raw, &value)
		return value
	})
	checkPayloadGolden(t, "top_floor_task_preferences", "payload", func(raw []byte) any {
		var value d.TaskModeDefense
		decodeGolden(t, "top_floor_task_preferences", raw, &value)
		return value
	})
	checkPayloadGolden(t, "top_floor_task_records", "payload", func(raw []byte) any {
		var value d.TaskModeRecord
		decodeGolden(t, "top_floor_task_records", raw, &value)
		return value
	})
}
