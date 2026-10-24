package characterhero

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const ca73TestRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

type ca73Time struct{ at time.Time }

func (t ca73Time) Now(context.Context) (time.Time, error) { return t.at.UTC(), nil }

type ca73Content struct {
	skins map[int64]characterasset.AppearanceSkinDefinition
	items map[int64]characterasset.AppearanceSkinItemDefinition
}

func (c ca73Content) AppearanceActive(context.Context) (string, bool, error) {
	return ca73TestRevision, true, nil
}
func (c ca73Content) AppearanceRevision(context.Context, string) (bool, error) { return true, nil }
func (c ca73Content) AppearanceRevisionTx(context.Context, tx.Queryer, string) (bool, error) {
	return true, nil
}
func (c ca73Content) AppearanceSkin(_ context.Context, _ string, id int64) (characterasset.AppearanceSkinDefinition, bool, error) {
	v, ok := c.skins[id]
	return v, ok, nil
}
func (c ca73Content) AppearanceSkinTx(_ context.Context, _ tx.Queryer, _ string, id int64) (characterasset.AppearanceSkinDefinition, bool, error) {
	v, ok := c.skins[id]
	return v, ok, nil
}
func (c ca73Content) AppearanceSkinItem(_ context.Context, _ string, id int64) (characterasset.AppearanceSkinItemDefinition, bool, error) {
	v, ok := c.items[id]
	return v, ok, nil
}
func (c ca73Content) AppearanceSkinItemTx(_ context.Context, _ tx.Queryer, _ string, id int64) (characterasset.AppearanceSkinItemDefinition, bool, error) {
	v, ok := c.items[id]
	return v, ok, nil
}
func (ca73Content) AppearanceLIVE(context.Context, string, int64) (characterasset.AppearanceLIVEDefinition, bool, error) {
	return characterasset.AppearanceLIVEDefinition{}, false, nil
}
func (ca73Content) AppearanceLIVETx(context.Context, tx.Queryer, string, int64) (characterasset.AppearanceLIVEDefinition, bool, error) {
	return characterasset.AppearanceLIVEDefinition{}, false, nil
}
func (ca73Content) AppearancePetStyle(context.Context, string, int64) (characterasset.AppearancePetStyleDefinition, bool, error) {
	return characterasset.AppearancePetStyleDefinition{}, false, nil
}
func (ca73Content) AppearancePetStyleTx(context.Context, tx.Queryer, string, int64) (characterasset.AppearancePetStyleDefinition, bool, error) {
	return characterasset.AppearancePetStyleDefinition{}, false, nil
}
func (ca73Content) HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error) {
	return character.NormalHero, nil
}

type ca73Store struct {
	hero  character.Hero
	ents  []character.HeroSkinEntitlement
	saves int
}

func (s *ca73Store) LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error) {
	return s.hero, nil
}
func (s *ca73Store) ListHeroSkinEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.HeroSkinEntitlement, error) {
	return append([]character.HeroSkinEntitlement(nil), s.ents...), nil
}
func (s *ca73Store) SaveHeroAppearanceMutationTx(_ context.Context, _ tx.Tx, h character.Hero, ent *character.HeroSkinEntitlement, old int64) error {
	if s.hero.StateVersion != old || h.StateVersion != old+1 {
		return errors.New("test CA7-3 store: bad version")
	}
	s.hero = h
	if ent != nil {
		s.ents = replaceSkinEntitlement(s.ents, *ent)
	}
	s.saves++
	return nil
}

type ca73Material struct {
	debits int
	item   int64
	err    error
}

func (m *ca73Material) DebitMaterialCostTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, cost appi5.MaterialCost, _ operation.Context) (appi5.MaterialDebitResult, error) {
	if len(cost.Stacks) != 1 || cost.Stacks[0].Amount != 1 {
		return appi5.MaterialDebitResult{}, errors.New("test CA7-3 material: unexpected cost")
	}
	m.debits++
	m.item = cost.Stacks[0].ItemID
	if m.err != nil {
		return appi5.MaterialDebitResult{}, m.err
	}
	return appi5.MaterialDebitResult{}, nil
}

