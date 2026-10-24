package playerdisplay

import (
	"bytes"
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
	"strconv"
	"time"
)

const resultSchema = "gxb.player-display.command.v1"

type Result struct {
	Schema         string                `json:"schema"`
	Actor          identity.ActorContext `json:"-"`
	Command        Command               `json:"command"`
	Operation      operation.Context     `json:"operation"`
	Revision       string                `json:"revision"`
	DecisionAt     time.Time             `json:"decision_at"`
	ProfileVersion int64                 `json:"profile_version"`
	Changed        bool                  `json:"changed"`
	Wire           map[string]any        `json:"wire"`
}

func displayIdentity(pid identity.PlayerID, q Command, o operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(pid), 10), Domain: "player-display", Operation: q.Kind, SemanticKey: o.ID.String()}
}
func (s Service) valid(a identity.ActorContext, o operation.Context) bool {
	return s.Runner.DB != nil && s.Fresh != nil && s.Time != nil && s.Store != nil && s.Players != nil && s.Fence != nil && s.Receipts != nil && s.Content != nil && s.Directory.Source != nil && s.Directory.Sink != nil && a.PlayerID.Valid() && a.LogicalServerID.Valid() && a.AccountUID.Valid() && !a.ContextID.UUID().IsZero() && !o.ID.IsZero() && !o.StartedAt.IsZero()
}
func (s Service) proof(c context.Context, t tx.Queryer, a identity.ActorContext, q Command, o operation.Context) (Result, bool, error) {
	var out Result
	r, ok, e := s.Receipts.FindTx(c, t, displayIdentity(a.PlayerID, q, o))
	if e != nil || !ok {
		return out, ok, e
	}
	fp, e := receipt.FingerprintRequest(q)
	if e != nil {
		return out, true, e
	}
	if r.Validate() != nil || r.OperationClass != "I7B6A_PLAYER_DISPLAY" || r.ResultSchema != resultSchema || r.Identity != displayIdentity(a.PlayerID, q, o) || r.RequestFingerprint != fp || r.OperationStartedAt.UnixMicro() != o.StartedAt.UnixMicro() || r.ActorAccountUID != string(a.AccountUID) || r.ContextID != a.ContextID.UUID() {
		return out, true, ErrConflict
	}
	d := json.NewDecoder(bytes.NewReader(r.ResultPayload))
	d.DisallowUnknownFields()
	if d.Decode(&out) != nil {
		return out, true, ErrConflict
	}
	var extra any
	if d.Decode(&extra) != io.EOF || out.Schema != resultSchema || out.Actor != a || out.Command != q || out.Operation.ID != o.ID || !out.Operation.StartedAt.Equal(o.StartedAt) || out.Operation.EntropySeed != o.EntropySeed || !out.Operation.Policies.Equal(r.OperationPolicyRefs) || out.ProfileVersion < 1 || out.DecisionAt.IsZero() || out.Wire == nil {
		return out, true, ErrConflict
	}
	rev, ok := r.OperationPolicyRefs.Get("content")
	if !ok || rev != out.Revision {
		return out, true, ErrConflict
	}
	v, ok := r.OperationPolicyRefs.Get("player-display")
	if !ok || v != player.DisplayPolicy || r.PolicyVersion != player.DisplayPolicy {
		return out, true, ErrConflict
	}
	for _, ref := range o.Policies.Refs() {
		v, ok := r.OperationPolicyRefs.Get(ref.Name)
		if !ok || v != ref.Version {
			return out, true, ErrConflict
		}
	}
	if _, e = s.Content.ReadPlayerDisplayCatalogTx(c, t, out.Revision); e != nil {
		return out, true, e
	}
	state, e := s.Store.ReadDisplayStateTx(c, t, a.PlayerID, false)
	if e != nil || state.Validate() != nil || state.Basis.Profile.StateVersion < out.ProfileVersion || state.Basis.Profile.CreatedAt.After(out.DecisionAt) {
		return out, true, ErrConflict
	}
	if q.Kind == "rename" || q.Kind == "purchase" {
		j, exists, e := s.Store.ReadDisplayAdmissionTx(c, t, o.ID.String(), false)
		if e != nil {
			return out, true, e
		}
		if exists && (j.State != "COMMITTED" || !admissionMatches(j, a, q, out.Operation) || !j.DecisionAt.Equal(out.DecisionAt)) {
			return out, true, ErrConflict
		}
	}
	return out, true, nil
}
func bind(o operation.Context, rev string) (operation.Context, error) {
	refs := o.Policies.Refs()
	for _, r := range []policy.Ref{{Name: "content", Version: rev}, {Name: "player-display", Version: player.DisplayPolicy}} {
		if v, ok := o.Policies.Get(r.Name); ok {
			if v != r.Version {
				return o, ErrConflict
			}
		} else {
			refs = append(refs, r)
		}
	}
	p, e := policy.NewSet(refs...)
	o.Policies = p
	return o, e
}

