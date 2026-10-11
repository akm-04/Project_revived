package characterhero

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const BookmarkPolicyID = "I7B_HERO_BOOKMARK_V1"
const bookmarkSchema = "gxb.character-hero.bookmark.v1"

var ErrBookmarkRequest = errors.New("character hero: invalid bookmark request")
var ErrBookmarkProof = errors.New("character hero: invalid bookmark proof")
var ErrBookmarkStaleTime = errors.New("character hero: stale bookmark decision time")

type BookmarkStore interface {
	LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error)
	ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error)
	SaveHeroBookmarkTx(context.Context, tx.Tx, character.Hero, int64) error
}
type BookmarkService struct {
	Timed    gen.TimedRunner
	Reads    tx.Runner
	Store    BookmarkStore
	Players  playerroot.TxLocker
	Fence    ActorFencer
	Receipts receipt.Store
}
type BookmarkResult struct {
	Schema       string    `json:"schema"`
	PlayerID     int64     `json:"player_id"`
	PartnerID    int64     `json:"partner_id"`
	IsLike       int64     `json:"is_like"`
	StateVersion int64     `json:"state_version"`
	Changed      bool      `json:"changed"`
	Account      string    `json:"account"`
	Context      string    `json:"context"`
	Server       int32     `json:"server"`
	EntropySeed  [32]byte  `json:"entropy_seed"`
	DecisionAt   time.Time `json:"decision_at"`
}

func bookmarkID(a identity.ActorContext, o operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "character-hero", Operation: "bookmark", SemanticKey: o.ID.String()}
}
func bookmarkFP(partner, value int64) ([32]byte, error) {
	return receipt.FingerprintRequest(map[string]any{"partner_id": partner, "is_like": value})
}
func (s BookmarkService) proof(c context.Context, q tx.Queryer, a identity.ActorContext, partner, value int64, o operation.Context) (BookmarkResult, bool, error) {
	rr, found, e := s.Receipts.FindTx(c, q, bookmarkID(a, o))
	if e != nil || !found {
		return BookmarkResult{}, found, e
	}
	fp, e := bookmarkFP(partner, value)
	if e != nil {
		return BookmarkResult{}, true, e
	}
	if rr.Validate() != nil || rr.Identity != bookmarkID(a, o) || rr.OperationClass != "I7B3B_HERO_BOOKMARK" || rr.ResultSchema != bookmarkSchema || rr.RequestFingerprint != fp || rr.ActorAccountUID != string(a.AccountUID) || rr.ContextID != a.ContextID.UUID() || rr.OperationStartedAt.UnixMicro() != o.StartedAt.UnixMicro() || rr.PolicyVersion != BookmarkPolicyID {
		return BookmarkResult{}, true, ErrBookmarkProof
	}
	if v, ok := rr.OperationPolicyRefs.Get("bookmark"); !ok || v != BookmarkPolicyID {
		return BookmarkResult{}, true, ErrBookmarkProof
	}
	for _, r := range o.Policies.Refs() {
		if v, ok := rr.OperationPolicyRefs.Get(r.Name); !ok || v != r.Version {
			return BookmarkResult{}, true, ErrBookmarkProof
		}
	}
	var out BookmarkResult
	d := json.NewDecoder(bytes.NewReader(rr.ResultPayload))
	d.DisallowUnknownFields()
	if d.Decode(&out) != nil {
		return out, true, ErrBookmarkProof
	}
	var extra any
	if d.Decode(&extra) != io.EOF {
		return out, true, ErrBookmarkProof
	}
	if out.Schema != bookmarkSchema || out.PlayerID != int64(a.PlayerID) || out.PartnerID != partner || out.IsLike != value || out.StateVersion < 1 || out.Account != string(a.AccountUID) || out.Context != a.ContextID.UUID().String() || out.Server != int32(a.LogicalServerID) || out.EntropySeed != o.EntropySeed || out.DecisionAt.IsZero() || out.DecisionAt.After(rr.RecordedAt) {
		return out, true, ErrBookmarkProof
	}
	// Known outcomes are historical. A later owner change need not equal the result.
	return out, true, nil
}

type bookmarkResolver struct {
	s              BookmarkService
	a              identity.ActorContext
	partner, value int64
	o              operation.Context
}

