package achievement

import (
	"context"
	"encoding/json"
	"errors"
	"sort"
	"strconv"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// CatalogPolicy is the I7C-4 full stage A runtime (C4F_ACHIEVEMENT_CATALOG_AND_AP_V1).
const CatalogPolicy = "C4F_ACHIEVEMENT_CATALOG_AND_AP_V1"

// Notice is one durable C4F_ACHIEVEMENT_NOTICE_V1 intent for a newly earned tier.
type Notice struct {
	Player        identity.PlayerID
	AchievementID int64
	Tier          int
	CompleteTime  time.Time
}

type Counter interface {
	OwnedStateCountsTx(context.Context, ca.CoherentReadScope, identity.PlayerID, []int64) map[int64]int64
}
type ActiveContent interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
}
type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

// Runtime carries the full-catalog collaborators; Service without it keeps
// only the 4B/5x producers.
type Runtime struct {
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Active      ActiveContent
	Counts      Counter
	Fence       Fence
	Grants      i5.TxGrantSettler
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
	Directory   Directory
	Servers     Servers
}

func (r *Runtime) ready() bool {
	return r != nil && r.Timed.Runner.DB != nil && r.Timed.Binder.Time != nil && r.Fresh != nil && r.Active != nil && r.Counts != nil && r.Fence != nil && r.Grants != nil && r.Receipts != nil && r.ReceiptRead != nil
}

// Families selects the owned-state achievements an owner's command can change.
var Families = map[string][]int64{
	"Hero":        {d.NormalHeroesID, d.AwakenedHeroesID},
	"Pet":         {d.PetsID},
	"Book":        {d.TextbooksID},
	"Conquer":     {d.RegionsID},
	"Course":      {d.SubjectsID},
	"Inscription": {d.SuitsID},
	"Dorm":        {d.RoomsID, d.ExpandedRoomsID},
}

func allFamilies() []int64 { return append(append([]int64{}, d.OwnedStateIDs...), d.SelectedID) }

type Entry struct {
	AchievementID int64
	CompleteTimes [3]int64
	Progress      int64
	Status        d.Status
}
type View struct {
	Entries     []Entry
	PointLevel  int64
	TotalPoints int64
	Rank        int64
	AwardStatus []int64
}
type ClaimResult struct {
	AwardStatus []int64    `json:"award_status"`
	Awards      []i5.Award `json:"awards"`
	Level       int64      `json:"level"`
	Items       [][2]int64 `json:"items"`
}

func Profile() tx.Profile {
	return tx.Profile{Name: "achievement", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 20 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 30 * time.Second}
}
func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

// unresolved leaves an uncertain observation commit unknown; observations are
// idempotent high-water writes, so the next observation reconciles them.
type unresolved struct{}

func (unresolved) ResolveTimed(context.Context, gen.TimedResolutionRequest) (tx.Resolution, error) {
	return tx.Resolution{State: tx.ResolutionUnknown}, nil
}

type receiptProof struct{ receipt.Resolver }

func (p receiptProof) ResolveTimed(c context.Context, r gen.TimedResolutionRequest) (tx.Resolution, error) {
	return p.Resolve(c, tx.ResolutionRequest{Operation: r.Operation.Operation(), CommitError: r.CommitError, Attempt: r.Attempt})
}

// child binds a separate semantic operation to the active content revision so
// the observation never reinterprets the caller's command operation.
func (s Service) child(c context.Context, parent operation.Context, label string) (operation.Context, string, error) {
	rev, e := s.Runtime.Active.ActiveRevision(c, s.Runtime.Fresh)
	if e != nil {
		return operation.Context{}, "", e
	}
	id, e := ids.NewUUID()
	if e != nil {
		return operation.Context{}, "", e
	}
	refs, e := policy.NewSet(policy.Ref{Name: "content", Version: rev}, policy.Ref{Name: "achievement", Version: CatalogPolicy})
	return operation.Context{ID: id, StartedAt: parent.StartedAt, EntropySeed: parent.Derive("achievement-"+label, 0), Policies: refs}, rev, e
}

// Observe is C4F_OBSERVE_AFTER_COMMAND_V1: its own Serializable transaction
// after the owner's command committed. Failure never alters that command.
func (s Service) Observe(c context.Context, a identity.ActorContext, parent operation.Context, families []int64) error {
	if !s.Runtime.ready() || s.Store == nil || s.Content == nil || s.Population == nil || !a.PlayerID.Valid() {
		return d.ErrUnavailable
	}
	op, rev, e := s.child(c, parent, "observe")
	if e != nil {
		return e
	}
	_, _, e = s.Runtime.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.Serializable}, retry(), unresolved{}, func(c context.Context, sc gen.TimedScope) error {
		_, e := s.observeOwnedTx(c, sc, rev, a.PlayerID, families)
		return e
	})
	return e
}

