package character

import (
	"errors"
	"strings"
	"time"
	"unicode/utf8"

	"gxb.local/backend/v2/internal/domain/identity"
)

const SavedPresetSchemaVersion = 1

// SavedPresetRoot is the durable owner root for one player's ordered saved-team
// presets. Child lanes/refs are one aggregate under this single revision.
type SavedPresetRoot struct {
	PlayerID     identity.PlayerID
	StateVersion int64
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

func (r SavedPresetRoot) Validate() error {
	if !r.PlayerID.Valid() || r.StateVersion <= 0 || r.CreatedAt.IsZero() || r.UpdatedAt.IsZero() {
		return errors.New("character saved preset: invalid root")
	}
	return nil
}

type SavedPresetLane struct {
	Name   string
	Heroes []HeroRef
	Pet    *PetRef
}

func (l SavedPresetLane) Validate(playerID identity.PlayerID) error {
	if !playerID.Valid() || len(l.Heroes) == 0 || !utf8.ValidString(l.Name) || strings.Contains(l.Name, "|||") {
		return errors.New("character saved preset: invalid lane")
	}
	for _, ref := range l.Heroes {
		if ref.Validate() != nil || ref.PlayerID != playerID {
			return errors.New("character saved preset: invalid Hero reference")
		}
	}
	if l.Pet != nil {
		if l.Pet.Validate() != nil || l.Pet.PlayerID != playerID {
			return errors.New("character saved preset: invalid Pet reference")
		}
	}
	return nil
}

type SavedPresetAggregate struct {
	Root  SavedPresetRoot
	Lanes []SavedPresetLane
}

func (a SavedPresetAggregate) Validate() error {
	if err := a.Root.Validate(); err != nil {
		return err
	}
	for _, lane := range a.Lanes {
		if err := lane.Validate(a.Root.PlayerID); err != nil {
			return err
		}
	}
	return nil
}

func (a SavedPresetAggregate) IsEmpty() bool { return len(a.Lanes) == 0 }
