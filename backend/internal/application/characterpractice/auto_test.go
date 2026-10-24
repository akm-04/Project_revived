package characterpractice

import (
	"errors"
	"math"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func TestAutoSavePredicateV1TruthTable(t *testing.T) {
	t.Parallel()
	for mask := 1; mask < 16; mask++ {
		save := AutoSavePredicates{mask&1 != 0, mask&2 != 0, mask&4 != 0, mask&8 != 0}
		if err := save.Validate(PracticeLocks{}); err != nil {
			t.Fatalf("mask=%04b: %v", mask, err)
		}
		for a := int64(-1); a <= 1; a++ {
			for b := int64(-1); b <= 1; b++ {
				for c := int64(-1); c <= 1; c++ {
					d := PracticeDelta{a, b, c}
					want := true
					if save[0] && a <= 0 {
						want = false
					}
					if save[1] && b <= 0 {
						want = false
					}
					if save[2] && c <= 0 {
						want = false
					}
					if save[3] && a+b+c <= 0 {
						want = false
					}
					if got := autoSavePredicateAccept(d, save); got != want {
						t.Fatalf("mask=%04b delta=%v got=%v want=%v", mask, d, got, want)
					}
				}
			}
		}
	}
	if err := (AutoSavePredicates{}).Validate(PracticeLocks{}); !errors.Is(err, ErrInvalidAutoSavePredicates) {
		t.Fatalf("empty save predicates: %v", err)
	}
	if err := (AutoSavePredicates{false, false, false, true}).Validate(PracticeLocks{true, false, false}); !errors.Is(err, ErrInvalidAutoSavePredicates) {
		t.Fatalf("lock/save mismatch: %v", err)
	}
}

func TestAutoBatchV1GoldenVectors(t *testing.T) {
	t.Parallel()
	now := time.Unix(576, 0).UTC()
	root := Root{PlayerID: identity.PlayerID(7), BlessRemaining: 1000, BlessCapacityAtEpoch: 1000, BaseMana: 123, BaseCrystal: 456, StateVersion: 3, CreatedAt: now.Add(-time.Hour), UpdatedAt: now}
	type golden struct {
		name    string
		seed    string
		method  Method
		current character.PracticeAttrs
		locks   PracticeLocks
		batch   int64
		save    AutoSavePredicates
		add     []PracticeDelta
		accept  []int64
		final   character.PracticeAttrs
		draws   int
	}
	vectors := []golden{
		{
			name: "advanced_total", seed: "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
			method: Method{ID: 2, CurrencyType: 2, BaseCost: 50}, current: character.PracticeAttrs{100, 100, 100}, batch: 6, save: AutoSavePredicates{false, false, false, true},
			add: []PracticeDelta{{1, -1, 1}, {1, 1, 1}, {1, -1, 1}, {1, 1, -1}, {-1, 1, 1}, {1, 1, -1}}, accept: []int64{1, 1, 1, 1, 1, 1}, final: character.PracticeAttrs{104, 102, 102}, draws: 6,
		},
		{
			name: "normal_str_and_total", seed: repeatHex("00"), method: Method{ID: 1, CurrencyType: 1, BaseCost: 20000}, current: character.PracticeAttrs{10, 20, 30}, batch: 4, save: AutoSavePredicates{true, false, false, true},
			add: []PracticeDelta{{-1, -1, -1}, {-1, 1, -1}, {1, 1, -1}, {-1, -1, -1}}, accept: []int64{0, 0, 1, 0}, final: character.PracticeAttrs{11, 21, 29}, draws: 4,
		},
		{
			name: "terminal_cap_suffix", seed: repeatHex("a5"), method: Method{ID: 2, CurrencyType: 2, BaseCost: 50}, current: character.PracticeAttrs{200, 200, 199}, batch: 10, save: AutoSavePredicates{false, false, false, true},
			add: []PracticeDelta{{0, 0, 1}, {}, {}, {}, {}, {}, {}, {}, {}, {}}, accept: []int64{1, 0, 0, 0, 0, 0, 0, 0, 0, 0}, final: character.PracticeAttrs{200, 200, 200}, draws: 1,
		},
	}
	for _, tc := range vectors {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			got, err := planAutoBatchV1(operation.Context{EntropySeed: mustSeed(t, tc.seed)}, root, tc.method, Method{ID: 2, CurrencyType: 2, BaseCost: 50}, nil, tc.current, tc.locks, tc.batch, tc.save)
			if err != nil {
				t.Fatal(err)
			}
			if !reflect.DeepEqual(got.AddAttrs, tc.add) || !reflect.DeepEqual(got.IsAdds, tc.accept) || got.FinalAttrs != tc.final || got.RollDraws != tc.draws {
				t.Fatalf("got add=%v accept=%v final=%v draws=%d", got.AddAttrs, got.IsAdds, got.FinalAttrs, got.RollDraws)
			}
			if len(got.AddAttrs) != int(tc.batch) || len(got.IsAdds) != int(tc.batch) {
				t.Fatalf("shape add=%d accept=%d batch=%d", len(got.AddAttrs), len(got.IsAdds), tc.batch)
			}
		})
	}
}

