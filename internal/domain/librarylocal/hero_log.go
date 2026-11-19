package librarylocal

import (
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// HeroLogFact is one Girls Log milestone. The stock table
// (data/tables/library_hero_log.lua) keys rows by sub_id and the client renders
// time; one row per (player, hero, log id).
type HeroLogFact struct {
	PlayerID   identity.PlayerID `json:"player_id"`
	PartnerID  int64             `json:"partner_id"`
	LogID      int64             `json:"log_id"`
	OccurredAt time.Time         `json:"occurred_at"`
}

func (f HeroLogFact) Validate() error {
	if !f.PlayerID.Valid() || f.PartnerID <= 0 || f.LogID <= 0 || f.OccurredAt.IsZero() {
		return ErrInvalidFacts
	}
	return nil
}

const (
	// LogAcquired defaults to the Vending summon source (10001, 贩卖机), the
	// stock acquisition path this server owns (PRIVATE_POLICY for non-summon
	// creation paths).
	LogAcquired int64 = 10001
	LogAwakened int64 = 30001
	LogMarried  int64 = 90001
)

type logThreshold struct {
	threshold int64
	logID     int64
}

// Favor thresholds and their library_hero_log sub_ids (type 8), ascending.
var favorLogThresholds = []logThreshold{
	{100, 80001}, {200, 80006}, {300, 80002}, {600, 80007}, {800, 80003},
	{1200, 80008}, {1400, 80004}, {1600, 80009}, {2000, 80005},
}

// Dialogue completion thresholds (type 7), ascending.
var dialogueLogThresholds = []logThreshold{
	{1, 70001}, {10, 70002}, {30, 70003}, {50, 70004},
}

// Hold time thresholds (type 5) are the condition days owned
// (library_hero_log.lua rows 50001-50004).
var holdTimeLogThresholds = []logThreshold{
	{30, 50001}, {90, 50002}, {180, 50003}, {365, 50004},
}

// Settled battle counts (type 6) reached, from library_hero_log.lua rows 36-39.
// No content catalog carries these thresholds, so they stay constants.
var battleLogThresholds = []logThreshold{
	{1, 60001}, {50, 60002}, {100, 60003}, {1000, 60004},
}

// HoldTimeLogMilestone is one type-5 entry, dated from acquisition.
type HoldTimeLogMilestone struct {
	LogID      int64
	OccurredAt time.Time
}

// HoldTimeLogsReached derives the type-5 milestones an acquisition reached by
// at. The stock table stores no row for these; the entry is the acquisition
// time plus the condition days (library_hero_log.lua:324-362).
func HoldTimeLogsReached(acquiredAt, at time.Time) []HoldTimeLogMilestone {
	out := []HoldTimeLogMilestone{}
	if acquiredAt.IsZero() || at.IsZero() || acquiredAt.After(at) {
		return out
	}
	for _, row := range holdTimeLogThresholds {
		occurredAt := acquiredAt.AddDate(0, 0, int(row.threshold))
		if occurredAt.After(at) {
			continue
		}
		out = append(out, HoldTimeLogMilestone{LogID: row.logID, OccurredAt: occurredAt})
	}
	return out
}

// FavorLogIDsCrossed returns the favor milestones in (from, to].
func FavorLogIDsCrossed(from, to int64) []int64 {
	return crossed(favorLogThresholds, from, to)
}

// DialogueLogIDsReached returns the dialogue milestones in (from, to].
func DialogueLogIDsReached(from, to int64) []int64 {
	return crossed(dialogueLogThresholds, from, to)
}

// BattleLogIDsCrossed returns the settled-battle milestones in (from, to].
func BattleLogIDsCrossed(from, to int64) []int64 {
	return crossed(battleLogThresholds, from, to)
}

func crossed(table []logThreshold, from, to int64) []int64 {
	out := []int64{}
	if to <= from {
		return out
	}
	for _, row := range table {
		if row.threshold > from && row.threshold <= to {
			out = append(out, row.logID)
		}
	}
	return out
}

// ColorLogID maps a promotion target color to its type-2 sub_id
// (20001: color 1->2 through 20013: color 13->14).
func ColorLogID(toColor int64) (int64, bool) {
	if toColor < 2 || toColor > 14 {
		return 0, false
	}
	return 20000 + toColor - 1, true
}

// StarLogID maps a star-up target to its type-4 sub_id
// (40001: star 1->2 through 40009: star 9->10).
func StarLogID(toStar int64) (int64, bool) {
	if toStar < 2 || toStar > 10 {
		return 0, false
	}
	return 40000 + toStar - 1, true
}
