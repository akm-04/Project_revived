package characterpractice

import (
	"encoding/hex"
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func TestPracticeRollPolicyV1GoldenVectors(t *testing.T) {
	t.Parallel()
	type golden struct {
		name    string
		seed    string
		method  int64
		current character.PracticeAttrs
		locks   PracticeLocks
		attempt uint64
		index   int
		size    int
		mask    uint8
		raw     [3]int64
		eff     [3]int64
	}
	vectors := []golden{
		{"normal_mid", repeatHex("00"), 1, character.PracticeAttrs{100, 100, 100}, PracticeLocks{}, 0, 0, 8, 0, [3]int64{-1, -1, -1}, [3]int64{-1, -1, -1}},
		{"normal_lock_str", "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f", 1, character.PracticeAttrs{100, 100, 100}, PracticeLocks{true, false, false}, 0, 0, 4, 1, [3]int64{1, -1, -1}, [3]int64{1, -1, -1}},
		{"normal_lower_bound", repeatHex("a5"), 1, character.PracticeAttrs{0, 0, 0}, PracticeLocks{}, 0, 7, 8, 7, [3]int64{1, 1, 1}, [3]int64{1, 1, 1}},
		{"advanced_mid", repeatHex("00"), 2, character.PracticeAttrs{100, 100, 100}, PracticeLocks{}, 0, 0, 4, 3, [3]int64{1, 1, -1}, [3]int64{1, 1, -1}},
		{"advanced_lock_int", "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f", 2, character.PracticeAttrs{100, 100, 100}, PracticeLocks{false, true, false}, 0, 2, 3, 7, [3]int64{1, 1, 1}, [3]int64{1, 1, 1}},
		{"advanced_cap_edge", repeatHex("a5"), 2, character.PracticeAttrs{200, 200, 199}, PracticeLocks{}, 0, 0, 1, 7, [3]int64{1, 1, 1}, [3]int64{0, 0, 1}},
		{"legendary_mid", repeatHex("00"), 3, character.PracticeAttrs{100, 100, 100}, PracticeLocks{}, 0, 3, 4, 7, [3]int64{1, 1, 1}, [3]int64{1, 1, 1}},
		{"legendary_cap_locked", repeatHex("5a"), 3, character.PracticeAttrs{200, 0, 0}, PracticeLocks{true, false, false}, 0, 2, 3, 7, [3]int64{1, 1, 1}, [3]int64{0, 1, 1}},
		{"advanced_attempt_7", repeatHex("00"), 2, character.PracticeAttrs{100, 100, 100}, PracticeLocks{}, 7, 0, 4, 3, [3]int64{1, 1, -1}, [3]int64{1, 1, -1}},
	}
	for _, tc := range vectors {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			op := operation.Context{EntropySeed: mustSeed(t, tc.seed)}
			got, err := RollPracticeV1(op, tc.method, tc.current, tc.locks, tc.attempt)
			if err != nil {
				t.Fatal(err)
			}
			if got.Index != tc.index || got.SupportSize != tc.size || got.Mask != tc.mask || got.Raw != tc.raw || got.Effective != tc.eff {
				t.Fatalf("got %+v, want index=%d size=%d mask=%d raw=%v effective=%v", got, tc.index, tc.size, tc.mask, tc.raw, tc.eff)
			}
		})
	}
}

