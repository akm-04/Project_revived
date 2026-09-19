package characterpractice

import (
	"context"
	"errors"
	"fmt"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Service) validateSave() error {
	d := s.Deps
	if s.Runner.DB == nil || s.Store == nil || d.Fencer == nil || d.HeroOwner == nil || d.PetOwner == nil || d.Receipts == nil || d.ReceiptRead == nil {
		return ErrPracticeUnavailable
	}
	return nil
}

func (s Service) Save(ctx context.Context, actor identity.ActorContext, target Target, op operation.Context) (SaveResult, error) {
	if err := s.validateSave(); err != nil {
		return SaveResult{}, err
	}
	if !actor.PlayerID.Valid() || actor.SessionID.UUID().IsZero() || actor.ContextID.UUID().IsZero() || op.ID.IsZero() || op.StartedAt.IsZero() || target.validate() != nil {
		return SaveResult{}, ErrPracticeAdmission
	}
	id := practiceReceiptIdentity(actor.PlayerID, target, "save", op)
	fp, err := actorFingerprint(target)
	if err != nil {
		return SaveResult{}, err
	}
	if got, ok, err := findReceipt(ctx, s.Deps.ReceiptRead, id, fp); err != nil {
		return SaveResult{}, err
	} else if ok {
		return decodeSaveReceipt(got)
	}

	var out SaveResult
	resolver := receipt.Resolver{Reader: s.Deps.ReceiptRead, Identity: id, Fingerprint: fp}
	res, err := s.Runner.Run(ctx, op, practiceProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Deps.Fencer.FenceActorTx(txctx, scope.Tx, actor, op.StartedAt); err != nil {
			return err
		}
		_, _, actorVersion, err := s.lockTarget(txctx, scope.Tx, actor.PlayerID, target)
		if err != nil {
			return err
		}
		if prior, ok, err := findReceiptTx(txctx, s.Deps.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			decoded, err := decodeSaveReceipt(prior)
			if err != nil {
				return err
			}
			out = decoded
			return nil
		}

		proposal, err := s.lockProposalTx(txctx, scope.Tx, actor.PlayerID, actor.SessionID, target)
		if err != nil {
			return err
		}
		if proposal.Validate() != nil || proposal.PlayerID != actor.PlayerID || proposal.SessionID != actor.SessionID || proposal.ActorID != target.ActorID {
			return ErrCandidateMissing
		}
		if proposal.ActorStateVersion != actorVersion {
			return ErrActorStaleVersion
		}
		if err := s.applyPracticeTx(txctx, scope.Tx, actor.PlayerID, target, actorVersion, proposal.Proposed, op.StartedAt.UTC()); err != nil {
			return err
		}
		if err := s.deleteProposalTx(txctx, scope.Tx, actor.PlayerID, actor.SessionID, target); err != nil {
			return err
		}
		out = SaveResult{PracticeAttr: proposal.Proposed}
		return putPracticeReceipt(txctx, s.Deps.Receipts, scope.Tx, actor, op, id, fp, saveReceiptSchema, saveReceiptResult{PracticeAttr: proposal.Proposed})
	})
	if err != nil {
		return SaveResult{}, err
	}
	if res.Reconciled && res.Evidence != nil {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			return decodeSaveReceipt(r)
		}
	}
	if out.PracticeAttr.Validate() != nil {
		return SaveResult{}, errors.New("character practice: missing terminal save result")
	}
	return out, nil
}

func ticketDelta(current character.PracticeAttrs, add character.PracticeAttrs) (PracticeDelta, character.PracticeAttrs, error) {
	if current.Validate() != nil || add.Validate() != nil {
		return PracticeDelta{}, character.PracticeAttrs{}, errors.New("character practice: invalid ticket attributes")
	}
	var delta PracticeDelta
	var next character.PracticeAttrs
	for i := range 3 {
		if add[i] != 1 {
			return PracticeDelta{}, character.PracticeAttrs{}, errors.New("character practice: ticket content must be source-qualified +1/+1/+1")
		}
		delta[i] = boundedPracticeDelta(current[i], add[i])
		next[i] = current[i] + delta[i]
	}
	if delta.Validate() != nil || next.Validate() != nil {
		return PracticeDelta{}, character.PracticeAttrs{}, errors.New("character practice: invalid bounded ticket result")
	}
	return delta, next, nil
}

