package oneonone

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"slices"
	"sort"
	"strconv"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/oneonone"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ErrTransitionDue makes a competition mutation yield to an owed settlement or promotion change.
var ErrTransitionDue = errors.New("oneonone: scheduled transition due first")

const (
	rewardMailKind = "ONE_ON_ONE_REWARD"
	// Private policy: the rank-1 frame (stack cap 1) travels in its own mail, once per player.
	frameMailKind = "ONE_ON_ONE_FRAME"
)

func Profile() tx.Profile {
	return tx.Profile{Name: "one-on-one", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

// matchProfile bounds START and match settlement, which freeze or settle one
// Combat attempt per round (up to 7) in a single transaction.
func matchProfile() tx.Profile {
	p := Profile()
	p.Name, p.StatementTimeout, p.TransactionTimeout, p.OperationTimeout = "one-on-one-match", 30*time.Second, 120*time.Second, 180*time.Second
	return p
}

func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

// child is a separate system operation; transitions never reuse a player's operation id.
func child(parent operation.Context, label string) (operation.Context, error) {
	id, err := ids.NewUUID()
	if err != nil {
		return operation.Context{}, err
	}
	return operation.Context{ID: id, StartedAt: parent.StartedAt, EntropySeed: parent.Derive("one-on-one:"+label, 0), Policies: parent.Policies}, nil
}

func (s Service) catalogTx(c context.Context, q tx.Queryer) (string, d.Catalog, error) {
	revision, err := s.Content.ActiveRevision(c, q)
	if err != nil {
		return "", d.Catalog{}, err
	}
	catalog, err := s.Content.OneOnOneCatalogTx(c, q, revision)
	return revision, catalog, err
}

// mutate applies owed transitions first and retries once when one falls due in between.
func (s Service) mutate(c context.Context, op operation.Context, run func() error) error {
	if !s.ready() {
		return d.ErrUnavailable
	}
	for range 2 {
		if _, err := s.Due(c, op); err != nil {
			return err
		}
		if err := run(); !errors.Is(err, ErrTransitionDue) {
			return err
		}
	}
	return ErrTransitionDue
}

// owed refuses a competition mutation while a transition is due.
func owed(catalog d.Catalog, root d.Competition, at time.Time) error {
	if _, due := catalog.NextDue(root, at); due {
		return ErrTransitionDue
	}
	return nil
}

type transitionEvidence struct {
	store  Store
	reader tx.Queryer
	next   d.Transition
}

func (e transitionEvidence) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	r, found, err := e.store.ReadCompetitionTx(c, e.reader, false)
	if err != nil || !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, err
	}
	marker := map[string]int64{d.TransitionSettle: r.SettledThrough, d.TransitionOpen: r.OpenedThrough, d.TransitionClose: r.ClosedThrough}[e.next.Kind]
	if marker < e.next.Key {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: marker}, nil
}

// Due applies every owed transition, oldest first, each in its own transaction.
func (s Service) Due(c context.Context, parent operation.Context) (int, error) {
	if !s.ready() {
		return 0, d.ErrUnavailable
	}
	applied := 0
	for {
		root, found, err := s.Store.ReadCompetitionTx(c, s.Fresh, false)
		if err != nil || !found {
			return applied, err
		}
		now, err := s.Timed.Binder.Time.Now(c)
		if err != nil {
			return applied, err
		}
		_, catalog, err := s.catalogTx(c, s.Fresh)
		if err != nil {
			return applied, err
		}
		next, due := catalog.NextDue(root, now)
		if !due {
			return applied, nil
		}
		op, err := child(parent, fmt.Sprintf("%s:%d", next.Kind, next.Key))
		if err != nil {
			return applied, err
		}
		_, _, err = s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), transitionEvidence{store: s.Store, reader: s.Fresh, next: next}, func(c context.Context, sc gen.TimedScope) error {
			return s.transitionTx(c, sc, next)
		})
		if err != nil {
			return applied, err
		}
		applied++
	}
}

