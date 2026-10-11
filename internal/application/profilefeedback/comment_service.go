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

const commentSchema = "gxb.profile-feedback.comment.v1"
const commentClass = "I7B4B_PROFILE_COMMENT"

type CommentTerminal struct {
	Schema, Kind                                 string
	Actor, Target, Author                        identity.PlayerID
	Server                                       identity.LogicalServerID
	Account, Context, Revision                   string
	EntropySeed                                  [32]byte
	ID, CreatedVersion, FactVersion, RootVersion int64
	Content                                      string
	CreatedAt, DecisionAt, FactAt                time.Time
	Inserted                                     bool
}

func commentReceipt(a identity.ActorContext, q CommentCommand, o operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "profile-feedback", Operation: "comment-" + q.Kind, SemanticKey: o.ID.String()}
}
func bindComment(o operation.Context, p publicprofile.ContentPolicy) (operation.Context, error) {
	refs := o.Policies.Refs()
	for _, r := range []policy.Ref{{Name: "content", Version: p.Revision}, {Name: "profile", Version: p.Policy.PolicyID}, {Name: "profile-moderation", Version: p.Policy.ModerationPolicyID}, {Name: "profile-comment", Version: d.CommentPolicyVersion}} {
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
func (s CommentService) selectPolicy(c context.Context, a identity.ActorContext, q CommentCommand, o operation.Context) (publicprofile.ContentPolicy, error) {
	var rev string
	if q.Kind == "post" {
		j, found, e := s.Store.ReadAdmissionTx(c, s.Base.Fresh, o.ID.String(), false)
		if e != nil {
			return publicprofile.ContentPolicy{}, e
		}
		if found {
			rev = j.Revision
		}
	}
	if rev == "" {
		rr, found, e := s.Base.Receipts.FindTx(c, s.Base.Fresh, commentReceipt(a, q, o))
		if e != nil {
			return publicprofile.ContentPolicy{}, e
		}
		if found {
			var yes bool
			rev, yes = rr.OperationPolicyRefs.Get("content")
			if !yes {
				return publicprofile.ContentPolicy{}, ErrConflict
			}
		} else {
			rev, e = s.Base.Content.ActiveRevision(c, s.Base.Fresh)
			if e != nil {
				return publicprofile.ContentPolicy{}, ErrProvider
			}
		}
	}
	p, e := s.Base.Content.ReadPublicProfilePolicy(c, s.Base.Fresh, rev)
	if e != nil || p.Validate() != nil || p.Revision != rev {
		return p, ErrProvider
	}
	return p, nil
}
func admissionMatches(j CommentAdmission, a identity.ActorContext, q CommentCommand, o operation.Context) bool {
	fp, e := receipt.FingerprintRequest(q)
	return e == nil && j.Operation.ID == o.ID && j.Operation.StartedAt.UnixMicro() == o.StartedAt.UnixMicro() && j.Operation.EntropySeed == o.EntropySeed && j.Operation.Policies.Equal(o.Policies) && j.Actor == a.PlayerID && j.Target == q.Target && j.Account == string(a.AccountUID) && j.Context == a.ContextID.UUID().String() && j.Server == a.LogicalServerID && j.Command == q && j.Fingerprint == fp && !j.DecisionAt.IsZero()
}
func (s CommentService) actorFence(c context.Context, sc tx.Scope, a identity.ActorContext, at time.Time) error {
	if e := s.Base.Basic.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
		return e
	}
	rs, e := s.Base.Basic.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID})
	if e != nil || len(rs) != 1 || rs[0].PlayerID != a.PlayerID {
		return ErrProvider
	}
	return nil
}

// Admission transactions write identity/control only. Unknown admission never
// starts gameplay without a fresh authoritative check of this exact record.
type admissionResolver struct {
	s CommentService
	a identity.ActorContext
	q CommentCommand
	o operation.Context
}

