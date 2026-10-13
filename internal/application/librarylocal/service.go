package librarylocal

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	gen "gxb.local/backend/v2/internal/application/generation"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
	"strconv"
	"time"
)

const LifecyclePolicy = "LIBRARY_INPUT_LIFECYCLE_V1"
const ResultSchema = "gxb.librarylocal.command.v1"
const (
	Gift         = "LIBRARY_GIFT"
	Feed         = "LIBRARY_FEED"
	Save         = "LIBRARY_SAVE"
	NormalClaim  = "LIBRARY_NORMAL_CLAIM"
	SpecialClaim = "LIBRARY_SPECIAL_CLAIM"
)

var ErrUnavailable = errors.New("library: unavailable or unresolved admission")
var ErrStale = errors.New("library: stale captured decision time")
var ErrRetired = errors.New("library: Hero no longer live")
var ErrActor = errors.New("library: retained actor no longer live")
var ErrRejected = errors.New("library: command rejected")
var ErrProof = errors.New("library: invalid operation proof")

type Command struct {
	Family    string
	PartnerID int64
	Value     int64
}

func (c Command) Validate() error {
	switch c.Family {
	case Gift:
		if c.PartnerID <= 0 || c.Value <= 0 {
			return lib.ErrInvalidGift
		}
	case Feed:
		if c.PartnerID <= 0 || c.Value < 1 || c.Value > 3 {
			return lib.ErrUnqualified
		}
	case Save, NormalClaim:
		if c.PartnerID <= 0 || c.Value != 0 {
			return lib.ErrUnqualified
		}
	case SpecialClaim:
		if c.PartnerID != 0 || c.Value < 1 || c.Value > 23 {
			return lib.ErrUnqualified
		}
	default:
		return lib.ErrUnqualified
	}
	if c.PartnerID > 9007199254740991 {
		return lib.ErrUnqualified
	}
	return nil
}

// DurableActor retains identity references and epochs, never credentials.
type DurableActor struct {
	Account, Session, Context                          ids.UUID
	AccountUID                                         string
	Server                                             int32
	Player, Generation, SessionVersion, ContextVersion int64
}

func actorRecord(a identity.ActorContext) DurableActor {
	return DurableActor{a.AccountID.UUID(), a.SessionID.UUID(), a.ContextID.UUID(), string(a.AccountUID), int32(a.LogicalServerID), int64(a.PlayerID), a.ContextGeneration, a.SessionLivenessVersion, a.ContextLivenessVersion}
}
func (d DurableActor) Actor() (identity.ActorContext, error) {
	a := identity.ActorContext{AccountUID: identity.AccountUID(d.AccountUID), LogicalServerID: identity.LogicalServerID(d.Server), PlayerID: identity.PlayerID(d.Player), ContextGeneration: d.Generation, SessionLivenessVersion: d.SessionVersion, ContextLivenessVersion: d.ContextVersion}
	var e error
	if a.AccountID, e = identity.AccountIDFrom(d.Account); e != nil {
		return a, e
	}
	if a.SessionID, e = identity.SessionIDFrom(d.Session); e != nil {
		return a, e
	}
	if a.ContextID, e = identity.ContextIDFrom(d.Context); e != nil {
		return a, e
	}
	return a, nil
}

type Admission struct {
	Operation       operation.Context
	DecisionAt      time.Time
	Actor           DurableActor
	Command         Command
	ContentRevision string
	State           string
}
type Result struct {
	Schema          string
	Command         Command
	Actor           DurableActor
	OperationID     ids.UUID
	Entropy         [32]byte
	ContentRevision string
	DecisionAt      time.Time
	StateVersion    int64
	Changed         bool
	Favor           int64
	Married         bool
	Applied         lib.FeedAttrs
	Delta           lib.FeedAttrs
	HasPreview      bool
	Rejected        string
}
type HeroPort interface {
	ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (character.HeroRoot, error)
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (character.HeroRoot, error)
	ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error)
	LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error)
	ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error)
}
type LibraryPort interface {
	ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (lib.PlayerFacts, error)
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (lib.PlayerFacts, error)
	ReadHeroTx(context.Context, tx.Queryer, character.HeroRef) (lib.HeroFacts, error)
	LockHeroTx(context.Context, tx.Tx, character.HeroRef) (lib.HeroFacts, error)
	SaveHeroTx(context.Context, tx.Tx, lib.HeroFacts, int64) error
	SavePlayerTx(context.Context, tx.Tx, lib.PlayerFacts, int64) error
	LockAdmissionTx(context.Context, tx.Tx, identity.PlayerID, string) (Admission, bool, error)
	SaveAdmissionTx(context.Context, tx.Tx, Admission) error
}
type ContentPort interface {
	LibraryInputsActive(context.Context) (string, bool, error)
	HeroCoreActiveTx(context.Context, tx.Queryer) (string, bool, error)
	LibraryInputsRevisionTx(context.Context, tx.Queryer, string) (bool, error)
	LibraryCatalogTx(context.Context, tx.Queryer, string) (lib.Catalog, error)
}
type ActorFence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type Service struct {
	Timed    gen.TimedRunner
	Reads    tx.Runner
	Heroes   HeroPort
	Library  LibraryPort
	Content  ContentPort
	Players  playerroot.TxLocker
	Fence    ActorFence
	Costs    i5.TxMaterialCostDebiter
	Receipts receipt.Store
	Roster   RosterProjectionPort
}

