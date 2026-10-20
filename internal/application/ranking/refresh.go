package ranking

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"strconv"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrUnavailable = errors.New("ranking: unavailable provider or unqualified history")
var ErrConflict = errors.New("ranking: conflicting scope or immutable proof")

// boardReceipt keeps each board's receipt names stable so stored receipts replay.
type boardReceipt struct{ metricPin, refreshClass, settlementClass string }

var boardReceipts = map[string]boardReceipt{
	d.GirlsPolicy:            {metricPin: "roster-metrics", refreshClass: "I7C4C_GIRLS_RANKING_REFRESH", settlementClass: "I7C4C_GIRLS_RANKING_WEEKLY_TITLES"},
	d.AchievementPointPolicy: {metricPin: "force-metric", refreshClass: "I7C4FA_AP_RANKING_REFRESH", settlementClass: "I7C4FA_AP_RANKING_WEEKLY_TITLES"},
}

func refreshSchema(b d.Board) string { return "gxb.ranking." + b.Name + "-refresh.v1" }

func Profile() tx.Profile {
	return tx.Profile{Name: "I7C4C_GIRLS_RANKING", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 20 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 30 * time.Second}
}
func (s Service) complete() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Fresh != nil && s.Store != nil && s.Cohort != nil && s.Directory != nil && s.Metrics != nil && s.Content != nil && s.Fence != nil && s.Receipts != nil && s.ReceiptRead != nil
}
func refreshIdentity(b d.Board, a identity.ActorContext, o operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "ranking", Operation: b.Name + "-refresh", SemanticKey: o.ID.String()}
}
func refreshFingerprint(b d.Board, a identity.ActorContext) ([32]byte, error) {
	return receipt.FingerprintRequest(map[string]any{"player": int64(a.PlayerID), "server": int64(a.LogicalServerID), "subtype": b.SubType, "policy": b.Policy})
}
func bind(o operation.Context, name, value string) (operation.Context, error) {
	if got, ok := o.Policies.Get(name); ok {
		if got != value {
			return o, ErrConflict
		}
		return o, nil
	}
	refs := append(o.Policies.Refs(), policy.Ref{Name: name, Version: value})
	var e error
	o.Policies, e = policy.NewSet(refs...)
	return o, e
}
func (s Service) bindRefresh(c context.Context, b d.Board, o operation.Context) (operation.Context, string, error) {
	rev, ok := o.Policies.Get("content")
	var e error
	if !ok {
		rev, e = s.Content.ActiveRevision(c, s.Fresh)
		if e != nil {
			return o, "", e
		}
	}
	o, e = bind(o, "content", rev)
	if e != nil {
		return o, "", e
	}
	o, e = bind(o, boardReceipts[b.Policy].metricPin, b.SourcePolicy)
	if e != nil {
		return o, "", e
	}
	o, e = bind(o, "ranking", b.Policy)
	return o, rev, e
}

// Actor identity wrappers keep UUIDs private. Durable evidence uses explicit
// UUID/scalar fields, as in the existing PlayerDisplay receipt encoding.
type refreshActor struct {
	AccountID, SessionID, ContextID                   ids.UUID
	AccountUID                                        string
	PlayerID                                          identity.PlayerID
	ServerID                                          identity.LogicalServerID
	ContextGeneration, SessionVersion, ContextVersion int64
}

func actorBinding(a identity.ActorContext) refreshActor {
	return refreshActor{AccountID: a.AccountID.UUID(), SessionID: a.SessionID.UUID(), ContextID: a.ContextID.UUID(), AccountUID: string(a.AccountUID), PlayerID: a.PlayerID, ServerID: a.LogicalServerID, ContextGeneration: a.ContextGeneration, SessionVersion: a.SessionLivenessVersion, ContextVersion: a.ContextLivenessVersion}
}

type refreshRecord struct {
	Actor     refreshActor
	Operation operation.Context
	Snapshot  d.BoardSnapshot
}