func TestAutoAccountingV1ReferenceVectorsAndStrictBless(t *testing.T) {
	t.Parallel()
	now := time.Unix(577, 0).UTC()
	methods := map[int64]Method{
		1: {ID: 1, CurrencyType: 1, BaseCost: 20000},
		2: {ID: 2, CurrencyType: 2, BaseCost: 50},
		3: {ID: 3, CurrencyType: 2, BaseCost: 100, VIPMin: 5},
	}
	locks := map[int64]LockCost{
		1: {Count: 1, ManaStep: 70000, CrystalStep: 15, BlessCost: 10},
		2: {Count: 2, ManaStep: 200000, CrystalStep: 40, BlessCost: 40},
		3: {Count: 3, ManaStep: 200000, CrystalStep: 40, BlessCost: 60},
	}
	for methodID := int64(1); methodID <= 3; methodID++ {
		for lockCount := int64(0); lockCount <= 3; lockCount++ {
			for _, batch := range []int64{2, 4, 6, 8, 10} {
				var lock *LockCost
				if lockCount > 0 {
					v := locks[lockCount]
					lock = &v
				}
				required := int64(0)
				if lock != nil {
					required = lock.BlessCost * batch
				}
				oldFree := now.Add(-2 * time.Hour)
				root := Root{PlayerID: identity.PlayerID(7), FreeLastConsumedAt: &oldFree, BlessRemaining: required + 1, BlessCapacityAtEpoch: required + 1, BaseMana: 123, BaseCrystal: 456, StateVersion: 3, CreatedAt: now.Add(-time.Hour), UpdatedAt: now}
				currency, total, bless, next, err := planAutoAccounting(root, methods[methodID], methods[2], lock, lockCount, batch)
				if err != nil {
					t.Fatalf("method=%d locks=%d batch=%d: %v", methodID, lockCount, batch, err)
				}
				methodBase := methods[methodID].BaseCost
				if methods[methodID].CurrencyType == 2 && lockCount == 3 {
					methodBase = methods[2].BaseCost
				}
				running := root.BaseCrystal
				step := int64(0)
				wantCurrency := "crystal"
				if methods[methodID].CurrencyType == 1 {
					running = root.BaseMana
					wantCurrency = "mana"
				}
				if lock != nil {
					if wantCurrency == "mana" {
						step = lock.ManaStep
					} else {
						step = lock.CrystalStep
					}
				}
				surcharge := int64(0)
				for i := int64(0); i < batch; i++ {
					for j := int64(0); j < lockCount; j++ {
						running += step
						surcharge += running
					}
				}
				wantTotal := methodBase*batch + surcharge
				if currency != wantCurrency || total != wantTotal || bless != required {
					t.Fatalf("method=%d locks=%d batch=%d got currency=%s total=%d bless=%d want=%s/%d/%d", methodID, lockCount, batch, currency, total, bless, wantCurrency, wantTotal, required)
				}
				if next.FreeLastConsumedAt == nil || !next.FreeLastConsumedAt.Equal(oldFree) {
					t.Fatalf("AUTO changed free entitlement: before=%v after=%v", oldFree, next.FreeLastConsumedAt)
				}
				if lockCount == 0 {
					if next.BaseMana != root.BaseMana || next.BaseCrystal != root.BaseCrystal || next.BlessRemaining != root.BlessRemaining {
						t.Fatalf("zero-lock root changed: before=%+v after=%+v", root, next)
					}
				} else {
					if next.BlessRemaining != 1 {
						t.Fatalf("bless remaining=%d want 1", next.BlessRemaining)
					}
					if wantCurrency == "mana" && next.BaseMana != running {
						t.Fatalf("mana base=%d want %d", next.BaseMana, running)
					}
					if wantCurrency == "crystal" && next.BaseCrystal != running {
						t.Fatalf("crystal base=%d want %d", next.BaseCrystal, running)
					}
				}

				if lockCount > 0 {
					eq := root
					eq.BlessRemaining, eq.BlessCapacityAtEpoch = required, required
					if _, _, _, _, err := planAutoAccounting(eq, methods[methodID], methods[2], lock, lockCount, batch); !errors.Is(err, ErrPracticeBless) {
						t.Fatalf("Bless equality method=%d locks=%d batch=%d err=%v", methodID, lockCount, batch, err)
					}
				}
			}
		}
	}
}

