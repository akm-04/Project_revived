package stockruntime

import (
	"testing"

	"gxb.local/backend/v2/internal/application/achievement"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

func TestAchievementNoticeFrameMatchesItsRegisteredSchema(t *testing.T) {
	registry, e := NewAchievementNoticeRegistry()
	if e != nil {
		t.Fatal(e)
	}
	n := achievement.NoticeParams{Entry: achievement.Entry{AchievementID: 100017, CompleteTimes: [3]int64{1700000000, 0, 0}, Progress: 3}, PointLevel: 1, TotalPoints: 500, Rank: 2}
	if e = registry.ValidateNotice(mids.MIDPlayerNotice, rt.NoticeNamespaceGeneric, rt.World, achievementNoticeFrame(n)); e != nil {
		t.Fatal(e)
	}
	if e = registry.ValidateNotice(mids.MIDPlayerNotice, rt.NoticeNamespaceGeneric, rt.Guild, achievementNoticeFrame(n)); e == nil {
		t.Fatal("notice 17 accepted on a non-World connection")
	}
}
