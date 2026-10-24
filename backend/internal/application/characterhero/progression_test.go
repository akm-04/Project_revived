package characterhero

import (
	"context"
	"errors"
	"strconv"
	"testing"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const progRev = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

type progStore struct {
	heroes      map[int64]character.Hero
	saves       int
	lockCalls   int
	lockedIDs   []int64
	lockErrOnce error
	onLockErr   func()
}

func (s *progStore) ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error) {
	out := make([]character.Hero, 0, len(s.heroes))
	for _, h := range s.heroes {
		out = append(out, h)
	}
	return out, nil
}
func (s *progStore) LockHeroByPartnerIDTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, id int64) (character.Hero, error) {
	s.lockCalls++
	s.lockedIDs = append(s.lockedIDs, id)
	if s.lockErrOnce != nil {
		err := s.lockErrOnce
		s.lockErrOnce = nil
		if s.onLockErr != nil {
			s.onLockErr()
		}
		return character.Hero{}, err
	}
	h, ok := s.heroes[id]
	if !ok {
		return character.Hero{}, ErrHeroNotFound
	}
	return h, nil
}
func (s *progStore) SaveHeroProgressionTx(_ context.Context, _ tx.Tx, h character.Hero, old int64) error {
	cur, ok := s.heroes[h.PartnerID]
	if !ok || cur.StateVersion != old {
		return errors.New("lost race")
	}
	s.heroes[h.PartnerID] = h
	s.saves++
	return nil
}
func (s *progStore) SaveHeroStateTx(ctx context.Context, t tx.Tx, h character.Hero, old int64) error {
	return s.SaveHeroProgressionTx(ctx, t, h, old)
}

type progContent struct {
	exp           map[int64]int64
	template      map[int64]character.HeroTemplateProgression
	normal        map[int64]character.HeroEvolutionPolicy
	super         map[int64]character.HeroEvolutionPolicy
	prereq        map[int64][]int64
	pieces        []character.HeroPieceMapping
	active        *string
	activeCalls   *int
	seenRevisions *[]string
}

func (c progContent) HeroProgressionActive(context.Context) (string, bool, error) {
	if c.activeCalls != nil {
		*c.activeCalls = *c.activeCalls + 1
	}
	if c.active != nil {
		return *c.active, true, nil
	}
	return progRev, true, nil
}
func (progContent) HeroProgressionRevision(context.Context, string) (bool, error) { return true, nil }
func (c progContent) HeroExpItemTx(_ context.Context, _ tx.Queryer, revision string, id int64) (int64, error) {
	if c.seenRevisions != nil {
		*c.seenRevisions = append(*c.seenRevisions, revision)
	}
	v, ok := c.exp[id]
	if !ok {
		return 0, errors.New("no exp item")
	}
	return v, nil
}
func (progContent) HeroMaxLevelTx(context.Context, tx.Queryer, string, int64) (int64, error) {
	return 3, nil
}
func (progContent) HeroExpPolicyTx(context.Context, tx.Queryer, string, int64) ([]character.HeroExpThreshold, error) {
	return []character.HeroExpThreshold{{Level: 1, TotalExp: 25}, {Level: 2, TotalExp: 55}, {Level: 3, TotalExp: 95}}, nil
}
func (c progContent) HeroTemplateProgressionTx(_ context.Context, _ tx.Queryer, _ string, id int64) (character.HeroTemplateProgression, error) {
	v, ok := c.template[id]
	if !ok {
		return character.HeroTemplateProgression{}, errors.New("no template")
	}
	return v, nil
}
func (c progContent) HeroNormalEvolutionTx(_ context.Context, _ tx.Queryer, _ string, star int64) (character.HeroEvolutionPolicy, error) {
	v, ok := c.normal[star]
	if !ok {
		return character.HeroEvolutionPolicy{}, errors.New("no normal evolution")
	}
	return v, nil
}
func (c progContent) HeroSuperEvolutionTx(_ context.Context, _ tx.Queryer, _ string, star int64) (character.HeroEvolutionPolicy, error) {
	v, ok := c.super[star]
	if !ok {
		return character.HeroEvolutionPolicy{}, errors.New("no super evolution")
	}
	return v, nil
}
func (c progContent) HeroSuperPrerequisitesTx(_ context.Context, _ tx.Queryer, _ string, id int64) ([]int64, error) {
	return append([]int64(nil), c.prereq[id]...), nil
}
func (c progContent) HeroPieceMappings(context.Context, string) ([]character.HeroPieceMapping, error) {
	return append([]character.HeroPieceMapping(nil), c.pieces...), nil
}

