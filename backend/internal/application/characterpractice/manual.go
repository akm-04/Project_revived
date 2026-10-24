package characterpractice

import (
	"context"
	"errors"
	"fmt"
	"math"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func checkedAddNonNegative(a, b int64) (int64, error) {
	if a < 0 || b < 0 || a > math.MaxInt64-b {
		return 0, errors.New("character practice: accounting overflow")
	}
	return a + b, nil
}

func freeEntitlementReady(root Root, at time.Time, intervalSeconds int64) bool {
	if root.FreeLastConsumedAt == nil {
		return true
	}
	if intervalSeconds <= 0 || at.IsZero() {
		return false
	}
	return !at.UTC().Before(root.FreeLastConsumedAt.UTC().Add(time.Duration(intervalSeconds) * time.Second))
}

type manualAccounting struct {
	CurrencyKey  string
	TotalCost    int64
	NextRoot     Root
	ConsumedFree bool
}

// planManualAccounting implements the frozen CA6-3 accounting compatibility
// decision after Root450 has been locked and any newer daily generation has
// been planned in memory. It performs no writes and no I5 reads.
func planManualAccounting(root Root, method Method, advanced Method, lock *LockCost, lockCount int64, facts PolicyFacts, at time.Time) (manualAccounting, error) {
	if root.Validate() != nil || facts.Validate() != nil || at.IsZero() || method.ID < 1 || method.ID > 3 || method.BaseCost < 0 || method.VIPMin < 0 || lockCount < 0 || lockCount > 3 {
		return manualAccounting{}, errors.New("character practice: invalid manual accounting input")
	}
	if method.CurrencyType != 1 && method.CurrencyType != 2 {
		return manualAccounting{}, errors.New("character practice: invalid method currency")
	}
	if lockCount == 0 && lock != nil {
		return manualAccounting{}, errors.New("character practice: unexpected zero-lock policy row")
	}
	if lockCount > 0 {
		if lock == nil || lock.Count != lockCount || lock.ManaStep < 0 || lock.CrystalStep < 0 || lock.BlessCost < 0 {
			return manualAccounting{}, errors.New("character practice: invalid lock accounting row")
		}
		if root.BlessRemaining < lock.BlessCost {
			return manualAccounting{}, ErrPracticeBless
		}
	}

	methodBase := method.BaseCost
	if method.CurrencyType == 2 && lockCount == 3 {
		// Current stock source explicitly substitutes Advanced's base method
		// price for all three-lock crystal rolls, including Legendary.
		if advanced.ID != 2 || advanced.CurrencyType != 2 || advanced.BaseCost < 0 {
			return manualAccounting{}, errors.New("character practice: invalid Advanced method for three-lock pricing")
		}
		methodBase = advanced.BaseCost
	}

	ready := freeEntitlementReady(root, at, facts.FreeIntervalSeconds)
	consumeFree := ready && methodBase > 0
	chargedMethodBase := methodBase
	if ready {
		chargedMethodBase = 0
	}

	next := root
	var running, step int64
	var key string
	switch method.CurrencyType {
	case 1:
		key = "mana"
		running = root.BaseMana
		if lock != nil {
			step = lock.ManaStep
		}
	case 2:
		key = "crystal"
		running = root.BaseCrystal
		if lock != nil {
			step = lock.CrystalStep
		}
	}

	var surcharge int64
	for i := int64(0); i < lockCount; i++ {
		var err error
		running, err = checkedAddNonNegative(running, step)
		if err != nil {
			return manualAccounting{}, err
		}
		surcharge, err = checkedAddNonNegative(surcharge, running)
		if err != nil {
			return manualAccounting{}, err
		}
	}
	total, err := checkedAddNonNegative(chargedMethodBase, surcharge)
	if err != nil {
		return manualAccounting{}, err
	}

	if lockCount > 0 {
		next.BlessRemaining -= lock.BlessCost
		if method.CurrencyType == 1 {
			next.BaseMana = running
		} else {
			next.BaseCrystal = running
		}
	}
	if consumeFree {
		consumedAt := at.UTC()
		next.FreeLastConsumedAt = &consumedAt
	}
	return manualAccounting{CurrencyKey: key, TotalCost: total, NextRoot: next, ConsumedFree: consumeFree}, nil
}

func (s Service) Manual(ctx context.Context, actor identity.ActorContext, cmd ManualCommand, op operation.Context) (ManualResult, error) {
	if err := s.validateMutation(); err != nil {
		return ManualResult{}, err
	}
	if !actor.PlayerID.Valid() || actor.SessionID.UUID().IsZero() || actor.ContextID.UUID().IsZero() || op.ID.IsZero() || op.StartedAt.IsZero() || cmd.Target.validate() != nil || cmd.Method < 1 || cmd.Method > 3 {
		return ManualResult{}, ErrPracticeAdmission
	}

	id := practiceReceiptIdentity(actor.PlayerID, cmd.Target, "manual", op)
	fp, err := manualFingerprint(cmd)
	if err != nil {
		return ManualResult{}, err
	}
	if got, ok, err := findReceipt(ctx, s.Deps.ReceiptRead, id, fp); err != nil {
		return ManualResult{}, err
	} else if ok {
		return decodeManualReceipt(got, manualReceiptSchema)
	}

	bound, revision, err := s.bindCA63Operation(ctx, op)
	if err != nil {
		return ManualResult{}, err
	}
	var out ManualResult
	resolver := receipt.Resolver{Reader: s.Deps.ReceiptRead, Identity: id, Fingerprint: fp}
	res, err := s.Runner.Run(ctx, bound, practiceProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope tx.Scope) error {
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
			decoded, err := decodeManualReceipt(prior, manualReceiptSchema)
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
		originalVersion := root.StateVersion
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
		accounting, err := planManualAccounting(plannedRoot, method, advanced, lockRow, lockCount, facts, bound.StartedAt)
		if err != nil {
			return err
		}

		if accounting.TotalCost == 0 {
			if s.Deps.Level == nil {
				return ErrPracticeUnavailable
			}
			level, err := s.Deps.Level.PlayerLevelTx(txctx, scope.Tx, actor.PlayerID)
			if err != nil {
				return err
			}
			if level < facts.UnlockLevel {
				return appi5.ErrLevelRequirement
			}
		} else {
			if s.Deps.LevelAndScalar == nil {
				return ErrPracticeUnavailable
			}
			if _, _, err := s.Deps.LevelAndScalar.AuthorizeLevelAndDebitScalarTx(txctx, scope.Tx, actor.PlayerID, facts.UnlockLevel, accounting.CurrencyKey, accounting.TotalCost, bound.StartedAt.UTC()); err != nil {
				return err
			}
		}

		// Entropy is drawn only after admission/level/cost authorization. Any I5
		// write above is still inside this caller-owned transaction and rolls back
		// if the pure policy layer unexpectedly rejects. Transaction retry count
		// never enters RollPracticeV1.
		roll, err := RollPracticeV1(bound, cmd.Method, current, cmd.Locks, 0)
		if err != nil {
			return err
		}
		nextAttrs, err := addEffective(current, roll.Effective)
		if err != nil {
			return err
		}

		finalRoot := accounting.NextRoot
		finalRoot.StateVersion = originalVersion + 1
		finalRoot.UpdatedAt = bound.StartedAt.UTC()
		if err := finalRoot.Validate(); err != nil {
			return err
		}
		if err := s.Store.SaveAccountingTx(txctx, scope.Tx, finalRoot, originalVersion); err != nil {
			return err
		}
		proposal := Proposal{
			PlayerID:                  actor.PlayerID,
			SessionID:                 actor.SessionID,
			ActorID:                   cmd.Target.ActorID,
			ActorStateVersion:         actorVersion,
			Proposed:                  nextAttrs,
			GenerationOperationID:     bound.ID,
			GenerationContextID:       actor.ContextID,
			GenerationKind:            PendingManual,
			GenerationContentRevision: revision,
			GenerationPolicyRefs:      bound.Policies,
			CreatedAt:                 bound.StartedAt.UTC(),
			UpdatedAt:                 bound.StartedAt.UTC(),
		}
		if err := proposal.Validate(); err != nil {
			return err
		}
		if err := s.upsertProposalTx(txctx, scope.Tx, cmd.Target, proposal); err != nil {
			return err
		}
		out = ManualResult{Info: rootInfo(finalRoot), AddAttr: PracticeDelta(roll.Effective)}
		payload := manualReceiptResult{Info: out.Info, AddAttr: out.AddAttr, ContentRevision: revision, RollPolicy: RollPolicyV1}
		return putPracticeReceipt(txctx, s.Deps.Receipts, scope.Tx, actor, bound, id, fp, manualReceiptSchema, payload)
	})
	if err != nil {
		return ManualResult{}, err
	}
	if res.Reconciled && res.Evidence != nil {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			return decodeManualReceipt(r, manualReceiptSchema)
		}
	}
	if out.AddAttr.Validate() != nil {
		return ManualResult{}, fmt.Errorf("character practice: missing terminal manual result")
	}
	return out, nil
}

// Compile-time assertion keeps the delta/absolute distinction visible where
// these arrays intentionally have the same representation.
var _ [3]int64 = PracticeDelta(character.PracticeAttrs{})
