package achievement

import "gxb.local/backend/v2/internal/domain/identity"

type TrophyStanding struct {
	Player identity.PlayerID
	Points int64
}

type TrophyPresentation struct {
	Name                                                  string
	Level, AvatarID, FrameID, ConquerLevel, ConquerLoopID int64
}

type TrophyRow struct {
	TrophyStanding
	Rank    int64
	Display TrophyPresentation
}

// TrophyBoard is 301 rank_types 15 (SubRankType.ACHIEVEMENT_POINT), ordered by
// C4F_LIVE_TROPHY_RANK_V1 like the 1302 rank.
type TrophyBoard struct {
	Server           identity.LogicalServerID
	Region           string
	Rows             []TrophyRow
	MyRank, MyPoints int64
}
