package publicprofile

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/profile"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
	"sort"
	"strconv"
	"time"
)

var ErrContent = errors.New("PublicProfile content/provider unavailable")
var ErrCommand = errors.New("invalid PublicProfile command")
var ErrConflict = errors.New("PublicProfile operation proof conflict")

const (
	IntroCommand = "intro"
	HideCommand  = "hide"
	ShowCommand  = "show"
)

type Command struct {
	Kind  string  `json:"kind"`
	Intro string  `json:"intro"`
	Hide  []int16 `json:"hide"`
	Show  []int64 `json:"show"`
}

func (q Command) Normalize() (Command, error) {
	q.Hide = append([]int16{}, q.Hide...)
	q.Show = append([]int64{}, q.Show...)
	if q.Kind == IntroCommand {
		if len(q.Hide) > 0 || len(q.Show) > 0 {
			return q, ErrCommand
		}
		p := profile.Defaults()
		p.Intro = q.Intro
		if p.Validate() != nil {
			return q, ErrCommand
		}
	}
	if q.Kind == HideCommand {
		if q.Intro != "" || len(q.Show) > 0 {
			return q, ErrCommand
		}
		sort.Slice(q.Hide, func(i, j int) bool { return q.Hide[i] < q.Hide[j] })
		p := profile.Defaults()
		p.HideSubtypes = q.Hide
		if p.Validate() != nil {
			return q, ErrCommand
		}
	}
	if q.Kind == ShowCommand {
		if q.Intro != "" || len(q.Hide) > 0 {
			return q, ErrCommand
		}
		p := profile.Defaults()
		p.ShowTypeIDs = q.Show
		if p.Validate() != nil {
			return q, ErrCommand
		}
	}
	if q.Kind != IntroCommand && q.Kind != HideCommand && q.Kind != ShowCommand {
		return q, ErrCommand
	}
	return q, nil
}

type CommandResult struct {
	MetricObservations []MetricObservation `json:"metric_observations"`
	EntropySeed        [32]byte            `json:"entropy_seed"`
	Schema             string              `json:"schema"`
	Kind               string              `json:"kind"`
	PlayerID           int64               `json:"player_id"`
	Server             int32               `json:"server"`
	Account            string              `json:"account"`
	Context            string              `json:"context"`
	Revision           string              `json:"revision"`
	DecisionAt         time.Time           `json:"decision_at"`
	RootVersion        int64               `json:"root_version"`
	Intro              string              `json:"intro"`
	Hide               []int16             `json:"hide"`
	Show               map[string]int64    `json:"show"`
}

func (r CommandResult) Wire() map[string]any {
	switch r.Kind {
	case IntroCommand:
		return map[string]any{"intro": r.Intro}
	case HideCommand:
		return map[string]any{"hide_types": append([]int16{}, r.Hide...)}
	case ShowCommand:
		m := map[string]int64{}
		for k, v := range r.Show {
			m[k] = v
		}
		return map[string]any{"show_types": m}
	}
	return nil
}

type ActorFencer interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type CommandService struct {
	Metrics  MetricReader
	Timed    gen.TimedRunner
	Reads    tx.Runner
	Fresh    tx.Queryer
	Roots    RootService
	Players  playerroot.TxLocker
	Fence    ActorFencer
	Receipts receipt.Store
	Content  ContentReader
}

