package occult

import (
	"encoding/json"
	"strconv"
)

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
