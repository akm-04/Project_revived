package arena

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"slices"
	"strconv"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/arena"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	terminalKind = "ARENA_SETTLED"
	closedKind   = "ARENA_CLOSED"
	// C5D policy: a fight result is due within this window, after which an unresolved attempt may close.
	resultWindow = 10 * time.Minute
	// C5D policy: FIGHT answers within this budget, inside the client's 20 s JSON request timeout.
	fightBudget = 15 * time.Second
)

// ErrUnresolved answers a FIGHT whose battle is still resolving; the client
// re-sends the same FIGHT (empty battle_report -> PLAYOFFS_RETRY).
var ErrUnresolved = errors.New("arena: battle still resolving")

func locator(match ids.UUID) cd.Locator {
	return cd.Locator{DomainKind: "ARENA", AuthorityScope: d.CompetitionID, DomainLocator: "match:" + match.String()}
}

func semanticReceipt(match ids.UUID) string { return "arena:" + match.String() }

func sortedPlayers(a, b identity.PlayerID) []identity.PlayerID {
	out := []identity.PlayerID{a, b}
	slices.Sort(out)
	return out
}

// Match offers one opponent with a saved defense (REARENA_MATCH_ENEMY).
func (s Service) Match(c context.Context, a identity.ActorContext, practice bool, op operation.Context) (d.EnemyView, error) {
	var out d.EnemyView
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
			if !catalog.SeasonAt(at).Open(at) {
				return d.ErrClosed
			}
			before, p, err := s.player(c, sc, catalog, a.PlayerID)
			if err != nil {
				return err
			}
			standings, err := s.Store.StandingsTx(c, sc.Tx, p.Season)
			if err != nil {
				return err
			}
			p.MatchCounter++
			enemy, found := catalog.Pick(p, standings, practice)
			if !found {
				return fmt.Errorf("%w: no opponent", d.ErrRefused)
			}
			p.Opponent, p.Practice = enemy, practice
			if err = s.save(c, sc.Tx, before, p, at); err != nil {
				return err
			}
			out, err = s.enemyView(c, sc.Tx, catalog, a.PlayerID, enemy, standings, at)
			return err
		})
		return err
	})
	return out, err
}

func (s Service) enemyView(c context.Context, q tx.Queryer, catalog d.Catalog, self, enemy identity.PlayerID, standings []d.Standing, at time.Time) (d.EnemyView, error) {
	e, found, err := s.Store.ReadPlayerTx(c, q, enemy, false)
	if err != nil || !found {
		return d.EnemyView{}, errors.Join(err, d.ErrConflict)
	}
	e = catalog.Rolled(e, at)
	templates, err := s.templates(c, q)
	if err != nil {
		return d.EnemyView{}, err
	}
	view := d.EnemyView{Standing: e.Standing()}
	if view.Face, err = s.face(c, q, enemy); err != nil {
		return d.EnemyView{}, err
	}
	if view.Heroes, err = s.lineupRows(c, q, enemy, e.Lineup(e.Defense.Heroes, templates.Base), at); err != nil {
		return d.EnemyView{}, err
	}
	if e.Defense.Pet > 0 {
		pets, err := s.petRows(c, q, enemy, at)
		if err != nil {
			return d.EnemyView{}, err
		}
		view.Pet = pets[strconv.FormatInt(e.Defense.Pet, 10)]
	}
	if i := slices.IndexFunc(standings, func(x d.Standing) bool { return x.PlayerID == enemy }); i >= 0 {
		view.Standing = standings[i]
	}
	view.SelfServerName, err = s.Servers.ServerNameTx(c, q, identity.LogicalServerID(int64(self)/100000))
	return view, err
}