func (r admissionResolver) Resolve(c context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
	at, e := r.s.Base.Timed.Binder.Time.Now(c)
	if e != nil {
		return tx.Resolution{}, e
	}
	var out CommentAdmission
	var found bool
	res, e := r.s.Base.Reads.Run(c, r.o, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 24, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 5 * time.Millisecond, DefiniteAbortBackoffMax: 100 * time.Millisecond}, nil, func(c context.Context, sc tx.Scope) error {
		if e := r.s.actorFence(c, sc, r.a, at); e != nil {
			return e
		}
		var e error
		out, found, e = r.s.Store.ReadAdmissionTx(c, sc.Tx, r.o.ID.String(), true)
		if e != nil {
			return e
		}
		if found && !admissionMatches(out, r.a, r.q, r.o) {
			return ErrConflict
		}
		return nil
	})
	if e != nil {
		return tx.Resolution{}, e
	}
	if res.Outcome != tx.DefiniteCommit || !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: out}, nil
}

// AdmitPost exposes the same owner-controlled admission path for process
// recovery. No caller may treat PENDING as permission without ExecuteComment's
// actor fence and exact state validation in the gameplay transaction.
func (s CommentService) AdmitPost(c context.Context, a identity.ActorContext, q CommentCommand, o operation.Context, p publicprofile.ContentPolicy) (CommentAdmission, error) {
	if s.Store == nil || q.Kind != "post" || q.Validate(a) != nil || !s.Base.valid(a, o) || p.Validate() != nil {
		return CommentAdmission{}, ErrRequest
	}
	var bindErr error
	o, bindErr = bindComment(o, p)
	if bindErr != nil {
		return CommentAdmission{}, bindErr
	}
	timed, e := s.Base.Timed.Binder.Bind(c, o)
	if e != nil {
		return CommentAdmission{}, e
	}
	fp, e := receipt.FingerprintRequest(q)
	if e != nil {
		return CommentAdmission{}, e
	}
	out := CommentAdmission{Operation: o, Actor: a.PlayerID, Target: q.Target, Account: string(a.AccountUID), Context: a.ContextID.UUID().String(), Server: a.LogicalServerID, Command: q, Fingerprint: fp, DecisionAt: timed.DecisionAt(), Revision: p.Revision, State: "PENDING"}
	blocked := false
	res, e := s.Base.Reads.Run(c, o, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 24, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 5 * time.Millisecond, DefiniteAbortBackoffMax: 100 * time.Millisecond}, admissionResolver{s, a, q, o}, func(c context.Context, sc tx.Scope) error {
		blocked = false
		if e := s.actorFence(c, sc, a, timed.DecisionAt()); e != nil {
			return e
		}
		prior, found, e := s.Store.ReadAdmissionTx(c, sc.Tx, o.ID.String(), true)
		if e != nil {
			return e
		}
		if found {
			if !admissionMatches(prior, a, q, o) || prior.State == "ABORTED" {
				return ErrConflict
			}
			if prior.State == "COMMITTED" {
				out = prior
				return nil
			}
			// Existing pending identity may have attempted gameplay.
			// Resolve/cancel below; never silently rerun its body.
		}
		pending, yes, e := s.Store.PendingAdmissionTx(c, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		if yes {
			// Gameplay always holds the same exclusive315 fence. While this control
			// transaction owns it, no old body can commit; cancellation additionally
			// prevents a delayed body that has not started from ever settling later.
			if pending.Account != string(a.AccountUID) {
				return ErrConflict
			}
			oldID := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "profile-feedback", Operation: "comment-post", SemanticKey: pending.Operation.ID.String()}
			_, has, e := s.Base.Receipts.FindTx(c, sc.Tx, oldID)
			if e != nil {
				return e
			}
			if has {
				return ErrConflict
			} // PENDING+receipt contradicts atomic settlement; preserve for investigation.
			if e = s.Store.SetAdmissionStateTx(c, sc.Tx, pending.Operation.ID.String(), "PENDING", "ABORTED"); e != nil {
				return e
			}
			blocked = true
			return nil
		}
		return s.Store.InsertAdmissionTx(c, sc.Tx, out)
	})
	if e != nil {
		return CommentAdmission{}, e
	}
	if res.Outcome != tx.DefiniteCommit || blocked {
		return CommentAdmission{}, ErrConflict
	}
	if res.Reconciled {
		got, ok := res.Evidence.(CommentAdmission)
		if !ok || got.State == "ABORTED" {
			return CommentAdmission{}, ErrConflict
		}
		return got, nil
	}
	return out, nil
}
func (s CommentService) proof(c context.Context, t tx.Queryer, a identity.ActorContext, q CommentCommand, o operation.Context) (CommentTerminal, bool, error) {
	var out CommentTerminal
	rr, found, e := s.Base.Receipts.FindTx(c, t, commentReceipt(a, q, o))
	if e != nil || !found {
		return out, found, e
	}
	fp, e := receipt.FingerprintRequest(q)
	if e != nil {
		return out, true, e
	}
	if rr.Validate() != nil || rr.Identity != commentReceipt(a, q, o) || rr.OperationClass != commentClass || rr.ResultSchema != commentSchema || rr.RequestFingerprint != fp || rr.ActorAccountUID != string(a.AccountUID) || rr.ContextID != a.ContextID.UUID() || rr.OperationStartedAt.UnixMicro() != o.StartedAt.UnixMicro() || rr.PolicyVersion != d.CommentPolicyVersion || rr.RetainUntil != nil || !rr.OperationPolicyRefs.Equal(o.Policies) {
		return out, true, ErrConflict
	}
	dec := json.NewDecoder(bytes.NewReader(rr.ResultPayload))
	dec.DisallowUnknownFields()
	if dec.Decode(&out) != nil {
		return out, true, ErrConflict
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return out, true, ErrConflict
	}
	rev, yes := o.Policies.Get("content")
	if !yes || out.Revision != rev || out.Schema != commentSchema || out.Kind != q.Kind || out.Actor != a.PlayerID || out.Server != a.LogicalServerID || out.Account != string(a.AccountUID) || out.Context != a.ContextID.UUID().String() || out.EntropySeed != o.EntropySeed || out.DecisionAt.IsZero() || out.DecisionAt.After(rr.RecordedAt) || out.ID <= 0 || out.ID > d.MaxWireCommentID || out.RootVersion < out.CreatedVersion || out.FactVersion <= 0 || out.RootVersion < out.FactVersion || out.FactAt.IsZero() {
		return out, true, ErrConflict
	}
	p, e := s.Base.Content.ReadPublicProfilePolicy(c, t, rev)
	if e != nil || p.Validate() != nil {
		return out, true, ErrProvider
	}
	reb, e := bindComment(o, p)
	if e != nil || !reb.Policies.Equal(o.Policies) {
		return out, true, ErrConflict
	}
	fact, has, e := s.Store.FindCommentTx(c, t, out.ID, a.PlayerID)
	if e != nil {
		return out, true, e
	}
	root, present, e := s.Base.Roots.Store.ReadRootTx(c, t, out.Target)
	if e != nil {
		return out, true, e
	}
	if !has || !present || root.Validate() != nil || root.StateVersion < out.RootVersion || fact.Target != out.Target || fact.Author != out.Author || fact.Content != out.Content || fact.CreatedVersion != out.CreatedVersion || !fact.CreatedAt.Equal(out.CreatedAt) {
		return out, true, ErrConflict
	}
	switch q.Kind {
	case "post":
		j, ok, e := s.Store.ReadAdmissionTx(c, t, o.ID.String(), false)
		if e != nil {
			return out, true, e
		}
		if !ok || j.State != "COMMITTED" || !admissionMatches(j, a, q, o) || !j.DecisionAt.Equal(out.DecisionAt) || out.Target != q.Target || out.Author != a.PlayerID || !out.Inserted || out.FactVersion != fact.CreatedVersion || out.RootVersion != out.FactVersion || !out.FactAt.Equal(fact.CreatedAt) || !out.DecisionAt.Equal(fact.CreatedAt) {
			return out, true, ErrConflict
		}
		moderated, e := d.ModerateComment(q.Content, p.Policy.Words)
		if e != nil || moderated != fact.Content {
			return out, true, ErrConflict
		}
	case "react":
		r, ok, e := s.Store.FindReactionTx(c, t, q.CommentID, a.PlayerID)
		if e != nil {
			return out, true, e
		}
		if !ok || out.ID != q.CommentID || out.Target != q.Target || r.RootVersion != out.FactVersion || !r.FirstAt.Equal(out.FactAt) || (out.Inserted && (!out.FactAt.Equal(out.DecisionAt) || out.RootVersion != out.FactVersion)) {
			return out, true, ErrConflict
		}
	case "delete":
		if out.ID != q.CommentID || out.Target != a.PlayerID || fact.DeletedVersion == nil || *fact.DeletedVersion != out.FactVersion || !fact.DeletedAt.Equal(out.FactAt) || !out.FactAt.Equal(out.DecisionAt) || out.RootVersion != out.FactVersion || !out.Inserted {
			return out, true, ErrConflict
		}
	default:
		return out, true, ErrConflict
	}
	return out, true, nil
}
func (s CommentService) row(c context.Context, t tx.Queryer, f d.Comment) (CommentRow, error) {
	if f.Validate() != nil || f.DeletedAt != nil {
		return CommentRow{}, ErrInvalid
	}
	srv, e := socialrelation.CanonicalServer(f.Author)
	if e != nil {
		return CommentRow{}, ErrProvider
	}
	r, e := s.Base.Recipients.ReadBoundRecipientTx(c, t, srv, f.Author)
	if e != nil || r.NonReusedAbsent || r.Root.Validate() != nil || r.Root.PlayerID != f.Author || r.Root.LogicalServerID != srv {
		return CommentRow{}, ErrProvider
	}
	basis, e := s.Base.Authors.ReadPublicPlayerBasisTx(c, t, f.Author)
	if e != nil || basis.Validate() != nil || basis.Profile.PlayerID != f.Author {
		return CommentRow{}, ErrProvider
	}
	bit := int64(0)
	if f.HasPraised {
		bit = 1
	}
	return CommentRow{ID: f.ID, Owner: f.Target, Author: Author{PlayerID: int64(f.Author), Name: basis.Profile.DisplayName, Avatar: basis.Profile.AvatarID, Frame: basis.Profile.AvatarFrameID, Level: basis.Progression.Level, Region: int32(srv)}, Content: f.Content, PraiseCount: f.PraiseCount, HasPraised: bit}, nil
}

