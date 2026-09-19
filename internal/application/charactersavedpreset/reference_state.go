package charactersavedpreset

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ReferenceStateStore is intentionally narrower than the CA5 mutation Store.
// CA5-4 reads one owner aggregate and does not widen CA5-3 mutation coupling.
type ReferenceStateStore interface {
	ReadSavedPresetAggregateTx(context.Context, tx.Queryer, identity.PlayerID) (character.SavedPresetAggregate, error)
}

type ReferenceStateReader struct {
	Store ReferenceStateStore
}

func (r ReferenceStateReader) SavedPresetReferenceStateTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (characterasset.SavedPresetReferenceState, error) {
	if r.Store == nil || q == nil || !pid.Valid() {
		return characterasset.SavedPresetReferenceState{}, errors.New("saved preset: invalid reference-state read")
	}
	agg, err := r.Store.ReadSavedPresetAggregateTx(ctx, q, pid)
	if err != nil {
		return characterasset.SavedPresetReferenceState{}, err
	}
	if err := agg.Validate(); err != nil || agg.Root.PlayerID != pid {
		if err != nil {
			return characterasset.SavedPresetReferenceState{}, err
		}
		return characterasset.SavedPresetReferenceState{}, errors.New("saved preset: reference-state actor mismatch")
	}
	out := characterasset.SavedPresetReferenceState{
		PlayerID:     pid,
		StateVersion: agg.Root.StateVersion,
		Loadouts:     make([]characterasset.SavedPresetReferenceLoadout, len(agg.Lanes)),
	}
	for i, lane := range agg.Lanes {
		out.Loadouts[i].Heroes = append([]character.HeroRef(nil), lane.Heroes...)
		if lane.Pet != nil {
			pet := *lane.Pet
			out.Loadouts[i].Pet = &pet
		}
	}
	if err := out.Validate(); err != nil {
		return characterasset.SavedPresetReferenceState{}, err
	}
	return out, nil
}
