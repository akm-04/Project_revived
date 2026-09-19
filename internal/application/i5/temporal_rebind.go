package i5

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrTemporalRebindStateWithoutReceipt = errors.New("temporal row is already immutable without matching migration receipt")

// TemporalRebindResult is the durable result of an explicit legacy temporal
// migration. It is intentionally separate from ordinary Grant settlement:
// activation alone never migrates persisted temporal policy identity.
type TemporalRebindResult struct {
	ReceiptID             string `json:"receipt_id"`
	ResourceKey           string `json:"resource_key"`
	BeforePolicyVersion   string `json:"before_policy_version"`
	AfterPolicyVersion    string `json:"after_policy_version"`
	TargetContentRevision string `json:"target_content_revision"`
	BeforeAmount          int64  `json:"before_amount"`
	AfterAmount           int64  `json:"after_amount"`
	BeforeAnchorUnix      int64  `json:"before_anchor_unix"`
	AfterAnchorUnix       int64  `json:"after_anchor_unix"`
	CompatibilityPolicy   string `json:"compatibility_policy"`
}

func temporalAnchorUnix(t *time.Time) int64 {
	if t == nil {
		return 0
	}
	return t.UTC().Unix()
}

// RebindLegacyTemporal explicitly migrates one legacy temporal row to an exact
// immutable R5 content revision. The target revision is caller-supplied and
// becomes part of semantic identity; this command never consults the active
// content pointer and therefore cannot silently follow an activation change.
func (s Service) RebindLegacyTemporal(ctx context.Context, actor identity.ActorContext, resourceKey, targetRevision string, op operation.Context) (TemporalRebindResult, error) {
	if err := s.validate(); err != nil {
		return TemporalRebindResult{}, err
	}
	if !actor.PlayerID.Valid() || resourceKey == "" || targetRevision == "" || op.StartedAt.IsZero() {
		return TemporalRebindResult{}, errors.New("invalid temporal rebind command")
	}
	boundOp, err := bindContentRevision(op, targetRevision)
	if err != nil {
		return TemporalRebindResult{}, err
	}
	semantic := "r5:temporal-rebind:v1:" + resourceKey + ":" + targetRevision
	id := receipt.Identity{
		OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10),
		Domain: "temporal", Operation: "rebind", SemanticKey: semantic,
	}
	fp, err := receipt.FingerprintRequest(map[string]any{"resource_key": resourceKey, "target_content_revision": targetRevision})
	if err != nil {
		return TemporalRebindResult{}, err
	}
	var out TemporalRebindResult
	resolver := receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}
	res, err := s.Runner.Run(ctx, boundOp, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, resolver, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Store.FenceActorTx(txctx, scope.Tx, actor, op.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			return decodeTemporalRebindReceipt(prior, &out)
		}

		line := grant.Line{Kind: grant.Temporal, ResourceKey: resourceKey, Amount: 1}
		targetResource, err := s.Content.ResolveResourceTx(txctx, scope.Tx, targetRevision, line)
		if err != nil {
			return err
		}
		if targetResource.Descriptor == nil || targetResource.Descriptor.Revision != targetRevision {
			return economy.ErrInvalidTemporalPolicy
		}

		// Frozen R5 ordering: owner 700, optional progression 710, temporal 721.
		if err := s.Store.LockEconomyOwnerTx(txctx, scope.Tx, actor.PlayerID); err != nil {
			return err
		}
		var progressionPolicy player.ProgressionPolicy
		level := int64(1)
		if targetResource.Descriptor.CapRule == "PLAYER_LEVEL_ENERGY" {
			progressionPolicy, err = s.Content.ResolveProgressionPolicyTx(txctx, scope.Tx, targetRevision)
			if err != nil {
				return err
			}
			prog, err := s.Store.LockProgressionTx(txctx, scope.Tx, actor.PlayerID)
			if err != nil {
				return err
			}
			if err := progressionPolicy.ValidateState(prog); err != nil {
				return err
			}
			level = prog.Level
		}
		newPolicy, _, err := ResolveTemporalPolicyTx(txctx, scope.Tx, actor.PlayerID, *targetResource.Descriptor, progressionPolicy, level, op.StartedAt.UTC(), s.Privileges)
		if err != nil {
			return err
		}

		state, exists, err := s.Store.LockTemporalTx(txctx, scope.Tx, actor.PlayerID, resourceKey)
		if err != nil {
			return err
		}
		if !exists {
			return economy.ErrUnknownResource
		}
		if state.ContentRevision != "" {
			if state.ContentRevision == targetRevision && state.PolicyVersion == newPolicy.Version {
				return ErrTemporalRebindStateWithoutReceipt
			}
			return ErrContentRevisionConflict
		}
		legacyResource, err := s.Store.ResolveLegacyTemporalPolicyTx(txctx, scope.Tx, resourceKey, state.PolicyVersion)
		if err != nil || legacyResource.Temporal == nil {
			if err == nil {
				err = economy.ErrInvalidTemporalPolicy
			}
			return err
		}
		before := state
		after, err := state.RebindLegacyPolicy(targetRevision, op.StartedAt.UTC(), *legacyResource.Temporal, newPolicy)
		if err != nil {
			return err
		}
		if err := s.Store.RebindTemporalTx(txctx, scope.Tx, after, before.StateVersion); err != nil {
			return err
		}

		rr, err := receipt.New(boundOp, id, "I5_TEMPORAL_REBIND", "gxb.i5.temporal-rebind.v1", json.RawMessage(`{"pending":true}`), fp)
		if err != nil {
			return err
		}
		out = TemporalRebindResult{
			ReceiptID: rr.ID.String(), ResourceKey: resourceKey,
			BeforePolicyVersion: before.PolicyVersion, AfterPolicyVersion: after.PolicyVersion,
			TargetContentRevision: targetRevision,
			BeforeAmount:          before.StoredAmount, AfterAmount: after.StoredAmount,
			BeforeAnchorUnix: temporalAnchorUnix(before.RegenAnchorAt), AfterAnchorUnix: temporalAnchorUnix(after.RegenAnchorAt),
			CompatibilityPolicy: "r5.temporal-rebind.v1",
		}
		raw, err := json.Marshal(out)
		if err != nil {
			return err
		}
		rr.ResultPayload = raw
		rr.PolicyVersion = after.PolicyVersion
		rr.ActorAccountUID = string(actor.AccountUID)
		rr.ContextID = actor.ContextID.UUID()
		put, err := s.Receipts.PutTx(txctx, scope.Tx, rr)
		if err != nil {
			return err
		}
		if !put.Inserted {
			return decodeTemporalRebindReceipt(put.Receipt, &out)
		}
		return nil
	})
	if err != nil {
		return TemporalRebindResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			if err := decodeTemporalRebindReceipt(r, &out); err != nil {
				return TemporalRebindResult{}, err
			}
		}
	}
	return out, nil
}

func decodeTemporalRebindReceipt(r receipt.Receipt, out *TemporalRebindResult) error {
	if r.ResultSchema != "gxb.i5.temporal-rebind.v1" {
		return fmt.Errorf("unsupported temporal rebind receipt schema %q", r.ResultSchema)
	}
	return json.Unmarshal(r.ResultPayload, out)
}