// Start binds the offered opponent and freezes the defender lineup
// (REARENA_START_FIGHT); it always answers a server-resolved battle.
func (s Service) Start(c context.Context, a identity.ActorContext, op operation.Context) error {
	if !s.ready() {
		return d.ErrUnavailable
	}
	latest, found, err := s.Store.LatestMatchTx(c, s.Fresh, a.PlayerID)
	if err != nil {
		return err
	}
	// A previous open match settles first: a started one was abandoned (a loss)
	// and a fighting one finishes its battle.
	if found && latest.Status == d.StatusStarted {
		p, _, err := s.Store.ReadPlayerTx(c, s.Fresh, a.PlayerID, false)
		if err != nil {
			return err
		}
		if latest.Defender == p.Opponent && latest.Practice == p.Practice {
			return nil
		}
		if err = s.settle(c, latest.ID, true, op); err != nil {
			return err
		}
	}
	if found && latest.Status == d.StatusFighting {
		if _, err = s.conclude(c, latest, op, time.Now().Add(fightBudget)); err != nil {
			return err
		}
	}
	return s.mutate(c, op, func() error {
		_, _, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
			at := sc.Operation.DecisionAt()
			if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
				return err
			}
			_, catalog, err := s.catalogTx(c, sc.Tx)
			if err != nil {
				return err
			}
			season := catalog.SeasonAt(at)
			if !season.Open(at) {
				return d.ErrClosed
			}
			_, p, err := s.player(c, sc, catalog, a.PlayerID)
			if err != nil {
				return err
			}
			if !p.Opponent.Valid() {
				return fmt.Errorf("%w: no offered opponent", d.ErrRefused)
			}
			enemy, found, err := s.Store.ReadPlayerTx(c, sc.Tx, p.Opponent, false)
			if err != nil || !found {
				return errors.Join(err, d.ErrRefused)
			}
			enemy = catalog.Rolled(enemy, at)
			if len(enemy.Defense.Heroes) != d.TeamSize {
				return fmt.Errorf("%w: opponent has no defense", d.ErrRefused)
			}
			templates, err := s.templates(c, sc.Tx)
			if err != nil {
				return err
			}
			id, err := ids.NewUUID()
			if err != nil {
				return err
			}
			m := d.Match{ID: id, Attacker: a.PlayerID, Defender: enemy.PlayerID, Season: season.Number, Practice: p.Practice, DefenseHeroes: enemy.Lineup(enemy.Defense.Heroes, templates.Base),
				DefensePet: enemy.Defense.Pet, StartedAt: at.UTC(), Status: d.StatusStarted, StateVersion: 1}
			return s.Store.InsertMatchTx(c, sc.Tx, m)
		})
		return err
	})
}

// FightCommand is REARENA_FIGHT: the attacker's formation by table id and pet.
type FightCommand struct {
	Enemy     identity.PlayerID
	Practice  bool
	Formation []int64
	Pet       int64
}

func fingerprint(pid identity.PlayerID, r FightCommand) string {
	raw, _ := json.Marshal(map[string]any{"policy": d.ContractID, "player": int64(pid), "enemy": int64(r.Enemy), "practice": r.Practice, "formation": r.Formation, "pet": r.Pet})
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}

// Fight freezes the battle of the started match, resolves it within the
// budget and settles it once; an identical FIGHT returns the recorded result.
func (s Service) Fight(c context.Context, a identity.ActorContext, r FightCommand, op operation.Context) (d.FightView, error) {
	if !r.Enemy.Valid() || r.Pet < 0 || len(r.Formation) < 1 || len(r.Formation) > d.TeamSize {
		return d.FightView{}, d.ErrInvalid
	}
	if !s.ready() {
		return d.FightView{}, d.ErrUnavailable
	}
	op, err := s.pin(c, op)
	if err != nil {
		return d.FightView{}, err
	}
	deadline := time.Now().Add(fightBudget)
	fp := fingerprint(a.PlayerID, r)
	m, found, err := s.Store.LatestMatchTx(c, s.Fresh, a.PlayerID)
	if err != nil || !found {
		return d.FightView{}, errors.Join(err, d.ErrRefused)
	}
	switch {
	case m.Fingerprint == fp && m.Status == d.StatusSettled:
		return s.fightView(c, m)
	case m.Status == d.StatusStarted:
		if m, err = s.admitFight(c, a, m.ID, r, fp, op); err != nil {
			return d.FightView{}, err
		}
	case m.Status != d.StatusFighting || m.Fingerprint != fp:
		return d.FightView{}, d.ErrRefused
	}
	if m, err = s.conclude(c, m, op, deadline); err != nil {
		return d.FightView{}, err
	}
	return s.fightView(c, m)
}

