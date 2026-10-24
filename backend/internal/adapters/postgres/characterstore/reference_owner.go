package characterstore

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) HeroReferenceLockKey(ref character.HeroRef) (lockkey.Key, error) {
	return characterasset.HeroReferenceLockKey(ref)
}

func (s Store) LockHeroReferenceKeyTx(ctx context.Context, t tx.Tx, k lockkey.Key, ref character.HeroRef) error {
	if t == nil || ref.Validate() != nil {
		return errors.New("character store: invalid Hero reference lock")
	}
	want, err := characterasset.HeroReferenceLockKey(ref)
	if err != nil || lockkey.Compare(want, k) != 0 {
		return lockkey.ErrInvalidKey
	}
	h, err := s.LockHeroByPartnerIDTx(ctx, t, ref.PlayerID, ref.PartnerID)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return characterasset.ErrReferenceNotFound
	}
	if err != nil {
		return err
	}
	if h.Ref() != ref {
		return errors.New("character store: Hero reference lock identity mismatch")
	}
	return nil
}

func (Store) PetReferenceLockKey(ref character.PetRef) (lockkey.Key, error) {
	return characterasset.PetReferenceLockKey(ref)
}

func (s Store) LockPetReferenceKeyTx(ctx context.Context, t tx.Tx, k lockkey.Key, ref character.PetRef) error {
	if t == nil || ref.Validate() != nil {
		return errors.New("character store: invalid Pet reference lock")
	}
	want, err := characterasset.PetReferenceLockKey(ref)
	if err != nil || lockkey.Compare(want, k) != 0 {
		return lockkey.ErrInvalidKey
	}
	p, found, err := s.LockPetByIDTx(ctx, t, ref.PlayerID, ref.PetID)
	if err != nil {
		return err
	}
	if !found {
		return characterasset.ErrReferenceNotFound
	}
	if p.Ref() != ref {
		return errors.New("character store: Pet reference lock identity mismatch")
	}
	return nil
}

var _ characterasset.HeroReferenceOwner = Store{}
var _ characterasset.PetReferenceOwner = Store{}
