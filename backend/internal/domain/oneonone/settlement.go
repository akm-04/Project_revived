package oneonone

import (
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

// Totals is a player's lifetime match history from producer start (C5C policy).
type Totals struct {
	Fights int64
	Wins   int64
}

type SettlementRow struct {
	Player     identity.PlayerID
	Global     int64
	ServerRank int64
	Mail       *ids.UUID
	Title      *Title
	TitleEnd   int64
}

// Settlement is the immutable Wednesday/Sunday 22:00 snapshot.
type Settlement struct {
	Day                int64
	CutoffAt           time.Time
	SettledAt          time.Time
	CompetitionVersion int64
	ContentRevision    string
	Rows               []SettlementRow
}

// TitleAward is one settled title entitlement.
type TitleAward struct {
	Day      int64     `json:"day"`
	TitleID  int64     `json:"title_id"`
	StartsAt time.Time `json:"starts_at"`
	End      int64     `json:"end"`
}