func Profile() tx.Profile {
	return tx.Profile{Name: "I7C2B_LIBRARY_INPUTS", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 15 * time.Second}
}
func (s Service) complete() bool {
	return s.Timed.Binder.Time != nil && s.Timed.Runner.DB != nil && s.Reads.DB != nil && s.Heroes != nil && s.Library != nil && s.Content != nil && s.Players != nil && s.Fence != nil && s.Costs != nil && s.Receipts != nil
}
func receiptID(d Admission) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(d.Actor.Player, 10), Domain: "library-local", Operation: d.Command.Family, SemanticKey: d.Operation.ID.String()}
}
func fingerprint(c Command) ([32]byte, error) {
	return receipt.FingerprintRequest(map[string]any{"family": c.Family, "partner_id": c.PartnerID, "value": c.Value, "policy": LifecyclePolicy})
}
func (s Service) proof(ctx context.Context, q tx.Queryer, d Admission) (Result, bool, error) {
	var out Result
	r, ok, e := s.Receipts.FindTx(ctx, q, receiptID(d))
	if e != nil || !ok {
		return out, ok, e
	}
	fp, e := fingerprint(d.Command)
	if e != nil {
		return out, true, e
	}
	if r.Validate() != nil || r.Identity != receiptID(d) || r.RequestFingerprint != fp || r.OperationClass != "I7C2B_LIBRARY_INPUT" || r.ResultSchema != ResultSchema || r.ActorAccountUID != d.Actor.AccountUID || r.ContextID != d.Actor.Context || r.PolicyVersion != LifecyclePolicy || r.OperationStartedAt.UnixMicro() != d.Operation.StartedAt.UnixMicro() {
		return out, true, ErrProof
	}
	dec := json.NewDecoder(bytes.NewReader(r.ResultPayload))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&out); e != nil {
		return out, true, e
	}
	var trailing any
	if dec.Decode(&trailing) != io.EOF {
		return out, true, ErrProof
	}
	if !d.DecisionAt.IsZero() && out.DecisionAt.UnixMicro() != d.DecisionAt.UnixMicro() {
		return out, true, ErrProof
	}
	if out.Schema != ResultSchema || out.Command != d.Command || out.Actor != d.Actor || out.OperationID != d.Operation.ID || out.Entropy != d.Operation.EntropySeed || out.DecisionAt.IsZero() || out.ContentRevision != d.ContentRevision || out.ContentRevision == "" || out.DecisionAt.After(r.RecordedAt) {
		return out, true, ErrProof
	}
	for _, ref := range d.Operation.Policies.Refs() {
		if v, ok := r.OperationPolicyRefs.Get(ref.Name); !ok || v != ref.Version {
			return out, true, ErrProof
		}
	}
	return out, true, nil
}
func (s Service) putReceipt(ctx context.Context, t tx.Tx, d Admission, out Result) error {
	raw, e := json.Marshal(out)
	if e != nil {
		return e
	}
	fp, e := fingerprint(d.Command)
	if e != nil {
		return e
	}
	r, e := receipt.New(d.Operation, receiptID(d), "I7C2B_LIBRARY_INPUT", ResultSchema, raw, fp)
	if e != nil {
		return e
	}
	r.ActorAccountUID = d.Actor.AccountUID
	r.ContextID = d.Actor.Context
	r.PolicyVersion = LifecyclePolicy
	r.RecordedAt = d.DecisionAt
	put, e := s.Receipts.PutTx(ctx, t, r)
	if e != nil {
		return e
	}
	if !put.Inserted {
		return ErrProof
	}
	return nil
}
func (s Service) lockPlan(ctx context.Context, t tx.Tx, a identity.ActorContext, c Command, at time.Time) error {
	if e := s.Fence.FenceActorTx(ctx, t, a, at); e != nil {
		if e.Error() == "actor liveness fence rejected" {
			return ErrActor
		}
		return e
	}
	roots, e := s.Players.LockPlayerRootsTx(ctx, t, a.LogicalServerID, []identity.PlayerID{a.PlayerID})
	if e != nil {
		return e
	}
	if len(roots) != 1 {
		return lib.ErrUnqualified
	}
	// Character population400 precedes instance410; Library root490 follows both.
	if _, e = s.Heroes.LockRootTx(ctx, t, a.PlayerID); e != nil {
		return e
	}
	if c.PartnerID > 0 {
		if _, e = s.Heroes.LockHeroByPartnerIDTx(ctx, t, a.PlayerID, c.PartnerID); e != nil {
			return e
		}
	}
	_, e = s.Library.LockRootTx(ctx, t, a.PlayerID)
	return e
}
func (s Service) Command(ctx context.Context, a identity.ActorContext, c Command, op operation.Context) (Result, error) {
	if !s.complete() || c.Validate() != nil || op.ID.IsZero() || op.StartedAt.IsZero() {
		return Result{}, lib.ErrUnqualified
	}
	timed, e := s.Timed.Binder.Bind(ctx, op)
	if e != nil {
		return Result{}, e
	}
	var historical Result
	found := false
	check, err := s.Reads.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		if e := s.Fence.FenceActorTx(ctx, sc.Tx, a, timed.DecisionAt()); e != nil {
			return e
		}
		d := Admission{Operation: op, Actor: actorRecord(a), Command: c}
		r, ok, e := s.Receipts.FindTx(ctx, sc.Tx, receiptID(d))
		if e != nil || !ok {
			return e
		}
		for _, ref := range op.Policies.Refs() {
			v, ok := r.OperationPolicyRefs.Get(ref.Name)
			if !ok || v != ref.Version {
				return ErrProof
			}
		}
		d.Operation.Policies = r.OperationPolicyRefs
		d.ContentRevision, _ = r.OperationPolicyRefs.Get("content")
		historical, found, e = s.proof(ctx, sc.Tx, d)
		return e
	})
	if err != nil {
		return Result{}, err
	}
	if check.Outcome != tx.DefiniteCommit {
		return Result{}, ErrUnavailable
	}
	if found {
		return finishResult(historical)
	}
	revision, active, e := s.Content.LibraryInputsActive(ctx)
	if e != nil {
		return Result{}, e
	}
	if !active {
		return Result{}, ErrUnavailable
	}
	// Caller-pinned policies are retained for known semantic replay.
	if v, ok := op.Policies.Get("content"); ok {
		revision = v
	}
	refs := op.Policies.Refs()
	if _, ok := op.Policies.Get("content"); !ok {
		refs = append(refs, policy.Ref{Name: "content", Version: revision})
	}
	if v, ok := op.Policies.Get("library"); ok {
		if v != LifecyclePolicy {
			return Result{}, ErrProof
		}
	} else {
		refs = append(refs, policy.Ref{Name: "library", Version: LifecyclePolicy})
	}
	if op.Policies, e = policy.NewSet(refs...); e != nil {
		return Result{}, e
	}
	fresh := Admission{Operation: op, DecisionAt: timed.DecisionAt(), Actor: actorRecord(a), Command: c, ContentRevision: revision, State: "PENDING"}
	for turn := 0; turn < 3; turn++ {
		chosen := fresh
		var known Result
		found := false
		admitResult, admitErr := s.Timed.Runner.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 5, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 10 * time.Millisecond, DefiniteAbortBackoffMax: 50 * time.Millisecond}, nil, func(ctx context.Context, sc tx.Scope) error {
			if e := s.lockPlan(ctx, sc.Tx, a, c, fresh.DecisionAt); e != nil {
				return e
			}
			var e error
			lookup := fresh
			lookup.DecisionAt = time.Time{}
			known, found, e = s.proof(ctx, sc.Tx, lookup)
			if e != nil || found {
				return e
			}
			prior, exists, e := s.Library.LockAdmissionTx(ctx, sc.Tx, a.PlayerID, c.Family)
			if e != nil {
				return e
			}
			if exists && prior.State == "PENDING" {
				chosen = prior
				return nil
			}
			return s.Library.SaveAdmissionTx(ctx, sc.Tx, fresh)
		})
		if admitErr != nil {
			return Result{}, admitErr
		}
		if admitResult.Outcome != tx.DefiniteCommit {
			return Result{}, ErrUnavailable
		}
		if found {
			return finishResult(known)
		}
		out, e := s.execute(ctx, chosen)
		if e != nil {
			return Result{}, e
		}
		if chosen.Operation.ID == fresh.Operation.ID || chosen.Command == fresh.Command {
			return finishResult(out)
		}
		// A different retained operation is resolved before admitting current intent.
	}
	return Result{}, ErrUnavailable
}
func finishResult(out Result) (Result, error) {
	if out.Rejected != "" {
		return out, fmt.Errorf("%w: %s", ErrRejected, out.Rejected)
	}
	return out, nil
}

