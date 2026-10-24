package characterpet

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type petAppearanceContributionQueryer struct{}

func (petAppearanceContributionQueryer) QueryRow(context.Context, string, ...any) tx.Row { return nil }

type petAppearanceContributionStore struct {
	pet        character.Pet
	styles     []character.PetStyleEntitlement
	ownerReads int
}

func (s *petAppearanceContributionStore) ReadPetByIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, error) {
	s.ownerReads++
	return s.pet, nil
}
func (s *petAppearanceContributionStore) ListPetStyleEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.PetStyleEntitlement, error) {
	return append([]character.PetStyleEntitlement(nil), s.styles...), nil
}

type petAppearanceContributionContent struct {
	active        bool
	revision      string
	revisionCalls int
}

func (c *petAppearanceContributionContent) AppearanceRevisionTx(_ context.Context, _ tx.Queryer, rev string) (bool, error) {
	c.revisionCalls++
	c.revision = rev
	return c.active, nil
}
func (*petAppearanceContributionContent) AppearanceSkinTx(context.Context, tx.Queryer, string, int64) (characterasset.AppearanceSkinDefinition, bool, error) {
	return characterasset.AppearanceSkinDefinition{}, false, nil
}
func (*petAppearanceContributionContent) AppearanceLIVETx(context.Context, tx.Queryer, string, int64) (characterasset.AppearanceLIVEDefinition, bool, error) {
	return characterasset.AppearanceLIVEDefinition{}, false, nil
}
func (*petAppearanceContributionContent) AppearancePetStyleTx(_ context.Context, _ tx.Queryer, _ string, id int64) (characterasset.AppearancePetStyleDefinition, bool, error) {
	if id == 50001376 {
		return characterasset.AppearancePetStyleDefinition{StyleItemID: id, PetOriginTableID: 10030001}, true, nil
	}
	return characterasset.AppearancePetStyleDefinition{}, false, nil
}

func petAppearanceContributionFixture() character.Pet {
	now := time.Unix(100, 0).UTC()
	return character.Pet{PlayerID: 7, PetID: 12, TableID: 10030001, OriginTableID: 10030001, Star: 1, Level: 1, Color: 1, Skills: character.DefaultPetSkillLevels(), ActiveStyle: 50001376, CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 6, CreatedAt: now, UpdatedAt: now}
}

func TestPetAppearanceContributionReaderUsesPinnedRevisionAndStableObservation(t *testing.T) {
	p := petAppearanceContributionFixture()
	at := time.Unix(200, 0).UTC()
	rev := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	st := &petAppearanceContributionStore{pet: p, styles: []character.PetStyleEntitlement{{PlayerID: 7, PetID: 12, StyleItemID: 50001376}}}
	c := &petAppearanceContributionContent{active: true}
	got, err := (AppearanceContributionReader{Store: st, Content: c}).PetAppearanceContributionTx(context.Background(), petAppearanceContributionQueryer{}, 7, 12, rev, at)
	if err != nil {
		t.Fatal(err)
	}
	if c.revision != rev || got.OwnerID != 12 || got.TableID != p.TableID || got.OriginTableID != p.OriginTableID || got.ContentRevision != rev {
		t.Fatalf("got=%+v revision=%q", got, c.revision)
	}
	if got.Appearance.OwnerStateVersion != 6 || !got.Appearance.ObservedAt.Equal(at) || got.Appearance.ActiveStyle != 50001376 || len(got.Appearance.OwnedStyles) != 1 {
		t.Fatalf("appearance=%+v", got.Appearance)
	}
	if err := got.Validate(); err != nil {
		t.Fatal(err)
	}
}

