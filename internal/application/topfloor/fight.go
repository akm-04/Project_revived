package topfloor

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
	"gxb.local/backend/v2/internal/application/i5"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	terminalKind = "TOP_FLOOR_SETTLED"
	closedKind   = "TOP_FLOOR_CLOSED"
	// Private policy: a combat result is due within this window, after which an unresolved attempt may close.
	resultWindow = 10 * time.Minute
	// Private policy: an identical START within this window of the previous one replays it (client retries every 3 s).
	replayWindow = time.Minute
)

type StartCommand struct {
	Formation []int64
	PetID     int64
	Enemy     int64
	Avenge    bool
}

func (r StartCommand) Validate() error {
	seen := map[int64]bool{}
	for _, id := range r.Formation {
		if id <= 0 || seen[id] {
			return d.ErrInvalid
		}
		seen[id] = true
	}
	if len(r.Formation) < 1 || len(r.Formation) > d.DefenseSlots || r.PetID < 0 || r.Enemy <= 0 {
		return d.ErrInvalid
	}
	return nil
}

func fingerprint(pid identity.PlayerID, r StartCommand) string {
	raw, _ := json.Marshal(map[string]any{"policy": d.ContractID, "player": int64(pid), "formation": r.Formation, "pet": r.PetID, "enemy": r.Enemy, "avenge": r.Avenge})
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

func locator(server identity.LogicalServerID, pid identity.PlayerID) cd.Locator {
	return cd.Locator{DomainKind: "TOP_FLOOR", AuthorityScope: fmt.Sprintf("server:%d", server), DomainLocator: fmt.Sprintf("challenger:%d", pid)}
}

func semanticReceipt(id ids.UUID) string { return "top-floor:" + id.String() }

// Start admits one fight, resolves it outside locks and settles it once. A
// pending result returns no report; the client repeats the same START.
func (s Service) Start(c context.Context, a identity.ActorContext, r StartCommand, op operation.Context) (FightView, error) {
	if err := r.Validate(); err != nil {
		return FightView{}, err
	}
	if !s.ready() {
		return FightView{}, d.ErrUnavailable
	}
	op, err := s.pin(c, op)
	if err != nil {
		return FightView{}, err
	}
	fp := fingerprint(a.PlayerID, r)
	now, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return FightView{}, err
	}
	latest, found, err := s.Store.LatestFightTx(c, s.Fresh, a.PlayerID)
	if err != nil {
		return FightView{}, err
	}
	repeat := found && latest.Fingerprint == fp && (latest.Status == d.StatusStarted || now.Sub(latest.StartedAt) < replayWindow)
	if repeat {
		return s.finish(c, latest, op)
	}
	// Server-authoritative results always apply: an abandoned fight settles first.
	if found && latest.Status == d.StatusStarted {
		view, err := s.finish(c, latest, op)
		if err != nil {
			return FightView{}, err
		}
		if view.Report == nil {
			return FightView{}, fmt.Errorf("%w: previous fight unresolved", d.ErrRefused)
		}
	}
	var fight d.Fight
	err = s.mutate(c, a.LogicalServerID, op, func() error {
		evidence := startEvidence{service: s, server: a.LogicalServerID, player: a.PlayerID, fingerprint: fp}
		_, res, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), evidence, func(c context.Context, sc gen.TimedScope) error {
			var err error
			fight, err = s.admit(c, sc, a, r, fp)
			return err
		})
		if err == nil && res.Reconciled {
			fight, err = evidence.fight(c)
		}
		return err
	})
	if err != nil {
		return FightView{}, err
	}
	return s.finish(c, fight, op)
}

type startEvidence struct {
	service     Service
	server      identity.LogicalServerID
	player      identity.PlayerID
	fingerprint string
}

