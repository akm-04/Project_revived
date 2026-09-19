package guildview

import (
	"context"
	"errors"
	"sort"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
)

var (
	ErrUnavailable = errors.New("guild view unavailable")
	ErrForbidden   = errors.New("guild view forbidden")
)

type Store interface {
	ReadGuild(context.Context, guild.ID) (guild.Guild, bool, error)
	ReadMembership(context.Context, identity.PlayerID) (guild.Membership, bool, error)
	ListMemberships(context.Context, guild.ID) ([]guild.Membership, error)
	ListGuilds(context.Context, identity.LogicalServerID, int) ([]guild.Guild, error)
	ListGuildApplications(context.Context, guild.ID) ([]guild.Application, error)
	ListPlayerApplications(context.Context, identity.PlayerID) ([]guild.Application, error)
}

type Service struct {
	Store     Store
	Directory playerdirectory.Reader
}

func (s Service) validateStore() error {
	if s.Store == nil {
		return ErrUnavailable
	}
	return nil
}

func (s Service) validateDirectory() error {
	if err := s.validateStore(); err != nil {
		return err
	}
	if s.Directory == nil {
		return ErrUnavailable
	}
	return nil
}

type GuildInfo struct {
	GuildID         int64
	Icon            int64
	IconFrame       int64
	Name            string
	Description     string
	ApplyType       int16
	MinAllowLevel   int64
	Vitality        int64
	MemberNum       int64
	GuildLeader     int64
	GuildLeaderName string
}
type Member struct {
	PlayerID          int64
	Name              string
	Level             int64
	AvatarID          int64
	AvatarFrameID     int64
	ConquerLevel      int64
	ConquerLoopID     int64
	Role              int16
	JoinTime          int64
	LastTime          int64
	SevenVitality     int64
	CopyChallengeTime int64
}
type Applicant struct {
	PlayerID      int64
	Name          string
	Level         int64
	AvatarID      int64
	AvatarFrameID int64
	ConquerLevel  int64
	ConquerLoopID int64
}
type SelfGuild struct {
	GuildInfo GuildInfo
	SelfRole  int16
	JoinTime  int64
	MemberNum int64
}

