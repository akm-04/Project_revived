package championsleague

import (
	"context"
	"errors"
	"fmt"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/application/playerroot"
	d "gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"slices"
	"strconv"
	"time"
)

type event struct {
	kind   string
	number int64
	at     time.Time
}

func nextEvent(cat d.Catalog, r d.Root) event {
	e := event{"DAY", r.Day + 1, cat.DayAt(r.Day + 1)}
	season := cat.SeasonNumbered(r.Season)
	if r.SettledSeason < r.Season && !season.ClosesAt.After(e.at) {
		e = event{"SEASON", r.Season, season.ClosesAt}
	}
	if season.NextAt.Before(e.at) {
		e = event{"ROLL", r.Season + 1, season.NextAt}
	}
	return e
}
func due(cat d.Catalog, r d.Root, at time.Time) bool { return !at.Before(nextEvent(cat, r).at) }

type cutoffProof struct {
	Store Store
	Fresh tx.Queryer
	Event event
}

func (p cutoffProof) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	s, ok, e := p.Store.SettlementTx(c, p.Fresh, p.Event.kind, p.Event.number)
	if e != nil || !ok || !s.CutoffAt.Equal(p.Event.at) {
		return tx.Resolution{State: tx.ResolutionUnknown}, e
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: s}, nil
}

// Due serializes chronological cutoff events before any new gameplay change.
// It initializes no missing root and awards no invented historical population.
func (s Service) dueBatch(c context.Context, parent operation.Context, limit int) (applied int, result error) {
	if !s.ready() {
		return applied, d.ErrUnavailable
	}
	if limit < 1 || limit > 1000 {
		return applied, d.ErrInvalid
	}
	var e error
	if parent, e = s.pin(c, parent); e != nil {
		return applied, e
	}
	for range limit {
		r, ok, e := s.Store.RootTx(c, s.Fresh, false)
		if e != nil || !ok {
			return applied, e
		}
		_, cat, e := s.catalog(c, s.Fresh, parent)
		if e != nil {
			return applied, e
		}
		now, e := s.Timed.Binder.Time.Now(c)
		if e != nil {
			return applied, e
		}
		ev := nextEvent(cat, r)
		if now.Before(ev.at) {
			return applied, nil
		}
		op, e := child(parent, fmt.Sprintf("%s:%d", ev.kind, ev.number))
		if e != nil {
			return applied, e
		}
		_, _, e = s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), cutoffProof{s.Store, s.Fresh, ev}, func(c context.Context, sc gen.TimedScope) error { return s.cutoff(c, sc, ev) })
		if e != nil {
			return applied, e
		}
		applied++
	}
	return applied, nil
}

func (s Service) Due(c context.Context, parent operation.Context, limit int) error {
	_, e := s.dueBatch(c, parent, limit)
	return e
}

