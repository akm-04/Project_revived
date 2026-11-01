package guildcampaign

import (
	"context"
	"fmt"
	"sort"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// AwardMember is one apply_member row.
type AwardMember struct {
	Rank      int64
	Profile   ProfileView
	AppliedAt time.Time
}

// AwardInfo is one 605 award_infos row.
type AwardInfo struct {
	AwardID   int64
	AwardNum  int64
	SelfRank  int64
	SelfApply int64
	Members   []AwardMember
}

// AwardBody is the 605/606 reply body.
type AwardBody struct {
	Awards        []AwardInfo
	NextApplyTime int64
	SelfItemID    int64
	SelfRank      int64
	ApplyTimes    int64
}

// Distribution is one 615 row.
type Distribution struct {
	ItemID      int64
	PlayerName  string
	Distributed time.Time
}

// AwardRead is 605: the chapter's award pool, queue and the caller's place.
func (m Mode) AwardRead(c context.Context, a identity.ActorContext, chapterID int64, op operation.Context) (AwardBody, error) {
	if !m.ready() || chapterID <= 0 {
		return AwardBody{}, ErrUnavailable
	}
	membership, joined, err := m.Service.Guilds.ReadMembership(c, a.PlayerID)
	if err != nil {
		return AwardBody{}, err
	}
	if !joined {
		return AwardBody{}, ErrUnavailable
	}
	var out AwardBody
	_, err = m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{}, nil, func(c context.Context, sc tx.Scope) error {
		at := op.StartedAt.UTC()
		body, err := m.awardBody(c, sc.Tx, int64(membership.GuildID), chapterID, a.PlayerID, at)
		out = body
		return err
	})
	return out, err
}

// ApplyReward is 606: one application per run per member, four a day.
func (m Mode) ApplyReward(c context.Context, a identity.ActorContext, chapterID, awardID int64, op operation.Context) (AwardBody, error) {
	if !m.ready() || chapterID <= 0 || awardID <= 0 {
		return AwardBody{}, ErrUnavailable
	}
	guildID, err := m.guildOf(c, a)
	if err != nil {
		return AwardBody{}, ErrUnavailable
	}
	var out AwardBody
	_, err = m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc tx.Scope) error {
		at := op.StartedAt.UTC()
		if err := m.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		if _, err := m.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID}); err != nil {
			return err
		}
		chapter, open, err := m.Service.Store.LockChapterTx(c, sc.Tx, guildID, chapterID)
		if err != nil {
			return err
		}
		if !open || !chapter.Win {
			return ErrUnavailable
		}
		awards, err := m.ModeStore.ListAwardsTx(c, sc.Tx, guildID, chapterID, chapter.Run)
		if err != nil {
			return err
		}
		if !hasAward(awards, awardID) {
			return ErrUnavailable
		}
		day := modes.Day(at)
		applied, err := m.ModeStore.ApplicationCountTx(c, sc.Tx, a.PlayerID, day)
		if err != nil {
			return err
		}
		if applied >= m.Settings.ApplicationsPerDay {
			return ErrUnavailable
		}
		if err := m.ModeStore.ApplyTx(c, sc.Tx, guildID, chapterID, chapter.Run, a.PlayerID, awardID, at); err != nil {
			return err
		}
		if err := m.ModeStore.BumpApplicationCountTx(c, sc.Tx, a.PlayerID, day); err != nil {
			return err
		}
		body, err := m.awardBody(c, sc.Tx, guildID, chapterID, a.PlayerID, at)
		out = body
		return err
	})
	return out, err
}

func hasAward(awards []AwardRow, awardID int64) bool {
	for _, award := range awards {
		if award.AwardID == awardID && award.Remaining > 0 {
			return true
		}
	}
	return false
}

func (m Mode) awardBody(c context.Context, q tx.Queryer, guildID, chapterID int64, player identity.PlayerID, at time.Time) (AwardBody, error) {
	body := AwardBody{NextApplyTime: secondsUntil(m.nextSlot(at), at)}
	chapter, open, err := m.ModeStore.ReadChapterTx(c, q, guildID, chapterID)
	if err != nil {
		return body, err
	}
	if !open {
		return body, nil
	}
	awards, err := m.ModeStore.ListAwardsTx(c, q, guildID, chapterID, chapter.Run)
	if err != nil {
		return body, err
	}
	rows, err := m.ModeStore.ListDamageTx(c, q, guildID, chapterID, chapter.Run, 1000)
	if err != nil {
		return body, err
	}
	rank := map[identity.PlayerID]int64{}
	for index, row := range rows {
		rank[identity.PlayerID(row.PlayerID)] = int64(index + 1)
	}
	own, found, err := m.ModeStore.ApplicationTx(c, q, guildID, chapterID, chapter.Run, player)
	if err != nil {
		return body, err
	}
	applied, err := m.ModeStore.ApplicationCountTx(c, q, player, modes.Day(at))
	if err != nil {
		return body, err
	}
	body.ApplyTimes = applied
	body.SelfRank = rank[player]
	if found {
		body.SelfItemID = own.AwardID
	}
	for _, award := range awards {
		row := AwardInfo{AwardID: award.AwardID, AwardNum: award.Remaining, SelfRank: body.SelfRank}
		if found && own.AwardID == award.AwardID {
			row.SelfApply = 1
		}
		applications, err := m.ModeStore.ApplicationsByAwardTx(c, q, guildID, chapterID, chapter.Run)
		if err != nil {
			return body, err
		}
		for _, application := range applications {
			if application.AwardID != award.AwardID {
				continue
			}
			profile, err := m.profileTx(c, q, identity.PlayerID(application.PlayerID))
			if err != nil {
				continue
			}
			row.Members = append(row.Members, AwardMember{Rank: rank[identity.PlayerID(application.PlayerID)], Profile: profile, AppliedAt: application.AppliedAt})
		}
		body.Awards = append(body.Awards, row)
	}
	return body, nil
}