func (s Service) transitionTx(c context.Context, sc gen.TimedScope, next d.Transition) error {
	at := sc.Operation.DecisionAt()
	root, found, err := s.Store.ReadCompetitionTx(c, sc.Tx, true)
	if err != nil || !found {
		return errors.Join(err, d.ErrConflict)
	}
	revision, catalog, err := s.catalogTx(c, sc.Tx)
	if err != nil {
		return err
	}
	current, due := catalog.NextDue(root, at)
	if !due || current != next {
		return nil
	}
	standings, err := s.Store.StandingsTx(c, sc.Tx)
	if err != nil {
		return err
	}
	ranked := catalog.Rank(standings)
	switch next.Kind {
	case d.TransitionSettle:
		err = s.settleTx(c, sc, catalog, revision, root, ranked, next)
		root.SettledThrough = next.Key
	case d.TransitionOpen:
		err = s.openTx(c, sc.Tx, catalog, &root, ranked, next.Key, at)
		root.OpenedThrough = next.Key
	default:
		err = s.closeTx(c, sc.Tx, at)
		root.ClosedThrough = next.Key
	}
	if err != nil {
		return err
	}
	old := root.StateVersion
	root.StateVersion, root.UpdatedAt = old+1, at
	return s.Store.SaveCompetitionTx(c, sc.Tx, root, old)
}

// settleTx mails legend_reward by server rank, the rank-1 frame once, records
// Sunday titles by global rank and feeds Achievement 100002 per server.
func (s Service) settleTx(c context.Context, sc gen.TimedScope, catalog d.Catalog, revision string, root d.Competition, ranked []d.Ranked, next d.Transition) error {
	at := sc.Operation.DecisionAt()
	settlement := d.Settlement{Day: next.Key, CutoffAt: next.At, SettledAt: at, CompetitionVersion: root.StateVersion, ContentRevision: revision}
	tops := map[identity.LogicalServerID][]identity.PlayerID{}
	sunday := d.Weekday(next.Key) == 7
	for _, a := range catalog.Awards(ranked, next.Key) {
		row := d.SettlementRow{Player: a.Player, Global: a.Global, ServerRank: a.ServerRank, Title: a.Title}
		if a.Reward != nil {
			m, _, err := s.Mail.DeliverTx(c, sc.Tx, i5.SettlementMailRequest{Recipient: a.Player, SourceKind: rewardMailKind, SourceKey: strconv.FormatInt(next.Key, 10),
				Title: catalog.Mail["LEGEND_MAIL_TITLE"], Sender: catalog.Mail["LEGEND_MAIL_SENDER"], Body: fmt.Sprintf(catalog.Mail["LEGEND_MAIL_TEXT"], a.ServerRank), PolicyVersion: d.ContractID, Lines: rewardLines(*a.Reward), At: at})
			if err != nil {
				return err
			}
			row.Mail = &m.MailUUID
			if a.Reward.FrameID > 0 {
				if _, _, err = s.Mail.DeliverTx(c, sc.Tx, i5.SettlementMailRequest{Recipient: a.Player, SourceKind: frameMailKind, SourceKey: strconv.FormatInt(int64(a.Player), 10),
					Title: catalog.Mail["LEGEND_MAIL_TITLE"], Sender: catalog.Mail["LEGEND_MAIL_SENDER"], Body: fmt.Sprintf(catalog.Mail["LEGEND_MAIL_TEXT"], a.ServerRank), PolicyVersion: d.ContractID,
					Lines: []grant.Line{{Kind: grant.StackItem, ItemID: a.Reward.FrameID, Amount: 1}}, At: at}); err != nil {
					return err
				}
			}
		}
		if a.Title != nil {
			row.TitleEnd = at.Unix() + a.Title.Seconds
		}
		settlement.Rows = append(settlement.Rows, row)
		if _, seen := tops[a.Server]; !seen {
			tops[a.Server] = []identity.PlayerID{}
		}
		if a.ServerRank <= 3 {
			tops[a.Server] = append(tops[a.Server], a.Player)
		}
	}
	if err := s.Store.InsertSettlementTx(c, sc.Tx, settlement); err != nil {
		return err
	}
	if !sunday {
		return nil
	}
	servers := make([]identity.LogicalServerID, 0, len(tops))
	for server := range tops {
		servers = append(servers, server)
	}
	slices.Sort(servers)
	for _, server := range servers {
		if err := s.Achievements.ObserveOneOnOneWeekTx(c, sc.Tx, server, next.Key, revision, tops[server], at); err != nil {
			return err
		}
	}
	return nil
}

