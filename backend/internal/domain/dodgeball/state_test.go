package dodgeball

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/domain/modes"
	"testing"
	"time"
)

func TestResetPreservesPaidOccurrenceAndSequence(t *testing.T) {
	at := time.Date(2026, 10, 28, 21, 1, 0, 0, time.UTC)
	pending := &Occurrence{Identity: "125001:9", Deadline: at.Add(time.Hour).Unix(), Revision: "frozen"}
	state := State{Day: modes.Day(at) - 1, Incoming: 3, Played: 4, Sequence: 9, Pending: pending, Invited: map[int64]bool{125002: true}}
	if err := state.Normalize(at); err != nil || state.Incoming != 0 || state.Played != 0 || state.Sequence != 9 || state.Pending != pending || len(state.Invited) != 0 {
		t.Fatal(state, err)
	}
	state.LastResult = map[string]any{"error_code": int64(0)}
	encoded, err := json.Marshal(state)
	if err != nil {
		t.Fatal(err)
	}
	var restored State
	if err = json.Unmarshal(encoded, &restored); err != nil || restored.LastResult == nil {
		t.Fatal("empty terminal result lost", restored, err)
	}
	if err = state.Normalize(at.Add(-24 * time.Hour)); err != ErrRefused {
		t.Fatal("backwards day", err)
	}
}
