package oneonone

import (
	"context"
	"errors"
	"fmt"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/oneonone"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// rankListSize is the private-policy length of the 1 on 1 rank lists.
const rankListSize = 50

// reportRetention is the 1 on 1 replay window (D25a private policy, at the D9 Q6 ceiling).
var reportRetention = cd.Retention{ID: "C5C_ONE_ON_ONE_REPORT_RETENTION_V1", Version: 1, Window: cd.RetentionCeiling}

// Report replays a round while a retained record references its match; nil is ARENA_RECORD_OUT_OF_DATE.
func (s Service) Report(c context.Context, key string) ([]byte, error) {
	if !s.ready() {
		return nil, d.ErrUnavailable
	}
	id, err := ids.ParseUUID(key)
	if err != nil {
		return nil, nil
	}
	retained, err := s.Store.RetainedRoundTx(c, s.Fresh, id)
	if err != nil || !retained {
		return nil, err
	}
	now, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	result, _, err := s.Combat.ReplayTx(c, s.Fresh, id, reportRetention, now)
	return result.Report, err
}

// DefenseReportKeys lists the round reports of the player's retained defense
// records, newest first (source red-dot list for 2485 without a key).
func (s Service) DefenseReportKeys(c context.Context, a identity.ActorContext) ([]string, error) {
	if !s.ready() {
		return nil, d.ErrUnavailable
	}
	records, err := s.Store.RecordsTx(c, s.Fresh, a.PlayerID)
	if err != nil {
		return nil, err
	}
	out := []string{}
	for _, r := range records {
		if r.Attack {
			continue
		}
		m, found, err := s.Store.ReadMatchTx(c, s.Fresh, r.MatchID, false)
		if err != nil || !found || m.Outcome == nil {
			return nil, errors.Join(err, d.ErrConflict)
		}
		for _, key := range reportKeys(m) {
			if key != "" {
				out = append(out, key)
			}
		}
	}
	return out, nil
}

// Records lists the player's retained matches, newest first.
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
		view := d.RecordView{Record: r}
		if view.Attacker, err = s.face(c, s.Fresh, m.Attacker); err != nil {
			return nil, err
		}
		if view.Defender, err = s.face(c, s.Fresh, m.Defender); err != nil {
			return nil, err
		}
		out = append(out, view)
	}
	return out, nil
}

// d.RecordDetail serves any retained record (records are shared through chat).
func (s Service) RecordDetail(c context.Context, record int64) (d.RecordDetail, error) {
	if !s.ready() {
		return d.RecordDetail{}, d.ErrUnavailable
	}
	now, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return d.RecordDetail{}, err
	}
	r, found, err := s.Store.RecordTx(c, s.Fresh, record)
	if err != nil || !found {
		return d.RecordDetail{}, errors.Join(err, d.ErrRefused)
	}
	m, found, err := s.Store.ReadMatchTx(c, s.Fresh, r.MatchID, false)
	if err != nil || !found || m.Outcome == nil {
		return d.RecordDetail{}, errors.Join(err, d.ErrConflict)
	}
	out := d.RecordDetail{ReportKeys: reportKeys(m), Wins: m.Outcome.Wins}
	if out.Attack, err = s.teams(c, s.Fresh, m.Attacker, m.AttackTeams[:len(out.Wins)], now, false); err != nil {
		return d.RecordDetail{}, err
	}
	defense := m.DefenseTeams[:min(len(m.DefenseTeams), len(out.Wins))]
	if out.Defense, err = s.teams(c, s.Fresh, m.Defender, defense, now, false); err != nil {
		return d.RecordDetail{}, err
	}
	for len(out.Defense) < len(out.Wins) {
		out.Defense = append(out.Defense, d.TeamView{})
	}
	return out, nil
}

// d.RankList is the global (rank_types 3) or the player's server (4) list, top 50.
func (s Service) RankList(c context.Context, a identity.ActorContext, global bool) (d.RankList, error) {
	if !s.ready() {
		return d.RankList{}, d.ErrUnavailable
	}
	_, catalog, err := s.catalogTx(c, s.Fresh)
	if err != nil {
		return d.RankList{}, err
	}
	standings, err := s.Store.StandingsTx(c, s.Fresh)
	if err != nil {
		return d.RankList{}, err
	}
	out := d.RankList{Rows: []d.Entry{}}
	for _, r := range catalog.Rank(standings) {
		if r.Player == a.PlayerID {
			out.Mine = r
		}
		if len(out.Rows) == rankListSize || !global && r.Server != a.LogicalServerID {
			continue
		}
		face, err := s.face(c, s.Fresh, r.Player)
		if err != nil {
			return d.RankList{}, err
		}
		out.Rows = append(out.Rows, d.Entry{Face: face, Ranked: r})
	}
	return out, nil
}

