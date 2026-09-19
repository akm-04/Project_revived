package characterpet

import (
	"context"
	"errors"
	"fmt"
	"reflect"
	"testing"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type caProgression struct {
	rev       string
	active    bool
	tmpl      ProgressionTemplate
	slots     []SkillSlotDefinition
	expItems  map[int64]int64
	threshold []ExpThreshold
	maxLevel  int64
	policies  map[int64]SkillSlotPolicy
	evolution map[int64]int64
	policy    ProgressionPolicy
	activeN   int
	onExpItem func()
}

func (c *caProgression) PetProgressionActive(context.Context) (string, bool, error) {
	c.activeN++
	return c.rev, c.active, nil
}
func (c *caProgression) PetProgressionRevision(context.Context, string) (bool, error) {
	return true, nil
}
func (c *caProgression) PetProgressionTemplateTx(context.Context, tx.Queryer, string, int64) (ProgressionTemplate, error) {
	return c.tmpl, nil
}
func (c *caProgression) PetSkillSlotsTx(context.Context, tx.Queryer, string, int64) ([]SkillSlotDefinition, error) {
	return append([]SkillSlotDefinition(nil), c.slots...), nil
}
func (c *caProgression) PetExpItemTx(_ context.Context, _ tx.Queryer, _ string, item int64) (int64, error) {
	if c.onExpItem != nil {
		c.onExpItem()
	}
	v, ok := c.expItems[item]
	if !ok {
		return 0, errors.New("missing exp item")
	}
	return v, nil
}
func (c *caProgression) PetExpPolicyTx(context.Context, tx.Queryer, string, int64) ([]ExpThreshold, error) {
	return append([]ExpThreshold(nil), c.threshold...), nil
}
func (c *caProgression) PetSkillBookCostTx(_ context.Context, _ tx.Queryer, _ string, level int64) (int64, error) {
	if level < 1 || level > 130 {
		return 0, errors.New("missing skill book row")
	}
	return (level + 9) / 10, nil
}
func (c *caProgression) PetSkillSlotPolicyTx(_ context.Context, _ tx.Queryer, _ string, slot int64) (SkillSlotPolicy, error) {
	v, ok := c.policies[slot]
	if !ok {
		return SkillSlotPolicy{}, errors.New("missing slot policy")
	}
	return v, nil
}
func (c *caProgression) PetEvolutionCostTx(_ context.Context, _ tx.Queryer, _ string, target int64) (int64, error) {
	v, ok := c.evolution[target]
	if !ok {
		return 0, errors.New("missing evolution")
	}
	return v, nil
}
func (c *caProgression) PetProgressionPolicyTx(context.Context, tx.Queryer, string) (ProgressionPolicy, error) {
	return c.policy, nil
}
func (c *caProgression) CharacterMaxLevelTx(context.Context, tx.Queryer, string, int64) (int64, error) {
	return c.maxLevel, nil
}

type caPetExp struct {
	prepare int
	apply   int
}

func (p *caPetExp) PreparePetExpDebitTx(context.Context, tx.Tx, identity.PlayerID, []appi5.PetExpItemDebit, operation.Context) (appi5.PetExpDebitPlan, error) {
	p.prepare++
	return appi5.PetExpDebitPlan{}, nil
}
func (p *caPetExp) ApplyPetExpDebitTx(context.Context, tx.Tx, appi5.PetExpDebitPlan) (appi5.PetExpDebitResult, error) {
	p.apply++
	return appi5.PetExpDebitResult{}, nil
}

func progressionFixture(t *testing.T) (Service, *caStore, *caProgression, *caMaterial, *caPetExp) {
	now := time.Unix(1000, 0).UTC()
	pet := character.Pet{
		PlayerID:                7,
		PetID:                   1,
		TableID:                 10030001,
		OriginTableID:           10030001,
		Star:                    1,
		Level:                   1,
		Exp:                     0,
		Color:                   1,
		Birthday:                100,
		IsShow:                  true,
		Skills:                  character.DefaultPetSkillLevels(),
		CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		StateVersion:            1,
		CreatedAt:               now,
		UpdatedAt:               now,
	}
	st := &caStore{root: character.PetRoot{PlayerID: 7, NextPetID: 2, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, byID: map[int64]character.Pet{1: pet}}
	rec := newCAReceipts()
	prog := &caProgression{
		rev:       "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		active:    true,
		tmpl:      ProgressionTemplate{TableID: 10030001, StoneItemID: 50002001},
		expItems:  map[int64]int64{50001087: 300, 50001088: 1500, 50001089: 7500},
		threshold: []ExpThreshold{{Level: 1, TotalExp: 25}, {Level: 2, TotalExp: 55}},
		maxLevel:  2,
		policies: map[int64]SkillSlotPolicy{
			1: {EffectiveOffset: 0, MinColor: 1},
			2: {EffectiveOffset: 0, MinColor: 2},
			3: {EffectiveOffset: 20, MinColor: 4},
			4: {EffectiveOffset: 40, MinColor: 7},
			5: {EffectiveOffset: 60, RequiresAwakened: true},
		},
		evolution: map[int64]int64{2: 20, 3: 50, 4: 100, 5: 150},
		policy:    ProgressionPolicy{SkillBookItemID: 50001090},
	}
	prog.slots = []SkillSlotDefinition{
		{Slot: 1, SourceSkillID: 1001, StarBonus: 10},
		{Slot: 2, SourceSkillID: 1002},
		{Slot: 3, SourceSkillID: 1003},
		{Slot: 4, SourceSkillID: 1004},
		{Slot: 5, SourceSkillID: 0},
	}
	mat := &caMaterial{}
	pexp := &caPetExp{}
	svc := Service{Runner: tx.Runner{DB: caDB{}}, Store: st, Fencer: caFence{}, Progression: prog, Receipts: rec, ReceiptRead: rec, MaterialCosts: mat, PetExp: pexp}
	return svc, st, prog, mat, pexp
}

func TestEvolveUsesAuthoritativeStoneAndPreservesOtherProgression(t *testing.T) {
	svc, st, _, mat, _ := progressionFixture(t)
	actor := caActor(t)
	before := st.byID[1]
	got, err := svc.Evolve(context.Background(), actor, 1, caOp(t, "88888888-8888-4888-8888-888888888888", 2000))
	if err != nil {
		t.Fatal(err)
	}
	if got.Star != 2 || mat.calls != 1 || len(mat.last.Stacks) != 1 || mat.last.Stacks[0].ItemID != 50002001 || mat.last.Stacks[0].Amount != 20 {
		t.Fatalf("got=%+v material=%+v", got, mat.last)
	}
	after := st.byID[1]
	if after.Level != before.Level || after.Exp != before.Exp || after.Skills != before.Skills || after.Star != 2 {
		t.Fatalf("before=%+v after=%+v", before, after)
	}
}

func TestManualFeedAllowsLevelAtMaxWhenCumulativeExpBelowCap(t *testing.T) {
	svc, st, _, _, pexp := progressionFixture(t)
	p := st.byID[1]
	p.Level = 2
	p.Exp = 25
	st.byID[1] = p
	got, err := svc.Feed(context.Background(), caActor(t), 1, 50001087, 1, caOp(t, "99999999-9999-4999-8999-999999999999", 2001))
	if err != nil {
		t.Fatal(err)
	}
	if got.Level != 2 || got.Exp != 55 || pexp.prepare != 1 || pexp.apply != 1 {
		t.Fatalf("got=%+v prepare=%d apply=%d", got, pexp.prepare, pexp.apply)
	}
}

func TestOneKeyRejectsAtMaxAfterPrepareBeforeApply(t *testing.T) {
	svc, st, _, _, pexp := progressionFixture(t)
	p := st.byID[1]
	p.Level = 2
	p.Exp = 25
	st.byID[1] = p
	_, err := svc.UseExpItems(context.Background(), caActor(t), 1, []appi5.PetExpItemDebit{{ItemID: 50001089, Count: 1}, {ItemID: 50001087, Count: 1}}, caOp(t, "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaab", 2002))
	if !errors.Is(err, ErrPetExpMax) {
		t.Fatalf("err=%v", err)
	}
	if pexp.prepare != 1 || pexp.apply != 0 || st.byID[1].Exp != 25 {
		t.Fatalf("prepare=%d apply=%d pet=%+v", pexp.prepare, pexp.apply, st.byID[1])
	}
}

func TestUpgradeSkillsUsesEffectiveLevelBookCostsAndStarBonus(t *testing.T) {
	svc, st, _, mat, _ := progressionFixture(t)
	p := st.byID[1]
	p.Level = 20
	p.Star = 2 // slot 1 qualifies for +10 source bonus
	p.Skills[0] = 10
	st.byID[1] = p
	got, err := svc.UpgradeSkills(context.Background(), caActor(t), 1, []SkillUpgrade{{Slot: 1, Count: 2}}, caOp(t, "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb", 2003))
	if err != nil {
		t.Fatal(err)
	}
	if got.Skills[0] != 12 || mat.calls != 1 || len(mat.last.Stacks) != 1 || mat.last.Stacks[0].ItemID != 50001090 || mat.last.Stacks[0].Amount != 3 {
		t.Fatalf("skills=%v material=%+v", got.Skills, mat.last)
	}
}

func TestUpgradeSkillsRejectsZeroSourceAwakenedSlot(t *testing.T) {
	svc, st, _, mat, _ := progressionFixture(t)
	p := st.byID[1]
	p.Level = 100
	p.Star = 5
	p.Color = 12
	p.TableID = 10030002 // awakened relative to origin; source slot 5 remains zero
	st.byID[1] = p
	_, err := svc.UpgradeSkills(context.Background(), caActor(t), 1, []SkillUpgrade{{Slot: 5, Count: 1}}, caOp(t, "cccccccc-cccc-4ccc-8ccc-cccccccccccc", 2004))
	if !errors.Is(err, ErrPetSkillUnavailable) || mat.calls != 0 {
		t.Fatalf("err=%v materialCalls=%d", err, mat.calls)
	}
}

func TestProgressionReceiptReplaysBeforeActiveContentLookup(t *testing.T) {
	svc, _, prog, _, _ := progressionFixture(t)
	op := caOp(t, "dddddddd-dddd-4ddd-8ddd-dddddddddddd", 2005)
	first, err := svc.Evolve(context.Background(), caActor(t), 1, op)
	if err != nil {
		t.Fatal(err)
	}
	calls := prog.activeN
	prog.active = false
	second, err := svc.Evolve(context.Background(), caActor(t), 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(first, second) || prog.activeN != calls {
		t.Fatalf("first=%+v second=%+v active calls %d->%d", first, second, calls, prog.activeN)
	}
}

func TestProgressionMutationsRecheckReceiptAfterPetLock(t *testing.T) {
	tests := []struct {
		name string
		run  func(Service, identity.ActorContext, operation.Context) error
	}{
		{"evolve", func(s Service, a identity.ActorContext, op operation.Context) error {
			_, err := s.Evolve(context.Background(), a, 1, op)
			return err
		}},
		{"feed", func(s Service, a identity.ActorContext, op operation.Context) error {
			_, err := s.Feed(context.Background(), a, 1, 50001087, 1, op)
			return err
		}},
		{"skills", func(s Service, a identity.ActorContext, op operation.Context) error {
			_, err := s.UpgradeSkills(context.Background(), a, 1, []SkillUpgrade{{Slot: 1, Count: 1}}, op)
			return err
		}},
	}
	for i, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			svc, st, _, _, _ := progressionFixture(t)
			if tc.name == "skills" {
				p := st.byID[1]
				p.Level = 20
				st.byID[1] = p
			}
			rec := svc.Receipts.(*caReceipts)
			op := caOp(t, fmt.Sprintf("eeeeeeee-eeee-4eee-8eee-%012d", i+1), 2100+int64(i))
			if err := tc.run(svc, caActor(t), op); err != nil {
				t.Fatal(err)
			}
			if rec.findTxN != 2 {
				t.Fatalf("transactional receipt checks=%d; want exactly pre-lock + post-lock", rec.findTxN)
			}
		})
	}
}

