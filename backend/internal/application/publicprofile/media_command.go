package publicprofile

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"strconv"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	blob "gxb.local/backend/v2/internal/application/profileasset"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/profile"
	asset "gxb.local/backend/v2/internal/domain/profileasset"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type MediaResult struct {
	Schema      string       `json:"schema"`
	History     MediaHistory `json:"history"`
	Account     string       `json:"account"`
	Context     string       `json:"context"`
	Revision    string       `json:"revision"`
	EntropySeed [32]byte     `json:"entropy_seed"`
}

func (r MediaResult) Wire() map[string]any {
	return map[string]any{"avatar_file_path": r.History.Reference.URL, "avatar_md5_code": r.History.Reference.Asset.MD5}
}

type MediaService struct {
	Commands CommandService
	Media    MediaStore
	Blobs    blob.Store
	URLs     MediaURL
}

func mediaIdentity(pid identity.PlayerID, o operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(pid), 10), Domain: "public-profile", Operation: MediaCommand, SemanticKey: o.ID.String()}
}
func decodeMediaResult(r receipt.Receipt) (MediaResult, error) {
	var out MediaResult
	d := json.NewDecoder(bytes.NewReader(r.ResultPayload))
	d.DisallowUnknownFields()
	if r.Validate() != nil || r.OperationClass != MediaClass || r.ResultSchema != MediaSchema || d.Decode(&out) != nil {
		return out, ErrConflict
	}
	var extra any
	if d.Decode(&extra) != io.EOF || out.Schema != MediaSchema || out.History.Validate() != nil || out.Account == "" || out.Context == "" || out.Revision == "" {
		return out, ErrConflict
	}
	if out.Account != r.ActorAccountUID || out.Context != r.ContextID.String() || out.History.Operation.String() != r.Identity.SemanticKey || r.Identity != mediaIdentity(out.History.PlayerID, operation.Context{ID: out.History.Operation}) || out.History.DecisionAt.After(r.RecordedAt) || r.PolicyVersion != profile.PolicyVersion {
		return out, ErrConflict
	}
	for _, ref := range []policy.Ref{{Name: "content", Version: out.Revision}, {Name: "profile-media", Version: asset.Policy}, {Name: "profile-media-url", Version: MediaURLPolicy}} {
		v, ok := r.OperationPolicyRefs.Get(ref.Name)
		if !ok || v != ref.Version {
			return out, ErrConflict
		}
	}
	fp, e := receipt.FingerprintRequest(out.History.Reference.Asset)
	if e != nil || fp != r.RequestFingerprint {
		return out, ErrConflict
	}
	return out, nil
}
func (s MediaService) historyProof(c context.Context, q tx.Queryer, r receipt.Receipt) (MediaResult, error) {
	out, e := decodeMediaResult(r)
	if e != nil {
		return out, e
	}
	h, ok, e := s.Media.ReadMediaHistoryTx(c, q, out.History.Operation)
	if e != nil {
		return out, e
	}
	if !ok || h != out.History {
		return out, ErrConflict
	}
	root, present, e := s.Commands.Roots.Store.ReadRootTx(c, q, h.PlayerID)
	if e != nil {
		return out, e
	}
	if !present || root.Validate() != nil || root.StateVersion < h.RootVersion || root.CreatedAt.After(h.DecisionAt) {
		return out, ErrConflict
	}
	origin, ok, e := s.Media.ReadMediaHistoryTx(c, q, h.Reference.Operation)
	if e != nil {
		return out, e
	}
	if !ok || origin.PlayerID != h.PlayerID || origin.Server != h.Server || origin.Reference != h.Reference {
		return out, ErrConflict
	}
	cp, e := s.Commands.Content.ReadPublicProfilePolicy(c, q, out.Revision)
	if e != nil || cp.Validate() != nil || cp.Revision != out.Revision {
		return out, ErrContent
	}
	for _, ref := range []policy.Ref{{Name: "profile", Version: cp.Policy.PolicyID}, {Name: "profile-moderation", Version: cp.Policy.ModerationPolicyID}} {
		v, ok := r.OperationPolicyRefs.Get(ref.Name)
		if !ok || v != ref.Version {
			return out, ErrConflict
		}
	}
	return out, nil
}
func (s MediaService) proof(c context.Context, q tx.Queryer, a identity.ActorContext, d asset.Descriptor, o operation.Context) (MediaResult, bool, error) {
	r, ok, e := s.Commands.Receipts.FindTx(c, q, mediaIdentity(a.PlayerID, o))
	if e != nil || !ok {
		return MediaResult{}, ok, e
	}
	out, e := s.historyProof(c, q, r)
	if e != nil {
		return out, true, e
	}
	fp, e := receipt.FingerprintRequest(d)
	if e != nil || r.RequestFingerprint != fp || r.OperationStartedAt.UnixMicro() != o.StartedAt.UnixMicro() || out.History.PlayerID != a.PlayerID || out.History.Server != a.LogicalServerID || out.Account != string(a.AccountUID) || out.Context != a.ContextID.UUID().String() || out.EntropySeed != o.EntropySeed {
		return out, true, ErrConflict
	}
	for _, ref := range o.Policies.Refs() {
		v, ok := r.OperationPolicyRefs.Get(ref.Name)
		if !ok || v != ref.Version {
			return out, true, ErrConflict
		}
	}
	return out, true, nil
}

