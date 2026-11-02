package guildcampaign

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/guild"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ChapterRow is one 601 chapter_list entry.
type ChapterRow struct {
	ChapterID      int64
	IsOpen         bool
	IsWin          bool
	HaveWin        bool
	Percent        float64
	StartTime      int64
	EndTime        int64
	ChallengeTimes int64
	ChapterVersion int64
	OpenCost       int64
}

// CopyRowView is one 603 copy_list entry.
type CopyRowView struct {
	CopyID  int64
	IsOpen  bool
	IsWin   bool
	Percent float64
}

// Lists is 601 and 603's shared body.
type Lists struct {
	Chapters []ChapterRow
	Copies   []CopyRowView
}

// RankRow is one 607 row.
type RankRow struct {
	Rank    int64
	Damage  int64
	Profile ProfileView
}

// ServerRankRow is one 608 rank row.
type ServerRankRow struct {
	Rank    int64
	Damage  int64
	Profile ProfileView
}

// Killer is 608's boss_killer row.
type Killer struct {
	Profile   ProfileView
	GuildID   int64
	GuildName string
	At        time.Time
}

// FastKiller is 608's fast_boss_killer row.
type FastKiller struct {
	GuildID   int64
	GuildName string
	Seconds   int64
	At        time.Time
}

// ServerView is 608.
type ServerView struct {
	Fast  *FastKiller
	Boss  *Killer
	Ranks []ServerRankRow
}

// LogRow is one 609 row.
type LogRow struct {
	Type      int64
	Profile   ProfileView
	PlayerJob int64
	ChapterID int64
	At        time.Time
}

// DetailView is 613.
type DetailView struct {
	CopyID       int64
	ChapterID    int64
	CurrentIndex int64
	Waves        map[int64][]EnemyRow
	IsOpen       bool
	IsWin        bool
	CurrentFight int64
	Stage        int64
	LastFight    int64
	StartFight   int64
	FightInfo    ProfileView
}

// CampaignLists is 601: every catalog chapter with this guild's state.
func (m Mode) CampaignLists(c context.Context, a identity.ActorContext, op operation.Context) (Lists, error) {
	return m.lists(c, a, op, false)
}

// GuildMap is 603: the chapter list plus the copy_list object source rows.
func (m Mode) GuildMap(c context.Context, a identity.ActorContext, op operation.Context) (Lists, error) {
	return m.lists(c, a, op, true)
}

func (m Mode) lists(c context.Context, a identity.ActorContext, op operation.Context, copies bool) (Lists, error) {
	if !m.ready() {
		return Lists{}, ErrUnavailable
	}
	membership, joined, err := m.Service.Guilds.ReadMembership(c, a.PlayerID)
	if err != nil {
		return Lists{}, err
	}
	if !joined {
		return Lists{}, nil
	}
	var out Lists
	_, err = m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		at := op.StartedAt.UTC()
		guildID := int64(membership.GuildID)
		for _, info := range sortedChapters(m.Tables) {
			chapter, open, err := m.ModeStore.ReadChapterTx(c, sc.Tx, guildID, info.ChapterID)
			if err != nil {
				return err
			}
			row := ChapterRow{ChapterID: info.ChapterID, OpenCost: info.OpenCost, ChapterVersion: 1}
			if open {
				row.IsOpen = true
				row.IsWin = chapter.Win
				row.HaveWin = chapter.Win
				row.Percent = chapter.Percent
				row.StartTime = chapter.StartTime.Unix()
				if chapter.EndTime != nil {
					row.EndTime = chapter.EndTime.Unix()
				}
				row.ChallengeTimes, err = m.ModeStore.MemberClearsTx(c, sc.Tx, a.PlayerID, info.ChapterID, modes.Day(at))
				if err != nil {
					return err
				}
			}
			out.Chapters = append(out.Chapters, row)
			if !copies || !open {
				continue
			}
			stored, err := m.ModeStore.ListCopiesTx(c, sc.Tx, guildID, info.ChapterID)
			if err != nil {
				return err
			}
			for _, copy := range stored {
				out.Copies = append(out.Copies, CopyRowView{CopyID: copy.CopyID, IsOpen: !copy.Win, IsWin: copy.Win, Percent: copy.Percent})
			}
		}
		return nil
	})
	return out, err
}

func sortedChapters(tables map[int64]ChapterInfo) []ChapterInfo {
	out := make([]ChapterInfo, 0, len(tables))
	for _, info := range tables {
		out = append(out, info)
	}
	for i := 1; i < len(out); i++ {
		for j := i; j > 0 && out[j].ChapterID < out[j-1].ChapterID; j-- {
			out[j], out[j-1] = out[j-1], out[j]
		}
	}
	return out
}

// DamageRank is 607.
func (m Mode) DamageRank(c context.Context, a identity.ActorContext, chapterID int64, op operation.Context) ([]RankRow, error) {
	if !m.ready() || chapterID <= 0 {
		return nil, ErrUnavailable
	}
	membership, joined, err := m.Service.Guilds.ReadMembership(c, a.PlayerID)
	if err != nil {
		return nil, err
	}
	if !joined {
		return nil, nil
	}
	var out []RankRow
	_, err = m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		guildID := int64(membership.GuildID)
		chapter, open, err := m.ModeStore.ReadChapterTx(c, sc.Tx, guildID, chapterID)
		if err != nil {
			return err
		}
		if !open {
			return nil
		}
		rows, err := m.ModeStore.ListDamageTx(c, sc.Tx, guildID, chapterID, chapter.Run, 100)
		if err != nil {
			return err
		}
		for index, row := range rows {
			profile, err := m.profileTx(c, sc.Tx, identity.PlayerID(row.PlayerID))
			if err != nil {
				continue
			}
			out = append(out, RankRow{Rank: int64(index + 1), Damage: row.Damage, Profile: profile})
		}
		return nil
	})
	return out, err
}