// ObserveCommentsTx is a typed provider for6. Its caller supplies privacy,
// qualified actor/target, one coherent scope, exact content and instant.
func (s CommentService) ObserveCommentsTx(c context.Context, sc tx.Scope, target, actor identity.PlayerID, rev string, at time.Time, start, offset int64, combined bool) (CommentPage, error) {
	out := CommentPage{Target: target, Actor: actor, Revision: rev, ObservedAt: at.UTC(), Best: []CommentRow{}, Rows: []CommentRow{}}
	if s.Store == nil || s.Base.Recipients == nil || s.Base.Authors == nil || sc.Tx == nil || sc.Attempt < 1 || sc.Operation.ID.IsZero() || sc.Operation.StartedAt.IsZero() || (sc.Options.Isolation != tx.RepeatableRead && sc.Options.Isolation != tx.Serializable) || !target.Valid() || !actor.Valid() || at.IsZero() || start < 0 || start > d.MaxWireCommentID || offset < 1 || offset > 20 {
		return out, ErrInvalid
	}
	p, e := s.Base.Content.ReadPublicProfilePolicy(c, sc.Tx, rev)
	if e != nil || p.Validate() != nil || p.Revision != rev {
		return out, ErrProvider
	}
	root, present, e := s.Base.Roots.Store.ReadRootTx(c, sc.Tx, target)
	if e != nil {
		return out, e
	}
	if present {
		if root.Validate() != nil || root.PlayerID != target {
			return out, ErrInvalid
		}
		out.RootVersion = root.StateVersion
	}
	out.Count, e = s.Store.CountCommentsTx(c, sc.Tx, target)
	if e != nil {
		return out, e
	}
	if !present && out.Count != 0 {
		return out, ErrInvalid
	}
	best, e := s.Store.ListCommentsTx(c, sc.Tx, target, actor, 0, 2, true)
	if e != nil {
		return out, e
	}
	for _, f := range best {
		if f.CreatedVersion > out.RootVersion {
			return out, ErrInvalid
		}
		r, e := s.row(c, sc.Tx, f)
		if e != nil {
			return out, e
		}
		out.Best = append(out.Best, r)
	}
	if combined {
		offset = 20 - int64(len(out.Best))
		start = 0
	}
	rows, e := s.Store.ListCommentsTx(c, sc.Tx, target, actor, start, offset, false)
	if e != nil {
		return out, e
	}
	for _, f := range rows {
		if f.CreatedVersion > out.RootVersion {
			return out, ErrInvalid
		}
		r, e := s.row(c, sc.Tx, f)
		if e != nil {
			return out, e
		}
		out.Rows = append(out.Rows, r)
	}
	return out, nil
}
func (s CommentService) currentResult(c context.Context, sc tx.Scope, a identity.ActorContext, term CommentTerminal, rev string, at time.Time) (CommentResult, error) {
	out := CommentResult{Terminal: term}
	var e error
	if term.Kind == "delete" {
		root, present, e := s.Base.Roots.Store.ReadRootTx(c, sc.Tx, term.Target)
		if e != nil {
			return out, e
		}
		if !present || root.Validate() != nil {
			return out, ErrInvalid
		}
		n, e := s.Store.CountCommentsTx(c, sc.Tx, term.Target)
		if e != nil {
			return out, e
		}
		out.Current = CommentPage{Target: term.Target, Actor: a.PlayerID, RootVersion: root.StateVersion, Count: n, Revision: rev, ObservedAt: at.UTC(), Best: []CommentRow{}, Rows: []CommentRow{}}
		return out, nil
	}
	out.Current, e = s.ObserveCommentsTx(c, sc, term.Target, a.PlayerID, rev, at, 0, 20, true)
	if e != nil {
		return out, e
	}
	if term.Kind == "react" {
		f, ok, e := s.Store.FindCommentTx(c, sc.Tx, term.ID, a.PlayerID)
		if e != nil {
			return out, e
		}
		if ok && f.DeletedAt == nil {
			row, e := s.row(c, sc.Tx, f)
			if e != nil {
				return out, e
			}
			out.Affected = &row
		} else {
			return out, ErrRequest
		}
	}
	return out, nil
}