func ca73Hero(at time.Time) character.Hero {
	h := heroAt(11, 1001, 1001, 3, 10, 0, at)
	h.CreationContentRevision = ca73TestRevision
	h.IllusionSkinID = character.DefaultIllusionSkinID
	return h
}

func ca73ContentFixture() ca73Content {
	return ca73Content{
		skins: map[int64]characterasset.AppearanceSkinDefinition{
			40002006: {ModelID: 40002006, HeroOriginTableID: 1001},
			40002007: {ModelID: 40002007, HeroOriginTableID: 1001},
		},
		items: map[int64]characterasset.AppearanceSkinItemDefinition{
			50001807: {ItemID: 50001807, ModelID: 40002006, HeroOriginTableID: 1001, DurationSeconds: 3 * 24 * 60 * 60},
			50009163: {ItemID: 50009163, ModelID: 40002006, HeroOriginTableID: 1001, DurationSeconds: 3 * 24 * 60 * 60},
			50010001: {ItemID: 50010001, ModelID: 40002006, HeroOriginTableID: 1001},
			50010002: {ItemID: 50010002, ModelID: 40002007, HeroOriginTableID: 1001},
		},
	}
}

func ca73Service(at time.Time, h character.Hero, ents []character.HeroSkinEntitlement) (Service, *ca73Store, *ca73Material, *receipts) {
	st := &ca73Store{hero: h, ents: append([]character.HeroSkinEntitlement(nil), ents...)}
	mat := &ca73Material{}
	rec := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	content := ca73ContentFixture()
	core := &store{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 12, StateVersion: 1, CreatedAt: at, UpdatedAt: at}}
	runner := tx.Runner{DB: fakeDB{}}
	return Service{
		Runner: runner, Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: ca73Time{at}}, Runner: runner},
		Store: core, Fencer: &fence{}, Content: gate(true), Receipts: rec, ReceiptRead: rec,
		MaterialCosts: mat, AppearanceMutationStore: st, AppearanceMutationContent: content,
	}, st, mat, rec
}

func skinEnt(player identity.PlayerID, partner, model int64, expiry *time.Time) character.HeroSkinEntitlement {
	return character.HeroSkinEntitlement{PlayerID: player, PartnerID: partner, ModelID: model, ExpiresAt: expiry}
}

