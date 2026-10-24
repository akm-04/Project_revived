package socialrelation

import (
	"testing"

	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
)

func TestI7A4ALockRanksAreFrozenAndAfterPlayerRoot(t *testing.T) {
	got := []uint16{LockRankSocialRoot, LockRankFriendship, LockRankRequest, LockRankBlock, LockRankRequestEpoch}
	want := []uint16{360, 361, 362, 363, 364}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("rank[%d]=%d want=%d", i, got[i], want[i])
		}
		if i > 0 && got[i-1] >= got[i] {
			t.Fatalf("non-increasing social rank plan: %v", got)
		}
	}
	if playerroot.LockRank >= LockRankSocialRoot {
		t.Fatalf("player root rank %d must precede SocialRoot %d", playerroot.LockRank, LockRankSocialRoot)
	}
}

func TestCanonicalRelationKeys(t *testing.T) {
	a, b := identity.PlayerID(200001), identity.PlayerID(100001)
	low, high, err := CanonicalPair(a, b)
	if err != nil || low != 100001 || high != 200001 {
		t.Fatalf("pair low=%d high=%d err=%v", low, high, err)
	}
	pk, _ := playerroot.LockKey(low)
	rk, _ := SocialRootLockKey(low)
	fk, _ := FriendshipLockKey(a, b)
	qk, _ := RequestLockKey(low, high)
	bk, _ := BlockLockKey(low, high)
	ek, _ := RequestEpochLockKey(low, "SOCIAL_REQUEST_DAY_V1")
	keys, err := lockkey.Canonical([]lockkey.Key{ek, fk, rk, pk, bk, qk})
	if err != nil {
		t.Fatal(err)
	}
	for i := 1; i < len(keys); i++ {
		if lockkey.Compare(keys[i-1], keys[i]) >= 0 {
			t.Fatalf("keys not canonical: %+v", keys)
		}
	}
	fence, err := SocialRootCreationFence(low)
	if err != nil || fence.UniqueConstraint != SocialRootUniqueConstraint || lockkey.Compare(fence.Parent, pk) != 0 {
		t.Fatalf("bad root creation fence: %+v err=%v", fence, err)
	}
}