func TestPetAppearanceContributionReaderFailsClosedBeforeOwnerRead(t *testing.T) {
	st := &petAppearanceContributionStore{pet: petAppearanceContributionFixture()}
	c := &petAppearanceContributionContent{active: false}
	r := AppearanceContributionReader{Store: st, Content: c}
	rev := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	_, err := r.PetAppearanceContributionTx(context.Background(), petAppearanceContributionQueryer{}, 7, 12, rev, time.Unix(200, 0))
	if !errors.Is(err, ErrPetAppearanceContentInactive) {
		t.Fatalf("err=%v", err)
	}
	if st.ownerReads != 0 {
		t.Fatalf("owner reads=%d", st.ownerReads)
	}
	_, err = r.PetAppearanceContributionTx(context.Background(), petAppearanceContributionQueryer{}, 7, 12, "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", time.Unix(200, 0))
	if err == nil {
		t.Fatal("uppercase revision accepted")
	}
	if c.revisionCalls != 1 {
		t.Fatalf("invalid revision reached content: calls=%d", c.revisionCalls)
	}
}

func TestPetAppearanceContributionReloadIsDeterministicAndIndependent(t *testing.T) {
	p := petAppearanceContributionFixture()
	at := time.Unix(200, 0).UTC()
	rev := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	st := &petAppearanceContributionStore{pet: p, styles: []character.PetStyleEntitlement{{PlayerID: 7, PetID: 12, StyleItemID: 50001376}}}
	c := &petAppearanceContributionContent{active: true}
	r := AppearanceContributionReader{Store: st, Content: c}
	first, err := r.PetAppearanceContributionTx(context.Background(), petAppearanceContributionQueryer{}, 7, 12, rev, at)
	if err != nil {
		t.Fatal(err)
	}
	second, err := r.PetAppearanceContributionTx(context.Background(), petAppearanceContributionQueryer{}, 7, 12, rev, at)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(first, second) {
		t.Fatalf("reload drift first=%+v second=%+v", first, second)
	}
	first.Appearance.OwnedStyles[0] = 99999999
	third, err := r.PetAppearanceContributionTx(context.Background(), petAppearanceContributionQueryer{}, 7, 12, rev, at)
	if err != nil {
		t.Fatal(err)
	}
	if len(third.Appearance.OwnedStyles) != 1 || third.Appearance.OwnedStyles[0] != 50001376 {
		t.Fatalf("consumer mutation leaked into reload: %+v", third.Appearance)
	}
}

func TestPetAppearanceContributionReaderRejectsOwnerMismatch(t *testing.T) {
	p := petAppearanceContributionFixture()
	p.PetID = 13
	st := &petAppearanceContributionStore{pet: p}
	c := &petAppearanceContributionContent{active: true}
	_, err := (AppearanceContributionReader{Store: st, Content: c}).PetAppearanceContributionTx(
		context.Background(), petAppearanceContributionQueryer{}, 7, 12,
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", time.Unix(200, 0),
	)
	if err == nil {
		t.Fatal("mismatched Pet owner accepted")
	}
}

func TestPetAppearanceContributionFreezesObservationAcrossLaterDurableMutation(t *testing.T) {
	p := petAppearanceContributionFixture()
	at := time.Unix(200, 0).UTC()
	rev := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	st := &petAppearanceContributionStore{pet: p, styles: []character.PetStyleEntitlement{{PlayerID: 7, PetID: 12, StyleItemID: 50001376}}}
	c := &petAppearanceContributionContent{active: true}
	r := AppearanceContributionReader{Store: st, Content: c}
	frozen, err := r.PetAppearanceContributionTx(context.Background(), petAppearanceContributionQueryer{}, 7, 12, rev, at)
	if err != nil {
		t.Fatal(err)
	}
	st.pet.ActiveStyle = 0
	st.styles = nil
	later, err := r.PetAppearanceContributionTx(context.Background(), petAppearanceContributionQueryer{}, 7, 12, rev, at.Add(time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if frozen.Appearance.ActiveStyle != 50001376 || len(frozen.Appearance.OwnedStyles) != 1 || frozen.Appearance.OwnedStyles[0] != 50001376 {
		t.Fatalf("previously returned Pet contribution changed after durable mutation: %+v", frozen)
	}
	if later.Appearance.ActiveStyle != 0 || len(later.Appearance.OwnedStyles) != 0 {
		t.Fatalf("later Pet read did not observe new durable state: %+v", later)
	}
}
