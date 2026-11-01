// Package guildcampaigncatalog is the immutable Guild Campaign content: chapters,
// copies and their three enemy waves, compiled from the hash-bound client tables
// by tools/guild_campaign_catalog.py. It implements guildcampaign.Catalog.
package guildcampaigncatalog

import (
	"crypto/sha256"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"errors"
	"sync"
)

//go:embed generated/guild_campaign_catalog.json
var builtinJSON []byte

// Enemy is one wave member at the seeded state; full HP is health 0 with no hp.
type Enemy struct {
	TableID int64 `json:"table_id"`
	Lev     int64 `json:"lev"`
	Star    int64 `json:"star"`
	Color   int64 `json:"color"`
	Health  int64 `json:"health"`
}

// Copy is one mission of a chapter; Waves is keyed "1".."3".
type Copy struct {
	CopyID  int64              `json:"copy_id"`
	FightID int64              `json:"fight_id"`
	Waves   map[string][]Enemy `json:"waves"`
}

type Chapter struct {
	ChapterID      int64   `json:"chapter_id"`
	Previous       int64   `json:"previous"`
	OpenCost       int64   `json:"open_cost"`
	CoinReward     int64   `json:"coin_reward"`
	AdditionReward int64   `json:"addition_reward"`
	Items          []int64 `json:"items"`
	Copies         []Copy  `json:"copies"`
}

// Settings are the server-only reward and schedule tables of misc.lua.
type Settings struct {
	RewardHurtRank       []int64 `json:"reward_hurt_rank"`
	DistRewardTime       []int64 `json:"dist_reward_time"`
	RewardParamPerMile   int64   `json:"reward_param_per_mille"`
	RewardTimeLimit      int64   `json:"reward_time_limit_seconds"`
	FirstRewardDiamond   int64   `json:"first_reward_diamond"`
	FirstRewardCoin      int64   `json:"first_reward_coin"`
	SourceSelectSHA256   string  `json:"source_select_sha256"`
	SourceCampaignSHA256 string  `json:"source_campaign_sha256"`
	SourceMiscSHA256     string  `json:"source_misc_sha256"`
}

type Catalog struct {
	SchemaVersion int       `json:"schema_version"`
	CampaignType  int64     `json:"campaign_type"`
	Chapters      []Chapter `json:"chapters"`
	Settings
}

type Builtin struct {
	Catalog  Catalog
	Revision string
}

var loaded sync.Once
var cached Builtin
var cachedErr error

func LoadBuiltin() (Builtin, error) {
	loaded.Do(func() {
		if err := json.Unmarshal(builtinJSON, &cached.Catalog); err != nil {
			cachedErr = err
			return
		}
		if err := cached.Catalog.Validate(); err != nil {
			cachedErr = err
			return
		}
		sum := sha256.Sum256(builtinJSON)
		cached.Revision = hex.EncodeToString(sum[:])
	})
	return cached, cachedErr
}

func (c Catalog) Validate() error {
	if c.SchemaVersion != 1 || c.CampaignType != 7 || len(c.Chapters) != 16 {
		return errors.New("guild campaign catalog identity")
	}
	for index, chapter := range c.Chapters {
		if chapter.ChapterID != int64(7+index) || chapter.OpenCost <= 0 || chapter.CoinReward <= 0 || chapter.AdditionReward <= 0 || len(chapter.Items) == 0 || len(chapter.Copies) == 0 {
			return errors.New("guild campaign chapter row")
		}
		want := int64(0)
		if index > 0 {
			want = c.Chapters[index-1].ChapterID
		}
		if chapter.Previous != want {
			return errors.New("guild campaign chapter precedence")
		}
		seen := map[int64]bool{}
		for _, copy := range chapter.Copies {
			if copy.CopyID <= 0 || copy.FightID <= 0 || seen[copy.CopyID] || len(copy.Waves) != 3 {
				return errors.New("guild campaign copy row")
			}
			seen[copy.CopyID] = true
			for _, wave := range []string{"1", "2", "3"} {
				if len(copy.Waves[wave]) == 0 {
					return errors.New("guild campaign copy wave")
				}
				for _, enemy := range copy.Waves[wave] {
					if enemy.TableID <= 0 || enemy.Lev <= 0 || enemy.Star < 0 || enemy.Color < 0 || enemy.Health != 0 {
						return errors.New("guild campaign enemy seed")
					}
				}
			}
		}
	}
	if len(c.RewardHurtRank) == 0 || len(c.DistRewardTime) != 14 {
		return errors.New("guild campaign settings")
	}
	for index := 1; index < len(c.DistRewardTime); index++ {
		if c.DistRewardTime[index] <= c.DistRewardTime[index-1] {
			return errors.New("guild campaign reward slots")
		}
	}
	if c.RewardParamPerMile <= 0 || c.RewardTimeLimit <= 0 || c.FirstRewardDiamond <= 0 || c.FirstRewardCoin <= 0 {
		return errors.New("guild campaign reward constants")
	}
	return nil
}

// Chapter returns the definition with rewards and copy ids.
func (c Catalog) Chapter(chapterID int64) (Chapter, bool) {
	for _, chapter := range c.Chapters {
		if chapter.ChapterID == chapterID {
			return chapter, true
		}
	}
	return Chapter{}, false
}

// Copy returns one copy with its seeded waves and fight id.
func (c Catalog) Copy(chapterID, copyID int64) (Copy, bool) {
	chapter, known := c.Chapter(chapterID)
	if !known {
		return Copy{}, false
	}
	for _, copy := range chapter.Copies {
		if copy.CopyID == copyID {
			return copy, true
		}
	}
	return Copy{}, false
}