// Load is 1302: observe every owned-state family, then read in the same snapshot.
func (s Service) Load(c context.Context, a identity.ActorContext, parent operation.Context) (View, error) {
	var out View
	if !s.Runtime.ready() || s.Store == nil || s.Content == nil || s.Population == nil || !a.PlayerID.Valid() {
		return out, d.ErrUnavailable
	}
	op, rev, e := s.child(c, parent, "load")
	if e != nil {
		return out, e
	}
	_, _, e = s.Runtime.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.Serializable}, retry(), unresolved{}, func(c context.Context, sc gen.TimedScope) error {
		catalog, e := s.observeOwnedTx(c, sc, rev, a.PlayerID, allFamilies())
		if e != nil {
			return e
		}
		out, e = s.viewTx(c, sc.Tx, catalog, a.PlayerID)
		return e
	})
	return out, e
}

func (s Service) observeOwnedTx(c context.Context, sc gen.TimedScope, rev string, p identity.PlayerID, families []int64) (d.Catalog, error) {
	at := sc.Operation.DecisionAt()
	catalog, e := s.Content.AchievementCatalogTx(c, sc.Tx, rev)
	if e != nil {
		return catalog, e
	}
	if len(catalog.Levels) == 0 {
		return catalog, d.ErrUnavailable
	}
	root, tracked, e := s.Store.ReadRootTx(c, sc.Tx, p, true)
	if e != nil {
		return catalog, e
	}
	// C4F_LEGACY_STATE_BACKFILL_V1: a legacy character gets its root now.
	if !tracked {
		if e = s.Store.InitFreshTx(c, sc.Tx, p, rev, at); e != nil {
			return catalog, e
		}
		if root, _, e = s.Store.ReadRootTx(c, sc.Tx, p, true); e != nil {
			return catalog, e
		}
	}
	if root.UpdatedAt.After(at) {
		return catalog, d.ErrConflict
	}
	scope, e := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, rev, at)
	if e != nil {
		return catalog, e
	}
	if e = s.observeMarriedTx(c, sc.Tx, catalog, root, rev, families, at); e != nil {
		return catalog, e
	}
	counts := s.Runtime.Counts.OwnedStateCountsTx(c, scope, p, families)
	achievementIDs := make([]int64, 0, len(counts))
	for id := range counts {
		achievementIDs = append(achievementIDs, id)
	}
	sort.Slice(achievementIDs, func(i, j int) bool { return achievementIDs[i] < achievementIDs[j] })
	for _, id := range achievementIDs {
		count := counts[id]
		e = s.observePlayerTx(c, sc.Tx, id, p, rev, at, func(current d.Streak) (d.Streak, bool, error) {
			return current.ObserveCount(catalog, count, at)
		})
		if e != nil {
			return catalog, e
		}
	}
	return catalog, nil
}

// observeMarriedTx evaluates 100014 from current state for backfilled roots.
func (s Service) observeMarriedTx(c context.Context, t tx.Tx, catalog d.Catalog, root d.Root, rev string, families []int64, at time.Time) error {
	wanted := false
	for _, id := range families {
		wanted = wanted || id == d.SelectedID
	}
	if !wanted {
		return nil
	}
	married, e := s.Population.MarriedHeroCountTx(c, t, lib.InputScope{Player: root.PlayerID, ContentRevision: rev, ObservedAt: at})
	if e != nil || married.MarriedCount < 1 {
		return nil
	}
	next, changed, e := root.ObservePopulation(catalog, married.MarriedCount, at)
	if e != nil || !changed {
		return e
	}
	if e = s.Store.SaveRootTx(c, t, next, root.StateVersion); e != nil {
		return e
	}
	return s.Store.PutNoticesTx(c, t, newTiers(root.PlayerID, d.SelectedID, root.CompleteTimes, next.CompleteTimes))
}

func newTiers(p identity.PlayerID, id int64, before, after [3]*time.Time) []Notice {
	out := []Notice{}
	for i := range after {
		if before[i] == nil && after[i] != nil {
			out = append(out, Notice{Player: p, AchievementID: id, Tier: i + 1, CompleteTime: *after[i]})
		}
	}
	return out
}

func (s Service) earnedTx(c context.Context, q tx.Queryer, p identity.PlayerID) (d.Root, []d.Streak, d.Tiers, error) {
	root, tracked, e := s.Store.ReadRootTx(c, q, p, false)
	if e != nil {
		return root, nil, nil, e
	}
	if !tracked {
		return root, nil, nil, d.ErrUnavailable
	}
	streaks, e := s.Store.ReadStreaksTx(c, q, p)
	if e != nil {
		return root, nil, nil, e
	}
	earned := d.Tiers{d.SelectedID: root.CompleteTimes}
	for _, streak := range streaks {
		earned[streak.AchievementID] = streak.CompleteTimes
	}
	return root, streaks, earned, nil
}

