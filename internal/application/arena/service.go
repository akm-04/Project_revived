package arena

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ErrSettlementDue makes an Arena mutation yield to an owed season settlement.
var ErrSettlementDue = errors.New("arena: season settlement due first")

const (
	seasonMailKind   = "ARENA_SEASON_REWARD"
	championMailKind = "ARENA_CHAMPION"
)

func Profile() tx.Profile {
	return tx.Profile{Name: "arena", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

// settlementProfile bounds a season settlement, which mails every participant.
func settlementProfile() tx.Profile {
	p := Profile()
	p.Name, p.StatementTimeout, p.TransactionTimeout, p.OperationTimeout = "arena-season", 30*time.Second, 300*time.Second, 600*time.Second
	return p
}

func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

// child is a separate system operation; settlements never reuse a player's operation id.
func child(parent operation.Context, label string) (operation.Context, error) {
	id, err := ids.NewUUID()
	if err != nil {
		return operation.Context{}, err
	}
	return operation.Context{ID: id, StartedAt: parent.StartedAt, EntropySeed: parent.Derive("arena:"+label, 0), Policies: parent.Policies}, nil
}

// pin binds the active content revision to the operation once, so every owner
// read and its retries observe one revision (Combat checks it is active).
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

func (s Service) catalogTx(c context.Context, q tx.Queryer) (string, d.Catalog, error) {
	revision, err := s.Content.ActiveRevision(c, q)
	if err != nil {
		return "", d.Catalog{}, err
	}
	catalog, err := s.Content.ArenaCatalogTx(c, q, revision)
	return revision, catalog, err
}

// mutate settles owed seasons first and retries once when one falls due in between.
func (s Service) mutate(c context.Context, op operation.Context, run func() error) error {
	if !s.ready() {
		return d.ErrUnavailable
	}
	for range 2 {
		if _, err := s.Due(c, op); err != nil {
			return err
		}
		if err := run(); !errors.Is(err, ErrSettlementDue) {
			return err
		}
	}
	return ErrSettlementDue
}

// owed refuses a mutation while a closed season is unsettled (settle-before-mutate).
func owed(catalog d.Catalog, root d.Competition, at time.Time) error {
	if root.SettledThrough < catalog.LatestClosed(at) {
		return ErrSettlementDue
	}
	return nil
}

type settledEvidence struct {
	store  Store
	reader tx.Queryer
	season int64
}

func (e settledEvidence) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	r, found, err := e.store.ReadCompetitionTx(c, e.reader, false)
	if err != nil || !found || r.SettledThrough < e.season {
		return tx.Resolution{State: tx.ResolutionUnknown}, err
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: r.SettledThrough}, nil
}

// Due settles every closed season, oldest first, each in its own transaction.
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
		if root.SettledThrough >= catalog.LatestClosed(now) {
			return applied, nil
		}
		season := root.SettledThrough + 1
		op, err := child(parent, fmt.Sprintf("season:%d", season))
		if err != nil {
			return applied, err
		}
		_, _, err = s.Timed.Run(c, op, settlementProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), settledEvidence{store: s.Store, reader: s.Fresh, season: season}, func(c context.Context, sc gen.TimedScope) error {
			return s.settleSeasonTx(c, sc, season)
		})
		if err != nil {
			return applied, err
		}
		applied++
	}
}

// settleSeasonTx mails every season participant its final-level reward and
// the season rank 1 Challenger the champion item, then marks the season settled.
func (s Service) settleSeasonTx(c context.Context, sc gen.TimedScope, season int64) error {
	at := sc.Operation.DecisionAt()
	root, found, err := s.Store.ReadCompetitionTx(c, sc.Tx, true)
	if err != nil || !found {
		return errors.Join(err, d.ErrConflict)
	}
	if root.SettledThrough >= season {
		return nil
	}
	revision, catalog, err := s.catalogTx(c, sc.Tx)
	if err != nil {
		return err
	}
	standings, err := s.Store.StandingsTx(c, sc.Tx, season)
	if err != nil {
		return err
	}
	settlement := d.Settlement{Season: season, CutoffAt: catalog.SeasonNumbered(season).ClosesAt, SettledAt: at, CompetitionVersion: root.StateVersion, ContentRevision: revision}
	for _, line := range catalog.Settle(standings) {
		row := d.SettlementRow{Player: line.Standing.PlayerID, Rank: line.Rank, Level: line.Level, Star: line.Standing.Star, Point: line.Standing.Point, Champion: line.Champion}
		body := fmt.Sprintf(catalog.Mail["REGION_ARENA_MAIL_TEXT"], catalog.LevelName(line.Standing.Star))
		title := fmt.Sprintf(catalog.Mail["REGION_ARENA_MAIL_TITLE"], strconv.FormatInt(season, 10))
		key := strconv.FormatInt(season, 10)
		m, _, err := s.Mail.DeliverTx(c, sc.Tx, i5.SettlementMailRequest{Recipient: line.Standing.PlayerID, SourceKind: seasonMailKind, SourceKey: key, Title: title,
			Sender: catalog.Mail["REGION_ARENA_MAIL_SENDER"], Body: body, PolicyVersion: d.ContractID, Lines: rewardLines(line.Reward), At: at})
		if err != nil {
			return err
		}
		row.Mail = &m.MailUUID
		if line.Champion {
			if _, _, err = s.Mail.DeliverTx(c, sc.Tx, i5.SettlementMailRequest{Recipient: line.Standing.PlayerID, SourceKind: championMailKind, SourceKey: key, Title: title,
				Sender: catalog.Mail["REGION_ARENA_MAIL_SENDER"], Body: body, PolicyVersion: d.ContractID, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: catalog.ChampionItem, Amount: 1}}, At: at}); err != nil {
				return err
			}
		}
		settlement.Rows = append(settlement.Rows, row)
	}
	if err = s.Store.InsertSettlementTx(c, sc.Tx, settlement); err != nil {
		return err
	}
	old := root.StateVersion
	root.SettledThrough, root.StateVersion, root.UpdatedAt = season, old+1, at
	return s.Store.SaveCompetitionTx(c, sc.Tx, root, old)
}

