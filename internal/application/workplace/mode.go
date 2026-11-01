package workplace

import (
	"context"
	"encoding/json"
	"fmt"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	d "gxb.local/backend/v2/internal/domain/workplace"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"time"
)

const policyID = "I9_WORKPLACE_PRIVATE_POLICY_V1"

type Dispatch struct {
	Team     int64
	Job      int64
	Partners []int64
	SP       int64
}
type view struct {
	catalog  d.Catalog
	revision string
	level    int64
	vip      int64
	eligible map[int64]bool
	locked   map[int64]character.Hero
}

func profile() tx.Profile {
	return tx.Profile{Name: "workplace", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 90 * time.Second}
}
func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

type timedReceipt struct{ receipt.Resolver }

func (r timedReceipt) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation(), CommitError: q.CommitError, Attempt: q.Attempt})
}
func withRevision(op operation.Context, rev string) (operation.Context, error) {
	refs := []policy.Ref{}
	for _, r := range op.Policies.Refs() {
		if r.Name != "content" {
			refs = append(refs, r)
		}
	}
	var err error
	op.Policies, err = policy.NewSet(append(refs, policy.Ref{Name: "content", Version: rev})...)
	return op, err
}
func (s Mode) pin(c context.Context, op operation.Context) (operation.Context, error) {
	if s.Fresh == nil || s.Store == nil || s.Content == nil || s.Fence == nil || s.Functions == nil || s.Directory == nil || s.Campaigns == nil || s.Heroes == nil || s.HeroLocks == nil || s.Values == nil || s.Privileges == nil || s.Facts == nil || s.Combat == nil || s.Stats == nil || s.Opponents == nil || s.HeroWire == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return op, d.ErrUnavailable
	}
	if _, ok := op.Policies.Get("content"); ok {
		return op, nil
	}
	rev, err := s.Content.ActiveRevision(c, s.Fresh)
	if err != nil {
		return op, err
	}
	return withRevision(op, rev)
}
func (s Mode) admit(c context.Context, sc gen.TimedScope, a identity.ActorContext) error {
	if err := s.Fence.FenceActorTx(c, sc.Tx, a, sc.Operation.DecisionAt()); err != nil {
		return err
	}
	gate, ok, err := s.Functions.ReadFunctionEligibilityTx(c, sc.Tx, a.PlayerID, 9)
	if err != nil {
		return err
	}
	if !ok || sc.Operation.DecisionAt().Before(gate.EligibleAt) {
		return d.ErrRefused
	}
	return nil
}
func (s Mode) run(c context.Context, a identity.ActorContext, name string, request any, partners []int64, op operation.Context, apply func(context.Context, gen.TimedScope, view, *d.State) (map[string]any, error)) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(a.PlayerID), Domain: "workplace", Operation: name, SemanticKey: op.ID.String()}
	fp, err := receipt.FingerprintRequest(request)
	if err != nil {
		return nil, err
	}
	var out map[string]any
	_, res, err := s.Timed.Run(c, op, profile(), tx.Options{Isolation: tx.Serializable}, retry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}}, func(c context.Context, sc gen.TimedScope) error {
		if err := s.admit(c, sc, a); err != nil {
			return err
		}
		prior, ok, err := s.Receipts.FindTx(c, sc.Tx, id)
		if err != nil {
			return err
		}
		if ok {
			if prior.RequestFingerprint != fp {
				return &receipt.ConflictError{Identity: id}
			}
			return json.Unmarshal(prior.ResultPayload, &out)
		}
		if err = s.Heroes.LockStoryRosterTx(c, sc.Tx, a.PlayerID); err != nil {
			return err
		}
		v := view{locked: map[int64]character.Hero{}}
		selected := append([]int64{}, partners...)
		sort.Slice(selected, func(i, j int) bool { return selected[i] < selected[j] })
		for _, pid := range selected {
			if pid <= 0 {
				return d.ErrInvalid
			}
			if _, ok := v.locked[pid]; ok {
				return d.ErrInvalid
			}
			h, e := s.HeroLocks.LockHeroByPartnerIDTx(c, sc.Tx, a.PlayerID, pid)
			if e != nil {
				return e
			}
			if s.Rental != nil {
				offered, e := s.Rental.HeroOfferedTx(c, sc.Tx, a.PlayerID, pid)
				if e != nil {
					return e
				}
				if offered {
					return d.ErrRefused
				}
			}
			h.Kind, e = s.Content.HeroKindTx(c, sc.Tx, h.CreationContentRevision, h.TableID)
			if e != nil {
				return e
			}
			v.locked[pid] = h
		}
		state, err := s.Store.LockTx(c, sc.Tx, a.PlayerID, sc.Operation.DecisionAt())
		if err != nil {
			return err
		}
		state.Init()
		v.revision, _ = op.Policies.Get("content")
		v.catalog, err = s.Content.WorkplaceCatalogTx(c, sc.Tx, v.revision)
		if err != nil {
			return err
		}
		p, found, err := s.Directory.ProfileTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return err
		}
		if !found {
			return d.ErrUnavailable
		}
		v.level = p.Level
		priv, err := s.Privileges.SnapshotTx(c, sc.Tx, a.PlayerID, sc.Operation.DecisionAt())
		if err != nil {
			return err
		}
		v.vip = priv.VIPLevel
		if v.vip < 0 || v.vip >= int64(len(v.catalog.VIP)) {
			return d.ErrUnavailable
		}
		progress, err := s.Campaigns.ReadTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return err
		}
		v.eligible = map[int64]bool{}
		for _, job := range v.catalog.Jobs {
			v.eligible[job.ID] = job.RequireType == 1 && v.level >= job.Require || job.RequireType == 2 && progress.Progress.State(job.Require).Star > 0
		}
		day := modes.Day(sc.Operation.DecisionAt())
		if !state.Initialized || day > state.Day || day == state.Day && state.BonusLocation == 0 && !state.BonusUsed && v.level >= v.catalog.Policy.BonusLevel {
			state.Initialized = true
			state.Day = day
			state.BonusUsed = false
			state.BonusLocation = 0
			state.BonusBase = 0
			if v.level >= v.catalog.Policy.BonusLevel {
				places := []int64{}
				for _, l := range v.catalog.Locations {
					for _, j := range l.Jobs {
						if v.eligible[j] {
							places = append(places, l.ID)
							break
						}
					}
				}
				if len(places) > 0 {
					rng := cd.NewStream(sc.Operation.Operation().Derive("workplace.daily-bonus/v1", uint64(day)))
					state.BonusLocation = places[rng.Uniform(uint64(len(places)))]
					state.BonusBase = v.catalog.Policy.BonusMin + int64(rng.Uniform(uint64(v.catalog.Policy.BonusMax-v.catalog.Policy.BonusMin+1)))
				}
			}
		}
		out, err = apply(c, sc, v, &state)
		if err != nil {
			return err
		}
		if err = s.Store.SaveTx(c, sc.Tx, a.PlayerID, state, sc.Operation.DecisionAt()); err != nil {
			return err
		}
		balances, functions := changes.Recorded(c)
		delete(balances, i5.WorkplaceSPKey)
		if len(balances) > 0 {
			out["economy_"] = balances
		}
		if len(functions) > 0 {
			out["new_funcs_"] = functions
		}
		for k, val := range changes.RecordedMissions(c) {
			out[k] = val
		}
		raw, err := json.Marshal(out)
		if err != nil {
			return err
		}
		rec, err := receipt.New(sc.Operation.Operation(), id, "I9_5B_WORKPLACE", "gxb.workplace.result.v1", raw, fp)
		if err != nil {
			return err
		}
		rec.PolicyVersion, rec.ActorAccountUID, rec.ContextID = policyID, string(a.AccountUID), a.ContextID.UUID()
		_, err = s.Receipts.PutTx(c, sc.Tx, rec)
		return err
	})
	if err == nil && res.Reconciled {
		stored, ok := res.Evidence.(receipt.Receipt)
		if !ok {
			return nil, d.ErrUnavailable
		}
		err = json.Unmarshal(stored.ResultPayload, &out)
	}
	return out, err
}
func team(v view, r *d.State, id int64) map[string]any {
	partners := r.Selections[id]
	if partners == nil {
		partners = []int64{}
	}
	bonus := int64(0)
	if !r.BonusUsed && r.BonusLocation == id {
		rate := v.catalog.VIP[v.vip]
		bonus = r.BonusBase * rate.Numerator / rate.Denominator
	}
	wire := map[string]any{"team_id": id, "partners": partners, "start_time": int64(0), "need_time": int64(0), "treasure_type": int64(0), "with_external_award": int64(0), "externa_crystal_award": bonus, "total_lev": int64(0), "total_star": int64(0), "total_color": int64(0)}
	if bonus > 0 {
		wire["with_external_award"] = int64(1)
	}
	if o := r.Slots[id]; o != nil {
		ids := []int64{}
		for _, w := range o.Workers {
			ids = append(ids, w.PartnerID)
		}
		wire["partners"], wire["start_time"], wire["need_time"], wire["treasure_type"] = ids, o.Start, o.Quote.Seconds, o.Job
		wire["total_lev"], wire["total_star"], wire["total_color"] = o.Quote.TotalLevel, o.Quote.TotalStar, o.Quote.TotalColor
		wire["externa_crystal_award"] = o.Award["externa_crystal_award"]
		wire["with_external_award"] = int64(0)
		if n, ok := o.Award["externa_crystal_award"].(int64); ok && n > 0 {
			wire["with_external_award"] = int64(1)
		} else if n, ok := o.Award["externa_crystal_award"].(json.Number); ok && n.String() != "0" {
			wire["with_external_award"] = int64(1)
		}
	}
	return wire
}
func (s Mode) Load(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "load", nil, nil, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		sp, err := s.Values.WorkplaceSPTx(c, sc.Tx, a.PlayerID, ownerOp(sc))
		if err != nil {
			return nil, err
		}
		anchor := int64(0)
		if sp.State.RegenAnchorAt != nil {
			anchor = sp.State.RegenAnchorAt.Unix()
		}
		teams := []map[string]any{}
		for _, l := range v.catalog.Locations {
			teams = append(teams, team(v, r, l.ID))
		}
		return map[string]any{"teams_info": teams, "sp_info": map[string]any{"sp": sp.Amount, "sp_last_refresh_time": anchor, "refresh_sp_times": int64(0)}}, nil
	})
}
func (s Mode) SP(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	body, err := s.Load(c, a, op)
	if err != nil {
		return nil, err
	}
	return body["sp_info"].(map[string]any), nil
}
func (s Mode) Log(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "log", nil, nil, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		return map[string]any{"records": r.Diary}, nil
	})
}

// BusyTx is the typed occupancy read for I9-9 Lending; the caller owns identity admission/locks.
func (s Mode) BusyTx(c context.Context, q tx.Queryer, p identity.PlayerID, partner int64) (bool, error) {
	r, _, err := s.Store.ReadTx(c, q, p)
	return r.Busy(partner), err
}

func ownerOp(sc gen.TimedScope) operation.Context {
	op := sc.Operation.Operation()
	op.StartedAt = sc.Operation.DecisionAt()
	return op
}
