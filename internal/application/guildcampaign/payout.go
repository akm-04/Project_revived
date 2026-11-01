package guildcampaign

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	payoutTitle  = "Guild Campaign reward"
	payoutBody   = "Your guild's Guild Campaign progress has been settled."
	payoutPolicy = "I9_GUILD_CAMPAIGN_V1"
)

// Payout is C12's once-per-run settlement: registered members only, by damage
// rank, through SettlementMail (rank 610) with a source key per run.
type Payout struct {
	Store    ModeStore
	Mail     Mailer
	Settings Settings
	Tables   map[int64]ChapterInfo
}

var _ RunPayout = Payout{}

func (p Payout) PayRunTx(c context.Context, t tx.Tx, chapter d.Chapter, registered []identity.PlayerID, at time.Time) error {
	if p.Store == nil || p.Mail == nil || len(registered) == 0 {
		return nil
	}
	info, known := p.chapterInfo(chapter.ChapterID)
	if !known {
		return nil
	}
	rows, err := p.Store.ListDamageTx(c, t, chapter.GuildID, chapter.ChapterID, chapter.Run, 1000)
	if err != nil {
		return err
	}
	rank := map[identity.PlayerID]int{}
	for index, row := range rows {
		rank[identity.PlayerID(row.PlayerID)] = index + 1
	}
	withinLimit := chapter.Win && chapter.EndTime != nil && at.Sub(chapter.StartTime) <= time.Duration(p.Settings.RewardTimeLimitSecond)*time.Second
	for _, member := range registered {
		lines := p.lines(info, chapter, rank[member], withinLimit)
		if len(lines) == 0 {
			continue
		}
		key := fmt.Sprintf("%d:%d:%d", chapter.GuildID, chapter.ChapterID, chapter.Run)
		request := i5.SettlementMailRequest{Recipient: member, SourceKind: payoutSource, SourceKey: key, Title: payoutTitle, Sender: "Guild",
			Body: payoutBody, PolicyVersion: payoutPolicy, Lines: lines, At: at}
		if _, _, err := p.Mail.DeliverTx(c, t, request); err != nil {
			return err
		}
	}
	return nil
}

func (p Payout) chapterInfo(chapterID int64) (ChapterInfo, bool) {
	info, known := p.Tables[chapterID]
	return info, known
}

// lines is C12: rule 14 Guild Coin by progress, rule 9/16 badge with the
// 7-day bonus, rule 10 rank bonus; a member owed nothing is skipped.
func (p Payout) lines(info ChapterInfo, chapter d.Chapter, rank int, withinLimit bool) []grant.Line {
	progress := chapter.Percent
	if progress < 0 {
		progress = 0
	}
	if progress > 1 {
		progress = 1
	}
	coin := int64(float64(info.CoinReward) * progress)
	badge := coin
	if withinLimit {
		badge += info.AdditionReward
	}
	if chapter.Win && rank > 0 && rank <= len(p.Settings.RewardHurtRank) {
		badge += p.Settings.RewardHurtRank[rank-1]
	}
	lines := []grant.Line{}
	if coin > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: dungeonCoinResource, Amount: coin})
	}
	if badge > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: guildCoinResource, Amount: badge})
	}
	return lines
}
