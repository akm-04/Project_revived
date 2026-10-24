package profilefeedback

import (
	"bytes"
	"context"
	"encoding/json"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/profilefeedback"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
	"strconv"
	"time"
)

const resultSchema = "gxb.profile-feedback.praise.v1"
const operationClass = "I7B4A_PROFILE_PRAISE"

type Command struct {
	Target identity.PlayerID `json:"to_player_id"`
}

func (q Command) Validate(a identity.ActorContext) error {
	if !q.Target.Valid() || int64(q.Target) > 9007199254740991 || q.Target == a.PlayerID {
		return ErrRequest
	}
	if _, e := socialrelation.CanonicalServer(q.Target); e != nil {
		return ErrRequest
	}
	return nil
}

type Terminal struct {
	Schema      string                   `json:"schema"`
	Actor       identity.PlayerID        `json:"actor"`
	Target      identity.PlayerID        `json:"target"`
	Server      identity.LogicalServerID `json:"server"`
	Account     string                   `json:"account"`
	Context     string                   `json:"context"`
	EntropySeed [32]byte                 `json:"entropy_seed"`
	Revision    string                   `json:"revision"`
	DecisionAt  time.Time                `json:"decision_at"`
	FirstAt     time.Time                `json:"first_at"`
	FactVersion int64                    `json:"fact_version"`
	RootVersion int64                    `json:"root_version"`
	Inserted    bool                     `json:"inserted"`
}
type CommandResult struct {
	Terminal Terminal
	Current  d.Observation
}

func (r CommandResult) Wire() map[string]any {
	bit := int64(0)
	if r.Current.HasPraised {
		bit = 1
	}
	return map[string]any{"praise_num": r.Current.Count, "is_has_praise": bit}
}

type Service struct {
	Timed      gen.TimedRunner
	Reads      tx.Runner
	Fresh      tx.Queryer
	Roots      RootService
	Basic      publicprofile.BasicReader
	Content    publicprofile.ContentReader
	Receipts   receipt.Store
	Recipients playerroot.RecipientReader
	Authors    i5.PublicPlayerBasisReader
	Display    i5.TxEffectivePlayerDisplayReader
}

func receiptIdentity(a identity.ActorContext, o operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "profile-feedback", Operation: "praise", SemanticKey: o.ID.String()}
}
func bind(o operation.Context, p publicprofile.ContentPolicy) (operation.Context, error) {
	refs := o.Policies.Refs()
	for _, r := range []policy.Ref{{Name: "content", Version: p.Revision}, {Name: "profile", Version: p.Policy.PolicyID}, {Name: "profile-moderation", Version: p.Policy.ModerationPolicyID}, {Name: "profile-praise", Version: d.PolicyVersion}} {
		if v, ok := o.Policies.Get(r.Name); ok {
			if v != r.Version {
				return o, ErrConflict
			}
		} else {
			refs = append(refs, r)
		}
	}
	ps, e := policy.NewSet(refs...)
	o.Policies = ps
	return o, e
}
func (s Service) valid(a identity.ActorContext, o operation.Context) bool {
	return s.Timed.Binder.Time != nil && s.Timed.Runner.DB != nil && s.Reads.DB != nil && s.Fresh != nil && s.Roots.Store != nil && s.Basic.Fence != nil && s.Content != nil && s.Receipts != nil && a.PlayerID.Valid() && a.LogicalServerID.Valid() && a.AccountUID.Valid() && !a.ContextID.UUID().IsZero() && !o.ID.IsZero() && !o.StartedAt.IsZero()
}