func TestFeedLocksPetBeforeResolvingRationContent(t *testing.T) {
	svc, st, prog, _, _ := progressionFixture(t)
	events := []string{}
	st.onLockPet = func() { events = append(events, "lock-pet") }
	prog.onExpItem = func() { events = append(events, "resolve-exp-item") }
	if _, err := svc.Feed(context.Background(), caActor(t), 1, 50001087, 1, caOp(t, "ffffffff-ffff-4fff-8fff-ffffffffffff", 2110)); err != nil {
		t.Fatal(err)
	}
	if len(events) < 2 || events[0] != "lock-pet" || events[1] != "resolve-exp-item" {
		t.Fatalf("unexpected order: %v", events)
	}
}

func TestEvolveAllSourceQualifiedTransitions(t *testing.T) {
	cases := []struct{ star, wantStar, wantCost int64 }{{1, 2, 20}, {2, 3, 50}, {3, 4, 100}, {4, 5, 150}}
	for i, tc := range cases {
		svc, st, _, mat, _ := progressionFixture(t)
		p := st.byID[1]
		p.Star = tc.star
		st.byID[1] = p
		op := caOp(t, fmt.Sprintf("12121212-1212-4212-8212-%012d", i+1), 2200+int64(i))
		got, err := svc.Evolve(context.Background(), caActor(t), 1, op)
		if err != nil {
			t.Fatal(err)
		}
		if got.Star != tc.wantStar || mat.last.Stacks[0].Amount != tc.wantCost {
			t.Fatalf("star %d got=%+v cost=%+v", tc.star, got, mat.last)
		}
	}
}

