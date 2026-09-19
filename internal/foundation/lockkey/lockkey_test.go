package lockkey

import (
	"math/rand"
	"reflect"
	"testing"
)

func must(k Key, e error) Key {
	if e != nil {
		panic(e)
	}
	return k
}
func TestCanonicalOrderingIndependentOfInputPermutation(t *testing.T) {
	base := []Key{must(New(2, "guild", Uint64(8))), must(New(1, "player", Int64(-1))), must(New(1, "player", Int64(9))), must(New(1, "player", String("9")))}
	want, _ := Canonical(base)
	r := rand.New(rand.NewSource(1))
	for n := 0; n < 200; n++ {
		in := append([]Key(nil), base...)
		r.Shuffle(len(in), func(i, j int) { in[i], in[j] = in[j], in[i] })
		got, err := Canonical(in)
		if err != nil {
			t.Fatal(err)
		}
		if !reflect.DeepEqual(got, want) {
			t.Fatalf("permutation changed order")
		}
	}
}
func TestIdentityTypesDoNotCollapse(t *testing.T) {
	a := must(New(1, "player", Int64(9)))
	b := must(New(1, "player", String("9")))
	if Compare(a, b) == 0 {
		t.Fatal("typed identities collapsed")
	}
}
func TestDuplicateRejected(t *testing.T) {
	k := must(New(1, "p", Uint64(1)))
	if _, err := Canonical([]Key{k, k}); err == nil {
		t.Fatal("expected duplicate rejection")
	}
}

func TestMissingRowCreationRequiresParentFenceAndUniqueConstraint(t *testing.T) {
	parent := must(New(1, "account_directory", Uint64(7)))
	if err := (CreationFence{Parent: parent, UniqueConstraint: "account_server_character_uq"}).Validate(); err != nil {
		t.Fatal(err)
	}
	if err := (CreationFence{}).Validate(); err == nil {
		t.Fatal("empty creation fence accepted")
	}
}

func TestCanonicalDedupCollapsesRepeatedRequirement(t *testing.T) {
	a, _ := New(40, "scalar", String("p1/gold"))
	b, _ := New(30, "owner", Int64(1))
	got, err := CanonicalDedup([]Key{a, b, a})
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 2 || Compare(got[0], b) != 0 || Compare(got[1], a) != 0 {
		t.Fatalf("dedup order=%v", got)
	}
}