func TestPracticeRollPolicyV1SupportProperties(t *testing.T) {
	t.Parallel()
	values := []int64{0, 1, 100, 199, 200}
	for _, method := range []int64{1, 2, 3} {
		for _, a := range values {
			for _, b := range values {
				for _, c := range values {
					current := character.PracticeAttrs{a, b, c}
					for mask := 0; mask < 8; mask++ {
						locks := PracticeLocks{mask&1 != 0, mask&2 != 0, mask&4 != 0}
						support, err := practiceRollSupportV1(method, current, locks)
						if a == 200 && b == 200 && c == 200 {
							if !errors.Is(err, ErrAllPracticeAttrsAtCap) {
								t.Fatalf("method=%d current=%v locks=%v: got %v, want all-cap", method, current, locks, err)
							}
							continue
						}
						if err != nil {
							t.Fatalf("method=%d current=%v locks=%v: %v", method, current, locks, err)
						}
						lastMask := -1
						for _, candidate := range support {
							if int(candidate.Mask) <= lastMask {
								t.Fatalf("support not in canonical mask order: %+v", support)
							}
							lastMask = int(candidate.Mask)
							total := int64(0)
							for axis := range 3 {
								if locks[axis] && candidate.Raw[axis] != 1 {
									t.Fatalf("locked axis not +1: %+v", candidate)
								}
								next := current[axis] + candidate.Effective[axis]
								if next < 0 || next > character.MaxPracticeAttr {
									t.Fatalf("out of bounds: current=%v candidate=%+v", current, candidate)
								}
								total += candidate.Effective[axis]
							}
							if method != 1 && total <= 0 {
								t.Fatalf("paid support contains non-positive effective delta: %+v", candidate)
							}
						}
					}
				}
			}
		}
	}
}

func TestPracticeRollPolicyV1RetryStableAndAttemptScoped(t *testing.T) {
	t.Parallel()
	op := operation.Context{EntropySeed: mustSeed(t, "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f")}
	current := character.PracticeAttrs{100, 100, 100}
	locks := PracticeLocks{}
	a, err := RollPracticeV1(op, 2, current, locks, 9)
	if err != nil {
		t.Fatal(err)
	}
	b, err := RollPracticeV1(op, 2, current, locks, 9)
	if err != nil {
		t.Fatal(err)
	}
	if a != b {
		t.Fatalf("same semantic operation/attempt changed result: %+v != %+v", a, b)
	}
	// Different attempt ordinals are allowed to collide by chance; prove that the
	// entropy plan itself changes rather than asserting a different selected mask.
	if op.Derive("characterpractice.roll.v1.selector/method=2/round=0", 9) == op.Derive("characterpractice.roll.v1.selector/method=2/round=0", 10) {
		t.Fatal("attempt ordinal did not alter derived entropy")
	}
}

func FuzzPracticeRollPolicyV1BoundsAndLocks(f *testing.F) {
	f.Add(int64(1), int64(0), int64(100), int64(199), uint8(0), uint64(0))
	f.Add(int64(3), int64(200), int64(0), int64(0), uint8(1), uint64(7))
	f.Fuzz(func(t *testing.T, method, a, b, c int64, lockMask uint8, attempt uint64) {
		method = 1 + positiveMod(method, 3)
		a = positiveMod(a, character.MaxPracticeAttr+1)
		b = positiveMod(b, character.MaxPracticeAttr+1)
		c = positiveMod(c, character.MaxPracticeAttr+1)
		if a == character.MaxPracticeAttr && b == character.MaxPracticeAttr && c == character.MaxPracticeAttr {
			return
		}
		locks := PracticeLocks{lockMask&1 != 0, lockMask&2 != 0, lockMask&4 != 0}
		op := operation.Context{EntropySeed: [32]byte{1, 2, 3, 4, 5, 6, 7, 8}}
		got, err := RollPracticeV1(op, method, character.PracticeAttrs{a, b, c}, locks, attempt)
		if err != nil {
			t.Fatal(err)
		}
		for axis := range 3 {
			if locks[axis] && got.Raw[axis] != 1 {
				t.Fatalf("locked axis raw=%d", got.Raw[axis])
			}
			next := []int64{a, b, c}[axis] + got.Effective[axis]
			if next < 0 || next > character.MaxPracticeAttr {
				t.Fatalf("next=%d outside bounds", next)
			}
		}
	})
}

func mustSeed(t *testing.T, s string) [32]byte {
	t.Helper()
	b, err := hex.DecodeString(s)
	if err != nil || len(b) != 32 {
		t.Fatalf("bad seed %q: %v len=%d", s, err, len(b))
	}
	var out [32]byte
	copy(out[:], b)
	return out
}

func repeatHex(pair string) string {
	out := ""
	for range 32 {
		out += pair
	}
	return out
}

func positiveMod(v, n int64) int64 {
	v %= n
	if v < 0 {
		v += n
	}
	return v
}