func strictDecode(raw []byte, out any) error {
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.DisallowUnknownFields()
	if e := dec.Decode(out); e != nil {
		return e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return ErrConflict
	}
	return nil
}
func (s Service) decodeRefresh(c context.Context, q tx.Queryer, b d.Board, r receipt.Receipt, a identity.ActorContext, o operation.Context, fp [32]byte) (d.BoardSnapshot, error) {
	var out refreshRecord
	if r.Validate() != nil || r.Identity != refreshIdentity(b, a, o) || r.RequestFingerprint != fp || r.OperationClass != boardReceipts[b.Policy].refreshClass || r.ResultSchema != refreshSchema(b) || r.PolicyVersion != b.Policy || r.ActorAccountUID != string(a.AccountUID) || r.ContextID != a.ContextID.UUID() || r.OperationStartedAt.UnixMicro() != o.StartedAt.UnixMicro() || strictDecode(r.ResultPayload, &out) != nil {
		return d.BoardSnapshot{}, ErrConflict
	}
	if out.Actor != actorBinding(a) || out.Operation.ID != o.ID || !out.Operation.StartedAt.Equal(o.StartedAt) || out.Operation.EntropySeed != o.EntropySeed || !out.Operation.Policies.Equal(r.OperationPolicyRefs) || out.Snapshot.Validate() != nil || out.Snapshot.Policy != b.Policy || out.Snapshot.Server != a.LogicalServerID || out.Snapshot.OperationID != o.ID {
		return d.BoardSnapshot{}, ErrConflict
	}
	for _, x := range o.Policies.Refs() {
		v, ok := r.OperationPolicyRefs.Get(x.Name)
		if !ok || v != x.Version {
			return d.BoardSnapshot{}, ErrConflict
		}
	}
	for k, want := range map[string]string{"ranking": b.Policy, boardReceipts[b.Policy].metricPin: b.SourcePolicy, "content": out.Snapshot.Revision} {
		got, ok := r.OperationPolicyRefs.Get(k)
		if !ok || got != want {
			return d.BoardSnapshot{}, ErrConflict
		}
	}
	stored, ok, e := s.Store.FindBoardSnapshotByOperationTx(c, q, o.ID)
	if e != nil {
		return d.BoardSnapshot{}, e
	}
	if !ok || stored.Policy != b.Policy || stored.Digest != out.Snapshot.Digest || stored.Server != out.Snapshot.Server || stored.Generation != out.Snapshot.Generation {
		return d.BoardSnapshot{}, ErrConflict
	}
	return out.Snapshot, nil
}

// The generic Kernel resolver uses its immutable receipt identity/fingerprint;
// it intentionally treats absence as unresolved. TimedRunner keeps one bound
// decision instant through retries and this positive-proof reconciliation.
type timedReceiptResolver struct{ receipt.Resolver }

