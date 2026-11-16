package guildcampaign

import (
	"context"
	"encoding/json"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/guild"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// serverRankPartnerLimit is the hero1..hero5 slot count of
// highest_damage_item.csb, which AllServerDamageWindow.lua:217-235 fills.
const serverRankPartnerLimit = 5

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
	Rank      int64
	Damage    int64
	Profile   ProfileView
	GuildID   int64
	GuildName string
	Partners  []Partner
}

// Partner is one stored formation slot of a 608 record, projected from the
// Character owner so AllServerDamageWindow.lua:217-235 can draw its avatar.
type Partner struct {
	TableID         int64
	Color           int64
	Star            int64
	Level           int64
	CurrentSkinID   int64
	TwiceAwakeStage int64
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
	GuildIcon int64
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
	Type       int64
	Profile    ProfileView
	MemberName string
	PlayerJob  int64
	ChapterID  int64
	At         time.Time
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
	var out Lists
	_, err := m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		at := op.StartedAt.UTC()
		membership, joined, err := m.Service.Guilds.ReadMembershipTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return err
		}
		if !joined {
			return nil
		}
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
	if !m.ready() {
		return nil, ErrUnavailable
	}
	if chapterID <= 0 {
		return nil, d.ErrRefused
	}
	var out []RankRow
	_, err := m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		membership, joined, err := m.Service.Guilds.ReadMembershipTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return err
		}
		if !joined {
			return nil
		}
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
	if !m.ready() || m.Roster == nil || m.Awakenings == nil {
		return ServerView{}, ErrUnavailable
	}
	if copyID <= 0 {
		return ServerView{}, d.ErrRefused
	}
	var out ServerView
	_, err := m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		guilds := map[int64]guild.Guild{}
		readGuild := func(id int64) (guild.Guild, bool, error) {
			if id <= 0 {
				return guild.Guild{}, false, nil
			}
			if known, cached := guilds[id]; cached {
				return known, true, nil
			}
			row, found, err := m.Service.Guilds.ReadGuildTx(c, sc.Tx, guild.ID(id))
			if err != nil || !found {
				return guild.Guild{}, false, err
			}
			guilds[id] = row
			return row, true, nil
		}
		rows, err := m.ModeStore.ListServerRecordsTx(c, sc.Tx, a.LogicalServerID, copyID, 100)
		if err != nil {
			return err
		}
		for index, row := range rows {
			profile, err := m.profileTx(c, sc.Tx, identity.PlayerID(row.PlayerID))
			if err != nil {
				continue
			}
			rank := ServerRankRow{Rank: int64(index + 1), Damage: row.Damage, Profile: profile, GuildID: row.GuildID}
			memberGuild, found, err := readGuild(row.GuildID)
			if err != nil {
				return err
			}
			if found {
				rank.GuildName = memberGuild.Name
			}
			rank.Partners, err = m.partnersTx(c, sc.Tx, identity.PlayerID(row.PlayerID), row.Partners)
			if err != nil {
				return err
			}
			out.Ranks = append(out.Ranks, rank)
		}
		kill, found, err := m.ModeStore.ServerKillReadTx(c, sc.Tx, a.LogicalServerID, copyID)
		if err != nil {
			return err
		}
		if !found {
			return nil
		}
		profile, err := m.profileTx(c, sc.Tx, identity.PlayerID(kill.FirstPlayerID))
		if err == nil {
			boss := &Killer{Profile: profile, GuildID: kill.FirstGuildID, At: kill.FirstAt}
			firstGuild, known, err := readGuild(kill.FirstGuildID)
			if err != nil {
				return err
			}
			if known {
				boss.GuildName = firstGuild.Name
			}
			out.Boss = boss
		}
		fast := &FastKiller{GuildID: kill.FastestGuild, Seconds: kill.FastestSecond, At: kill.FirstAt}
		fastGuild, known, err := readGuild(kill.FastestGuild)
		if err != nil {
			return err
		}
		if known {
			fast.GuildName = fastGuild.Name
			fast.GuildIcon = fastGuild.Icon
		}
		out.Fast = fast
		return nil
	})
	return out, err
}