func commandIdentity(a identity.ActorContext, q Command, o operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "public-profile", Operation: q.Kind, SemanticKey: o.ID.String()}
}
func bindPolicy(o operation.Context, p ContentPolicy) (operation.Context, error) {
	refs := o.Policies.Refs()
	for _, r := range []policy.Ref{{Name: "content", Version: p.Revision}, {Name: "profile", Version: p.Policy.PolicyID}, {Name: "profile-moderation", Version: p.Policy.ModerationPolicyID}} {
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
func (s CommandService) proof(c context.Context, t tx.Queryer, a identity.ActorContext, q Command, o operation.Context) (CommandResult, bool, error) {
	rr, ok, e := s.Receipts.FindTx(c, t, commandIdentity(a, q, o))
	if e != nil || !ok {
		return CommandResult{}, ok, e
	}
	fp, e := receipt.FingerprintRequest(q)
	if e != nil {
		return CommandResult{}, true, e
	}
	if rr.Validate() != nil || rr.Identity != commandIdentity(a, q, o) || rr.OperationClass != "I7B2B_PREFERENCE_ASSIGNMENT" || rr.ResultSchema != "gxb.public-profile.assignment.v1" || rr.ActorAccountUID != string(a.AccountUID) || rr.ContextID != a.ContextID.UUID() || rr.OperationStartedAt.UnixMicro() != o.StartedAt.UnixMicro() || rr.RequestFingerprint != fp || rr.PolicyVersion != profile.PolicyVersion {
		return CommandResult{}, true, ErrConflict
	}
	for _, ref := range o.Policies.Refs() {
		v, yes := rr.OperationPolicyRefs.Get(ref.Name)
		if !yes || v != ref.Version {
			return CommandResult{}, true, ErrConflict
		}
	}
	var r CommandResult
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
	p, e := s.Content.ReadPublicProfilePolicy(c, t, rev)
	if e != nil || p.Validate() != nil || p.Revision != rev {
		return r, true, ErrContent
	}
	if v, yes := rr.OperationPolicyRefs.Get("profile"); !yes || v != p.Policy.PolicyID {
		return r, true, ErrConflict
	}
	if v, yes := rr.OperationPolicyRefs.Get("profile-moderation"); !yes || v != p.Policy.ModerationPolicyID {
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
	if r.EntropySeed != o.EntropySeed || r.Schema != rr.ResultSchema || r.Kind != q.Kind || r.PlayerID != int64(a.PlayerID) || r.Server != int32(a.LogicalServerID) || r.Account != string(a.AccountUID) || r.Context != a.ContextID.UUID().String() || r.RootVersion < 0 || r.DecisionAt.IsZero() || r.DecisionAt.After(rr.RecordedAt) {
		return r, true, ErrConflict
	}
	if q.Kind == IntroCommand {
		want, e := profile.ModerateIntro(q.Intro, p.Policy.Words)
		if e != nil || r.Intro != want || len(r.Hide) > 0 || len(r.Show) > 0 || len(r.MetricObservations) > 0 {
			return r, true, ErrConflict
		}
	}
	if q.Kind == HideCommand {
		if r.Intro != "" || len(r.Show) > 0 || len(r.Hide) != len(q.Hide) {
			return r, true, ErrConflict
		}
		for i, id := range q.Hide {
			if r.Hide[i] != id {
				return r, true, ErrConflict
			}
		}
	}
	if q.Kind == ShowCommand {
		values, e := metricValues(MetricRequest{PlayerID: a.PlayerID, IDs: q.Show, ContentRevision: r.Revision, ObservedAt: r.DecisionAt}, r.MetricObservations)
		if e != nil || r.Intro != "" || len(r.Hide) > 0 || len(values) != len(r.Show) {
			return r, true, ErrConflict
		}
		for k, value := range values {
			if r.Show[k] != value {
				return r, true, ErrConflict
			}
		}
	}
	return r, true, nil
}

// Reconciliation re-reads retained policy + typed outcome on the authoritative
// writer. Receipt absence is UNKNOWN, never authorization to re-execute.
type commandResolver struct {
	s CommandService
	a identity.ActorContext
	q Command
	o operation.Context
}

func (r commandResolver) ResolveTimed(c context.Context, sc gen.TimedResolutionRequest) (tx.Resolution, error) {
	var out CommandResult
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
func (s CommandService) Execute(c context.Context, a identity.ActorContext, q Command, o operation.Context) (CommandResult, error) {
	q, e := q.Normalize()
	if e != nil {
		return CommandResult{}, e
	}
	if s.Timed.Binder.Time == nil || s.Timed.Runner.DB == nil || s.Reads.DB == nil || s.Fresh == nil || s.Roots.Store == nil || s.Players == nil || s.Fence == nil || s.Receipts == nil || s.Content == nil || s.Metrics == nil || !a.PlayerID.Valid() || !a.LogicalServerID.Valid() || !a.AccountUID.Valid() || a.ContextID.UUID().IsZero() || o.ID.IsZero() || o.StartedAt.IsZero() {
		return CommandResult{}, ErrCommand
	}
	// Known attempt is checked before consulting current active policy. Authentication
	// is re-fenced in the caller transaction; historical replay cannot bypass revocation.
	var replay CommandResult
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
		return CommandResult{}, e
	}
	if found {
		if rr.Outcome != tx.DefiniteCommit {
			return CommandResult{}, ErrConflict
		}
		return replay, nil
	}
	rev, e := s.Content.ActiveRevision(c, s.Fresh)
	if e != nil {
		return CommandResult{}, ErrContent
	}
	p, e := s.Content.ReadPublicProfilePolicy(c, s.Fresh, rev)
	if e != nil || p.Validate() != nil || p.Revision != rev {
		return CommandResult{}, ErrContent
	}
	bound, e := bindPolicy(o, p)
	if e != nil {
		return CommandResult{}, e
	}
	var out CommandResult
	_, res, e := s.Timed.Run(c, bound, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, commandResolver{s, a, q, bound}, func(c context.Context, sc gen.TimedScope) error {
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
		cp, e := s.Content.ReadPublicProfilePolicy(c, sc.Tx, rev)
		if e != nil || cp.Validate() != nil || cp.Revision != rev {
			return ErrContent
		}
		change := profile.Change{}
		result := CommandResult{EntropySeed: bound.EntropySeed, Schema: "gxb.public-profile.assignment.v1", Kind: q.Kind, PlayerID: int64(a.PlayerID), Server: int32(a.LogicalServerID), Account: string(a.AccountUID), Context: a.ContextID.UUID().String(), Revision: rev, DecisionAt: at, Hide: []int16{}, Show: map[string]int64{}}
		switch q.Kind {
		case IntroCommand:
			v, e := profile.ModerateIntro(q.Intro, cp.Policy.Words)
			if e != nil {
				return e
			}
			change.Intro = &v
			result.Intro = v
		case HideCommand:
			change.HideSubtypes = &q.Hide
			result.Hide = append([]int16{}, q.Hide...)
		case ShowCommand:
			obs, e := s.Metrics.ReadMetricsTx(c, sc.Tx, MetricRequest{PlayerID: a.PlayerID, IDs: q.Show, ContentRevision: rev, ObservedAt: at})
			if e != nil {
				return ErrContent
			}
			values, e := metricValues(MetricRequest{PlayerID: a.PlayerID, IDs: q.Show, ContentRevision: rev, ObservedAt: at}, obs)
			if e != nil {
				return e
			}
			result.Show = values
			result.MetricObservations = obs
			change.ShowTypeIDs = &q.Show
		}
		prep, e := s.Roots.PreparePreferencesTx(c, sc.Tx, roots[0])
		if e != nil {
			return e
		}
		root, _, e := s.Roots.ApplyPreferencesTx(c, sc.Tx, prep, change, at)
		if e != nil {
			return e
		}
		result.RootVersion = root.StateVersion
		payload, e := json.Marshal(result)
		if e != nil {
			return e
		}
		fp, e := receipt.FingerprintRequest(q)
		if e != nil {
			return e
		}
		r, e := receipt.New(bound, commandIdentity(a, q, bound), "I7B2B_PREFERENCE_ASSIGNMENT", result.Schema, payload, fp)
		if e != nil {
			return e
		}
		r.PolicyVersion = profile.PolicyVersion
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
		return CommandResult{}, e
	}
	if res.Reconciled && res.Outcome == tx.DefiniteCommit {
		got, ok := res.Evidence.(CommandResult)
		if !ok {
			return CommandResult{}, ErrConflict
		}
		return got, nil
	}
	if res.Outcome != tx.DefiniteCommit {
		return CommandResult{}, ErrConflict
	}
	return out, nil
}
