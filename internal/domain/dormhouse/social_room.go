package dormhouse

import "time"

type SocialRoomState struct {
	Target       RoomTarget
	Name         string
	Hidden       bool
	StateVersion int64
	UpdatedAt    time.Time
}

func (state SocialRoomState) Validate() error {
	if err := state.Target.Validate(); err != nil {
		return err
	}
	if _, err := NormalizeRoomName(state.Name); err != nil {
		return err
	}
	if state.StateVersion < 1 || state.UpdatedAt.IsZero() {
		return ErrInvalidFacts
	}
	return nil
}
