package topfloor

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"slices"
	"strconv"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// mutate settles owed days first and retries once when a cutoff passes in between.
func (s Service) mutate(c context.Context, server identity.LogicalServerID, op operation.Context, run func() error) error {
	if !s.ready() {
		return d.ErrUnavailable
	}
	for range 2 {
		if _, err := s.SettleDue(c, server, op); err != nil {
			return err
		}
		if err := run(); !errors.Is(err, ErrSettlementDue) {
			return err
		}
	}
	return ErrSettlementDue
}

func (s Service) catalogTx(c context.Context, q tx.Queryer) (string, d.Catalog, error) {
	revision, err := s.Content.ActiveRevision(c, q)
	if err != nil {
		return "", d.Catalog{}, err
	}
	catalog, err := s.Content.TopFloorCatalogTx(c, q, revision)
	return revision, catalog, err
}

// open requires the function 4 eligibility fact (player level 10).
func (s Service) open(c context.Context, q tx.Queryer, catalog d.Catalog, pid identity.PlayerID, at time.Time) error {
	fact, found, err := s.Functions.ReadFunctionEligibilityTx(c, q, pid, catalog.FunctionID)
	if err != nil {
		return err
	}
	if !found || fact.FunctionID != catalog.FunctionID || at.Before(fact.EligibleAt) {
		return fmt.Errorf("%w: function %d closed", d.ErrRefused, catalog.FunctionID)
	}
	return nil
}

func (s Service) Load(c context.Context, a identity.ActorContext, op operation.Context) (ArenaView, error) {
	return s.arena(c, a, op, false)
}

// Refresh draws a new deterministic opponent set (free; ArenaRefreshWindow is dead legacy UI).
func (s Service) Refresh(c context.Context, a identity.ActorContext, op operation.Context) (ArenaView, error) {
	return s.arena(c, a, op, true)
}

// errEntryRequired makes LOAD join the ladder in a short transaction first; the
// server-wide ladder root must not stay locked through the offer projection.
var errEntryRequired = errors.New("topfloor: entry required")

func (s Service) arena(c context.Context, a identity.ActorContext, op operation.Context, refresh bool) (ArenaView, error) {
	var out ArenaView
	err := s.mutate(c, a.LogicalServerID, op, func() error {
		err := s.loadArena(c, a, op, refresh, &out)
		if !errors.Is(err, errEntryRequired) {
			return err
		}
		if err = s.joinLadder(c, a, op); err != nil {
			return err
		}
		if err = s.loadArena(c, a, op, refresh, &out); errors.Is(err, errEntryRequired) {
			return errors.Join(err, d.ErrConflict)
		}
		return err
	})
	return out, err
}

// joinLadder enters the player once, alone in its transaction. Read Committed
// lets concurrent first entries wait on the ladder root instead of aborting, and
// keeping the root lock out of the projection keeps the pool from queueing. The
// ladder update is version-guarded while the row is locked; the player insert is
// keyed by player_id, so no stale read is written back.
func (s Service) joinLadder(c context.Context, a identity.ActorContext, op operation.Context) error {
	_, _, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.ReadCommitted}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		revision, catalog, err := s.catalogTx(c, sc.Tx)
		if err != nil {
			return err
		}
		if err = s.open(c, sc.Tx, catalog, a.PlayerID, at); err != nil {
			return err
		}
		_, found, err := s.Store.ReadPlayerTx(c, sc.Tx, a.PlayerID, true)
		if err != nil || found {
			return err
		}
		_, err = s.enter(c, sc.Tx, catalog, revision, a, at)
		return err
	})
	return err
}

