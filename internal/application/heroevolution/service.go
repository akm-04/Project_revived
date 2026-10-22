package heroevolution

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
	heroevolution "gxb.local/backend/v2/internal/domain/heroevolution"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"

	"strconv"
	"time"
)

const LifecyclePolicy = "C2I_V1_STONE_LIFECYCLE_V2"
const ResultSchema = "gxb.heroevolution.command.v1"
const (
	Allocate = "BREACH_STONE_ADD"
	Advance  = "BREACH_STONE_EVOLVE"
)

var ErrUnavailable = errors.New("evolution: unavailable or unresolved admission")
var ErrStale = errors.New("evolution: stale time")
var ErrRetired = errors.New("evolution: Hero no longer live")
var ErrActor = errors.New("evolution: actor retired")
var ErrRejected = errors.New("evolution: command rejected")
var ErrProof = errors.New("evolution: invalid retained proof")

type Command struct {
	Family                              string
	PartnerID, AttrID, Amount, CostItem int64
}

func (c Command) Validate() error {
	for _, v := range []int64{c.PartnerID, c.AttrID, c.Amount, c.CostItem} {
		if v < 0 || v > 9007199254740991 {
			return heroevolution.ErrInvalid
		}
	}
	if c.PartnerID <= 0 {
		return heroevolution.ErrInvalid
	}
	switch c.Family {
	case Allocate:
		if c.AttrID <= 0 || c.Amount <= 0 || c.CostItem <= 0 {
			return heroevolution.ErrInvalid
		}
	case Advance:
		if c.AttrID != 0 || c.Amount != 0 || c.CostItem != 0 {
			return heroevolution.ErrInvalid
		}
	default:
		return heroevolution.ErrInvalid
	}
	return nil
}
func sameCommand(a, b Command) bool {
	x, e := fingerprint(a)
	y, f := fingerprint(b)
	return e == nil && f == nil && x == y
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
	Body            map[string]any
	Rejected        string
}
type HeroPort interface {
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (character.HeroRoot, error)
	LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error)
	ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (character.HeroRoot, error)
	ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error)
	ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error)
}
type OwnerPort interface {
	ReadHeroTx(context.Context, tx.Queryer, identity.PlayerID, int64) (heroevolution.Facet, error)
	LockHeroTx(context.Context, tx.Tx, identity.PlayerID, int64) (heroevolution.Facet, error)
	SaveHeroTx(context.Context, tx.Tx, heroevolution.Facet, int64) error
	LockAdmissionTx(context.Context, tx.Tx, identity.PlayerID, string) (Admission, bool, error)
	SaveAdmissionTx(context.Context, tx.Tx, Admission) error
}
type ContentPort interface {
	ResolveProgressionPolicyTx(context.Context, tx.Queryer, string) (player.ProgressionPolicy, error)
	HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error)
	EvolutionCatalogTx(context.Context, tx.Queryer, string) (heroevolution.Catalog, error)
	EvolutionInputsActive(context.Context) (string, bool, error)
	EvolutionInputsRevisionTx(context.Context, tx.Queryer, string) (bool, error)
}
type ActorFence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type DebitPort interface {
	PrepareMaterialDebitTx(context.Context, tx.Tx, identity.PlayerID, i5.MaterialCost, operation.Context) (*i5.PreparedMaterialDebit, error)
	ApplyMaterialDebitTx(context.Context, tx.Tx, *i5.PreparedMaterialDebit) (i5.MaterialDebitResult, error)
}
type ValuePort interface {
	ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error)
}
type Service struct {
	Values   ValuePort
	Timed    gen.TimedRunner
	Reads    tx.Runner
	Heroes   HeroPort
	Owner    OwnerPort
	Content  ContentPort
	Players  playerroot.TxLocker
	Fence    ActorFence
	Costs    DebitPort
	Receipts receipt.Store
}

