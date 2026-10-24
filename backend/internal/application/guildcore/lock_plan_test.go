package guildcore

import (
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"testing"
)

func TestI6CLockRanksMatchPass498AndRemainBelowI5(t *testing.T) {
	if LockRankAllocator != 300 || LockRankGuild != 310 || playerroot.LockRank != 315 || LockRankMembership != 320 || LockRankApplication != 330 || LockRankInvite != 340 || LockRankAudit != 350 {
		t.Fatalf("rank drift allocator=%d guild=%d player=%d membership=%d app=%d invite=%d audit=%d", LockRankAllocator, LockRankGuild, playerroot.LockRank, LockRankMembership, LockRankApplication, LockRankInvite, LockRankAudit)
	}
	if !(LockRankAudit < 610 && 610 < 700) {
		t.Fatal("Guild locks must precede I5 mail/economy ranks")
	}
}
func TestI6CLockPlanCanonicalizesPlayersAndChildOrder(t *testing.T) {
	p, err := NewLockPlan(1, guild.ID(1000001), []identity.PlayerID{100002, 100001}, true, []identity.PlayerID{100002}, []identity.PlayerID{100001})
	if err != nil {
		t.Fatal(err)
	}
	last := uint16(0)
	for _, k := range p.Keys {
		if k.DomainRank < last {
			t.Fatalf("noncanonical ranks: %+v", p.Keys)
		}
		last = k.DomainRank
	}
	want := []uint16{300, 310, 315, 315, 320, 320, 330, 340, 350}
	if len(p.Keys) != len(want) {
		t.Fatalf("keys=%+v", p.Keys)
	}
	for i, r := range want {
		if p.Keys[i].DomainRank != r {
			t.Fatalf("key[%d] rank=%d want=%d", i, p.Keys[i].DomainRank, r)
		}
	}
}
func TestI6CLockPlanRejectsCrossServerGuild(t *testing.T) {
	if _, err := NewLockPlan(2, guild.ID(1000001), []identity.PlayerID{200001}, false, nil, nil); err == nil {
		t.Fatal("expected cross-server failure")
	}
}
