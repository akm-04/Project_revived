package characterhero

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fakeTag int64

func (t fakeTag) RowsAffected() int64 { return int64(t) }

type fakeRow struct{ err error }

func (r fakeRow) Scan(...any) error { return r.err }

type fakeTx struct{}

func (*fakeTx) QueryRow(context.Context, string, ...any) tx.Row {
	return fakeRow{err: errors.New("unexpected query")}
}
func (*fakeTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return fakeTag(1), nil }
func (*fakeTx) Commit(context.Context) error                                { return nil }
func (*fakeTx) Rollback(context.Context) error                              { return nil }

type fakeDB struct{}

func (fakeDB) Begin(context.Context, tx.Options) (tx.Tx, error) { return &fakeTx{}, nil }

type gate bool

func (g gate) HeroCoreActive(context.Context) (string, bool, error) { return "rev", bool(g), nil }
func (g gate) HeroKind(context.Context, string, int64) (character.HeroKind, error) {
	return character.NormalHero, nil
}

type rosterProjection struct {
	equipmentOK bool
	fumoOK      bool
	positions   map[int64]character.HeroEquipmentPosition
	targets     map[character.EquipmentTemplateID]character.HeroFumoTarget
}

func (r rosterProjection) HeroEquipmentRevision(context.Context, string) (bool, error) {
	return r.equipmentOK, nil
}
func (r rosterProjection) HeroFumoRevision(context.Context, string) (bool, error) {
	return r.fumoOK, nil
}
func (r rosterProjection) HeroEquipmentPosition(_ context.Context, _ string, heroTableID, color, slot int64) (character.HeroEquipmentPosition, error) {
	if p, ok := r.positions[slot]; ok {
		return p, nil
	}
	return character.HeroEquipmentPosition{HeroTableID: heroTableID, Color: color, Slot: slot}, nil
}
func (r rosterProjection) HeroFumoTarget(_ context.Context, _ string, itemID character.EquipmentTemplateID) (character.HeroFumoTarget, error) {
	if v, ok := r.targets[itemID]; ok {
		return v, nil
	}
	return character.HeroFumoTarget{}, errors.New("missing target")
}

type fence struct{ n int }

func (f *fence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	f.n++
	return nil
}

type store struct {
	root      character.HeroRoot
	heroes    []character.Hero
	saves     int
	rootLocks int
}

func (s *store) ReadRoot(context.Context, identity.PlayerID) (character.HeroRoot, error) {
	return s.root, nil
}
func (s *store) ListHeroes(context.Context, identity.PlayerID) ([]character.Hero, error) {
	return append([]character.Hero(nil), s.heroes...), nil
}
func (s *store) LockRootTx(context.Context, tx.Tx, identity.PlayerID) (character.HeroRoot, error) {
	s.rootLocks++
	return s.root, nil
}
func (s *store) SaveSortTypeTx(_ context.Context, _ tx.Tx, r character.HeroRoot, _ int64) error {
	s.root = r
	s.saves++
	return nil
}

type receipts struct {
	m map[receipt.Identity]receipt.Receipt
}

func (r *receipts) PutTx(_ context.Context, _ tx.Tx, x receipt.Receipt) (receipt.PutResult, error) {
	if r.m == nil {
		r.m = map[receipt.Identity]receipt.Receipt{}
	}
	if p, ok := r.m[x.Identity]; ok {
		return receipt.PutResult{Receipt: p, Inserted: false}, nil
	}
	r.m[x.Identity] = x
	return receipt.PutResult{Receipt: x, Inserted: true}, nil
}
func (r *receipts) FindTx(_ context.Context, _ tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	x, ok := r.m[id]
	return x, ok, nil
}
func (r *receipts) Find(_ context.Context, id receipt.Identity) (receipt.Receipt, bool, error) {
	x, ok := r.m[id]
	return x, ok, nil
}
func testActor(t *testing.T) identity.ActorContext {
	u, _ := ids.ParseUUID("11111111-1111-4111-8111-111111111111")
	a, _ := identity.AccountIDFrom(u)
	s, _ := identity.SessionIDFrom(u)
	c, _ := identity.ContextIDFrom(u)
	return identity.ActorContext{AccountID: a, AccountUID: "u", SessionID: s, ContextID: c, LogicalServerID: 1, PlayerID: 7, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func testOp(t *testing.T, raw string) operation.Context {
	u, err := ids.ParseUUID(raw)
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: u, StartedAt: time.Unix(100, 0).UTC()}
}
func TestRosterRequiresHeroCapability(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	st := &store{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 1, StateVersion: 1, CreatedAt: now, UpdatedAt: now}}
	s := Service{Runner: tx.Runner{DB: fakeDB{}}, Store: st, Fencer: &fence{}, Content: gate(false), Receipts: &receipts{}, ReceiptRead: &receipts{}}
	if _, _, err := s.Roster(context.Background(), testActor(t)); !errors.Is(err, ErrHeroContentInactive) {
		t.Fatal(err)
	}
}

