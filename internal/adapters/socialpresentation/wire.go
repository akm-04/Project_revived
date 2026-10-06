package socialpresentation

import (
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	sv "gxb.local/backend/v2/internal/projection/socialview"
	"time"
)

func timeCopy(p *time.Time) *time.Time {
	if p == nil {
		return nil
	}
	v := p.UTC()
	return &v
}
func wirePlayer(p sp.Player) sv.Player {
	m, o := p.Presentation.Minimal, p.Presentation.Presence
	return sv.Player{Minimal: sv.Minimal{PlayerID: int64(m.PlayerID), Name: m.Name, Level: m.Level, AvatarID: m.AvatarID, AvatarFrameID: m.AvatarFrameID, ConquerLevel: m.ConquerLevel, ConquerLoopID: m.ConquerLoopID, PlayerType: m.PlayerType}, Presence: sv.Presence{IsOnline: o.IsOnline, LastSeenAt: timeCopy(o.LastSeenAt), LatestConnectedAt: timeCopy(o.LatestConnectedAt)}, OutgoingPending: p.OutgoingPending}
}

// wireInput is the finite application-to-view bridge at the allowed edge. It
// copies only committed response values; it performs no read or selection.
func wireInput(r sp.Result) sv.Result {
	v := sv.Result{ObservedAt: r.ObservedAt}
	for _, p := range r.Friends {
		v.Friends = append(v.Friends, wirePlayer(p))
	}
	for _, p := range r.Blocks {
		v.Blocks = append(v.Blocks, wirePlayer(p))
	}
	for _, p := range r.Players {
		v.Players = append(v.Players, wirePlayer(p))
	}
	for _, p := range r.Requests {
		v.Requests = append(v.Requests, sv.Requested{Player: wirePlayer(p.Player), Message: p.Relation.Message, At: p.Relation.RequestedAt})
	}
	for _, p := range r.Notices {
		v.Notices = append(v.Notices, sv.Notified{Player: wirePlayer(p.Player), ID: int64(p.Notice.NoticeID), Type: p.Notice.NoticeType, At: p.Notice.NoticeTime})
	}
	return v
}
func MapBase(r sp.Result) sv.Base { return sv.MapBase(wireInput(r)) }
func MapList(r sp.Result, k sp.ListKind) (any, error) {
	return sv.MapList(wireInput(r), sv.ListKind(k))
}
func MapSearch(r sp.Result, m sp.SearchMode) (any, error) {
	return sv.MapSearch(wireInput(r), sv.SearchMode(m))
}
func MapRecommend(r sp.Result) sv.Recommendations { return sv.MapRecommend(wireInput(r)) }
func DecodeSearch(raw []byte) (sp.SearchQuery, error) {
	q, e := sv.DecodeSearch(raw)
	if e != nil {
		return sp.SearchQuery{}, e
	}
	return sp.SearchQuery{Mode: sp.SearchMode(q.Mode), Term: q.Term}, nil
}