func TestEvolveRejectsStarFive(t *testing.T) {
	svc, st, _, mat, _ := progressionFixture(t)
	p := st.byID[1]
	p.Star = 5
	st.byID[1] = p
	_, err := svc.Evolve(context.Background(), caActor(t), 1, caOp(t, "13131313-1313-4313-8313-131313131313", 2210))
	if !errors.Is(err, ErrPetEvolutionUnavailable) || mat.calls != 0 {
		t.Fatalf("err=%v calls=%d", err, mat.calls)
	}
}

func TestOneKeyAcceptsUnsortedUnderTargetBatch(t *testing.T) {
	svc, st, prog, _, pexp := progressionFixture(t)
	prog.threshold = []ExpThreshold{{Level: 1, TotalExp: 25}, {Level: 2, TotalExp: 10000}}
	got, err := svc.UseExpItems(context.Background(), caActor(t), 1, []appi5.PetExpItemDebit{{ItemID: 50001089, Count: 1}, {ItemID: 50001087, Count: 1}}, caOp(t, "14141414-1414-4414-8414-141414141414", 2220))
	if err != nil {
		t.Fatal(err)
	}
	if got.Exp != 7800 || got.Level != 2 || pexp.prepare != 1 || pexp.apply != 1 || st.byID[1].Exp != 7800 {
		t.Fatalf("got=%+v prepare=%d apply=%d pet=%+v", got, pexp.prepare, pexp.apply, st.byID[1])
	}
}
