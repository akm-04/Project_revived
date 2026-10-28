package dodgeball

import (
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/modes"
	"time"
)

const MaximumSequence int64 = 9007199254740991

type Occurrence struct {
	Identity string              `json:"identity"`
	Revision string              `json:"revision"`
	Friend   int64               `json:"friend"`
	Deadline int64               `json:"deadline"`
	Board    Board               `json:"board"`
	Marked   int64               `json:"marked"`
	Draws    *combat.DrawPackage `json:"draws,omitempty"`
}

type State struct {
	Day             int64          `json:"day"`
	Incoming        int64          `json:"incoming"`
	Played          int64          `json:"played"`
	Invited         map[int64]bool `json:"invited"`
	Sequence        int64          `json:"sequence"`
	Pending         *Occurrence    `json:"pending,omitempty"`
	LastFingerprint string         `json:"last_fingerprint,omitempty"`
	LastResult      map[string]any `json:"last_result,omitempty"`
}

func (state *State) Normalize(at time.Time) error {
	if state.Incoming < 0 || state.Incoming > 3 || state.Played < 0 || state.Sequence < 0 || state.Sequence > MaximumSequence {
		return ErrUnavailable
	}
	day := modes.Day(at)
	if state.Day > day {
		return ErrRefused
	}
	if state.Day != day {
		state.Day, state.Incoming, state.Played = day, 0, 0
		state.Invited = nil
	}
	if state.Invited == nil {
		state.Invited = map[int64]bool{}
	}
	return nil
}
