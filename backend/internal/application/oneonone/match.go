package oneonone

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"slices"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/oneonone"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	terminalKind = "ONE_ON_ONE_SETTLED"
	closedKind   = "ONE_ON_ONE_CLOSED"
	// Private policy: a round result is due within this window, after which an unresolved attempt may close.
	resultWindow = 10 * time.Minute
	// Private policy: an identical START within this window of the previous one returns it (client retry).
	replayWindow = time.Minute
	// Private policy: START answers within this budget, inside the client's 30 s request timeout.
	startBudget = 25 * time.Second
)

type StartCommand struct {
	Formations []d.Team
	Enemy      identity.PlayerID
}

func fingerprint(pid identity.PlayerID, r StartCommand) string {
	raw, _ := json.Marshal(map[string]any{"policy": d.ContractID, "player": int64(pid), "formations": r.Formations, "enemy": int64(r.Enemy)})
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}

// pin binds the active content revision to the operation once, so every owner
// read in START and its retries observes one revision (combat checks it is active).
func (s Service) pin(c context.Context, op operation.Context) (operation.Context, error) {
	if _, bound := op.Policies.Get("content"); bound {
		return op, nil
	}
	revision, err := s.Content.ActiveRevision(c, s.Fresh)
	if err != nil {
		return op, err
	}
	op.Policies, err = policy.NewSet(append(op.Policies.Refs(), policy.Ref{Name: "content", Version: revision})...)
	return op, err
}

// Each round has its own locator: the Combat root allows one unresolved attempt per locator.
func roundLocator(match ids.UUID, round int) cd.Locator {
	return cd.Locator{DomainKind: "ONE_ON_ONE", AuthorityScope: d.CompetitionID, DomainLocator: fmt.Sprintf("match:%s:round:%d", match, round)}
}

func semanticReceipt(match ids.UUID, round int) string {
	return fmt.Sprintf("one-on-one:%s:%d", match, round)
}

// Start admits one match, resolves its rounds outside locks and settles it once.
func (s Service) Start(c context.Context, a identity.ActorContext, r StartCommand, op operation.Context) (d.MatchView, error) {
	if !r.Enemy.Valid() || len(r.Formations) < 1 || len(r.Formations) > 7 {
		return d.MatchView{}, d.ErrInvalid
	}
	if !s.ready() {
		return d.MatchView{}, d.ErrUnavailable
	}
	op, err := s.pin(c, op)
	if err != nil {
		return d.MatchView{}, err
	}
	fp := fingerprint(a.PlayerID, r)
	// The stock client waits 30 s for this form-data request (Backend.lua).
	deadline := time.Now().Add(startBudget)
	now, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return d.MatchView{}, err
	}
	latest, found, err := s.Store.LatestMatchTx(c, s.Fresh, a.PlayerID)
	if err != nil {
		return d.MatchView{}, err
	}
	if found && latest.Fingerprint == fp && (latest.Status == d.StatusStarted || now.Sub(latest.StartedAt) < replayWindow) {
		return s.finish(c, a, latest, op, deadline)
	}
	// Server-authoritative results always apply: an abandoned match settles first.
	if found && latest.Status == d.StatusStarted {
		if _, err = s.finish(c, a, latest, op, deadline); err != nil {
			return d.MatchView{}, fmt.Errorf("%w: previous match unresolved", errors.Join(err, d.ErrRefused))
		}
	}
	var m d.Match
	err = s.mutate(c, op, func() error {
		evidence := startEvidence{service: s, player: a.PlayerID, fingerprint: fp, since: op.StartedAt}
		_, res, err := s.Timed.Run(c, op, matchProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), evidence, func(c context.Context, sc gen.TimedScope) error {
			var err error
			m, err = s.admit(c, sc, a, r, fp)
			return err
		})
		if err == nil && res.Reconciled {
			m, err = evidence.match(c)
		}
		return err
	})
	if err != nil {
		return d.MatchView{}, err
	}
	return s.finish(c, a, m, op, deadline)
}

