package i5

import (
	"context"
	"encoding/hex"
	"errors"
	"strings"

	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const contentPolicyRefName = "content"

var ErrContentRevisionConflict = errors.New("operation content revision conflict")

func validateContentRevision(revision string) error {
	if len(revision) != 64 || strings.ToLower(revision) != revision {
		return errors.New("invalid content revision")
	}
	raw, err := hex.DecodeString(revision)
	if err != nil || len(raw) != 32 {
		return errors.New("invalid content revision")
	}
	return nil
}

func bindContentRevision(op operation.Context, revision string) (operation.Context, error) {
	if err := validateContentRevision(revision); err != nil {
		return operation.Context{}, err
	}
	if current, ok := op.Policies.Get(contentPolicyRefName); ok {
		if current != revision {
			return operation.Context{}, ErrContentRevisionConflict
		}
		return op, nil
	}
	refs := op.Policies.Refs()
	refs = append(refs, policy.Ref{Name: contentPolicyRefName, Version: revision})
	set, err := policy.NewSet(refs...)
	if err != nil {
		return operation.Context{}, err
	}
	op.Policies = set
	return op, nil
}

func requireContentRevision(op operation.Context) (string, error) {
	revision, ok := op.Policies.Get(contentPolicyRefName)
	if !ok {
		return "", errors.New("operation content revision is not bound")
	}
	if err := validateContentRevision(revision); err != nil {
		return "", err
	}
	return revision, nil
}

func (s Service) bindActiveContentTx(ctx context.Context, q tx.Queryer, op operation.Context) (operation.Context, error) {
	if revision, ok := op.Policies.Get(contentPolicyRefName); ok {
		return bindContentRevision(op, revision)
	}
	if s.Content == nil {
		return operation.Context{}, errors.New("I5 content runtime unavailable")
	}
	revision, err := s.Content.ActiveRevision(ctx, q)
	if err != nil {
		return operation.Context{}, err
	}
	return bindContentRevision(op, revision)
}

// prepareGrantOperationTx preserves replay-first behavior: an existing v2 or
// reconstructable legacy v1 Grant receipt is sufficient to replay without
// consulting today's active content. Only genuinely new settlement binds the
// currently active immutable revision.
func (s Service) prepareGrantOperationTx(ctx context.Context, q tx.Queryer, plan grant.Plan, op operation.Context) (operation.Context, error) {
	fp, err := receiptFingerprintForGrant(plan)
	if err != nil {
		return operation.Context{}, err
	}
	if _, ok, err := s.findGrantReceiptTx(ctx, q, plan, fp); err != nil {
		return operation.Context{}, err
	} else if ok {
		return op, nil
	}
	return s.bindActiveContentTx(ctx, q, op)
}
