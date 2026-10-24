package achievement

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const trophyRows = 50

// TrophyCountPolicy is metric 1004: tiers recorded by observation. An unobserved
// legacy root has recorded none yet; its first observation backfills them.
const TrophyCountPolicy = "C4F_TROPHY_COUNT_V1"

type TrophyCount struct {
	Value, RootVersion int64
	TiersDigest        string
}

func (s Service) TrophyCountTx(c context.Context, sc ca.CoherentReadScope, p identity.PlayerID) (TrophyCount, error) {
	if s.Store == nil || s.Content == nil || !p.Valid() {
		return TrophyCount{}, d.ErrUnavailable
	}
	catalog, e := s.Content.AchievementCatalogTx(c, sc.Queryer(), sc.ContentRevision)
	if e != nil {
		return TrophyCount{}, e
	}
	root, _, earned, e := s.earnedTx(c, sc.Queryer(), p)
	if errors.Is(e, d.ErrUnavailable) {
		return TrophyCount{TiersDigest: tiersDigest(nil)}, nil
	}
	if e != nil {
		return TrophyCount{}, e
	}
	if root.UpdatedAt.After(sc.ObservedAt) {
		return TrophyCount{}, d.ErrConflict
	}
	recorded := [][2]int64{}
	for _, row := range catalog.Rows {
		for tier, at := range earned[row.ID] {
			if at != nil {
				recorded = append(recorded, [2]int64{row.ID, int64(tier + 1)})
			}
		}
	}
	return TrophyCount{Value: catalog.Trophies(earned), RootVersion: root.StateVersion, TiersDigest: tiersDigest(recorded)}, nil
}

func tiersDigest(recorded [][2]int64) string {
	if recorded == nil {
		recorded = [][2]int64{}
	}
	b, _ := json.Marshal(recorded)
	h := sha256.Sum256(b)
	return hex.EncodeToString(h[:])
}

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
