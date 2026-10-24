package arena

import (
	"encoding/json"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// Face is a player's public display in Arena surfaces.
type Face struct {
	Player       identity.PlayerID
	Name         string
	Level        int64
	AvatarID     int64
	FrameID      int64
	ConquerLevel int64
	ConquerLoop  int64
	Server       identity.LogicalServerID
	ServerName   string
	GuildName    string
}

type InfoView struct {
	Player   Player
	Season   Season
	Rank     int64
	Total    int64
	Closed   bool
	KingCoin int64
	At       time.Time
}

// EnemyView is the offered opponent; Heroes are the defender's lineup rows
// with season awards applied (the client balances them itself).
type EnemyView struct {
	Face           Face
	Standing       Standing
	Heroes         []map[string]any
	Pet            map[string]any
	SelfServerName string
}

type FightView struct {
	Unresolved bool
	Win        bool
	Report     json.RawMessage
	Player     Player
	Coins      int64
	RegionCoin int64
}

type RecordView struct {
	Record    Record
	Opponent  Face
	ReportKey string
}

// Usage is one girl's season totals from ranked attacks.
type Usage struct {
	TableID int64  `json:"table_id"`
	Fights  int64  `json:"fights"`
	Wins    int64  `json:"wins"`
	Kills   int64  `json:"kills"`
	Harms   string `json:"harms"`
}

type PartnersView struct {
	Player Player
	Usage  []Usage
}

type RankEntry struct {
	Face     Face
	Standing Standing
	Rank     int64
	Level    int64
}

type RankList struct {
	Rows []RankEntry
	Mine RankEntry
}

// MissionsView answers mission and exchange changes with the mode state and balance.
type MissionsView struct {
	Player   Player
	KingCoin int64
	Coins    int64
	Award    *Award
}
