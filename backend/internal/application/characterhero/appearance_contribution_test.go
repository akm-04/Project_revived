package characterhero

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

type heroAppearanceContributionQueryer struct{}

func (heroAppearanceContributionQueryer) QueryRow(context.Context, string, ...any) tx.Row { return nil }

type heroAppearanceContributionStore struct {
	hero       character.Hero
	skins      []character.HeroSkinEntitlement
	lives      []character.HeroLIVEEntitlement
	ownerReads int
}

func (s *heroAppearanceContributionStore) ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error) {
	s.ownerReads++
	return s.hero, nil
}
func (s *heroAppearanceContributionStore) ListHeroSkinEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.HeroSkinEntitlement, error) {
	return append([]character.HeroSkinEntitlement(nil), s.skins...), nil
}
func (s *heroAppearanceContributionStore) ListHeroLIVEEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.HeroLIVEEntitlement, error) {
	return append([]character.HeroLIVEEntitlement(nil), s.lives...), nil
}

type heroAppearanceContributionContent struct {
	active             bool
	kind               character.HeroKind
	kindRevision       string
	appearanceRevision string
	revisionCalls      int
}

func (c *heroAppearanceContributionContent) AppearanceRevisionTx(_ context.Context, _ tx.Queryer, rev string) (bool, error) {
	c.revisionCalls++
	c.appearanceRevision = rev
	return c.active, nil
}
func (c *heroAppearanceContributionContent) HeroKindTx(_ context.Context, _ tx.Queryer, rev string, _ int64) (character.HeroKind, error) {
	c.kindRevision = rev
	return c.kind, nil
}
func (*heroAppearanceContributionContent) AppearanceSkinTx(_ context.Context, _ tx.Queryer, _ string, id int64) (characterasset.AppearanceSkinDefinition, bool, error) {
	if id == 40002006 {
		return characterasset.AppearanceSkinDefinition{ModelID: id, HeroOriginTableID: 1001}, true, nil
	}
	return characterasset.AppearanceSkinDefinition{}, false, nil
}
func (*heroAppearanceContributionContent) AppearanceLIVETx(_ context.Context, _ tx.Queryer, _ string, id int64) (characterasset.AppearanceLIVEDefinition, bool, error) {
	if id == 45001 {
		return characterasset.AppearanceLIVEDefinition{ModelID: id, HeroOriginTableID: 1001, CrystalCost: 1, ActivationItemID: 2, ActivationItemCount: 1}, true, nil
	}
	return characterasset.AppearanceLIVEDefinition{}, false, nil
}
func (*heroAppearanceContributionContent) AppearancePetStyleTx(context.Context, tx.Queryer, string, int64) (characterasset.AppearancePetStyleDefinition, bool, error) {
	return characterasset.AppearancePetStyleDefinition{}, false, nil
}

func heroAppearanceContributionFixture() character.Hero {
	now := time.Unix(100, 0).UTC()
	return character.Hero{RawSkills: character.NewHeroRawSkillSeed(), PlayerID: 7, PartnerID: 9, TableID: 10001003, OriginTableID: 1001, Star: 1, Level: 1, Color: 1, CurrentSkinID: 40002006, IllusionSkinID: -1, CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 8, CreatedAt: now, UpdatedAt: now}
}

func TestHeroAppearanceContributionReaderUsesPinnedRevisionAndCreationKindProvenance(t *testing.T) {
	h := heroAppearanceContributionFixture()
	at := time.Unix(200, 0).UTC()
	rev := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	st := &heroAppearanceContributionStore{hero: h, skins: []character.HeroSkinEntitlement{{PlayerID: 7, PartnerID: 9, ModelID: 40002006}}, lives: []character.HeroLIVEEntitlement{{PlayerID: 7, PartnerID: 9, ModelID: 45001, IsShow: true}}}
	c := &heroAppearanceContributionContent{active: true, kind: character.NormalHero}
	got, err := (AppearanceContributionReader{Store: st, Content: c}).HeroAppearanceContributionTx(context.Background(), heroAppearanceContributionQueryer{}, 7, 9, rev, at)
	if err != nil {
		t.Fatal(err)
	}
	if c.appearanceRevision != rev || c.kindRevision != h.CreationContentRevision {
		t.Fatalf("appearance/kind revisions=%q/%q", c.appearanceRevision, c.kindRevision)
	}
	if got.OwnerID != h.PartnerID || got.TableID != h.TableID || got.OriginTableID != h.OriginTableID || got.ContentRevision != rev {
		t.Fatalf("identity=%+v", got)
	}
	if got.Appearance.OwnerStateVersion != h.StateVersion || !got.Appearance.ObservedAt.Equal(at) || got.Appearance.CurrentSkinID != 40002006 || len(got.Appearance.Skins) != 1 || len(got.Appearance.LIVE) != 1 {
		t.Fatalf("appearance=%+v", got.Appearance)
	}
	if err := got.Validate(); err != nil {
		t.Fatal(err)
	}
}