func (s Service) loadArena(c context.Context, a identity.ActorContext, op operation.Context, refresh bool, out *ArenaView) error {
	_, _, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		_, catalog, err := s.catalogTx(c, sc.Tx)
		if err != nil {
			return err
		}
		if err = s.open(c, sc.Tx, catalog, a.PlayerID, at); err != nil {
			return err
		}
		p, found, err := s.Store.ReadPlayerTx(c, sc.Tx, a.PlayerID, true)
		if err != nil {
			return err
		}
		if !found {
			return errEntryRequired
		}
		rank, ok, err := s.Store.RankOfTx(c, sc.Tx, a.LogicalServerID, d.Occupant{Player: a.PlayerID})
		if err != nil || !ok {
			return errors.Join(err, d.ErrConflict)
		}
		next := catalog.Rolled(p, at)
		if next.OfferedDay != next.TicketDay {
			next.OfferedDay, next.RefreshCount = next.TicketDay, 0
		}
		if refresh {
			next.RefreshCount++
		}
		if next.Offered, err = s.offers(c, sc.Tx, catalog, next, rank); err != nil {
			return err
		}
		if !samePlayer(p, next) {
			next.StateVersion, next.UpdatedAt = p.StateVersion+1, at
			if err = s.Store.SavePlayerTx(c, sc.Tx, next, p.StateVersion); err != nil {
				return err
			}
		}
		weeklyChallenges, err := s.Store.WeeklyChallengesTx(c, sc.Tx, a.PlayerID, at)
		if err != nil {
			return err
		}
		*out = ArenaView{Player: next, Rank: rank, ServerTime: at, WeeklyChallenges: weeklyChallenges}
		for _, o := range next.Offered {
			view, err := s.display(c, sc.Tx, catalog, a.LogicalServerID, o, at)
			if err != nil {
				return err
			}
			out.Enemies = append(out.Enemies, view)
		}
		return s.saveOfferSnapshot(c, sc.Tx, a.LogicalServerID, a.PlayerID, d.OfferScopeNormal, 0, rank, out.Enemies, at)
	})
	return err
}

func samePlayer(a, b d.Player) bool {
	x, _ := json.Marshal(a)
	y, _ := json.Marshal(b)
	return string(x) == string(y)
}

// saveOfferSnapshot persists the identities and ranks the offer response just
// returned, so admission can compare them without reserving the opponent.
func (s Service) saveOfferSnapshot(c context.Context, t tx.Tx, server identity.LogicalServerID, pid identity.PlayerID, scope, generation, challengerRank int64, enemies []d.Display, at time.Time) error {
	offers := make([]d.Ranked, 0, len(enemies))
	for _, enemy := range enemies {
		offers = append(offers, d.Ranked{Rank: enemy.Rank, Occupant: enemy.Occupant})
	}
	return s.Store.SaveOfferSnapshotTx(c, t, d.OfferSnapshot{Player: pid, Server: server, Scope: scope, Generation: generation, ChallengerRank: challengerRank, Offers: offers, UpdatedAt: at.UTC()})
}

// requireAttackDefense refuses a new attack whose owner has no usable saved
// defense. It reads through the same roster owner SaveDefense validates.
func (s Service) requireAttackDefense(c context.Context, q tx.Queryer, pid identity.PlayerID, p d.Player, at time.Time) error {
	if len(p.Defense) == 0 {
		return d.ErrDefenseRequired
	}
	if _, _, err := s.team(c, q, pid, p.Defense, p.DefensePet, at); err != nil {
		return fmt.Errorf("%w: %v", d.ErrDefenseRequired, err)
	}
	return nil
}

// presetDefense selects the owned subset of the D511 preset girls, choosing the
// highest-level owned copy of each in policy slot order. No selection means the
// player owns none and keeps the D487 refusal.
func (s Service) presetDefense(c context.Context, q tx.Queryer, pid identity.PlayerID) ([]int64, error) {
	heroes, err := s.OwnedHeroes.ListHeroesTx(c, q, pid)
	if err != nil {
		return nil, err
	}
	selected, err := d.SelectPresetDefense(heroes, pid)
	if err != nil {
		return nil, err
	}
	chosen := make([]int64, 0, len(selected))
	for _, hero := range selected {
		chosen = append(chosen, hero.PartnerID)
	}
	if err = defenseShape(chosen, 0); err != nil {
		return nil, err
	}
	return chosen, nil
}

