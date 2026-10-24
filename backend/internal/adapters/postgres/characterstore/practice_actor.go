package characterstore

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterqueries"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) SaveHeroPracticeTx(ctx context.Context, t tx.Tx, h character.Hero, oldVersion int64) error {
	if t == nil || oldVersion <= 0 || h.ValidatePersistent() != nil || h.StateVersion != oldVersion+1 || h.Practice.Validate() != nil {
		return errors.New("character store: invalid Hero Practice update")
	}
	tag, err := t.Exec(ctx, characterqueries.SaveHeroPractice, int64(h.PlayerID), h.PartnerID, h.Practice[0], h.Practice[1], h.Practice[2], h.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Hero Practice update lost race")
	}
	return nil
}

func (Store) SavePetPracticeTx(ctx context.Context, t tx.Tx, p character.Pet, oldVersion int64) error {
	if t == nil || oldVersion <= 0 || p.ValidatePersistent() != nil || p.StateVersion != oldVersion+1 || p.Practice.Validate() != nil {
		return errors.New("character store: invalid Pet Practice update")
	}
	tag, err := t.Exec(ctx, characterqueries.SavePetPractice, int64(p.PlayerID), p.PetID, p.Practice[0], p.Practice[1], p.Practice[2], p.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Pet Practice update lost race")
	}
	return nil
}

// LockHeroPracticeTx acquires the canonical Hero410 row lock while exposing
// only the immutable Practice-facing owner snapshot required by CA6.
func (s Store) LockHeroPracticeTx(ctx context.Context, t tx.Tx, ref character.HeroRef) (apppractice.HeroPracticeSnapshot, error) {
	if t == nil || ref.Validate() != nil {
		return apppractice.HeroPracticeSnapshot{}, errors.New("character store: invalid Hero Practice lock")
	}
	h, err := s.LockHeroByPartnerIDTx(ctx, t, ref.PlayerID, ref.PartnerID)
	if errors.Is(err, kernelstore.ErrNoRows) || errors.Is(err, sql.ErrNoRows) {
		return apppractice.HeroPracticeSnapshot{}, apppractice.ErrActorMissing
	}
	if err != nil {
		return apppractice.HeroPracticeSnapshot{}, err
	}
	snap := apppractice.HeroPracticeSnapshot{Ref: h.Ref(), TableID: h.TableID, Practice: h.Practice, StateVersion: h.StateVersion}
	if snap.Ref != ref || snap.Validate() != nil {
		return apppractice.HeroPracticeSnapshot{}, errors.New("character store: invalid locked Hero Practice snapshot")
	}
	return snap, nil
}

// CompareAndSwapHeroPracticeTx mutates only the CharacterHero-owned Practice
// tuple and the aggregate state version. No other Hero column is writable
// through the CA6 owner port.
func (Store) CompareAndSwapHeroPracticeTx(ctx context.Context, t tx.Tx, ref character.HeroRef, expectedVersion int64, next character.PracticeAttrs, updatedAt time.Time) error {
	if t == nil || ref.Validate() != nil || expectedVersion <= 0 || next.Validate() != nil || updatedAt.IsZero() {
		return errors.New("character store: invalid Hero Practice CAS")
	}
	tag, err := t.Exec(ctx, characterqueries.SaveHeroPractice, int64(ref.PlayerID), ref.PartnerID, next[0], next[1], next[2], updatedAt.UTC(), expectedVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return apppractice.ErrActorStaleVersion
	}
	return nil
}

// LockPetPracticeTx is the Pet430 equivalent of LockHeroPracticeTx.
func (s Store) LockPetPracticeTx(ctx context.Context, t tx.Tx, ref character.PetRef) (apppractice.PetPracticeSnapshot, error) {
	if t == nil || ref.Validate() != nil {
		return apppractice.PetPracticeSnapshot{}, errors.New("character store: invalid Pet Practice lock")
	}
	p, found, err := s.LockPetByIDTx(ctx, t, ref.PlayerID, ref.PetID)
	if err != nil {
		return apppractice.PetPracticeSnapshot{}, err
	}
	if !found {
		return apppractice.PetPracticeSnapshot{}, apppractice.ErrActorMissing
	}
	snap := apppractice.PetPracticeSnapshot{Ref: p.Ref(), TableID: p.TableID, Practice: p.Practice, StateVersion: p.StateVersion}
	if snap.Ref != ref || snap.Validate() != nil {
		return apppractice.PetPracticeSnapshot{}, errors.New("character store: invalid locked Pet Practice snapshot")
	}
	return snap, nil
}

// CompareAndSwapPetPracticeTx mutates only the CharacterPet-owned Practice
// tuple and aggregate state version.
func (Store) CompareAndSwapPetPracticeTx(ctx context.Context, t tx.Tx, ref character.PetRef, expectedVersion int64, next character.PracticeAttrs, updatedAt time.Time) error {
	if t == nil || ref.Validate() != nil || expectedVersion <= 0 || next.Validate() != nil || updatedAt.IsZero() {
		return errors.New("character store: invalid Pet Practice CAS")
	}
	tag, err := t.Exec(ctx, characterqueries.SavePetPractice, int64(ref.PlayerID), ref.PetID, next[0], next[1], next[2], updatedAt.UTC(), expectedVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return apppractice.ErrActorStaleVersion
	}
	return nil
}

var _ apppractice.HeroPracticeOwner = Store{}
var _ apppractice.PetPracticeOwner = Store{}
