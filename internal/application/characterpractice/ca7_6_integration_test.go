package characterpractice_test

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	heroapp "gxb.local/backend/v2/internal/application/characterhero"
	petapp "gxb.local/backend/v2/internal/application/characterpet"
	practice "gxb.local/backend/v2/internal/application/characterpractice"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	ca76AppearanceRev = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	ca76PracticeRev   = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
	ca76CreationRev   = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	ca76HeroSkin      = int64(40002006)
	ca76PetStyle      = int64(50001376)
)

type ca76Tag int64

func (t ca76Tag) RowsAffected() int64 { return int64(t) }

type ca76Row struct{ err error }

func (r ca76Row) Scan(...any) error { return r.err }

type ca76Tx struct{}

func (*ca76Tx) QueryRow(context.Context, string, ...any) tx.Row {
	return ca76Row{err: errors.New("unused CA7-6 row")}
}
func (*ca76Tx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return ca76Tag(1), nil }
func (*ca76Tx) Commit(context.Context) error                                { return nil }
func (*ca76Tx) Rollback(context.Context) error                              { return nil }

type ca76Harness struct {
	now           time.Time
	hero          character.Hero
	pet           character.Pet
	heroSkins     []character.HeroSkinEntitlement
	petStyles     []character.PetStyleEntitlement
	root          practice.Root
	heroProposal  map[string]practice.Proposal
	petProposal   map[string]practice.Proposal
	receipts      map[receipt.Identity]receipt.Receipt
	ticketQty     int64
	ticketPrepare int
	ticketApply   int
	scalarCalls   int
	trace         []string
}

func newCA76Harness(now time.Time) *ca76Harness {
	epoch, _ := practice.AlchemyEpochStartV1(now)
	vip := int64(0)
	return &ca76Harness{
		now: now.UTC(), ticketQty: 3, heroProposal: map[string]practice.Proposal{}, petProposal: map[string]practice.Proposal{}, receipts: map[receipt.Identity]receipt.Receipt{},
		hero:      character.Hero{PlayerID: 100001, PartnerID: 11, TableID: 101, OriginTableID: 101, Star: 1, Level: 1, Color: 1, Practice: character.PracticeAttrs{10, 10, 10}, CurrentSkinID: 0, IllusionSkinID: character.DefaultIllusionSkinID, CreationContentRevision: ca76CreationRev, StateVersion: 7, CreatedAt: now.Add(-time.Hour), UpdatedAt: now.Add(-time.Hour)},
		pet:       character.Pet{PlayerID: 100001, PetID: 21, TableID: 201, OriginTableID: 201, Star: 1, Level: 1, Color: 1, Practice: character.PracticeAttrs{10, 10, 10}, Skills: character.DefaultPetSkillLevels(), ActiveStyle: 0, CreationContentRevision: ca76CreationRev, StateVersion: 9, CreatedAt: now.Add(-time.Hour), UpdatedAt: now.Add(-time.Hour)},
		petStyles: []character.PetStyleEntitlement{{PlayerID: 100001, PetID: 21, StyleItemID: ca76PetStyle}},
		root:      practice.Root{PlayerID: 100001, DailyEpochStartAt: &epoch, DailyEpochPolicyVersion: practice.DailyEpochPolicyV1, BlessRemaining: 100, BlessCapacityAtEpoch: 100, BlessVIPLevelAtEpoch: &vip, BlessPrivilegeProviderRevision: "ca7-6.vip.v1", BlessContentRevision: ca76PracticeRev, StateVersion: 3, CreatedAt: now.Add(-48 * time.Hour), UpdatedAt: now.Add(-time.Hour)},
	}
}

func (*ca76Harness) Begin(context.Context, tx.Options) (tx.Tx, error) { return &ca76Tx{}, nil }
func (*ca76Harness) QueryRow(context.Context, string, ...any) tx.Row {
	return ca76Row{err: errors.New("unused CA7-6 query")}
}
func (h *ca76Harness) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	h.trace = append(h.trace, "fence")
	return nil
}

