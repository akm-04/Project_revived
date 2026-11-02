package dodgeball

import (
	"context"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/dodgeball"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"time"
)

type timedReceipt struct{ receipt.Resolver }

func (resolver timedReceipt) ResolveTimed(ctx context.Context, request generation.TimedResolutionRequest) (tx.Resolution, error) {
	return resolver.Resolve(ctx, tx.ResolutionRequest{Operation: request.Operation.Operation(), CommitError: request.CommitError, Attempt: request.Attempt})
}

type scope struct {
	timed    generation.TimedScope
	catalog  dodgeball.Catalog
	revision string
	states   map[identity.PlayerID]*dodgeball.State
}

func (mode Mode) pin(ctx context.Context, operationContext operation.Context) (operation.Context, error) {
	if mode.Fresh == nil || mode.Store == nil || mode.Content == nil || mode.Fence == nil || mode.Functions == nil || mode.Players == nil || mode.Privacy == nil || mode.Friends == nil || mode.Presentation == nil || mode.Combat == nil || mode.Values == nil || mode.Costs == nil || mode.Mail == nil || mode.Delivery == nil || mode.Receipts == nil || mode.ReceiptRead == nil {
		return operationContext, dodgeball.ErrUnavailable
	}
	if _, present := operationContext.Policies.Get("content"); present {
		return operationContext, nil
	}
	revision, err := mode.Content.ActiveRevision(ctx, mode.Fresh)
	if err != nil {
		return operationContext, err
	}
	operationContext.Policies, err = policy.NewSet(append(operationContext.Policies.Refs(), policy.Ref{Name: "content", Version: revision})...)
	return operationContext, err
}

func (mode Mode) run(ctx context.Context, actor identity.ActorContext, name string, request any, invited identity.PlayerID, operationContext operation.Context, apply func(context.Context, scope) (map[string]any, error)) (map[string]any, error) {
	operationContext, err := mode.pin(ctx, operationContext)
	if err != nil {
		return nil, err
	}
	identityKey := receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(actor.PlayerID), Domain: "dodgeball", Operation: name, SemanticKey: operationContext.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(request)
	if err != nil {
		return nil, err
	}
	profile := tx.Profile{Name: "dodgeball", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 90 * time.Second}
	retry := tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
	var response map[string]any
	_, resolution, err := mode.Timed.Run(ctx, operationContext, profile, tx.Options{Isolation: tx.Serializable}, retry, timedReceipt{receipt.Resolver{Reader: mode.ReceiptRead, Identity: identityKey, Fingerprint: fingerprint}}, func(ctx context.Context, timed generation.TimedScope) error {
		at := timed.Operation.DecisionAt()
		if err := mode.Fence.FenceActorTx(ctx, timed.Tx, actor, at); err != nil {
			return err
		}
		prior, present, err := mode.Receipts.FindTx(ctx, timed.Tx, identityKey)
		if err != nil {
			return err
		}
		if present {
			if prior.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: identityKey}
			}
			return json.Unmarshal(prior.ResultPayload, &response)
		}
		eligibility, present, err := mode.Functions.ReadFunctionEligibilityTx(ctx, timed.Tx, actor.PlayerID, 95)
		if err != nil {
			return err
		}
		if !present || at.Before(eligibility.EligibleAt) {
			return dodgeball.ErrRefused
		}
		// SERIALIZABLE retries a concurrent change of the pre-read participant set.
		previous, _, err := mode.Store.ReadTx(ctx, timed.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		participants := []identity.PlayerID{actor.PlayerID}
		friend := invited
		if name == "result" && previous.Pending != nil {
			friend = identity.PlayerID(previous.Pending.Friend)
		}
		if friend != 0 {
			if friend == actor.PlayerID || !friend.Valid() || int64(friend)/100000 != int64(actor.LogicalServerID) {
				return dodgeball.ErrRefused
			}
			participants = append(participants, friend)
		}
		sort.Slice(participants, func(left, right int) bool { return participants[left] < participants[right] })
		if _, err = mode.Players.LockPlayerRootsTx(ctx, timed.Tx, actor.LogicalServerID, participants); err != nil {
			return err
		}
		if name == "enter" && friend != 0 {
			privacy, err := mode.Privacy.PrepareFriendDMPrivacyTx(ctx, timed.Tx, friend, []identity.PlayerID{actor.PlayerID})
			if err != nil {
				return err
			}
			if !privacy.RecipientRootPresent || !privacy.BySender[actor.PlayerID].Eligible {
				return dodgeball.ErrRefused
			}
		}
		states := map[identity.PlayerID]*dodgeball.State{}
		for _, player := range participants {
			state, err := mode.Store.LockTx(ctx, timed.Tx, player, at)
			if err != nil {
				return err
			}
			if err = state.Normalize(at); err != nil {
				return err
			}
			states[player] = &state
		}
		revision, _ := operationContext.Policies.Get("content")
		pending := states[actor.PlayerID].Pending
		if (name == "start" || name == "result") && pending != nil {
			revision = pending.Revision
		}
		catalog, err := mode.Content.DodgeballCatalogTx(ctx, timed.Tx, revision)
		if err != nil {
			return err
		}
		response, err = apply(ctx, scope{timed: timed, catalog: catalog, revision: revision, states: states})
		if err != nil {
			return err
		}
		balances, functions := changes.Recorded(ctx)
		if len(balances) > 0 {
			response["economy_"] = balances
		}
		if len(functions) > 0 {
			response["new_funcs_"] = functions
		}
		for _, player := range participants {
			if err = mode.Store.SaveTx(ctx, timed.Tx, player, *states[player], at); err != nil {
				return err
			}
		}
		payload, err := json.Marshal(response)
		if err != nil {
			return err
		}
		record, err := receipt.New(timed.Operation.Operation(), identityKey, "I9_6B_DODGEBALL", "gxb.dodgeball.result.v1", payload, fingerprint)
		if err != nil {
			return err
		}
		record.PolicyVersion, record.ActorAccountUID, record.ContextID = dodgeball.PolicyID, string(actor.AccountUID), actor.ContextID.UUID()
		_, err = mode.Receipts.PutTx(ctx, timed.Tx, record)
		return err
	})
	if err == nil && resolution.Reconciled {
		record, present := resolution.Evidence.(receipt.Receipt)
		if !present {
			return nil, dodgeball.ErrUnavailable
		}
		err = json.Unmarshal(record.ResultPayload, &response)
	}
	return response, err
}
