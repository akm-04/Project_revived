package characterpet

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type petBaseQ struct{}

func (petBaseQ) QueryRow(context.Context, string, ...any) tx.Row { return nil }

type petBaseStore struct{ p character.Pet }

func (s petBaseStore) ReadPetByIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, error) {
	return s.p, nil
}

func TestPetBaseObservationPreservesCA3LifecycleAndSkillsOnly(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	rev := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	p := character.Pet{PlayerID: 7, PetID: 3, TableID: 2001, OriginTableID: 2001, Star: 2, Level: 4, Exp: 5, Color: 6, Equipment: character.PetEquipmentSlots{1}, Fumo: character.PetFumoSlots{9}, Practice: character.PracticeAttrs{1, 2, 3}, Skills: character.PetSkillLevels{2, 3, 4, 5, 6}, Birthday: 123, IsShow: false, ActiveStyle: 88, CreationContentRevision: rev, StateVersion: 14, CreatedAt: now, UpdatedAt: now}
	got, err := (BaseObservationReader{Store: petBaseStore{p: p}}).PetBaseObservationTx(context.Background(), petBaseQ{}, 7, 3)
	if err != nil {
		t.Fatal(err)
	}
	if got.Ref != p.Ref() || got.Birthday != 123 || got.IsShow || got.Skills != p.Skills || got.StateVersion != 14 || got.CreationContentRevision != rev {
		t.Fatalf("got=%+v", got)
	}
}