func TestCA73MID60TimedAcquireDoesNotAutoEquipAndReplaysSameOperation(t *testing.T) {
	at := time.Unix(1_700_000_000, 0).UTC()
	h := ca73Hero(at.Add(-time.Hour))
	// Stale unowned selector intent must be normalized before acquisition.
	h.CurrentSkinID = 40002006
	svc, st, mat, _ := ca73Service(at, h, nil)
	op := testOp(t, "a1010101-0101-4101-8101-010101010101")
	got, err := svc.SkinOn(context.Background(), testActor(t), 11, 50001807, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.CurrentSkinID != 0 || !got.RemoveItem || !got.Mutated || got.StateVersion != 2 || mat.debits != 1 || st.saves != 1 {
		t.Fatalf("got=%+v debits=%d saves=%d hero=%+v", got, mat.debits, st.saves, st.hero)
	}
	if len(got.Skins) != 1 || got.Skins[0].ExpiresAtUnix == nil || *got.Skins[0].ExpiresAtUnix != at.Add(72*time.Hour).Unix() {
		t.Fatalf("skin projection=%+v", got.Skins)
	}
	if st.hero.CurrentSkinID != 0 || st.hero.IllusionSkinID != character.DefaultIllusionSkinID {
		t.Fatalf("acquisition auto-equipped or resurrected selector: %+v", st.hero)
	}
	replay, err := svc.SkinOn(context.Background(), testActor(t), 11, 50001807, op)
	if err != nil || !replay.Replayed || mat.debits != 1 || st.saves != 1 {
		t.Fatalf("replay=%+v err=%v debits=%d saves=%d", replay, err, mat.debits, st.saves)
	}
}

func TestCA73MID60PermanentAcquireAndPermanentReselect(t *testing.T) {
	at := time.Unix(1_700_025_000, 0).UTC()
	h := ca73Hero(at.Add(-time.Hour))
	h.CurrentSkinID = 40002007 // stale unowned intent must not survive acquisition.
	svc, st, mat, _ := ca73Service(at, h, nil)
	got, err := svc.SkinOn(context.Background(), testActor(t), 11, 50010001, testOp(t, "ae0e0e0e-0e0e-4e0e-8e0e-0e0e0e0e0e0e"))
	if err != nil || !got.RemoveItem || got.CurrentSkinID != 0 || mat.debits != 1 || len(st.ents) != 1 || st.ents[0].ExpiresAt != nil || st.hero.StateVersion != 2 {
		t.Fatalf("permanent acquire=%+v err=%v debits=%d hero=%+v ents=%+v", got, err, mat.debits, st.hero, st.ents)
	}
	got, err = svc.SkinOn(context.Background(), testActor(t), 11, 50010001, testOp(t, "af0f0f0f-0f0f-4f0f-8f0f-0f0f0f0f0f0f"))
	if err != nil || got.RemoveItem || got.CurrentSkinID != 40002006 || mat.debits != 1 || st.hero.StateVersion != 3 {
		t.Fatalf("permanent reselect=%+v err=%v debits=%d hero=%+v", got, err, mat.debits, st.hero)
	}
}

func TestCA73MID60DeadlineMinusOneRemainsActiveWithoutDebit(t *testing.T) {
	deadline := time.Unix(1_700_090_000, 0).UTC()
	at := deadline.Add(-time.Second)
	h := ca73Hero(at.Add(-time.Hour))
	svc, st, mat, _ := ca73Service(at, h, []character.HeroSkinEntitlement{skinEnt(7, 11, 40002006, &deadline)})
	got, err := svc.SkinOn(context.Background(), testActor(t), 11, 50001807, testOp(t, "b0101010-1010-4010-8010-101010101010"))
	if err != nil || got.RemoveItem || mat.debits != 0 || got.CurrentSkinID != 40002006 || st.hero.StateVersion != 2 {
		t.Fatalf("deadline-1=%+v err=%v debits=%d hero=%+v", got, err, mat.debits, st.hero)
	}
}

func TestCA73MID60ActiveTimedPromotesPermanentWithoutAutoEquip(t *testing.T) {
	at := time.Unix(1_700_150_000, 0).UTC()
	expires := at.Add(time.Hour)
	h := ca73Hero(at.Add(-time.Hour))
	svc, st, mat, _ := ca73Service(at, h, []character.HeroSkinEntitlement{skinEnt(7, 11, 40002006, &expires)})
	got, err := svc.SkinOn(context.Background(), testActor(t), 11, 50010001, testOp(t, "b1111111-1111-4111-8111-111111111111"))
	if err != nil || !got.RemoveItem || got.CurrentSkinID != 0 || mat.debits != 1 || len(st.ents) != 1 || st.ents[0].ExpiresAt != nil || st.hero.StateVersion != 2 {
		t.Fatalf("active promotion=%+v err=%v debits=%d hero=%+v ents=%+v", got, err, mat.debits, st.hero, st.ents)
	}
}

func TestCA73MID60KnownUnqualifiedAnomalyFailsClosedWithoutDebit(t *testing.T) {
	at := time.Unix(1_700_165_000, 0).UTC()
	h := ca73Hero(at.Add(-time.Hour))
	svc, st, mat, _ := ca73Service(at, h, nil)
	_, err := svc.SkinOn(context.Background(), testActor(t), 11, 50005191, testOp(t, "b6161616-1616-4616-8616-161616161616"))
	if !errors.Is(err, ErrHeroAppearanceUnavailable) || mat.debits != 0 || st.saves != 0 || st.hero.StateVersion != 1 {
		t.Fatalf("err=%v debits=%d saves=%d hero=%+v", err, mat.debits, st.saves, st.hero)
	}
}

func TestCA73MID60InsufficientCardRejectsWithoutHeroMutation(t *testing.T) {
	at := time.Unix(1_700_175_000, 0).UTC()
	h := ca73Hero(at.Add(-time.Hour))
	svc, st, mat, _ := ca73Service(at, h, nil)
	mat.err = economy.ErrInsufficientBalance
	_, err := svc.SkinOn(context.Background(), testActor(t), 11, 50001807, testOp(t, "b2121212-1212-4212-8212-121212121212"))
	if !errors.Is(err, ErrHeroAppearanceUnavailable) || st.saves != 0 || st.hero.StateVersion != 1 || len(st.ents) != 0 {
		t.Fatalf("err=%v saves=%d hero=%+v ents=%+v", err, st.saves, st.hero, st.ents)
	}
}

func TestCA73MID60FreshRepeatReevaluatesCurrentStateWithoutExtendingTimedGrant(t *testing.T) {
	at := time.Unix(1_700_000_000, 0).UTC()
	expires := at.Add(24 * time.Hour)
	h := ca73Hero(at.Add(-time.Hour))
	svc, st, mat, _ := ca73Service(at, h, []character.HeroSkinEntitlement{skinEnt(7, 11, 40002006, &expires)})
	first, err := svc.SkinOn(context.Background(), testActor(t), 11, 50001807, testOp(t, "a2020202-0202-4202-8202-020202020202"))
	if err != nil {
		t.Fatal(err)
	}
	if first.CurrentSkinID != 40002006 || first.RemoveItem || mat.debits != 0 || st.hero.StateVersion != 2 {
		t.Fatalf("first=%+v debits=%d hero=%+v", first, mat.debits, st.hero)
	}
	second, err := svc.SkinOn(context.Background(), testActor(t), 11, 50001807, testOp(t, "a3030303-0303-4303-8303-030303030303"))
	if err != nil {
		t.Fatal(err)
	}
	if second.Mutated || second.RemoveItem || second.Replayed || st.hero.StateVersion != 2 || mat.debits != 0 {
		t.Fatalf("fresh repeat=%+v debits=%d hero=%+v", second, mat.debits, st.hero)
	}
	if len(st.ents) != 1 || st.ents[0].ExpiresAt == nil || !st.ents[0].ExpiresAt.Equal(expires) {
		t.Fatalf("timed grant was extended: %+v", st.ents)
	}
}

func TestCA73MID60DeadlineEqualityValidThenExpiredReacquires(t *testing.T) {
	deadline := time.Unix(1_700_100_000, 0).UTC()
	base := ca73Hero(deadline.Add(-time.Hour))
	ent := skinEnt(7, 11, 40002006, &deadline)

	svc, st, mat, _ := ca73Service(deadline, base, []character.HeroSkinEntitlement{ent})
	got, err := svc.SkinOn(context.Background(), testActor(t), 11, 50001807, testOp(t, "a4040404-0404-4404-8404-040404040404"))
	if err != nil || got.RemoveItem || mat.debits != 0 || st.hero.CurrentSkinID != 40002006 {
		t.Fatalf("deadline equality result=%+v err=%v debits=%d hero=%+v", got, err, mat.debits, st.hero)
	}

	after := deadline.Add(time.Second)
	base.CurrentSkinID = 40002006
	svc, st, mat, _ = ca73Service(after, base, []character.HeroSkinEntitlement{ent})
	got, err = svc.SkinOn(context.Background(), testActor(t), 11, 50001807, testOp(t, "a5050505-0505-4505-8505-050505050505"))
	if err != nil || !got.RemoveItem || mat.debits != 1 || got.CurrentSkinID != 0 || st.hero.CurrentSkinID != 0 {
		t.Fatalf("expired reacquire result=%+v err=%v debits=%d hero=%+v", got, err, mat.debits, st.hero)
	}
	if st.ents[0].ExpiresAt == nil || !st.ents[0].ExpiresAt.Equal(after.Add(72*time.Hour)) {
		t.Fatalf("new deadline=%+v", st.ents)
	}
}

func TestCA73MID60PermanentTrialRejectedAndTimedPromotesPermanent(t *testing.T) {
	at := time.Unix(1_700_200_000, 0).UTC()
	h := ca73Hero(at.Add(-time.Hour))
	permanent := skinEnt(7, 11, 40002006, nil)
	svc, st, mat, _ := ca73Service(at, h, []character.HeroSkinEntitlement{permanent})
	_, err := svc.SkinOn(context.Background(), testActor(t), 11, 50009163, testOp(t, "a6060606-0606-4606-8606-060606060606"))
	if !errors.Is(err, ErrHeroSkinExperienceAlreadyOwned) || mat.debits != 0 || st.saves != 0 {
		t.Fatalf("err=%v debits=%d saves=%d", err, mat.debits, st.saves)
	}

	expired := at.Add(-time.Second)
	h.CurrentSkinID = 40002006
	svc, st, mat, _ = ca73Service(at, h, []character.HeroSkinEntitlement{skinEnt(7, 11, 40002006, &expired)})
	got, err := svc.SkinOn(context.Background(), testActor(t), 11, 50010001, testOp(t, "a7070707-0707-4707-8707-070707070707"))
	if err != nil || !got.RemoveItem || mat.debits != 1 || got.CurrentSkinID != 0 || len(st.ents) != 1 || st.ents[0].ExpiresAt != nil {
		t.Fatalf("promotion=%+v err=%v debits=%d ents=%+v hero=%+v", got, err, mat.debits, st.ents, st.hero)
	}
}

func TestCA73MID61NoOpDoesNotBumpVersionAndPreservesIllusion(t *testing.T) {
	at := time.Unix(1_700_300_000, 0).UTC()
	h := ca73Hero(at.Add(-time.Hour))
	h.CurrentSkinID = 0
	h.IllusionSkinID = 1
	svc, st, _, _ := ca73Service(at, h, nil)
	// Proves non-consumptive operation does not require the Economy debit port.
	svc.MaterialCosts = nil
	got, err := svc.SkinCancel(context.Background(), testActor(t), 11, testOp(t, "a8080808-0808-4808-8808-080808080808"))
	if err != nil || got.Mutated || st.hero.StateVersion != 1 || st.hero.IllusionSkinID != 1 || st.saves != 0 {
		t.Fatalf("got=%+v err=%v hero=%+v saves=%d", got, err, st.hero, st.saves)
	}
}

func TestCA73MID61MutationAndSameAttemptReplay(t *testing.T) {
	at := time.Unix(1_700_325_000, 0).UTC()
	h := ca73Hero(at.Add(-time.Hour))
	h.CurrentSkinID = 40002006
	h.IllusionSkinID = 1
	svc, st, _, _ := ca73Service(at, h, nil)
	svc.MaterialCosts = nil
	op := testOp(t, "b3131313-1313-4313-8313-131313131313")
	got, err := svc.SkinCancel(context.Background(), testActor(t), 11, op)
	if err != nil || !got.Mutated || got.CurrentSkinID != 0 || got.StateVersion != 2 || st.hero.IllusionSkinID != 1 || st.saves != 1 {
		t.Fatalf("cancel=%+v err=%v hero=%+v saves=%d", got, err, st.hero, st.saves)
	}
	replay, err := svc.SkinCancel(context.Background(), testActor(t), 11, op)
	if err != nil || !replay.Replayed || st.saves != 1 || st.hero.StateVersion != 2 {
		t.Fatalf("replay=%+v err=%v hero=%+v saves=%d", replay, err, st.hero, st.saves)
	}
}

func TestCA73MID2979SentinelNoOpAndReplay(t *testing.T) {
	at := time.Unix(1_700_425_000, 0).UTC()
	h := ca73Hero(at.Add(-time.Hour))
	h.IllusionSkinID = 1
	svc, st, _, _ := ca73Service(at, h, nil)
	svc.MaterialCosts = nil
	op := testOp(t, "b4141414-1414-4414-8414-141414141414")
	got, err := svc.UseIllusionSkinItem(context.Background(), testActor(t), 11, 1, op)
	if err != nil || got.Mutated || got.IllusionSkinID != 1 || st.saves != 0 || st.hero.StateVersion != 1 {
		t.Fatalf("no-op=%+v err=%v hero=%+v saves=%d", got, err, st.hero, st.saves)
	}
	replay, err := svc.UseIllusionSkinItem(context.Background(), testActor(t), 11, 1, op)
	if err != nil || !replay.Replayed || st.saves != 0 || st.hero.StateVersion != 1 {
		t.Fatalf("replay=%+v err=%v hero=%+v saves=%d", replay, err, st.hero, st.saves)
	}
	base, err := svc.UseIllusionSkinItem(context.Background(), testActor(t), 11, 0, testOp(t, "b5151515-1515-4515-8515-151515151515"))
	if err != nil || !base.Mutated || base.IllusionSkinID != 0 || st.hero.StateVersion != 2 || st.saves != 1 {
		t.Fatalf("base=%+v err=%v hero=%+v saves=%d", base, err, st.hero, st.saves)
	}
}

func TestCA73MID2979RequiresEffectiveOwnedSkinAndKeepsOrdinaryAxis(t *testing.T) {
	at := time.Unix(1_700_400_000, 0).UTC()
	h := ca73Hero(at.Add(-time.Hour))
	h.CurrentSkinID = 40002006
	expires := at.Add(time.Hour)
	svc, st, _, _ := ca73Service(at, h, []character.HeroSkinEntitlement{skinEnt(7, 11, 40002007, &expires)})
	svc.MaterialCosts = nil
	got, err := svc.UseIllusionSkinItem(context.Background(), testActor(t), 11, 50010002, testOp(t, "a9090909-0909-4909-8909-090909090909"))
	if err != nil || got.IllusionSkinID != 40002007 || st.hero.CurrentSkinID != 40002006 || st.hero.IllusionSkinID != 40002007 {
		t.Fatalf("got=%+v err=%v hero=%+v", got, err, st.hero)
	}

	expired := at.Add(-time.Second)
	h = ca73Hero(at.Add(-time.Hour))
	svc, st, _, _ = ca73Service(at, h, []character.HeroSkinEntitlement{skinEnt(7, 11, 40002007, &expired)})
	svc.MaterialCosts = nil
	_, err = svc.UseIllusionSkinItem(context.Background(), testActor(t), 11, 50010002, testOp(t, "ab0b0b0b-0b0b-4b0b-8b0b-0b0b0b0b0b0b"))
	if !errors.Is(err, ErrHeroAppearanceUnavailable) || st.saves != 0 {
		t.Fatalf("expired illusion err=%v saves=%d", err, st.saves)
	}
}

func TestCA73PermanentSkinMaterializerConvergesOneOwnerVersionWithoutAutoEquip(t *testing.T) {
	at := time.Unix(1_700_500_000, 0).UTC()
	expired := at.Add(-time.Second)
	h := ca73Hero(at.Add(-time.Hour))
	h.CurrentSkinID = 40002006
	st := &ca73Store{hero: h, ents: []character.HeroSkinEntitlement{skinEnt(7, 11, 40002006, &expired)}}
	m := PermanentSkinMaterializer{Store: st, Content: ca73ContentFixture()}
	got, err := m.GrantPermanentSkinTx(context.Background(), &fakeTx{}, PermanentSkinGrant{PlayerID: 7, PartnerID: 11, ModelID: 40002006, ContentRevision: ca73TestRevision, DecisionAt: at})
	if err != nil || !got.Mutated || got.StateVersion != 2 || st.hero.CurrentSkinID != 0 || st.hero.StateVersion != 2 || st.ents[0].ExpiresAt != nil || st.saves != 1 {
		t.Fatalf("got=%+v err=%v hero=%+v ents=%+v saves=%d", got, err, st.hero, st.ents, st.saves)
	}
	got, err = m.GrantPermanentSkinTx(context.Background(), &fakeTx{}, PermanentSkinGrant{PlayerID: 7, PartnerID: 11, ModelID: 40002006, ContentRevision: ca73TestRevision, DecisionAt: at})
	if err != nil || got.Mutated || st.saves != 1 || st.hero.StateVersion != 2 {
		t.Fatalf("converged grant=%+v err=%v saves=%d hero=%+v", got, err, st.saves, st.hero)
	}
}

// Atomic store for the race where two fresh identical MID60 packets reach an
// expired timed entitlement. The first reacquires and consumes; after the Hero
// lock is released, the waiter must observe active ownership and only select.
type ca73AtomicStore struct {
	mu    sync.Mutex
	hero  character.Hero
	ents  []character.HeroSkinEntitlement
	saves int
}

func (s *ca73AtomicStore) LockHeroByPartnerIDTx(_ context.Context, t tx.Tx, _ identity.PlayerID, _ int64) (character.Hero, error) {
	at, ok := t.(*ca45AtomicTx)
	if !ok {
		return character.Hero{}, errors.New("test CA7-3 atomic store: unexpected tx")
	}
	at.lockHero()
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.hero, nil
}
func (s *ca73AtomicStore) ListHeroSkinEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.HeroSkinEntitlement, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]character.HeroSkinEntitlement(nil), s.ents...), nil
}
func (s *ca73AtomicStore) SaveHeroAppearanceMutationTx(_ context.Context, t tx.Tx, h character.Hero, ent *character.HeroSkinEntitlement, old int64) error {
	at, ok := t.(*ca45AtomicTx)
	if !ok {
		return errors.New("test CA7-3 atomic store: unexpected tx")
	}
	s.mu.Lock()
	if s.hero.StateVersion != old || h.StateVersion != old+1 {
		s.mu.Unlock()
		return errors.New("test CA7-3 atomic store: bad version")
	}
	s.mu.Unlock()
	var copied *character.HeroSkinEntitlement
	if ent != nil {
		v := *ent
		copied = &v
	}
	at.stage(func() {
		s.mu.Lock()
		defer s.mu.Unlock()
		s.hero = h
		if copied != nil {
			s.ents = replaceSkinEntitlement(s.ents, *copied)
		}
		s.saves++
	})
	return nil
}