type commentResolver struct {
	s CommentService
	a identity.ActorContext
	q CommentCommand
	o operation.Context
}

func (r commentResolver) Resolve(c context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
	at, e := r.s.Base.Timed.Binder.Time.Now(c)
	if e != nil {
		return tx.Resolution{}, e
	}
	var out CommentResult
	found := false
	res, e := r.s.Base.Reads.Run(c, r.o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		if e := r.s.Base.Basic.Fence.FenceActorTx(c, sc.Tx, r.a, at); e != nil {
			return e
		}
		term, has, e := r.s.proof(c, sc.Tx, r.a, r.q, r.o)
		if e != nil || !has {
			return e
		}
		found = true
		basic, e := r.s.Base.Basic.ReadBasicTx(c, sc, r.a, term.Target, term.Revision, at)
		if e != nil {
			return e
		}
		if !basic.Eligible[4] {
			return ErrRequest
		}
		out, e = r.s.currentResult(c, sc, r.a, term, term.Revision, at)
		return e
	})
	if e != nil {
		return tx.Resolution{}, e
	}
	if res.Outcome != tx.DefiniteCommit || !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: out}, nil
}
func (s CommentService) ExecuteComment(c context.Context, a identity.ActorContext, q CommentCommand, o operation.Context) (CommentResult, error) {
	if s.Store == nil || !s.Base.valid(a, o) || q.Validate(a) != nil || s.Base.Recipients == nil || s.Base.Authors == nil {
		return CommentResult{}, ErrRequest
	}
	p, e := s.selectPolicy(c, a, q, o)
	if e != nil {
		return CommentResult{}, e
	}
	bound, e := bindComment(o, p)
	if e != nil {
		return CommentResult{}, e
	}
	var timed gen.TimedOperation
	var knownReadAt time.Time
	if q.Kind == "post" {
		j, e := s.AdmitPost(c, a, q, bound, p)
		if e != nil {
			return CommentResult{}, e
		}
		if j.State == "COMMITTED" {
			knownReadAt, e = s.Base.Timed.Binder.Time.Now(c)
			if e != nil {
				return CommentResult{}, e
			}
		}
		timed, e = gen.NewTimedOperation(bound, j.DecisionAt)
		if e != nil {
			return CommentResult{}, e
		}
	} else {
		timed, e = s.Base.Timed.Binder.Bind(c, bound)
		if e != nil {
			return CommentResult{}, e
		}
	}
	target := q.Target
	if q.Kind != "post" {
		f, ok, e := s.Store.FindCommentTx(c, s.Base.Fresh, q.CommentID, a.PlayerID)
		if e != nil {
			return CommentResult{}, e
		}
		if !ok || (q.Kind == "react" && target != f.Target) {
			return CommentResult{}, ErrRequest
		}
		target = f.Target
	}
	var out CommentResult
	res, e := s.Base.Timed.Runner.Run(c, bound, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 24, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 5 * time.Millisecond, DefiniteAbortBackoffMax: 100 * time.Millisecond}, commentResolver{s, a, q, bound}, func(c context.Context, sc tx.Scope) error {
		at := timed.DecisionAt()
		if !knownReadAt.IsZero() {
			at = knownReadAt
		}
		basic, e := s.Base.Basic.ReadBasicTx(c, sc, a, target, p.Revision, at)
		if e != nil {
			return e
		}
		prep, e := s.Base.Roots.PrepareTx(c, sc.Tx, playerroot.Root{PlayerID: basic.Identity.PlayerID, LogicalServerID: basic.Identity.Server})
		if e != nil {
			return e
		}
		prior, found, e := s.proof(c, sc.Tx, a, q, bound)
		if e != nil {
			return e
		}
		if !basic.Eligible[4] {
			return ErrRequest
		}
		if found {
			out, e = s.currentResult(c, sc, a, prior, p.Revision, at)
			return e
		}
		if q.Kind != "delete" && (basic.Relation.Blocked || target == a.PlayerID) {
			return ErrRequest
		}
		if q.Kind == "delete" && target != a.PlayerID {
			return ErrRequest
		}
		var fact d.Comment
		root := prep.root
		inserted := true
		var factAt time.Time
		var factVersion int64
		switch q.Kind {
		case "post":
			j, ok, e := s.Store.ReadAdmissionTx(c, sc.Tx, bound.ID.String(), true)
			if e != nil {
				return e
			}
			if !ok || j.State != "PENDING" || !admissionMatches(j, a, q, bound) || !j.DecisionAt.Equal(at) {
				return ErrConflict
			}
			text, e := d.ModerateComment(q.Content, p.Policy.Words)
			if e != nil {
				return e
			}
			root, e = s.Base.Roots.TouchTx(c, sc.Tx, prep, at)
			if e != nil {
				return e
			}
			fact, e = s.Store.InsertCommentTx(c, sc.Tx, d.Comment{Target: target, Author: a.PlayerID, Content: text, CreatedAt: at, CreatedVersion: root.StateVersion})
			if e != nil {
				return e
			}
			factAt = at
			factVersion = root.StateVersion
		case "react", "delete":
			var ok bool
			fact, ok, e = s.Store.FindCommentTx(c, sc.Tx, q.CommentID, a.PlayerID)
			if e != nil {
				return e
			}
			if !ok || fact.Target != target || fact.DeletedAt != nil {
				return ErrRequest
			}
			if q.Kind == "react" {
				r, yes, e := s.Store.FindReactionTx(c, sc.Tx, q.CommentID, a.PlayerID)
				if e != nil {
					return e
				}
				if yes {
					if r.RootVersion > root.StateVersion {
						return ErrInvalid
					}
					inserted = false
					factAt = r.FirstAt
					factVersion = r.RootVersion
				} else {
					root, e = s.Base.Roots.TouchTx(c, sc.Tx, prep, at)
					if e != nil {
						return e
					}
					r = d.CommentReaction{CommentID: q.CommentID, Actor: a.PlayerID, FirstAt: at, RootVersion: root.StateVersion}
					if e = s.Store.InsertReactionTx(c, sc.Tx, r); e != nil {
						return e
					}
					factAt = at
					factVersion = root.StateVersion
				}
			} else {
				root, e = s.Base.Roots.TouchTx(c, sc.Tx, prep, at)
				if e != nil {
					return e
				}
				if e = s.Store.DeleteCommentTx(c, sc.Tx, fact, at, root.StateVersion); e != nil {
					return e
				}
				factAt = at
				factVersion = root.StateVersion
			}
		}
		term := CommentTerminal{Schema: commentSchema, Kind: q.Kind, Actor: a.PlayerID, Target: target, Author: fact.Author, Server: a.LogicalServerID, Account: string(a.AccountUID), Context: a.ContextID.UUID().String(), Revision: p.Revision, EntropySeed: bound.EntropySeed, ID: fact.ID, CreatedVersion: fact.CreatedVersion, FactVersion: factVersion, RootVersion: root.StateVersion, Content: fact.Content, CreatedAt: fact.CreatedAt, DecisionAt: at, FactAt: factAt, Inserted: inserted}
		raw, e := json.Marshal(term)
		if e != nil {
			return e
		}
		fp, e := receipt.FingerprintRequest(q)
		if e != nil {
			return e
		}
		rr, e := receipt.New(bound, commentReceipt(a, q, bound), commentClass, commentSchema, raw, fp)
		if e != nil {
			return e
		}
		rr.ActorAccountUID = string(a.AccountUID)
		rr.ContextID = a.ContextID.UUID()
		rr.RecordedAt = at
		rr.PolicyVersion = d.CommentPolicyVersion
		put, e := s.Base.Receipts.PutTx(c, sc.Tx, rr)
		if e != nil {
			return e
		}
		if !put.Inserted {
			return ErrConflict
		}
		if q.Kind == "post" {
			if e = s.Store.SetAdmissionStateTx(c, sc.Tx, bound.ID.String(), "PENDING", "COMMITTED"); e != nil {
				return e
			}
		}
		out, e = s.currentResult(c, sc, a, term, p.Revision, at)
		return e
	})
	if e != nil {
		if q.Kind == "post" && res.Outcome == tx.DefiniteAbort {
			_ = s.cancelAdmission(c, a, bound)
		}
		return CommentResult{}, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return CommentResult{}, ErrConflict
	}
	if res.Reconciled {
		got, ok := res.Evidence.(CommentResult)
		if !ok {
			return CommentResult{}, ErrConflict
		}
		return got, nil
	}
	return out, nil
}
func (s CommentService) ListComments(c context.Context, a identity.ActorContext, target identity.PlayerID, q PageRequest, o operation.Context) (CommentPage, error) {
	if s.Store == nil || !s.Base.valid(a, o) || !target.Valid() || int64(target) > d.MaxWireCommentID || q.Validate() != nil {
		return CommentPage{}, ErrRequest
	}
	at, e := s.Base.Timed.Binder.Time.Now(c)
	if e != nil {
		return CommentPage{}, e
	}
	rev, e := s.Base.Content.ActiveRevision(c, s.Base.Fresh)
	if e != nil {
		return CommentPage{}, ErrProvider
	}
	var out CommentPage
	res, e := s.Base.Reads.Run(c, o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		basic, e := s.Base.Basic.ReadBasicTx(c, sc, a, target, rev, at)
		if e != nil {
			return e
		}
		if !basic.Eligible[4] {
			return ErrRequest
		}
		if _, e = s.Base.Roots.PrepareTx(c, sc.Tx, playerroot.Root{PlayerID: basic.Identity.PlayerID, LogicalServerID: basic.Identity.Server}); e != nil {
			return e
		}
		out, e = s.ObserveCommentsTx(c, sc, target, a.PlayerID, rev, at, q.Start, q.Offset, false)
		return e
	})
	if e != nil {
		return CommentPage{}, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return CommentPage{}, ErrConflict
	}
	return out, nil
}