type startEvidence struct {
	service     Service
	player      identity.PlayerID
	fingerprint string
	since       time.Time
}

func (e startEvidence) match(c context.Context) (d.Match, error) {
	m, found, err := e.service.Store.LatestMatchTx(c, e.service.Fresh, e.player)
	if err != nil || !found || m.Fingerprint != e.fingerprint || m.StartedAt.Before(e.since.Add(-time.Second)) {
		return d.Match{}, errors.Join(err, d.ErrConflict)
	}
	return m, nil
}

func (e startEvidence) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	m, err := e.match(c)
	if err != nil {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: m.ID}, nil
}

func (s Service) admit(c context.Context, sc gen.TimedScope, a identity.ActorContext, r StartCommand, fp string) (d.Match, error) {
	at := sc.Operation.DecisionAt()
	if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
		return d.Match{}, err
	}
	// Admission changes no position, so it does not hold the competition root
	// while freezing; position changes conflict on the locked player rows.
	root, found, err := s.Store.ReadCompetitionTx(c, sc.Tx, false)
	if err != nil || !found {
		return d.Match{}, errors.Join(err, d.ErrRefused)
	}
	revision, _ := sc.Operation.Operation().Policies.Get("content")
	catalog, err := s.Content.OneOnOneCatalogTx(c, sc.Tx, revision)
	if err != nil {
		return d.Match{}, err
	}
	if err = owed(catalog, root, at); err != nil {
		return d.Match{}, err
	}
	players := map[identity.PlayerID]d.Player{}
	for _, pid := range sortedPlayers(a.PlayerID, r.Enemy) {
		p, _, found, err := s.Store.ReadPlayerTx(c, sc.Tx, pid, true)
		if err != nil || !found {
			return d.Match{}, errors.Join(err, d.ErrRefused)
		}
		players[pid] = p
	}
	attacker, defender := players[a.PlayerID], players[r.Enemy]
	mode := attacker.Mode
	chosen := attacker.Offered
	sameGroup := d.Group(defender.Level) == d.Group(attacker.Level)
	if mode == d.ModePromotion {
		chosen = attacker.Candidates
		sameGroup = d.Group(defender.Level) == d.Group(attacker.Level)-1
	}
	locked := mode == d.ModePromotion && attacker.Opponent != 0 && attacker.Opponent != r.Enemy
	if !slices.Contains(chosen, r.Enemy) || !sameGroup || locked {
		return d.Match{}, d.ErrRefused
	}
	rounds := catalog.Level(defender.Level).Teams
	if !d.ValidTeams(r.Formations, rounds) {
		return d.Match{}, d.ErrInvalid
	}
	// Ownership of every formation member is enforced by the Combat freezer (OWNED_SELF).
	next, err := catalog.Admit(attacker, at)
	if err != nil {
		return d.Match{}, err
	}
	if mode == d.ModePromotion {
		next.Opponent = r.Enemy
	}
	next.StateVersion, next.UpdatedAt = attacker.StateVersion+1, at
	if err = s.Store.SavePlayerTx(c, sc.Tx, next, attacker.StateVersion, d.Totals{}); err != nil {
		return d.Match{}, err
	}
	id, err := ids.NewUUID()
	if err != nil {
		return d.Match{}, err
	}
	defense := defender.Teams[:min(int64(len(defender.Teams)), rounds)]
	m := d.Match{ID: id, Attacker: a.PlayerID, Defender: r.Enemy, Mode: mode, Fingerprint: fp, AttackTeams: r.Formations, DefenseTeams: defense, StartedAt: at.UTC(), Status: d.StatusStarted, StateVersion: 1}
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, revision, at)
	if err != nil {
		return d.Match{}, err
	}
	requests := []combat.StartRequest{}
	for i := range defense {
		battle := combat.BattleRequest{CampaignType: d.CampaignType, BattleID: d.BattleID, TeamA: participants(cd.OwnedSelf, a.PlayerID, r.Formations[i].Heroes, cd.HeroActor),
			PetsA: participants(cd.OwnedSelf, a.PlayerID, pet(r.Formations[i]), cd.PetActor), WavesB: [][]combat.Participant{participants(cd.OwnedForeign, r.Enemy, defense[i].Heroes, cd.HeroActor)},
			PetsB: participants(cd.OwnedForeign, r.Enemy, pet(defense[i]), cd.PetActor), Context: &cd.BattleContext{Transform: d.Transform}}
		requests = append(requests, combat.StartRequest{Actor: a, Locator: roundLocator(id, i+1), GenerationRef: d.ContractID, StartFingerprint: fp, ResultDeadline: at.Add(resultWindow), Battle: battle})
	}
	started := []combat.Started{}
	if len(requests) > 0 {
		if started, err = s.Combat.StartManyTx(c, sc.Tx, scope, requests); err != nil {
			return d.Match{}, err
		}
	}
	for i := range r.Formations {
		if i >= len(started) {
			m.Rounds = append(m.Rounds, d.Round{})
			continue
		}
		if started[i].Replayed {
			return d.Match{}, d.ErrConflict
		}
		m.Rounds = append(m.Rounds, d.Round{AttemptID: started[i].Attempt.ID})
	}
	return m, s.Store.InsertMatchTx(c, sc.Tx, m)
}

