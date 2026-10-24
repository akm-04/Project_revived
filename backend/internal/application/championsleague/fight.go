package championsleague

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/championsleague"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func locator(id ids.UUID) cd.Locator {
	return cd.Locator{DomainKind: "ACADEMY_LEAGUE", AuthorityScope: d.CompetitionID, DomainLocator: "fight:" + id.String()}
}
func fightHash(a identity.PlayerID, intent int64, cmd Command) string {
	b, _ := json.Marshal(struct {
		Player identity.PlayerID
		Intent int64
		Enemy  identity.PlayerID
		Lineup d.Lineup
	}{a, intent, cmd.Enemy, cmd.Lineup})
	h := sha256.Sum256(b)
	return hex.EncodeToString(h[:])
}
func participants(pid identity.PlayerID, l d.Lineup, origin cd.Origin) ([]combat.Participant, []combat.Participant) {
	h := []combat.Participant{}
	for _, id := range l.Heroes {
		h = append(h, combat.Participant{Origin: origin, Kind: cd.HeroActor, Player: pid, Identity: id})
	}
	p := []combat.Participant{}
	if l.Pet > 0 {
		p = append(p, combat.Participant{Origin: origin, Kind: cd.PetActor, Player: pid, Identity: l.Pet})
	}
	return h, p
}

// admit holds only the caller transaction. It stages canonical actual-owned
// snapshots; the worker is launched only after this transaction commits.
func (s Service) admit(c context.Context, sc gen.TimedScope, a identity.ActorContext, op operation.Context, cat d.Catalog, rev string, p *d.Player, players *[]d.Player, cmd Command) (d.Match, error) {
	at := sc.Operation.DecisionAt()
	if !cmd.Lineup.Valid(false) || !cmd.Enemy.Valid() || cmd.Enemy == p.ID {
		return d.Match{}, d.ErrInvalid
	}
	fp := fightHash(p.ID, p.Intent, cmd)
	if m, ok, e := s.Store.IntentTx(c, sc.Tx, p.ID, p.Intent); e != nil {
		return m, e
	} else if ok {
		if m.Fingerprint != fp || m.Defender != cmd.Enemy {
			return m, d.ErrRefused
		}
		return m, nil
	}
	if p.Selected != cmd.Enemy {
		return d.Match{}, d.ErrRefused
	}
	enemy, ok := find(*players, cmd.Enemy)
	if !ok || enemy.Group != p.Group || enemy.Season != p.Season || !enemy.Defense.Valid(false) {
		return d.Match{}, d.ErrRefused
	}
	rank := d.Order(*players, p.Season, p.Group)
	ar, br := d.Rank(rank, p.ID), d.Rank(rank, enemy.ID)
	if ar == 0 || br == 0 || br < ar-cat.OpponentRadius || br > ar+cat.OpponentRadius || at.Before(cat.Protection(enemy.LastAttacked, at)) {
		return d.Match{}, d.ErrRefused
	}
	selfRows, _, e := s.rows(c, sc.Tx, p.ID, cmd.Lineup, at)
	if e != nil {
		return d.Match{}, e
	}
	enemyRows, enemyPet, e := s.rows(c, sc.Tx, enemy.ID, enemy.Defense, at)
	if e != nil {
		return d.Match{}, e
	}
	sf, e := s.face(c, sc.Tx, p.ID)
	if e != nil {
		return d.Match{}, e
	}
	ef, e := s.face(c, sc.Tx, enemy.ID)
	if e != nil {
		return d.Match{}, e
	}
	enemyLevel, e := s.level(c, sc.Tx, enemy.ID)
	if e != nil {
		return d.Match{}, e
	}
	if cat.Group(enemyLevel) != enemy.Group {
		return d.Match{}, d.ErrRefused
	}
	scope, e := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, rev, at)
	if e != nil {
		return d.Match{}, e
	}
	ha, pa := participants(p.ID, cmd.Lineup, cd.OwnedSelf)
	hb, pb := participants(enemy.ID, enemy.Defense, cd.OwnedForeign)
	id := op.ID
	started, e := s.Combat.StartTx(c, sc.Tx, scope, combat.StartRequest{Actor: a, Locator: locator(id), GenerationRef: d.ContractID, StartFingerprint: fp, ResultDeadline: at.Add(time.Duration(d.ResultSeconds) * time.Second), Battle: combat.BattleRequest{CampaignType: d.CampaignType, BattleID: d.BattleID, TeamA: ha, PetsA: pa, WavesB: [][]combat.Participant{hb}, PetsB: pb}})
	if e != nil {
		return d.Match{}, e
	}
	if started.Replayed {
		return d.Match{}, d.ErrConflict
	}
	m := d.Match{ID: id, Attacker: p.ID, Defender: enemy.ID, Intent: p.Intent, Season: p.Season, Group: p.Group, Fingerprint: fp, Revision: rev, Status: "FIGHTING", Attempt: started.Attempt.ID, Attack: cmd.Lineup, Defense: enemy.Defense, SelfRows: selfRows, EnemyRows: enemyRows, EnemyPet: enemyPet, SelfFace: sf, EnemyFace: ef, PreviousAttack: enemy.LastAttacked, PreviousProtectedBy: enemy.ProtectedBy, StartedAt: at, Version: 1}
	enemy.LastAttacked = at
	enemy.ProtectedBy = id
	if e = s.savePlayer(c, sc.Tx, &enemy, at); e != nil {
		return m, e
	}
	*players = set(*players, enemy)
	return s.Store.PutMatchTx(c, sc.Tx, m, 0)
}

