package topfloor

import (
	"context"
	"errors"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// rankListSize is the private-policy length of the live Top Floor rank list.
const rankListSize = 50

func (s Service) readContext(c context.Context) (d.Catalog, time.Time, error) {
	if !s.ready() {
		return d.Catalog{}, time.Time{}, d.ErrUnavailable
	}
	now, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return d.Catalog{}, time.Time{}, err
	}
	_, catalog, err := s.catalogTx(c, s.Fresh)
	return catalog, now, err
}

// Records lists the player's retained fights, newest first; unentered players have none.
func (s Service) Records(c context.Context, a identity.ActorContext) ([]RecordView, error) {
	catalog, now, err := s.readContext(c)
	if err != nil {
		return nil, err
	}
	records, err := s.Store.RecordsTx(c, s.Fresh, a.PlayerID)
	if err != nil {
		return nil, err
	}
	self, err := s.face(c, catalog, a.LogicalServerID, d.Occupant{Player: a.PlayerID}, now)
	if err != nil && len(records) > 0 {
		return nil, err
	}
	out := []RecordView{}
	for _, r := range records {
		opponent, err := s.face(c, catalog, a.LogicalServerID, r.Opponent, now)
		if err != nil {
			return nil, err
		}
		out = append(out, RecordView{Record: r, Self: self, Opponent: opponent})
	}
	return out, nil
}

// face is a display without the roster team, for record rows.
func (s Service) face(c context.Context, catalog d.Catalog, server identity.LogicalServerID, o d.Occupant, now time.Time) (d.Display, error) {
	if o.IsRobot() {
		return s.display(c, s.Fresh, catalog, server, o, now)
	}
	profile, found, err := s.Directory.ProfileTx(c, s.Fresh, o.Player)
	if err != nil || !found {
		return d.Display{}, errors.Join(err, d.ErrUnavailable)
	}
	return d.Display{Occupant: o, Name: profile.Name, Level: profile.Level, AvatarID: profile.AvatarID, FrameID: profile.AvatarFrameID, ConquerLevel: profile.ConquerLevel, ConquerLoop: profile.ConquerLoopID}, nil
}

// Report replays a fight while any retained record references it; nil is ARENA_RECORD_OUT_OF_DATE.
func (s Service) Report(c context.Context, key string) ([]byte, error) {
	if !s.ready() {
		return nil, d.ErrUnavailable
	}
	id, err := ids.ParseUUID(key)
	if err != nil {
		return nil, nil
	}
	retained, err := s.Store.RetainedTx(c, s.Fresh, id)
	if err != nil || !retained {
		return nil, err
	}
	result, err := s.Combat.ResultTx(c, s.Fresh, id)
	if err != nil {
		return nil, err
	}
	return result.Report, nil
}

// RecordInfo is the opponent of one of the player's own records with its revenge state.
func (s Service) RecordInfo(c context.Context, a identity.ActorContext, recordID int64) (RecordInfo, d.Record, error) {
	catalog, now, err := s.readContext(c)
	if err != nil {
		return RecordInfo{}, d.Record{}, err
	}
	r, found, err := s.Store.RecordTx(c, s.Fresh, recordID)
	if err != nil || !found || r.Owner != a.PlayerID {
		return RecordInfo{}, d.Record{}, errors.Join(err, d.ErrRefused)
	}
	opponent, err := s.display(c, s.Fresh, catalog, a.LogicalServerID, r.Opponent, now)
	if err != nil {
		return RecordInfo{}, d.Record{}, err
	}
	rank, _, err := s.Store.RankOfTx(c, s.Fresh, a.LogicalServerID, d.Occupant{Player: a.PlayerID})
	if err != nil {
		return RecordInfo{}, d.Record{}, err
	}
	info := RecordInfo{Opponent: opponent, AvengeType: catalog.AvengeType(rank, opponent.Rank)}
	info.CanAvenge = !r.Attack && !r.Win && !r.Opponent.IsRobot() && info.AvengeType == 0
	return info, r, nil
}