type resolver struct {
	s  Service
	a  identity.ActorContext
	q  Command
	o  operation.Context
	at time.Time
}

func (r resolver) Resolve(c context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
	var out Result
	var found bool
	res, e := r.s.Runner.Run(c, r.o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		if e := r.s.Fence.FenceActorTx(c, sc.Tx, r.a, r.at); e != nil {
			return e
		}
		var e error
		out, found, e = r.s.proof(c, sc.Tx, r.a, r.q, r.o)
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
func (s Service) Execute(c context.Context, a identity.ActorContext, q Command, o operation.Context) (Result, error) {
	var out Result
	if !s.valid(a, o) || q.Validate() != nil {
		return out, ErrRequest
	}
	now, e := s.Time.Now(c)
	if e != nil {
		return out, e
	}
	var found bool
	res, e := s.Runner.Run(c, o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		if e := s.Fence.FenceActorTx(c, sc.Tx, a, now); e != nil {
			return e
		}
		var e error
		out, found, e = s.proof(c, sc.Tx, a, q, o)
		return e
	})
	if e != nil {
		return out, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return out, ErrUnresolved
	}
	if found {
		return out, nil
	}
	rev, e := s.Content.ActiveRevision(c, s.Fresh)
	if e != nil {
		return out, e
	}
	p, e := s.Content.ReadPlayerDisplayCatalogTx(c, s.Fresh, rev)
	if e != nil {
		return out, e
	}
	o, e = bind(o, rev)
	if e != nil {
		return out, e
	}
	at := now.UTC()
	var journal *Admission
	// First/no-op rename has no consumptive lane. The semantic body rejects a
	// concurrent transition into a charged rename without prepared admission.
	if q.Kind == "purchase" || q.Kind == "rename" {
		j, needed, e := s.admit(c, a, q, o, p, rev, at)
		if e != nil {
			return out, e
		}
		if needed {
			journal = &j
			at = j.DecisionAt
			o = j.Operation
			rev = j.Revision
			p, e = s.Content.ReadPlayerDisplayCatalogTx(c, s.Fresh, rev)
			if e != nil {
				return out, e
			}
		}
	}
	res, e = s.Runner.Run(c, o, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver{s, a, q, o, at}, func(c context.Context, sc tx.Scope) error {
		if e := s.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		roots, e := s.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID})
		if e != nil || len(roots) != 1 {
			return ErrRequest
		}
		prior, has, e := s.proof(c, sc.Tx, a, q, o)
		if e != nil {
			return e
		}
		if has {
			out = prior
			return nil
		}
		if journal != nil {
			j, yes, e := s.Store.ReadDisplayAdmissionTx(c, sc.Tx, o.ID.String(), true)
			if e != nil {
				return e
			}
			if !yes || j.State != "PENDING" || !admissionMatches(j, a, q, o) || !j.DecisionAt.Equal(at) {
				return ErrUnresolved
			}
		}
		current, e := s.Store.ReadDisplayStateTx(c, sc.Tx, a.PlayerID, true)
		if e != nil || current.Validate() != nil {
			return ErrConflict
		}
		if at.Before(current.Basis.Profile.UpdatedAt) {
			return ErrConflict
		}
		next := current
		if q.Kind == "avatar" {
			v, yes := p.Find("avatar", q.ID)
			if !yes || v.ValidateAvatarTuple(q.Icon, q.Category) != nil {
				return ErrRequest
			}
			if v.Type == 2 || v.Type == 3 || v.Type == 7 || v.Type == 11 {
				if s.Characters == nil {
					return ErrUnavailable
				}
				if e = s.Characters.PrepareDisplayHeroesTx(c, sc.Tx, a.PlayerID); e != nil {
					return e
				}
			}
		}
		wire := map[string]any{}
		value := i5.DisplayValueRequest{}
		switch q.Kind {
		case "rename":
			if p.ValidateName(q.Name) != nil {
				return ErrRequest
			}
			if current.Basis.Profile.DisplayName != "" && current.Basis.Profile.DisplayName != q.Name {
				value.RenameAmount = p.RenameCost
				if journal == nil {
					return ErrConflict
				}
			}
			next.Basis.Profile.DisplayName = q.Name
			wire["player_name"] = q.Name
		case "purchase":
			value.BuyID = q.ID
			wire["id"] = q.ID
		case "avatar", "frame", "bubble", "title":
			if q.Kind == "title" && q.ID == 0 {
				next.Selection.TitleID = 0
				next.Selection.TitleUniqueID = 0
				wire["title_info"] = map[string]any{"title_id": int64(0), "unique_id": int64(0)}
				break
			}
			v, yes := p.Find(q.Kind, q.ID)
			if !yes {
				return ErrRequest
			}
			qualified, _, qualErr := s.eligible(c, sc.Tx, a.PlayerID, v, q.Category, q.UniqueID, rev, at, p)
			end := int64(0)
			if len(qualified) > 0 {
				end = qualified[0].EndTime
			}
			if e = qualErr; e != nil {
				return e
			}
			switch q.Kind {
			case "avatar":
				next.Basis.Profile.AvatarID = v.Icon
				next.Selection.AvatarTableID = q.ID
				next.Selection.AvatarCategory = q.Category
				wire["avatar_id"] = v.Icon
			case "frame":
				next.Basis.Profile.AvatarFrameID = q.ID
				wire["avatar_frame_id"] = q.ID
			case "title":
				next.Selection.TitleID = q.ID
				next.Selection.TitleUniqueID = q.UniqueID
				wire["title_info"] = map[string]any{"title_id": q.ID, "unique_id": q.UniqueID, "end_time": end}
			case "bubble":
				next.Selection.BubbleID = q.ID
				wire["bubble_info"] = map[string]any{"bubble_id": q.ID, "end_time": end}
			}
		}
		var pv PreparedValue
		if value.BuyID > 0 || value.RenameAmount > 0 {
			if s.Values == nil {
				return ErrUnavailable
			}
			pv, e = s.Values.PrepareDisplayValueTx(c, sc.Tx, a, value, p, rev, at, o)
			if e != nil {
				return e
			}
		}
		// Final740 lock is acquired before any gameplay mutation/debit/grant.
		if _, e = s.Directory.Sink.LockOwnedDirectoryTx(c, sc.Tx, a.PlayerID); e != nil {
			return e
		}
		changed := next.Basis.Profile.DisplayName != current.Basis.Profile.DisplayName || next.Basis.Profile.AvatarID != current.Basis.Profile.AvatarID || next.Basis.Profile.AvatarFrameID != current.Basis.Profile.AvatarFrameID || next.Selection != current.Selection
		if pv != nil {
			effect, e := pv.ApplyDisplayValueTx(c, sc.Tx)
			if e != nil {
				return e
			}
			for k, v := range effect {
				wire[k] = v
			}
		}
		if changed {
			if e = s.Store.SaveDisplayStateTx(c, sc.Tx, current, next, at); e != nil {
				return e
			}
			next.Basis.Profile.StateVersion = current.Basis.Profile.StateVersion + 1
		}
		if e = s.Directory.ReconcileDirectoryTx(c, sc.Tx, a.PlayerID, o); e != nil {
			return e
		}
		out = Result{Schema: resultSchema, Actor: a, Command: q, Operation: o, Revision: rev, DecisionAt: at, ProfileVersion: next.Basis.Profile.StateVersion, Changed: changed, Wire: wire}
		raw, e := json.Marshal(out)
		if e != nil {
			return e
		}
		fp, e := receipt.FingerprintRequest(q)
		if e != nil {
			return e
		}
		r, e := receipt.New(o, displayIdentity(a.PlayerID, q, o), "I7B6A_PLAYER_DISPLAY", resultSchema, raw, fp)
		if e != nil {
			return e
		}
		r.ActorAccountUID = string(a.AccountUID)
		r.ContextID = a.ContextID.UUID()
		r.PolicyVersion = player.DisplayPolicy
		r.RecordedAt = at
		put, e := s.Receipts.PutTx(c, sc.Tx, r)
		if e != nil {
			return e
		}
		if !put.Inserted {
			return ErrConflict
		}
		if journal != nil {
			return s.Store.SetDisplayAdmissionTx(c, sc.Tx, o.ID.String(), "PENDING", "COMMITTED")
		}
		return nil
	})
	if e != nil {
		return Result{}, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return Result{}, ErrUnresolved
	}
	if res.Evidence != nil {
		r, ok := res.Evidence.(Result)
		if !ok {
			return Result{}, ErrConflict
		}
		return r, nil
	}
	return out, nil
}