func (e startEvidence) fight(c context.Context) (d.Fight, error) {
	a, found, err := e.service.Combat.StartEvidenceTx(c, e.service.Fresh, locator(e.server, e.player), e.fingerprint)
	if err != nil || !found {
		return d.Fight{}, errors.Join(err, d.ErrConflict)
	}
	f, found, err := e.service.Store.ReadFightTx(c, e.service.Fresh, a.ID, false)
	if err != nil || !found {
		return d.Fight{}, errors.Join(err, d.ErrConflict)
	}
	return f, nil
}

func (e startEvidence) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	f, err := e.fight(c)
	if err != nil {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: f.AttemptID}, nil
}

func (s Service) admit(c context.Context, sc gen.TimedScope, a identity.ActorContext, r StartCommand, fp string) (d.Fight, error) {
	at := sc.Operation.DecisionAt()
	server := a.LogicalServerID
	if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
		return d.Fight{}, err
	}
	l, found, err := s.Store.ReadLadderTx(c, sc.Tx, server, true)
	if err != nil || !found {
		return d.Fight{}, errors.Join(err, d.ErrRefused)
	}
	revision, _ := sc.Operation.Operation().Policies.Get("content")
	catalog, err := s.Content.TopFloorCatalogTx(c, sc.Tx, revision)
	if err != nil {
		return d.Fight{}, err
	}
	if len(catalog.Unsettled(l, at)) > 0 {
		return d.Fight{}, ErrSettlementDue
	}
	if err = s.open(c, sc.Tx, catalog, a.PlayerID, at); err != nil {
		return d.Fight{}, err
	}
	p, found, err := s.Store.ReadPlayerTx(c, sc.Tx, a.PlayerID, true)
	if err != nil || !found {
		return d.Fight{}, errors.Join(err, d.ErrRefused)
	}
	rank, _, err := s.Store.RankOfTx(c, sc.Tx, server, d.Occupant{Player: a.PlayerID})
	if err != nil {
		return d.Fight{}, err
	}
	enemy, err := s.opponent(c, sc.Tx, catalog, p, rank, r)
	if err != nil {
		return d.Fight{}, err
	}
	enemyRank, ok, err := s.Store.RankOfTx(c, sc.Tx, server, enemy)
	if err != nil || !ok {
		return d.Fight{}, errors.Join(err, d.ErrConflict)
	}
	defenders, pets, err := s.defenders(c, sc.Tx, catalog, enemy)
	if err != nil {
		return d.Fight{}, err
	}
	next, err := catalog.AdmitStart(p, at)
	if err != nil {
		return d.Fight{}, err
	}
	next.StateVersion, next.UpdatedAt = p.StateVersion+1, at
	if err = s.Store.SavePlayerTx(c, sc.Tx, next, p.StateVersion); err != nil {
		return d.Fight{}, err
	}
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, revision, at)
	if err != nil {
		return d.Fight{}, err
	}
	battle := combat.BattleRequest{CampaignType: d.CampaignType, BattleID: d.BattleID, PetsA: []combat.Participant{}, WavesB: [][]combat.Participant{defenders}, PetsB: pets}
	for _, id := range r.Formation {
		battle.TeamA = append(battle.TeamA, combat.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: a.PlayerID, Identity: id})
	}
	if r.PetID > 0 {
		battle.PetsA = append(battle.PetsA, combat.Participant{Origin: cd.OwnedSelf, Kind: cd.PetActor, Player: a.PlayerID, Identity: r.PetID})
	}
	started, err := s.Combat.StartTx(c, sc.Tx, scope, combat.StartRequest{Actor: a, Locator: locator(server, a.PlayerID), GenerationRef: d.ContractID, StartFingerprint: fp, ResultDeadline: at.Add(resultWindow), Battle: battle})
	if err != nil {
		return d.Fight{}, err
	}
	if started.Replayed {
		return d.Fight{}, d.ErrConflict
	}
	fight := d.Fight{AttemptID: started.Attempt.ID, Server: server, Challenger: a.PlayerID, Defender: enemy, Avenge: r.Avenge, Fingerprint: fp, Formation: r.Formation, PetID: r.PetID,
		ChallengerRank: rank, DefenderRank: enemyRank, StartedAt: at.UTC(), Status: d.StatusStarted, StateVersion: 1}
	return fight, s.Store.InsertFightTx(c, sc.Tx, fight)
}

