package publicprofile

import (
	"bytes"
	"context"
	"encoding/json"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
	"strconv"
	"time"
)

type ShowcaseResult struct {
	EntropySeed [32]byte  `json:"entropy_seed"`
	Schema      string    `json:"schema"`
	PlayerID    int64     `json:"player_id"`
	Server      int32     `json:"server"`
	Account     string    `json:"account"`
	Context     string    `json:"context"`
	Revision    string    `json:"revision"`
	DecisionAt  time.Time `json:"decision_at"`
	RootVersion int64     `json:"root_version"`
	Changed     bool      `json:"changed"`
	Selection   Selection `json:"selection"`
}

// Internal outcome only. It is never a stock1832 success receipt or a full wire DTO.
type ShowcaseAssignmentService struct {
	Timed       gen.TimedRunner
	Reads       tx.Runner
	Fresh       tx.Queryer
	Roots       RootService
	Players     playerroot.TxLocker
	Fence       ActorFencer
	Receipts    receipt.Store
	Content     ShowcaseContentReader
	Slots       ShowcaseStore
	References  ShowcaseReferences
	Bases       ShowcaseBases
	BeforeWrite func(context.Context, gen.TimedScope, Selection, string, time.Time) error
}

func showcaseIdentity(a identity.ActorContext, q Selection, o operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "public-profile", Operation: "showcase-internal", SemanticKey: o.ID.String()}
}
func bindShowcasePolicy(o operation.Context, p ShowcaseContentPolicy) (operation.Context, error) {
	refs := o.Policies.Refs()
	for _, r := range []policy.Ref{{Name: "content", Version: p.Revision}, {Name: "showcase", Version: p.Policy.PolicyID}} {
		if v, ok := o.Policies.Get(r.Name); ok {
			if v != r.Version {
				return o, ErrConflict
			}
		} else {
			refs = append(refs, r)
		}
	}
	s, e := policy.NewSet(refs...)
	o.Policies = s
	return o, e
}
func (s ShowcaseAssignmentService) proof(c context.Context, t tx.Queryer, a identity.ActorContext, q Selection, o operation.Context) (ShowcaseResult, bool, error) {
	rr, ok, e := s.Receipts.FindTx(c, t, showcaseIdentity(a, q, o))
	if e != nil || !ok {
		return ShowcaseResult{}, ok, e
	}
	fp, e := receipt.FingerprintRequest(q)
	if e != nil {
		return ShowcaseResult{}, true, e
	}
	if rr.Validate() != nil || rr.Identity != showcaseIdentity(a, q, o) || rr.OperationClass != "I7B3A_SHOWCASE_INTERNAL_ASSIGNMENT" || rr.ResultSchema != "gxb.public-profile.showcase-internal.v1" || rr.ActorAccountUID != string(a.AccountUID) || rr.ContextID != a.ContextID.UUID() || rr.OperationStartedAt.UnixMicro() != o.StartedAt.UnixMicro() || rr.RequestFingerprint != fp || rr.PolicyVersion != ShowcasePolicyID {
		return ShowcaseResult{}, true, ErrConflict
	}
	for _, ref := range o.Policies.Refs() {
		v, yes := rr.OperationPolicyRefs.Get(ref.Name)
		if !yes || v != ref.Version {
			return ShowcaseResult{}, true, ErrConflict
		}
	}
	var r ShowcaseResult
	d := json.NewDecoder(bytes.NewReader(rr.ResultPayload))
	d.DisallowUnknownFields()
	if d.Decode(&r) != nil {
		return r, true, ErrConflict
	}
	var extra any
	if d.Decode(&extra) != io.EOF {
		return r, true, ErrConflict
	}
	rev, yes := rr.OperationPolicyRefs.Get("content")
	if !yes || rev != r.Revision {
		return r, true, ErrConflict
	}
	p, e := s.Content.ReadPublicShowcasePolicy(c, t, rev)
	if e != nil || p.Validate() != nil || p.Revision != rev {
		return r, true, ErrContent
	}
	if v, yes := rr.OperationPolicyRefs.Get("showcase"); !yes || v != p.Policy.PolicyID {
		return r, true, ErrConflict
	}
	current, present, e := s.Roots.Store.ReadRootTx(c, t, a.PlayerID)
	if e != nil {
		return r, true, e
	}
	if present && (current.Validate() != nil || current.PlayerID != a.PlayerID) {
		return r, true, ErrConflict
	}
	if r.RootVersion > 0 && (!present || current.StateVersion < r.RootVersion || current.CreatedAt.After(r.DecisionAt)) {
		return r, true, ErrConflict
	}
	if r.EntropySeed != o.EntropySeed || r.Schema != rr.ResultSchema || r.PlayerID != int64(a.PlayerID) || r.Server != int32(a.LogicalServerID) || r.Account != string(a.AccountUID) || r.Context != a.ContextID.UUID().String() || r.RootVersion < 0 || r.DecisionAt.IsZero() || r.DecisionAt.After(rr.RecordedAt) || r.Selection != q || r.Selection.Validate() != nil || (r.Changed && r.RootVersion < 1) || (r.RootVersion == 0 && r.Selection != (Selection{})) {
		return r, true, ErrConflict
	}
	return r, true, nil
}