// finish survives a request timeout through the shared Combat flight. A stock
// retry sees the same persisted intent; it cannot manufacture another fight.
func (s Service) finish(c context.Context, m d.Match, op operation.Context, budget time.Duration) (Reply, error) {
	current, ok, e := s.Store.MatchTx(c, s.Fresh, m.ID)
	if e != nil || !ok {
		return Reply{}, errors.Join(e, d.ErrConflict)
	}
	m = current
	if m.Status == "FIGHTING" {
		f := s.Combat.ResolveDetached(c, op, m.Attempt)
		timer := time.NewTimer(budget)
		defer timer.Stop()
		select {
		case <-f.Done:
		case <-timer.C:
			s.completeDetached(c, m, op, f)
			return Reply{Kind: "FIGHT", Match: m}, nil
		case <-c.Done():
			s.completeDetached(c, m, op, f)
			return Reply{}, c.Err()
		}
		closeOnly := errors.Is(f.Err, cd.ErrResolverPermanent)
		if f.Err != nil && !closeOnly {
			return Reply{}, f.Err
		}
		if e = s.terminal(c, m.ID, op, closeOnly); e != nil {
			return Reply{}, e
		}
		m, ok, e = s.Store.MatchTx(c, s.Fresh, m.ID)
		if e != nil || !ok {
			return Reply{}, errors.Join(e, d.ErrConflict)
		}
	}
	if m.Status != "SETTLED" {
		return Reply{}, d.ErrRefused
	}
	v, e := s.Combat.ResultTx(c, s.Fresh, m.Attempt)
	if e != nil {
		return Reply{}, e
	}
	return Reply{Kind: "FIGHT", Match: m, Report: v.Report}, nil
}

type matchProof struct {
	Store Store
	Fresh tx.Queryer
	ID    ids.UUID
}

func (p matchProof) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	m, ok, e := p.Store.MatchTx(c, p.Fresh, p.ID)
	if e != nil || !ok || m.Status == "FIGHTING" {
		return tx.Resolution{State: tx.ResolutionUnknown}, e
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: m.Status}, nil
}
func child(parent operation.Context, label string) (operation.Context, error) {
	id, e := ids.NewUUID()
	if e != nil {
		return operation.Context{}, e
	}
	return operation.Context{ID: id, StartedAt: parent.StartedAt, EntropySeed: parent.Derive("league:"+label, 0), Policies: parent.Policies}, nil
}

