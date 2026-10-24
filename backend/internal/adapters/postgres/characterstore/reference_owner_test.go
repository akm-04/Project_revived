package characterstore

import (
	"context"
	"errors"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/characterqueries"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type referenceOwnerRow struct{ err error }

func (r referenceOwnerRow) Scan(...any) error { return r.err }

type referenceOwnerTx struct {
	query string
	args  []any
	err   error
}

func (t *referenceOwnerTx) QueryRow(_ context.Context, q string, args ...any) tx.Row {
	t.query = q
	t.args = append([]any(nil), args...)
	return referenceOwnerRow{err: t.err}
}
func (*referenceOwnerTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return nil, errors.New("unexpected exec")
}
func (*referenceOwnerTx) Commit(context.Context) error   { return nil }
func (*referenceOwnerTx) Rollback(context.Context) error { return nil }

func TestHeroReferenceOwnerLocksExactOwnerRowAndNormalizesMissing(t *testing.T) {
	ref := character.HeroRef{PlayerID: 7, PartnerID: 9}
	k, err := (Store{}).HeroReferenceLockKey(ref)
	if err != nil {
		t.Fatal(err)
	}
	tx := &referenceOwnerTx{err: kernelstore.ErrNoRows}
	err = (Store{}).LockHeroReferenceKeyTx(context.Background(), tx, k, ref)
	if !errors.Is(err, characterasset.ErrReferenceNotFound) {
		t.Fatalf("missing err=%v", err)
	}
	if tx.query != characterqueries.LockHeroByPartnerID || !reflect.DeepEqual(tx.args, []any{int64(7), int64(9)}) {
		t.Fatalf("query=%q args=%v", tx.query, tx.args)
	}
}

func TestPetReferenceOwnerLocksExactOwnerRowAndNormalizesMissing(t *testing.T) {
	ref := character.PetRef{PlayerID: 7, PetID: 9}
	k, err := (Store{}).PetReferenceLockKey(ref)
	if err != nil {
		t.Fatal(err)
	}
	tx := &referenceOwnerTx{err: kernelstore.ErrNoRows}
	err = (Store{}).LockPetReferenceKeyTx(context.Background(), tx, k, ref)
	if !errors.Is(err, characterasset.ErrReferenceNotFound) {
		t.Fatalf("missing err=%v", err)
	}
	if tx.query != characterqueries.LockPetByID || !reflect.DeepEqual(tx.args, []any{int64(7), int64(9)}) {
		t.Fatalf("query=%q args=%v", tx.query, tx.args)
	}
}

func TestReferenceOwnerRejectsWrongFamilyBeforeQuery(t *testing.T) {
	petKey, err := characterasset.PetReferenceLockKey(character.PetRef{PlayerID: 7, PetID: 9})
	if err != nil {
		t.Fatal(err)
	}
	tx := &referenceOwnerTx{err: kernelstore.ErrNoRows}
	want := character.HeroRef{PlayerID: 7, PartnerID: 9}
	if err := (Store{}).LockHeroReferenceKeyTx(context.Background(), tx, petKey, want); err == nil {
		t.Fatal("Pet key accepted by Hero owner")
	}
	if tx.query != "" {
		t.Fatalf("wrong-family key reached database query %q", tx.query)
	}
	otherPlayerKey, _ := characterasset.HeroReferenceLockKey(character.HeroRef{PlayerID: 8, PartnerID: 9})
	if err := (Store{}).LockHeroReferenceKeyTx(context.Background(), tx, otherPlayerKey, want); err == nil {
		t.Fatal("other-player Hero key accepted")
	}
	otherIDKey, _ := characterasset.HeroReferenceLockKey(character.HeroRef{PlayerID: 7, PartnerID: 10})
	if err := (Store{}).LockHeroReferenceKeyTx(context.Background(), tx, otherIDKey, want); err == nil {
		t.Fatal("other-instance Hero key accepted")
	}
	if tx.query != "" {
		t.Fatalf("mismatched Hero key reached database query %q", tx.query)
	}
}

func TestReferenceOwnerPropagatesInfrastructureFailure(t *testing.T) {
	infra := errors.New("connection lost")
	hk, _ := characterasset.HeroReferenceLockKey(character.HeroRef{PlayerID: 7, PartnerID: 9})
	tx := &referenceOwnerTx{err: infra}
	if err := (Store{}).LockHeroReferenceKeyTx(context.Background(), tx, hk, character.HeroRef{PlayerID: 7, PartnerID: 9}); !errors.Is(err, infra) {
		t.Fatalf("Hero infrastructure err=%v", err)
	}
	pk, _ := characterasset.PetReferenceLockKey(character.PetRef{PlayerID: 7, PetID: 9})
	tx = &referenceOwnerTx{err: infra}
	if err := (Store{}).LockPetReferenceKeyTx(context.Background(), tx, pk, character.PetRef{PlayerID: 7, PetID: 9}); !errors.Is(err, infra) {
		t.Fatalf("Pet infrastructure err=%v", err)
	}
}