// A definite semantic abort can retire its admission immediately. Cleanup
// failure retains PENDING and the next request still uses the same fence.
func (s CommentService) cancelAdmission(c context.Context, a identity.ActorContext, o operation.Context) error {
	at, e := s.Base.Timed.Binder.Time.Now(c)
	if e != nil {
		return e
	}
	_, e = s.Base.Reads.Run(c, o, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 24, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 5 * time.Millisecond, DefiniteAbortBackoffMax: 100 * time.Millisecond}, nil, func(c context.Context, sc tx.Scope) error {
		if e := s.actorFence(c, sc, a, at); e != nil {
			return e
		}
		j, found, e := s.Store.ReadAdmissionTx(c, sc.Tx, o.ID.String(), true)
		if e != nil {
			return e
		}
		if !found || j.Actor != a.PlayerID || j.Account != string(a.AccountUID) {
			return ErrConflict
		}
		if j.State != "PENDING" {
			return nil
		}
		_, has, e := s.Base.Receipts.FindTx(c, sc.Tx, receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "profile-feedback", Operation: "comment-post", SemanticKey: o.ID.String()})
		if e != nil {
			return e
		}
		if has {
			return ErrConflict
		}
		return s.Store.SetAdmissionStateTx(c, sc.Tx, o.ID.String(), "PENDING", "ABORTED")
	})
	return e
}
