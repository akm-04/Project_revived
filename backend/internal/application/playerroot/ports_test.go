package playerroot

import (
	"gxb.local/backend/v2/internal/domain/identity"
	"testing"
)

func TestCanonicalPlayerIDsSortsAndDeduplicates(t *testing.T) {
	got, err := CanonicalPlayerIDs([]identity.PlayerID{9, 2, 9, 4})
	if err != nil {
		t.Fatal(err)
	}
	want := []identity.PlayerID{2, 4, 9}
	if len(got) != len(want) {
		t.Fatalf("got=%v", got)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("got=%v want=%v", got, want)
		}
	}
}
func TestLockRankBetweenGuildRootAndMembership(t *testing.T) {
	if !(310 < LockRank && LockRank < 320) {
		t.Fatalf("rank=%d", LockRank)
	}
}