// rewardLines is the legend_reward row as mail attachments.
func rewardLines(reward d.Reward) []grant.Line {
	lines := []grant.Line{}
	for _, scalar := range []struct {
		key    string
		amount int64
	}{{"crystal", reward.Crystal}, {"mana", reward.Mana}, {"top_coin", reward.TopCoin}} {
		if scalar.amount > 0 {
			lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: scalar.key, Amount: scalar.amount})
		}
	}
	for _, item := range reward.Items {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: item[0], Amount: item[1]})
	}
	return lines
}

// openTx fills vacancies and starts promotion for the remaining eligible players.
func (s Service) openTx(c context.Context, t tx.Tx, catalog d.Catalog, root *d.Competition, ranked []d.Ranked, week int64, at time.Time) error {
	opening := catalog.OpenPromotion(ranked, week)
	players := make([]identity.PlayerID, 0, len(opening.Moves)+len(opening.Entrants))
	for pid := range opening.Moves {
		players = append(players, pid)
	}
	for pid := range opening.Entrants {
		players = append(players, pid)
	}
	slices.Sort(players)
	for _, pid := range players {
		err := s.update(c, t, pid, at, d.Totals{}, func(p d.Player) d.Player {
			if position, moved := opening.Moves[pid]; moved {
				p.Position = position
				return p
			}
			p.Mode, p.PromotionWeek, p.Candidates, p.Opponent, p.Challenges, p.PromotionWins = d.ModePromotion, week, opening.Entrants[pid], 0, 0, 0
			return p
		})
		if err != nil {
			return err
		}
	}
	root.MasterCount, root.SeniorCount = 0, 0
	for _, r := range ranked {
		level := r.Level
		if position, moved := opening.Moves[r.Player]; moved {
			level = position.Level
		}
		switch level {
		case d.LevelMaster:
			root.MasterCount++
		case d.LevelSenior:
			root.SeniorCount++
		}
	}
	return nil
}

func (s Service) closeTx(c context.Context, t tx.Tx, at time.Time) error {
	promoting, err := s.Store.PromotingTx(c, t)
	if err != nil {
		return err
	}
	for _, pid := range promoting {
		if err = s.update(c, t, pid, at, d.Totals{}, d.EndPromotion); err != nil {
			return err
		}
	}
	return nil
}

// update locks, changes and saves one player.
func (s Service) update(c context.Context, t tx.Tx, pid identity.PlayerID, at time.Time, totals d.Totals, change func(d.Player) d.Player) error {
	p, _, found, err := s.Store.ReadPlayerTx(c, t, pid, true)
	if err != nil || !found {
		return errors.Join(err, d.ErrConflict)
	}
	next := change(p)
	next.StateVersion, next.UpdatedAt = p.StateVersion+1, at
	return s.Store.SavePlayerTx(c, t, next, p.StateVersion, totals)
}

// gate requires function 16: level 55 (client type-6 rule) and 15 owned girls (function tip).
func (s Service) gate(c context.Context, q tx.Queryer, catalog d.Catalog, pid identity.PlayerID, at time.Time) error {
	profile, found, err := s.Directory.ProfileTx(c, q, pid)
	if err != nil || !found {
		return errors.Join(err, d.ErrRefused)
	}
	rows, err := s.heroRows(c, q, pid, at)
	if err != nil {
		return err
	}
	if profile.Level < catalog.RequiredLevel || int64(len(rows)) < catalog.RequiredHeroes {
		return fmt.Errorf("%w: function %d closed", d.ErrRefused, catalog.FunctionID)
	}
	return nil
}