// enter seeds the server ladder on first use, appends the player at the bottom
// and writes the D511 preset defense in the same transaction before the insert.
func (s Service) enter(c context.Context, t tx.Tx, catalog d.Catalog, revision string, a identity.ActorContext, at time.Time) (d.Player, error) {
	l, found, err := s.Store.ReadLadderTx(c, t, a.LogicalServerID, true)
	if err != nil {
		return d.Player{}, err
	}
	if !found {
		seed, _ := catalog.NewLadder(a.LogicalServerID, revision, at)
		if err = s.Store.CreateLadderTx(c, t, seed); err != nil {
			return d.Player{}, err
		}
		l, found, err = s.Store.ReadLadderTx(c, t, a.LogicalServerID, true)
		if err != nil || !found {
			return d.Player{}, errors.Join(err, d.ErrConflict)
		}
	}
	if len(catalog.Unsettled(l, at)) > 0 {
		return d.Player{}, ErrSettlementDue
	}
	rank := l.Size + 1
	if err = s.Store.AppendPlayerTx(c, t, a.LogicalServerID, rank, a.PlayerID); err != nil {
		return d.Player{}, err
	}
	next := l
	// A concurrent first entry can create the root with a later decision instant
	// than this operation's bound one; the root's timestamps must stay ordered.
	updatedAt := at.UTC()
	if updatedAt.Before(l.CreatedAt) {
		updatedAt = l.CreatedAt
	}
	next.Size, next.StateVersion, next.UpdatedAt = rank, l.StateVersion+1, updatedAt
	if err = s.Store.SaveLadderTx(c, t, next, l.StateVersion); err != nil {
		return d.Player{}, err
	}
	p := catalog.NewPlayer(a.PlayerID, a.LogicalServerID, revision, rank, at)
	preset, err := s.presetDefense(c, t, a.PlayerID)
	if err != nil {
		return d.Player{}, err
	}
	if len(preset) > 0 {
		stamp := at.UTC()
		p.Defense, p.DefensePet, p.DefenseSetAt = preset, 0, &stamp
	}
	return p, s.Store.InsertPlayerTx(c, t, p)
}

// offers takes the first eligible occupant of each band in the deterministic
// probe order: robots always, players only with a saved defense. A robot whose
// wire table_id collides with a chosen player's is skipped (START names table_id only).
func (s Service) offers(c context.Context, q tx.Queryer, catalog d.Catalog, p d.Player, rank int64) ([]d.Occupant, error) {
	chosen := []d.Occupant{}
	tables := map[int64]bool{int64(p.PlayerID) % d.RegionStride: true}
	probes := catalog.OfferRanks(p.Server, p.PlayerID, rank, p.TicketDay, p.RefreshCount)
	for i, probe := range probes {
		if len(chosen) == 3 || len(probe) == 0 {
			break
		}
		// The trailing nearest-ranks probe fills a shortfall; each band gives one.
		near := i == len(probes)-1
		ranked, err := s.Store.RangeTx(c, q, p.Server, slices.Min(probe), slices.Max(probe))
		if err != nil {
			return nil, err
		}
		byRank := map[int64]d.Occupant{}
		players := []identity.PlayerID{}
		for _, r := range ranked {
			byRank[r.Rank] = r.Occupant
			if !r.Occupant.IsRobot() {
				players = append(players, r.Occupant.Player)
			}
		}
		defended, err := s.Store.DefendedTx(c, q, players)
		if err != nil {
			return nil, err
		}
		for _, r := range probe {
			o, ok := byRank[r]
			if len(chosen) == 3 || !ok || o.Player == p.PlayerID || !(o.IsRobot() || defended[o.Player]) || tables[o.TableID()] {
				continue
			}
			chosen = append(chosen, o)
			tables[o.TableID()] = true
			if !near {
				break
			}
		}
	}
	return chosen, nil
}

// display builds an occupant's public face: robots from the catalog, players
// from their canonical owners (directory, guild, roster rows of the defense).
func (s Service) display(c context.Context, q tx.Queryer, catalog d.Catalog, server identity.LogicalServerID, o d.Occupant, at time.Time) (d.Display, error) {
	return s.displayTeam(c, q, catalog, server, o, at, true)
}

