// Package guildcampaign is the application owner of I9_GUILD_CAMPAIGN_V1.
package guildcampaign

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/guild"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	policyVersion = "I9_GUILD_POLICY_V1"
	noticeSource  = "GUILD_CAMPAIGN_NOTICE"
)

// CopySeed is a copy's full-health first state, from content.
type CopySeed struct {
	CopyID int64
	Waves  json.RawMessage
}

// ChapterDefinition is team_dungeon_select and team_campaign. Previous is 0 for the first chapter.
type ChapterDefinition struct {
	ChapterID int64
	Previous  int64
	OpenCost  int64
	Copies    []CopySeed
}

type Catalog interface {
	ChapterTx(context.Context, tx.Queryer, int64) (ChapterDefinition, bool, error)
}

type NoticeMail struct {
	Enabled    bool
	OpenTitle  string
	OpenBody   string
	ResetTitle string
	ResetBody  string
	Sender     string
}

type Guilds interface {
	ReadMembership(context.Context, identity.PlayerID) (guild.Membership, bool, error)
	LockGuildTx(context.Context, tx.Tx, guild.ID) (guild.Guild, bool, error)
	LockMembershipTx(context.Context, tx.Tx, identity.PlayerID) (guild.Membership, bool, error)
	ListMembershipsTx(context.Context, tx.Queryer, guild.ID) ([]guild.Membership, error)
	SaveGuildTx(context.Context, tx.Tx, guild.Guild, int64) error
	FoldActivityTx(context.Context, tx.Tx, []identity.PlayerID) (int64, error)
	FoldActivityAwardsTx(context.Context, tx.Tx, guild.ID) (int64, error)
}

type Store interface {
	LockChapterTx(context.Context, tx.Tx, int64, int64) (d.Chapter, bool, error)
	ChapterWonTx(context.Context, tx.Queryer, int64, int64) (bool, error)
	LockGuildChaptersTx(context.Context, tx.Tx, int64) ([]int64, error)
	LockChapterCopiesTx(context.Context, tx.Tx, int64, int64) error
	BeginRunTx(context.Context, tx.Tx, d.Chapter, []d.Copy, []identity.PlayerID) error
	ListRegisteredTx(context.Context, tx.Queryer, int64, int64) ([]identity.PlayerID, error)
	RemoveMemberTx(context.Context, tx.Tx, int64, identity.PlayerID) error
	DeleteGuildTx(context.Context, tx.Tx, int64) error
	AppendLogTx(context.Context, tx.Tx, int64, int64, identity.PlayerID, int64, time.Time) error
}