type mediaResolver struct {
	s MediaService
	a identity.ActorContext
	d asset.Descriptor
	o operation.Context
}

func (r mediaResolver) ResolveTimed(c context.Context, sc gen.TimedResolutionRequest) (tx.Resolution, error) {
	var out MediaResult
	var found bool
	res, e := r.s.Commands.Reads.Run(c, r.o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, t tx.Scope) error {
		if e := r.s.Commands.Fence.FenceActorTx(c, t.Tx, r.a, sc.Operation.DecisionAt()); e != nil {
			return e
		}
		var e error
		out, found, e = r.s.proof(c, t.Tx, r.a, r.d, r.o)
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

// Publish closes the physical permit only after every DB scope has ended.
// Cleanup errors are separate from committed business success, and never cause
// re-execution. A nil permit is usable only to replay a positively proved known
// operation; a new reference always requires the exact live prepared binding.
func (s MediaService) Publish(c context.Context, a identity.ActorContext, d asset.Descriptor, p blob.PreparedAsset, o operation.Context) (out MediaResult, err error, cleanup error) {
	terminal := asset.DefiniteAbort
	defer func() {
		if p != nil {
			cleanup = p.Close(terminal)
		}
	}()
	cs := s.Commands
	if d.Validate() != nil || s.Media == nil || s.Blobs == nil || s.URLs.origin == "" || cs.Reads.DB == nil || cs.Timed.Runner.DB == nil || cs.Timed.Binder.Time == nil || cs.Fresh == nil || cs.Fence == nil || cs.Players == nil || cs.Content == nil || cs.Roots.Store == nil || cs.Receipts == nil || !a.PlayerID.Valid() || !a.LogicalServerID.Valid() || !a.AccountUID.Valid() || a.ContextID.UUID().IsZero() || o.ID.IsZero() || o.StartedAt.IsZero() {
		return out, ErrCommand, nil
	}
	var found bool
	res, e := cs.Reads.Run(c, o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, t tx.Scope) error {
		var e error
		out, found, e = s.proof(c, t.Tx, a, d, o)
		if e != nil || !found {
			return e
		}
		at, e := cs.Timed.Binder.Time.Now(c)
		if e != nil {
			return e
		}
		return cs.Fence.FenceActorTx(c, t.Tx, a, at)
	})
	if e != nil {
		return MediaResult{}, e, nil
	}
	if found {
		if res.Outcome != tx.DefiniteCommit {
			return MediaResult{}, ErrConflict, nil
		}
		terminal = asset.VerifiedCommit
		return out, nil, nil
	}
	reservation := asset.Reservation{Operation: o.ID, Actor: a.PlayerID, Server: a.LogicalServerID}
	if p == nil || p.ValidateBinding(s.Blobs, reservation) != nil {
		return MediaResult{}, asset.ErrBinding, nil
	}
	pd, e := p.Descriptor()
	if e != nil || pd != d {
		return MediaResult{}, asset.ErrBinding, nil
	}
	rev, e := cs.Content.ActiveRevision(c, cs.Fresh)
	if e != nil {
		return MediaResult{}, ErrContent, nil
	}
	cp, e := cs.Content.ReadPublicProfilePolicy(c, cs.Fresh, rev)
	if e != nil || cp.Validate() != nil {
		return MediaResult{}, ErrContent, nil
	}
	bound, e := bindPolicy(o, cp)
	if e != nil {
		return MediaResult{}, e, nil
	}
	refs := bound.Policies.Refs()
	for _, r := range []policy.Ref{{Name: "profile-media", Version: asset.Policy}, {Name: "profile-media-url", Version: MediaURLPolicy}} {
		if v, ok := bound.Policies.Get(r.Name); ok {
			if v != r.Version {
				return MediaResult{}, ErrConflict, nil
			}
		} else {
			refs = append(refs, r)
		}
	}
	bound.Policies, e = policy.NewSet(refs...)
	if e != nil {
		return MediaResult{}, e, nil
	}
	terminal = asset.Unknown
	_, res, e = cs.Timed.Run(c, bound, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, mediaResolver{s, a, d, bound}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if e := p.ValidateBinding(s.Blobs, reservation); e != nil {
			return e
		}
		if e := cs.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		prior, ok, e := s.proof(c, sc.Tx, a, d, bound)
		if e != nil {
			return e
		}
		if ok {
			out = prior
			return nil
		}
		roots, e := cs.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID})
		if e != nil || len(roots) != 1 {
			return ErrCommand
		}
		prep, e := cs.Roots.PrepareRootTx(c, sc.Tx, roots[0])
		if e != nil {
			return e
		}
		root, present := prep.Existing()
		if present && at.Before(root.UpdatedAt) {
			return ErrInvalidState
		}
		current, exists, e := s.Media.ReadCurrentMediaTx(c, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		ref, e := s.URLs.Reference(bound.ID, d)
		if e != nil {
			return e
		}
		changed := !exists || current.Reference.Asset != d
		if exists && (current.PlayerID != a.PlayerID || current.Server != a.LogicalServerID || !present || root.StateVersion < current.RootVersion) {
			return ErrConflict
		}
		if changed {
			root, e = cs.Roots.TouchForChildChangeTx(c, sc.Tx, prep, at)
			if e != nil {
				return e
			}
		} else {
			ref = current.Reference
		}
		h := MediaHistory{Operation: bound.ID, PlayerID: a.PlayerID, Server: a.LogicalServerID, Reference: ref, RootVersion: root.StateVersion, DecisionAt: at}
		if e = s.Media.InsertMediaHistoryTx(c, sc.Tx, h); e != nil {
			return e
		}
		if changed {
			if e = s.Media.SetCurrentMediaTx(c, sc.Tx, a.PlayerID, bound.ID); e != nil {
				return e
			}
		}
		out = MediaResult{Schema: MediaSchema, History: h, Account: string(a.AccountUID), Context: a.ContextID.UUID().String(), Revision: rev, EntropySeed: bound.EntropySeed}
		payload, e := json.Marshal(out)
		if e != nil {
			return e
		}
		fp, e := receipt.FingerprintRequest(d)
		if e != nil {
			return e
		}
		rr, e := receipt.New(bound, mediaIdentity(a.PlayerID, bound), MediaClass, MediaSchema, payload, fp)
		if e != nil {
			return e
		}
		rr.PolicyVersion = profile.PolicyVersion
		rr.ActorAccountUID = string(a.AccountUID)
		rr.ContextID = a.ContextID.UUID()
		rr.RecordedAt = at
		put, e := cs.Receipts.PutTx(c, sc.Tx, rr)
		if e != nil {
			return e
		}
		if !put.Inserted {
			return ErrConflict
		}
		return nil
	})
	if res.Outcome == tx.DefiniteAbort || res.Outcome == tx.OutcomeNone {
		terminal = asset.DefiniteAbort
	}
	if e != nil {
		return MediaResult{}, e, nil
	}
	if res.Outcome != tx.DefiniteCommit {
		return MediaResult{}, ErrConflict, nil
	}
	if res.Reconciled {
		var ok bool
		out, ok = res.Evidence.(MediaResult)
		if !ok {
			return MediaResult{}, ErrConflict, nil
		}
	}
	terminal = asset.VerifiedCommit
	return out, nil, nil
}