func (r bookmarkResolver) ResolveTimed(c context.Context, req gen.TimedResolutionRequest) (tx.Resolution, error) {
	var out BookmarkResult
	var found bool
	res, e := r.s.Reads.Run(c, r.o, profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		if e := r.s.Fence.FenceActorTx(c, sc.Tx, r.a, req.Operation.DecisionAt()); e != nil {
			return e
		}
		var e error
		out, found, e = r.s.proof(c, sc.Tx, r.a, r.partner, r.value, r.o)
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
func (s BookmarkService) SetBookmark(c context.Context, a identity.ActorContext, partner, value int64, o operation.Context) (BookmarkResult, error) {
	if partner <= 0 || partner > 9007199254740991 || (value != 0 && value != 1) || !a.PlayerID.Valid() || !a.LogicalServerID.Valid() || !a.AccountUID.Valid() || a.ContextID.UUID().IsZero() || o.ID.IsZero() || o.StartedAt.IsZero() || s.Timed.Binder.Time == nil || s.Timed.Runner.DB == nil || s.Reads.DB == nil || s.Store == nil || s.Players == nil || s.Fence == nil || s.Receipts == nil {
		return BookmarkResult{}, ErrBookmarkRequest
	}
	var known BookmarkResult
	var found bool
	res, e := s.Reads.Run(c, o, profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		known, found, e = s.proof(c, sc.Tx, a, partner, value, o)
		if e != nil || !found {
			return e
		}
		at, e := s.Timed.Binder.Time.Now(c)
		if e != nil {
			return e
		}
		return s.Fence.FenceActorTx(c, sc.Tx, a, at)
	})
	if e != nil {
		return BookmarkResult{}, e
	}
	if found {
		if res.Outcome != tx.DefiniteCommit {
			return BookmarkResult{}, ErrBookmarkProof
		}
		return known, nil
	}
	refs := o.Policies.Refs()
	if v, ok := o.Policies.Get("bookmark"); ok {
		if v != BookmarkPolicyID {
			return BookmarkResult{}, ErrBookmarkProof
		}
	} else {
		refs = append(refs, policy.Ref{Name: "bookmark", Version: BookmarkPolicyID})
	}
	ps, e := policy.NewSet(refs...)
	if e != nil {
		return BookmarkResult{}, e
	}
	o.Policies = ps
	// Entire owner lock plan is known before mutation: actor root315 then Hero410.
	ref := character.HeroRef{PlayerID: a.PlayerID, PartnerID: partner}
	if _, e := characterasset.HeroReferenceLockKey(ref); e != nil {
		return BookmarkResult{}, e
	}
	var out BookmarkResult
	_, res, e = s.Timed.Run(c, o, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 5 * time.Millisecond, DefiniteAbortBackoffMax: 30 * time.Millisecond}, bookmarkResolver{s, a, partner, value, o}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if e := s.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		prior, ok, e := s.proof(c, sc.Tx, a, partner, value, o)
		if e != nil {
			return e
		}
		if ok {
			out = prior
			return nil
		}
		roots, e := s.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID})
		if e != nil {
			return e
		}
		if len(roots) != 1 {
			return ErrBookmarkRequest
		}
		h, e := s.Store.LockHeroByPartnerIDTx(c, sc.Tx, a.PlayerID, partner)
		if e != nil {
			return e
		}
		if h.ValidatePersistent() != nil || h.Ref() != ref {
			return ErrBookmarkRequest
		}
		if at.Before(h.UpdatedAt) {
			return ErrBookmarkStaleTime
		}
		changed := h.IsLike != value
		if changed {
			old := h.StateVersion
			h.IsLike = value
			h.StateVersion++
			h.UpdatedAt = at
			if e = s.Store.SaveHeroBookmarkTx(c, sc.Tx, h, old); e != nil {
				return e
			}
		}
		r := BookmarkResult{Schema: bookmarkSchema, PlayerID: int64(a.PlayerID), PartnerID: partner, IsLike: value, StateVersion: h.StateVersion, Changed: changed, Account: string(a.AccountUID), Context: a.ContextID.UUID().String(), Server: int32(a.LogicalServerID), EntropySeed: o.EntropySeed, DecisionAt: at}
		raw, e := json.Marshal(r)
		if e != nil {
			return e
		}
		fp, e := bookmarkFP(partner, value)
		if e != nil {
			return e
		}
		rr, e := receipt.New(o, bookmarkID(a, o), "I7B3B_HERO_BOOKMARK", bookmarkSchema, raw, fp)
		if e != nil {
			return e
		}
		rr.ActorAccountUID = string(a.AccountUID)
		rr.ContextID = a.ContextID.UUID()
		rr.PolicyVersion = BookmarkPolicyID
		rr.RecordedAt = at
		put, e := s.Receipts.PutTx(c, sc.Tx, rr)
		if e != nil {
			return e
		}
		if !put.Inserted {
			return ErrBookmarkProof
		}
		out = r
		return nil
	})
	if e != nil {
		return BookmarkResult{}, e
	}
	if res.Reconciled && res.Outcome == tx.DefiniteCommit {
		got, ok := res.Evidence.(BookmarkResult)
		if !ok {
			return BookmarkResult{}, ErrBookmarkProof
		}
		return got, nil
	}
	if res.Outcome != tx.DefiniteCommit {
		return BookmarkResult{}, ErrBookmarkProof
	}
	return out, nil
}

// Bookmark is CharacterHero metadata. CA8 remains a read-only character facade.
type BookmarkObservation struct {
	Ref             character.HeroRef
	IsLike          int64
	StateVersion    int64
	ContentRevision string
	ObservedAt      time.Time
}
type BookmarkObservationReader struct{ Store BaseObservationStore }

func (r BookmarkObservationReader) BookmarkTx(c context.Context, sc characterasset.CoherentReadScope, ref character.HeroRef) (BookmarkObservation, error) {
	if r.Store == nil || sc.Validate() != nil || ref.Validate() != nil {
		return BookmarkObservation{}, ErrBookmarkRequest
	}
	h, e := r.Store.ReadHeroByPartnerIDTx(c, sc.Queryer(), ref.PlayerID, ref.PartnerID)
	if e != nil {
		return BookmarkObservation{}, e
	}
	if h.ValidatePersistent() != nil || h.Ref() != ref {
		return BookmarkObservation{}, ErrBookmarkRequest
	}
	return BookmarkObservation{Ref: ref, IsLike: h.IsLike, StateVersion: h.StateVersion, ContentRevision: sc.ContentRevision, ObservedAt: sc.ObservedAt}, nil
}