// rewardLines is the region_arena_reward row as mail attachments; the frame
// and skin pack travel as stack items (stack cap 1 and 99).
func rewardLines(reward d.Reward) []grant.Line {
	lines := []grant.Line{}
	for _, scalar := range []struct {
		key    string
		amount int64
	}{{"region_coin", reward.RegionCoin}, {"mana", reward.Mana}} {
		if scalar.amount > 0 {
			lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: scalar.key, Amount: scalar.amount})
		}
	}
	for _, item := range reward.Items {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: item[0], Amount: item[1]})
	}
	for _, id := range []int64{reward.FrameID, reward.SkinID} {
		if id > 0 {
			lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: id, Amount: 1})
		}
	}
	return lines
}

// player reads the actor's row for a change: the root must exist and owe no
// season, and the row is rolled to the current season and day.
func (s Service) player(c context.Context, sc gen.TimedScope, catalog d.Catalog, pid identity.PlayerID) (d.Player, d.Player, error) {
	at := sc.Operation.DecisionAt()
	root, found, err := s.Store.ReadCompetitionTx(c, sc.Tx, false)
	if err != nil || !found {
		return d.Player{}, d.Player{}, errors.Join(err, d.ErrRefused)
	}
	if err = owed(catalog, root, at); err != nil {
		return d.Player{}, d.Player{}, err
	}
	p, found, err := s.Store.ReadPlayerTx(c, sc.Tx, pid, true)
	if err != nil || !found {
		return d.Player{}, d.Player{}, errors.Join(err, d.ErrRefused)
	}
	return p, catalog.Rolled(p, at), nil
}

func (s Service) save(c context.Context, t tx.Tx, before, next d.Player, at time.Time) error {
	next.StateVersion, next.UpdatedAt = before.StateVersion+1, at
	return s.Store.SavePlayerTx(c, t, next, before.StateVersion)
}

func (s Service) balance(c context.Context, q tx.Queryer, pid identity.PlayerID, key string) (int64, error) {
	b, found, err := s.Values.ReadScalarTx(c, q, pid, key)
	if err != nil || !found {
		return 0, err
	}
	return b.Amount, nil
}

// gate requires function 37: level 60 (client type-6 rule) and 5 owned girls.
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

// Info enters the player on first use and answers GET_REARENA_INFO.
func (s Service) Info(c context.Context, a identity.ActorContext, op operation.Context) (d.InfoView, error) {
	var out d.InfoView
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
				root = d.Competition{ID: d.CompetitionID, ContentRevision: revision, SettledThrough: max(0, catalog.LatestClosed(at)), StateVersion: 1, CreatedAt: at, UpdatedAt: at}
				if err = s.Store.CreateCompetitionTx(c, sc.Tx, root); err != nil {
					return err
				}
			}
			if err = owed(catalog, root, at); err != nil {
				return err
			}
			p, found, err := s.Store.ReadPlayerTx(c, sc.Tx, a.PlayerID, true)
			if err != nil {
				return err
			}
			if !found {
				if err = s.gate(c, sc.Tx, catalog, a.PlayerID, at); err != nil {
					return err
				}
				// Bumping the root serializes concurrent first entries into a retryable conflict.
				if root, _, err = s.Store.ReadCompetitionTx(c, sc.Tx, true); err != nil {
					return err
				}
				old := root.StateVersion
				root.StateVersion, root.UpdatedAt = old+1, at
				if err = s.Store.SaveCompetitionTx(c, sc.Tx, root, old); err != nil {
					return err
				}
				p = d.NewPlayer(catalog, a.PlayerID, a.LogicalServerID, at)
				if err = s.Store.InsertPlayerTx(c, sc.Tx, p, revision); err != nil {
					return err
				}
			}
			next := catalog.Rolled(p, at)
			if !samePlayer(p, next) {
				if err = s.save(c, sc.Tx, p, next, at); err != nil {
					return err
				}
			}
			out, err = s.infoView(c, sc.Tx, catalog, next, at)
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