func (r timedReceiptResolver) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolver.Resolve(c, tx.ResolutionRequest{})
}
func (s Service) RefreshBoard(c context.Context, b d.Board, a identity.ActorContext, o operation.Context) (d.BoardSnapshot, error) {
	var out d.BoardSnapshot
	if _, known := boardReceipts[b.Policy]; !known || !s.complete() || !a.PlayerID.Valid() || !a.LogicalServerID.Valid() || !a.AccountUID.Valid() || a.ContextID.UUID().IsZero() || o.ID.IsZero() || o.StartedAt.IsZero() {
		return out, ErrUnavailable
	}
	id := refreshIdentity(b, a, o)
	fp, e := refreshFingerprint(b, a)
	if e != nil {
		return out, e
	}
	// A historic replay pins its original content before any current discovery.
	prior, has, e := s.Receipts.FindTx(c, s.Fresh, id)
	if e != nil {
		return out, e
	}
	bound := o
	rev := ""
	if has {
		old, e := s.decodeRefresh(c, s.Fresh, b, prior, a, o, fp)
		if e != nil {
			return out, e
		}
		rev = old.Revision
		bound.Policies = prior.OperationPolicyRefs
	} else {
		bound, rev, e = s.bindRefresh(c, b, o)
		if e != nil {
			return out, e
		}
	}
	_, res, e := s.Timed.Run(c, bound, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}, timedReceiptResolver{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if e := s.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		prior, ok, e := s.Receipts.FindTx(c, sc.Tx, id)
		if e != nil {
			return e
		}
		if ok {
			out, e = s.decodeRefresh(c, sc.Tx, b, prior, a, o, fp)
			return e
		}
		catalog, e := s.Content.ReadPlayerDisplayCatalogTx(c, sc.Tx, rev)
		if e != nil {
			return e
		}
		if catalog.Validate() != nil {
			return ErrConflict
		}
		for _, title := range b.Titles {
			v, ok := catalog.Find("title", title)
			if !ok || v.Type != b.TitleType || v.Days != d.BoardTitleDuration {
				return ErrConflict
			}
		}
		root, e := s.Store.LockBoardRootTx(c, sc.Tx, b, a.LogicalServerID, at)
		if e != nil {
			return e
		}
		if at.Before(root.UpdatedAt) {
			return d.ErrStale
		}
		roots, e := s.Cohort.ListPlayerRootsTx(c, sc.Tx)
		if e != nil {
			return e
		}
		seen := map[identity.PlayerID]bool{}
		actorPresent := false
		inputs := []d.BoardInput{}
		scope := tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}
		// Build/validate the same CA8 witness that is handed to the metric owner.
		if _, e = ca.NewCoherentReadScope(scope, rev, at); e != nil {
			return e
		}
		for _, r := range roots {
			if r.Validate() != nil || seen[r.PlayerID] {
				return ErrConflict
			}
			seen[r.PlayerID] = true
			if r.LogicalServerID != a.LogicalServerID {
				continue
			}
			if r.PlayerID == a.PlayerID {
				actorPresent = true
			}
			ms, e := s.Metrics.ReadMetricsScopeTx(c, scope, publicprofile.MetricRequest{PlayerID: r.PlayerID, IDs: []int64{b.FieldID}, ContentRevision: rev, ObservedAt: at})
			if e != nil {
				return e
			}
			if len(ms) != 1 {
				return ErrUnavailable
			}
			m := ms[0]
			p, ok, e := s.Directory.ProfileTx(c, sc.Tx, r.PlayerID)
			if e != nil {
				return e
			}
			if !ok || p.Validate() != nil || p.PlayerID != r.PlayerID {
				return ErrUnavailable
			}
			inputs = append(inputs, d.BoardInput{Metric: d.BoardMetric{Player: m.PlayerID, Owner: m.Owner, Policy: m.PrivatePolicy, Semantics: m.Semantics, Revision: m.ContentRevision, PopulationDigest: m.PopulationDigest, FieldID: m.FieldID, Value: m.Value, SourceVersion: m.SourceVersion, PopulationVersion: m.PopulationVersion, ObservedAt: m.ObservedAt}, Display: d.BoardPresentation{Player: p.PlayerID, Name: p.Name, Level: p.Level, AvatarID: p.AvatarID, FrameID: p.AvatarFrameID, ConquerLevel: p.ConquerLevel, ConquerLoopID: p.ConquerLoopID}})
		}
		if !actorPresent {
			return ErrConflict
		}
		next, snapshot, e := d.BuildBoardSnapshot(root, at, rev, bound.ID, inputs)
		if e != nil {
			return e
		}
		if e = s.Store.InsertBoardSnapshotTx(c, sc.Tx, snapshot); e != nil {
			return e
		}
		if e = s.Store.BindBoardPeriodTx(c, sc.Tx, snapshot); e != nil {
			return e
		}
		if e = s.Store.SaveBoardRootTx(c, sc.Tx, next, root.StateVersion); e != nil {
			return e
		}
		raw, e := json.Marshal(refreshRecord{Actor: actorBinding(a), Operation: bound, Snapshot: snapshot})
		if e != nil {
			return e
		}
		rr, e := receipt.New(bound, id, boardReceipts[b.Policy].refreshClass, refreshSchema(b), raw, fp)
		if e != nil {
			return e
		}
		rr.ActorAccountUID = string(a.AccountUID)
		rr.ContextID = a.ContextID.UUID()
		rr.PolicyVersion = b.Policy
		if _, e = s.Receipts.PutTx(c, sc.Tx, rr); e != nil {
			return e
		}
		out = snapshot
		return nil
	})
	if e != nil {
		return d.BoardSnapshot{}, e
	}
	if res.Reconciled {
		r, ok := res.Evidence.(receipt.Receipt)
		if !ok {
			return d.BoardSnapshot{}, ErrConflict
		}
		return s.decodeRefresh(c, s.Fresh, b, r, a, o, fp)
	}
	if res.Outcome != tx.DefiniteCommit {
		return d.BoardSnapshot{}, ErrUnavailable
	}
	return out, nil
}