// ReadCatalogDisplayOriginsTx proves this owner's 1 on 1 titles (100002-100005)
// from settled Sunday snapshots; the producer starts with the mode, so its
// history is complete (no legacy 1 on 1 titles exist in this backend).
func (s Service) ReadCatalogDisplayOriginsTx(c context.Context, q tx.Queryer, r app.CatalogOriginRequest) (app.CatalogOriginObservation, error) {
	out := app.CatalogOriginObservation{Request: r, Origins: []app.Origin{}}
	if q == nil || s.Store == nil || s.Content == nil || s.Entitlements == nil || !r.PlayerID.Valid() || r.Family != "title" || r.CatalogID < 100002 || r.CatalogID > 100005 || len(r.Revision) != 64 {
		return out, app.ErrUnavailable
	}
	catalog, err := s.Content.ReadPlayerDisplayCatalogTx(c, q, r.Revision)
	if err != nil {
		return out, err
	}
	if v, ok := catalog.Find(r.Family, r.CatalogID); !ok || v.Type != 2 {
		return out, app.ErrConflict
	}
	awards, err := s.Store.TitlesTx(c, q, r.PlayerID, r.CatalogID)
	if err != nil {
		return out, err
	}
	canonical := map[string]app.Origin{}
	for _, a := range awards {
		if a.StartsAt.After(r.ObservedAt) {
			continue
		}
		starts := a.StartsAt.UTC()
		o := app.Origin{PlayerID: r.PlayerID, Key: fmt.Sprintf("one-on-one:%d:%d", a.Day, a.TitleID), Owner: "OneOnOne", Family: "title", CatalogID: a.TitleID, StartsAt: &starts, EndTime: a.End, Revision: r.Revision, StateVersion: 1}
		canonical[o.Key] = o
		out.Origins = append(out.Origins, o)
	}
	mirror, err := s.Entitlements.ReadDisplayEntitlementsTx(c, q, r.PlayerID, "title")
	if err != nil {
		return out, err
	}
	for _, m := range mirror {
		if m.Owner != "OneOnOne" {
			continue
		}
		own, ok := canonical[m.Key]
		if !ok || own.CatalogID != m.CatalogID || own.EndTime != m.EndTime {
			return out, app.ErrConflict
		}
	}
	out.Qualified, out.CompleteHistory = true, true
	return out, nil
}

var _ app.CatalogExternalOrigins = Service{}

// Reconciler applies owed transitions and abandoned matches promptly (generation reconcile provider).
type Reconciler struct{ Service Service }

func (Reconciler) Name() string { return "one-on-one" }

// openMatchGrace leaves fresh matches to their own START.
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
		if err := r.match(c, id, op, now); err != nil {
			return out, err
		}
		out.Settled++
	}
	return out, nil
}

func (r Reconciler) match(c context.Context, id ids.UUID, op gen.TimedOperation, now time.Time) error {
	s := r.Service
	m, found, err := s.Store.ReadMatchTx(c, s.Fresh, id, false)
	if err != nil || !found {
		return errors.Join(err, d.ErrConflict)
	}
	for _, round := range m.Rounds {
		if round.Forfeit() {
			continue
		}
		attempt, found, err := s.Combat.AttemptTx(c, s.Fresh, round.AttemptID)
		if err != nil || !found {
			return errors.Join(err, d.ErrConflict)
		}
		if attempt.State == cd.Staged && attempt.Closable(now) {
			return s.close(c, m, op.Operation())
		}
	}
	_, err = s.conclude(c, m, op.Operation(), time.Time{})
	return err
}

// PublicHistoryTx is the 1829 HISTORY SUPER_ARENA entry inside the caller's
// transaction: server rank, lifetime totals and partner usage.
func (s Service) PublicHistoryTx(c context.Context, q tx.Queryer, pid identity.PlayerID, _ time.Time) (cd.History, error) {
	if !s.ready() {
		return cd.History{}, d.ErrUnavailable
	}
	p, totals, found, err := s.Store.ReadPlayerTx(c, q, pid, false)
	if err != nil || !found {
		return cd.History{}, err
	}
	_, catalog, err := s.catalogTx(c, q)
	if err != nil {
		return cd.History{}, err
	}
	standings, err := s.Store.StandingsTx(c, q)
	if err != nil {
		return cd.History{}, err
	}
	var rank int64
	for _, r := range catalog.Rank(standings) {
		if r.Player == pid {
			rank = r.ServerRank
		}
	}
	usage, err := s.Store.UsageTx(c, q, pid)
	return cd.History{Rank: rank, Fights: totals.Fights, Wins: totals.Wins, Version: p.StateVersion, Partners: usage}, err
}
