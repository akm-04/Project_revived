package socialinbox

import (
	"testing"

	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
)

func TestNoticeRankFollowsRelationRanks(t *testing.T) {
	if LockRankNotice != 370 || LockRankNotice <= socialrelation.LockRankRequestEpoch {
		t.Fatalf("notice rank=%d request epoch=%d", LockRankNotice, socialrelation.LockRankRequestEpoch)
	}
}

func TestNoticeKeysAreTypedAndCanonical(t *testing.T) {
	pid := identity.PlayerID(100001)
	a, err := NoticeLockKey(pid, 7)
	if err != nil {
		t.Fatal(err)
	}
	b, err := NoticeSourceLockKey(pid, SourceKey{Kind: "friend-request", Key: "100001:200001:3:accepted"})
	if err != nil {
		t.Fatal(err)
	}
	keys, err := lockkey.Canonical([]lockkey.Key{b, a})
	if err != nil || len(keys) != 2 {
		t.Fatalf("canonical=%v err=%v", keys, err)
	}
}
