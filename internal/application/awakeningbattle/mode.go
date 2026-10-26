// Package awakeningbattle orchestrates only the source Blood branch of 866/867.
package awakeningbattle

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Combat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, combat.StartRequest) (combat.Started, error)
	AttestSummaryTx(context.Context, tx.Tx, combat.SummaryRequest) (combat.SummaryAttested, error)
}
type Mode struct {
	Timed   gen.TimedRunner
	Fresh   tx.Queryer
	Content interface {
		ActiveRevision(context.Context, tx.Queryer) (string, error)
	}
	Fence interface {
		FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
	}
	Heroes      i5.AwakeningHeroes
	Missions    i5.AwakeningBloodPort
	Combat      Combat
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
}

func locator(a identity.ActorContext) cd.Locator {
	return cd.Locator{DomainKind: "AWAKENING_BLOOD", AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID), DomainLocator: fmt.Sprintf("player:%d", a.PlayerID)}
}
func generation(a objective.AwakeInstance) string {
	return fmt.Sprintf("blood:%d:%d", a.Mission, a.Generation)
}
func (s Mode) pin(ctx context.Context, op operation.Context) (operation.Context, error) {
	if s.Fresh == nil || s.Content == nil || s.Fence == nil || s.Heroes == nil || s.Missions == nil || s.Combat == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return op, errors.New("Blood combat runtime unavailable")
	}
	if _, ok := op.Policies.Get("content"); ok {
		return op, nil
	}
	rev, e := s.Content.ActiveRevision(ctx, s.Fresh)
	if e != nil {
		return op, e
	}
	op.Policies, e = policy.NewSet(append(op.Policies.Refs(), policy.Ref{Name: "content", Version: rev})...)
	return op, e
}
func (s Mode) Start(ctx context.Context, actor identity.ActorContext, id int64, op operation.Context) (map[string]any, error) {
	if id <= 0 {
		return nil, objective.ErrAwakeningRefused
	}
	op, e := s.pin(ctx, op)
	if e != nil {
		return nil, e
	}
	_, _, e = s.Timed.Run(ctx, op, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, sc gen.TimedScope) error {
		at, current := sc.Operation.DecisionAt(), sc.Operation.Operation()
		if e := s.Fence.FenceActorTx(ctx, sc.Tx, actor, at); e != nil {
			return e
		}
		rev, _ := current.Policies.Get("content")
		if _, e := s.Heroes.LockAwakeningHeroesTx(ctx, sc.Tx, actor.PlayerID, rev); e != nil {
			return e
		}
		frozen, e := s.Missions.FreezeAwakeningBloodTx(ctx, sc.Tx, actor.PlayerID, id)
		if e != nil {
			return e
		}
		a := frozen.Occurrence
		scope, e := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: current, Attempt: sc.Attempt, Options: sc.Options}, rev, at)
		if e != nil {
			return e
		}
		raw, e := json.Marshal(map[string]any{"contract": objective.AwakeningContract, "mission": a.Mission, "generation": a.Generation, "guard_witness": a.OwnerID})
		if e != nil {
			return e
		}
		fp := sha256.Sum256(raw)
		// Source 866 omits the selected team; this snapshots only its mandatory canonical girl witness.
		_, e = s.Combat.StartTx(ctx, sc.Tx, scope, combat.StartRequest{Actor: actor, Locator: locator(actor), GenerationRef: generation(a), StartFingerprint: hex.EncodeToString(fp[:]), ResultDeadline: at.Add(time.Duration(frozen.WindowSeconds) * time.Second), TrustProfile: cd.ClientSummaryAttested, Replay: cd.ReplaySpec{Response: cd.ReplayOK}, Battle: combat.BattleRequest{CampaignType: 27, BattleID: id, Formation: []int64{a.OwnerID}, TeamA: []combat.Participant{{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: actor.PlayerID, Identity: a.OwnerID}}}})
		return e
	})
	if e != nil {
		return nil, e
	}
	return map[string]any{}, nil
}