func proposalKey(s identity.SessionID, id int64) string {
	return s.UUID().String() + fmt.Sprintf("/%d", id)
}
func (h *ca76Harness) ReadPracticeRootTx(context.Context, tx.Queryer, identity.PlayerID) (practice.Root, error) {
	return h.root, nil
}
func (h *ca76Harness) LockPracticeRootTx(context.Context, tx.Tx, identity.PlayerID) (practice.Root, error) {
	h.trace = append(h.trace, "practice-root450")
	return h.root, nil
}
func (h *ca76Harness) SaveGenerationTx(_ context.Context, _ tx.Tx, n practice.Root, old int64) error {
	if h.root.StateVersion != old {
		return practice.ErrStaleVersion
	}
	h.root = n
	return nil
}
func (h *ca76Harness) SaveAccountingTx(_ context.Context, _ tx.Tx, n practice.Root, old int64) error {
	if h.root.StateVersion != old {
		return practice.ErrStaleVersion
	}
	h.root = n
	return nil
}
func (*ca76Harness) EnsureRootTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (bool, error) {
	return false, nil
}
func (h *ca76Harness) ReadHeroProposalTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID, s identity.SessionID, id int64) (practice.Proposal, error) {
	p, ok := h.heroProposal[proposalKey(s, id)]
	if !ok {
		return practice.Proposal{}, practice.ErrCandidateMissing
	}
	return p, nil
}
func (h *ca76Harness) LockHeroProposalTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, s identity.SessionID, id int64) (practice.Proposal, error) {
	h.trace = append(h.trace, "hero-proposal")
	return h.ReadHeroProposalTx(context.Background(), nil, 0, s, id)
}
func (h *ca76Harness) UpsertHeroProposalTx(_ context.Context, _ tx.Tx, p practice.Proposal) error {
	h.heroProposal[proposalKey(p.SessionID, p.ActorID)] = p
	return nil
}
func (h *ca76Harness) DeleteHeroProposalTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, s identity.SessionID, id int64) error {
	delete(h.heroProposal, proposalKey(s, id))
	return nil
}
func (h *ca76Harness) ReadPetProposalTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID, s identity.SessionID, id int64) (practice.Proposal, error) {
	p, ok := h.petProposal[proposalKey(s, id)]
	if !ok {
		return practice.Proposal{}, practice.ErrCandidateMissing
	}
	return p, nil
}
func (h *ca76Harness) LockPetProposalTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, s identity.SessionID, id int64) (practice.Proposal, error) {
	h.trace = append(h.trace, "pet-proposal")
	return h.ReadPetProposalTx(context.Background(), nil, 0, s, id)
}
func (h *ca76Harness) UpsertPetProposalTx(_ context.Context, _ tx.Tx, p practice.Proposal) error {
	h.petProposal[proposalKey(p.SessionID, p.ActorID)] = p
	return nil
}
func (h *ca76Harness) DeletePetProposalTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, s identity.SessionID, id int64) error {
	delete(h.petProposal, proposalKey(s, id))
	return nil
}

func (h *ca76Harness) LockHeroPracticeTx(_ context.Context, _ tx.Tx, ref character.HeroRef) (practice.HeroPracticeSnapshot, error) {
	h.trace = append(h.trace, "hero410-practice")
	if ref.PartnerID != h.hero.PartnerID {
		return practice.HeroPracticeSnapshot{}, practice.ErrActorMissing
	}
	return practice.HeroPracticeSnapshot{Ref: ref, TableID: h.hero.TableID, Practice: h.hero.Practice, StateVersion: h.hero.StateVersion}, nil
}
func (h *ca76Harness) CompareAndSwapHeroPracticeTx(_ context.Context, _ tx.Tx, ref character.HeroRef, old int64, next character.PracticeAttrs, at time.Time) error {
	if ref.PartnerID != h.hero.PartnerID {
		return practice.ErrActorMissing
	}
	if h.hero.StateVersion != old {
		return practice.ErrActorStaleVersion
	}
	h.hero.Practice = next
	h.hero.StateVersion++
	h.hero.UpdatedAt = at.UTC()
	return nil
}
func (h *ca76Harness) LockPetPracticeTx(_ context.Context, _ tx.Tx, ref character.PetRef) (practice.PetPracticeSnapshot, error) {
	h.trace = append(h.trace, "pet430-practice")
	if ref.PetID != h.pet.PetID {
		return practice.PetPracticeSnapshot{}, practice.ErrActorMissing
	}
	return practice.PetPracticeSnapshot{Ref: ref, TableID: h.pet.TableID, Practice: h.pet.Practice, StateVersion: h.pet.StateVersion}, nil
}
func (h *ca76Harness) CompareAndSwapPetPracticeTx(_ context.Context, _ tx.Tx, ref character.PetRef, old int64, next character.PracticeAttrs, at time.Time) error {
	if ref.PetID != h.pet.PetID {
		return practice.ErrActorMissing
	}
	if h.pet.StateVersion != old {
		return practice.ErrActorStaleVersion
	}
	h.pet.Practice = next
	h.pet.StateVersion++
	h.pet.UpdatedAt = at.UTC()
	return nil
}

