package achievement

import (
	"context"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const trophyRows = 50

type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}
type Servers interface {
	ServerNameTx(context.Context, tx.Queryer, identity.LogicalServerID) (string, error)
}

func (s Service) TrophyBoard(c context.Context, a identity.ActorContext) (d.TrophyBoard, error) {
	out := d.TrophyBoard{Server: a.LogicalServerID, Rows: []d.TrophyRow{}}
	if s.Runtime == nil || s.Runtime.Fresh == nil || s.Runtime.Active == nil || s.Runtime.Directory == nil || s.Runtime.Servers == nil || s.Store == nil || s.Content == nil || !a.PlayerID.Valid() {
		return out, d.ErrUnavailable
	}
	q := s.Runtime.Fresh
	rev, e := s.Runtime.Active.ActiveRevision(c, q)
	if e != nil {
		return out, e
	}
	catalog, e := s.Content.AchievementCatalogTx(c, q, rev)
	if e != nil {
		return out, e
	}
	top, e := s.Store.TrophyTopTx(c, q, a.LogicalServerID, catalog, trophyRows)
	if e != nil {
		return out, e
	}
	out.Region, e = s.Runtime.Servers.ServerNameTx(c, q, a.LogicalServerID)
	if e != nil {
		return out, e
	}
	for i, standing := range top {
		profile, ok, e := s.Runtime.Directory.ProfileTx(c, q, standing.Player)
		if e != nil {
			return out, e
		}
		if !ok {
			return out, d.ErrUnavailable
		}
		display := d.TrophyPresentation{Name: profile.Name, Level: profile.Level, AvatarID: profile.AvatarID, FrameID: profile.AvatarFrameID, ConquerLevel: profile.ConquerLevel, ConquerLoopID: profile.ConquerLoopID}
		out.Rows = append(out.Rows, d.TrophyRow{TrophyStanding: standing, Rank: int64(i + 1), Display: display})
	}
	out.MyRank, e = s.Store.TrophyRankTx(c, q, a.PlayerID, catalog)
	if e != nil || out.MyRank == 0 {
		return out, e
	}
	_, _, earned, e := s.earnedTx(c, q, a.PlayerID)
	if e != nil {
		return out, e
	}
	out.MyPoints, _ = catalog.Points(earned)
	return out, nil
}