func (s Service) Load(c context.Context, a identity.ActorContext, op operation.Context) (d.ArenaView, error) {
	var out d.ArenaView
	err := s.mutate(c, op, func() error {
		_, _, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
			at := sc.Operation.DecisionAt()
			if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
				return err
			}
			revision, catalog, err := s.catalogTx(c, sc.Tx)
			if err != nil {
				return err
			}
			root, found, err := s.Store.ReadCompetitionTx(c, sc.Tx, false)
			if err != nil {
				return err
			}
			if !found {
				root = catalog.NewCompetition(revision, at)
				if err = s.Store.CreateCompetitionTx(c, sc.Tx, root); err != nil {
					return err
				}
			}
			if err = owed(catalog, root, at); err != nil {
				return err
			}
			p, _, found, err := s.Store.ReadPlayerTx(c, sc.Tx, a.PlayerID, true)
			if err != nil {
				return err
			}
			if !found {
				if err = s.gate(c, sc.Tx, catalog, a.PlayerID, at); err != nil {
					return err
				}
				p = catalog.NewPlayer(a.PlayerID, a.LogicalServerID, revision, at)
				if err = s.Store.InsertPlayerTx(c, sc.Tx, p); err != nil {
					return err
				}
			}
			next := catalog.Rolled(p, at)
			if !samePlayer(p, next) {
				next.StateVersion, next.UpdatedAt = p.StateVersion+1, at
				if err = s.Store.SavePlayerTx(c, sc.Tx, next, p.StateVersion, d.Totals{}); err != nil {
					return err
				}
			}
			out, err = s.arenaView(c, sc.Tx, catalog, next, at)
			return err
		})
		return err
	})
	return out, err
}

func samePlayer(a, b d.Player) bool {
	x, _ := json.Marshal(a)
	y, _ := json.Marshal(b)
	return string(x) == string(y)
}

func (s Service) arenaView(c context.Context, q tx.Queryer, catalog d.Catalog, p d.Player, at time.Time) (d.ArenaView, error) {
	standings, err := s.Store.StandingsTx(c, q)
	if err != nil {
		return d.ArenaView{}, err
	}
	me, found := d.Find(catalog.Rank(standings), p.PlayerID)
	if !found {
		return d.ArenaView{}, d.ErrConflict
	}
	view := d.ArenaView{Player: p, Ranked: me, ServerTime: at}
	if p.Mode == d.ModePromotion {
		end := catalog.PromotionClosesAt(p.PromotionWeek)
		view.PromotionEnd = &end
	}
	return view, nil
}

// ChangeTeams saves exactly the group's team count of owned, distinct heroes and pets.
func (s Service) ChangeTeams(c context.Context, a identity.ActorContext, teams []d.Team, op operation.Context) error {
	if !s.ready() {
		return d.ErrUnavailable
	}
	_, _, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		_, catalog, err := s.catalogTx(c, sc.Tx)
		if err != nil {
			return err
		}
		p, _, found, err := s.Store.ReadPlayerTx(c, sc.Tx, a.PlayerID, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrRefused)
		}
		if !d.ValidTeams(teams, catalog.Level(p.Level).Teams) {
			return d.ErrInvalid
		}
		if _, err = s.teams(c, sc.Tx, a.PlayerID, teams, at, true); err != nil {
			return err
		}
		next := p
		next.Teams = teams
		next.StateVersion, next.UpdatedAt = p.StateVersion+1, at
		return s.Store.SavePlayerTx(c, sc.Tx, next, p.StateVersion, d.Totals{})
	})
	return err
}

// Match draws a fresh candidate set (free and unlimited; C5C policy) or, in
// promotion, returns the fixed promotion candidates.
func (s Service) Match(c context.Context, a identity.ActorContext, op operation.Context) ([]d.Entry, error) {
	var out []d.Entry
	err := s.mutate(c, op, func() error {
		_, _, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
			at := sc.Operation.DecisionAt()
			if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
				return err
			}
			_, catalog, err := s.catalogTx(c, sc.Tx)
			if err != nil {
				return err
			}
			p, _, found, err := s.Store.ReadPlayerTx(c, sc.Tx, a.PlayerID, true)
			if err != nil || !found {
				return errors.Join(err, d.ErrRefused)
			}
			standings, err := s.Store.StandingsTx(c, sc.Tx)
			if err != nil {
				return err
			}
			ranked := catalog.Rank(standings)
			next := catalog.Rolled(p, at)
			chosen := next.Candidates
			if next.Mode == d.ModeNormal {
				next.Refreshes++
				next.Offered = catalog.Offer(ranked, p.PlayerID, next.OfferedDay, next.Refreshes)
				chosen = next.Offered
			}
			next.StateVersion, next.UpdatedAt = p.StateVersion+1, at
			if err = s.Store.SavePlayerTx(c, sc.Tx, next, p.StateVersion, d.Totals{}); err != nil {
				return err
			}
			out = []d.Entry{}
			for _, pid := range chosen {
				r, ok := d.Find(ranked, pid)
				if !ok {
					continue
				}
				face, err := s.face(c, sc.Tx, pid)
				if err != nil {
					return err
				}
				out = append(out, d.Entry{Face: face, Ranked: r})
			}
			return nil
		})
		return err
	})
	return out, err
}