type resolver struct{ receipt.Resolver }

func (r resolver) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation(), CommitError: q.CommitError, Attempt: q.Attempt})
}
func decode(r receipt.Receipt, id receipt.Identity, fp [32]byte) (map[string]any, error) {
	if r.Validate() != nil || r.Identity != id || r.RequestFingerprint != fp || r.OperationClass != "I9_AWAKENING_BLOOD" || r.ResultSchema != "gxb.i9.awakening-blood.v1" {
		return nil, errors.New("invalid Blood receipt")
	}
	var body map[string]any
	e := json.Unmarshal(r.ResultPayload, &body)
	if e == nil && body == nil {
		e = errors.New("empty Blood receipt")
	}
	return body, e
}
func (s Mode) Result(ctx context.Context, actor identity.ActorContext, id, waves int64, op operation.Context) (map[string]any, error) {
	if id <= 0 || waves != 20 {
		return nil, objective.ErrAwakeningRefused
	}
	op, e := s.pin(ctx, op)
	if e != nil {
		return nil, e
	}
	rid := receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(actor.PlayerID), Domain: "objective", Operation: "blood-result", SemanticKey: op.ID.String()}
	fp, e := receipt.FingerprintRequest(map[string]any{"mission": id, "waves": waves, "npc_ids_empty": true})
	if e != nil {
		return nil, e
	}
	var body map[string]any
	_, res, e := s.Timed.Run(ctx, op, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, resolver{receipt.Resolver{Reader: s.ReceiptRead, Identity: rid, Fingerprint: fp}}, func(ctx context.Context, sc gen.TimedScope) error {
		if e := s.Fence.FenceActorTx(ctx, sc.Tx, actor, sc.Operation.DecisionAt()); e != nil {
			return e
		}
		if prior, ok, e := s.Receipts.FindTx(ctx, sc.Tx, rid); e != nil {
			return e
		} else if ok {
			if prior.RequestFingerprint != fp {
				return &receipt.ConflictError{Identity: rid}
			}
			body, e = decode(prior, rid, fp)
			return e
		}
		frozen, e := s.Missions.FreezeAwakeningBloodTx(ctx, sc.Tx, actor.PlayerID, id)
		if e != nil {
			return e
		}
		a := frozen.Occurrence
		attested, e := s.Combat.AttestSummaryTx(ctx, sc.Tx, combat.SummaryRequest{Locator: locator(actor), GenerationRef: generation(a), TerminalKind: "AWAKENING_BLOOD_RESULT", At: sc.Operation.DecisionAt(), Policy: cd.SummaryPolicy{ID: "AWAKENING_BLOOD_SUMMARY_V1", Version: 1, OmitParticipantEcho: true}, Summary: cd.Summary{Win: true}})
		if e != nil {
			return e
		}
		if attested.Drained && !a.Complete || !attested.Drained && attested.Attestation.Verdict == cd.VerdictRejected {
			body = map[string]any{"error_code": int64(1)}
		} else {
			body, e = s.Missions.CompleteAwakeningBloodTx(ctx, sc.Tx, actor.PlayerID, a)
			if e != nil {
				return e
			}
		}
		raw, e := json.Marshal(body)
		if e != nil {
			return e
		}
		r, e := receipt.New(sc.Operation.Operation(), rid, "I9_AWAKENING_BLOOD", "gxb.i9.awakening-blood.v1", raw, fp)
		if e != nil {
			return e
		}
		r.ActorAccountUID, r.ContextID, r.PolicyVersion = string(actor.AccountUID), actor.ContextID.UUID(), objective.AwakeningContract
		_, e = s.Receipts.PutTx(ctx, sc.Tx, r)
		return e
	})
	if e != nil {
		return nil, e
	}
	if res.Reconciled {
		r, ok := res.Evidence.(receipt.Receipt)
		if !ok {
			return nil, errors.New("Blood recovery receipt missing")
		}
		body, e = decode(r, rid, fp)
	}
	return body, e
}
