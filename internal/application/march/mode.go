package march

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"strconv"
	"time"
)

type lockedHeroesKey struct{}
type Fight struct {
	Formation  []int64 `json:"formation"`
	Force      int64   `json:"force"`
	RentPlayer int64   `json:"rent_player_id"`
	RentUnit   int64   `json:"rent_formation"`
}
type Result struct {
	Report    cd.Report `json:"report"`
	CostDrink int64     `json:"cost_drink"`
}
type view struct {
	catalog  d.Catalog
	revision string
	day      int64
	level    int64
}

var reportPolicy = cd.ReportPolicy{ID: "MARCH_REPORT_V1", Version: 1, Formation: true, CompleteEnemies: true, LivingWinner: true, WinClearsEnemies: true, MaxHP: 1e12, HPPerFrozen: 2}

func profile() tx.Profile {
	return tx.Profile{Name: "march", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}
func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}
func locator(a identity.ActorContext) cd.Locator {
	return cd.Locator{DomainKind: "CHAMPION_MARCH", AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID), DomainLocator: fmt.Sprintf("player:%d", a.PlayerID)}
}

type timedReceipt struct{ receipt.Resolver }

func (r timedReceipt) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation(), CommitError: q.CommitError, Attempt: q.Attempt})
}
func (s Mode) pin(c context.Context, op operation.Context) (operation.Context, error) {
	if s.Timed.Runner.DB == nil || s.Fresh == nil || s.Content == nil || s.Store == nil || s.Fence == nil || s.Functions == nil || s.Heroes == nil || s.HeroLocks == nil || s.Roster == nil || s.Opponents == nil || s.Combat == nil || s.Facts == nil || s.Grants == nil || s.Costs == nil || s.Receipts == nil || s.ReceiptRead == nil || s.Directory == nil || s.HeroWire == nil || s.Stats == nil {
		return op, d.ErrUnavailable
	}
	if _, ok := op.Policies.Get("content"); ok {
		return op, nil
	}
	rev, err := s.Content.ActiveRevision(c, s.Fresh)
	if err != nil {
		return op, err
	}
	op.Policies, err = policy.NewSet(append(op.Policies.Refs(), policy.Ref{Name: "content", Version: rev})...)
	return op, err
}
func (s Mode) run(c context.Context, a identity.ActorContext, name string, request any, formation []int64, op operation.Context, apply func(context.Context, gen.TimedScope, view, *d.Run) (map[string]any, error)) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "march", Operation: name, SemanticKey: op.ID.String()}
	fp, err := receipt.FingerprintRequest(request)
	if err != nil {
		return nil, err
	}
	var out map[string]any
	_, result, err := s.Timed.Run(c, op, profile(), tx.Options{Isolation: tx.Serializable}, retry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		gate, found, err := s.Functions.ReadFunctionEligibilityTx(c, sc.Tx, a.PlayerID, 8)
		if err != nil {
			return err
		}
		if !found || at.Before(gate.EligibleAt) {
			return d.ErrRefused
		}
		stored, found, err := s.Receipts.FindTx(c, sc.Tx, id)
		if err != nil {
			return err
		}
		if found {
			if stored.RequestFingerprint != fp {
				return &receipt.ConflictError{Identity: id}
			}
			return json.Unmarshal(stored.ResultPayload, &out)
		}
		if err = s.Heroes.LockStoryRosterTx(c, sc.Tx, a.PlayerID); err != nil {
			return err
		}
		selected := formation
		if name == "result" && len(selected) == 0 {
			old, _, e := s.Store.ReadTx(c, sc.Tx, a.PlayerID)
			if e != nil {
				return e
			}
			selected = old.Formation
		}
		ids := append([]int64{}, selected...)
		sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
		locked := map[int64]character.Hero{}
		for _, id := range ids {
			if id > 0 {
				hero, e := s.HeroLocks.LockHeroByPartnerIDTx(c, sc.Tx, a.PlayerID, id)
				if e != nil {
					return e
				}
				locked[id] = hero
			}
		}
		c = context.WithValue(c, lockedHeroesKey{}, locked)
		r, err := s.Store.LockTx(c, sc.Tx, a.PlayerID, at)
		if err != nil {
			return err
		}
		revision, _ := op.Policies.Get("content")
		cat, err := s.Content.MarchCatalogTx(c, sc.Tx, revision)
		if err != nil {
			return err
		}
		player, found, err := s.Directory.ProfileTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return err
		}
		if !found {
			return d.ErrUnavailable
		}
		v := view{catalog: cat, revision: revision, day: modes.Day(at), level: player.Level}
		if r.Occurrence == "" {
			if err = s.initialize(c, sc, a, v, &r, false); err != nil {
				return err
			}
		}
		r.Refresh(v.day)
		out, err = apply(c, sc, v, &r)
		if err != nil {
			return err
		}
		if err = s.Store.SaveTx(c, sc.Tx, a.PlayerID, r, at); err != nil {
			return err
		}
		balances, functions := changes.Recorded(c)
		if len(balances) > 0 {
			out["economy_"] = balances
		}
		if len(functions) > 0 {
			out["new_funcs_"] = functions
		}
		for key, value := range changes.RecordedMissions(c) {
			out[key] = value
		}
		raw, err := json.Marshal(out)
		if err != nil {
			return err
		}
		rec, err := receipt.New(sc.Operation.Operation(), id, "I9_5A_MARCH", "gxb.march.result.v1", raw, fp)
		if err != nil {
			return err
		}
		rec.PolicyVersion, rec.ActorAccountUID, rec.ContextID = d.PolicyID, string(a.AccountUID), a.ContextID.UUID()
		_, err = s.Receipts.PutTx(c, sc.Tx, rec)
		return err
	})
	if err == nil && result.Reconciled {
		stored, ok := result.Evidence.(receipt.Receipt)
		if !ok {
			return nil, d.ErrUnavailable
		}
		err = json.Unmarshal(stored.ResultPayload, &out)
	}
	return out, err
}
func (s Mode) Load(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "load", struct{}{}, nil, op, func(_ context.Context, _ gen.TimedScope, _ view, r *d.Run) (map[string]any, error) {
		return r.Projection(), nil
	})
}
func (s Mode) Reset(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "reset", struct{}{}, nil, op, func(c context.Context, sc gen.TimedScope, v view, r *d.Run) (map[string]any, error) {
		if r.ResetUsed {
			return nil, d.ErrRefused
		}
		if err := s.initialize(c, sc, a, v, r, true); err != nil {
			return nil, err
		}
		return r.Projection(), nil
	})
}
func (s Mode) OverlayMID1(c context.Context, q tx.Queryer, a identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	r, found, err := s.Store.ReadTx(c, q, a.PlayerID)
	if err != nil {
		return err
	}
	// A missing map must stay absent: stock opens the window without LOAD when
	// mapInfo exists, and an uninitialized empty enemy list is not a valid map.
	if !found || r.Occurrence == "" {
		delete(detail, "336")
		return nil
	}
	r.Refresh(modes.Day(at))
	detail["336"] = r.Projection()
	return nil
}
func (s Mode) Start(c context.Context, a identity.ActorContext, q Fight, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "start", q, q.Formation, op, func(c context.Context, sc gen.TimedScope, v view, r *d.Run) (map[string]any, error) {
		if !r.CanFight() {
			return nil, d.ErrRefused
		}
		if err := s.admitFormation(c, sc, a, *r, q.Formation, false); err != nil {
			return nil, err
		}
		if r.Pending != "" {
			if !sameFormation(r.Formation, q.Formation) {
				return nil, d.ErrRefused
			}
		} else {
			r.BattleOrdinal++
			r.Pending = r.Generation()
			r.Formation = append([]int64{}, q.Formation...)
		}
		battle := appcombat.BattleRequest{CampaignType: 5, BattleID: 112000 + r.NextStage(), Formation: q.Formation, PetsA: []appcombat.Participant{}}
		for _, id := range q.Formation {
			if id > 0 {
				battle.TeamA = append(battle.TeamA, appcombat.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: a.PlayerID, Identity: id})
			}
		}
		switch {
		case q.RentUnit == 0:
		case r.Loan == nil:
			r.Loan = &d.Loan{Player: q.RentPlayer, Unit: q.RentUnit}
			battle.TeamA = append(battle.TeamA, appcombat.Participant{Origin: cd.Borrowed, Kind: cd.HeroActor, Player: identity.PlayerID(q.RentPlayer), Identity: q.RentUnit})
		case !r.Loan.Fights(q.RentPlayer, q.RentUnit):
			return nil, d.ErrRefused
		default:
			battle.TeamA = append(battle.TeamA, appcombat.Participant{Origin: cd.Borrowed, Kind: cd.HeroActor, Player: identity.PlayerID(r.Loan.Player), Identity: r.Loan.Unit, LoanHeld: true})
		}
		enemies := []appcombat.Participant{}
		enemy := r.Enemies[r.Passed]
		keys := make([]string, 0, len(enemy.Heroes))
		for key := range enemy.Heroes {
			keys = append(keys, key)
		}
		sort.Strings(keys)
		for _, key := range keys {
			row := enemy.Heroes[key]
			if number(row["health"]) == 2 {
				continue
			}
			raw, _ := json.Marshal(row)
			params := map[string]any{}
			decoder := json.NewDecoder(bytes.NewReader(raw))
			decoder.UseNumber()
			if err := decoder.Decode(&params); err != nil {
				return nil, err
			}
			id, err := strconv.ParseInt(key, 10, 64)
			if err != nil {
				return nil, err
			}
			params["partner_id"] = id
			params["player_id"] = int64(0)
			enemies = append(enemies, appcombat.Participant{Origin: cd.Template, Kind: cd.HeroActor, Identity: id, TemplateParams: params})
		}
		battle.WavesB = [][]appcombat.Participant{enemies}
		scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, v.revision, sc.Operation.DecisionAt())
		if err != nil {
			return nil, err
		}
		fp, err := receipt.FingerprintRequest(map[string]any{"generation": r.Pending, "formation": q.Formation,
			"rent_player": q.RentPlayer, "rent_unit": q.RentUnit})
		if err != nil {
			return nil, err
		}
		_, err = s.Combat.StartTx(c, sc.Tx, scope, appcombat.StartRequest{Actor: a, Locator: locator(a), GenerationRef: r.Pending, StartFingerprint: fmt.Sprintf("%x", fp), ResultDeadline: sc.Operation.DecisionAt().Add(time.Duration(v.catalog.Policy.ResultWindow) * time.Second), Battle: battle, TrustProfile: cd.ClientFullReportAttested, Replay: cd.ReplaySpec{Response: cd.ReplayFightExist, ErrorCode: cd.FightExistCode}, Package: func(_ *cd.Stream) (any, error) {
			return map[string]any{"hero_status": r.Heroes, "enemies": enemy, "power_drink": r.Drinks, "policy": d.PolicyID}, nil
		}})
		if err != nil {
			return nil, err
		}
		r.HasFight = true
		r.Version++
		return r.Projection(), nil
	})
}
func sameFormation(a, b []int64) bool {
	if len(a) != len(b) {
		return false
	}
	for i, v := range a {
		if b[i] != v {
			return false
		}
	}
	return true
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

func (Mode) Name() string     { return "i9-5a.march" }
func (Mode) Claims() []string { return []string{"336"} }