func (s Service) Ticket(ctx context.Context, actor identity.ActorContext, target Target, op operation.Context) (ManualResult, error) {
	if err := s.validateMutation(); err != nil {
		return ManualResult{}, err
	}
	if s.Deps.TicketDebit == nil {
		return ManualResult{}, ErrPracticeUnavailable
	}
	if !actor.PlayerID.Valid() || actor.SessionID.UUID().IsZero() || actor.ContextID.UUID().IsZero() || op.ID.IsZero() || op.StartedAt.IsZero() || target.validate() != nil {
		return ManualResult{}, ErrPracticeAdmission
	}
	id := practiceReceiptIdentity(actor.PlayerID, target, "ticket", op)
	fp, err := actorFingerprint(target)
	if err != nil {
		return ManualResult{}, err
	}
	if got, ok, err := findReceipt(ctx, s.Deps.ReceiptRead, id, fp); err != nil {
		return ManualResult{}, err
	} else if ok {
		return decodeManualReceipt(got, ticketReceiptSchema)
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
		tableID, current, actorVersion, err := s.lockTarget(txctx, scope.Tx, actor.PlayerID, target)
		if err != nil {
			return err
		}
		if prior, ok, err := findReceiptTx(txctx, s.Deps.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			decoded, err := decodeManualReceipt(prior, ticketReceiptSchema)
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
		plannedRoot, generated, err := s.planDailyGenerationTx(txctx, scope.Tx, root, desired, bound, revision)
		if err != nil {
			return err
		}
		awakened, err := s.actorAwakenedTx(txctx, scope.Tx, revision, target, tableID)
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
		prepared, err := s.Deps.TicketDebit.PrepareLevelAndStackDebitTx(txctx, scope.Tx, actor.PlayerID, appi5.LevelStackDebitRequest{ItemID: facts.TicketItemID, Count: 1, MinPlayerLevel: facts.UnlockLevel}, bound)
		if err != nil {
			return err
		}
		delta, proposedAttrs, err := ticketDelta(current, facts.TicketAdd)
		if err != nil {
			return err
		}

		proposal := Proposal{
			PlayerID:                  actor.PlayerID,
			SessionID:                 actor.SessionID,
			ActorID:                   target.ActorID,
			ActorStateVersion:         actorVersion,
			Proposed:                  proposedAttrs,
			GenerationOperationID:     bound.ID,
			GenerationContextID:       actor.ContextID,
			GenerationKind:            PendingTicket,
			GenerationContentRevision: revision,
			GenerationPolicyRefs:      bound.Policies,
			CreatedAt:                 bound.StartedAt.UTC(),
			UpdatedAt:                 bound.StartedAt.UTC(),
		}
		if err := proposal.Validate(); err != nil {
			return err
		}
		if _, err := s.Deps.TicketDebit.ApplyLevelAndStackDebitTx(txctx, scope.Tx, prepared); err != nil {
			return err
		}
		if generated {
			plannedRoot.StateVersion = originalVersion + 1
			plannedRoot.UpdatedAt = bound.StartedAt.UTC()
			if err := s.Store.SaveAccountingTx(txctx, scope.Tx, plannedRoot, originalVersion); err != nil {
				return err
			}
		}
		if err := s.upsertProposalTx(txctx, scope.Tx, target, proposal); err != nil {
			return err
		}
		out = ManualResult{Info: rootInfo(plannedRoot), AddAttr: delta}
		payload := ticketReceiptResult{Info: out.Info, AddAttr: delta, ContentRevision: revision, RollPolicy: RollPolicyV1}
		return putPracticeReceipt(txctx, s.Deps.Receipts, scope.Tx, actor, bound, id, fp, ticketReceiptSchema, payload)
	})
	if err != nil {
		return ManualResult{}, err
	}
	if res.Reconciled && res.Evidence != nil {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			return decodeManualReceipt(r, ticketReceiptSchema)
		}
	}
	if out.AddAttr.Validate() != nil {
		return ManualResult{}, fmt.Errorf("character practice: missing terminal ticket result")
	}
	return out, nil
}
