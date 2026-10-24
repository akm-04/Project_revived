package characterasset

import (
	"errors"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
)

// SavedPresetReferenceState is CA5's immutable, revision-qualified observation
// for later CA8/I9 consumers. It is the whole ordered saved-reference set at
// one saved-preset root revision; it is not a selected/current formation and
// deliberately carries no presentation name or mode policy.
type SavedPresetReferenceState struct {
	PlayerID     identity.PlayerID
	StateVersion int64
	Loadouts     []SavedPresetReferenceLoadout
}

type SavedPresetReferenceLoadout struct {
	Heroes []character.HeroRef
	Pet    *character.PetRef
}

func (s SavedPresetReferenceState) Validate() error {
	if !s.PlayerID.Valid() || s.StateVersion <= 0 {
		return errors.New("character asset: invalid saved-preset reference state")
	}
	for _, loadout := range s.Loadouts {
		if len(loadout.Heroes) == 0 {
			return errors.New("character asset: empty saved-preset reference loadout")
		}
		for _, ref := range loadout.Heroes {
			if err := ref.Validate(); err != nil || ref.PlayerID != s.PlayerID {
				return errors.New("character asset: invalid saved-preset Hero reference")
			}
		}
		if loadout.Pet != nil {
			if err := loadout.Pet.Validate(); err != nil || loadout.Pet.PlayerID != s.PlayerID {
				return errors.New("character asset: invalid saved-preset Pet reference")
			}
		}
	}
	return nil
}

// Clone returns a fully independent value so later CA5 mutations cannot alter
// a previously accepted downstream observation through shared slices/pointers.
func (s SavedPresetReferenceState) Clone() SavedPresetReferenceState {
	out := SavedPresetReferenceState{
		PlayerID:     s.PlayerID,
		StateVersion: s.StateVersion,
		Loadouts:     make([]SavedPresetReferenceLoadout, len(s.Loadouts)),
	}
	for i, loadout := range s.Loadouts {
		out.Loadouts[i].Heroes = append([]character.HeroRef(nil), loadout.Heroes...)
		if loadout.Pet != nil {
			pet := *loadout.Pet
			out.Loadouts[i].Pet = &pet
		}
	}
	return out
}