type progEconomy struct {
	playerLevel                   int64
	remaining                     map[int64]int64
	expCalls                      int
	evolveCalls                   int
	mana, fragmentItem, fragments int64
	expErr, evolveErr             error
}

func (e *progEconomy) DebitHeroExpItemsTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, items []appi5.HeroExpItemDebit, _ operation.Context) (appi5.HeroExpDebitResult, error) {
	e.expCalls++
	if e.expErr != nil {
		return appi5.HeroExpDebitResult{}, e.expErr
	}
	out := appi5.HeroExpDebitResult{PlayerLevel: e.playerLevel}
	for _, x := range items {
		q := e.remaining[x.ItemID]
		q -= x.Count
		if q < 0 {
			return out, economy.ErrInsufficientBalance
		}
		e.remaining[x.ItemID] = q
		out.Stacks = append(out.Stacks, economy.StackState{PlayerID: 7, ItemID: x.ItemID, Quantity: q, StateVersion: 2, AcquiredAt: time.Unix(1, 0).UTC(), UpdatedAt: time.Unix(2, 0).UTC()})
	}
	return out, nil
}
func (e *progEconomy) DebitHeroEvolutionTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, mana, item, frags int64, _ operation.Context) (appi5.MaterialDebitResult, error) {
	e.evolveCalls++
	e.mana, e.fragmentItem, e.fragments = mana, item, frags
	if e.evolveErr != nil {
		return appi5.MaterialDebitResult{}, e.evolveErr
	}
	return appi5.MaterialDebitResult{}, nil
}

type emptyBackpack struct{}

func (emptyBackpack) ListStacks(context.Context, identity.PlayerID) ([]economy.StackState, error) {
	return nil, nil
}

type progBackpack struct{ stacks []economy.StackState }

func (b progBackpack) ListStacks(context.Context, identity.PlayerID) ([]economy.StackState, error) {
	return append([]economy.StackState(nil), b.stacks...), nil
}

type commitErrorTx struct {
	fakeTx
	commitErr error
}

func (t *commitErrorTx) Commit(context.Context) error { return t.commitErr }

type commitErrorDB struct {
	begins int
	err    error
}

func (d *commitErrorDB) Begin(context.Context, tx.Options) (tx.Tx, error) {
	d.begins++
	return &commitErrorTx{commitErr: d.err}, nil
}

type missingProgressionReceiptReader struct{}

func (missingProgressionReceiptReader) Find(context.Context, receipt.Identity) (receipt.Receipt, bool, error) {
	return receipt.Receipt{}, false, nil
}

func heroAt(id, table, origin, star, level, exp int64, now time.Time) character.Hero {
	return character.Hero{RawSkills: character.NewHeroRawSkillSeed(), PlayerID: 7, PartnerID: id, TableID: table, OriginTableID: origin, Star: star, Level: level, Exp: exp, Color: 1, CreationContentRevision: progRev, StateVersion: 1, CreatedAt: now, UpdatedAt: now}
}
func progressionService(ps *progStore, pc progContent, pe *progEconomy, rr *receipts) Service {
	now := time.Unix(1, 0).UTC()
	core := &store{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 100, StateVersion: 1, CreatedAt: now, UpdatedAt: now}}
	return Service{Runner: tx.Runner{DB: fakeDB{}}, Store: core, Fencer: &fence{}, Content: gate(true), Receipts: rr, ReceiptRead: rr, ProgressionStore: ps, Progression: pc, Economy: pe, Backpack: emptyBackpack{}}
}