// EnemyTeam shows a competitor's defense: the group's team count, with the
// last team_hide teams and any missing team empty.
func (s Service) EnemyTeam(c context.Context, enemy identity.PlayerID) ([]d.TeamView, error) {
	if !s.ready() {
		return nil, d.ErrUnavailable
	}
	now, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	_, catalog, err := s.catalogTx(c, s.Fresh)
	if err != nil {
		return nil, err
	}
	p, _, found, err := s.Store.ReadPlayerTx(c, s.Fresh, enemy, false)
	if err != nil || !found {
		return nil, errors.Join(err, d.ErrRefused)
	}
	level := catalog.Level(p.Level)
	visible := p.Teams[:min(int64(len(p.Teams)), level.Teams-level.Hidden)]
	views, err := s.teams(c, s.Fresh, enemy, visible, now, false)
	if err != nil {
		return nil, err
	}
	for int64(len(views)) < level.Teams {
		views = append(views, d.TeamView{})
	}
	return views, nil
}

func (s Service) heroRows(c context.Context, q tx.Queryer, pid identity.PlayerID, at time.Time) (map[string]any, error) {
	detail := map[string]any{}
	if err := s.Heroes.OverlayMID1(c, q, identity.ActorContext{PlayerID: pid}, false, at, detail); err != nil {
		return nil, err
	}
	body, _ := detail["49"].(map[string]any)
	rows, _ := body["heros"].(map[string]any)
	return rows, nil
}

func (s Service) petRows(c context.Context, q tx.Queryer, pid identity.PlayerID, at time.Time) (map[string]map[string]any, error) {
	detail := map[string]any{}
	if err := s.Pets.OverlayMID1(c, q, identity.ActorContext{PlayerID: pid}, false, at, detail); err != nil {
		return nil, err
	}
	body, _ := detail["780"].(map[string]any)
	raw, _ := body["pets"].([]any)
	out := map[string]map[string]any{}
	for _, x := range raw {
		if row, ok := x.(map[string]any); ok {
			out[fmt.Sprint(row["pet_id"])] = row
		}
	}
	return out, nil
}

// teams reads the owner's current roster rows; strict refuses a hero or pet
// the owner no longer holds, otherwise such a member is left out (history views).
func (s Service) teams(c context.Context, q tx.Queryer, pid identity.PlayerID, teams []d.Team, at time.Time, strict bool) ([]d.TeamView, error) {
	heroes, err := s.heroRows(c, q, pid, at)
	if err != nil {
		return nil, err
	}
	// The pet roster is read only when a team names a pet; an owner without pets has none.
	pets := map[string]map[string]any{}
	if slices.ContainsFunc(teams, func(t d.Team) bool { return t.Pet > 0 }) {
		if pets, err = s.petRows(c, q, pid, at); err != nil {
			return nil, err
		}
	}
	out := []d.TeamView{}
	for _, t := range teams {
		view := d.TeamView{Heroes: []map[string]any{}}
		for _, id := range t.Heroes {
			row, ok := heroes[strconv.FormatInt(id, 10)].(map[string]any)
			if !ok && strict {
				return nil, fmt.Errorf("%w: hero %d not owned", d.ErrRefused, id)
			}
			if ok {
				view.Heroes = append(view.Heroes, row)
			}
		}
		if t.Pet > 0 {
			row, ok := pets[strconv.FormatInt(t.Pet, 10)]
			if !ok && strict {
				return nil, fmt.Errorf("%w: pet %d not owned", d.ErrRefused, t.Pet)
			}
			view.Pet = row
		}
		out = append(out, view)
	}
	return out, nil
}

