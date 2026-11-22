package occult

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"math"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// scoreTenths converts a misc coefficient ("2.5", "1.1", "10") to tenths so the
// score is integer arithmetic and deterministic.
func scoreTenths(raw string) int64 {
	value, err := strconv.ParseFloat(raw, 64)
	if err != nil {
		return 0
	}
	return int64(math.Round(value * 10))
}

// ScoreProfile is the coefficient set of one room type; all values are tenths.
type ScoreProfile struct {
	DispatchLimit int64
	Survival      int64
	Dispatch      int64
	Schedule      int64
	Time          int64
}

func (c Catalog) ScoreProfile(campaignType int64) ScoreProfile {
	if campaignType == SingleCampaignType {
		return ScoreProfile{DispatchLimit: c.DispatchHeroLimitSingle, Survival: scoreTenths(c.SurvivalParameterSingle),
			Dispatch: scoreTenths(c.DispatchParameterSingle), Schedule: scoreTenths(c.ScheduleParameterSingle), Time: scoreTenths(c.TimeParameterSingle)}
	}
	return ScoreProfile{DispatchLimit: c.DispatchHeroLimit, Survival: scoreTenths(c.SurvivalParameter),
		Dispatch: scoreTenths(c.DispatchParameter), Schedule: scoreTenths(c.ScheduleParameter), Time: scoreTenths(c.TimeParameter)}
}

// ProgressFraction is the chapter completion the client draws; every fight
// sub-stage of the room weighs the same.
func (s RunState) ProgressFraction(catalog Catalog) float64 {
	total, cleared := 0, 0
	for _, campaign := range catalog.RoomCampaigns(s.ChapterID, s.CampaignType) {
		stages := s.StagesOf(campaign.ID)
		total += len(stages)
		for _, stage := range stages {
			if stage.HP <= 0 {
				cleared++
			}
		}
	}
	if total == 0 {
		return 0
	}
	if cleared >= total {
		return 1
	}
	return float64(cleared) / float64(total)
}

// ProgressPercent is floor(progress*100), the unit the schedule coefficient reads.
func (s RunState) ProgressPercent(catalog Catalog) int64 {
	return int64(math.Floor(s.ProgressFraction(catalog) * 100))
}

// ScoreSeconds is the remaining fight time the time coefficient reads.
func (s RunState) ScoreSeconds(at int64) int64 {
	if s.FightStartedAt <= 0 {
		return 0
	}
	remaining := FightSeconds - (at - s.FightStartedAt)
	return min(max(remaining, 0), FightSeconds)
}

// ChapterScore is the Sorcery War score for one player at the current room
// state: surviving dispatched heroes, dispatch slots never fielded, chapter
// progress percent and remaining fight seconds, plus accumulated event points.
// The coefficients are the stock misc creats_*_param values. PRIVATE_POLICY: the
// source names the terms but not their exact assembly, so counting dispatch slots
// as limit-minus-dispatched, equal weight per fight sub-stage and flooring the
// summed tenths are this server's reading.
func (s RunState) ChapterScore(catalog Catalog, playerID, at int64, extraPoints int64) int64 {
	profile := catalog.ScoreProfile(s.CampaignType)
	dispatched, surviving := int64(0), int64(0)
	for _, status := range s.HeroStatus[key(playerID)] {
		dispatched++
		if status.HP > 0 {
			surviving++
		}
	}
	slots := max(profile.DispatchLimit-dispatched, 0)
	tenths := surviving*profile.Survival + slots*profile.Dispatch +
		s.ProgressPercent(catalog)*profile.Schedule + s.ScoreSeconds(at)*profile.Time
	return tenths/10 + extraPoints
}

// Scores is a player's best score per chapter; a chapter with a best score
// above zero has its sweep unlocked.
type Scores map[string]int64

func (s Scores) Best(chapterID int64) int64 { return s[strconv.FormatInt(chapterID, 10)] }

func (s Scores) SweepUnlocked(chapterID int64) bool { return s.Best(chapterID) > 0 }

// Record keeps the better score and reports whether it improved.
func (s Scores) Record(chapterID, score int64) (Scores, bool) {
	if score <= s.Best(chapterID) {
		return s, false
	}
	next := make(Scores, len(s)+1)
	for key, value := range s {
		next[key] = value
	}
	next[strconv.FormatInt(chapterID, 10)] = score
	return next, true
}

const maxFactValue int64 = 9007199254740991

// ChapterScoreFact is the typed per-player best-score input the Ranking owner
// orders. ReadScoresTx exposes no root version, so SourceVersion is the fixed
// marker 1 while ScoresDigest witnesses the read content.
type ChapterScoreFact struct {
	Player                          identity.PlayerID
	ChapterID, Value, SourceVersion int64
	ScoresDigest, Revision          string
	ObservedAt                      time.Time
}

func (f ChapterScoreFact) Validate(at time.Time) error {
	digest, err := hex.DecodeString(f.ScoresDigest)
	if !f.Player.Valid() || f.ChapterID < 1 || f.Value < 1 || f.Value > maxFactValue || f.SourceVersion != 1 || err != nil || len(digest) != sha256.Size || hex.EncodeToString(digest) != f.ScoresDigest || f.Revision == "" || !f.ObservedAt.Equal(at.UTC()) {
		return ErrInvalid
	}
	return nil
}

// BuildChapterScoreFact returns found=false when the player has no positive
// best for the chapter, so Ranking never ranks an invented zero.
func BuildChapterScoreFact(player identity.PlayerID, chapterID int64, scores Scores, revision string, at time.Time) (ChapterScoreFact, bool, error) {
	var out ChapterScoreFact
	if !player.Valid() || chapterID < 1 || revision == "" || at.Unix() <= 0 {
		return out, false, ErrInvalid
	}
	for key, value := range scores {
		if value < 0 || value > maxFactValue {
			return out, false, ErrInvalid
		}
		if _, err := strconv.ParseInt(key, 10, 64); err != nil {
			return out, false, ErrInvalid
		}
	}
	best := scores.Best(chapterID)
	if best <= 0 {
		return out, false, nil
	}
	raw, err := json.Marshal(scores)
	if err != nil {
		return out, false, ErrInvalid
	}
	digest := sha256.Sum256(raw)
	out = ChapterScoreFact{Player: player, ChapterID: chapterID, Value: best, SourceVersion: 1, ScoresDigest: hex.EncodeToString(digest[:]), Revision: revision, ObservedAt: at.UTC()}
	return out, true, out.Validate(at)
}

func LoadScores(raw json.RawMessage) (Scores, error) {
	scores := Scores{}
	if len(raw) == 0 {
		return scores, nil
	}
	if err := json.Unmarshal(raw, &scores); err != nil {
		return nil, err
	}
	return scores, nil
}
