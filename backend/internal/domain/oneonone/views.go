package oneonone

import (
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// Face is a competitor's public card (source player_info).
type Face struct {
	Player       identity.PlayerID
	Name         string
	Level        int64
	AvatarID     int64
	FrameID      int64
	ConquerLevel int64
	ConquerLoop  int64
}

// TeamView is one team's roster rows (source formation_info / pet_info); a
// hidden or missing team has no rows.
type TeamView struct {
	Heroes []map[string]any
	Pet    map[string]any
}

type Entry struct {
	Face   Face
	Ranked Ranked
}

type ArenaView struct {
	Player       Player
	Ranked       Ranked
	PromotionEnd *time.Time
	ServerTime   time.Time
}

type MatchView struct {
	Arena      ArenaView
	ReportKeys []string
	Wins       []int64
	Win        bool
}

type RecordView struct {
	Record   Record
	Attacker Face
	Defender Face
}

type RecordDetail struct {
	ReportKeys []string
	Wins       []int64
	Attack     []TeamView
	Defense    []TeamView
}

type RankList struct {
	Rows []Entry
	Mine Ranked
}