func (s Service) face(c context.Context, q tx.Queryer, pid identity.PlayerID) (d.Face, error) {
	profile, found, err := s.Directory.ProfileTx(c, q, pid)
	if err != nil || !found {
		return d.Face{}, errors.Join(err, d.ErrUnavailable)
	}
	return d.Face{Player: pid, Name: profile.Name, Level: profile.Level, AvatarID: profile.AvatarID, FrameID: profile.AvatarFrameID, ConquerLevel: profile.ConquerLevel, ConquerLoop: profile.ConquerLoopID}, nil
}

type timedReceipt struct{ receipt.Resolver }

func (r timedReceipt) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation(), CommitError: q.CommitError, Attempt: q.Attempt})
}

// purchase runs one crystal-priced change with an operation receipt for unknown COMMIT.
func (s Service) purchase(c context.Context, a identity.ActorContext, op operation.Context, name string, change func(d.Catalog, d.Player, d.VIP, bool, time.Time) (d.Player, int64, error)) (d.Player, error) {
	var out d.Player
	if !s.ready() {
		return out, d.ErrUnavailable
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "one-on-one", Operation: name, SemanticKey: op.ID.String()}
	fp, err := receipt.FingerprintRequest(map[string]any{"player": int64(a.PlayerID), "operation": name})
	if err != nil {
		return out, err
	}
	_, res, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		_, catalog, err := s.catalogTx(c, sc.Tx)
		if err != nil {
			return err
		}
		p, _, found, err := s.Store.ReadPlayerTx(c, sc.Tx, a.PlayerID, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrRefused)
		}
		privilege, err := s.Privileges.SnapshotTx(c, sc.Tx, a.PlayerID, at)
		if err != nil {
			return err
		}
		next, cost, err := change(catalog, p, catalog.Privilege(privilege.VIPLevel), privilege.MonthlyPrivilegeActive, at)
		if err != nil {
			return err
		}
		if _, err = s.Costs.DebitMaterialCostTx(c, sc.Tx, a.PlayerID, i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: cost}}}, sc.Operation.Operation()); err != nil {
			return err
		}
		next.StateVersion, next.UpdatedAt = p.StateVersion+1, at
		if err = s.Store.SavePlayerTx(c, sc.Tx, next, p.StateVersion, d.Totals{}); err != nil {
			return err
		}
		out = next
		raw, err := json.Marshal(map[string]any{"tries_left": next.TriesLeft, "purchases": next.Purchases, "last_fight_at": next.LastFightAt})
		if err != nil {
			return err
		}
		rr, err := receipt.New(sc.Operation.Operation(), id, "I7C5C_ONE_ON_ONE", "gxb.oneonone."+name+".v1", raw, fp)
		if err != nil {
			return err
		}
		rr.PolicyVersion, rr.ActorAccountUID, rr.ContextID = d.ContractID, string(a.AccountUID), a.ContextID.UUID()
		_, err = s.Receipts.PutTx(c, sc.Tx, rr)
		return err
	})
	if err == nil && res.Reconciled {
		p, _, _, readErr := s.Store.ReadPlayerTx(c, s.Fresh, a.PlayerID, false)
		return p, readErr
	}
	return out, err
}

func (s Service) BuyTimes(c context.Context, a identity.ActorContext, op operation.Context) (d.Player, error) {
	return s.purchase(c, a, op, "buy-times", func(catalog d.Catalog, p d.Player, v d.VIP, _ bool, at time.Time) (d.Player, int64, error) {
		return catalog.Buy(p, v, at)
	})
}

func (s Service) ResetTime(c context.Context, a identity.ActorContext, op operation.Context) (d.Player, error) {
	return s.purchase(c, a, op, "reset-time", func(catalog d.Catalog, p d.Player, v d.VIP, monthly bool, at time.Time) (d.Player, int64, error) {
		return catalog.ResetTimer(p, v, monthly, at)
	})
}

// sortedPlayers returns the ids in lock order.
func sortedPlayers(ids ...identity.PlayerID) []identity.PlayerID {
	out := append([]identity.PlayerID(nil), ids...)
	sort.Slice(out, func(i, j int) bool { return out[i] < out[j] })
	return out
}