func (s Service) infoView(c context.Context, q tx.Queryer, catalog d.Catalog, p d.Player, at time.Time) (d.InfoView, error) {
	season := catalog.SeasonAt(at)
	standings, err := s.Store.StandingsTx(c, q, season.Number)
	if err != nil {
		return d.InfoView{}, err
	}
	king, err := s.balance(c, q, p.PlayerID, "king_coin")
	if err != nil {
		return d.InfoView{}, err
	}
	return d.InfoView{Player: p, Season: season, Rank: d.Rank(d.Order(standings), p.PlayerID), Total: int64(len(standings)), Closed: !season.Open(at), KingCoin: king, At: at}, nil
}

// change runs one locked player change of the actor in the current season.
func (s Service) change(c context.Context, a identity.ActorContext, op operation.Context, apply func(context.Context, gen.TimedScope, d.Catalog, d.Player) (d.Player, error)) (d.Player, error) {
	var out d.Player
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
			before, p, err := s.player(c, sc, catalog, a.PlayerID)
			if err != nil {
				return err
			}
			next, err := apply(c, sc, catalog, p)
			if err != nil {
				return err
			}
			out = next
			return s.save(c, sc.Tx, before, next, at)
		})
		return err
	})
	return out, err
}

// ModifyDefence saves exactly five distinct girls by table id, each owned or
// summoned this season, and an optional own pet.
func (s Service) ModifyDefence(c context.Context, a identity.ActorContext, heroes []int64, pet int64, op operation.Context) (d.Player, error) {
	if pet < 0 {
		return d.Player{}, d.ErrInvalid
	}
	return s.change(c, a, op, func(c context.Context, sc gen.TimedScope, catalog d.Catalog, p d.Player) (d.Player, error) {
		at := sc.Operation.DecisionAt()
		templates, err := s.templates(c, sc.Tx)
		if err != nil {
			return p, err
		}
		if !d.ValidFormation(heroes, templates.Base, true) {
			return p, d.ErrInvalid
		}
		roster, err := s.heroRows(c, sc.Tx, a.PlayerID, at)
		if err != nil {
			return p, err
		}
		for _, id := range heroes {
			if _, ok := s.available(p, roster, templates, id); !ok {
				return p, fmt.Errorf("%w: girl %d unavailable", d.ErrRefused, id)
			}
		}
		if pet > 0 {
			pets, err := s.petRows(c, sc.Tx, a.PlayerID, at)
			if err != nil {
				return p, err
			}
			if _, owned := pets[strconv.FormatInt(pet, 10)]; !owned {
				return p, fmt.Errorf("%w: pet %d not owned", d.ErrRefused, pet)
			}
		}
		p.Defense = d.Lineup{Heroes: heroes, Pet: pet}
		return p, nil
	})
}

// receipted runs one value-moving change with an operation receipt so an
// unknown COMMIT resolves without a second grant or debit.
func (s Service) receipted(c context.Context, a identity.ActorContext, op operation.Context, name string, apply func(context.Context, gen.TimedScope, d.Catalog, d.Player) (d.Player, d.MissionsView, error)) (d.MissionsView, error) {
	var out d.MissionsView
	if !s.ready() {
		return out, d.ErrUnavailable
	}
	// I5 grants and debits settle against the operation's pinned content revision.
	op, err := s.pin(c, op)
	if err != nil {
		return out, err
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "arena", Operation: name, SemanticKey: op.ID.String()}
	fp, err := receipt.FingerprintRequest(map[string]any{"player": int64(a.PlayerID), "operation": name})
	if err != nil {
		return out, err
	}
	var reconciled bool
	err = s.mutate(c, op, func() error {
		_, res, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}}, func(c context.Context, sc gen.TimedScope) error {
			at := sc.Operation.DecisionAt()
			if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
				return err
			}
			_, catalog, err := s.catalogTx(c, sc.Tx)
			if err != nil {
				return err
			}
			before, p, err := s.player(c, sc, catalog, a.PlayerID)
			if err != nil {
				return err
			}
			next, view, err := apply(c, sc, catalog, p)
			if err != nil {
				return err
			}
			if err = s.save(c, sc.Tx, before, next, at); err != nil {
				return err
			}
			if view.KingCoin, err = s.balance(c, sc.Tx, a.PlayerID, "king_coin"); err != nil {
				return err
			}
			view.Player = next
			out = view
			raw, err := json.Marshal(map[string]any{"missions": next.Missions, "awards": next.Awards})
			if err != nil {
				return err
			}
			rr, err := receipt.New(sc.Operation.Operation(), id, "I7C5D_ARENA", "gxb.arena."+name+".v1", raw, fp)
			if err != nil {
				return err
			}
			rr.PolicyVersion, rr.ActorAccountUID, rr.ContextID = d.ContractID, string(a.AccountUID), a.ContextID.UUID()
			_, err = s.Receipts.PutTx(c, sc.Tx, rr)
			return err
		})
		reconciled = res.Reconciled
		return err
	})
	if err != nil || !reconciled {
		return out, err
	}
	p, _, err := s.Store.ReadPlayerTx(c, s.Fresh, a.PlayerID, false)
	if err != nil {
		return out, err
	}
	king, err := s.balance(c, s.Fresh, a.PlayerID, "king_coin")
	return d.MissionsView{Player: p, KingCoin: king}, err
}

