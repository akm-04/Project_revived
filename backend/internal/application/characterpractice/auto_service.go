package characterpractice

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	AutoSavePredicatePolicyRef = "practice.auto_save_predicate"
	AutoBatchPolicyRef         = "practice.auto_batch"
	autoReceiptSchema          = "gxb.ca6.practice-auto.v1"
	autoReceiptClass           = "CA6_4_PRACTICE_AUTO"
)

type autoReceiptResult struct {
	Info                    Info                    `json:"info"`
	AddAttrs                []PracticeDelta         `json:"add_attrs"`
	IsAdds                  []int64                 `json:"is_adds"`
	PracticeAttr            character.PracticeAttrs `json:"practice_attr"`
	ContentRevision         string                  `json:"content_revision"`
	RollPolicy              string                  `json:"roll_policy"`
	AutoSavePredicatePolicy string                  `json:"auto_save_predicate_policy"`
	AutoBatchPolicy         string                  `json:"auto_batch_policy"`
}

func autoPracticeProfile() tx.Profile {
	return tx.Profile{Name: "CA6_4_PRACTICE_AUTO", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}

func (s Service) bindCA64Operation(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	bound, revision, err := s.bindDailyOperation(ctx, op)
	if err != nil {
		return operation.Context{}, "", err
	}
	for _, p := range [][2]string{
		{BoundsPolicyRef, BoundsPolicyV1},
		{RollPolicyRef, RollPolicyV1},
		{BaseLedgerPolicyRef, BaseLedgerPolicyV1},
		{AutoSavePredicatePolicyRef, AutoSavePredicatePolicyV1},
		{AutoBatchPolicyRef, AutoBatchPolicyV1},
	} {
		bound, err = bindPolicyRef(bound, p[0], p[1])
		if err != nil {
			return operation.Context{}, "", err
		}
	}
	return bound, revision, nil
}

func autoFingerprint(cmd AutoCommand) ([32]byte, error) {
	return receipt.FingerprintRequest(map[string]any{
		"actor_kind":    cmd.Target.kind(),
		"actor_id":      cmd.Target.ActorID,
		"locks":         []bool{cmd.Locks[0], cmd.Locks[1], cmd.Locks[2]},
		"practice_type": cmd.Method,
		"practice_num":  cmd.BatchSize,
		"save_types":    []bool{cmd.Save[0], cmd.Save[1], cmd.Save[2], cmd.Save[3]},
	})
}

func putAutoReceipt(ctx context.Context, st receipt.Store, t tx.Tx, actor identity.ActorContext, op operation.Context, id receipt.Identity, fp [32]byte, payload autoReceiptResult) error {
	raw, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	rr, err := receipt.New(op, id, autoReceiptClass, autoReceiptSchema, raw, fp)
	if err != nil {
		return err
	}
	rr.ActorAccountUID = string(actor.AccountUID)
	rr.ContextID = actor.ContextID.UUID()
	rr.PolicyVersion = RollPolicyV1
	_, err = st.PutTx(ctx, t, rr)
	return err
}

func decodeAutoReceipt(r receipt.Receipt) (AutoResult, error) {
	if r.ResultSchema != autoReceiptSchema {
		return AutoResult{}, fmt.Errorf("character practice: unsupported AUTO receipt schema %q", r.ResultSchema)
	}
	var p autoReceiptResult
	if err := json.Unmarshal(r.ResultPayload, &p); err != nil {
		return AutoResult{}, err
	}
	if len(p.ContentRevision) != 64 || p.RollPolicy != RollPolicyV1 || p.AutoSavePredicatePolicy != AutoSavePredicatePolicyV1 || p.AutoBatchPolicy != AutoBatchPolicyV1 || !validAutoBatchSize(int64(len(p.AddAttrs))) || len(p.AddAttrs) != len(p.IsAdds) || validateCA63Info(p.Info) != nil || p.PracticeAttr.Validate() != nil {
		return AutoResult{}, errors.New("character practice: invalid AUTO terminal receipt")
	}
	for i := range p.AddAttrs {
		if p.AddAttrs[i].Validate() != nil || (p.IsAdds[i] != 0 && p.IsAdds[i] != 1) {
			return AutoResult{}, errors.New("character practice: invalid AUTO terminal attempt")
		}
	}
	return AutoResult{Info: p.Info, AddAttrs: p.AddAttrs, IsAdds: p.IsAdds, PracticeAttr: p.PracticeAttr, Replayed: true}, nil
}

// Auto executes one stock AUTO batch as one semantic command and one
// caller-owned transaction. The complete deterministic effect plan is built
// before the first I5/Root/actor mutation.
func (s Service) Auto(ctx context.Context, actor identity.ActorContext, cmd AutoCommand, op operation.Context) (AutoResult, error) {
	if err := s.validateMutation(); err != nil {
		return AutoResult{}, err
	}
	if s.Deps.LevelAndScalar == nil {
		return AutoResult{}, ErrPracticeUnavailable
	}
	if !actor.PlayerID.Valid() || actor.SessionID.UUID().IsZero() || actor.ContextID.UUID().IsZero() || op.ID.IsZero() || op.StartedAt.IsZero() || cmd.validate() != nil {
		return AutoResult{}, ErrPracticeAdmission
	}

	id := practiceReceiptIdentity(actor.PlayerID, cmd.Target, "auto", op)
	fp, err := autoFingerprint(cmd)
	if err != nil {
		return AutoResult{}, err
	}
	if got, ok, err := findReceipt(ctx, s.Deps.ReceiptRead, id, fp); err != nil {
		return AutoResult{}, err
	} else if ok {
		return decodeAutoReceipt(got)
	}

	bound, revision, err := s.bindCA64Operation(ctx, op)
	if err != nil {
		return AutoResult{}, err
	}
	var out AutoResult
	resolver := receipt.Resolver{Reader: s.Deps.ReceiptRead, Identity: id, Fingerprint: fp}
	res, err := s.Runner.Run(ctx, bound, autoPracticeProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Deps.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		tableID, current, actorVersion, err := s.lockTarget(txctx, scope.Tx, actor.PlayerID, cmd.Target)
		if err != nil {
			return err
		}
		if prior, ok, err := findReceiptTx(txctx, s.Deps.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			decoded, err := decodeAutoReceipt(prior)
			if err != nil {
				return err
			}
			out = decoded
			return nil
		}

		root, err := s.Store.LockPracticeRootTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		originalRootVersion := root.StateVersion
		desired, err := AlchemyEpochStartV1(bound.StartedAt)
		if err != nil {
			return err
		}
		plannedRoot, _, err := s.planDailyGenerationTx(txctx, scope.Tx, root, desired, bound, revision)
		if err != nil {
			return err
		}
		awakened, err := s.actorAwakenedTx(txctx, scope.Tx, revision, cmd.Target, tableID)
		if err != nil {
			return err
		}
		if !awakened || allPracticeAtCap(current) {
			return ErrPracticeAdmission
		}
		facts, err := s.Content.PracticePolicyFactsTx(txctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		if err := facts.Validate(); err != nil {
			return err
		}
		method, err := s.Content.PracticeMethodTx(txctx, scope.Tx, revision, cmd.Method)
		if err != nil {
			return err
		}
		if method.ID != cmd.Method || (method.ID == 3 && method.VIPMin != facts.LegendaryVIPMin) {
			return errors.New("character practice: method policy/content mismatch")
		}
		priv, err := s.Privileges.SnapshotTx(txctx, scope.Tx, actor.PlayerID, bound.StartedAt.UTC())
		if err != nil {
			return err
		}
		if priv.ProviderRevision == "" || priv.VIPLevel < 0 || priv.VIPLevel > 15 {
			return errors.New("character practice: invalid privilege snapshot")
		}
		if priv.VIPLevel < method.VIPMin {
			return ErrPracticePrivilege
		}

		lockCount := countLocks(cmd.Locks)
		var lockRow *LockCost
		if lockCount > 0 {
			row, err := s.Content.PracticeLockTx(txctx, scope.Tx, revision, lockCount)
			if err != nil {
				return err
			}
			lockRow = &row
		}
		advanced := Method{ID: 2, CurrencyType: 2}
		if method.CurrencyType == 2 && lockCount == 3 {
			advanced, err = s.Content.PracticeMethodTx(txctx, scope.Tx, revision, 2)
			if err != nil {
				return err
			}
		}
		plan, err := planAutoBatchV1(bound, plannedRoot, method, advanced, lockRow, current, cmd.Locks, cmd.BatchSize, cmd.Save)
		if err != nil {
			return err
		}

		if _, _, err := s.Deps.LevelAndScalar.AuthorizeLevelAndDebitScalarTx(txctx, scope.Tx, actor.PlayerID, facts.UnlockLevel, plan.CurrencyKey, plan.TotalCost, bound.StartedAt.UTC()); err != nil {
			return err
		}
		finalRoot := plan.NextRoot
		finalRoot.StateVersion = originalRootVersion + 1
		finalRoot.UpdatedAt = bound.StartedAt.UTC()
		if err := finalRoot.Validate(); err != nil {
			return err
		}
		if err := s.Store.SaveAccountingTx(txctx, scope.Tx, finalRoot, originalRootVersion); err != nil {
			return err
		}
		if err := s.applyPracticeTx(txctx, scope.Tx, actor.PlayerID, cmd.Target, actorVersion, plan.FinalAttrs, bound.StartedAt.UTC()); err != nil {
			return err
		}

		out = AutoResult{Info: rootInfo(finalRoot), AddAttrs: append([]PracticeDelta(nil), plan.AddAttrs...), IsAdds: append([]int64(nil), plan.IsAdds...), PracticeAttr: plan.FinalAttrs}
		payload := autoReceiptResult{Info: out.Info, AddAttrs: out.AddAttrs, IsAdds: out.IsAdds, PracticeAttr: out.PracticeAttr, ContentRevision: revision, RollPolicy: RollPolicyV1, AutoSavePredicatePolicy: AutoSavePredicatePolicyV1, AutoBatchPolicy: AutoBatchPolicyV1}
		return putAutoReceipt(txctx, s.Deps.Receipts, scope.Tx, actor, bound, id, fp, payload)
	})
	if err != nil {
		return AutoResult{}, err
	}
	if res.Reconciled && res.Evidence != nil {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			return decodeAutoReceipt(r)
		}
	}
	if !validAutoBatchSize(int64(len(out.AddAttrs))) || len(out.AddAttrs) != len(out.IsAdds) || out.PracticeAttr.Validate() != nil {
		return AutoResult{}, errors.New("character practice: missing terminal AUTO result")
	}
	return out, nil
}