// RunPayout pays a run's registered members once (C12). It may only take locks
// at rank 610 for those members: open and reset fold activity at 723 after it.
type RunPayout interface {
	PayRunTx(context.Context, tx.Tx, d.Chapter, []identity.PlayerID, time.Time) error
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Mail interface {
	DeliverNoticeTx(context.Context, tx.Tx, i5.SettlementMailRequest) (mail.Record, bool, error)
}

type Service struct {
	Runner  tx.Runner
	Store   Store
	Guilds  Guilds
	Catalog Catalog
	Payout  RunPayout
	Mail    Mail
	Fence   Fence
	Players playerroot.TxLocker
	Notice  NoticeMail
}

func (s Service) validate() error {
	if s.Store == nil || s.Guilds == nil || s.Catalog == nil || s.Payout == nil || s.Mail == nil || s.Fence == nil || s.Players == nil {
		return errors.New("guildcampaign: service incomplete")
	}
	return nil
}

// Open is 611. It returns the guild's activity balance after the spend.
func (s Service) Open(c context.Context, a identity.ActorContext, chapterID int64, op operation.Context) (int64, error) {
	return s.beginRun(c, a, chapterID, false, op)
}

// Reset is 602: it pays the current run and starts another.
func (s Service) Reset(c context.Context, a identity.ActorContext, chapterID int64, op operation.Context) (int64, error) {
	return s.beginRun(c, a, chapterID, true, op)
}

// beginRun holds C2's order: fence 315, guild 310, root, membership 320, chapter
// 606, copies 607, mail 610, activity 723. The fold comes last because nothing
// may follow 723, so the spend is decided after the mail; a refusal rolls it back.
func (s Service) beginRun(c context.Context, a identity.ActorContext, chapterID int64, reset bool, op operation.Context) (int64, error) {
	if err := s.validate(); err != nil {
		return 0, err
	}
	hint, joined, err := s.Guilds.ReadMembership(c, a.PlayerID)
	if err != nil {
		return 0, err
	}
	if !joined {
		return 0, d.ErrRefused
	}
	var balance int64
	_, err = s.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, sc tx.Scope) error {
		at := op.StartedAt.UTC()
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		g, members, err := s.lockOfficer(c, sc.Tx, a, hint.GuildID)
		if err != nil {
			return err
		}
		guildID := int64(g.ID)
		definition, known, err := s.Catalog.ChapterTx(c, sc.Tx, chapterID)
		if err != nil {
			return err
		}
		if !known {
			return d.ErrRefused
		}
		current, open, err := s.Store.LockChapterTx(c, sc.Tx, guildID, chapterID)
		if err != nil {
			return err
		}
		next, err := s.admitRun(c, sc.Tx, guildID, definition, current, open, reset)
		if err != nil {
			return err
		}
		if open {
			if err := s.Store.LockChapterCopiesTx(c, sc.Tx, guildID, chapterID); err != nil {
				return err
			}
			registered, err := s.Store.ListRegisteredTx(c, sc.Tx, guildID, chapterID)
			if err != nil {
				return err
			}
			if err := s.Payout.PayRunTx(c, sc.Tx, current, registered, at); err != nil {
				return err
			}
		}
		chapter := d.Chapter{GuildID: guildID, ChapterID: chapterID, Run: next, StartTime: at}
		copies := make([]d.Copy, 0, len(definition.Copies))
		for _, seed := range definition.Copies {
			copies = append(copies, d.Copy{CopyID: seed.CopyID, Waves: seed.Waves})
		}
		if err := s.Store.BeginRunTx(c, sc.Tx, chapter, copies, members); err != nil {
			return err
		}
		logType := d.LogOpenChapter
		if reset {
			logType = d.LogResetChapter
		}
		if err := s.Store.AppendLogTx(c, sc.Tx, guildID, logType, a.PlayerID, chapterID, at); err != nil {
			return err
		}
		if err := s.noticeTx(c, sc.Tx, chapter, reset, members, at); err != nil {
			return err
		}
		balance, err = s.spendTx(c, sc.Tx, g, members, definition.OpenCost, at)
		return err
	})
	if err != nil {
		return 0, err
	}
	return balance, nil
}

// lockOfficer takes guild 310, the actor's root and membership 320, and returns
// the guild's members in player order. Only a leader or deputy passes (C3).
func (s Service) lockOfficer(c context.Context, t tx.Tx, a identity.ActorContext, id guild.ID) (guild.Guild, []identity.PlayerID, error) {
	g, found, err := s.Guilds.LockGuildTx(c, t, id)
	if err != nil {
		return guild.Guild{}, nil, err
	}
	if !found || g.RetiredAt != nil || g.LogicalServerID != a.LogicalServerID {
		return guild.Guild{}, nil, d.ErrRefused
	}
	if _, err := s.Players.LockPlayerRootsTx(c, t, a.LogicalServerID, []identity.PlayerID{a.PlayerID}); err != nil {
		return guild.Guild{}, nil, err
	}
	actor, joined, err := s.Guilds.LockMembershipTx(c, t, a.PlayerID)
	if err != nil {
		return guild.Guild{}, nil, err
	}
	if !joined || actor.GuildID != id || actor.Role != guild.Leader && actor.Role != guild.Deputy {
		return guild.Guild{}, nil, d.ErrRefused
	}
	memberships, err := s.Guilds.ListMembershipsTx(c, t, id)
	if err != nil {
		return guild.Guild{}, nil, err
	}
	members := make([]identity.PlayerID, 0, len(memberships))
	for _, membership := range memberships {
		members = append(members, membership.PlayerID)
	}
	sort.Slice(members, func(i, j int) bool { return members[i] < members[j] })
	return g, members, nil
}