// opponent resolves START's enemy table_id: an offered occupant, or for revenge a
// player who beat this player's defense and now ranks within the match range.
func (s Service) opponent(c context.Context, q tx.Queryer, catalog d.Catalog, p d.Player, rank int64, r StartCommand) (d.Occupant, error) {
	if !r.Avenge {
		o, ok := offered(p, r.Enemy)
		if !ok {
			return d.Occupant{}, d.ErrRefused
		}
		return o, nil
	}
	attacker := identity.PlayerID(int64(p.Server)*d.RegionStride + r.Enemy)
	lost, err := s.Store.LostDefenseTx(c, q, p.PlayerID, attacker)
	if err != nil || !lost {
		return d.Occupant{}, errors.Join(err, d.ErrRefused)
	}
	o := d.Occupant{Player: attacker}
	theirs, ok, err := s.Store.RankOfTx(c, q, p.Server, o)
	if err != nil || !ok || catalog.AvengeType(rank, theirs) != 0 {
		return d.Occupant{}, errors.Join(err, d.ErrRefused)
	}
	return o, nil
}

// defenders freezes a robot team as TEMPLATE actors or a player's saved defense as OWNED_FOREIGN.
func (s Service) defenders(c context.Context, q tx.Queryer, catalog d.Catalog, o d.Occupant) ([]combat.Participant, []combat.Participant, error) {
	heroes, pets := []combat.Participant{}, []combat.Participant{}
	if o.IsRobot() {
		team, _ := catalog.Team(o.Robot)
		for _, id := range team.Heroes {
			params, _ := catalog.RobotHeroParams(id)
			heroes = append(heroes, combat.Participant{Origin: cd.Template, Kind: cd.HeroActor, Identity: params["partner_id"].(int64), TemplateParams: params})
		}
		return heroes, pets, nil
	}
	dp, found, err := s.Store.ReadPlayerTx(c, q, o.Player, false)
	if err != nil || !found || len(dp.Defense) == 0 {
		return nil, nil, errors.Join(err, d.ErrRefused)
	}
	for _, id := range dp.Defense {
		heroes = append(heroes, combat.Participant{Origin: cd.OwnedForeign, Kind: cd.HeroActor, Player: o.Player, Identity: id})
	}
	if dp.DefensePet > 0 {
		pets = append(pets, combat.Participant{Origin: cd.OwnedForeign, Kind: cd.PetActor, Player: o.Player, Identity: dp.DefensePet})
	}
	return heroes, pets, nil
}

// finish resolves a started fight outside locks, settles it once and builds the result view.
func (s Service) finish(c context.Context, f d.Fight, op operation.Context) (FightView, error) {
	if f.Status == d.StatusStarted {
		_, err := s.Combat.Resolve(c, op, f.AttemptID)
		if errors.Is(err, cd.ErrResolverPermanent) {
			return FightView{}, errors.Join(err, s.close(c, f, op))
		}
		if err != nil && !errors.Is(err, cd.ErrResolverRetryable) && !errors.Is(err, cd.ErrNotReady) {
			return FightView{}, err
		}
		if err == nil {
			if f, err = s.settle(c, f, op); err != nil {
				return FightView{}, err
			}
		}
	}
	if f.Status == d.StatusClosed {
		return FightView{}, fmt.Errorf("%w: fight closed without result", d.ErrRefused)
	}
	return s.fightView(c, f)
}