func (*ca76Harness) PracticeActive(context.Context) (string, bool, error) {
	return ca76PracticeRev, true, nil
}
func (*ca76Harness) PracticeRevision(_ context.Context, r string) (bool, error) {
	return r == ca76PracticeRev, nil
}
func (*ca76Harness) PracticeMethodTx(_ context.Context, _ tx.Queryer, _ string, id int64) (practice.Method, error) {
	switch id {
	case 1:
		return practice.Method{ID: 1, CurrencyType: 1, BaseCost: 1, VIPMin: 0}, nil
	case 2:
		return practice.Method{ID: 2, CurrencyType: 2, BaseCost: 1, VIPMin: 0}, nil
	case 3:
		return practice.Method{ID: 3, CurrencyType: 2, BaseCost: 1, VIPMin: 0}, nil
	}
	return practice.Method{}, errors.New("missing method")
}
func (*ca76Harness) PracticeLockTx(context.Context, tx.Queryer, string, int64) (practice.LockCost, error) {
	return practice.LockCost{}, errors.New("unexpected lock policy")
}
func (*ca76Harness) PracticeVIPBlessTx(context.Context, tx.Queryer, string, int64) (int64, error) {
	return 100, nil
}
func (*ca76Harness) PracticePolicyFactsTx(context.Context, tx.Queryer, string) (practice.PolicyFacts, error) {
	return practice.PolicyFacts{UnlockLevel: 1, AttrCap: character.MaxPracticeAttr, FreeIntervalSeconds: 3600, LegendaryVIPMin: 0, TicketItemID: 9001, TicketAdd: character.PracticeAttrs{1, 1, 1}}, nil
}
func (*ca76Harness) HeroPracticeThresholdsTx(context.Context, tx.Queryer, string, int64) ([]practice.Threshold, error) {
	return nil, nil
}
func (*ca76Harness) PetPracticeThresholdsTx(context.Context, tx.Queryer, string, int64) ([]practice.Threshold, error) {
	return nil, nil
}
func (*ca76Harness) HeroTemplateAwakenedTx(context.Context, tx.Queryer, string, int64) (bool, error) {
	return true, nil
}
func (*ca76Harness) PetTemplateAwakenedTx(context.Context, tx.Queryer, string, int64) (bool, error) {
	return true, nil
}
func (*ca76Harness) SnapshotTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (appi5.PrivilegeSnapshot, error) {
	return appi5.PrivilegeSnapshot{ProviderRevision: "ca7-6.vip.v1", VIPLevel: 0}, nil
}
func (h *ca76Harness) PrepareLevelAndStackDebitTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, r appi5.LevelStackDebitRequest, _ operation.Context) (appi5.PreparedLevelStackDebit, error) {
	h.ticketPrepare++
	if r.ItemID != 9001 || r.Count != 1 || r.MinPlayerLevel != 1 || h.ticketQty < 1 {
		return appi5.PreparedLevelStackDebit{}, economy.ErrInsufficientBalance
	}
	return appi5.PreparedLevelStackDebit{}, nil
}
func (h *ca76Harness) ApplyLevelAndStackDebitTx(context.Context, tx.Tx, appi5.PreparedLevelStackDebit) (appi5.LevelStackDebitResult, error) {
	h.ticketApply++
	if h.ticketQty < 1 {
		return appi5.LevelStackDebitResult{}, economy.ErrInsufficientBalance
	}
	h.ticketQty--
	return appi5.LevelStackDebitResult{PlayerLevel: 100}, nil
}
func (h *ca76Harness) AuthorizeLevelAndDebitScalarTx(context.Context, tx.Tx, identity.PlayerID, int64, string, int64, time.Time) (int64, economy.ScalarBalance, error) {
	h.scalarCalls++
	return 100, economy.ScalarBalance{}, nil
}
func (*ca76Harness) PlayerLevelTx(context.Context, tx.Tx, identity.PlayerID) (int64, error) {
	return 100, nil
}