// This preflight chooses retained policy only. Terminal acceptance occurs after
// authentication and full proof on the caller's coherent transaction.
func (s Service) selectPolicy(c context.Context, a identity.ActorContext, o operation.Context) (publicprofile.ContentPolicy, error) {
	rr, found, e := s.Receipts.FindTx(c, s.Fresh, receiptIdentity(a, o))
	if e != nil {
		return publicprofile.ContentPolicy{}, e
	}
	var rev string
	if found {
		var ok bool
		rev, ok = rr.OperationPolicyRefs.Get("content")
		if !ok {
			return publicprofile.ContentPolicy{}, ErrConflict
		}
	} else {
		rev, e = s.Content.ActiveRevision(c, s.Fresh)
		if e != nil {
			return publicprofile.ContentPolicy{}, ErrProvider
		}
	}
	p, e := s.Content.ReadPublicProfilePolicy(c, s.Fresh, rev)
	if e != nil || p.Validate() != nil || p.Revision != rev {
		return p, ErrProvider
	}
	return p, nil
}
func (s Service) proof(c context.Context, t tx.Queryer, a identity.ActorContext, q Command, o operation.Context) (Terminal, bool, error) {
	rr, found, e := s.Receipts.FindTx(c, t, receiptIdentity(a, o))
	if e != nil || !found {
		return Terminal{}, found, e
	}
	fp, e := receipt.FingerprintRequest(q)
	if e != nil {
		return Terminal{}, true, e
	}
	if rr.Validate() != nil || rr.Identity != receiptIdentity(a, o) || rr.OperationClass != operationClass || rr.ResultSchema != resultSchema || rr.ActorAccountUID != string(a.AccountUID) || rr.ContextID != a.ContextID.UUID() || rr.OperationStartedAt.UnixMicro() != o.StartedAt.UnixMicro() || rr.RequestFingerprint != fp || rr.PolicyVersion != d.PolicyVersion || rr.RetainUntil != nil {
		return Terminal{}, true, ErrConflict
	}
	for _, ref := range o.Policies.Refs() {
		v, yes := rr.OperationPolicyRefs.Get(ref.Name)
		if !yes || v != ref.Version {
			return Terminal{}, true, ErrConflict
		}
	}
	var r Terminal
	dec := json.NewDecoder(bytes.NewReader(rr.ResultPayload))
	dec.DisallowUnknownFields()
	if dec.Decode(&r) != nil {
		return r, true, ErrConflict
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return r, true, ErrConflict
	}
	rev, yes := rr.OperationPolicyRefs.Get("content")
	if !yes || rev != r.Revision {
		return r, true, ErrConflict
	}
	p, e := s.Content.ReadPublicProfilePolicy(c, t, rev)
	if e != nil || p.Validate() != nil || p.Revision != rev {
		return r, true, ErrProvider
	}
	for _, ref := range []policy.Ref{{Name: "profile", Version: p.Policy.PolicyID}, {Name: "profile-moderation", Version: p.Policy.ModerationPolicyID}, {Name: "profile-praise", Version: d.PolicyVersion}} {
		v, yes := rr.OperationPolicyRefs.Get(ref.Name)
		if !yes || v != ref.Version {
			return r, true, ErrConflict
		}
	}
	if r.Schema != resultSchema || r.Actor != a.PlayerID || r.Target != q.Target || r.Server != a.LogicalServerID || r.Account != string(a.AccountUID) || r.Context != a.ContextID.UUID().String() || r.EntropySeed != o.EntropySeed || r.DecisionAt.IsZero() || r.DecisionAt.After(rr.RecordedAt) || r.FirstAt.IsZero() || r.FactVersion <= 0 || r.RootVersion < r.FactVersion || (r.Inserted && (!r.FirstAt.Equal(r.DecisionAt) || r.RootVersion != r.FactVersion)) {
		return r, true, ErrConflict
	}
	root, present, e := s.Roots.Store.ReadRootTx(c, t, q.Target)
	if e != nil {
		return r, true, e
	}
	fact, has, e := s.Roots.Store.FindPraiseTx(c, t, q.Target, a.PlayerID)
	if e != nil {
		return r, true, e
	}
	if !present || root.Validate() != nil || root.PlayerID != q.Target || root.StateVersion < r.RootVersion || !has || fact.Validate() != nil || fact.Target != q.Target || fact.Actor != a.PlayerID || !fact.FirstAt.Equal(r.FirstAt) || fact.RootVersion != r.FactVersion {
		return r, true, ErrConflict
	}
	// A later creator may have won the shared root; CreatedAt need not precede this DecisionAt.
	return r, true, nil
}
func (s Service) currentTx(c context.Context, sc tx.Scope, a identity.ActorContext, q Command, rev string, at time.Time) (d.Observation, error) {
	return s.Roots.ObserveTx(c, sc, q.Target, a.PlayerID, rev, at)
}