func (s Service) admitFight(c context.Context, a identity.ActorContext, id ids.UUID, r FightCommand, fp string, op operation.Context) (d.Match, error) {
	var out d.Match
	err := s.mutate(c, op, func() error {
		_, res, err := s.Timed.Run(c, op, fightProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), fightEvidence{store: s.Store, reader: s.Fresh, id: id, fingerprint: fp}, func(c context.Context, sc gen.TimedScope) error {
			at := sc.Operation.DecisionAt()
			if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
				return err
			}
			revision, _ := sc.Operation.Operation().Policies.Get("content")
			catalog, err := s.Content.ArenaCatalogTx(c, sc.Tx, revision)
			if err != nil {
				return err
			}
			_, p, err := s.player(c, sc, catalog, a.PlayerID)
			if err != nil {
				return err
			}
			m, found, err := s.Store.ReadMatchTx(c, sc.Tx, id, true)
			if err != nil || !found || m.Status != d.StatusStarted || m.Attacker != a.PlayerID || m.Defender != r.Enemy || m.Practice != r.Practice {
				return errors.Join(err, d.ErrRefused)
			}
			templates, err := s.Content.ArenaTemplatesTx(c, sc.Tx, revision)
			if err != nil {
				return err
			}
			if !d.ValidFormation(r.Formation, templates.Base, false) {
				return d.ErrInvalid
			}
			formation := p.Lineup(r.Formation, templates.Base)
			teamA, err := s.participants(c, sc.Tx, p, a.PlayerID, cd.OwnedSelf, formation, templates, at)
			if err != nil {
				return err
			}
			if len(teamA) != len(r.Formation) {
				return fmt.Errorf("%w: girl unavailable", d.ErrRefused)
			}
			defender, _, err := s.Store.ReadPlayerTx(c, sc.Tx, m.Defender, false)
			if err != nil {
				return err
			}
			teamB, err := s.participants(c, sc.Tx, catalog.Rolled(defender, at), m.Defender, cd.OwnedForeign, m.DefenseHeroes, templates, at)
			if err != nil {
				return err
			}
			if len(teamB) == 0 {
				return fmt.Errorf("%w: defense unavailable", d.ErrConflict)
			}
			petsA, err := s.pet(c, sc.Tx, a.PlayerID, cd.OwnedSelf, r.Pet, at, true)
			if err != nil {
				return err
			}
			petsB, err := s.pet(c, sc.Tx, m.Defender, cd.OwnedForeign, m.DefensePet, at, false)
			if err != nil {
				return err
			}
			scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, revision, at)
			if err != nil {
				return err
			}
			battle := combat.BattleRequest{CampaignType: d.CampaignType, BattleID: d.BattleID, TeamA: teamA, PetsA: petsA, WavesB: [][]combat.Participant{teamB}, PetsB: petsB, Context: &cd.BattleContext{Transform: d.Transform}}
			started, err := s.Combat.StartTx(c, sc.Tx, scope, combat.StartRequest{Actor: a, Locator: locator(m.ID), GenerationRef: d.ContractID, StartFingerprint: fp, ResultDeadline: at.Add(resultWindow), Battle: battle})
			if err != nil {
				return err
			}
			if started.Replayed {
				return d.ErrConflict
			}
			next := m
			next.Formation, next.AttackPet, next.AttemptID, next.Fingerprint, next.Status, next.StateVersion = formation, r.Pet, started.Attempt.ID, fp, d.StatusFighting, m.StateVersion+1
			out = next
			return s.Store.SaveMatchTx(c, sc.Tx, next, m.StateVersion)
		})
		if err == nil && res.Reconciled {
			m, _, readErr := s.Store.ReadMatchTx(c, s.Fresh, id, false)
			out, err = m, readErr
		}
		return err
	})
	return out, err
}

type fightEvidence struct {
	store       Store
	reader      tx.Queryer
	id          ids.UUID
	fingerprint string
}

