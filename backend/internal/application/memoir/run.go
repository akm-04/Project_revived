package memoir

import (
	"context"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"strconv"
	"time"
)

type timedReceipt struct{ receipt.Resolver }

func (resolver timedReceipt) ResolveTimed(ctx context.Context, request generation.TimedResolutionRequest) (tx.Resolution, error) {
	return resolver.Resolve(ctx, tx.ResolutionRequest{Operation: request.Operation.Operation(), CommitError: request.CommitError, Attempt: request.Attempt})
}

type scope struct {
	timed    generation.TimedScope
	catalog  memoir.Catalog
	revision string
	heroes   []int64
	pets     []int64
}

func (mode Mode) pin(ctx context.Context, operationContext operation.Context) (operation.Context, error) {
	if mode.Timed.Runner.DB == nil || mode.Fresh == nil || mode.Store == nil || mode.Content == nil || mode.Fence == nil || mode.Functions == nil || mode.Heroes == nil || mode.HeroLocks == nil || mode.Roster == nil || mode.Pets == nil || mode.Opponents == nil || mode.Combat == nil || mode.Grants == nil || mode.Costs == nil || mode.Energy == nil || mode.Exchange == nil || mode.Receipts == nil || mode.ReceiptRead == nil {
		return operationContext, memoir.ErrUnavailable
	}
	if _, found := operationContext.Policies.Get("content"); found {
		return operationContext, nil
	}
	revision, err := mode.Content.ActiveRevision(ctx, mode.Fresh)
	if err != nil {
		return operationContext, err
	}
	operationContext.Policies, err = policy.NewSet(append(operationContext.Policies.Refs(), policy.Ref{Name: "content", Version: revision})...)
	return operationContext, err
}
func (mode Mode) run(ctx context.Context, actor identity.ActorContext, name string, request any, operationContext operation.Context, apply func(context.Context, scope, *memoir.State) (map[string]any, error)) (map[string]any, error) {
	operationContext, err := mode.pin(ctx, operationContext)
	if err != nil {
		return nil, err
	}
	identityKey := receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(actor.PlayerID), Domain: "memoir", Operation: name, SemanticKey: operationContext.ID.String()}
	if name == "player_finish" {
		attempt, valid := request.(string)
		if !valid || attempt == "" {
			return nil, memoir.ErrInvalid
		}
		identityKey.SemanticKey = attempt
	}
	fingerprint, err := receipt.FingerprintRequest(request)
	if err != nil {
		return nil, err
	}
	profile := tx.Profile{Name: "memoir", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 90 * time.Second}
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
		eligibility, present, err := mode.Functions.ReadFunctionEligibilityTx(ctx, timed.Tx, actor.PlayerID, 64)
		if err != nil {
			return err
		}
		if !present || at.Before(eligibility.EligibleAt) {
			return memoir.ErrRefused
		}
		current := scope{timed: timed}
		needsRoster := name == "start" || name == "start_fight" || name == "player_start" || name == "revive"
		if needsRoster {
			if err = mode.Heroes.LockStoryRosterTx(ctx, timed.Tx, actor.PlayerID); err != nil {
				return err
			}
			current.heroes, current.pets, err = mode.roster(ctx, timed, actor)
			if err != nil {
				return err
			}
			for _, identifier := range current.heroes {
				if _, err = mode.HeroLocks.LockHeroByPartnerIDTx(ctx, timed.Tx, actor.PlayerID, identifier); err != nil {
					return err
				}
			}
		}
		state, err := mode.Store.LockTx(ctx, timed.Tx, actor.PlayerID, at)
		if err != nil {
			return err
		}
		state.Initialize()
		if err = state.Validate(); err != nil {
			return err
		}
		current.revision, _ = operationContext.Policies.Get("content")
		if state.Active() {
			current.revision = state.Revision
		}
		current.catalog, err = mode.Content.MemoirCatalogTx(ctx, timed.Tx, current.revision)
		if err != nil {
			return err
		}
		response, err = apply(ctx, current, &state)
		if err != nil {
			return err
		}
		if err = mode.Store.SaveTx(ctx, timed.Tx, actor.PlayerID, state, at); err != nil {
			return err
		}
		balances, functions := changes.Recorded(ctx)
		if len(balances) > 0 {
			response["economy_"] = balances
		}
		if len(functions) > 0 {
			response["new_funcs_"] = functions
		}
		payload, err := json.Marshal(response)
		if err != nil {
			return err
		}
		record, err := receipt.New(timed.Operation.Operation(), identityKey, "I9_6C_MEMOIR", "gxb.memoir.result.v1", payload, fingerprint)
		if err != nil {
			return err
		}
		record.PolicyVersion, record.ActorAccountUID, record.ContextID = memoir.PolicyID, string(actor.AccountUID), actor.ContextID.UUID()
		_, err = mode.Receipts.PutTx(ctx, timed.Tx, record)
		return err
	})
	if err == nil && resolution.Reconciled {
		record, present := resolution.Evidence.(receipt.Receipt)
		if !present {
			return nil, memoir.ErrUnavailable
		}
		err = json.Unmarshal(record.ResultPayload, &response)
	}
	return response, err
}
func (mode Mode) roster(ctx context.Context, timed generation.TimedScope, actor identity.ActorContext) ([]int64, []int64, error) {
	detail := map[string]any{}
	if err := mode.Roster.OverlayMID1(ctx, timed.Tx, actor, false, timed.Operation.DecisionAt(), detail); err != nil {
		return nil, nil, err
	}
	body, present := detail["49"].(map[string]any)
	if !present {
		return nil, nil, memoir.ErrUnavailable
	}
	rows, present := body["heros"].(map[string]any)
	if !present {
		return nil, nil, memoir.ErrUnavailable
	}
	heroes := []int64{}
	for key := range rows {
		identifier, err := strconv.ParseInt(key, 10, 64)
		if err != nil || identifier <= 0 {
			return nil, nil, memoir.ErrUnavailable
		}
		heroes = append(heroes, identifier)
	}
	sort.Slice(heroes, func(left, right int) bool { return heroes[left] < heroes[right] })
	if err := mode.Pets.OverlayMID1(ctx, timed.Tx, actor, false, timed.Operation.DecisionAt(), detail); err != nil {
		return nil, nil, err
	}
	pets := []int64{}
	if body, present := detail["780"].(map[string]any); present {
		raw, err := json.Marshal(body["pets"])
		if err != nil {
			return nil, nil, err
		}
		var rows []struct {
			Identity int64 `json:"pet_id"`
		}
		if string(raw) != "null" {
			if err = json.Unmarshal(raw, &rows); err != nil {
				return nil, nil, err
			}
		}
		for _, row := range rows {
			if row.Identity <= 0 {
				return nil, nil, memoir.ErrUnavailable
			}
			pets = append(pets, row.Identity)
		}
	}
	sort.Slice(pets, func(left, right int) bool { return pets[left] < pets[right] })
	return heroes, pets, nil
}