func TestRosterRehydratesKindFromCreationRevisionAfterReload(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	rev := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	st := &store{
		root:   character.HeroRoot{PlayerID: 7, NextPartnerID: 43, StateVersion: 2, CreatedAt: now, UpdatedAt: now},
		heroes: []character.Hero{{PlayerID: 7, PartnerID: 42, TableID: 10001062, OriginTableID: 10001062, Star: 5, Level: 17, Exp: 1234, Color: 1, CreationContentRevision: rev, StateVersion: 4, CreatedAt: now, UpdatedAt: now}},
	}
	s := Service{Runner: tx.Runner{DB: fakeDB{}}, Store: st, Fencer: &fence{}, Content: gate(true), Receipts: &receipts{}, ReceiptRead: &receipts{}}
	root, heroes, err := s.Roster(context.Background(), testActor(t))
	if err != nil {
		t.Fatal(err)
	}
	if root.NextPartnerID != 43 || len(heroes) != 1 {
		t.Fatalf("root=%+v heroes=%+v", root, heroes)
	}
	h := heroes[0]
	if h.Kind != character.NormalHero || h.PartnerID != 42 || h.Star != 5 || h.Level != 17 || h.Exp != 1234 || h.CreationContentRevision != rev {
		t.Fatalf("rehydrated Hero=%+v", h)
	}
}

func TestRosterViewPinsActiveRevisionAndDerivesSixNormalHeroFumoLevels(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	rev := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	h := character.Hero{PlayerID: 7, PartnerID: 42, TableID: 10001062, OriginTableID: 10001062, Star: 5, Level: 17, Exp: 1234, Color: 3, Equipment: character.HeroEquipmentSlots{1, 0, 0, 0, 0, 0}, Fumo: character.HeroFumoSlots{60, 0, 0, 0, 0, 0}, CreationContentRevision: rev, StateVersion: 4, CreatedAt: now, UpdatedAt: now}
	st := &store{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 43, StateVersion: 2, CreatedAt: now, UpdatedAt: now}, heroes: []character.Hero{h}}
	itemID := character.EquipmentTemplateID(20001001)
	rp := rosterProjection{equipmentOK: true, fumoOK: true, positions: map[int64]character.HeroEquipmentPosition{1: {HeroTableID: h.TableID, Color: h.Color, Slot: 1, ItemID: itemID, OrdinaryEligible: true}}, targets: map[character.EquipmentTemplateID]character.HeroFumoTarget{itemID: {ItemID: itemID, ThresholdIncrements: []int64{20, 40, 40}, TotalCap: 100, ManaPerFumo: 1, StageDeltaByAttr: []map[int64]string{{1: "1"}, {1: "1"}, {1: "1"}}}}}
	svc := Service{Runner: tx.Runner{DB: fakeDB{}}, Store: st, Fencer: &fence{}, Content: gate(true), Receipts: &receipts{}, ReceiptRead: &receipts{}, RosterProjection: rp}
	root, views, err := svc.RosterView(context.Background(), testActor(t))
	if err != nil {
		t.Fatal(err)
	}
	if root.NextPartnerID != 43 || len(views) != 1 {
		t.Fatalf("root=%+v views=%+v", root, views)
	}
	if views[0].Hero.Kind != character.NormalHero {
		t.Fatalf("kind=%q", views[0].Hero.Kind)
	}
	if got := views[0].FumoLevels; got != (character.HeroFumoSlots{2, 0, 0, 0, 0, 0}) {
		t.Fatalf("levels=%v", got)
	}
}

func TestRosterViewFailsClosedWhenDerivedCapabilitiesInactive(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	st := &store{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 1, StateVersion: 1, CreatedAt: now, UpdatedAt: now}}
	svc := Service{Runner: tx.Runner{DB: fakeDB{}}, Store: st, Fencer: &fence{}, Content: gate(true), Receipts: &receipts{}, ReceiptRead: &receipts{}, RosterProjection: rosterProjection{equipmentOK: false, fumoOK: true}}
	if _, _, err := svc.RosterView(context.Background(), testActor(t)); !errors.Is(err, ErrHeroEquipmentContentInactive) {
		t.Fatalf("err=%v", err)
	}
}

func TestSaveSortReceiptIsOperationScoped(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	st := &store{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 1, StateVersion: 1, CreatedAt: now, UpdatedAt: now}}
	f := &fence{}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	s := Service{Runner: tx.Runner{DB: fakeDB{}}, Store: st, Fencer: f, Content: gate(true), Receipts: rr, ReceiptRead: rr}
	actor := testActor(t)
	op1 := testOp(t, "22222222-2222-4222-8222-222222222222")
	if err := s.SaveSortType(context.Background(), actor, 5, op1); err != nil {
		t.Fatal(err)
	}
	if err := s.SaveSortType(context.Background(), actor, 5, op1); err != nil {
		t.Fatal(err)
	}
	if st.saves != 1 {
		t.Fatalf("same operation reapplied mutation: %d", st.saves)
	}
	op2 := testOp(t, "33333333-3333-4333-8333-333333333333")
	if err := s.SaveSortType(context.Background(), actor, 6, op2); err != nil {
		t.Fatal(err)
	}
	if st.saves != 2 {
		t.Fatalf("new operation was treated as replay: %d", st.saves)
	}
	if len(rr.m) != 2 {
		t.Fatalf("receipts=%d", len(rr.m))
	}
}
