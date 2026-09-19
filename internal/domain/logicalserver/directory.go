package logicalserver

import (
	"gxb.local/backend/v2/internal/domain/identity"
	"sort"
)

type RegionView struct {
	RegionID    int32  `json:"region_id"`
	Name        string `json:"name"`
	CurID       int64  `json:"cur_id"`
	MaxPlayerID int64  `json:"max_player_id"`
}

// BootstrapDirectoryAvatarID is the narrow I4 fresh-character directory
// baseline. The verified current avatar table marks 110001001 as initially
// owned, and the frozen V1 runtime corroborates the same stock-facing value.
// Player Core owns subsequent profile mutation beginning in I5.
const BootstrapDirectoryAvatarID int64 = 110001001

type PlayerSummary struct {
	ID            int64  `json:"id"`
	Region        int32  `json:"region"`
	Level         int64  `json:"lev"`
	VIP           int64  `json:"vip"`
	Name          string `json:"name"`
	AvatarID      int64  `json:"avatar_id"`
	AvatarFrameID int64  `json:"avatar_frame_id"`
	ConquerLevel  int64  `json:"conquer_lev"`
	ConquerLoopID int64  `json:"conquer_loop_id"`
}
type MID18View struct {
	Regions       []RegionView    `json:"regions"`
	Players       []PlayerSummary `json:"players"`
	RecallRegions []int32         `json:"recall_regions"`
}

func ProjectRegion(s Server) RegionView {
	cur := int64(s.NextPlayerID) - 1
	if !s.NewCharacterAllowed && cur < int64(s.MaxPlayerID) {
		cur = int64(s.MaxPlayerID)
	}
	return RegionView{int32(s.ID), s.Name, cur, int64(s.MaxPlayerID)}
}
func ProjectMID18(servers []Server, players []PlayerSummary) MID18View {
	r := make([]RegionView, 0, len(servers))
	for _, s := range servers {
		if s.DirectoryVisible {
			r = append(r, ProjectRegion(s))
		}
	}
	sort.Slice(r, func(i, j int) bool { return r[i].RegionID < r[j].RegionID })
	p := make([]PlayerSummary, 0, len(players))
	p = append(p, players...)
	sort.SliceStable(p, func(i, j int) bool { return p[i].Level > p[j].Level })
	return MID18View{Regions: r, Players: p, RecallRegions: []int32{}}
}

type ServerObservation struct {
	SessionID       identity.SessionID
	LogicalServerID identity.LogicalServerID
}

func ObserveVisible(session identity.SessionID, servers []Server) []ServerObservation {
	out := []ServerObservation{}
	for _, s := range servers {
		if s.DirectoryVisible {
			out = append(out, ServerObservation{session, s.ID})
		}
	}
	return out
}