func (s Service) fightView(c context.Context, f d.Fight) (FightView, error) {
	now, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return FightView{}, err
	}
	_, catalog, err := s.catalogTx(c, s.Fresh)
	if err != nil {
		return FightView{}, err
	}
	view := FightView{}
	if view.Formation, _, err = s.team(c, s.Fresh, f.Challenger, f.Formation, 0, now); err != nil {
		return FightView{}, err
	}
	if view.Enemy, err = s.display(c, s.Fresh, catalog, f.Server, f.Defender, now); err != nil {
		return FightView{}, err
	}
	if f.Status != d.StatusSettled {
		return view, nil
	}
	result, err := s.Combat.ResultTx(c, s.Fresh, f.AttemptID)
	if err != nil {
		return FightView{}, err
	}
	view.Report, view.Win, view.AwardCrystal = result.Report, f.Outcome.Win, f.Outcome.AwardCrystal
	return view, nil
}

type settledFightEvidence struct {
	store  Store
	reader tx.Queryer
	id     ids.UUID
}

func (e settledFightEvidence) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	f, found, err := e.store.ReadFightTx(c, e.reader, e.id, false)
	if err != nil || !found || f.Status == d.StatusStarted {
		return tx.Resolution{State: tx.ResolutionUnknown}, err
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: f.Status}, nil
}

// settle applies the resolved fight once: ladder root, both Top Floor players,
// Combat terminal (609) and the best-rank mail (610), in that order.
func (s Service) settle(c context.Context, f d.Fight, parent operation.Context) (d.Fight, error) {
	op, err := child(parent, "settle:"+f.AttemptID.String())
	if err != nil {
		return d.Fight{}, err
	}
	err = s.mutate(c, f.Server, op, func() error {
		_, _, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), settledFightEvidence{store: s.Store, reader: s.Fresh, id: f.AttemptID}, func(c context.Context, sc gen.TimedScope) error {
			return s.settleTx(c, sc, f.AttemptID)
		})
		return err
	})
	if err != nil {
		return d.Fight{}, err
	}
	out, _, err := s.Store.ReadFightTx(c, s.Fresh, f.AttemptID, false)
	return out, err
}