// partnersTx projects the stored formation ids through the Character owner;
// a released hero has no display row and drops out.
func (m Mode) partnersTx(c context.Context, q tx.Queryer, player identity.PlayerID, stored []byte) ([]Partner, error) {
	if len(stored) == 0 {
		return nil, nil
	}
	var ids []int64
	if err := json.Unmarshal(stored, &ids); err != nil {
		return nil, err
	}
	slots := make([]int64, 0, serverRankPartnerLimit)
	for _, id := range ids {
		if id <= 0 {
			continue
		}
		slots = append(slots, id)
		if len(slots) == serverRankPartnerLimit {
			break
		}
	}
	if len(slots) == 0 {
		return nil, nil
	}
	heroes, err := m.Roster.ListHeroesTx(c, q, player)
	if err != nil {
		return nil, err
	}
	owned := make(map[int64]character.Hero, len(heroes))
	for _, hero := range heroes {
		owned[hero.PartnerID] = hero
	}
	awakenings, err := m.Awakenings.ListRawAwakeningsTx(c, q, player, slots)
	if err != nil {
		return nil, err
	}
	out := make([]Partner, 0, len(slots))
	for _, id := range slots {
		hero, found := owned[id]
		if !found {
			continue
		}
		row := Partner{TableID: hero.TableID, Color: hero.Color, Star: hero.Star, Level: hero.Level, CurrentSkinID: hero.CurrentSkinID}
		if raw, known := awakenings[id]; known {
			row.TwiceAwakeStage = raw.RawStage
		}
		out = append(out, row)
	}
	return out, nil
}

// GuildLog is 609, newest first and bounded by policy retention days.
func (m Mode) GuildLog(c context.Context, a identity.ActorContext, op operation.Context) ([]LogRow, error) {
	if !m.ready() {
		return nil, ErrUnavailable
	}
	var out []LogRow
	_, err := m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		membership, joined, err := m.Service.Guilds.ReadMembershipTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return err
		}
		if !joined {
			return nil
		}
		guildID := int64(membership.GuildID)
		cutoff := op.StartedAt.AddDate(0, 0, -int(m.Settings.RetentionDays))
		roles := map[identity.PlayerID]int64{}
		memberships, err := m.Service.Guilds.ListMembershipsTx(c, sc.Tx, guild.ID(guildID))
		if err != nil {
			return err
		}
		for _, member := range memberships {
			roles[member.PlayerID] = int64(member.Role)
		}
		rows, err := m.ModeStore.ListGuildLogTx(c, sc.Tx, guildID, cutoff, 100)
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
		members, err := m.Service.Guilds.ListMemberLogTx(c, sc.Tx, guildID, cutoff, 100)
		if err != nil {
			return err
		}
		for _, row := range members {
			kind, known := memberLogType(row.Kind, row.Role)
			if !known {
				continue
			}
			actor, err := m.profileTx(c, sc.Tx, identity.PlayerID(row.ActorID))
			if err != nil {
				continue
			}
			subject := ""
			if row.SubjectID != row.ActorID {
				if profile, err := m.profileTx(c, sc.Tx, identity.PlayerID(row.SubjectID)); err == nil {
					subject = profile.Name
				}
			}
			out = append(out, LogRow{Type: kind, Profile: actor, MemberName: subject, PlayerJob: roles[identity.PlayerID(row.ActorID)], At: row.At})
		}
		sort.SliceStable(out, func(i, j int) bool { return out[i].At.After(out[j].At) })
		if len(out) > 100 {
			out = out[:100]
		}
		return nil
	})
	return out, err
}

// memberLogType maps the membership audit kinds onto the client's log types.
// Kinds with no stock row (APPLY, CANCEL_APPLY, REFUSE_APPLY, INVITE, SETTINGS,
// DISSOLVE, BROADCAST) are not shown; 10 and 14 stay unemitted until drink or
// their source activates.
func memberLogType(kind string, role int64) (int64, bool) {
	switch kind {
	case "CREATE":
		return 1, true
	case "DESCRIPTION":
		return 2, true
	case "KICK":
		return 3, true
	case "JOIN", "ACCEPT_INVITE":
		return 4, true
	case "ACCEPT_APPLY":
		return 5, true
	case "LEAVE":
		return 6, true
	case "ROLE":
		switch role {
		case 1:
			return 11, true
		case 2:
			return 12, true
		case 0:
			return 13, true
		}
	}
	return 0, false
}

// MapDetail is 613.
func (m Mode) MapDetail(c context.Context, a identity.ActorContext, copyID int64, op operation.Context) (DetailView, error) {
	if !m.ready() {
		return DetailView{}, ErrUnavailable
	}
	if copyID <= 0 {
		return DetailView{}, d.ErrRefused
	}
	chapterID, known := m.Content.ChapterOfCopy(copyID)
	if !known {
		return DetailView{}, d.ErrRefused
	}
	var out DetailView
	_, err := m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		at := op.StartedAt.UTC()
		membership, joined, err := m.Service.Guilds.ReadMembershipTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return err
		}
		if !joined {
			return nil
		}
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
