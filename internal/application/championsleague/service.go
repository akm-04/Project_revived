package championsleague

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
	"time"
)

func Profile() tx.Profile {
	return tx.Profile{Name: "champions-league", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 30 * time.Second, TransactionTimeout: 120 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 180 * time.Second}
}
func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

type proof struct{ receipt.Resolver }

func (p proof) ResolveTimed(c context.Context, r gen.TimedResolutionRequest) (tx.Resolution, error) {
	return p.Resolve(c, tx.ResolutionRequest{Operation: r.Operation.Operation(), CommitError: r.CommitError, Attempt: r.Attempt})
}
func (s Service) pin(c context.Context, op operation.Context) (operation.Context, error) {
	if _, ok := op.Policies.Get("content"); ok {
		return op, nil
	}
	r, e := s.Content.ActiveRevision(c, s.Fresh)
	if e != nil {
		return op, e
	}
	op.Policies, e = policy.NewSet(append(op.Policies.Refs(), policy.Ref{Name: "content", Version: r})...)
	return op, e
}
func (s Service) catalog(c context.Context, q tx.Queryer, op operation.Context) (string, d.Catalog, error) {
	r, ok := op.Policies.Get("content")
	if !ok {
		return "", d.Catalog{}, d.ErrUnavailable
	}
	cat, e := s.Content.LeagueCatalogTx(c, q, r)
	return r, cat, e
}
func number(v any) int64 {
	switch x := v.(type) {
	case int64:
		return x
	case int:
		return int64(x)
	case float64:
		return int64(x)
	case json.Number:
		n, _ := x.Int64()
		return n
	case string:
		n, _ := strconv.ParseInt(x, 10, 64)
		return n
	}
	return 0
}
func find(players []d.Player, id identity.PlayerID) (d.Player, bool) {
	for _, p := range players {
		if p.ID == id {
			return p, true
		}
	}
	return d.Player{}, false
}
func set(players []d.Player, p d.Player) []d.Player {
	for i, x := range players {
		if x.ID == p.ID {
			players[i] = p
			return players
		}
	}
	return append(players, p)
}
func (s Service) savePlayer(c context.Context, t tx.Tx, p *d.Player, at time.Time) error {
	old := p.Version
	p.Version++
	p.UpdatedAt = at
	return s.Store.PutPlayerTx(c, t, *p, old)
}
func (s Service) rows(c context.Context, q tx.Queryer, pid identity.PlayerID, l d.Lineup, at time.Time) ([]map[string]any, map[string]any, error) {
	if !l.Valid(true) {
		return nil, nil, d.ErrInvalid
	}
	detail := map[string]any{}
	a := identity.ActorContext{PlayerID: pid}
	if e := s.Heroes.OverlayMID1(c, q, a, false, at, detail); e != nil {
		return nil, nil, e
	}
	body, _ := detail["49"].(map[string]any)
	heros, _ := body["heros"].(map[string]any)
	out := []map[string]any{}
	for _, id := range l.Heroes {
		row, ok := heros[strconv.FormatInt(id, 10)].(map[string]any)
		if !ok || number(row["partner_id"]) != id {
			return nil, nil, fmt.Errorf("%w: owned girl %d", d.ErrRefused, id)
		}
		out = append(out, row)
	}
	if l.Pet == 0 {
		return out, nil, nil
	}
	if e := s.Pets.OverlayMID1(c, q, a, false, at, detail); e != nil {
		return nil, nil, e
	}
	pb, _ := detail["780"].(map[string]any)
	pets, _ := pb["pets"].([]any)
	for _, raw := range pets {
		if row, ok := raw.(map[string]any); ok && number(row["pet_id"]) == l.Pet {
			return out, row, nil
		}
	}
	return nil, nil, fmt.Errorf("%w: owned pet %d", d.ErrRefused, l.Pet)
}
func (s Service) face(c context.Context, q tx.Queryer, id identity.PlayerID) (d.Face, error) {
	v, ok, e := s.Directory.ProfileTx(c, q, id)
	if e != nil || !ok {
		return d.Face{}, errors.Join(e, d.ErrUnavailable)
	}
	out := d.Face{ID: id, Name: v.Name, Level: v.Level, Avatar: v.AvatarID, Frame: v.AvatarFrameID, Conquer: v.ConquerLevel, Loop: v.ConquerLoopID}
	if membership, found, e := s.Guilds.ReadMembershipTx(c, q, id); e != nil {
		return out, e
	} else if found {
		g, exists, e := s.Guilds.ReadGuildTx(c, q, membership.GuildID)
		if e != nil {
			return out, e
		}
		if exists {
			out.GuildID = int64(g.ID)
			out.GuildName = g.Name
		}
	}
	return out, nil
}
func (s Service) enemy(c context.Context, q tx.Queryer, players []d.Player, p d.Player, at time.Time) (EnemyView, error) {
	v := EnemyView{Player: p, Rank: d.Rank(d.Order(players, p.Season, p.Group), p.ID)}
	var e error
	if v.Face, e = s.face(c, q, p.ID); e != nil {
		return v, e
	}
	v.Heroes, v.Pet, e = s.displayRows(c, q, p.ID, p.Defense, at)
	return v, e
}