// displayTeam leaves player hero rows without force when withForce is false,
// for callers that freeze the same heroes themselves.
func (s Service) displayTeam(c context.Context, q tx.Queryer, catalog d.Catalog, server identity.LogicalServerID, o d.Occupant, at time.Time, withForce bool) (d.Display, error) {
	rank, _, err := s.Store.RankOfTx(c, q, server, o)
	if err != nil {
		return d.Display{}, err
	}
	if o.IsRobot() {
		team, ok := catalog.Team(o.Robot)
		if !ok {
			return d.Display{}, d.ErrConflict
		}
		view := d.Display{Occupant: o, Rank: rank, Name: catalog.RobotName(o.Robot), Level: team.Level, AvatarID: catalog.RobotAvatarID, FrameID: catalog.RobotFrameID}
		if band, ok := catalog.RobotBand(rank); ok && band.Level > view.Level {
			view.Level = band.Level
		}
		heroes, ok := catalog.RobotHeroesAt(o.Robot, rank)
		if !ok {
			return d.Display{}, d.ErrConflict
		}
		view.Heroes = append(view.Heroes, heroes...)
		if pet, ok := catalog.RobotPet(o.Robot, rank); ok {
			view.Pet = pet
		}
		if err = s.fillRobotForce(c, q, view.Heroes, at); err != nil {
			return d.Display{}, err
		}
		view.Force = teamForce(view.Heroes)
		return view, nil
	}
	view, err := s.playerDisplay(c, q, o)
	if err != nil {
		return d.Display{}, err
	}
	view.Rank = rank
	p, found, err := s.Store.ReadPlayerTx(c, q, o.Player, false)
	if err != nil || !found {
		return view, err
	}
	view.Wins = p.Wins
	view.Heroes, view.Pet, err = s.team(c, q, o.Player, p.Defense, p.DefensePet, at)
	if err != nil {
		return view, err
	}
	if !withForce {
		return view, nil
	}
	if err = s.fillHeroForce(c, q, o.Player, view.Heroes, at); err != nil {
		return d.Display{}, err
	}
	view.Force = teamForce(view.Heroes)
	return view, nil
}

// fillHeroForce adds the canonical public force to each defended hero row. The
// stock enemy board reads row.force instead of recomputing it.
func (s Service) fillHeroForce(c context.Context, q tx.Queryer, owner identity.PlayerID, heroes []map[string]any, at time.Time) error {
	if s.HeroPower == nil || len(heroes) == 0 {
		return nil
	}
	scope, ok, err := s.readScope(c, q, at)
	if err != nil || !ok {
		return err
	}
	for _, row := range heroes {
		partnerID, _ := row["partner_id"].(int64)
		if partnerID <= 0 {
			continue
		}
		result, err := s.HeroPower.HeroTx(c, scope, character.HeroRef{PlayerID: owner, PartnerID: partnerID}, publicstats.View{Kind: publicstats.Self, Viewer: owner})
		if err != nil {
			return err
		}
		force := math.Round(result.Stats.Force)
		if math.IsNaN(force) || math.IsInf(force, 0) || force < 0 || force > 100000000000 {
			return d.ErrUnavailable
		}
		row["force"] = int64(force)
	}
	return nil
}

// fillRobotForce gives each robot hero row the power of the same banded team a
// Top Floor fight resolves, so the enemy board and the team popup show it.
func (s Service) fillRobotForce(c context.Context, q tx.Queryer, heroes []map[string]any, at time.Time) error {
	if s.HeroPower == nil || len(heroes) == 0 {
		return nil
	}
	scope, ok, err := s.readScope(c, q, at)
	if err != nil || !ok {
		return err
	}
	for _, row := range heroes {
		tableID, _ := row["table_id"].(int64)
		level, _ := row["lev"].(int64)
		star, _ := row["star"].(int64)
		color, _ := row["color"].(int64)
		flags := integerRows(row["equips"])
		result, err := s.HeroPower.RobotForceTx(c, scope, tableID, level, star, color, flags)
		if err != nil {
			return err
		}
		force := math.Round(result.Stats.Force)
		if math.IsNaN(force) || math.IsInf(force, 0) || force < 0 || force > 100000000000 {
			return d.ErrUnavailable
		}
		row["force"] = int64(force)
	}
	return nil
}

func integerRows(raw any) []int64 {
	items, _ := raw.([]any)
	out := make([]int64, 0, len(items))
	for _, item := range items {
		switch value := item.(type) {
		case int64:
			out = append(out, value)
		case int:
			out = append(out, int64(value))
		case float64:
			out = append(out, int64(value))
		}
	}
	return out
}

// readScope is the coherent read the force projection needs. The stock rank
// list reads on the fresh pool outside a transaction; force is projected only
// where the owner read already holds one.
func (s Service) readScope(c context.Context, q tx.Queryer, at time.Time) (ca.CoherentReadScope, bool, error) {
	raw, ok := q.(tx.Tx)
	if !ok {
		return ca.CoherentReadScope{}, false, nil
	}
	revision, err := s.Content.ActiveRevision(c, q)
	if err != nil {
		return ca.CoherentReadScope{}, false, err
	}
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: revision})
	if err != nil {
		return ca.CoherentReadScope{}, false, err
	}
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: raw, Operation: operation.Context{ID: ids.UUID{15: 1}, StartedAt: at.UTC(), Policies: policies}, Attempt: 1, Options: tx.Options{Isolation: tx.Serializable}}, revision, at)
	if err != nil {
		return ca.CoherentReadScope{}, false, err
	}
	return scope, true, nil
}