func TestAutoBatchV1RejectsInvalidSurfaceBeforeRoll(t *testing.T) {
	t.Parallel()
	now := time.Unix(578, 0).UTC()
	root := Root{PlayerID: identity.PlayerID(7), BlessRemaining: 1000, BlessCapacityAtEpoch: 1000, StateVersion: 1, CreatedAt: now, UpdatedAt: now}
	method := Method{ID: 2, CurrencyType: 2, BaseCost: 50}
	op := operation.Context{EntropySeed: [32]byte{1}}
	if _, err := planAutoBatchV1(op, root, method, method, nil, character.PracticeAttrs{200, 200, 200}, PracticeLocks{}, 2, AutoSavePredicates{false, false, false, true}); !errors.Is(err, ErrAllPracticeAttrsAtCap) {
		t.Fatalf("all cap: %v", err)
	}
	if _, err := planAutoBatchV1(op, root, method, method, nil, character.PracticeAttrs{1, 1, 1}, PracticeLocks{}, 3, AutoSavePredicates{false, false, false, true}); !errors.Is(err, ErrInvalidAutoBatch) {
		t.Fatalf("batch=3: %v", err)
	}
	if _, err := planAutoBatchV1(op, root, method, method, nil, character.PracticeAttrs{1, 1, 1}, PracticeLocks{true, false, false}, 2, AutoSavePredicates{false, false, false, true}); !errors.Is(err, ErrInvalidAutoSavePredicates) {
		t.Fatalf("lock/save mismatch: %v", err)
	}
	bad := method
	bad.BaseCost = math.MaxInt64
	if _, err := planAutoBatchV1(op, root, bad, method, nil, character.PracticeAttrs{1, 1, 1}, PracticeLocks{}, 10, AutoSavePredicates{false, false, false, true}); err == nil {
		t.Fatal("overflowing aggregate cost accepted")
	}
}

func FuzzAutoBatchV1BoundsShapeAndRetryStability(f *testing.F) {
	f.Add(int64(2), int64(100), int64(100), int64(100), uint8(0), uint8(8), uint8(4), uint8(1))
	f.Add(int64(1), int64(200), int64(200), int64(199), uint8(0), uint8(8), uint8(0), uint8(9))
	f.Fuzz(func(t *testing.T, methodID, a, b, c int64, lockMask, saveMask, batchChoice, seedByte uint8) {
		methodID = 1 + positiveMod(methodID, 3)
		a = positiveMod(a, character.MaxPracticeAttr+1)
		b = positiveMod(b, character.MaxPracticeAttr+1)
		c = positiveMod(c, character.MaxPracticeAttr+1)
		if a == character.MaxPracticeAttr && b == character.MaxPracticeAttr && c == character.MaxPracticeAttr {
			c--
		}
		locks := PracticeLocks{lockMask&1 != 0, lockMask&2 != 0, lockMask&4 != 0}
		saveMask &= 0x0f
		for axis := range 3 {
			if locks[axis] {
				saveMask |= 1 << axis
			}
		}
		if saveMask == 0 {
			saveMask = 8
		}
		save := AutoSavePredicates{saveMask&1 != 0, saveMask&2 != 0, saveMask&4 != 0, saveMask&8 != 0}
		batches := [...]int64{2, 4, 6, 8, 10}
		batch := batches[int(batchChoice)%len(batches)]
		lockCount := countLocks(locks)
		var lock *LockCost
		if lockCount > 0 {
			v := LockCost{Count: lockCount, ManaStep: 7, CrystalStep: 3, BlessCost: 2}
			lock = &v
		}
		required := int64(0)
		if lock != nil {
			required = lock.BlessCost * batch
		}
		now := time.Unix(579, 0).UTC()
		root := Root{PlayerID: identity.PlayerID(7), BlessRemaining: required + 1, BlessCapacityAtEpoch: required + 1, BaseMana: 11, BaseCrystal: 13, StateVersion: 1, CreatedAt: now, UpdatedAt: now}
		methods := map[int64]Method{1: {ID: 1, CurrencyType: 1, BaseCost: 20}, 2: {ID: 2, CurrencyType: 2, BaseCost: 5}, 3: {ID: 3, CurrencyType: 2, BaseCost: 10, VIPMin: 5}}
		op := operation.Context{EntropySeed: [32]byte{seedByte, 1, 2, 3}}
		one, err := planAutoBatchV1(op, root, methods[methodID], methods[2], lock, character.PracticeAttrs{a, b, c}, locks, batch, save)
		if err != nil {
			t.Fatal(err)
		}
		two, err := planAutoBatchV1(op, root, methods[methodID], methods[2], lock, character.PracticeAttrs{a, b, c}, locks, batch, save)
		if err != nil {
			t.Fatal(err)
		}
		if !reflect.DeepEqual(one, two) {
			t.Fatalf("same semantic operation changed plan: one=%+v two=%+v", one, two)
		}
		if len(one.AddAttrs) != int(batch) || len(one.IsAdds) != int(batch) || one.RollDraws > int(batch) || one.TotalCost <= 0 || one.FinalAttrs.Validate() != nil {
			t.Fatalf("invalid plan shape/result: %+v", one)
		}
		for i := range one.AddAttrs {
			if one.AddAttrs[i].Validate() != nil || (one.IsAdds[i] != 0 && one.IsAdds[i] != 1) {
				t.Fatalf("attempt=%d delta=%v accepted=%d", i, one.AddAttrs[i], one.IsAdds[i])
			}
		}
		for i := one.RollDraws; i < int(batch); i++ {
			if one.AddAttrs[i] != (PracticeDelta{}) || one.IsAdds[i] != 0 {
				t.Fatalf("terminal suffix attempt=%d delta=%v accepted=%d", i, one.AddAttrs[i], one.IsAdds[i])
			}
		}
	})
}