type timedReceipt struct{ receipt.Resolver }

func (r timedReceipt) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation(), CommitError: q.CommitError, Attempt: q.Attempt})
}

func grantPlan(pid identity.PlayerID, op operation.Context, name string, lines []grant.Line) grant.Plan {
	return grant.Plan{PlayerID: pid, Source: grant.SourceIdentity{Domain: "arena", Operation: name, BusinessKey: strconv.FormatInt(int64(pid), 10), Occurrence: op.ID.String(), PolicyVersion: d.ContractID}, Lines: lines}
}

// ClaimMission empties a completed mission slot and grants its king_coin.
func (s Service) ClaimMission(c context.Context, a identity.ActorContext, mission int64, op operation.Context) (d.MissionsView, error) {
	return s.receipted(c, a, op, "claim-mission", func(c context.Context, sc gen.TimedScope, catalog d.Catalog, p d.Player) (d.Player, d.MissionsView, error) {
		next, coins, err := catalog.Claim(p, mission, sc.Operation.DecisionAt())
		if err != nil {
			return p, d.MissionsView{}, err
		}
		plan := grantPlan(a.PlayerID, sc.Operation.Operation(), "claim-mission", []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "king_coin", Amount: coins}})
		if _, err = s.Grants.SettleGrantTx(c, sc.Tx, a, plan, sc.Operation.Operation(), i5.GrantTxOptions{}); err != nil {
			return p, d.MissionsView{}, err
		}
		return next, d.MissionsView{Coins: coins}, nil
	})
}

func (s Service) GiveUpMission(c context.Context, a identity.ActorContext, mission int64, op operation.Context) (d.MissionsView, error) {
	return s.receipted(c, a, op, "give-up-mission", func(_ context.Context, sc gen.TimedScope, catalog d.Catalog, p d.Player) (d.Player, d.MissionsView, error) {
		next, err := catalog.GiveUp(p, mission, sc.Operation.DecisionAt())
		return next, d.MissionsView{}, err
	})
}

// Exchange buys one season award with king_coin (RegionArenaHeroShop).
func (s Service) Exchange(c context.Context, a identity.ActorContext, exchangeType, tableID int64, op operation.Context) (d.MissionsView, error) {
	return s.receipted(c, a, op, "exchange", func(c context.Context, sc gen.TimedScope, catalog d.Catalog, p d.Player) (d.Player, d.MissionsView, error) {
		at := sc.Operation.DecisionAt()
		templates, err := s.templates(c, sc.Tx)
		if err != nil {
			return p, d.MissionsView{}, err
		}
		template, known := templates[tableID]
		roster, err := s.heroRows(c, sc.Tx, a.PlayerID, at)
		if err != nil {
			return p, d.MissionsView{}, err
		}
		girl := d.Girl{Known: known, Super: template.Super, InitialStar: template.InitialStar, CanAwaken: templates.CanAwaken(template.Base)}
		if row, owned := strongest(roster, templates, tableID); owned {
			girl.Owned, girl.Star = true, number(row["star"])
			girl.Awakened = templates[number(row["table_id"])].Awakened
		}
		next, award, cost, err := catalog.Exchange(p, exchangeType, template.Base, girl)
		if err != nil {
			return p, d.MissionsView{}, err
		}
		if _, err = s.Costs.DebitMaterialCostTx(c, sc.Tx, a.PlayerID, i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "king_coin", Amount: cost}}}, sc.Operation.Operation()); err != nil {
			return p, d.MissionsView{}, err
		}
		return next, d.MissionsView{Award: &award}, nil
	})
}