// Formation resolves a wire player id (table_id + region*100000): a ranked player
// holding that id first, otherwise the robot team with that table id.
func (s Service) Formation(c context.Context, a identity.ActorContext, wire int64) (d.Display, error) {
	catalog, now, err := s.readContext(c)
	if err != nil {
		return d.Display{}, err
	}
	table := wire % d.RegionStride
	if wire/d.RegionStride != int64(a.LogicalServerID) || table <= 0 {
		return d.Display{}, d.ErrInvalid
	}
	o := d.Occupant{Player: identity.PlayerID(wire)}
	if _, ranked, err := s.Store.RankOfTx(c, s.Fresh, a.LogicalServerID, o); err != nil || !ranked {
		if err != nil {
			return d.Display{}, err
		}
		o = d.Occupant{Robot: table}
		if !o.Valid() {
			return d.Display{}, d.ErrRefused
		}
	}
	return s.display(c, s.Fresh, catalog, a.LogicalServerID, o, now)
}

func (s Service) RankList(c context.Context, a identity.ActorContext) (RankList, error) {
	catalog, now, err := s.readContext(c)
	if err != nil {
		return RankList{}, err
	}
	ranked, err := s.Store.RangeTx(c, s.Fresh, a.LogicalServerID, 1, rankListSize)
	if err != nil {
		return RankList{}, err
	}
	out := RankList{}
	for _, r := range ranked {
		face, err := s.face(c, catalog, a.LogicalServerID, r.Occupant, now)
		if err != nil {
			return RankList{}, err
		}
		face.Rank = r.Rank
		out.Rows = append(out.Rows, face)
	}
	out.MyRank, _, err = s.Store.RankOfTx(c, s.Fresh, a.LogicalServerID, d.Occupant{Player: a.PlayerID})
	return out, err
}

// Reconciler settles owed days and abandoned fights promptly (generation reconcile provider).
type Reconciler struct{ Service Service }

func (Reconciler) Name() string { return "top-floor" }

// openFightGrace leaves fresh fights to their own START retries.
const openFightGrace = 30 * time.Second

func (r Reconciler) Reconcile(c context.Context, op gen.TimedOperation, limit int) (gen.ReconcileResult, error) {
	out := gen.ReconcileResult{Provider: r.Name()}
	s := r.Service
	catalog, now, err := s.readContext(c)
	if err != nil {
		return out, err
	}
	servers, err := s.Store.DueServersTx(c, s.Fresh, catalog.LatestCutoffDay(now))
	if err != nil {
		return out, err
	}
	for _, server := range servers {
		if out.Scanned >= limit {
			return out, nil
		}
		out.Scanned++
		settled, err := s.SettleDue(c, server, op.Operation())
		if err != nil {
			return out, err
		}
		out.Settled += settled
	}
	fights, err := s.Store.OpenFightsTx(c, s.Fresh, now.Add(-openFightGrace), max(limit-out.Scanned, 0))
	if err != nil {
		return out, err
	}
	for _, f := range fights {
		out.Scanned++
		if err := r.fight(c, f, op, now); err != nil {
			return out, err
		}
		out.Settled++
	}
	return out, nil
}

func (r Reconciler) fight(c context.Context, f d.Fight, op gen.TimedOperation, now time.Time) error {
	s := r.Service
	attempt, found, err := s.Combat.AttemptTx(c, s.Fresh, f.AttemptID)
	if err != nil || !found {
		return errors.Join(err, d.ErrConflict)
	}
	if attempt.State == cd.Staged && attempt.Closable(now) {
		return s.close(c, f, op.Operation())
	}
	_, err = s.finish(c, f, op.Operation())
	return err
}

// PublicHistoryTx is the 1829 HISTORY ARENA entry inside the caller's
// transaction: current ladder rank, lifetime totals and partner usage.
func (s Service) PublicHistoryTx(c context.Context, q tx.Queryer, pid identity.PlayerID, _ time.Time) (cd.History, error) {
	if !s.ready() {
		return cd.History{}, d.ErrUnavailable
	}
	p, found, err := s.Store.ReadPlayerTx(c, q, pid, false)
	if err != nil || !found {
		return cd.History{}, err
	}
	rank, _, err := s.Store.RankOfTx(c, q, p.Server, d.Occupant{Player: pid})
	if err != nil {
		return cd.History{}, err
	}
	usage, err := s.Store.UsageTx(c, q, pid)
	return cd.History{Rank: rank, Fights: p.Fights, Wins: p.Wins, Version: p.StateVersion, Partners: usage}, err
}