func TestHeroAppearanceContributionReaderFailsClosedBeforeOwnerRead(t *testing.T) {
	st := &heroAppearanceContributionStore{hero: heroAppearanceContributionFixture()}
	c := &heroAppearanceContributionContent{active: false, kind: character.NormalHero}
	r := AppearanceContributionReader{Store: st, Content: c}
	rev := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	_, err := r.HeroAppearanceContributionTx(context.Background(), heroAppearanceContributionQueryer{}, 7, 9, rev, time.Unix(200, 0))
	if !errors.Is(err, ErrAppearanceContentInactive) {
		t.Fatalf("err=%v", err)
	}
	if st.ownerReads != 0 {
		t.Fatalf("owner reads=%d", st.ownerReads)
	}
	_, err = r.HeroAppearanceContributionTx(context.Background(), heroAppearanceContributionQueryer{}, 7, 9, "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", time.Unix(200, 0))
	if err == nil {
		t.Fatal("uppercase revision accepted")
	}
	if c.revisionCalls != 1 {
		t.Fatalf("invalid revision reached content: calls=%d", c.revisionCalls)
	}
}

func TestHeroAppearanceContributionReloadIsDeterministicAndIndependent(t *testing.T) {
	h := heroAppearanceContributionFixture()
	at := time.Unix(200, 0).UTC()
	rev := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	expires := at.Add(time.Hour)
	st := &heroAppearanceContributionStore{
		hero:  h,
		skins: []character.HeroSkinEntitlement{{PlayerID: 7, PartnerID: 9, ModelID: 40002006, ExpiresAt: &expires}},
		lives: []character.HeroLIVEEntitlement{{PlayerID: 7, PartnerID: 9, ModelID: 45001, IsShow: true}},
	}
	c := &heroAppearanceContributionContent{active: true, kind: character.NormalHero}
	r := AppearanceContributionReader{Store: st, Content: c}
	first, err := r.HeroAppearanceContributionTx(context.Background(), heroAppearanceContributionQueryer{}, 7, 9, rev, at)
	if err != nil {
		t.Fatal(err)
	}
	second, err := r.HeroAppearanceContributionTx(context.Background(), heroAppearanceContributionQueryer{}, 7, 9, rev, at)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(first, second) {
		t.Fatalf("reload drift first=%+v second=%+v", first, second)
	}
	if len(first.Appearance.Skins) != 1 || first.Appearance.Skins[0].ExpiresAt == nil {
		t.Fatalf("missing timed skin: %+v", first.Appearance)
	}
	// Mutating a consumer-owned result must not mutate durable/store input or a later reload.
	first.Appearance.Skins[0].ModelID = 99999999
	*first.Appearance.Skins[0].ExpiresAt = at.Add(-time.Hour)
	first.Appearance.LIVE[0].ModelID = 99999998
	third, err := r.HeroAppearanceContributionTx(context.Background(), heroAppearanceContributionQueryer{}, 7, 9, rev, at)
	if err != nil {
		t.Fatal(err)
	}
	if third.Appearance.Skins[0].ModelID != 40002006 || !third.Appearance.Skins[0].ExpiresAt.Equal(expires) || third.Appearance.LIVE[0].ModelID != 45001 {
		t.Fatalf("consumer mutation leaked into reload: %+v", third.Appearance)
	}
}

func TestHeroAppearanceContributionReaderRejectsOwnerMismatch(t *testing.T) {
	h := heroAppearanceContributionFixture()
	h.PartnerID = 10
	st := &heroAppearanceContributionStore{hero: h}
	c := &heroAppearanceContributionContent{active: true, kind: character.NormalHero}
	_, err := (AppearanceContributionReader{Store: st, Content: c}).HeroAppearanceContributionTx(
		context.Background(), heroAppearanceContributionQueryer{}, 7, 9,
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", time.Unix(200, 0),
	)
	if err == nil {
		t.Fatal("mismatched Hero owner accepted")
	}
}

func TestHeroAppearanceContributionFreezesObservationAcrossLaterDurableMutation(t *testing.T) {
	h := heroAppearanceContributionFixture()
	at := time.Unix(200, 0).UTC()
	rev := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	expires := at.Add(time.Hour)
	st := &heroAppearanceContributionStore{
		hero:  h,
		skins: []character.HeroSkinEntitlement{{PlayerID: 7, PartnerID: 9, ModelID: 40002006, ExpiresAt: &expires}},
	}
	c := &heroAppearanceContributionContent{active: true, kind: character.NormalHero}
	r := AppearanceContributionReader{Store: st, Content: c}
	frozen, err := r.HeroAppearanceContributionTx(context.Background(), heroAppearanceContributionQueryer{}, 7, 9, rev, at)
	if err != nil {
		t.Fatal(err)
	}
	st.hero.CurrentSkinID = 0
	past := at.Add(-time.Second)
	st.skins[0].ExpiresAt = &past
	later, err := r.HeroAppearanceContributionTx(context.Background(), heroAppearanceContributionQueryer{}, 7, 9, rev, at.Add(time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if frozen.Appearance.CurrentSkinID != 40002006 || len(frozen.Appearance.Skins) != 1 || frozen.Appearance.Skins[0].ExpiresAt == nil || !frozen.Appearance.Skins[0].ExpiresAt.Equal(expires) {
		t.Fatalf("previously returned contribution changed after durable mutation: %+v", frozen)
	}
	if later.Appearance.CurrentSkinID != 0 || len(later.Appearance.Skins) != 0 {
		t.Fatalf("later read did not observe new durable/time-qualified state: %+v", later)
	}
}