type resolver struct {
	s Service
	a identity.ActorContext
	q Command
	o operation.Context
}

func (r resolver) ResolveTimed(c context.Context, req gen.TimedResolutionRequest) (tx.Resolution, error) {
	var out CommandResult
	var found bool
	// One mandatory fresh authoritative read. Its witness is separate from original DecisionAt.
	at, e := r.s.Timed.Binder.Time.Now(c)
	if e != nil {
		return tx.Resolution{}, e
	}
	res, e := r.s.Reads.Run(c, r.o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		if e := r.s.Basic.Fence.FenceActorTx(c, sc.Tx, r.a, at); e != nil {
			return e
		}
		var e error
		out.Terminal, found, e = r.s.proof(c, sc.Tx, r.a, r.q, r.o)
		if e != nil || !found {
			return e
		}
		out.Current, e = r.s.currentTx(c, sc, r.a, r.q, out.Terminal.Revision, at)
		return e
	})
	if e != nil {
		return tx.Resolution{}, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return tx.Resolution{}, ErrConflict
	}
	if !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: out}, nil
}
func (s Service) Execute(c context.Context, a identity.ActorContext, q Command, o operation.Context) (CommandResult, error) {
	if q.Validate(a) != nil || !s.valid(a, o) {
		return CommandResult{}, ErrRequest
	}
	p, e := s.selectPolicy(c, a, o)
	if e != nil {
		return CommandResult{}, e
	}
	bound, e := bind(o, p)
	if e != nil {
		return CommandResult{}, e
	}
	var out CommandResult
	_, res, e := s.Timed.Run(c, bound, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 24, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 5 * time.Millisecond, DefiniteAbortBackoffMax: 100 * time.Millisecond}, resolver{s, a, q, bound}, func(c context.Context, ts gen.TimedScope) error {
		at := ts.Operation.DecisionAt()
		sc := tx.Scope{Tx: ts.Tx, Operation: ts.Operation.Operation(), Attempt: ts.Attempt, Options: ts.Options}
		basic, e := s.Basic.ReadBasicTx(c, sc, a, q.Target, p.Revision, at)
		if e != nil {
			return e
		}
		prep, e := s.Roots.PrepareTx(c, ts.Tx, playerroot.Root{PlayerID: basic.Identity.PlayerID, LogicalServerID: basic.Identity.Server})
		if e != nil {
			return e
		}
		prior, found, e := s.proof(c, ts.Tx, a, q, bound)
		if e != nil {
			return e
		}
		if found {
			out.Terminal = prior
			out.Current, e = s.currentTx(c, sc, a, q, p.Revision, at)
			return e
		}
		if !basic.Eligible[1] || basic.Relation.Blocked {
			return ErrRequest
		}
		fact, root, inserted, e := s.Roots.AddPraiseTx(c, ts.Tx, prep, a.PlayerID, at)
		if e != nil {
			return e
		}
		term := Terminal{Schema: resultSchema, Actor: a.PlayerID, Target: q.Target, Server: a.LogicalServerID, Account: string(a.AccountUID), Context: a.ContextID.UUID().String(), EntropySeed: bound.EntropySeed, Revision: p.Revision, DecisionAt: at, FirstAt: fact.FirstAt, FactVersion: fact.RootVersion, RootVersion: root.StateVersion, Inserted: inserted}
		payload, e := json.Marshal(term)
		if e != nil {
			return e
		}
		fp, e := receipt.FingerprintRequest(q)
		if e != nil {
			return e
		}
		rr, e := receipt.New(bound, receiptIdentity(a, bound), operationClass, resultSchema, payload, fp)
		if e != nil {
			return e
		}
		rr.PolicyVersion = d.PolicyVersion
		rr.ActorAccountUID = string(a.AccountUID)
		rr.ContextID = a.ContextID.UUID()
		rr.RecordedAt = at
		put, e := s.Receipts.PutTx(c, ts.Tx, rr)
		if e != nil {
			return e
		}
		if !put.Inserted {
			return ErrConflict
		}
		out.Terminal = term
		out.Current, e = s.currentTx(c, sc, a, q, p.Revision, at)
		return e
	})
	if e != nil {
		return CommandResult{}, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return CommandResult{}, ErrConflict
	}
	if res.Reconciled {
		got, ok := res.Evidence.(CommandResult)
		if !ok {
			return CommandResult{}, ErrConflict
		}
		return got, nil
	}
	return out, nil
}