// team reads the owner's current roster rows for the given heroes and pet.
func (s Service) team(c context.Context, q tx.Queryer, pid identity.PlayerID, heroes []int64, pet int64, at time.Time) ([]map[string]any, map[string]any, error) {
	detail := map[string]any{}
	actor := identity.ActorContext{PlayerID: pid}
	if err := s.Heroes.OverlayMID1(c, q, actor, false, at, detail); err != nil {
		return nil, nil, err
	}
	body, _ := detail["49"].(map[string]any)
	rows, _ := body["heros"].(map[string]any)
	out := []map[string]any{}
	for _, id := range heroes {
		row, ok := rows[strconv.FormatInt(id, 10)].(map[string]any)
		if !ok {
			return nil, nil, fmt.Errorf("%w: hero %d not owned", d.ErrRefused, id)
		}
		out = append(out, row)
	}
	if pet <= 0 {
		return out, nil, nil
	}
	if err := s.Pets.OverlayMID1(c, q, actor, false, at, detail); err != nil {
		return nil, nil, err
	}
	petBody, _ := detail["780"].(map[string]any)
	pets, _ := petBody["pets"].([]any)
	for _, raw := range pets {
		if row, ok := raw.(map[string]any); ok && fmt.Sprint(row["pet_id"]) == strconv.FormatInt(pet, 10) {
			return out, row, nil
		}
	}
	return nil, nil, fmt.Errorf("%w: pet %d not owned", d.ErrRefused, pet)
}

// defenseShape is the formation validation shared by MID278 and the D511 preset.
func defenseShape(heroes []int64, pet int64) error {
	seen := map[int64]bool{}
	for _, id := range heroes {
		if id <= 0 || seen[id] {
			return d.ErrInvalid
		}
		seen[id] = true
	}
	if len(heroes) > d.DefenseSlots || pet < 0 {
		return d.ErrInvalid
	}
	return nil
}

func (s Service) SaveDefense(c context.Context, a identity.ActorContext, heroes []int64, pet int64, op operation.Context) error {
	if err := defenseShape(heroes, pet); err != nil {
		return err
	}
	if !s.ready() {
		return d.ErrUnavailable
	}
	_, _, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		p, found, err := s.Store.ReadPlayerTx(c, sc.Tx, a.PlayerID, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrRefused)
		}
		if _, _, err = s.team(c, sc.Tx, a.PlayerID, heroes, pet, at); err != nil {
			return err
		}
		next := p
		stamp := at.UTC()
		next.Defense, next.DefensePet, next.DefenseSetAt = append([]int64{}, heroes...), pet, &stamp
		next.StateVersion, next.UpdatedAt = p.StateVersion+1, at
		return s.Store.SavePlayerTx(c, sc.Tx, next, p.StateVersion)
	})
	return err
}

// PreFight checks that the named opponent is currently admissible without
// consuming anything; revenge sends no enemy and is checked at START. A moved
// challenger or offered target rank is refused before the formation opens.
func (s Service) PreFight(c context.Context, a identity.ActorContext, enemy int64, op operation.Context) error {
	if !s.ready() {
		return d.ErrUnavailable
	}
	_, _, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, readRetry(), nil, func(c context.Context, sc gen.TimedScope) error {
		p, found, err := s.Store.ReadPlayerTx(c, sc.Tx, a.PlayerID, false)
		if err != nil || !found {
			return errors.Join(err, d.ErrRefused)
		}
		if enemy == 0 {
			return nil
		}
		occupant, ok := offered(p, enemy)
		if !ok {
			return d.ErrRefused
		}
		rank, ok, err := s.Store.RankOfTx(c, sc.Tx, a.LogicalServerID, d.Occupant{Player: a.PlayerID})
		if err != nil || !ok {
			return errors.Join(err, d.ErrRefused)
		}
		targetRank, ok, err := s.Store.RankOfTx(c, sc.Tx, a.LogicalServerID, occupant)
		if err != nil || !ok {
			return errors.Join(err, d.ErrRefused)
		}
		snapshot, found, err := s.Store.ReadOfferSnapshotTx(c, sc.Tx, a.PlayerID, d.OfferScopeNormal, false)
		if err != nil {
			return err
		}
		return d.MatchOfferSnapshot(snapshot, found, 0, rank, occupant, targetRank)
	})
	return err
}

