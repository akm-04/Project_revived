package topfloor

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"slices"
	"strconv"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/operation"
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

func (s Service) arena(c context.Context, a identity.ActorContext, op operation.Context, refresh bool) (ArenaView, error) {
	var out ArenaView
	err := s.mutate(c, a.LogicalServerID, op, func() error {
		_, _, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
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
			p, found, err := s.Store.ReadPlayerTx(c, sc.Tx, a.PlayerID, true)
			if err != nil {
				return err
			}
			if !found {
				if p, err = s.enter(c, sc.Tx, catalog, revision, a, at); err != nil {
					return err
				}
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
			out = ArenaView{Player: next, Rank: rank, ServerTime: at}
			for _, o := range next.Offered {
				view, err := s.display(c, sc.Tx, catalog, a.LogicalServerID, o, at)
				if err != nil {
					return err
				}
				out.Enemies = append(out.Enemies, view)
			}
			return nil
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

// enter seeds the server ladder on first use and appends the player at the bottom.
func (s Service) enter(c context.Context, t tx.Tx, catalog d.Catalog, revision string, a identity.ActorContext, at time.Time) (d.Player, error) {
	l, found, err := s.Store.ReadLadderTx(c, t, a.LogicalServerID, true)
	if err != nil {
		return d.Player{}, err
	}
	if !found {
		l, _ = catalog.NewLadder(a.LogicalServerID, revision, at)
		if err = s.Store.CreateLadderTx(c, t, l); err != nil {
			return d.Player{}, err
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
	next.Size, next.StateVersion, next.UpdatedAt = rank, l.StateVersion+1, at
	if err = s.Store.SaveLadderTx(c, t, next, l.StateVersion); err != nil {
		return d.Player{}, err
	}
	p := catalog.NewPlayer(a.PlayerID, a.LogicalServerID, revision, rank, at)
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
		for _, id := range team.Heroes {
			params, _ := catalog.RobotHeroParams(id)
			view.Heroes = append(view.Heroes, params)
		}
		return view, nil
	}
	profile, found, err := s.Directory.ProfileTx(c, q, o.Player)
	if err != nil || !found {
		return d.Display{}, errors.Join(err, d.ErrUnavailable)
	}
	view := d.Display{Occupant: o, Rank: rank, Name: profile.Name, Level: profile.Level, AvatarID: profile.AvatarID, FrameID: profile.AvatarFrameID, ConquerLevel: profile.ConquerLevel, ConquerLoop: profile.ConquerLoopID}
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
	p, found, err := s.Store.ReadPlayerTx(c, q, o.Player, false)
	if err != nil || !found {
		return view, err
	}
	view.Wins = p.Wins
	view.Heroes, view.Pet, err = s.team(c, q, o.Player, p.Defense, p.DefensePet, at)
	for _, h := range view.Heroes {
		if f, ok := h["force"].(json.Number); ok {
			n, _ := f.Int64()
			view.Force += n
		}
		if f, ok := h["force"].(int64); ok {
			view.Force += f
		}
	}
	return view, err
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

func (s Service) SaveDefense(c context.Context, a identity.ActorContext, heroes []int64, pet int64, op operation.Context) error {
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
// consuming anything; revenge sends no enemy and is checked at START.
func (s Service) PreFight(c context.Context, a identity.ActorContext, enemy int64) error {
	if !s.ready() {
		return d.ErrUnavailable
	}
	p, found, err := s.Store.ReadPlayerTx(c, s.Fresh, a.PlayerID, false)
	if err != nil || !found {
		return errors.Join(err, d.ErrRefused)
	}
	if enemy == 0 {
		return nil
	}
	if _, ok := offered(p, enemy); !ok {
		return d.ErrRefused
	}
	return nil
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