// terminal is one owner terminal transaction: root604 -> Combat609 -> owner
// points/records. Daily Achievement and value effects have separate cutoffs.
func (s Service) terminal(c context.Context, id ids.UUID, parent operation.Context, closeOnly bool) error {
	if e := s.Due(c, parent, 100); e != nil {
		return e
	}
	op, e := child(parent, "terminal:"+id.String())
	if e != nil {
		return e
	}
	_, _, e = s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), matchProof{s.Store, s.Fresh, id}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		_, cat, e := s.catalog(c, sc.Tx, op)
		if e != nil {
			return e
		}
		root, ok, e := s.Store.RootTx(c, sc.Tx, true)
		if e != nil || !ok {
			return errors.Join(e, d.ErrConflict)
		}
		if due(cat, root, at) {
			return d.ErrDue
		}
		if at.Before(root.UpdatedAt) {
			return d.ErrConflict
		}
		m, ok, e := s.Store.MatchTx(c, sc.Tx, id)
		if e != nil || !ok {
			return errors.Join(e, d.ErrConflict)
		}
		if m.Status != "FIGHTING" {
			return nil
		}
		players, e := s.Store.PlayersTx(c, sc.Tx, true)
		if e != nil {
			return e
		}
		a, aok := find(players, m.Attacker)
		b, bok := find(players, m.Defender)
		if !aok || !bok {
			return d.ErrConflict
		}
		req := combat.TerminalRequest{Locator: locator(m.ID), GenerationRef: d.ContractID, TerminalKind: "LEAGUE_SETTLED", SemanticReceiptID: "league:" + m.ID.String(), At: at}
		void := !cat.SeasonNumbered(root.Season).Open(at) || m.Season != root.Season || a.Group != m.Group || b.Group != m.Group
		al, e := s.level(c, sc.Tx, a.ID)
		if e != nil {
			return e
		}
		bl, e := s.level(c, sc.Tx, b.ID)
		if e != nil {
			return e
		}
		void = void || cat.Group(al) != m.Group || cat.Group(bl) != m.Group
		if closeOnly {
			attempt, found, e := s.Combat.AttemptTx(c, sc.Tx, m.Attempt)
			if e != nil || !found {
				return errors.Join(e, d.ErrConflict)
			}
			if !attempt.Closable(at) {
				return d.ErrPending
			}
			req.TerminalKind = "LEAGUE_CLOSED"
			if _, e = s.Combat.CloseTx(c, sc.Tx, req); e != nil {
				return e
			}
			void = true
		} else {
			if void {
				req.TerminalKind = "LEAGUE_VOID"
			}
			v, e := s.Combat.TerminalTx(c, sc.Tx, req)
			if e != nil {
				return e
			}
			m.Win = v.Resolution.Outcome.Star > 0
		}
		m.Status = "SETTLED"
		if void {
			m.Status = "CLOSED"
			if b.ProtectedBy == m.ID {
				b.LastAttacked = m.PreviousAttack
				b.ProtectedBy = m.PreviousProtectedBy
			}
		} else {
			a, b, m.Delta = cat.Attack(a, b, m.Win, at)
		}
		// Global root serializes both rows; preserve lock/key order for all writers.
		if a.ID < b.ID {
			if e = s.savePlayer(c, sc.Tx, &a, at); e != nil {
				return e
			}
			if e = s.savePlayer(c, sc.Tx, &b, at); e != nil {
				return e
			}
		} else {
			if e = s.savePlayer(c, sc.Tx, &b, at); e != nil {
				return e
			}
			if e = s.savePlayer(c, sc.Tx, &a, at); e != nil {
				return e
			}
		}
		old := m.Version
		m.Version++
		stamp := at.UTC()
		m.SettledAt = &stamp
		if _, e = s.Store.PutMatchTx(c, sc.Tx, m, old); e != nil {
			return e
		}
		old = root.Version
		root.Version++
		root.UpdatedAt = at
		return s.Store.PutRootTx(c, sc.Tx, root, old)
	})
	return e
}

// A timeout/disconnect does not leave gameplay settlement waiting for the
// client. Durable sweeps recover a process crash; the callback is only a wakeup.
func (s Service) completeDetached(c context.Context, m d.Match, op operation.Context, f *combat.Flight) {
	go func() {
		<-f.Done
		if f.Err == nil || errors.Is(f.Err, cd.ErrResolverPermanent) {
			_ = s.terminal(context.WithoutCancel(c), m.ID, op, errors.Is(f.Err, cd.ErrResolverPermanent))
		}
	}()
}