func (s Service) profile(ctx context.Context, pid identity.PlayerID) (playerdirectory.Profile, error) {
	p, ok, err := s.Directory.Profile(ctx, pid)
	if err != nil {
		return playerdirectory.Profile{}, err
	}
	if !ok {
		return playerdirectory.Profile{}, playerdirectory.ErrProfileNotFound
	}
	return p, nil
}
func (s Service) guildInfo(ctx context.Context, g guild.Guild, members []guild.Membership) (GuildInfo, error) {
	out := GuildInfo{GuildID: int64(g.ID), Icon: g.Icon, IconFrame: g.IconFrame, Name: g.Name, Description: g.Description, ApplyType: int16(g.ApplyType), MinAllowLevel: g.MinAllowLevel, Vitality: g.Vitality, MemberNum: int64(len(members))}
	for _, m := range members {
		if m.Role == guild.Leader {
			p, err := s.profile(ctx, m.PlayerID)
			if err != nil {
				return GuildInfo{}, err
			}
			out.GuildLeader = int64(m.PlayerID)
			out.GuildLeaderName = p.Name
			break
		}
	}
	return out, nil
}
func (s Service) GuildInfo(ctx context.Context, actor identity.ActorContext, gid guild.ID) (GuildInfo, bool, error) {
	if err := s.validateDirectory(); err != nil {
		return GuildInfo{}, false, err
	}
	g, ok, err := s.Store.ReadGuild(ctx, gid)
	if err != nil || !ok {
		return GuildInfo{}, ok, err
	}
	if g.RetiredAt != nil || g.LogicalServerID != actor.LogicalServerID {
		return GuildInfo{}, false, nil
	}
	ms, err := s.Store.ListMemberships(ctx, gid)
	if err != nil {
		return GuildInfo{}, false, err
	}
	out, err := s.guildInfo(ctx, g, ms)
	return out, err == nil, err
}
func (s Service) Self(ctx context.Context, actor identity.ActorContext) (SelfGuild, bool, error) {
	if err := s.validateDirectory(); err != nil {
		return SelfGuild{}, false, err
	}
	m, ok, err := s.Store.ReadMembership(ctx, actor.PlayerID)
	if err != nil || !ok {
		return SelfGuild{}, false, err
	}
	g, ok, err := s.Store.ReadGuild(ctx, m.GuildID)
	if err != nil || !ok {
		return SelfGuild{}, false, err
	}
	if g.RetiredAt != nil || g.LogicalServerID != actor.LogicalServerID {
		return SelfGuild{}, false, nil
	}
	ms, err := s.Store.ListMemberships(ctx, g.ID)
	if err != nil {
		return SelfGuild{}, false, err
	}
	info, err := s.guildInfo(ctx, g, ms)
	if err != nil {
		return SelfGuild{}, false, err
	}
	return SelfGuild{GuildInfo: info, SelfRole: int16(m.Role), JoinTime: m.JoinedAt.Unix(), MemberNum: int64(len(ms))}, true, nil
}
func (s Service) Members(ctx context.Context, actor identity.ActorContext) (GuildInfo, []Member, error) {
	self, ok, err := s.Self(ctx, actor)
	if err != nil {
		return GuildInfo{}, nil, err
	}
	if !ok {
		return GuildInfo{}, nil, ErrForbidden
	}
	ms, err := s.Store.ListMemberships(ctx, guild.ID(self.GuildInfo.GuildID))
	if err != nil {
		return GuildInfo{}, nil, err
	}
	out := make([]Member, 0, len(ms))
	for _, m := range ms {
		p, err := s.profile(ctx, m.PlayerID)
		if err != nil {
			return GuildInfo{}, nil, err
		}
		out = append(out, Member{PlayerID: int64(m.PlayerID), Name: p.Name, Level: p.Level, AvatarID: p.AvatarID, AvatarFrameID: p.AvatarFrameID, ConquerLevel: p.ConquerLevel, ConquerLoopID: p.ConquerLoopID, Role: int16(m.Role), JoinTime: m.JoinedAt.Unix(), LastTime: 0, SevenVitality: 0, CopyChallengeTime: 0})
	}
	sort.Slice(out, func(i, j int) bool { return out[i].PlayerID < out[j].PlayerID })
	return self.GuildInfo, out, nil
}
func (s Service) Guilds(ctx context.Context, actor identity.ActorContext, limit int) ([]GuildInfo, error) {
	if err := s.validateDirectory(); err != nil {
		return nil, err
	}
	gs, err := s.Store.ListGuilds(ctx, actor.LogicalServerID, limit)
	if err != nil {
		return nil, err
	}
	out := make([]GuildInfo, 0, len(gs))
	for _, g := range gs {
		ms, err := s.Store.ListMemberships(ctx, g.ID)
		if err != nil {
			return nil, err
		}
		info, err := s.guildInfo(ctx, g, ms)
		if err != nil {
			return nil, err
		}
		out = append(out, info)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].GuildID < out[j].GuildID })
	return out, nil
}
func (s Service) Applicants(ctx context.Context, actor identity.ActorContext) ([]Applicant, error) {
	self, ok, err := s.Self(ctx, actor)
	if err != nil {
		return nil, err
	}
	if !ok || self.SelfRole == int16(guild.Member) {
		return nil, ErrForbidden
	}
	apps, err := s.Store.ListGuildApplications(ctx, guild.ID(self.GuildInfo.GuildID))
	if err != nil {
		return nil, err
	}
	out := make([]Applicant, 0, len(apps))
	for _, a := range apps {
		p, err := s.profile(ctx, a.PlayerID)
		if err != nil {
			return nil, err
		}
		out = append(out, Applicant{PlayerID: int64(a.PlayerID), Name: p.Name, Level: p.Level, AvatarID: p.AvatarID, AvatarFrameID: p.AvatarFrameID, ConquerLevel: p.ConquerLevel, ConquerLoopID: p.ConquerLoopID})
	}
	return out, nil
}
func (s Service) PlayerApplications(ctx context.Context, actor identity.ActorContext) ([]GuildInfo, error) {
	if err := s.validateDirectory(); err != nil {
		return nil, err
	}
	apps, err := s.Store.ListPlayerApplications(ctx, actor.PlayerID)
	if err != nil {
		return nil, err
	}
	out := make([]GuildInfo, 0, len(apps))
	seen := map[guild.ID]struct{}{}
	for _, a := range apps {
		if _, ok := seen[a.GuildID]; ok {
			continue
		}
		seen[a.GuildID] = struct{}{}
		info, ok, err := s.GuildInfo(ctx, actor, a.GuildID)
		if err != nil {
			return nil, err
		}
		if ok {
			out = append(out, info)
		}
	}
	return out, nil
}

func (s Service) GuildForPlayer(ctx context.Context, actor identity.ActorContext, pid identity.PlayerID) (GuildInfo, bool, error) {
	if err := s.validateDirectory(); err != nil {
		return GuildInfo{}, false, err
	}
	if !pid.Valid() {
		return GuildInfo{}, false, nil
	}
	m, ok, err := s.Store.ReadMembership(ctx, pid)
	if err != nil || !ok {
		return GuildInfo{}, false, err
	}
	return s.GuildInfo(ctx, actor, m.GuildID)
}

func (s Service) Other(ctx context.Context, actor identity.ActorContext, gid guild.ID) (SelfGuild, bool, error) {
	info, ok, err := s.GuildInfo(ctx, actor, gid)
	if err != nil || !ok {
		return SelfGuild{}, ok, err
	}
	return SelfGuild{GuildInfo: info, SelfRole: int16(guild.Member), JoinTime: 0, MemberNum: info.MemberNum}, true, nil
}

func (s Service) GuildRoom(ctx context.Context, actor identity.ActorContext) (int64, bool, error) {
	if err := s.validateStore(); err != nil {
		return 0, false, err
	}
	m, ok, err := s.Store.ReadMembership(ctx, actor.PlayerID)
	if err != nil || !ok {
		return 0, false, err
	}
	g, ok, err := s.Store.ReadGuild(ctx, m.GuildID)
	if err != nil || !ok {
		return 0, false, err
	}
	if g.RetiredAt != nil || g.LogicalServerID != actor.LogicalServerID {
		return 0, false, nil
	}
	return int64(g.ID), true, nil
}
