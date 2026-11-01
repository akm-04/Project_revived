// Package guildcampaign owns the Guild Campaign chapter and copy state of
// I9_GUILD_CAMPAIGN_V1.
package guildcampaign

import (
	"encoding/json"
	"errors"
	"time"
)

// ErrRefused is an admission the client answers with its own rule, not a fault.
var ErrRefused = errors.New("guild campaign refused")

// Guild log types (enums.lua:1911-1913).
const (
	LogFinalHit     int64 = 7
	LogOpenChapter  int64 = 8
	LogResetChapter int64 = 9
)

// Holder stages (C6): stage 1 is the claim, stage 2 the fight.
const (
	StageFree    int64 = 0
	StagePrepare int64 = 1
	StageFight   int64 = 2
)

// Chapter is one guild's open chapter. Run counts opens and resets, so payouts
// and rank rows of a reset run stay apart from the new one.
type Chapter struct {
	GuildID   int64
	ChapterID int64
	Run       int64
	Win       bool
	Percent   float64
	StartTime time.Time
	EndTime   *time.Time
}

// Copy is one stage. Waves holds enemy HP that carries across every member's fights.
type Copy struct {
	GuildID           int64
	ChapterID         int64
	CopyID            int64
	Run               int64
	Waves             json.RawMessage
	CurrentIndex      int64
	Win               bool
	Percent           float64
	HolderID          int64
	HolderStage       int64
	LastFightTime     *time.Time
	StartFightTime    *time.Time
	AttemptGeneration string
}