// Reconciliation re-reads retained policy + typed outcome on the authoritative
// writer. Receipt absence is UNKNOWN, never authorization to re-execute.
type showcaseResolver struct {
	s ShowcaseAssignmentService
	a identity.ActorContext
	q Selection
	o operation.Context
}

func (r showcaseResolver) ResolveTimed(c context.Context, sc gen.TimedResolutionRequest) (tx.Resolution, error) {
	var out ShowcaseResult
	var found bool
	res, e := r.s.Reads.Run(c, r.o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, t tx.Scope) error {
		if e := r.s.Fence.FenceActorTx(c, t.Tx, r.a, sc.Operation.DecisionAt()); e != nil {
			return e
		}
		var e error
		out, found, e = r.s.proof(c, t.Tx, r.a, r.q, r.o)
		return e
	})
	if e != nil || res.Outcome != tx.DefiniteCommit {
		return tx.Resolution{}, e
	}
	if !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: out}, nil
}
func (s ShowcaseAssignmentService) Execute(c context.Context, a identity.ActorContext, q Selection, o operation.Context) (ShowcaseResult, error) {
	if e := q.Validate(); e != nil {
		return ShowcaseResult{}, e
	}
	var e error
	if s.Timed.Binder.Time == nil || s.Timed.Runner.DB == nil || s.Reads.DB == nil || s.Fresh == nil || s.Roots.Store == nil || s.Players == nil || s.Fence == nil || s.Receipts == nil || s.Content == nil || s.Slots == nil || s.References == nil || s.Bases == nil || !a.PlayerID.Valid() || !a.LogicalServerID.Valid() || !a.AccountUID.Valid() || a.ContextID.UUID().IsZero() || o.ID.IsZero() || o.StartedAt.IsZero() {
		return ShowcaseResult{}, ErrCommand
	}
	// Known attempt is checked before consulting current active policy. Authentication
	// is re-fenced in the caller transaction; historical replay cannot bypass revocation.
	var replay ShowcaseResult
	var found bool
	rr, e := s.Reads.Run(c, o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, t tx.Scope) error {
		var e error
		replay, found, e = s.proof(c, t.Tx, a, q, o)
		if e != nil || !found {
			return e
		}
		at, e := s.Timed.Binder.Time.Now(c)
		if e != nil {
			return e
		}
		return s.Fence.FenceActorTx(c, t.Tx, a, at)
	})
	if e != nil {
		return ShowcaseResult{}, e
	}
	if found {
		if rr.Outcome != tx.DefiniteCommit {
			return ShowcaseResult{}, ErrConflict
		}
		return replay, nil
	}
	rev, e := s.Content.ActiveRevision(c, s.Fresh)
	if e != nil {
		return ShowcaseResult{}, ErrContent
	}
	p, e := s.Content.ReadPublicShowcasePolicy(c, s.Fresh, rev)
	if e != nil || p.Validate() != nil || p.Revision != rev {
		return ShowcaseResult{}, ErrContent
	}
	bound, e := bindShowcasePolicy(o, p)
	if e != nil {
		return ShowcaseResult{}, e
	}
	keys, e := selectionKeys(a.PlayerID, q, s.References)
	if e != nil {
		return ShowcaseResult{}, e
	}

	var out ShowcaseResult
	_, res, e := s.Timed.Run(c, bound, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, showcaseResolver{s, a, q, bound}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if e := s.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		prior, ok, e := s.proof(c, sc.Tx, a, q, bound)
		if e != nil {
			return e
		}
		if ok {
			out = prior
			return nil
		}
		roots, e := s.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID})
		if e != nil || len(roots) != 1 {
			return ErrCommand
		}
		cp, e := s.Content.ReadPublicShowcasePolicy(c, sc.Tx, rev)
		if e != nil || cp.Validate() != nil || cp.Revision != rev {
			return ErrContent
		}
		prep, e := s.Roots.PrepareRootTx(c, sc.Tx, roots[0])
		if e != nil {
			return e
		}
		if e = lockSelection(c, sc.Tx, a.PlayerID, keys, s.References); e != nil {
			return e
		}
		if e = validateSelectionRefs(c, sc.Tx, a.PlayerID, q, s.Bases); e != nil {
			return e
		}
		// This optional consumer boundary runs before the first root/slot write.
		// Missing or unqualified rich builders must fail closed at that boundary.
		if s.BeforeWrite != nil {
			if e = s.BeforeWrite(c, sc, q, rev, at); e != nil {
				return e
			}
		}
		old, e := s.Slots.ReadSelectionTx(c, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		root, present := prep.Existing()
		if !present && old != (Selection{}) {
			return ErrInvalidState
		}
		changed := old != q
		if changed {
			root, e = s.Roots.TouchForChildChangeTx(c, sc.Tx, prep, at)
			if e != nil {
				return e
			}
			if e = s.Slots.ReplaceSelectionTx(c, sc.Tx, a.PlayerID, q); e != nil {
				return e
			}
		}
		result := ShowcaseResult{EntropySeed: bound.EntropySeed, Schema: "gxb.public-profile.showcase-internal.v1", PlayerID: int64(a.PlayerID), Server: int32(a.LogicalServerID), Account: string(a.AccountUID), Context: a.ContextID.UUID().String(), Revision: rev, DecisionAt: at, RootVersion: root.StateVersion, Selection: q, Changed: changed}

		payload, e := json.Marshal(result)
		if e != nil {
			return e
		}
		fp, e := receipt.FingerprintRequest(q)
		if e != nil {
			return e
		}
		r, e := receipt.New(bound, showcaseIdentity(a, q, bound), "I7B3A_SHOWCASE_INTERNAL_ASSIGNMENT", result.Schema, payload, fp)
		if e != nil {
			return e
		}
		r.PolicyVersion = ShowcasePolicyID
		r.ActorAccountUID = string(a.AccountUID)
		r.ContextID = a.ContextID.UUID()
		r.RecordedAt = at
		put, e := s.Receipts.PutTx(c, sc.Tx, r)
		if e != nil {
			return e
		}
		if !put.Inserted {
			return ErrConflict
		}
		out = result
		return nil
	})
	if e != nil {
		return ShowcaseResult{}, e
	}
	if res.Reconciled && res.Outcome == tx.DefiniteCommit {
		got, ok := res.Evidence.(ShowcaseResult)
		if !ok {
			return ShowcaseResult{}, ErrConflict
		}
		return got, nil
	}
	if res.Outcome != tx.DefiniteCommit {
		return ShowcaseResult{}, ErrConflict
	}
	return out, nil
}