func (h *ca76Harness) PutTx(_ context.Context, _ tx.Tx, r receipt.Receipt) (receipt.PutResult, error) {
	if old, ok := h.receipts[r.Identity]; ok {
		return receipt.PutResult{Receipt: old}, nil
	}
	h.receipts[r.Identity] = r
	return receipt.PutResult{Receipt: r, Inserted: true}, nil
}
func (h *ca76Harness) FindTx(_ context.Context, _ tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	r, ok := h.receipts[id]
	return r, ok, nil
}
func (h *ca76Harness) Find(_ context.Context, id receipt.Identity) (receipt.Receipt, bool, error) {
	r, ok := h.receipts[id]
	return r, ok, nil
}

// Hero CA7-3 permanent-skin owner seam.
func (h *ca76Harness) LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error) {
	h.trace = append(h.trace, "hero410-ca7")
	return h.hero, nil
}
func (h *ca76Harness) ListHeroSkinEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.HeroSkinEntitlement, error) {
	return append([]character.HeroSkinEntitlement(nil), h.heroSkins...), nil
}
func (h *ca76Harness) SaveHeroAppearanceMutationTx(_ context.Context, _ tx.Tx, next character.Hero, ent *character.HeroSkinEntitlement, old int64) error {
	if h.hero.StateVersion != old || next.StateVersion != old+1 {
		return errors.New("hero CA7-6 CAS")
	}
	h.hero = next
	if ent != nil {
		h.heroSkins = append(h.heroSkins, *ent)
	}
	return nil
}
func (*ca76Harness) HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error) {
	return character.NormalHero, nil
}

// Shared CA7 immutable content surface.
func (*ca76Harness) AppearanceActive(context.Context) (string, bool, error) {
	return ca76AppearanceRev, true, nil
}
func (*ca76Harness) AppearanceRevision(_ context.Context, r string) (bool, error) {
	return r == ca76AppearanceRev, nil
}
func (*ca76Harness) AppearanceRevisionTx(_ context.Context, _ tx.Queryer, r string) (bool, error) {
	return r == ca76AppearanceRev, nil
}
func (*ca76Harness) AppearanceSkin(_ context.Context, _ string, id int64) (characterasset.AppearanceSkinDefinition, bool, error) {
	if id == ca76HeroSkin {
		return characterasset.AppearanceSkinDefinition{ModelID: id, HeroOriginTableID: 101}, true, nil
	}
	return characterasset.AppearanceSkinDefinition{}, false, nil
}
func (h *ca76Harness) AppearanceSkinTx(ctx context.Context, _ tx.Queryer, r string, id int64) (characterasset.AppearanceSkinDefinition, bool, error) {
	return h.AppearanceSkin(ctx, r, id)
}
func (*ca76Harness) AppearanceSkinItem(context.Context, string, int64) (characterasset.AppearanceSkinItemDefinition, bool, error) {
	return characterasset.AppearanceSkinItemDefinition{}, false, nil
}
func (*ca76Harness) AppearanceSkinItemTx(context.Context, tx.Queryer, string, int64) (characterasset.AppearanceSkinItemDefinition, bool, error) {
	return characterasset.AppearanceSkinItemDefinition{}, false, nil
}
func (*ca76Harness) AppearanceLIVE(context.Context, string, int64) (characterasset.AppearanceLIVEDefinition, bool, error) {
	return characterasset.AppearanceLIVEDefinition{}, false, nil
}
func (*ca76Harness) AppearanceLIVETx(context.Context, tx.Queryer, string, int64) (characterasset.AppearanceLIVEDefinition, bool, error) {
	return characterasset.AppearanceLIVEDefinition{}, false, nil
}
func (*ca76Harness) AppearancePetStyle(_ context.Context, _ string, id int64) (characterasset.AppearancePetStyleDefinition, bool, error) {
	if id == ca76PetStyle {
		return characterasset.AppearancePetStyleDefinition{StyleItemID: id, PetOriginTableID: 201}, true, nil
	}
	return characterasset.AppearancePetStyleDefinition{}, false, nil
}
func (h *ca76Harness) AppearancePetStyleTx(ctx context.Context, _ tx.Queryer, r string, id int64) (characterasset.AppearancePetStyleDefinition, bool, error) {
	return h.AppearancePetStyle(ctx, r, id)
}