func (e fightEvidence) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	m, found, err := e.store.ReadMatchTx(c, e.reader, e.id, false)
	if err != nil || !found || m.Fingerprint != e.fingerprint {
		return tx.Resolution{State: tx.ResolutionUnknown}, err
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: m.Status}, nil
}

// participants resolves frozen lineup girls: the owner's strongest owned
// copy, or a summoned template girl; season awards ride as transform parameters.
func (s Service) participants(c context.Context, q tx.Queryer, owner d.Player, pid identity.PlayerID, origin cd.Origin, lineup []d.Fighter, templates d.Templates, at time.Time) ([]combat.Participant, error) {
	roster, err := s.heroRows(c, q, pid, at)
	if err != nil {
		return nil, err
	}
	out := []combat.Participant{}
	for _, f := range lineup {
		row, ok := s.available(owner, roster, templates, f.TableID)
		if !ok && !(origin == cd.OwnedForeign && f.Summon) {
			continue
		}
		var award map[string]int64
		if f.AddStar > 0 || f.Awake {
			award = map[string]int64{}
			if f.AddStar > 0 {
				award["arena_add_star"] = f.AddStar
			}
			if f.Awake {
				award["arena_awake"] = 1
			}
		}
		if row == nil {
			out = append(out, combat.Participant{Origin: cd.Template, Kind: cd.HeroActor, Identity: f.TableID, TemplateParams: summoned(templates, f.TableID), Transform: award})
			continue
		}
		out = append(out, combat.Participant{Origin: origin, Kind: cd.HeroActor, Player: pid, Identity: number(row["partner_id"]), Transform: award})
	}
	return out, nil
}

// pet is the side's pet participant; strict refuses an attacker pet not owned,
// a defender pet no longer owned is left out.
func (s Service) pet(c context.Context, q tx.Queryer, pid identity.PlayerID, origin cd.Origin, id int64, at time.Time, strict bool) ([]combat.Participant, error) {
	if id <= 0 {
		return nil, nil
	}
	pets, err := s.petRows(c, q, pid, at)
	if err != nil {
		return nil, err
	}
	if _, owned := pets[strconv.FormatInt(id, 10)]; !owned {
		if strict {
			return nil, fmt.Errorf("%w: pet %d not owned", d.ErrRefused, id)
		}
		return nil, nil
	}
	return []combat.Participant{{Origin: origin, Kind: cd.PetActor, Player: pid, Identity: id}}, nil
}

// conclude resolves the match's battle on a detached context within the
// deadline and settles it once; a permanently failed battle closes the match.
// A zero deadline waits.
func (s Service) conclude(c context.Context, m d.Match, op operation.Context, deadline time.Time) (d.Match, error) {
	if m.Status != d.StatusFighting {
		return m, nil
	}
	f := s.Combat.ResolveDetached(c, op, m.AttemptID)
	var budget <-chan time.Time
	if !deadline.IsZero() {
		timer := time.NewTimer(time.Until(deadline))
		defer timer.Stop()
		budget = timer.C
	}
	select {
	case <-f.Done:
	case <-budget:
		return m, ErrUnresolved
	}
	if errors.Is(f.Err, cd.ErrResolverPermanent) {
		return m, errors.Join(f.Err, s.close(c, m, op))
	}
	if f.Err != nil {
		return m, f.Err
	}
	if err := s.settle(c, m.ID, false, op); err != nil {
		return m, err
	}
	out, _, err := s.Store.ReadMatchTx(c, s.Fresh, m.ID, false)
	return out, err
}

type settledEvidenceMatch struct {
	store  Store
	reader tx.Queryer
	id     ids.UUID
}

func (e settledEvidenceMatch) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	m, found, err := e.store.ReadMatchTx(c, e.reader, e.id, false)
	if err != nil || !found || m.Status == d.StatusStarted || m.Status == d.StatusFighting {
		return tx.Resolution{State: tx.ResolutionUnknown}, err
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: m.Status}, nil
}