// Execute runs one source command in a repeatable-read caller transaction.
// It replays exact operation receipts; new HTTP operations still use durable
// fight intent / daily-claim identities to avoid stock-client retry duplicates.
func (s Service) Execute(c context.Context, a identity.ActorContext, cmd Command, op operation.Context) (Reply, error) {
	if !s.ready() {
		return Reply{}, d.ErrUnavailable
	}
	switch cmd.Kind {
	case "INFO", "ENEMY", "DEFENSE", "CHOOSE", "CLAIM", "FIGHT", "RECORDS", "HONOR":
	default:
		return Reply{}, d.ErrInvalid
	}
	var e error
	if op, e = s.pin(c, op); e != nil {
		return Reply{}, e
	}
	if e = s.Due(c, op, 100); e != nil {
		return Reply{}, e
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "champions-league", Operation: cmd.Kind, SemanticKey: op.ID.String()}
	fp, e := receipt.FingerprintRequest(cmd)
	if e != nil {
		return Reply{}, e
	}
	var out Reply
	_, res, e := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), proof{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if e := s.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		if r, found, e := s.Receipts.FindTx(c, sc.Tx, id); e != nil {
			return e
		} else if found {
			if r.RequestFingerprint != fp {
				return d.ErrConflict
			}
			return json.Unmarshal(r.ResultPayload, &out)
		}
		rev, cat, e := s.catalog(c, sc.Tx, op)
		if e != nil {
			return e
		}
		root, found, e := s.Store.RootTx(c, sc.Tx, true)
		if e != nil {
			return e
		}
		if !found {
			season := cat.SeasonAt(at)
			if season.Number < 1 {
				return d.ErrRefused
			}
			settled := season.Number - 1
			if !season.Open(at) {
				settled = season.Number
			}
			root = d.Root{Revision: rev, Season: season.Number, SettledSeason: settled, Day: cat.Day(at), Version: 1, CreatedAt: at, UpdatedAt: at}
			if e = s.Store.PutRootTx(c, sc.Tx, root, 0); e != nil {
				return e
			}
		}
		if due(cat, root, at) {
			return d.ErrDue
		}
		if at.Before(root.UpdatedAt) {
			return d.ErrConflict
		}
		players, e := s.Store.PlayersTx(c, sc.Tx, true)
		if e != nil {
			return e
		}
		p, present := find(players, a.PlayerID)
		_, e = s.face(c, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		level, e := s.level(c, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		group := cat.Group(level)
		fact, eligible, e := s.Progression.ReadFunctionEligibilityTx(c, sc.Tx, a.PlayerID, cat.FunctionID)
		if e != nil {
			return e
		}
		if !eligible || fact.PlayerID != a.PlayerID || fact.FunctionID != cat.FunctionID || at.Before(fact.EligibleAt) {
			return d.ErrRefused
		}
		if group == 0 {
			return d.ErrRefused
		}
		if !present {
			if cmd.Kind != "INFO" {
				return d.ErrRefused
			}
			p = cat.NewPlayer(a.PlayerID, a.LogicalServerID, level, at)
			if e = s.Store.PutPlayerTx(c, sc.Tx, p, 0); e != nil {
				return e
			}
			players = set(players, p)
		} else {
			if p.Server != a.LogicalServerID {
				return d.ErrConflict
			}
			if p.Season != root.Season {
				return d.ErrConflict
			}
			if group > p.Group {
				if m, ok, e := s.Store.IntentTx(c, sc.Tx, p.ID, p.Intent); e != nil {
					return e
				} else if ok && m.Status == "FIGHTING" {
					return d.ErrPending
				}
			}
			p = cat.Promote(p, group, d.Rank(d.Order(players, p.Season, p.Group), p.ID), at)
		}
		if !cat.SeasonNumbered(root.Season).Open(at) && (cmd.Kind == "FIGHT" || cmd.Kind == "DEFENSE" || cmd.Kind == "CHOOSE" || cmd.Kind == "ENEMY") {
			return d.ErrRefused
		}
		out = Reply{Kind: cmd.Kind}
		switch cmd.Kind {
		case "INFO":
			// A menu reopen may start another attack only after the old intent ended.
			if m, ok, e := s.Store.IntentTx(c, sc.Tx, p.ID, p.Intent); e != nil {
				return e
			} else if ok && m.Status != "FIGHTING" {
				p.Intent++
				p.Selected = 0
			}
			players = set(players, p)
			v := InfoView{Player: p, Rank: d.Rank(d.Order(players, p.Season, p.Group), p.ID), At: at, Active: cat.SeasonNumbered(root.Season).Open(at), Final: d.FinalPlacement(players, p)}
			v.Defense, e = s.enemy(c, sc.Tx, players, p, at)
			if e != nil {
				return e
			}
			ordered := d.Order(players, p.Season, p.Group)
			for i, x := range ordered {
				r := int64(i + 1)
				if x.ID == p.ID || r < v.Rank-cat.OpponentRadius || r > v.Rank+cat.OpponentRadius {
					continue
				}
				ev := EnemyView{Player: x, Rank: r}
				if ev.Face, e = s.face(c, sc.Tx, x.ID); e != nil {
					return e
				}
				v.Enemies = append(v.Enemies, ev)
			}
			out.Info = v
		case "ENEMY":
			enemy, ok := find(players, cmd.Enemy)
			if !ok || enemy.ID == p.ID || enemy.Season != p.Season || enemy.Group != p.Group {
				return d.ErrRefused
			}
			if m, ok, e := s.Store.IntentTx(c, sc.Tx, p.ID, p.Intent); e != nil {
				return e
			} else if ok {
				if m.Status == "FIGHTING" {
					return d.ErrRefused
				}
				p.Intent++
			}
			ordered := d.Order(players, p.Season, p.Group)
			rank, er := d.Rank(ordered, p.ID), d.Rank(ordered, enemy.ID)
			if er < rank-cat.OpponentRadius || er > rank+cat.OpponentRadius {
				return d.ErrRefused
			}
			p.Selected = enemy.ID
			out.Enemy, e = s.enemy(c, sc.Tx, players, enemy, at)
			if e != nil {
				return e
			}
		case "DEFENSE":
			if !cmd.Lineup.Valid(true) {
				return d.ErrInvalid
			}
			if _, _, e = s.rows(c, sc.Tx, p.ID, cmd.Lineup, at); e != nil {
				return e
			}
			p.Defense = cmd.Lineup
		case "CHOOSE":
			if !p.ChoicePending {
				return d.ErrRefused
			}
			p.Choice = 0
			if cmd.UseOriginal {
				p.Choice = 1
			}
			p.ChoicePending = false
		case "CLAIM":
			day := cat.Day(at)
			if p.ClaimedDay >= day || p.LastWin.Unix() <= cat.DayAt(day).Unix() {
				return d.ErrRefused
			}
			g := cat.DailyGift(p.LastDay.Group, p.LastDay.Rank)
			lines := giftLines(g)
			if len(lines) == 0 {
				return d.ErrUnavailable
			}
			plan := grant.Plan{PlayerID: p.ID, Source: grant.SourceIdentity{Domain: "champions-league", Operation: "daily-chest", BusinessKey: strconv.FormatInt(int64(p.ID), 10), Occurrence: strconv.FormatInt(day, 10), PolicyVersion: d.ContractID}, Lines: lines}
			gr, e := s.Grants.SettleGrantTx(c, sc.Tx, a, plan, sc.Operation.Operation(), i5.GrantTxOptions{AllowOverflowMail: true})
			if e != nil {
				return e
			}
			p.ClaimedDay = day
			for _, item := range gr.Awards {
				if item.TableID > 0 && item.ItemNum > 0 {
					out.Awards = append(out.Awards, Item{item.TableID, item.ItemNum})
				}
			}
		case "FIGHT":
			players = set(players, p)
			out.Match, e = s.admit(c, sc, a, op, cat, rev, &p, &players, cmd)
			if e != nil {
				return e
			}
		case "RECORDS":
			out.Records, e = s.Store.RecordsTx(c, sc.Tx, p.ID)
			if e != nil {
				return e
			}
			if cmd.RecordID > 0 {
				found := false
				for _, m := range out.Records {
					if m.WireID == cmd.RecordID {
						found = true
						out.Match = m
						break
					}
				}
				if !found {
					return d.ErrRefused
				}
				if out.Match.SettledAt != nil && at.Unix() < out.Match.SettledAt.Unix()+d.ReplaySeconds {
					v, e := s.Combat.ResultTx(c, sc.Tx, out.Match.Attempt)
					if e != nil {
						return e
					}
					out.Report = v.Report
				}
			}
		case "HONOR":
			if root.Season > 1 {
				prev, ok, e := s.Store.SettlementTx(c, sc.Tx, "SEASON", root.Season-1)
				if e != nil {
					return e
				}
				if ok {
					for _, r := range prev.Rows {
						if r.Placement.Group == p.Group && r.Placement.Rank <= 10 {
							out.Honor = append(out.Honor, r)
						}
					}
				}
			}
		}
		if e = s.savePlayer(c, sc.Tx, &p, at); e != nil {
			return e
		}
		old := root.Version
		root.Version++
		root.UpdatedAt = at
		if e = s.Store.PutRootTx(c, sc.Tx, root, old); e != nil {
			return e
		}
		raw, e := json.Marshal(out)
		if e != nil {
			return e
		}
		r, e := receipt.New(sc.Operation.Operation(), id, "I7C5F_LEAGUE", "gxb.league.command.v1", raw, fp)
		if e != nil {
			return e
		}
		r.PolicyVersion = d.ContractID
		r.ActorAccountUID = string(a.AccountUID)
		r.ContextID = a.ContextID.UUID()
		_, e = s.Receipts.PutTx(c, sc.Tx, r)
		return e
	})
	if e != nil {
		return Reply{}, e
	}
	if res.Reconciled {
		r, ok, e := s.ReceiptRead.Find(c, id)
		if e != nil || !ok {
			return Reply{}, errors.Join(e, d.ErrConflict)
		}
		if e = json.Unmarshal(r.ResultPayload, &out); e != nil {
			return Reply{}, e
		}
	}
	if cmd.Kind == "FIGHT" {
		return s.finish(c, out.Match, op, 15*time.Second)
	}
	return out, nil
}
func giftLines(g d.Gift) []grant.Line {
	out := []grant.Line{}
	for _, x := range g.Items {
		out = append(out, grant.Line{Kind: grant.StackItem, ItemID: x[0], Amount: x[1]})
	}
	if g.Crystal > 0 {
		out = append(out, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: g.Crystal})
	}
	if g.Mana > 0 {
		out = append(out, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: g.Mana})
	}
	return out
}

// I5 progression is gameplay authority; the directory is presentation only.
func (s Service) level(c context.Context, q tx.Queryer, id identity.PlayerID) (int64, error) {
	v, e := s.Progression.ReadProgressionTx(c, q, id)
	return v.Level, e
}