// AllServerRank is 608, scoped to the logical server.
func (m Mode) AllServerRank(c context.Context, a identity.ActorContext, copyID int64, op operation.Context) (ServerView, error) {
	if !m.ready() || copyID <= 0 {
		return ServerView{}, ErrUnavailable
	}
	var out ServerView
	_, err := m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		rows, err := m.ModeStore.ListServerRecordsTx(c, sc.Tx, a.LogicalServerID, copyID, 100)
		if err != nil {
			return err
		}
		for index, row := range rows {
			profile, err := m.profileTx(c, sc.Tx, identity.PlayerID(row.PlayerID))
			if err != nil {
				continue
			}
			out.Ranks = append(out.Ranks, ServerRankRow{Rank: int64(index + 1), Damage: row.Damage, Profile: profile})
		}
		kill, found, err := m.ModeStore.ServerKillReadTx(c, sc.Tx, a.LogicalServerID, copyID)
		if err != nil {
			return err
		}
		if found {
			profile, err := m.profileTx(c, sc.Tx, identity.PlayerID(kill.FirstPlayerID))
			if err == nil {
				out.Boss = &Killer{Profile: profile, GuildID: kill.FirstGuildID, At: kill.FirstAt}
			}
			out.Fast = &FastKiller{GuildID: kill.FastestGuild, Seconds: kill.FastestSecond, At: kill.FirstAt}
		}
		return nil
	})
	return out, err
}

// GuildLog is 609, newest first and bounded by policy retention days.
func (m Mode) GuildLog(c context.Context, a identity.ActorContext, op operation.Context) ([]LogRow, error) {
	if !m.ready() {
		return nil, ErrUnavailable
	}
	membership, joined, err := m.Service.Guilds.ReadMembership(c, a.PlayerID)
	if err != nil {
		return nil, err
	}
	if !joined {
		return nil, nil
	}
	var out []LogRow
	_, err = m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		guildID := int64(membership.GuildID)
		roles := map[identity.PlayerID]int64{}
		memberships, err := m.Service.Guilds.ListMembershipsTx(c, sc.Tx, guild.ID(guildID))
		if err != nil {
			return err
		}
		for _, member := range memberships {
			roles[member.PlayerID] = int64(member.Role)
		}
		rows, err := m.ModeStore.ListGuildLogTx(c, sc.Tx, guildID, op.StartedAt.AddDate(0, 0, -int(m.Settings.RetentionDays)), 100)
		if err != nil {
			return err
		}
		for _, row := range rows {
			profile, err := m.profileTx(c, sc.Tx, identity.PlayerID(row.PlayerID))
			if err != nil {
				continue
			}
			out = append(out, LogRow{Type: row.Type, Profile: profile, PlayerJob: roles[identity.PlayerID(row.PlayerID)], ChapterID: row.ChapterID, At: row.At})
		}
		return nil
	})
	return out, err
}

// MapDetail is 613.
func (m Mode) MapDetail(c context.Context, a identity.ActorContext, copyID int64, op operation.Context) (DetailView, error) {
	if !m.ready() || copyID <= 0 {
		return DetailView{}, ErrUnavailable
	}
	chapterID, known := m.Content.ChapterOfCopy(copyID)
	if !known {
		return DetailView{}, d.ErrRefused
	}
	membership, joined, err := m.Service.Guilds.ReadMembership(c, a.PlayerID)
	if err != nil {
		return DetailView{}, err
	}
	if !joined {
		return DetailView{}, nil
	}
	var out DetailView
	_, err = m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		at := op.StartedAt.UTC()
		guildID := int64(membership.GuildID)
		chapter, open, err := m.ModeStore.ReadChapterTx(c, sc.Tx, guildID, chapterID)
		if err != nil {
			return err
		}
		copy, found, err := m.ModeStore.ReadCopyTx(c, sc.Tx, guildID, chapterID, copyID)
		if err != nil || !found {
			return err
		}
		waves, err := decodeWaves(copy.Waves)
		if err != nil {
			return err
		}
		view := DetailView{CopyID: copyID, ChapterID: chapterID, CurrentIndex: currentIndex(copy), Waves: waves,
			IsOpen: open && !chapter.Win, IsWin: copy.Win, Stage: copy.HolderStage}
		if copy.LastFightTime != nil {
			view.LastFight = copy.LastFightTime.Unix()
		}
		if copy.StartFightTime != nil {
			view.StartFight = copy.StartFightTime.Unix()
		}
		if holderLive(copy, m.Settings, at) {
			view.CurrentFight = copy.HolderID
			view.FightInfo, _ = m.profileTx(c, sc.Tx, identity.PlayerID(copy.HolderID))
		}
		out = view
		return nil
	})
	return out, err
}