// Pet CA7-5 owner/store seams. Unused CA3 methods remain inert but valid.
func (h *ca76Harness) ReadPetRoot(context.Context, identity.PlayerID) (character.PetRoot, error) {
	return character.PetRoot{PlayerID: 100001, NextPetID: 22, StateVersion: 1, CreatedAt: h.now.Add(-time.Hour), UpdatedAt: h.now}, nil
}
func (h *ca76Harness) ListPets(context.Context, identity.PlayerID) ([]character.Pet, error) {
	return []character.Pet{h.pet}, nil
}
func (h *ca76Harness) LockPetRootTx(context.Context, tx.Tx, identity.PlayerID) (character.PetRoot, error) {
	return h.ReadPetRoot(context.Background(), 100001)
}
func (*ca76Harness) SavePetRootAllocatorTx(context.Context, tx.Tx, character.PetRoot, int64) error {
	return errors.New("unexpected allocator")
}
func (*ca76Harness) SavePetRootFreeHatchTx(context.Context, tx.Tx, character.PetRoot, int64) error {
	return errors.New("unexpected hatch")
}
func (*ca76Harness) InsertPetTx(context.Context, tx.Tx, character.Pet) error {
	return errors.New("unexpected insert")
}
func (h *ca76Harness) FindPetByOriginTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, bool, error) {
	return h.pet, true, nil
}
func (h *ca76Harness) LockPetByIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Pet, bool, error) {
	h.trace = append(h.trace, "pet430-ca7")
	return h.pet, true, nil
}
func (*ca76Harness) SavePetShowStateTx(context.Context, tx.Tx, character.Pet, int64) error {
	return errors.New("unexpected show save")
}
func (*ca76Harness) SavePetStateTx(context.Context, tx.Tx, character.Pet, int64) error {
	return errors.New("unexpected state save")
}
func (h *ca76Harness) ListPetStyleEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.PetStyleEntitlement, error) {
	return append([]character.PetStyleEntitlement(nil), h.petStyles...), nil
}
func (h *ca76Harness) SavePetAppearanceMutationTx(context.Context, tx.Tx, character.Pet, *character.PetStyleEntitlement, int64) error {
	return errors.New("unexpected composite save")
}
func (h *ca76Harness) SavePetActiveStyleTx(_ context.Context, _ tx.Tx, next character.Pet, old int64) error {
	if h.pet.StateVersion != old || next.StateVersion != old+1 {
		return errors.New("pet CA7-6 CAS")
	}
	h.pet = next
	return nil
}

