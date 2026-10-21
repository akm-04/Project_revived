package arena

import (
	"context"
	"errors"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/arena"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// rankRows is the number of 301 rank_types 6 rows (C5D policy, as 5C).
const rankRows = 50

func (s Service) current(c context.Context, pid identity.PlayerID) (d.Catalog, d.Player, time.Time, error) {
	if !s.ready() {
		return d.Catalog{}, d.Player{}, time.Time{}, d.ErrUnavailable
	}
	now, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return d.Catalog{}, d.Player{}, now, err
	}
	_, catalog, err := s.catalogTx(c, s.Fresh)
	if err != nil {
		return d.Catalog{}, d.Player{}, now, err
	}
	p, found, err := s.Store.ReadPlayerTx(c, s.Fresh, pid, false)
	if err != nil || !found {
		return d.Catalog{}, d.Player{}, now, errors.Join(err, d.ErrRefused)
	}
	return catalog, catalog.Rolled(p, now), now, nil
}

// Partners answers GET_REARENA_PARTNERS: season statistics and girl usage.
func (s Service) Partners(c context.Context, a identity.ActorContext) (d.PartnersView, error) {
	_, p, _, err := s.current(c, a.PlayerID)
	if err != nil {
		return d.PartnersView{}, err
	}
	usage, err := s.Store.UsageTx(c, s.Fresh, a.PlayerID, p.Season)
	return d.PartnersView{Player: p, Usage: usage}, err
}

// Records lists the retained ranked fights, newest first.
func (s Service) Records(c context.Context, a identity.ActorContext) ([]d.RecordView, error) {
	if !s.ready() {
		return nil, d.ErrUnavailable
	}
	records, err := s.Store.RecordsTx(c, s.Fresh, a.PlayerID)
	if err != nil {
		return nil, err
	}
	out := []d.RecordView{}
	for _, r := range records {
		m, found, err := s.Store.ReadMatchTx(c, s.Fresh, r.MatchID, false)
		if err != nil || !found {
			return nil, errors.Join(err, d.ErrConflict)
		}
		opponent := m.Defender
		if !r.Attack {
			opponent = m.Attacker
		}
		face, err := s.face(c, s.Fresh, opponent)
		if err != nil {
			return nil, err
		}
		view := d.RecordView{Record: r, Opponent: face}
		if !m.AttemptID.IsZero() {
			view.ReportKey = m.AttemptID.String()
		}
		out = append(out, view)
	}
	return out, nil
}

// Report replays a retained record's battle report; an expired key is absent.
func (s Service) Report(c context.Context, key string) ([]byte, bool, error) {
	if !s.ready() {
		return nil, false, d.ErrUnavailable
	}
	id, err := ids.ParseUUID(key)
	if err != nil {
		return nil, false, d.ErrInvalid
	}
	retained, err := s.Store.RetainedAttemptTx(c, s.Fresh, id)
	if err != nil || !retained {
		return nil, false, err
	}
	result, err := s.Combat.ResultTx(c, s.Fresh, id)
	if err != nil {
		return nil, false, err
	}
	return result.Report, true, nil
}

// RankList is 301 rank_types 6: the season's top rows and the viewer's place.
func (s Service) RankList(c context.Context, a identity.ActorContext) (d.RankList, error) {
	if !s.ready() {
		return d.RankList{}, d.ErrUnavailable
	}
	now, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return d.RankList{}, err
	}
	_, catalog, err := s.catalogTx(c, s.Fresh)
	if err != nil {
		return d.RankList{}, err
	}
	standings, err := s.Store.StandingsTx(c, s.Fresh, catalog.SeasonAt(now).Number)
	if err != nil {
		return d.RankList{}, err
	}
	ordered := d.Order(standings)
	out := d.RankList{Rows: []d.RankEntry{}}
	for i, st := range ordered {
		if i >= rankRows && st.PlayerID != a.PlayerID {
			continue
		}
		face, err := s.face(c, s.Fresh, st.PlayerID)
		if err != nil {
			return d.RankList{}, err
		}
		entry := d.RankEntry{Face: face, Standing: st, Rank: int64(i + 1), Level: catalog.LevelOf(st.Star)}
		if i < rankRows {
			out.Rows = append(out.Rows, entry)
		}
		if st.PlayerID == a.PlayerID {
			out.Mine = entry
		}
	}
	return out, nil
}

// Reconciler settles owed seasons, abandoned started matches and unresolved
// fights promptly (generation reconcile provider).
type Reconciler struct{ Service Service }

func (Reconciler) Name() string { return "arena" }

// openMatchGrace leaves fresh fights to their own FIGHT request.
const openMatchGrace = 30 * time.Second

func (r Reconciler) Reconcile(c context.Context, op gen.TimedOperation, limit int) (gen.ReconcileResult, error) {
	out := gen.ReconcileResult{Provider: r.Name()}
	s := r.Service
	if !s.ready() {
		return out, d.ErrUnavailable
	}
	applied, err := s.Due(c, op.Operation())
	out.Scanned, out.Settled = applied, applied
	if err != nil {
		return out, err
	}
	now, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return out, err
	}
	matches, err := s.Store.OpenMatchesTx(c, s.Fresh, now.Add(-openMatchGrace), max(limit-out.Scanned, 0))
	if err != nil {
		return out, err
	}
	for _, id := range matches {
		out.Scanned++
		settled, err := r.match(c, id, op, now)
		if err != nil {
			return out, err
		}
		if settled {
			out.Settled++
		}
	}
	return out, nil
}

func (r Reconciler) match(c context.Context, id ids.UUID, op gen.TimedOperation, now time.Time) (bool, error) {
	s := r.Service
	m, found, err := s.Store.ReadMatchTx(c, s.Fresh, id, false)
	if err != nil || !found {
		return false, errors.Join(err, d.ErrConflict)
	}
	if m.Status == d.StatusStarted {
		if !m.Abandoned(now) {
			return false, nil
		}
		return true, s.settle(c, m.ID, true, op.Operation())
	}
	attempt, found, err := s.Combat.AttemptTx(c, s.Fresh, m.AttemptID)
	if err != nil || !found {
		return false, errors.Join(err, d.ErrConflict)
	}
	if attempt.State == cd.Staged && attempt.Closable(now) {
		return true, s.close(c, m, op.Operation())
	}
	_, err = s.conclude(c, m, op.Operation(), time.Time{})
	return true, err
}

// PublicHistoryTx is the 1829 HISTORY REGION_ARENA entry inside the caller's
// transaction: season Lord points, season totals and that season's girl usage.
func (s Service) PublicHistoryTx(c context.Context, q tx.Queryer, pid identity.PlayerID, at time.Time) (cd.History, error) {
	if !s.ready() {
		return cd.History{}, d.ErrUnavailable
	}
	_, catalog, err := s.catalogTx(c, q)
	if err != nil {
		return cd.History{}, err
	}
	p, found, err := s.Store.ReadPlayerTx(c, q, pid, false)
	if err != nil || !found {
		return cd.History{}, err
	}
	p = catalog.Rolled(p, at)
	usage, err := s.Store.UsageTx(c, q, pid, p.Season)
	if err != nil {
		return cd.History{}, err
	}
	partners := make([]cd.PartnerTotals, 0, len(usage))
	for _, u := range usage {
		partners = append(partners, cd.PartnerTotals{TableID: u.TableID, Fights: u.Fights, Wins: u.Wins, Kills: u.Kills, Harms: u.Harms})
	}
	return cd.History{Points: p.Point, Fights: p.TotalFight, Wins: p.WinTimes, Version: p.StateVersion, Partners: partners}, nil
}