type resolver struct {
	s Service
	d Admission
}

func (r resolver) Resolve(ctx context.Context, req tx.ResolutionRequest) (tx.Resolution, error) {
	var out Result
	found := false
	res, e := r.s.Reads.Run(ctx, r.d.Operation, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		var e error
		out, found, e = r.s.proof(ctx, sc.Tx, r.d)
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
func (s Service) execute(ctx context.Context, d Admission) (Result, error) {
	a, e := d.Actor.Actor()
	if e != nil {
		return Result{}, e
	}
	var out Result
	res, e := s.Timed.Runner.Run(ctx, d.Operation, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 5 * time.Millisecond, DefiniteAbortBackoffMax: 30 * time.Millisecond}, resolver{s, d}, func(ctx context.Context, sc tx.Scope) error {
		if e := s.lockPlan(ctx, sc.Tx, a, d.Command, d.DecisionAt); e != nil {
			return e
		}
		lane, exists, e := s.Library.LockAdmissionTx(ctx, sc.Tx, a.PlayerID, d.Command.Family)
		if e != nil {
			return e
		}
		prior, found, e := s.proof(ctx, sc.Tx, d)
		if e != nil {
			return e
		}
		if found {
			out = prior
			return nil
		}
		if !exists || lane.Operation.ID != d.Operation.ID || lane.State != "PENDING" {
			return ErrUnavailable
		}
		catalog, e := s.Content.LibraryCatalogTx(ctx, sc.Tx, d.ContentRevision)
		if e != nil {
			return e
		}
		out = Result{Schema: ResultSchema, Command: d.Command, Actor: d.Actor, OperationID: d.Operation.ID, Entropy: d.Operation.EntropySeed, ContentRevision: d.ContentRevision, DecisionAt: d.DecisionAt}
		root, e := s.Library.LockRootTx(ctx, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		if d.DecisionAt.Before(root.UpdatedAt) {
			return ErrStale
		}
		costOp := d.Operation
		costOp.StartedAt = d.DecisionAt
		if d.Command.Family == SpecialClaim {
			heroes, e := s.Heroes.ListHeroesTx(ctx, sc.Tx, a.PlayerID)
			if e != nil {
				return e
			}
			owned := map[int64]bool{}
			for _, h := range heroes {
				rule, ok := catalog.Templates[h.TableID]
				if !ok {
					return lib.ErrUnqualified
				}
				owned[rule.CollectionSourceID] = true
			}
			next, changed, e := root.ClaimSpecial(catalog.SpecialCollections[d.Command.Value-1], owned, d.DecisionAt)
			if e != nil {
				return e
			}
			out.Changed = changed
			out.StateVersion = next.StateVersion
			if changed {
				if e = s.Library.SavePlayerTx(ctx, sc.Tx, next, root.StateVersion); e != nil {
					return e
				}
			}
		} else {
			h, e := s.Heroes.ReadHeroByPartnerIDTx(ctx, sc.Tx, a.PlayerID, d.Command.PartnerID)
			if e != nil {
				return e
			}
			rule, ok := catalog.Templates[h.TableID]
			if !ok {
				return lib.ErrUnqualified
			}
			facts, e := s.Library.LockHeroTx(ctx, sc.Tx, h.Ref())
			if e != nil {
				return e
			}
			if d.DecisionAt.Before(facts.UpdatedAt) || d.DecisionAt.Before(h.UpdatedAt) {
				return ErrStale
			}
			old := facts.StateVersion
			changed := false
			switch d.Command.Family {
			case Gift:
				gift, ok := catalog.Gifts[d.Command.Value]
				if !ok {
					return lib.ErrInvalidGift
				}
				facts, changed, e = facts.ApplyGift(rule, gift, d.DecisionAt)
				if e != nil {
					return e
				}
				if changed {
					_, e = s.Costs.DebitMaterialCostTx(ctx, sc.Tx, a.PlayerID, i5.MaterialCost{Stacks: []i5.StackMaterialCost{{ItemID: gift.ItemID, Amount: 1}}}, costOp)
				}
			case Feed:
				candidate, err := RollFeedingV1(costOp, catalog, facts, rule, d.Command.Value)
				if err != nil {
					return err
				}
				m := catalog.Feeding.Methods[d.Command.Value-1]
				cost := i5.MaterialCost{}
				switch m.CostType {
				case 1:
					cost.Scalars = []i5.ScalarMaterialCost{{ResourceKey: "mana", Amount: m.Cost}}
				case 2:
					cost.Scalars = []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: m.Cost}}
				default:
					cost.Stacks = []i5.StackMaterialCost{{ItemID: m.CostType, Amount: m.Cost}}
				}
				if _, e = s.Costs.DebitMaterialCostTx(ctx, sc.Tx, a.PlayerID, cost, costOp); e == nil {
					facts, e = facts.WithPreview(candidate, d.DecisionAt)
					changed = true
					out.Delta = candidate.Delta
					out.HasPreview = true
				}
			case Save:
				if !rule.DialogEnabled || !facts.Married {
					return lib.ErrNotMarried
				}
				facts, changed, e = facts.SaveCurrent(d.DecisionAt)
			case NormalClaim:
				normal, ok := catalog.NormalCollections[rule.CollectionSourceID]
				if !ok {
					return lib.ErrUnqualified
				}
				facts, changed, e = facts.ClaimNormal(normal, h.Color, h.Star, d.DecisionAt)
			}
			if e != nil {
				return e
			}
			if changed {
				if e = s.Library.SaveHeroTx(ctx, sc.Tx, facts, old); e != nil {
					return e
				}
			}
			out.Changed = changed
			out.StateVersion = facts.StateVersion
			out.Favor = facts.Favor
			out.Married = facts.Married
			out.Applied = facts.Applied
		}
		if e = s.putReceipt(ctx, sc.Tx, d, out); e != nil {
			return e
		}
		d.State = "COMMITTED"
		return s.Library.SaveAdmissionTx(ctx, sc.Tx, d)
	})
	if res.Reconciled && res.Outcome == tx.DefiniteCommit {
		v, ok := res.Evidence.(Result)
		if !ok {
			return Result{}, ErrProof
		}
		return v, nil
	}
	if e != nil && res.Outcome == tx.DefiniteAbort && terminalRejection(e) {
		// Definite rollback authorizes a terminal rejection record. Unknown outcome never does.
		rejected := Result{Schema: ResultSchema, Command: d.Command, Actor: d.Actor, OperationID: d.Operation.ID, Entropy: d.Operation.EntropySeed, ContentRevision: d.ContentRevision, DecisionAt: d.DecisionAt, Rejected: e.Error()}
		marked, markErr := s.Reads.Run(ctx, d.Operation, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 5, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 10 * time.Millisecond, DefiniteAbortBackoffMax: 50 * time.Millisecond}, nil, func(ctx context.Context, sc tx.Scope) error {
			// Current command's caller has already passed actor admission; keep original receipt identity.
			if _, err := s.Library.LockRootTx(ctx, sc.Tx, a.PlayerID); err != nil {
				return err
			}
			lane, exists, err := s.Library.LockAdmissionTx(ctx, sc.Tx, a.PlayerID, d.Command.Family)
			if err != nil {
				return err
			}
			if !exists || lane.Operation.ID != d.Operation.ID {
				return ErrUnavailable
			}
			prior, found, err := s.proof(ctx, sc.Tx, d)
			if err != nil {
				return err
			}
			if found {
				rejected = prior
				return nil
			}
			if lane.State != "PENDING" {
				return ErrUnavailable
			}
			if err = s.putReceipt(ctx, sc.Tx, d, rejected); err != nil {
				return err
			}
			d.State = "REJECTED"
			return s.Library.SaveAdmissionTx(ctx, sc.Tx, d)
		})
		if markErr != nil {
			return Result{}, markErr
		}
		if marked.Outcome != tx.DefiniteCommit {
			return Result{}, ErrUnavailable
		}
		return rejected, nil
	}
	if e != nil {
		return Result{}, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return Result{}, ErrUnavailable
	}
	return out, nil
}

// Infrastructure/proof/unknown failures retain PENDING; only definite domain or
// lifecycle rejection may advance a lane without its economic effect.
func terminalRejection(e error) bool {
	for _, x := range []error{lib.ErrNotMarried, lib.ErrAtCap, lib.ErrInvalidGift, lib.ErrMarriageGate, lib.ErrUnqualified, economy.ErrInsufficientBalance, ErrStale, ErrRetired, ErrActor} {
		if errors.Is(e, x) {
			return true
		}
	}
	return false
}