func ca76UUID(b byte) ids.UUID { var u ids.UUID; u[15] = b; return u }
func ca76Actor() identity.ActorContext {
	a, _ := identity.AccountIDFrom(ca76UUID(1))
	s, _ := identity.SessionIDFrom(ca76UUID(2))
	c, _ := identity.ContextIDFrom(ca76UUID(3))
	return identity.ActorContext{AccountID: a, AccountUID: "20000007", SessionID: s, ContextID: c, LogicalServerID: 1, PlayerID: 100001, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func ca76Op(b byte, at time.Time) operation.Context {
	var seed [32]byte
	for i := range seed {
		seed[i] = byte(i) + b
	}
	return operation.Context{ID: ca76UUID(b), StartedAt: at.UTC(), EntropySeed: seed}
}
func (h *ca76Harness) practiceService() practice.Service {
	return practice.Service{Runner: tx.Runner{DB: h}, Store: h, Content: h, Privileges: h, ReconcileQueryer: h, Deps: practice.ServiceDeps{Fencer: h, HeroOwner: h, PetOwner: h, Level: h, LevelAndScalar: h, TicketDebit: h, Receipts: h, ReceiptRead: h}}
}
func (h *ca76Harness) heroMaterializer() heroapp.PermanentSkinMaterializer {
	return heroapp.PermanentSkinMaterializer{Store: h, Content: h}
}
func (h *ca76Harness) petService() petapp.Service {
	return petapp.Service{Runner: tx.Runner{DB: h}, Store: h, Fencer: h, Receipts: h, ReceiptRead: h, Appearance: h, AppearanceMutationStore: h}
}

func TestCA76RealHeroTicketStalesAfterActualCA7MutationWithoutRefundOrDeletion(t *testing.T) {
	now := time.Date(2026, 9, 21, 1, 0, 0, 0, time.UTC)
	h := newCA76Harness(now)
	actor := ca76Actor()
	svc := h.practiceService()
	target := practice.Target{Hero: true, ActorID: 11}
	if _, err := svc.Ticket(context.Background(), actor, target, ca76Op(10, now)); err != nil {
		t.Fatal(err)
	}
	if h.ticketQty != 2 || h.ticketApply != 1 {
		t.Fatalf("ticket qty/apply=%d/%d", h.ticketQty, h.ticketApply)
	}
	pkey := proposalKey(actor.SessionID, 11)
	if _, ok := h.heroProposal[pkey]; !ok {
		t.Fatal("ticket proposal missing")
	}
	res, err := h.heroMaterializer().GrantPermanentSkinTx(context.Background(), &ca76Tx{}, heroapp.PermanentSkinGrant{PlayerID: actor.PlayerID, PartnerID: 11, ModelID: ca76HeroSkin, ContentRevision: ca76AppearanceRev, DecisionAt: now.Add(time.Minute)})
	if err != nil || !res.Mutated || h.hero.StateVersion != 8 {
		t.Fatalf("grant=%+v err=%v hero=%+v", res, err, h.hero)
	}
	if _, err := svc.Save(context.Background(), actor, target, ca76Op(11, now.Add(2*time.Minute))); !errors.Is(err, practice.ErrActorStaleVersion) {
		t.Fatalf("save err=%v", err)
	}
	if h.ticketQty != 2 || h.ticketApply != 1 {
		t.Fatalf("stale save changed ticket accounting qty/apply=%d/%d", h.ticketQty, h.ticketApply)
	}
	if _, ok := h.heroProposal[pkey]; !ok {
		t.Fatal("stale proposal deleted")
	}
	if h.hero.Practice != (character.PracticeAttrs{10, 10, 10}) {
		t.Fatalf("practice mutated=%v", h.hero.Practice)
	}
}

func TestCA76RealPetTicketStalesAfterActualCA7MutationWithoutRefundOrDeletion(t *testing.T) {
	now := time.Date(2026, 9, 21, 1, 0, 0, 0, time.UTC)
	h := newCA76Harness(now)
	actor := ca76Actor()
	svc := h.practiceService()
	target := practice.Target{Hero: false, ActorID: 21}
	if _, err := svc.Ticket(context.Background(), actor, target, ca76Op(20, now)); err != nil {
		t.Fatal(err)
	}
	pkey := proposalKey(actor.SessionID, 21)
	if _, ok := h.petProposal[pkey]; !ok {
		t.Fatal("ticket proposal missing")
	}
	res, err := h.petService().SelectPetStyle(context.Background(), actor, 21, ca76PetStyle, ca76Op(21, now.Add(time.Minute)))
	if err != nil || !res.Mutated || h.pet.StateVersion != 10 {
		t.Fatalf("select=%+v err=%v pet=%+v", res, err, h.pet)
	}
	if _, err := svc.Save(context.Background(), actor, target, ca76Op(22, now.Add(2*time.Minute))); !errors.Is(err, practice.ErrActorStaleVersion) {
		t.Fatalf("save err=%v", err)
	}
	if h.ticketQty != 2 || h.ticketApply != 1 {
		t.Fatalf("stale save changed ticket accounting qty/apply=%d/%d", h.ticketQty, h.ticketApply)
	}
	if _, ok := h.petProposal[pkey]; !ok {
		t.Fatal("stale proposal deleted")
	}
}

func TestCA76SemanticNoopPreservesPendingProposalValidity(t *testing.T) {
	now := time.Date(2026, 9, 21, 1, 0, 0, 0, time.UTC)
	actor := ca76Actor()
	t.Run("hero", func(t *testing.T) {
		h := newCA76Harness(now)
		h.heroSkins = []character.HeroSkinEntitlement{{PlayerID: actor.PlayerID, PartnerID: 11, ModelID: ca76HeroSkin}}
		svc := h.practiceService()
		target := practice.Target{Hero: true, ActorID: 11}
		if _, err := svc.Ticket(context.Background(), actor, target, ca76Op(30, now)); err != nil {
			t.Fatal(err)
		}
		before := h.hero.StateVersion
		res, err := h.heroMaterializer().GrantPermanentSkinTx(context.Background(), &ca76Tx{}, heroapp.PermanentSkinGrant{PlayerID: actor.PlayerID, PartnerID: 11, ModelID: ca76HeroSkin, ContentRevision: ca76AppearanceRev, DecisionAt: now.Add(time.Minute)})
		if err != nil || res.Mutated || h.hero.StateVersion != before {
			t.Fatalf("noop grant=%+v err=%v version=%d", res, err, h.hero.StateVersion)
		}
		if _, err := svc.Save(context.Background(), actor, target, ca76Op(31, now.Add(2*time.Minute))); err != nil {
			t.Fatal(err)
		}
		if h.hero.StateVersion != before+1 {
			t.Fatalf("save version=%d", h.hero.StateVersion)
		}
	})
	t.Run("pet", func(t *testing.T) {
		h := newCA76Harness(now)
		h.pet.ActiveStyle = ca76PetStyle
		svc := h.practiceService()
		target := practice.Target{Hero: false, ActorID: 21}
		if _, err := svc.Ticket(context.Background(), actor, target, ca76Op(40, now)); err != nil {
			t.Fatal(err)
		}
		before := h.pet.StateVersion
		res, err := h.petService().SelectPetStyle(context.Background(), actor, 21, ca76PetStyle, ca76Op(41, now.Add(time.Minute)))
		if err != nil || res.Mutated || h.pet.StateVersion != before {
			t.Fatalf("noop select=%+v err=%v version=%d", res, err, h.pet.StateVersion)
		}
		if _, err := svc.Save(context.Background(), actor, target, ca76Op(42, now.Add(2*time.Minute))); err != nil {
			t.Fatal(err)
		}
		if h.pet.StateVersion != before+1 {
			t.Fatalf("save version=%d", h.pet.StateVersion)
		}
	})
}

func TestCA76AUTOAndCA7SerializeBySharedOwnerVersionInBothOrders(t *testing.T) {
	now := time.Date(2026, 9, 21, 1, 0, 0, 0, time.UTC)
	actor := ca76Actor()
	t.Run("hero-ca7-then-auto", func(t *testing.T) {
		h := newCA76Harness(now)
		res, err := h.heroMaterializer().GrantPermanentSkinTx(context.Background(), &ca76Tx{}, heroapp.PermanentSkinGrant{PlayerID: actor.PlayerID, PartnerID: 11, ModelID: ca76HeroSkin, ContentRevision: ca76AppearanceRev, DecisionAt: now})
		if err != nil || !res.Mutated {
			t.Fatalf("grant=%+v err=%v", res, err)
		}
		auto, err := h.practiceService().Auto(context.Background(), actor, practice.AutoCommand{Target: practice.Target{Hero: true, ActorID: 11}, Method: 1, BatchSize: 2, Save: practice.AutoSavePredicates{true, true, true, true}}, ca76Op(50, now.Add(time.Minute)))
		if err != nil {
			t.Fatal(err)
		}
		if h.hero.StateVersion != 9 || auto.PracticeAttr != h.hero.Practice || len(h.heroSkins) != 1 {
			t.Fatalf("hero=%+v auto=%+v", h.hero, auto)
		}
	})
	t.Run("hero-auto-then-ca7", func(t *testing.T) {
		h := newCA76Harness(now)
		auto, err := h.practiceService().Auto(context.Background(), actor, practice.AutoCommand{Target: practice.Target{Hero: true, ActorID: 11}, Method: 1, BatchSize: 2, Save: practice.AutoSavePredicates{true, true, true, true}}, ca76Op(51, now))
		if err != nil {
			t.Fatal(err)
		}
		afterAuto := h.hero.StateVersion
		res, err := h.heroMaterializer().GrantPermanentSkinTx(context.Background(), &ca76Tx{}, heroapp.PermanentSkinGrant{PlayerID: actor.PlayerID, PartnerID: 11, ModelID: ca76HeroSkin, ContentRevision: ca76AppearanceRev, DecisionAt: now.Add(time.Minute)})
		if err != nil || !res.Mutated || h.hero.StateVersion != afterAuto+1 || auto.PracticeAttr != h.hero.Practice {
			t.Fatalf("grant=%+v err=%v hero=%+v auto=%+v", res, err, h.hero, auto)
		}
	})
	t.Run("pet-ca7-then-auto", func(t *testing.T) {
		h := newCA76Harness(now)
		res, err := h.petService().SelectPetStyle(context.Background(), actor, 21, ca76PetStyle, ca76Op(52, now))
		if err != nil || !res.Mutated {
			t.Fatalf("select=%+v err=%v", res, err)
		}
		auto, err := h.practiceService().Auto(context.Background(), actor, practice.AutoCommand{Target: practice.Target{Hero: false, ActorID: 21}, Method: 1, BatchSize: 2, Save: practice.AutoSavePredicates{true, true, true, true}}, ca76Op(53, now.Add(time.Minute)))
		if err != nil {
			t.Fatal(err)
		}
		if h.pet.StateVersion != 11 || auto.PracticeAttr != h.pet.Practice || h.pet.ActiveStyle != ca76PetStyle {
			t.Fatalf("pet=%+v auto=%+v", h.pet, auto)
		}
	})
}

func TestCA76AppearanceMutationsPreserveEarlierOwnedFields(t *testing.T) {
	now := time.Date(2026, 9, 21, 1, 0, 0, 0, time.UTC)
	actor := ca76Actor()
	t.Run("hero", func(t *testing.T) {
		h := newCA76Harness(now)
		h.hero.Star, h.hero.Level, h.hero.Exp, h.hero.Color = 4, 55, 9876, 7
		h.hero.Equipment = character.HeroEquipmentSlots{1, 0, 1, 0, 1, 0}
		h.hero.Fumo = character.HeroFumoSlots{2, 3, 4, 5, 6, 7}
		h.hero.Practice = character.PracticeAttrs{23, 34, 45}
		before := h.hero
		res, err := h.heroMaterializer().GrantPermanentSkinTx(context.Background(), &ca76Tx{}, heroapp.PermanentSkinGrant{PlayerID: actor.PlayerID, PartnerID: 11, ModelID: ca76HeroSkin, ContentRevision: ca76AppearanceRev, DecisionAt: now})
		if err != nil || !res.Mutated {
			t.Fatalf("grant=%+v err=%v", res, err)
		}
		if h.hero.Star != before.Star || h.hero.Level != before.Level || h.hero.Exp != before.Exp || h.hero.Color != before.Color || h.hero.Equipment != before.Equipment || h.hero.Fumo != before.Fumo || h.hero.Practice != before.Practice || h.hero.TableID != before.TableID || h.hero.OriginTableID != before.OriginTableID || h.hero.CreationContentRevision != before.CreationContentRevision {
			t.Fatalf("CA7 Hero mutation altered earlier-owned fields before=%+v after=%+v", before, h.hero)
		}
		if h.hero.StateVersion != before.StateVersion+1 {
			t.Fatalf("version=%d before=%d", h.hero.StateVersion, before.StateVersion)
		}
	})
	t.Run("pet", func(t *testing.T) {
		h := newCA76Harness(now)
		h.pet.Star, h.pet.Level, h.pet.Exp, h.pet.Color = 3, 44, 5432, 6
		h.pet.Equipment = character.PetEquipmentSlots{1, 0, 1}
		h.pet.Fumo = character.PetFumoSlots{5, 6, 7}
		h.pet.Practice = character.PracticeAttrs{31, 42, 53}
		h.pet.Skills = character.PetSkillLevels{2, 3, 4, 5, 6}
		h.pet.Birthday = 12345
		h.pet.IsShow = true
		before := h.pet
		res, err := h.petService().SelectPetStyle(context.Background(), actor, 21, ca76PetStyle, ca76Op(60, now))
		if err != nil || !res.Mutated {
			t.Fatalf("select=%+v err=%v", res, err)
		}
		if h.pet.Star != before.Star || h.pet.Level != before.Level || h.pet.Exp != before.Exp || h.pet.Color != before.Color || h.pet.Equipment != before.Equipment || h.pet.Fumo != before.Fumo || h.pet.Practice != before.Practice || h.pet.Skills != before.Skills || h.pet.Birthday != before.Birthday || h.pet.IsShow != before.IsShow || h.pet.TableID != before.TableID || h.pet.OriginTableID != before.OriginTableID || h.pet.CreationContentRevision != before.CreationContentRevision {
			t.Fatalf("CA7 Pet mutation altered earlier-owned fields before=%+v after=%+v", before, h.pet)
		}
		if h.pet.StateVersion != before.StateVersion+1 || h.pet.ActiveStyle != ca76PetStyle {
			t.Fatalf("after=%+v", h.pet)
		}
	})
}
