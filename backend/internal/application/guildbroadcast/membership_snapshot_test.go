package guildbroadcast

import (
	"gxb.local/backend/v2/internal/domain/guild"
	"testing"
	"time"
)

func TestMembershipClosureComparesAllFactsAndTimestampInstants(t *testing.T) {
	at := time.Date(2026, 10, 9, 8, 0, 0, 123000, time.UTC)
	a := guild.Membership{PlayerID: 100001, GuildID: 1000001, Role: guild.Leader, MembershipVersion: 1, StateVersion: 2, JoinedAt: at, UpdatedAt: at}
	b := a
	b.JoinedAt = at.In(time.FixedZone("same instant", 3600))
	b.UpdatedAt = b.JoinedAt
	if !sameMembership(a, b) {
		t.Fatal("same instant rejected")
	}
	for _, change := range []func(*guild.Membership){func(m *guild.Membership) { m.PlayerID++ }, func(m *guild.Membership) { m.GuildID++ }, func(m *guild.Membership) { m.Role = guild.Member }, func(m *guild.Membership) { m.MembershipVersion++ }, func(m *guild.Membership) { m.StateVersion++ }, func(m *guild.Membership) { m.JoinedAt = m.JoinedAt.Add(time.Microsecond) }, func(m *guild.Membership) { m.UpdatedAt = m.UpdatedAt.Add(time.Microsecond) }} {
		b := a
		change(&b)
		if sameMembership(a, b) {
			t.Fatal("closure drift ignored", b)
		}
	}
}