// settle applies a match once; forfeit settles a started match as the
// attacker's loss without a battle (STOP, abandon, superseded START).
func (s Service) settle(c context.Context, id ids.UUID, forfeit bool, parent operation.Context) error {
	parent, err := s.pin(c, parent)
	if err != nil {
		return err
	}
	op, err := child(parent, "settle:"+id.String())
	if err != nil {
		return err
	}
	return s.mutate(c, op, func() error {
		_, _, err := s.Timed.Run(c, op, fightProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), settledEvidenceMatch{store: s.Store, reader: s.Fresh, id: id}, func(c context.Context, sc gen.TimedScope) error {
			return s.settleMatchTx(c, sc, id, forfeit)
		})
		return err
	})
}

// settleMatchTx: competition root (603), both players, Combat terminal (609),
// region_coin grant, history facts and Achievement 100003 (620).
func (s Service) settleMatchTx(c context.Context, sc gen.TimedScope, id ids.UUID, forfeit bool) error {
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
	expected := d.StatusFighting
	if forfeit {
		expected = d.StatusStarted
	}
	if err != nil || !found || m.Status != expected {
		return errors.Join(err, d.ErrConflict)
	}
	players := map[identity.PlayerID][2]d.Player{}
	for _, pid := range sortedPlayers(m.Attacker, m.Defender) {
		p, found, err := s.Store.ReadPlayerTx(c, sc.Tx, pid, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrConflict)
		}
		players[pid] = [2]d.Player{p, catalog.Rolled(p, at)}
	}
	attacker, defender := players[m.Attacker][1], players[m.Defender][1]
	outcome := d.Outcome{Forfeit: forfeit, StarBefore: attacker.Star}
	var report []byte
	if !forfeit {
		settled, err := s.Combat.TerminalTx(c, sc.Tx, combat.TerminalRequest{Locator: locator(m.ID), GenerationRef: d.ContractID, TerminalKind: terminalKind, SemanticReceiptID: semanticReceipt(m.ID), At: at})
		if err != nil {
			return err
		}
		outcome.Win, report = settled.Resolution.Outcome.Star > 0, settled.Report
	}
	// A season that turned over during the fight leaves practice and stale-season fights without effects.
	ranked := !m.Practice && m.Season == attacker.Season
	if ranked {
		if err = s.applyRanked(c, sc, catalog, revision, m, &attacker, &defender, &outcome, report); err != nil {
			return err
		}
	}
	for _, pid := range sortedPlayers(m.Attacker, m.Defender) {
		next := map[identity.PlayerID]d.Player{m.Attacker: attacker, m.Defender: defender}[pid]
		if !samePlayer(players[pid][0], next) {
			if err = s.save(c, sc.Tx, players[pid][0], next, at); err != nil {
				return err
			}
		}
	}
	outcome.Star, outcome.Point = attacker.Star, attacker.Point
	done := m
	stamp := at.UTC()
	done.Status, done.Outcome, done.SettledAt, done.StateVersion = d.StatusSettled, &outcome, &stamp, m.StateVersion+1
	return s.Store.SaveMatchTx(c, sc.Tx, done, m.StateVersion)
}

func (s Service) applyRanked(c context.Context, sc gen.TimedScope, catalog d.Catalog, revision string, m d.Match, attacker, defender *d.Player, outcome *d.Outcome, report []byte) error {
	at := sc.Operation.DecisionAt()
	result := catalog.Attack(*attacker, *defender, outcome.Win, outcome.Forfeit, at)
	*attacker, *defender, outcome.Coins = result.Attacker, result.Defender, result.Coins
	if !outcome.Forfeit {
		uses, err := cd.Usage(report, "A", outcome.Win)
		if err != nil {
			return err
		}
		if err = s.Store.AddUsageTx(c, sc.Tx, m.Attacker, m.Season, uses); err != nil {
			return err
		}
		for _, u := range uses {
			harms, _ := strconv.ParseFloat(u.Harms, 64)
			outcome.Kills, outcome.Damage = outcome.Kills+u.Kills, outcome.Damage+int64(harms)
		}
		*attacker = catalog.Progress(*attacker, outcome.Kills, outcome.Damage, outcome.Win)
		if err = s.Store.InsertRecordTx(c, sc.Tx, d.Record{Owner: m.Defender, MatchID: m.ID, Attack: false, Win: !outcome.Win, At: at}, d.RecordsMax); err != nil {
			return err
		}
	}
	if err := s.Store.InsertRecordTx(c, sc.Tx, d.Record{Owner: m.Attacker, MatchID: m.ID, Attack: true, Win: outcome.Win, At: at}, d.RecordsMax); err != nil {
		return err
	}
	if outcome.Coins > 0 {
		actor := identity.ActorContext{PlayerID: m.Attacker, LogicalServerID: attacker.Server}
		plan := grantPlan(m.Attacker, sc.Operation.Operation(), "daily-coin", []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "region_coin", Amount: outcome.Coins}})
		if _, err := s.Grants.SettleGrantTx(c, sc.Tx, actor, plan, sc.Operation.Operation(), i5.GrantTxOptions{}); err != nil {
			return err
		}
	}
	return s.Achievements.ObserveArenaWinStreakTx(c, sc.Tx, m.Attacker, revision, attacker.KeepWin, at)
}