func pet(t d.Team) []int64 {
	if t.Pet > 0 {
		return []int64{t.Pet}
	}
	return nil
}

func participants(origin cd.Origin, owner identity.PlayerID, members []int64, kind cd.ActorKind) []combat.Participant {
	out := []combat.Participant{}
	for _, id := range members {
		out = append(out, combat.Participant{Origin: origin, Kind: kind, Player: owner, Identity: id})
	}
	return out
}

// finish concludes the match within the START budget and builds the result view.
func (s Service) finish(c context.Context, a identity.ActorContext, m d.Match, op operation.Context, deadline time.Time) (d.MatchView, error) {
	m, err := s.conclude(c, m, op, deadline)
	if err != nil {
		return d.MatchView{}, err
	}
	if m.Status != d.StatusSettled {
		return d.MatchView{}, fmt.Errorf("%w: match closed without result", d.ErrRefused)
	}
	return s.matchView(c, a, m)
}

// ErrUnresolved answers a START whose rounds are still resolving at its
// deadline; resolution continues detached, an identical START returns the
// result and the reconcile provider settles it regardless.
var ErrUnresolved = errors.New("oneonone: match rounds still resolving")

// conclude resolves a started match's rounds outside locks, on a context
// detached from the caller so work survives the request, and settles it once.
// Each wave resolves in parallel the fewest rounds that could decide the
// match, so no round after the decision is simulated; a permanently failed
// round closes the match. A zero deadline waits.
func (s Service) conclude(c context.Context, m d.Match, op operation.Context, deadline time.Time) (d.Match, error) {
	if m.Status != d.StatusStarted {
		return m, nil
	}
	var budget <-chan time.Time
	if !deadline.IsZero() {
		timer := time.NewTimer(time.Until(deadline))
		defer timer.Stop()
		budget = timer.C
	}
	for wave := d.Pending(m.Rounds); len(wave) > 0; wave = d.Pending(m.Rounds) {
		flights := make([]*combat.Flight, len(wave))
		for i, round := range wave {
			flights[i] = s.Combat.ResolveDetached(c, op, m.Rounds[round].AttemptID)
		}
		errs := []error{}
		for i, f := range flights {
			select {
			case <-f.Done:
				errs = append(errs, f.Err)
				m.Rounds[wave[i]].Star, m.Rounds[wave[i]].Resolved = f.Resolved.Resolution.Outcome.Star, f.Err == nil
			case <-budget:
				return m, ErrUnresolved
			}
		}
		for _, err := range errs {
			if errors.Is(err, cd.ErrResolverPermanent) {
				return m, errors.Join(err, s.close(c, m, op))
			}
		}
		if err := errors.Join(errs...); err != nil {
			return m, err
		}
	}
	return s.settle(c, m, op)
}