// lockRoots discovers no mode lock. It locks canonical recipients in global
// player-id order (logical-server batches follow that same order), then root604.
func (s Service) lockRoots(c context.Context, t tx.Tx, players []d.Player) (map[identity.PlayerID]playerroot.Root, error) {
	sorted := append([]d.Player(nil), players...)
	slices.SortFunc(sorted, func(a, b d.Player) int {
		if a.ID < b.ID {
			return -1
		}
		if a.ID > b.ID {
			return 1
		}
		return 0
	})
	out := map[identity.PlayerID]playerroot.Root{}
	for i := 0; i < len(sorted); {
		j := i + 1
		for j < len(sorted) && sorted[j].Server == sorted[i].Server {
			j++
		}
		pids := []identity.PlayerID{}
		for _, p := range sorted[i:j] {
			pids = append(pids, p.ID)
		}
		roots, e := s.Players.LockPlayerRootsTx(c, t, sorted[i].Server, pids)
		if e != nil {
			return nil, e
		}
		for _, r := range roots {
			out[r.PlayerID] = r
		}
		i = j
	}
	return out, nil
}
func (s Service) cutoff(c context.Context, sc gen.TimedScope, ev event) error {
	at := sc.Operation.DecisionAt()
	rev, cat, e := s.catalog(c, sc.Tx, sc.Operation.Operation())
	if e != nil {
		return e
	}
	before, ok, e := s.Store.RootTx(c, sc.Tx, false)
	if e != nil || !ok {
		return errors.Join(e, d.ErrConflict)
	}
	// Another caller may already have settled this exact event; immutable row is
	// positive evidence, and no alternate clock or reward computation is used.
	if prior, found, e := s.Store.SettlementTx(c, sc.Tx, ev.kind, ev.number); e != nil {
		return e
	} else if found {
		if !prior.CutoffAt.Equal(ev.at) {
			return d.ErrConflict
		}
		return nil
	}
	players, e := s.Store.PlayersTx(c, sc.Tx, false)
	if e != nil {
		return e
	}
	roots, e := s.lockRoots(c, sc.Tx, players)
	if e != nil {
		return e
	}
	root, ok, e := s.Store.RootTx(c, sc.Tx, true)
	if e != nil || !ok {
		return errors.Join(e, d.ErrConflict)
	}
	if root.Version != before.Version {
		return d.ErrConflict
	}
	current := nextEvent(cat, root)
	if current.kind != ev.kind || current.number != ev.number || !current.at.Equal(ev.at) || at.Before(ev.at) {
		return d.ErrDue
	}
	players, e = s.Store.PlayersTx(c, sc.Tx, true)
	if e != nil {
		return e
	}
	settled := d.Settlement{Kind: ev.kind, Number: ev.number, CutoffAt: ev.at, SettledAt: at, Revision: rev, Rows: []d.SettlementRow{}}
	origins := []OriginAward{}
	changed := map[identity.PlayerID]d.Player{}
	activeDay := cat.SeasonAt(ev.at.Add(-time.Nanosecond)).Open(ev.at.Add(-time.Nanosecond))
	switch ev.kind {
	case "DAY":
		for _, p := range players {
			if p.Season != root.Season {
				continue
			}
			rank := d.Rank(d.Order(players, p.Season, p.Group), p.ID)
			p.LastDay = d.Placement{Group: p.Group, Rank: rank, Points: p.Points, Participated: p.Participated, ScoreAt: p.ScoreAt, Tie: p.Tie}
			if activeDay && p.Participated && rank > 0 && rank <= 5 {
				p.QualifyingDays++
				settled.Rows = append(settled.Rows, d.SettlementRow{Player: p.ID, Placement: p.LastDay, QualifyingDays: p.QualifyingDays})
			}
			changed[p.ID] = p
		}
		root.Day = ev.number
	case "SEASON":
		for _, p := range players {
			if p.Season != ev.number {
				continue
			}
			place := d.FinalPlacement(players, p)
			if !place.Participated || place.Rank < 1 {
				continue
			}
			reward, ok := cat.FinalReward(place.Group, place.Rank)
			if !ok {
				continue
			}
			row := d.SettlementRow{Player: p.ID, Placement: place, Reward: reward}
			if row.Face, e = s.face(c, sc.Tx, p.ID); e != nil {
				return e
			}
			// Honor captures a currently valid saved defense; an unavailable preference
			// cannot create a synthetic fighter. Missing rows are omitted in the read.
			if row.Heroes, row.Pet, e = s.displayRows(c, sc.Tx, p.ID, p.Defense, ev.at); e != nil {
				return e
			}
			start := ev.at.UTC()
			key := fmt.Sprintf("league:season:%d", ev.number)
			if reward.BubbleID > 0 {
				origins = append(origins, OriginAward{Origin: playerdisplay.Origin{PlayerID: p.ID, Key: key + ":bubble", Owner: "ChampionsLeague", Family: "bubble", CatalogID: reward.BubbleID, StartsAt: &start, EndTime: start.Unix() + cat.BubbleSeconds, Revision: rev, StateVersion: 1}, Season: ev.number, Placement: place})
			}
			if place.Group == 3 && place.Rank <= 10 {
				p.TopSeasons++
				row.TopSeasons = p.TopSeasons
				if p.TopSeasons <= int64(len(cat.TitleIDs)) {
					title := cat.TitleIDs[p.TopSeasons-1]
					origins = append(origins, OriginAward{Origin: playerdisplay.Origin{PlayerID: p.ID, Key: fmt.Sprintf("league:title:%d", title), Owner: "ChampionsLeague", Family: "title", CatalogID: title, StartsAt: &start, EndTime: 0, Revision: rev, StateVersion: 1}, Season: ev.number, Placement: place, Count: p.TopSeasons})
				}
			}
			changed[p.ID] = p
			settled.Rows = append(settled.Rows, row)
		}
		root.SettledSeason = ev.number
	case "ROLL":
		if root.SettledSeason != root.Season {
			return d.ErrConflict
		}
		for _, p := range players {
			changed[p.ID] = cat.Rolled(p, ev.at)
		}
		root.Season = ev.number
	default:
		return d.ErrConflict
	}
	// All League child rows are acquired before foreign owners. No mail/grant
	// occurs until immutable owning facts and the cutoff snapshot are staged.
	for _, p := range players {
		if next, ok := changed[p.ID]; ok {
			if e = s.savePlayer(c, sc.Tx, &next, at); e != nil {
				return e
			}
		}
	}
	for _, o := range origins {
		if e = s.Store.PutOriginTx(c, sc.Tx, o); e != nil {
			return e
		}
	}
	if e = s.Store.PutSettlementTx(c, sc.Tx, settled); e != nil {
		return e
	}
	// Mail rank610 first, then Achievement620, then typed display mirrors. Root
	// witnesses315 are already held, including cross-server recipients.
	if ev.kind == "SEASON" {
		slices.SortFunc(settled.Rows, func(a, b d.SettlementRow) int {
			if a.Player < b.Player {
				return -1
			}
			if a.Player > b.Player {
				return 1
			}
			return 0
		})
		for _, row := range settled.Rows {
			lines := giftLines(d.Gift{Items: row.Reward.Items, Crystal: row.Reward.Crystal})
			if len(lines) == 0 {
				continue
			}
			_, _, e = s.Mail.DeliverTx(c, sc.Tx, i5.SettlementMailRequest{Recipient: row.Player, SourceKind: "CHAMPIONS_LEAGUE_SEASON", SourceKey: strconv.FormatInt(ev.number, 10), Title: cat.Mail["CROSS_ARENA_MAIL_TITLE"], Sender: cat.Mail["CROSS_ARENA_MAIL_SENDER"], Body: fmt.Sprintf(cat.Mail["CROSS_ARENA_MAIL_TXT"], fmt.Sprintf("Group %d rank %d", row.Placement.Group, row.Placement.Rank)), PolicyVersion: d.PolicyID, Lines: lines, At: ev.at})
			if e != nil {
				return e
			}
		}
	}
	if ev.kind == "DAY" {
		for _, row := range settled.Rows {
			if e = s.Achievements.ObserveLeagueDaysTx(c, sc.Tx, row.Player, rev, row.QualifyingDays, ev.at); e != nil {
				return e
			}
		}
	}
	for _, award := range origins {
		o := award.Origin
		root, ok := roots[o.PlayerID]
		if !ok {
			return d.ErrConflict
		}
		if e = s.Recipient.ReceiveOriginTx(c, sc.Tx, root, o); e != nil {
			return e
		}
	}
	old := root.Version
	root.Version++
	root.UpdatedAt = at
	return s.Store.PutRootTx(c, sc.Tx, root, old)
}

// displayRows validates weak saved defense references through canonical roster
// reads. Consumed girls are omitted, never replaced or counted as owned; FIGHT
// still revalidates every requested participant through the strict rows path.
func (s Service) displayRows(c context.Context, q tx.Queryer, pid identity.PlayerID, l d.Lineup, at time.Time) ([]map[string]any, map[string]any, error) {
	out := []map[string]any{}
	for _, id := range l.Heroes {
		rows, _, e := s.rows(c, q, pid, d.Lineup{Heroes: []int64{id}}, at)
		if errors.Is(e, d.ErrRefused) {
			continue
		}
		if e != nil {
			return nil, nil, e
		}
		out = append(out, rows...)
	}
	var pet map[string]any
	if l.Pet > 0 {
		_, v, e := s.rows(c, q, pid, d.Lineup{Heroes: []int64{}, Pet: l.Pet}, at)
		if e != nil && !errors.Is(e, d.ErrRefused) {
			return nil, nil, e
		}
		pet = v
	}
	return out, pet, nil
}

// Keep the owning wire/reward mapping separate from these transactions.