func offered(p d.Player, table int64) (d.Occupant, bool) {
	for _, o := range p.Offered {
		if o.TableID() == table {
			return o, true
		}
	}
	return d.Occupant{}, false
}

type timedReceipt struct{ receipt.Resolver }

func (r timedReceipt) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation(), CommitError: q.CommitError, Attempt: q.Attempt})
}

// purchase runs one crystal-priced ticket change with an operation receipt for unknown COMMIT.
func (s Service) purchase(c context.Context, a identity.ActorContext, op operation.Context, name string, change func(d.Catalog, d.Player, d.VIP, bool, time.Time) (d.Player, int64, error)) (d.Player, error) {
	var out d.Player
	if !s.ready() {
		return out, d.ErrUnavailable
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "top-floor", Operation: name, SemanticKey: op.ID.String()}
	fp, err := receipt.FingerprintRequest(map[string]any{"player": int64(a.PlayerID), "operation": name})
	if err != nil {
		return out, err
	}
	op, err = s.pin(c, op)
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
		p, found, err := s.Store.ReadPlayerTx(c, sc.Tx, a.PlayerID, true)
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
		if err = s.Store.SavePlayerTx(c, sc.Tx, next, p.StateVersion); err != nil {
			return err
		}
		out = next
		raw, err := json.Marshal(map[string]any{"tickets_left": next.TicketsLeft, "purchases": next.Purchases, "last_match_at": next.LastMatchAt})
		if err != nil {
			return err
		}
		rr, err := receipt.New(sc.Operation.Operation(), id, "I7C5B_TOP_FLOOR", "gxb.topfloor."+name+".v1", raw, fp)
		if err != nil {
			return err
		}
		rr.PolicyVersion, rr.ActorAccountUID, rr.ContextID = d.ContractID, string(a.AccountUID), a.ContextID.UUID()
		_, err = s.Receipts.PutTx(c, sc.Tx, rr)
		return err
	})
	if err == nil && res.Reconciled {
		p, _, readErr := s.Store.ReadPlayerTx(c, s.Fresh, a.PlayerID, false)
		return p, readErr
	}
	return out, err
}

func (s Service) BuyTicket(c context.Context, a identity.ActorContext, op operation.Context) (d.Player, error) {
	return s.purchase(c, a, op, "buy-ticket", func(catalog d.Catalog, p d.Player, v d.VIP, _ bool, at time.Time) (d.Player, int64, error) {
		return catalog.Buy(p, v, at)
	})
}

func (s Service) ResetTimer(c context.Context, a identity.ActorContext, op operation.Context) (d.Player, error) {
	return s.purchase(c, a, op, "reset-timer", func(catalog d.Catalog, p d.Player, v d.VIP, monthly bool, at time.Time) (d.Player, int64, error) {
		return catalog.ResetTimer(p, v, monthly, at)
	})
}

func (s Service) playerDisplay(c context.Context, q tx.Queryer, o d.Occupant) (d.Display, error) {
	profile, found, err := s.Directory.ProfileTx(c, q, o.Player)
	if err != nil || !found {
		return d.Display{}, errors.Join(err, d.ErrUnavailable)
	}
	view := d.Display{Occupant: o, Name: profile.Name, Level: profile.Level, AvatarID: profile.AvatarID, FrameID: profile.AvatarFrameID, ConquerLevel: profile.ConquerLevel, ConquerLoop: profile.ConquerLoopID}
	if membership, member, err := s.Guilds.ReadMembershipTx(c, q, o.Player); err != nil {
		return d.Display{}, err
	} else if member {
		g, ok, err := s.Guilds.ReadGuildTx(c, q, membership.GuildID)
		if err != nil {
			return d.Display{}, err
		}
		if ok {
			view.GuildID, view.GuildName = int64(g.ID), g.Name
		}
	}
	return view, nil
}
func teamForce(heroes []map[string]any) int64 {
	var force int64
	for _, h := range heroes {
		if f, ok := h["force"].(json.Number); ok {
			n, _ := f.Int64()
			force += n
		}
		if f, ok := h["force"].(int64); ok {
			force += f
		}
	}
	return force
}
