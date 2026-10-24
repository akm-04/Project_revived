package characterasset

import (
	"context"
	"errors"
	"fmt"

	"gxb.local/backend/v2/internal/domain/identity"
)

var ErrModeGuildCharacterRequest = errors.New("character asset: invalid mode/guild character request")

// ModeGuildCharacterReader is the Character-side CA8-8 provider boundary for
// future mode/Guild consumers. It exposes accepted saved-reference state and
// already-qualified lender-owned borrowed projections without taking ownership
// of selected/current formation, mode state or rental business policy.
//
// The caller retains the coherent transaction and must qualify any borrowed
// capability before invoking this reader. Raw stock rental fields deliberately
// never enter this boundary.
type ModeGuildCharacterReader struct {
	Owned    *OwnedCompositeBuilder
	Borrowed *BorrowedCompositeBuilder
}

// SavedPresetReferencesTx exposes the accepted CA5 ordered saved-reference
// state. Saved presets remain references only; this method does not select a
// preset or infer mode eligibility/current formation.
func (r ModeGuildCharacterReader) SavedPresetReferencesTx(ctx context.Context, scope CoherentReadScope, pid identity.PlayerID) (SavedPresetReferenceState, error) {
	if r.Owned == nil {
		return SavedPresetReferenceState{}, ErrModeGuildCharacterRequest
	}
	if err := scope.Validate(); err != nil {
		return SavedPresetReferenceState{}, err
	}
	if !pid.Valid() {
		return SavedPresetReferenceState{}, ErrModeGuildCharacterRequest
	}

	state, err := r.Owned.SavedPresetReferencesTx(ctx, scope, pid)
	if err != nil {
		return SavedPresetReferenceState{}, err
	}
	if err := state.Validate(); err != nil {
		return SavedPresetReferenceState{}, fmt.Errorf("%w: saved-preset state: %v", ErrModeGuildCharacterRequest, err)
	}
	if state.PlayerID != pid {
		return SavedPresetReferenceState{}, fmt.Errorf("%w: saved-preset owner", ErrModeGuildCharacterRequest)
	}
	return state.Clone(), nil
}

// BorrowedHeroTx projects exact lender-owned Character state for a capability
// already qualified by the owning mode/Guild/rental orchestrator. Opaque
// capability provenance is preserved byte-for-byte as typed string fields.
func (r ModeGuildCharacterReader) BorrowedHeroTx(ctx context.Context, scope CoherentReadScope, ref QualifiedBorrowedHeroReference) (BorrowedHeroComposite, error) {
	if r.Borrowed == nil {
		return BorrowedHeroComposite{}, ErrModeGuildCharacterRequest
	}
	if err := scope.Validate(); err != nil {
		return BorrowedHeroComposite{}, err
	}
	if err := ref.Validate(); err != nil {
		return BorrowedHeroComposite{}, err
	}

	borrowed, err := r.Borrowed.BorrowedHeroTx(ctx, scope, ref)
	if err != nil {
		return BorrowedHeroComposite{}, err
	}
	if borrowed.Origin != ActorOriginBorrowed || borrowed.QualifiedReference != ref || borrowed.Base.Ref != ref.ActorRef {
		return BorrowedHeroComposite{}, fmt.Errorf("%w: borrowed Hero coherence", ErrModeGuildCharacterRequest)
	}
	if err := borrowed.Validate(); err != nil {
		return BorrowedHeroComposite{}, err
	}
	return borrowed.clone(), nil
}

// BorrowedPetTx is the Pet equivalent of BorrowedHeroTx.
func (r ModeGuildCharacterReader) BorrowedPetTx(ctx context.Context, scope CoherentReadScope, ref QualifiedBorrowedPetReference) (BorrowedPetComposite, error) {
	if r.Borrowed == nil {
		return BorrowedPetComposite{}, ErrModeGuildCharacterRequest
	}
	if err := scope.Validate(); err != nil {
		return BorrowedPetComposite{}, err
	}
	if err := ref.Validate(); err != nil {
		return BorrowedPetComposite{}, err
	}

	borrowed, err := r.Borrowed.BorrowedPetTx(ctx, scope, ref)
	if err != nil {
		return BorrowedPetComposite{}, err
	}
	if borrowed.Origin != ActorOriginBorrowed || borrowed.QualifiedReference != ref || borrowed.Base.Ref != ref.ActorRef {
		return BorrowedPetComposite{}, fmt.Errorf("%w: borrowed Pet coherence", ErrModeGuildCharacterRequest)
	}
	if err := borrowed.Validate(); err != nil {
		return BorrowedPetComposite{}, err
	}
	return borrowed.clone(), nil
}