func (s Service) complete() bool {
	return s.Timed.Binder.Time != nil && s.Timed.Runner.DB != nil && s.Reads.DB != nil && s.Heroes != nil && s.Owner != nil && s.Content != nil && s.Values != nil && s.Players != nil && s.Fence != nil && s.Costs != nil && s.Receipts != nil
}
func receiptID(d Admission) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(d.Actor.Player, 10), Domain: "heroevolution", Operation: d.Command.Family, SemanticKey: d.Operation.ID.String()}
}
func fingerprint(c Command) ([32]byte, error) {
	return receipt.FingerprintRequest(map[string]any{"command": c, "policy": LifecyclePolicy})
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
	if r.Validate() != nil || r.Identity != receiptID(d) || r.RequestFingerprint != fp || r.OperationClass != "I7C2I_EVOLUTION_INPUT" || r.ResultSchema != ResultSchema || r.ActorAccountUID != d.Actor.AccountUID || r.ContextID != d.Actor.Context || r.PolicyVersion != LifecyclePolicy || r.OperationStartedAt.UnixMicro() != d.Operation.StartedAt.UnixMicro() {
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
	if out.Schema != ResultSchema || !sameCommand(out.Command, d.Command) || out.Actor != d.Actor || out.OperationID != d.Operation.ID || out.Entropy != d.Operation.EntropySeed || out.DecisionAt.IsZero() || out.ContentRevision != d.ContentRevision || out.ContentRevision == "" || (out.Rejected == "" && out.Body == nil) || out.DecisionAt.After(r.RecordedAt) {
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
	r, e := receipt.New(d.Operation, receiptID(d), "I7C2I_EVOLUTION_INPUT", ResultSchema, raw, fp)
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

// Canonical union prefix before all I5 value suffixes. Population fences retirement/fresh facets.
func (s Service) lockRootPlan(ctx context.Context, t tx.Tx, a identity.ActorContext, at time.Time) error {
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
		return heroevolution.ErrUnqualified
	}
	_, e = s.Heroes.LockRootTx(ctx, t, a.PlayerID)
	return e
}
func (s Service) lockHero(ctx context.Context, t tx.Tx, p identity.PlayerID, id int64) error {
	if _, e := s.Heroes.LockHeroByPartnerIDTx(ctx, t, p, id); e != nil {
		return e
	}
	_, e := s.Owner.LockHeroTx(ctx, t, p, id)
	return e
}
func (s Service) lockPlan(ctx context.Context, t tx.Tx, a identity.ActorContext, c Command, at time.Time) error {
	if e := s.lockRootPlan(ctx, t, a, at); e != nil {
		return e
	}
	return s.lockHero(ctx, t, a.PlayerID, c.PartnerID)
}
func (s Service) Command(ctx context.Context, a identity.ActorContext, c Command, op operation.Context) (Result, error) {
	if !s.complete() || c.Validate() != nil || op.ID.IsZero() || op.StartedAt.IsZero() {
		return Result{}, heroevolution.ErrUnqualified
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
	revision, active, e := s.Content.EvolutionInputsActive(ctx)
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
	if v, ok := op.Policies.Get("heroevolution"); ok {
		if v != LifecyclePolicy {
			return Result{}, ErrProof
		}
	} else {
		refs = append(refs, policy.Ref{Name: "heroevolution", Version: LifecyclePolicy})
	}
	if op.Policies, e = policy.NewSet(refs...); e != nil {
		return Result{}, e
	}
	fresh := Admission{Operation: op, DecisionAt: timed.DecisionAt(), Actor: actorRecord(a), Command: c, ContentRevision: revision, State: "PENDING"}
	for turn := 0; turn < 3; turn++ {
		chosen := fresh
		var known Result
		found := false
		admitResult, admitErr := s.Timed.Runner.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 16, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}, nil, func(ctx context.Context, sc tx.Scope) error {
			if e := s.lockRootPlan(ctx, sc.Tx, a, fresh.DecisionAt); e != nil {
				return e
			}
			var e error
			lookup := fresh
			lookup.DecisionAt = time.Time{}
			known, found, e = s.proof(ctx, sc.Tx, lookup)
			if e != nil || found {
				return e
			}
			prior, exists, e := s.Owner.LockAdmissionTx(ctx, sc.Tx, a.PlayerID, "EVOLUTION")
			if e != nil {
				return e
			}
			if exists && prior.State == "PENDING" {
				chosen = prior
				return nil
			}
			if e := s.lockHero(ctx, sc.Tx, a.PlayerID, c.PartnerID); e != nil {
				return e
			}
			if e := s.requirePlayer(ctx, sc.Tx, a.PlayerID, revision, fresh.DecisionAt); e != nil {
				return e
			}
			return s.Owner.SaveAdmissionTx(ctx, sc.Tx, fresh)
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
		if chosen.Operation.ID == fresh.Operation.ID || sameCommand(chosen.Command, fresh.Command) && chosen.Actor == fresh.Actor {
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
	res, e := s.Timed.Runner.Run(ctx, d.Operation, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 16, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}, resolver{s, d}, func(ctx context.Context, sc tx.Scope) error {
		if e := s.lockPlan(ctx, sc.Tx, a, d.Command, d.DecisionAt); e != nil {
			return e
		}
		lane, exists, e := s.Owner.LockAdmissionTx(ctx, sc.Tx, a.PlayerID, "EVOLUTION")
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
		out = Result{Schema: ResultSchema, Command: d.Command, Actor: d.Actor, OperationID: d.Operation.ID, Entropy: d.Operation.EntropySeed, ContentRevision: d.ContentRevision, DecisionAt: d.DecisionAt}
		out.Body, e = s.apply(ctx, sc.Tx, a, d)
		if out.Body != nil {
			if v, ok := out.Body["_rejected"].(string); ok {
				out.Rejected = v
				delete(out.Body, "_rejected")
			}
		}
		if e != nil {
			return e
		}

		if e = s.putReceipt(ctx, sc.Tx, d, out); e != nil {
			return e
		}
		d.State = "COMMITTED"
		if out.Rejected != "" {
			d.State = "REJECTED"
		}
		return s.Owner.SaveAdmissionTx(ctx, sc.Tx, d)
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
		marked, markErr := s.Reads.Run(ctx, d.Operation, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 16, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}, nil, func(ctx context.Context, sc tx.Scope) error {
			// Current command's caller has already passed actor admission; keep original receipt identity.
			if _, err := s.Heroes.LockRootTx(ctx, sc.Tx, a.PlayerID); err != nil {
				return err
			}
			lane, exists, err := s.Owner.LockAdmissionTx(ctx, sc.Tx, a.PlayerID, "EVOLUTION")
			if err != nil {
				return err
			}
			prior, found, err := s.proof(ctx, sc.Tx, d)
			if err != nil {
				return err
			}
			if found {
				rejected = prior
				return nil
			}
			if !exists || lane.Operation.ID != d.Operation.ID {
				return ErrUnavailable
			}
			if lane.State != "PENDING" {
				return ErrUnavailable
			}
			if err = s.putReceipt(ctx, sc.Tx, d, rejected); err != nil {
				return err
			}
			d.State = "REJECTED"
			return s.Owner.SaveAdmissionTx(ctx, sc.Tx, d)
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
	for _, x := range []error{heroevolution.ErrUnqualified, heroevolution.ErrInvalid, heroevolution.ErrStaleTime, economy.ErrInsufficientBalance, ErrStale, ErrRetired, ErrActor} {
		if errors.Is(e, x) {
			return true
		}
	}
	return false
}