func (s Service) matchView(c context.Context, a identity.ActorContext, m d.Match) (d.MatchView, error) {
	now, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return d.MatchView{}, err
	}
	_, catalog, err := s.catalogTx(c, s.Fresh)
	if err != nil {
		return d.MatchView{}, err
	}
	p, _, found, err := s.Store.ReadPlayerTx(c, s.Fresh, a.PlayerID, false)
	if err != nil || !found {
		return d.MatchView{}, errors.Join(err, d.ErrConflict)
	}
	arena, err := s.arenaView(c, s.Fresh, catalog, catalog.Rolled(p, now), now)
	if err != nil {
		return d.MatchView{}, err
	}
	return d.MatchView{Arena: arena, ReportKeys: reportKeys(m), Wins: m.Outcome.Wins, Win: m.Outcome.Win}, nil
}

// reportKeys names each played round's report; a forfeited round has none.
func reportKeys(m d.Match) []string {
	out := []string{}
	for i := range m.Outcome.Wins {
		key := ""
		if !m.Rounds[i].Forfeit() {
			key = m.Rounds[i].AttemptID.String()
		}
		out = append(out, key)
	}
	return out
}

type settledMatchEvidence struct {
	store  Store
	reader tx.Queryer
	id     ids.UUID
}

func (e settledMatchEvidence) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	m, found, err := e.store.ReadMatchTx(c, e.reader, e.id, false)
	if err != nil || !found || m.Status == d.StatusStarted {
		return tx.Resolution{State: tx.ResolutionUnknown}, err
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: m.Status}, nil
}

func (s Service) settle(c context.Context, m d.Match, parent operation.Context) (d.Match, error) {
	op, err := child(parent, "settle:"+m.ID.String())
	if err != nil {
		return d.Match{}, err
	}
	err = s.mutate(c, op, func() error {
		_, _, err := s.Timed.Run(c, op, matchProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), settledMatchEvidence{store: s.Store, reader: s.Fresh, id: m.ID}, func(c context.Context, sc gen.TimedScope) error {
			return s.settleMatchTx(c, sc, m.ID)
		})
		return err
	})
	if err != nil {
		return d.Match{}, err
	}
	out, _, err := s.Store.ReadMatchTx(c, s.Fresh, m.ID, false)
	return out, err
}

