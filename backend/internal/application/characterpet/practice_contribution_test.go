package characterpet

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type petPracticeContributionQueryer struct{}

func (petPracticeContributionQueryer) QueryRow(context.Context, string, ...any) tx.Row { return nil }

type petPracticeContributionStore struct {
	pet   character.Pet
	calls int
}

func (s *petPracticeContributionStore) ReadPetByIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, error) {
	s.calls++
	return s.pet, nil
}

type petPracticeContributionContent struct {
	good       bool
	revision   string
	tableID    int64
	thresholds []apppractice.Threshold
	err        error
}

func (c *petPracticeContributionContent) PracticeRevisionTx(_ context.Context, _ tx.Queryer, revision string) (bool, error) {
	c.revision = revision
	if c.err != nil {
		return false, c.err
	}
	return c.good, nil
}
func (c *petPracticeContributionContent) PetPracticeThresholdsTx(_ context.Context, _ tx.Queryer, revision string, tableID int64) ([]apppractice.Threshold, error) {
	c.revision = revision
	c.tableID = tableID
	if c.err != nil {
		return nil, c.err
	}
	return append([]apppractice.Threshold(nil), c.thresholds...), nil
}

func petPracticeContributionFixture() character.Pet {
	now := time.Unix(100, 0).UTC()
	rev := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	return character.Pet{PlayerID: 7, PetID: 12, TableID: 30001, OriginTableID: 30001, Star: 1, Level: 1, Color: 1, Practice: character.PracticeAttrs{1, 2, 3}, Skills: character.DefaultPetSkillLevels(), CreationContentRevision: rev, StateVersion: 6, CreatedAt: now, UpdatedAt: now}
}

func TestPetPracticeContributionReaderUsesSourceOrderOverwriteAndPinnedRevision(t *testing.T) {
	p := petPracticeContributionFixture()
	st := &petPracticeContributionStore{pet: p}
	c := &petPracticeContributionContent{good: true, thresholds: []apppractice.Threshold{{Ordinal: 1, NeedValue: 1, TargetAttrType: 2, BonusValue: 5}, {Ordinal: 2, NeedValue: 1, TargetAttrType: 2, BonusValue: 9}, {Ordinal: 3, NeedValue: 1, TargetAttrType: 20, BonusValue: 4}}}
	rev := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	got, err := (PracticeContributionReader{Store: st, Content: c}).PetPracticeContributionTx(context.Background(), petPracticeContributionQueryer{}, 7, 12, rev)
	if err != nil {
		t.Fatal(err)
	}
	if got.Family != characterasset.PracticeFamilyPet || got.OwnerID != 12 || got.StateVersion != 6 || got.ContentRevision != rev || got.Reducer != characterasset.PracticeReducerPetSourceOverwrite {
		t.Fatalf("got=%+v", got)
	}
	var attr2 int64
	for _, r := range got.Contributions {
		if r.AttrType == 2 {
			attr2 = r.Value
		}
	}
	if attr2 != 11 {
		t.Fatalf("attr2=%d rows=%v", attr2, got.Contributions)
	}
}

func TestPetPracticeContributionReaderFailsBeforeOwnerReadWhenRevisionInactive(t *testing.T) {
	st := &petPracticeContributionStore{pet: petPracticeContributionFixture()}
	c := &petPracticeContributionContent{good: false}
	_, err := (PracticeContributionReader{Store: st, Content: c}).PetPracticeContributionTx(context.Background(), petPracticeContributionQueryer{}, 7, 12, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
	if !errors.Is(err, apppractice.ErrContentInactive) {
		t.Fatalf("err=%v", err)
	}
	if st.calls != 0 {
		t.Fatalf("owner read occurred before revision qualification: %d", st.calls)
	}
}