type PageRequest struct {
	Start, Offset int64
	TotalHint     *int64
}

func (q PageRequest) Validate() error {
	if q.Start < 0 || q.Start > 9007199254740991 || q.Offset < 1 || q.Offset > 20 || (q.TotalHint != nil && (*q.TotalHint < 0 || *q.TotalHint > 9007199254740991)) {
		return ErrRequest
	}
	return nil
}

type Author = d.PublicAuthor

type Row struct {
	Author     Author `json:"player_info"`
	PraiseTime int64  `json:"praise_time"`
}
type Page struct {
	Rows    []Row
	Current d.Observation
}

func (p Page) Wire() map[string]any {
	return map[string]any{"praise_list": p.Rows, "total_num": p.Current.Count}
}
func (s Service) List(c context.Context, a identity.ActorContext, q PageRequest, o operation.Context) (Page, error) {
	if !s.valid(a, o) || s.Recipients == nil || s.Authors == nil || q.Validate() != nil {
		return Page{}, ErrRequest
	}
	at, e := s.Timed.Binder.Time.Now(c)
	if e != nil {
		return Page{}, e
	}
	rev, e := s.Content.ActiveRevision(c, s.Fresh)
	if e != nil {
		return Page{}, ErrProvider
	}
	out := Page{Rows: []Row{}}
	res, e := s.Reads.Run(c, o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		basic, e := s.Basic.ReadBasicTx(c, sc, a, a.PlayerID, rev, at)
		if e != nil {
			return e
		}
		if _, e = s.Roots.PrepareTx(c, sc.Tx, playerroot.Root{PlayerID: a.PlayerID, LogicalServerID: basic.Identity.Server}); e != nil {
			return e
		}
		out.Current, e = s.Roots.ObserveTx(c, sc, a.PlayerID, a.PlayerID, rev, at)
		if e != nil {
			return e
		}
		facts, e := s.Roots.Store.ListTx(c, sc.Tx, a.PlayerID, q.Start, q.Offset)
		if e != nil {
			return e
		}
		for i, f := range facts {
			if f.Validate() != nil || f.Target != a.PlayerID || f.RootVersion > out.Current.RootVersion {
				return ErrInvalid
			}
			if i > 0 {
				prev := facts[i-1]
				if f.FirstAt.After(prev.FirstAt) || (f.FirstAt.Equal(prev.FirstAt) && f.Actor >= prev.Actor) {
					return ErrInvalid
				}
			}
			srv, e := socialrelation.CanonicalServer(f.Actor)
			if e != nil {
				return ErrProvider
			}
			recipient, e := s.Recipients.ReadBoundRecipientTx(c, sc.Tx, srv, f.Actor)
			if e != nil || recipient.NonReusedAbsent || recipient.Root.Validate() != nil || recipient.Root.PlayerID != f.Actor || recipient.Root.LogicalServerID != srv {
				return ErrProvider
			}
			basis, e := s.Authors.ReadPublicPlayerBasisTx(c, sc.Tx, f.Actor)
			if e != nil || basis.Validate() != nil || basis.Profile.PlayerID != f.Actor {
				return ErrProvider
			}
			author, e := s.author(c, sc.Tx, basis, rev, at, srv)
			if e != nil {
				return e
			}
			out.Rows = append(out.Rows, Row{Author: author, PraiseTime: f.FirstAt.Unix()})
		}
		return nil
	})
	if e != nil {
		return Page{}, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return Page{}, ErrConflict
	}
	return out, nil
}