// settleMatchTx applies a resolved match once: competition root, both players,
// Combat terminal/close per round (609), history facts and Achievement 100028 (620).
func (s Service) settleMatchTx(c context.Context, sc gen.TimedScope, id ids.UUID) error {
	at := sc.Operation.DecisionAt()
	root, found, err := s.Store.ReadCompetitionTx(c, sc.Tx, true)
	if err != nil || !found {
		return errors.Join(err, d.ErrConflict)
	}
	revision, catalog, err := s.catalogTx(c, sc.Tx)
	if err != nil {
		return err
	}
	if err = owed(catalog, root, at); err != nil {
		return err
	}
	m, found, err := s.Store.ReadMatchTx(c, sc.Tx, id, true)
	if err != nil || !found || m.Status != d.StatusStarted {
		return errors.Join(err, d.ErrConflict)
	}
	players := map[identity.PlayerID]d.Player{}
	for _, pid := range sortedPlayers(m.Attacker, m.Defender) {
		p, _, found, err := s.Store.ReadPlayerTx(c, sc.Tx, pid, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrConflict)
		}
		players[pid] = p
	}
	// Rounds up to the majority are settled terminally (Combat 609); later
	// rounds were frozen at START but never simulated, so their attempts stay
	// staged without a result.
	reports := make([][]byte, len(m.Rounds))
	for i := range m.Rounds {
		if _, _, decided := d.Wins(m.Rounds); decided {
			break
		}
		if m.Rounds[i].Forfeit() {
			continue
		}
		settled, err := s.Combat.TerminalTx(c, sc.Tx, combat.TerminalRequest{Locator: roundLocator(m.ID, i+1), GenerationRef: d.ContractID, TerminalKind: terminalKind, SemanticReceiptID: semanticReceipt(m.ID, i+1), At: at})
		if err != nil {
			return err
		}
		m.Rounds[i].Star, m.Rounds[i].Resolved, reports[i] = settled.Resolution.Outcome.Star, true, settled.Report
	}
	wins, win, done := d.Wins(m.Rounds)
	if !done {
		return cd.ErrNotReady
	}
	for i := range wins {
		if m.Rounds[i].Forfeit() {
			continue
		}
		for _, side := range []struct {
			player identity.PlayerID
			report string
			won    bool
		}{{m.Attacker, "A", wins[i] == 1}, {m.Defender, "B", wins[i] == 0}} {
			uses, err := cd.Usage(reports[i], side.report, side.won)
			if err != nil {
				return err
			}
			if err = s.Store.AddUsageTx(c, sc.Tx, side.player, uses); err != nil {
				return err
			}
		}
	}
	attacker, defender, outcome := catalog.Decide(m, players[m.Attacker], players[m.Defender], wins, win, at)
	for _, side := range []struct {
		before, after d.Player
		attack, won   bool
	}{{players[m.Attacker], attacker, true, win}, {players[m.Defender], defender, false, !win}} {
		totals := d.Totals{Fights: 1}
		if side.won {
			totals.Wins = 1
		}
		next := side.after
		next.StateVersion, next.UpdatedAt = side.before.StateVersion+1, at
		if err = s.Store.SavePlayerTx(c, sc.Tx, next, side.before.StateVersion, totals); err != nil {
			return err
		}
		if err = s.Store.InsertRecordTx(c, sc.Tx, d.Record{Owner: next.PlayerID, MatchID: m.ID, Attack: side.attack, Win: side.won, Mode: m.Mode, At: at}, catalog.RecordsMax); err != nil {
			return err
		}
	}
	if err = s.Achievements.ObserveOneOnOneWinStreakTx(c, sc.Tx, m.Attacker, revision, attacker.WinStreak, at); err != nil {
		return err
	}
	done2 := m
	stamp := at.UTC()
	done2.Status, done2.Outcome, done2.SettledAt, done2.StateVersion = d.StatusSettled, &outcome, &stamp, m.StateVersion+1
	return s.Store.FinishMatchTx(c, sc.Tx, done2, m.StateVersion)
}

// close ends a match whose rounds can no longer produce results; the consumed
// try or chance is not restored (private policy).
func (s Service) close(c context.Context, m d.Match, parent operation.Context) error {
	op, err := child(parent, "close:"+m.ID.String())
	if err != nil {
		return err
	}
	_, _, err = s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), settledMatchEvidence{store: s.Store, reader: s.Fresh, id: m.ID}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		current, found, err := s.Store.ReadMatchTx(c, sc.Tx, m.ID, true)
		if err != nil || !found || current.Status != d.StatusStarted {
			return err
		}
		for i, r := range current.Rounds {
			if r.Forfeit() {
				continue
			}
			attempt, found, err := s.Combat.AttemptTx(c, sc.Tx, r.AttemptID)
			if err != nil || !found {
				return errors.Join(err, d.ErrConflict)
			}
			if !attempt.Unresolved() {
				continue
			}
			if _, err = s.Combat.CloseTx(c, sc.Tx, combat.TerminalRequest{Locator: roundLocator(m.ID, i+1), GenerationRef: d.ContractID, TerminalKind: closedKind, SemanticReceiptID: semanticReceipt(m.ID, i+1), At: at}); err != nil {
				return err
			}
		}
		done := current
		stamp := at.UTC()
		done.Status, done.SettledAt, done.StateVersion = d.StatusClosed, &stamp, current.StateVersion+1
		return s.Store.FinishMatchTx(c, sc.Tx, done, current.StateVersion)
	})
	return err
}