// admitRun returns the new run number. Open needs a closed chapter whose
// predecessor is won; reset needs an open chapter with damage on it.
func (s Service) admitRun(c context.Context, t tx.Tx, guildID int64, definition ChapterDefinition, current d.Chapter, open, reset bool) (int64, error) {
	if reset {
		if !open || current.Percent <= 0 {
			return 0, d.ErrRefused
		}
		return current.Run + 1, nil
	}
	if open {
		return 0, d.ErrRefused
	}
	if definition.Previous == 0 {
		return 1, nil
	}
	won, err := s.Store.ChapterWonTx(c, t, guildID, definition.Previous)
	if err != nil {
		return 0, err
	}
	if !won {
		return 0, d.ErrRefused
	}
	return 1, nil
}

func (s Service) noticeTx(c context.Context, t tx.Tx, chapter d.Chapter, reset bool, members []identity.PlayerID, at time.Time) error {
	if !s.Notice.Enabled {
		return nil
	}
	title, body := s.Notice.OpenTitle, s.Notice.OpenBody
	if reset {
		title, body = s.Notice.ResetTitle, s.Notice.ResetBody
	}
	key := fmt.Sprintf("%d:%d:%d", chapter.GuildID, chapter.ChapterID, chapter.Run)
	for _, member := range members {
		request := i5.SettlementMailRequest{Recipient: member, SourceKind: noticeSource, SourceKey: key, Title: title, Sender: s.Notice.Sender, Body: body, PolicyVersion: policyVersion, At: at}
		if _, _, err := s.Mail.DeliverNoticeTx(c, t, request); err != nil {
			return err
		}
	}
	return nil
}

// spendTx folds every member's credit and the guild's awards at 723, clamps, and
// spends the chapter's cost from the result (I9_GUILD_ACTIVITY_V1 C5, C8).
func (s Service) spendTx(c context.Context, t tx.Tx, g guild.Guild, members []identity.PlayerID, cost int64, at time.Time) (int64, error) {
	credited, err := s.Guilds.FoldActivityTx(c, t, members)
	if err != nil {
		return 0, err
	}
	awarded, err := s.Guilds.FoldActivityAwardsTx(c, t, g.ID)
	if err != nil {
		return 0, err
	}
	balance := guild.ActivityBalance(g.Vitality, credited+awarded)
	if balance < cost {
		return 0, d.ErrRefused
	}
	old := g.StateVersion
	g.Vitality = balance - cost
	g.StateVersion++
	g.UpdatedAt = at
	return g.Vitality, s.Guilds.SaveGuildTx(c, t, g, old)
}

// RemoveMemberTx forfeits a leaver's registrations inside the guild's leave or
// kick transaction, at rank 606 under guild 310 and membership 320 (C2, C4).
func (s Service) RemoveMemberTx(c context.Context, t tx.Tx, id guild.ID, player identity.PlayerID) error {
	if err := s.validate(); err != nil {
		return err
	}
	if _, err := s.Store.LockGuildChaptersTx(c, t, int64(id)); err != nil {
		return err
	}
	return s.Store.RemoveMemberTx(c, t, int64(id), player)
}

// CloseGuildTx ends a dissolved guild's chapters. Its copies follow by cascade, in
// the transaction that holds the guild; a late result finds no copy and gets 30021.
func (s Service) CloseGuildTx(c context.Context, t tx.Tx, id guild.ID) error {
	if err := s.validate(); err != nil {
		return err
	}
	chapters, err := s.Store.LockGuildChaptersTx(c, t, int64(id))
	if err != nil {
		return err
	}
	for _, chapter := range chapters {
		if err := s.Store.LockChapterCopiesTx(c, t, int64(id), chapter); err != nil {
			return err
		}
	}
	return s.Store.DeleteGuildTx(c, t, int64(id))
}