func (s Service) viewTx(c context.Context, q tx.Queryer, catalog d.Catalog, p identity.PlayerID) (View, error) {
	var out View
	root, streaks, earned, e := s.earnedTx(c, q, p)
	if e != nil {
		return out, e
	}
	progress := map[int64]int64{d.SelectedID: root.Progress}
	for _, streak := range streaks {
		progress[streak.AchievementID] = streak.Current
	}
	for _, row := range catalog.Rows {
		entry := Entry{AchievementID: row.ID, Status: d.StatusOf(row.ID), Progress: progress[row.ID]}
		for i, at := range earned[row.ID] {
			if at != nil {
				entry.CompleteTimes[i] = at.Unix()
			}
		}
		out.Entries = append(out.Entries, entry)
	}
	claimed, e := s.Store.ReadClaimsTx(c, q, p)
	if e != nil {
		return out, e
	}
	out.TotalPoints, _ = catalog.Points(earned)
	out.PointLevel = catalog.PointLevel(out.TotalPoints)
	out.AwardStatus = catalog.AwardStatus(out.TotalPoints, claimed)
	out.Rank, e = s.Store.TrophyRankTx(c, q, p, catalog)
	return out, e
}

// Claim is 1303 (C4F_POINT_LEVEL_AWARDS_V1): the lowest reached unclaimed level
// with items, granted once through I5 and replayed from its receipt.
func (s Service) Claim(c context.Context, a identity.ActorContext, op operation.Context) (ClaimResult, error) {
	var out ClaimResult
	if !s.Runtime.ready() || s.Store == nil || s.Content == nil || !a.PlayerID.Valid() || op.ID.IsZero() {
		return out, d.ErrUnavailable
	}
	if _, pinned := op.Policies.Get("content"); !pinned {
		rev, e := s.Runtime.Active.ActiveRevision(c, s.Runtime.Fresh)
		if e != nil {
			return out, e
		}
		if op.Policies, e = policy.NewSet(append(op.Policies.Refs(), policy.Ref{Name: "content", Version: rev})...); e != nil {
			return out, e
		}
	}
	rev, _ := op.Policies.Get("content")
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "achievement", Operation: "CLAIM", SemanticKey: op.ID.String()}
	fp, e := receipt.FingerprintRequest(struct{ Player identity.PlayerID }{a.PlayerID})
	if e != nil {
		return out, e
	}
	_, res, e := s.Runtime.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.Serializable}, retry(), receiptProof{receipt.Resolver{Reader: s.Runtime.ReceiptRead, Identity: id, Fingerprint: fp}}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if e := s.Runtime.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		if r, found, e := s.Runtime.Receipts.FindTx(c, sc.Tx, id); e != nil || found {
			if e == nil && r.RequestFingerprint != fp {
				e = d.ErrConflict
			}
			if e != nil {
				return e
			}
			return json.Unmarshal(r.ResultPayload, &out)
		}
		catalog, e := s.Content.AchievementCatalogTx(c, sc.Tx, rev)
		if e != nil {
			return e
		}
		if len(catalog.Levels) == 0 {
			return d.ErrUnavailable
		}
		if _, _, e = s.Store.ReadRootTx(c, sc.Tx, a.PlayerID, true); e != nil {
			return e
		}
		_, _, earned, e := s.earnedTx(c, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		claimed, e := s.Store.ReadClaimsTx(c, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		total, _ := catalog.Points(earned)
		level, ok := catalog.NextClaim(total, claimed)
		if !ok {
			return ErrNothingToClaim
		}
		lines := []grant.Line{}
		for _, item := range level.Items {
			lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: item[0], Amount: item[1]})
		}
		plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "achievement", Operation: "point-level-award", BusinessKey: strconv.FormatInt(int64(a.PlayerID), 10), Occurrence: strconv.FormatInt(level.ID, 10), PolicyVersion: CatalogPolicy}, Lines: lines}
		granted, e := s.Runtime.Grants.SettleGrantTx(c, sc.Tx, a, plan, sc.Operation.Operation(), i5.GrantTxOptions{AllowOverflowMail: true})
		if e != nil {
			return e
		}
		if e = s.Store.PutClaimTx(c, sc.Tx, a.PlayerID, level.ID, rev, op.ID, total, at); e != nil {
			return e
		}
		claimed[level.ID] = true
		out = ClaimResult{AwardStatus: catalog.AwardStatus(total, claimed), Awards: []i5.Award{}, Level: level.ID, Items: level.Items}
		for _, award := range granted.Awards {
			if award.TableID > 0 && award.ItemNum > 0 {
				out.Awards = append(out.Awards, award)
			}
		}
		raw, e := json.Marshal(out)
		if e != nil {
			return e
		}
		r, e := receipt.New(sc.Operation.Operation(), id, "I7C4FA_ACHIEVEMENT", "gxb.achievement.claim.v1", raw, fp)
		if e != nil {
			return e
		}
		r.PolicyVersion = CatalogPolicy
		r.ActorAccountUID = string(a.AccountUID)
		r.ContextID = a.ContextID.UUID()
		_, e = s.Runtime.Receipts.PutTx(c, sc.Tx, r)
		return e
	})
	if e != nil {
		return ClaimResult{}, e
	}
	if res.Reconciled {
		r, found, e := s.Runtime.ReceiptRead.Find(c, id)
		if e != nil || !found {
			return ClaimResult{}, errors.Join(e, d.ErrConflict)
		}
		return out, json.Unmarshal(r.ResultPayload, &out)
	}
	return out, nil
}

var ErrNothingToClaim = errors.New("achievement: no claimable point level")
