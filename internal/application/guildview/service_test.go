package guildview

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
)

type viewStore struct {
	g           guild.Guild
	memberships map[identity.PlayerID]guild.Membership
	apps        []guild.Application
}

func (s viewStore) ReadGuild(context.Context, guild.ID) (guild.Guild, bool, error) {
	if s.g.ID == 0 {
		return guild.Guild{}, false, nil
	}
	return s.g, true, nil
}
func (s viewStore) ReadMembership(_ context.Context, p identity.PlayerID) (guild.Membership, bool, error) {
	m, ok := s.memberships[p]
	return m, ok, nil
}
func (s viewStore) ListMemberships(context.Context, guild.ID) ([]guild.Membership, error) {
	out := make([]guild.Membership, 0, len(s.memberships))
	for _, m := range s.memberships {
		out = append(out, m)
	}
	return out, nil
}
func (s viewStore) ListGuilds(context.Context, identity.LogicalServerID, int) ([]guild.Guild, error) {
	if s.g.ID == 0 {
		return nil, nil
	}
	return []guild.Guild{s.g}, nil
}
func (s viewStore) ListGuildApplications(context.Context, guild.ID) ([]guild.Application, error) {
	return append([]guild.Application(nil), s.apps...), nil
}
func (s viewStore) ListPlayerApplications(context.Context, identity.PlayerID) ([]guild.Application, error) {
	return append([]guild.Application(nil), s.apps...), nil
}

type viewDirectory map[identity.PlayerID]playerdirectory.Profile

func (d viewDirectory) Profile(_ context.Context, p identity.PlayerID) (playerdirectory.Profile, bool, error) {
	v, ok := d[p]
	return v, ok, nil
}

func viewFixture() (Service, identity.ActorContext) {
	at := time.Unix(100, 0).UTC()
	g := guild.Guild{ID: 1000001, LogicalServerID: 1, Name: "guild", Icon: 20010001, Description: "d", ApplyType: guild.ApplyByApplication, MinAllowLevel: 32, Vitality: 20000, PolicyRevision: "p", StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	ms := map[identity.PlayerID]guild.Membership{
		100001: {PlayerID: 100001, GuildID: g.ID, Role: guild.Leader, JoinedAt: at, MembershipVersion: 1, StateVersion: 1, UpdatedAt: at},
		100002: {PlayerID: 100002, GuildID: g.ID, Role: guild.Member, JoinedAt: at, MembershipVersion: 1, StateVersion: 1, UpdatedAt: at},
	}
	dir := viewDirectory{
		100001: {PlayerID: 100001, Name: "leader", Level: 40, AvatarID: 11, AvatarFrameID: 1, ConquerLevel: 2, ConquerLoopID: 3},
		100002: {PlayerID: 100002, Name: "member", Level: 35, AvatarID: 12, AvatarFrameID: 2, ConquerLevel: 4, ConquerLoopID: 5},
	}
	return Service{Store: viewStore{g: g, memberships: ms}, Directory: dir}, identity.ActorContext{LogicalServerID: 1, PlayerID: 100001}
}

func TestMembersUsesTypedPlayerDirectoryAndPresentationSentinels(t *testing.T) {
	s, a := viewFixture()
	info, members, err := s.Members(context.Background(), a)
	if err != nil {
		t.Fatal(err)
	}
	if info.GuildLeader != 100001 || info.GuildLeaderName != "leader" || len(members) != 2 {
		t.Fatalf("info=%+v members=%+v", info, members)
	}
	for _, m := range members {
		if m.LastTime != 0 || m.SevenVitality != 0 || m.CopyChallengeTime != 0 {
			t.Fatalf("presentation sentinel drift: %+v", m)
		}
		if m.Name == "" || m.Level < 1 {
			t.Fatalf("typed profile missing: %+v", m)
		}
	}
}

func TestGuildRoomRequiresOnlyCanonicalGuildStore(t *testing.T) {
	s, a := viewFixture()
	s.Directory = nil
	id, ok, err := s.GuildRoom(context.Background(), a)
	if err != nil {
		t.Fatal(err)
	}
	if !ok || id != 1000001 {
		t.Fatalf("id=%d ok=%v", id, ok)
	}
}

func TestGuildForPlayerIsServerFenced(t *testing.T) {
	s, a := viewFixture()
	info, ok, err := s.GuildForPlayer(context.Background(), a, 100002)
	if err != nil {
		t.Fatal(err)
	}
	if !ok || info.GuildID != 1000001 {
		t.Fatalf("info=%+v ok=%v", info, ok)
	}
	a.LogicalServerID = 2
	if _, ok, err := s.GuildForPlayer(context.Background(), a, 100002); err != nil || ok {
		t.Fatalf("cross-server ok=%v err=%v", ok, err)
	}
}
