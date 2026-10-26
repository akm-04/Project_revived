package i5

import (
	"context"
	"encoding/json"
	"fmt"
	"slices"

	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type MissionActivityCatalog interface {
	MissionActivityCatalogTx(context.Context, tx.Queryer, string) (*objective.ActivityCatalog, error)
}

func claimFlags(claimed []int64, size int) []int64 {
	flags := make([]int64, size)
	for _, id := range claimed {
		if id >= 1 && id <= int64(size) {
			flags[id-1] = 1
		}
	}
	return flags
}

func (s Service) ClaimActivityChest(ctx context.Context, actor identity.ActorContext, period string, index int64, op operation.Context) (map[string]any, error) {
	limit := int64(5)
	if period == "WEEK" {
		limit = 2
	} else if period != "DAY" {
		return nil, ErrMissionRefused
	}
	if index < 1 || index > limit || s.Missions == nil || s.Missions.Activity == nil {
		return nil, ErrMissionRefused
	}
	timed, err := s.missionOperation(ctx, op)
	if err != nil {
		return nil, err
	}
	scope, err := missionScope(actor.PlayerID, timed)
	if err != nil {
		return nil, err
	}
	initial, err := objective.NewMissionRoot(actor.PlayerID, scope.DecisionAt)
	if err != nil {
		return nil, err
	}
	occurrence := initial.Day
	if period == "WEEK" {
		occurrence = initial.Week
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(actor.PlayerID), Domain: "objective", Operation: "activity-claim", SemanticKey: fmt.Sprintf("%s:%d:%d", period, index, occurrence)}
	fingerprint, _ := receipt.FingerprintRequest(map[string]any{"period": period, "index": index, "occurrence": occurrence})
	var out ObjectiveClaimResult
	replay := false
	var view MissionView
	result, err := s.Runner.Run(ctx, timed.Operation(), s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fingerprint}, func(ctx context.Context, tr tx.Scope) error {
		if err := s.Store.FenceActorTx(ctx, tr.Tx, actor, scope.DecisionAt); err != nil {
			return err
		}
		var err error
		view, err = s.Missions.MaterializeTx(ctx, tr.Tx, scope)
		if err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(ctx, tr.Tx, id); err != nil {
			return err
		} else if ok {
			if prior.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: id}
			}
			replay = true
			return json.Unmarshal(prior.ResultPayload, &out)
		}
		if view.Activity == nil {
			return ErrMissionRefused
		}
		catalog := *view.Activity
		progress, err := s.Store.ReadProgressionTx(ctx, tr.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		rule, err := s.Content.ResolveProgressionPolicyTx(ctx, tr.Tx, scope.ContentRevision)
		if err != nil {
			return err
		}
		privilege, err := s.Privileges.SnapshotTx(ctx, tr.Tx, actor.PlayerID, scope.DecisionAt)
		if err != nil {
			return err
		}
		plan, medal, err := catalog.Reward(period, index, progress.Level, rule.MaxLevel(), privilege.VIPLevel)
		if err != nil {
			return err
		}
		points, claimed := view.Root.DayHuoyue, view.Root.DayAward
		if period == "WEEK" {
			points, claimed = view.Root.WeekHuoyue, view.Root.WeekAward
		}
		if points < medal || slices.Contains(claimed, index) {
			return ErrMissionRefused
		}
		plan.PlayerID = actor.PlayerID
		plan.Source = grant.SourceIdentity{Domain: "objective", Operation: "activity-claim", BusinessKey: fmt.Sprintf("%s:%d", period, index), Occurrence: fmt.Sprint(occurrence), PolicyVersion: "I9_ACTIVITY_CHESTS_V1"}
		granted, err := s.SettleGrantTx(ctx, tr.Tx, actor, plan, timed.Operation(), GrantTxOptions{AllowOverflowMail: true})
		if err != nil {
			return err
		}
		root := view.Root
		if period == "DAY" {
			root.DayAward = append(slices.Clone(root.DayAward), index)
		} else {
			root.WeekAward = append(slices.Clone(root.WeekAward), index)
		}
		root.StateVersion++
		if err := s.Missions.Store.SaveMissionRootTx(ctx, tr.Tx, root, view.Root.StateVersion); err != nil {
			return err
		}
		view, err = s.Missions.MaterializeTx(ctx, tr.Tx, scope)
		if err != nil {
			return err
		}
		changes.Missions(ctx, MissionProjection(view, scope.DecisionAt, 0))
		out = ObjectiveClaimResult{Awards: granted.Awards, Grant: &granted}
		raw, err := json.Marshal(out)
		if err != nil {
			return err
		}
		record, err := receipt.New(timed.Operation(), id, "I5_OBJECTIVE", "gxb.i5.activity-claim.v1", raw, fingerprint)
		if err != nil {
			return err
		}
		record.ActorAccountUID, record.ContextID = string(actor.AccountUID), actor.ContextID.UUID()
		_, err = s.Receipts.PutTx(ctx, tr.Tx, record)
		return err
	})
	if err != nil {
		return nil, err
	}
	if result.Reconciled {
		record, ok := result.Evidence.(receipt.Receipt)
		if !ok {
			return nil, ErrMissionRefused
		}
		if err = json.Unmarshal(record.ResultPayload, &out); err != nil {
			return nil, err
		}
		replay = true
	}
	// Committed recovery projects current root state without rerunning eligibility or rewards.
	_, err = s.Runner.Run(ctx, timed.Operation(), s.profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 2, RetryDefiniteAbort: true}, nil, func(ctx context.Context, tr tx.Scope) error {
		var err error
		view.Root, err = s.Missions.Store.ReadMissionRootTx(ctx, tr.Tx, actor.PlayerID)
		return err
	})
	if err != nil {
		return nil, err
	}
	if out.Grant == nil {
		return nil, ErrMissionRefused
	}
	projected, err := s.projectSettlement(ctx, actor, projectionGrants([]GrantResult{*out.Grant}, out.Awards), op, replay)
	if err != nil {
		return nil, err
	}
	body := map[string]any{"awards": StockRepresentableBulkAwards(out.Awards), "huoyue_info": map[string]any{"day_huoyue": view.Root.DayHuoyue, "week_huoyue": view.Root.WeekHuoyue, "day_award": claimFlags(view.Root.DayAward, 5), "week_award": claimFlags(view.Root.WeekAward, 2)}}
	if len(projected.Economy) > 0 {
		body["economy_"] = projected.Economy
	}
	if len(projected.NewFunctionIDs) > 0 {
		body["new_funcs_"] = projected.NewFunctionIDs
	}
	return body, nil
}
