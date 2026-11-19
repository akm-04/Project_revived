package arena

import (
	"context"
	"errors"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// rankRows is the number of 301 rank_types 6 rows (C5D policy, as 5C).
const rankRows = 50

func (s Service) current(c context.Context, q tx.Queryer, pid identity.PlayerID, now time.Time) (d.Catalog, d.Player, error) {
	if !s.ready() {
		return d.Catalog{}, d.Player{}, d.ErrUnavailable
	}
	_, catalog, err := s.catalogTx(c, q)
	if err != nil {
		return d.Catalog{}, d.Player{}, err
	}
	p, found, err := s.Store.ReadPlayerTx(c, q, pid, false)
	if err != nil || !found {
		return d.Catalog{}, d.Player{}, errors.Join(err, d.ErrRefused)
	}
	return catalog, catalog.Rolled(p, now), nil
}

// Partners answers GET_REARENA_PARTNERS: the requested player's season
// statistics and girl usage, read without mutation.
func (s Service) Partners(c context.Context, a identity.ActorContext, subject identity.PlayerID, op operation.Context) (d.PartnersView, error) {
	var out d.PartnersView
	_, _, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, readRetry(), nil, func(c context.Context, sc gen.TimedScope) error {
		p, usage, err := s.partnersSubject(c, sc.Tx, subject, sc.Operation.DecisionAt())
		if err != nil {
			return err
		}
		out = d.PartnersView{Player: p, Usage: usage}
		return nil
	})
	return out, err
}

// partnersSubject is the Arena-owned subject read of one player's statistics.
// An unknown subject is ErrRefused, which the dispatcher answers 409.
func (s Service) partnersSubject(c context.Context, q tx.Queryer, subject identity.PlayerID, at time.Time) (d.Player, []d.Usage, error) {
	_, p, err := s.current(c, q, subject, at)
	if err != nil {
		return d.Player{}, nil, err
	}
	usage, err := s.Store.UsageTx(c, q, subject, p.Season)
	if err != nil {
		return d.Player{}, nil, err
	}
	if err = s.fillPartnerStars(c, q, subject, usage); err != nil {
		return d.Player{}, nil, err
	}
	return p, usage, nil
}

// fillPartnerStars adds each usage girl's current star from the subject's owned
// heroes; a girl the subject no longer owns keeps no star.
func (s Service) fillPartnerStars(c context.Context, q tx.Queryer, subject identity.PlayerID, usage []d.Usage) error {
	if len(usage) == 0 {
		return nil
	}
	templates, err := s.templates(c, q)
	if err != nil {
		return err
	}
	owned, err := s.OwnedHeroes.ListHeroesTx(c, q, subject)
	if err != nil {
		return err
	}
	attachPartnerStars(usage, owned, templates)
	return nil
}

// attachPartnerStars resolves each usage girl to the subject's strongest owned
// copy, as lineupRows picks it, and records that copy's current star.
func attachPartnerStars(usage []d.Usage, owned []character.Hero, templates d.Templates) {
	strongest := make(map[int64]character.Hero, len(owned))
	for _, hero := range owned {
		base := templates.Base(hero.TableID)
		if current, found := strongest[base]; !found || heroRanksAbove(hero, current) {
			strongest[base] = hero
		}
	}
	for index := range usage {
		hero, found := strongest[templates.Base(usage[index].TableID)]
		if !found {
			continue
		}
		star := hero.Star
		usage[index].Star = &star
	}
}

// heroRanksAbove orders owned copies of one girl: most stars, then the highest
// level, then the lowest partner id (C5D policy, as strongest does).
func heroRanksAbove(candidate, current character.Hero) bool {
	if candidate.Star != current.Star {
		return candidate.Star > current.Star
	}
	if candidate.Level != current.Level {
		return candidate.Level > current.Level
	}
	return candidate.PartnerID < current.PartnerID
}

// Records lists the retained ranked fights, newest first.
func (s Service) Records(c context.Context, a identity.ActorContext, op operation.Context) ([]d.RecordView, error) {
	var out []d.RecordView
	_, _, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, readRetry(), nil, func(c context.Context, sc gen.TimedScope) error {
		records, err := s.Store.RecordsTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return err
		}
		out = []d.RecordView{}
		for _, r := range records {
			m, found, err := s.Store.ReadMatchTx(c, sc.Tx, r.MatchID, false)
			if err != nil || !found {
				return errors.Join(err, d.ErrConflict)
			}
			opponent := m.Defender
			if !r.Attack {
				opponent = m.Attacker
			}
			face, err := s.face(c, sc.Tx, opponent)
			if err != nil {
				return err
			}
			view := d.RecordView{Record: r, Opponent: face}
			if !m.AttemptID.IsZero() {
				view.ReportKey = m.AttemptID.String()
			}
			out = append(out, view)
		}
		return nil
	})
	return out, err
}

// readRetry keeps a read-only snapshot from retrying a definite abort.
func readRetry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 1}
}

// Report replays a retained record's battle report; an expired key is absent.
func (s Service) Report(c context.Context, key string, op operation.Context) ([]byte, bool, error) {
	if !s.ready() {
		return nil, false, d.ErrUnavailable
	}
	id, err := ids.ParseUUID(key)
	if err != nil {
		return nil, false, d.ErrInvalid
	}
	var report []byte
	served := false
	_, _, err = s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, readRetry(), nil, func(c context.Context, sc gen.TimedScope) error {
		retained, err := s.Store.RetainedAttemptTx(c, sc.Tx, id)
		if err != nil || !retained {
			return err
		}
		result, found, err := s.Combat.ReplayTx(c, sc.Tx, id, *cd.MustMode(cd.ModeArena).Retention, sc.Operation.DecisionAt())
		report, served = result.Report, found
		return err
	})
	return report, served, err
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
	tournamentCount, err := s.ReconcileTournaments(c, op.Operation(), max(limit-out.Scanned, 0))
	out.Scanned += tournamentCount
	out.Settled += tournamentCount
	return out, err
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