func (s Service) settleTx(c context.Context, sc gen.TimedScope, id ids.UUID) error {
	at := sc.Operation.DecisionAt()
	f, found, err := s.Store.ReadFightTx(c, sc.Tx, id, false)
	if err != nil || !found {
		return errors.Join(err, d.ErrConflict)
	}
	l, found, err := s.Store.ReadLadderTx(c, sc.Tx, f.Server, true)
	if err != nil || !found {
		return errors.Join(err, d.ErrConflict)
	}
	_, catalog, err := s.catalogTx(c, sc.Tx)
	if err != nil {
		return err
	}
	if len(catalog.Unsettled(l, at)) > 0 {
		return ErrSettlementDue
	}
	if f, _, err = s.Store.ReadFightTx(c, sc.Tx, id, true); err != nil || f.Status != d.StatusStarted {
		return err
	}
	owners := []identity.PlayerID{f.Challenger}
	if !f.Defender.IsRobot() {
		owners = append(owners, f.Defender.Player)
	}
	slices.Sort(owners)
	players := map[identity.PlayerID]d.Player{}
	for _, pid := range owners {
		p, found, err := s.Store.ReadPlayerTx(c, sc.Tx, pid, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrConflict)
		}
		players[pid] = p
	}
	challenger := d.Ranked{Occupant: d.Occupant{Player: f.Challenger}}
	defender := d.Ranked{Occupant: f.Defender}
	for _, r := range []*d.Ranked{&challenger, &defender} {
		rank, ok, err := s.Store.RankOfTx(c, sc.Tx, f.Server, r.Occupant)
		if err != nil || !ok {
			return errors.Join(err, d.ErrConflict)
		}
		r.Rank = rank
	}
	settled, err := s.Combat.TerminalTx(c, sc.Tx, combat.TerminalRequest{Locator: locator(f.Server, f.Challenger), GenerationRef: d.ContractID, TerminalKind: terminalKind, SemanticReceiptID: semanticReceipt(f.AttemptID), At: at})
	if err != nil {
		return err
	}
	cp := players[f.Challenger]
	outcome := catalog.Decide(settled.Resolution.Outcome.Star, challenger.Rank, defender.Rank, cp.BestRank)
	if outcome.ChallengerAfter != challenger.Rank {
		if err = s.Store.SwapTx(c, sc.Tx, f.Server, challenger, defender); err != nil {
			return err
		}
		next := l
		next.StateVersion, next.UpdatedAt = l.StateVersion+1, at
		if err = s.Store.SaveLadderTx(c, sc.Tx, next, l.StateVersion); err != nil {
			return err
		}
	}
	if outcome.AwardCrystal > 0 {
		if _, _, err = s.Mail.DeliverTx(c, sc.Tx, i5.SettlementMailRequest{Recipient: f.Challenger, SourceKind: bestRankMailKind, SourceKey: f.AttemptID.String(), Title: bestRankMailTitle, Sender: catalog.MailSender,
			Body: fmt.Sprintf(bestRankMailText, outcome.BestAfter), PolicyVersion: d.ContractID, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: outcome.AwardCrystal}}, At: at}); err != nil {
			return err
		}
	}
	sides := []fightSide{{f.Challenger, true, outcome.Win, "A", f.Defender}}
	if !f.Defender.IsRobot() {
		sides = append(sides, fightSide{f.Defender.Player, false, !outcome.Win, "B", d.Occupant{Player: f.Challenger}})
	}
	for _, side := range sides {
		p := players[side.player]
		next := p
		next.Fights++
		if side.won {
			next.Wins++
		}
		if side.attack {
			next.BestRank = outcome.BestAfter
		}
		next.StateVersion, next.UpdatedAt = p.StateVersion+1, at
		if err = s.Store.SavePlayerTx(c, sc.Tx, next, p.StateVersion); err != nil {
			return err
		}
		if err = s.Store.InsertRecordTx(c, sc.Tx, d.Record{Owner: side.player, AttemptID: f.AttemptID, Attack: side.attack, Win: side.won, Opponent: side.opponent, At: at}, catalog.RecordsMax); err != nil {
			return err
		}
		uses, err := d.Usage(settled.Report, side.side, side.won)
		if err != nil {
			return err
		}
		if err = s.Store.AddUsageTx(c, sc.Tx, side.player, uses); err != nil {
			return err
		}
	}
	done := f
	stamp := at.UTC()
	done.Status, done.Outcome, done.SettledAt, done.StateVersion = d.StatusSettled, &outcome, &stamp, f.StateVersion+1
	return s.Store.FinishFightTx(c, sc.Tx, done, f.StateVersion)
}

// fightSide is one Top Floor player's view of a settled fight; report side "A" is the challenger.
type fightSide struct {
	player   identity.PlayerID
	attack   bool
	won      bool
	side     string
	opponent d.Occupant
}

// close ends a fight whose combat attempt can no longer produce a result; the
// consumed ticket is not restored (private policy).
func (s Service) close(c context.Context, f d.Fight, parent operation.Context) error {
	op, err := child(parent, "close:"+f.AttemptID.String())
	if err != nil {
		return err
	}
	_, _, err = s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), settledFightEvidence{store: s.Store, reader: s.Fresh, id: f.AttemptID}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		current, found, err := s.Store.ReadFightTx(c, sc.Tx, f.AttemptID, true)
		if err != nil || !found || current.Status != d.StatusStarted {
			return err
		}
		if _, err = s.Combat.CloseTx(c, sc.Tx, combat.TerminalRequest{Locator: locator(f.Server, f.Challenger), GenerationRef: d.ContractID, TerminalKind: closedKind, SemanticReceiptID: semanticReceipt(f.AttemptID), At: at}); err != nil {
			return err
		}
		done := current
		stamp := at.UTC()
		done.Status, done.SettledAt, done.StateVersion = d.StatusClosed, &stamp, current.StateVersion+1
		return s.Store.FinishFightTx(c, sc.Tx, done, current.StateVersion)
	})
	return err
}
