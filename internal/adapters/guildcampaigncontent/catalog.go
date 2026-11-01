// Package guildcampaigncontent adapts the embedded Guild Campaign catalog to
// the application owner's ports (content may not depend on application).
package guildcampaigncontent

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/application/guildcampaign"
	"gxb.local/backend/v2/internal/content/guildcampaigncatalog"
	"gxb.local/backend/v2/internal/content/guildcampaignpolicy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Catalog struct{ Installed guildcampaigncatalog.Catalog }

// Settings maps the immutable policy and misc tables to the application owner.
func Settings(policy guildcampaignpolicy.Policy, settings guildcampaigncatalog.Settings) guildcampaign.Settings {
	return guildcampaign.Settings{
		AttemptsPerChapterDay: policy.AttemptsPerChapterDay,
		PrepareSeconds:        policy.PrepareSeconds,
		BattleSeconds:         policy.BattleSeconds,
		RestSecondsOfDay:      policy.RestSecondsOfDay,
		ApplicationsPerDay:    policy.ApplicationsPerDay,
		BossRankFactor:        policy.BossDamageRankFactor,
		RetentionDays:         policy.GuildLogRetentionDays,
		RewardHurtRank:        settings.RewardHurtRank,
		DistRewardTime:        settings.DistRewardTime,
		RewardParamPerMille:   settings.RewardParamPerMile,
		RewardTimeLimitSecond: settings.RewardTimeLimit,
		RecordRewardCrystal:   settings.FirstRewardDiamond,
		RecordRewardBadge:     settings.FirstRewardCoin,
		LastStrikeCoin:        policy.LastStrikeCoin,
		MaxFightDamage:        policy.MaxFightDamage,
	}
}

// ChapterInfos returns every chapter's application view keyed by id.
func (c Catalog) ChapterInfos() map[int64]guildcampaign.ChapterInfo {
	out := map[int64]guildcampaign.ChapterInfo{}
	for _, chapter := range c.Installed.Chapters {
		info, _ := c.ChapterInfo(chapter.ChapterID)
		out[chapter.ChapterID] = info
	}
	return out
}

var _ guildcampaign.Catalog = Catalog{}
var _ guildcampaign.Content = Catalog{}

func (c Catalog) ChapterTx(_ context.Context, q tx.Queryer, chapterID int64) (guildcampaign.ChapterDefinition, bool, error) {
	if q == nil {
		return guildcampaign.ChapterDefinition{}, false, errors.New("guild campaign catalog: no transaction")
	}
	chapter, known := c.Installed.Chapter(chapterID)
	if !known {
		return guildcampaign.ChapterDefinition{}, false, nil
	}
	copies := make([]guildcampaign.CopySeed, 0, len(chapter.Copies))
	for _, copy := range chapter.Copies {
		waves, err := json.Marshal(copy.Waves)
		if err != nil {
			return guildcampaign.ChapterDefinition{}, false, err
		}
		copies = append(copies, guildcampaign.CopySeed{CopyID: copy.CopyID, Waves: waves})
	}
	return guildcampaign.ChapterDefinition{ChapterID: chapter.ChapterID, Previous: chapter.Previous, OpenCost: chapter.OpenCost, Copies: copies}, true, nil
}

func (c Catalog) ChapterInfo(chapterID int64) (guildcampaign.ChapterInfo, bool) {
	chapter, known := c.Installed.Chapter(chapterID)
	if !known {
		return guildcampaign.ChapterInfo{}, false
	}
	info := guildcampaign.ChapterInfo{ChapterID: chapter.ChapterID, Previous: chapter.Previous, OpenCost: chapter.OpenCost,
		CoinReward: chapter.CoinReward, AdditionReward: chapter.AdditionReward, Items: append([]int64(nil), chapter.Items...)}
	for _, copy := range chapter.Copies {
		info.Copies = append(info.Copies, copy.CopyID)
	}
	return info, true
}

func (c Catalog) CopyInfo(chapterID, copyID int64) (guildcampaign.CopyInfo, bool) {
	copy, known := c.Installed.Copy(chapterID, copyID)
	if !known {
		return guildcampaign.CopyInfo{}, false
	}
	info := guildcampaign.CopyInfo{CopyID: copy.CopyID, FightID: copy.FightID, Waves: map[int64][]guildcampaign.EnemyRow{}}
	for wave, enemies := range copy.Waves {
		number := int64(0)
		for index := 0; index < len(wave); index++ {
			if wave[index] >= '1' && wave[index] <= '9' {
				number = int64(wave[index] - '0')
				break
			}
		}
		rows := make([]guildcampaign.EnemyRow, 0, len(enemies))
		for _, enemy := range enemies {
			rows = append(rows, guildcampaign.EnemyRow{TableID: enemy.TableID, Lev: enemy.Lev, Star: enemy.Star, Color: enemy.Color, Health: enemy.Health})
		}
		info.Waves[number] = rows
	}
	return info, true
}

func (c Catalog) ChapterOfCopy(copyID int64) (int64, bool) {
	for _, chapter := range c.Installed.Chapters {
		for _, copy := range chapter.Copies {
			if copy.CopyID == copyID {
				return chapter.ChapterID, true
			}
		}
	}
	return 0, false
}