func TestUseExpItemAppliesSourceCumulativeLevelAndReceiptReplay(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	ps := &progStore{heroes: map[int64]character.Hero{11: heroAt(11, 1001, 1001, 3, 1, 0, now)}}
	pc := progContent{exp: map[int64]int64{50001001: 60}}
	pe := &progEconomy{playerLevel: 20, remaining: map[int64]int64{50001001: 3}}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	s := progressionService(ps, pc, pe, rr)
	op := testOp(t, "44444444-4444-4444-8444-444444444444")
	got, err := s.UseExpItem(context.Background(), testActor(t), 11, 50001001, 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.Exp != 60 || got.Level != 3 || got.Remaining[50001001] != 2 {
		t.Fatalf("got=%+v", got)
	}
	if ps.saves != 1 || pe.expCalls != 1 {
		t.Fatalf("saves=%d debits=%d", ps.saves, pe.expCalls)
	}
	if _, err := s.UseExpItem(context.Background(), testActor(t), 11, 50001001, 1, op); err != nil {
		t.Fatal(err)
	}
	if ps.saves != 1 || pe.expCalls != 1 {
		t.Fatalf("receipt replay reapplied mutation saves=%d debits=%d", ps.saves, pe.expCalls)
	}
}

func TestSuperLowStarEvolutionUsesLockedFiveStarPrerequisitesWithoutDebit(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	heroes := map[int64]character.Hero{11: heroAt(11, 9001, 9001, 1, 1, 0, now), 21: heroAt(21, 101, 101, 5, 1, 0, now), 22: heroAt(22, 102, 102, 5, 1, 0, now)}
	ps := &progStore{heroes: heroes}
	pc := progContent{template: map[int64]character.HeroTemplateProgression{9001: {Kind: character.SuperHero, OriginTableID: 9001, FragmentItemID: 5009001}}, super: map[int64]character.HeroEvolutionPolicy{2: {NeedHeroNum: 2, Effective: true}}, prereq: map[int64][]int64{9001: {101, 102, 103, 104, 105}}}
	pe := &progEconomy{playerLevel: 20, remaining: map[int64]int64{}}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	s := progressionService(ps, pc, pe, rr)
	if err := s.Evolve(context.Background(), testActor(t), 11, testOp(t, "55555555-5555-4555-8555-555555555555")); err != nil {
		t.Fatal(err)
	}
	if ps.heroes[11].Star != 2 {
		t.Fatalf("star=%d", ps.heroes[11].Star)
	}
	if pe.evolveCalls != 1 || pe.mana != 0 || pe.fragments != 0 {
		t.Fatalf("unexpected debit calls=%d mana=%d fragments=%d", pe.evolveCalls, pe.mana, pe.fragments)
	}
}

func TestSuperSixStarTransitionUsesManaAndNoPrerequisiteConsumption(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	ps := &progStore{heroes: map[int64]character.Hero{11: heroAt(11, 9001, 9001, 5, 1, 0, now)}}
	pc := progContent{template: map[int64]character.HeroTemplateProgression{9001: {Kind: character.SuperHero, OriginTableID: 9001, FragmentItemID: 5009001}}, super: map[int64]character.HeroEvolutionPolicy{6: {Mana: 80000000, NeedHeroNum: 5, Effective: true}}}
	pe := &progEconomy{playerLevel: 20, remaining: map[int64]int64{}}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	s := progressionService(ps, pc, pe, rr)
	if err := s.Evolve(context.Background(), testActor(t), 11, testOp(t, "66666666-6666-4666-8666-666666666666")); err != nil {
		t.Fatal(err)
	}
	if ps.heroes[11].Star != 6 || pe.mana != 80000000 || pe.fragments != 0 {
		t.Fatalf("star=%d mana=%d fragments=%d", ps.heroes[11].Star, pe.mana, pe.fragments)
	}
}

func TestUseExpItemPinsContentAcrossDefiniteAbortRetryAndActivationChange(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	active := progRev
	activeCalls := 0
	seen := []string{}
	ps := &progStore{heroes: map[int64]character.Hero{11: heroAt(11, 1001, 1001, 3, 1, 0, now)}, lockErrOnce: tx.MarkDefiniteAbort(errors.New("retry witness"))}
	ps.onLockErr = func() { active = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" }
	pc := progContent{exp: map[int64]int64{50001001: 60}, active: &active, activeCalls: &activeCalls, seenRevisions: &seen}
	pe := &progEconomy{playerLevel: 20, remaining: map[int64]int64{50001001: 3}}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	s := progressionService(ps, pc, pe, rr)
	if _, err := s.UseExpItem(context.Background(), testActor(t), 11, 50001001, 1, testOp(t, "77777777-7777-4777-8777-777777777777")); err != nil {
		t.Fatal(err)
	}
	if activeCalls != 1 {
		t.Fatalf("active content was rebound across retry: calls=%d", activeCalls)
	}
	if len(seen) != 2 || seen[0] != progRev || seen[1] != progRev {
		t.Fatalf("retry escaped bound content revision: %v", seen)
	}
	if ps.lockCalls != 2 || pe.expCalls != 1 || ps.saves != 1 {
		t.Fatalf("unexpected retry effects locks=%d debits=%d saves=%d", ps.lockCalls, pe.expCalls, ps.saves)
	}
}

func TestUseExpItemUnknownCommitReceiptReconcilesWithoutReapply(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	ps := &progStore{heroes: map[int64]character.Hero{11: heroAt(11, 1001, 1001, 3, 1, 0, now)}}
	pc := progContent{exp: map[int64]int64{50001001: 60}}
	pe := &progEconomy{playerLevel: 20, remaining: map[int64]int64{50001001: 3}}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	s := progressionService(ps, pc, pe, rr)
	db := &commitErrorDB{err: errors.New("commit acknowledgement lost")}
	s.Runner = tx.Runner{DB: db}
	got, err := s.UseExpItem(context.Background(), testActor(t), 11, 50001001, 1, testOp(t, "88888888-8888-4888-8888-888888888888"))
	if err != nil {
		t.Fatal(err)
	}
	if got.Exp != 60 || db.begins != 1 || pe.expCalls != 1 || ps.saves != 1 {
		t.Fatalf("unknown-commit reconciliation drift got=%+v begins=%d debits=%d saves=%d", got, db.begins, pe.expCalls, ps.saves)
	}
}

func TestUseExpItemUnknownCommitWithoutReceiptDoesNotBlindRetry(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	ps := &progStore{heroes: map[int64]character.Hero{11: heroAt(11, 1001, 1001, 3, 1, 0, now)}}
	pc := progContent{exp: map[int64]int64{50001001: 60}}
	pe := &progEconomy{playerLevel: 20, remaining: map[int64]int64{50001001: 3}}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	s := progressionService(ps, pc, pe, rr)
	db := &commitErrorDB{err: errors.New("commit acknowledgement lost")}
	s.Runner = tx.Runner{DB: db}
	s.ReceiptRead = missingProgressionReceiptReader{}
	_, err := s.UseExpItem(context.Background(), testActor(t), 11, 50001001, 1, testOp(t, "99999999-9999-4999-8999-999999999999"))
	var unknown *tx.UnknownCommitError
	if !errors.As(err, &unknown) {
		t.Fatalf("expected UNKNOWN COMMIT, got %v", err)
	}
	if db.begins != 1 || pe.expCalls != 1 || ps.saves != 1 {
		t.Fatalf("ambiguous commit was replayed begins=%d debits=%d saves=%d", db.begins, pe.expCalls, ps.saves)
	}
}

func TestNormalEvolutionUsesTargetStarCosts(t *testing.T) {
	cases := []struct {
		star, mana, fragments int64
	}{
		{1, 35000, 20},
		{2, 120000, 50},
		{3, 300000, 100},
		{4, 800000, 150},
	}
	for _, tc := range cases {
		t.Run(strconv.FormatInt(tc.star, 10), func(t *testing.T) {
			now := time.Unix(1, 0).UTC()
			ps := &progStore{heroes: map[int64]character.Hero{11: heroAt(11, 1001, 1001, tc.star, 1, 0, now)}}
			pc := progContent{template: map[int64]character.HeroTemplateProgression{1001: {Kind: character.NormalHero, OriginTableID: 1001, FragmentItemID: 40001001}}, normal: map[int64]character.HeroEvolutionPolicy{tc.star + 1: {Mana: tc.mana, FragmentCount: tc.fragments, Effective: true}}}
			pe := &progEconomy{playerLevel: 20, remaining: map[int64]int64{}}
			rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
			s := progressionService(ps, pc, pe, rr)
			if err := s.Evolve(context.Background(), testActor(t), 11, testOp(t, "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")); err != nil {
				t.Fatal(err)
			}
			if got := ps.heroes[11].Star; got != tc.star+1 || pe.mana != tc.mana || pe.fragments != tc.fragments || pe.fragmentItem != 40001001 {
				t.Fatalf("star=%d mana=%d fragments=%d item=%d", got, pe.mana, pe.fragments, pe.fragmentItem)
			}
		})
	}
}

func TestSuperHighStarEvolutionUsesManaAndFragmentCosts(t *testing.T) {
	cases := []struct {
		star, mana, fragments int64
	}{
		{5, 80000000, 0},
		{6, 90000000, 300},
		{7, 100000000, 800},
	}
	for _, tc := range cases {
		t.Run(strconv.FormatInt(tc.star, 10), func(t *testing.T) {
			now := time.Unix(1, 0).UTC()
			ps := &progStore{heroes: map[int64]character.Hero{11: heroAt(11, 9001, 9001, tc.star, 1, 0, now)}}
			pc := progContent{template: map[int64]character.HeroTemplateProgression{9001: {Kind: character.SuperHero, OriginTableID: 9001, FragmentItemID: 5009001}}, super: map[int64]character.HeroEvolutionPolicy{tc.star + 1: {Mana: tc.mana, FragmentCount: tc.fragments, NeedHeroNum: 5, Effective: true}}}
			pe := &progEconomy{playerLevel: 20, remaining: map[int64]int64{}}
			rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
			s := progressionService(ps, pc, pe, rr)
			if err := s.Evolve(context.Background(), testActor(t), 11, testOp(t, "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")); err != nil {
				t.Fatal(err)
			}
			wantItem := int64(0)
			if tc.fragments > 0 {
				wantItem = 5009001
			}
			if got := ps.heroes[11].Star; got != tc.star+1 || pe.mana != tc.mana || pe.fragments != tc.fragments || pe.fragmentItem != wantItem {
				t.Fatalf("star=%d mana=%d fragments=%d item=%d", got, pe.mana, pe.fragments, pe.fragmentItem)
			}
		})
	}
}

func TestSuperPrerequisiteFailureAndDebitFailureDoNotAdvanceHero(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	ps := &progStore{heroes: map[int64]character.Hero{11: heroAt(11, 9001, 9001, 1, 1, 0, now), 21: heroAt(21, 101, 101, 5, 1, 0, now)}}
	pc := progContent{template: map[int64]character.HeroTemplateProgression{9001: {Kind: character.SuperHero, OriginTableID: 9001, FragmentItemID: 5009001}}, super: map[int64]character.HeroEvolutionPolicy{2: {NeedHeroNum: 2, Effective: true}}, prereq: map[int64][]int64{9001: {101, 102, 103, 104, 105}}}
	pe := &progEconomy{playerLevel: 20, remaining: map[int64]int64{}}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	s := progressionService(ps, pc, pe, rr)
	if err := s.Evolve(context.Background(), testActor(t), 11, testOp(t, "cccccccc-cccc-4ccc-8ccc-cccccccccccc")); !errors.Is(err, ErrHeroPrerequisites) {
		t.Fatalf("expected prerequisite rejection, got %v", err)
	}
	if ps.heroes[11].Star != 1 || ps.saves != 0 || pe.evolveCalls != 0 {
		t.Fatalf("prerequisite failure partially mutated star=%d saves=%d debits=%d", ps.heroes[11].Star, ps.saves, pe.evolveCalls)
	}

	ps2 := &progStore{heroes: map[int64]character.Hero{11: heroAt(11, 1001, 1001, 1, 1, 0, now)}}
	pc2 := progContent{template: map[int64]character.HeroTemplateProgression{1001: {Kind: character.NormalHero, OriginTableID: 1001, FragmentItemID: 40001001}}, normal: map[int64]character.HeroEvolutionPolicy{2: {Mana: 35000, FragmentCount: 20, Effective: true}}}
	pe2 := &progEconomy{playerLevel: 20, remaining: map[int64]int64{}, evolveErr: economy.ErrInsufficientBalance}
	rr2 := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	s2 := progressionService(ps2, pc2, pe2, rr2)
	if err := s2.Evolve(context.Background(), testActor(t), 11, testOp(t, "dddddddd-dddd-4ddd-8ddd-dddddddddddd")); !errors.Is(err, economy.ErrInsufficientBalance) {
		t.Fatalf("expected debit failure, got %v", err)
	}
	if ps2.heroes[11].Star != 1 || ps2.saves != 0 || pe2.evolveCalls != 1 {
		t.Fatalf("debit failure partially mutated star=%d saves=%d debits=%d", ps2.heroes[11].Star, ps2.saves, pe2.evolveCalls)
	}
}

func TestHeroPiecesProjectsCanonicalI5Stacks(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	ps := &progStore{heroes: map[int64]character.Hero{}}
	pc := progContent{pieces: []character.HeroPieceMapping{{ItemID: 40001001, OriginTableID: 10001001}, {ItemID: 40001002, OriginTableID: 10001002}}}
	pe := &progEconomy{playerLevel: 20, remaining: map[int64]int64{}}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	s := progressionService(ps, pc, pe, rr)
	s.Backpack = progBackpack{stacks: []economy.StackState{
		{PlayerID: 7, ItemID: 40001001, Quantity: 9, StateVersion: 1, AcquiredAt: now, UpdatedAt: now},
		{PlayerID: 7, ItemID: 40001002, Quantity: 0, StateVersion: 1, AcquiredAt: now, UpdatedAt: now},
		{PlayerID: 7, ItemID: 12345, Quantity: 99, StateVersion: 1, AcquiredAt: now, UpdatedAt: now},
	}}
	got, err := s.HeroPieces(context.Background(), testActor(t))
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 1 || got[10001001] != 9 {
		t.Fatalf("MID67 projection=%v", got)
	}
}

func TestCanonicalPartnerSortUsesNumericInt64Order(t *testing.T) {
	ids := []int64{10, 2, 1, 20}
	canonicalPartnerSort(ids)
	want := []int64{1, 2, 10, 20}
	for i := range want {
		if ids[i] != want[i] {
			t.Fatalf("ids=%v want=%v", ids, want)
		}
	}
}

func TestSuperLowStarEvolutionStabilizesRootBeforeNumericHeroLocks(t *testing.T) {
	now := time.Unix(1, 0).UTC()
	ps := &progStore{heroes: map[int64]character.Hero{10: heroAt(10, 9001, 9001, 1, 1, 0, now), 2: heroAt(2, 101, 101, 5, 1, 0, now)}}
	pc := progContent{template: map[int64]character.HeroTemplateProgression{9001: {Kind: character.SuperHero, OriginTableID: 9001, FragmentItemID: 5009001, InitialStar: 1}}, super: map[int64]character.HeroEvolutionPolicy{2: {NeedHeroNum: 1, Effective: true}}, prereq: map[int64][]int64{9001: {101, 102, 103, 104, 105}}}
	pe := &progEconomy{playerLevel: 20, remaining: map[int64]int64{}}
	rr := &receipts{m: map[receipt.Identity]receipt.Receipt{}}
	core := &store{root: character.HeroRoot{PlayerID: 7, NextPartnerID: 100, StateVersion: 1, CreatedAt: now, UpdatedAt: now}}
	svc := Service{Runner: tx.Runner{DB: fakeDB{}}, Store: core, Fencer: &fence{}, Content: gate(true), Receipts: rr, ReceiptRead: rr, ProgressionStore: ps, Progression: pc, Economy: pe, Backpack: emptyBackpack{}}
	if err := svc.Evolve(context.Background(), testActor(t), 10, testOp(t, "77777777-7777-4777-8777-777777777777")); err != nil {
		t.Fatal(err)
	}
	if core.rootLocks != 1 {
		t.Fatalf("root locks=%d want=1", core.rootLocks)
	}
	if len(ps.lockedIDs) < 2 || ps.lockedIDs[0] != 2 || ps.lockedIDs[1] != 10 {
		t.Fatalf("HeroInstance lock order=%v want prefix [2 10]", ps.lockedIDs)
	}
}