// close ends a match whose battle can no longer produce a result; the attempt
// is closed and the fight counts for nothing (C5D policy).
func (s Service) close(c context.Context, m d.Match, parent operation.Context) error {
	op, err := child(parent, "close:"+m.ID.String())
	if err != nil {
		return err
	}
	_, _, err = s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), settledEvidenceMatch{store: s.Store, reader: s.Fresh, id: m.ID}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		current, found, err := s.Store.ReadMatchTx(c, sc.Tx, m.ID, true)
		if err != nil || !found || current.Status != d.StatusFighting {
			return err
		}
		attempt, found, err := s.Combat.AttemptTx(c, sc.Tx, current.AttemptID)
		if err != nil || !found {
			return errors.Join(err, d.ErrConflict)
		}
		if attempt.Unresolved() {
			if _, err = s.Combat.CloseTx(c, sc.Tx, combat.TerminalRequest{Locator: locator(m.ID), GenerationRef: d.ContractID, TerminalKind: closedKind, SemanticReceiptID: semanticReceipt(m.ID), At: at}); err != nil {
				return err
			}
		}
		done := current
		stamp := at.UTC()
		done.Status, done.SettledAt, done.StateVersion = d.StatusClosed, &stamp, current.StateVersion+1
		return s.Store.SaveMatchTx(c, sc.Tx, done, current.StateVersion)
	})
	return err
}

// Stop is REARENA_STOP_FIGHT: the started match settles as the attacker's loss.
func (s Service) Stop(c context.Context, a identity.ActorContext, enemy identity.PlayerID, op operation.Context) (d.Player, error) {
	if !s.ready() {
		return d.Player{}, d.ErrUnavailable
	}
	m, found, err := s.Store.LatestMatchTx(c, s.Fresh, a.PlayerID)
	if err != nil || !found || m.Status != d.StatusStarted || m.Defender != enemy {
		return d.Player{}, errors.Join(err, d.ErrRefused)
	}
	if err = s.settle(c, m.ID, true, op); err != nil {
		return d.Player{}, err
	}
	p, _, err := s.Store.ReadPlayerTx(c, s.Fresh, a.PlayerID, false)
	return p, err
}

func (s Service) fightView(c context.Context, m d.Match) (d.FightView, error) {
	if m.Status != d.StatusSettled || m.Outcome == nil || m.Outcome.Forfeit {
		return d.FightView{}, fmt.Errorf("%w: fight closed without result", d.ErrRefused)
	}
	result, err := s.Combat.ResultTx(c, s.Fresh, m.AttemptID)
	if err != nil {
		return d.FightView{}, err
	}
	p, _, err := s.Store.ReadPlayerTx(c, s.Fresh, m.Attacker, false)
	if err != nil {
		return d.FightView{}, err
	}
	coin, err := s.balance(c, s.Fresh, m.Attacker, "region_coin")
	return d.FightView{Win: m.Outcome.Win, Report: result.Report, Player: p, Coins: m.Outcome.Coins, RegionCoin: coin}, err
}