func secondsUntil(value, at time.Time) int64 {
	if !value.After(at) {
		return 0
	}
	return int64(value.Sub(at).Seconds())
}

// DistributeRecord is 615.
func (m Mode) DistributeRecord(c context.Context, a identity.ActorContext, op operation.Context) ([]Distribution, error) {
	if !m.ready() {
		return nil, ErrUnavailable
	}
	membership, joined, err := m.Service.Guilds.ReadMembership(c, a.PlayerID)
	if err != nil {
		return nil, err
	}
	if !joined {
		return nil, ErrUnavailable
	}
	var out []Distribution
	_, err = m.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{}, nil, func(c context.Context, sc tx.Scope) error {
		rows, err := m.ModeStore.ListDistributionsTx(c, sc.Tx, int64(membership.GuildID), 100)
		if err != nil {
			return err
		}
		for _, row := range rows {
			profile, err := m.profileTx(c, sc.Tx, identity.PlayerID(row.PlayerID))
			if err != nil {
				continue
			}
			out = append(out, Distribution{ItemID: row.ItemID, PlayerName: profile.Name, Distributed: row.Distributed})
		}
		return nil
	})
	return out, err
}

// Reconciler is C14's durable distributor. It scans due award rows and
// distributes one item per slot; no read path writes.
type Reconciler struct {
	Mode Mode
}

func (r Reconciler) Name() string { return "guild-campaign" }

func (r Reconciler) Reconcile(c context.Context, timed gen.TimedOperation, limit int) (gen.ReconcileResult, error) {
	out := gen.ReconcileResult{Provider: r.Name()}
	m := r.Mode
	if !m.ready() || m.Fresh == nil || limit < 1 || limit > gen.MaxReconcileBatch {
		return out, ErrUnavailable
	}
	at := timed.DecisionAt()
	due, err := m.ModeStore.ListDueAwardsTx(c, m.Fresh, at, limit)
	if err != nil {
		return out, err
	}
	out.Scanned = len(due)
	for _, award := range due {
		child, err := awardOperation(timed.Operation(), award)
		if err != nil {
			return out, err
		}
		settled := false
		_, _, err = m.Timed.Run(c, child, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
			now := sc.Operation.DecisionAt()
			locked, ok, err := m.ModeStore.LockAwardTx(c, sc.Tx, award)
			if err != nil || !ok {
				return err
			}
			applications, err := m.ModeStore.ApplicationsByAwardTx(c, sc.Tx, locked.GuildID, locked.ChapterID, locked.Run)
			if err != nil {
				return err
			}
			rows, err := m.ModeStore.ListDamageTx(c, sc.Tx, locked.GuildID, locked.ChapterID, locked.Run, 1000)
			if err != nil {
				return err
			}
			rank := map[identity.PlayerID]int{}
			for index, row := range rows {
				rank[identity.PlayerID(row.PlayerID)] = index + 1
			}
			chosen, found := chooseApplicant(applications, rank)
			locked.NextSlot = m.nextSlot(now)
			if !found {
				out.Noops++
				if err := m.ModeStore.SaveAwardTx(c, sc.Tx, locked); err != nil {
					return err
				}
				return nil
			}
			if locked.Remaining > 0 {
				locked.Remaining--
			}
			if err := m.ModeStore.SaveAwardTx(c, sc.Tx, locked); err != nil {
				return err
			}
			if err := m.ModeStore.InsertDistributionTx(c, sc.Tx, locked.GuildID, chosen, locked.AwardID, now); err != nil {
				return err
			}
			key := fmt.Sprintf("award:%d:%d:%d:%d:%d", locked.GuildID, locked.ChapterID, locked.Run, locked.AwardID, locked.Remaining)
			request := i5.SettlementMailRequest{Recipient: chosen, SourceKind: awardSource, SourceKey: key, Title: "Guild Campaign award",
				Sender: "Guild", Body: "A Guild Campaign award was distributed to you.", PolicyVersion: payoutPolicy,
				Lines: []grant.Line{{Kind: grant.StackItem, ItemID: locked.AwardID, Amount: 1}}, At: now}
			if _, _, err := m.Mail.DeliverTx(c, sc.Tx, request); err != nil {
				return err
			}
			settled = true
			return nil
		})
		if err != nil {
			return out, err
		}
		if settled {
			out.Settled++
		}
	}
	return out, nil
}

func chooseApplicant(applications []ApplicationRow, rank map[identity.PlayerID]int) (identity.PlayerID, bool) {
	if len(applications) == 0 {
		return 0, false
	}
	sort.SliceStable(applications, func(i, j int) bool {
		left, right := rank[identity.PlayerID(applications[i].PlayerID)], rank[identity.PlayerID(applications[j].PlayerID)]
		if left == 0 {
			left = 1 << 30
		}
		if right == 0 {
			right = 1 << 30
		}
		if left != right {
			return left < right
		}
		return applications[i].AppliedAt.Before(applications[j].AppliedAt)
	})
	return identity.PlayerID(applications[0].PlayerID), true
}

func awardOperation(parent operation.Context, award AwardRow) (operation.Context, error) {
	id, err := ids.NewUUID()
	if err != nil {
		return operation.Context{}, err
	}
	return operation.Context{ID: id, StartedAt: parent.StartedAt,
		EntropySeed: parent.Derive(fmt.Sprintf("guildcampaign:award:%d:%d:%d:%d", award.GuildID, award.ChapterID, award.Run, award.AwardID), 0),
		Policies:    parent.Policies}, nil
}