func TestCA73ConcurrentExpiredReacquireConsumesOnceThenWaiterSelects(t *testing.T) {
	at := time.Unix(1_700_600_000, 0).UTC()
	expired := at.Add(-time.Second)
	h := ca73Hero(at.Add(-time.Hour))
	heroMu := &sync.Mutex{}
	db := &ca45AtomicDB{heroMu: heroMu}
	st := &ca73AtomicStore{hero: h, ents: []character.HeroSkinEntitlement{skinEnt(7, 11, 40002006, &expired)}}
	mat := &ca45AtomicMaterial{}
	rec := newCA45AtomicReceipts()
	content := ca73ContentFixture()
	core := &store{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 12, StateVersion: 1, CreatedAt: at, UpdatedAt: at}}
	runner := tx.Runner{DB: db}
	svc := Service{Runner: runner, Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: ca73Time{at}}, Runner: runner}, Store: core, Fencer: ca45AtomicFence{}, Content: gate(true), Receipts: rec, ReceiptRead: rec, MaterialCosts: mat, AppearanceMutationStore: st, AppearanceMutationContent: content}

	ops := []operation.Context{
		testOp(t, "ac0c0c0c-0c0c-4c0c-8c0c-0c0c0c0c0c0c"),
		testOp(t, "ad0d0d0d-0d0d-4d0d-8d0d-0d0d0d0d0d0d"),
	}
	results := make(chan SkinOnResult, 2)
	errs := make(chan error, 2)
	var wg sync.WaitGroup
	for _, op := range ops {
		op := op
		wg.Add(1)
		go func() {
			defer wg.Done()
			got, err := svc.SkinOn(context.Background(), testActor(t), 11, 50001807, op)
			results <- got
			errs <- err
		}()
	}
	wg.Wait()
	close(results)
	close(errs)
	for err := range errs {
		if err != nil {
			t.Fatal(err)
		}
	}
	consumed := 0
	for got := range results {
		if got.RemoveItem {
			consumed++
		}
	}
	if consumed != 1 {
		t.Fatalf("consumptive results=%d", consumed)
	}
	if n, item, count := mat.snapshot(); n != 1 || item != 50001807 || count != 1 {
		t.Fatalf("debits=%d item=%d count=%d", n, item, count)
	}
	st.mu.Lock()
	defer st.mu.Unlock()
	if st.hero.CurrentSkinID != 40002006 || st.hero.StateVersion != 3 || st.saves != 2 || len(st.ents) != 1 || st.ents[0].ExpiresAt == nil || !st.ents[0].ExpiresAt.Equal(at.Add(72*time.Hour)) {
		t.Fatalf("final hero=%+v ents=%+v saves=%d", st.hero, st.ents, st.saves)
	}
}
