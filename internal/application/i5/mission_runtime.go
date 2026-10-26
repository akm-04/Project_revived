package i5

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"slices"
	"strconv"
	"strings"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrMissionRefused = errors.New("mission claim refused")

func (s Service) missionOperation(ctx context.Context, op operation.Context) (gen.TimedOperation, error) {
	if s.Missions == nil || s.MissionTime == nil || s.MissionFresh == nil || s.Content == nil {
		return gen.TimedOperation{}, errors.New("mission runtime unavailable")
	}
	if _, ok := op.Policies.Get("content"); !ok {
		revision, err := s.Content.ActiveRevision(ctx, s.MissionFresh)
		if err != nil {
			return gen.TimedOperation{}, err
		}
		op, err = bindContentRevision(op, revision)
		if err != nil {
			return gen.TimedOperation{}, err
		}
	}
	return (gen.Binder{Time: s.MissionTime}).Bind(ctx, op)
}

func missionScope(pid identity.PlayerID, timed gen.TimedOperation) (MissionScope, error) {
	if err := timed.Validate(); err != nil {
		return MissionScope{}, err
	}
	revision, err := requireContentRevision(timed.Operation())
	return MissionScope{PlayerID: pid, ContentRevision: revision, DecisionAt: timed.DecisionAt()}, err
}

func (s Service) ReadMissions(ctx context.Context, actor identity.ActorContext, family objective.StockFamily, op operation.Context) (map[string]any, error) {
	timed, err := s.missionOperation(ctx, op)
	if err != nil {
		return nil, err
	}
	scope, err := missionScope(actor.PlayerID, timed)
	if err != nil {
		return nil, err
	}
	var body map[string]any
	_, err = s.Runner.Run(ctx, timed.Operation(), s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, tr tx.Scope) error {
		if err := s.Store.FenceActorTx(ctx, tr.Tx, actor, scope.DecisionAt); err != nil {
			return err
		}
		view, err := s.Missions.MaterializeTx(ctx, tr.Tx, scope)
		if err != nil {
			return err
		}
		body = MissionProjection(view, scope.DecisionAt, family)
		return nil
	})
	return body, err
}

func missionRow(instance objective.Instance) map[string]any {
	complete, reward := int64(0), int64(0)
	if instance.CompletedAt != nil {
		complete = 1
	}
	if instance.ClaimState == objective.Claimed {
		reward = 1
	}
	return map[string]any{"table_id": instance.ObjectiveID, "count": instance.Progress, "is_complete": complete, "is_reward": reward, "is_going": int64(1)}
}

func missionFamily(instance objective.Instance) objective.StockFamily {
	value, _ := strconv.ParseInt(strings.TrimPrefix(instance.ProgramID, "mission:"), 10, 64)
	return objective.StockFamily(value)
}

func missionEntitlement(id int64, definitions []objective.MissionDefinition) bool {
	for _, d := range definitions {
		if d.ObjectiveID == id {
			return d.Strategy == "TEMPORAL_ENTITLEMENT" && d.Presentation.Condition != 111 && d.Presentation.Condition != 118
		}
	}
	return false
}

func MissionProjection(view MissionView, at time.Time, family objective.StockFamily) map[string]any {
	byFamily := map[objective.StockFamily][]any{}
	partner := map[string]any{}
	partnerHooks := []any{}
	marks := map[int64]bool{}
	for _, instance := range view.Instances {
		if instance.ClaimState == objective.Claimed && !missionEntitlement(instance.ObjectiveID, view.Definitions) {
			continue
		}
		f := missionFamily(instance)
		if instance.CompletedAt != nil && instance.ClaimState != objective.Claimed {
			switch f {
			case objective.Daily:
				marks[2701] = true
			case objective.GrowMain:
				marks[2702] = true
			case objective.Story:
				marks[2704] = true
			case objective.Partner:
				marks[2706] = true
			}
		}
		if f == objective.Partner {
			key := strings.TrimPrefix(instance.GenerationID, "hero:")
			partnerHooks = append(partnerHooks, map[string]any{key: missionRow(instance)})
			rows, _ := partner[key].([]any)
			partner[key] = append(rows, missionRow(instance))
		} else {
			byFamily[f] = append(byFamily[f], missionRow(instance))
		}
	}
	list := func(f objective.StockFamily) any {
		if f == objective.Partner {
			return partner
		}
		if byFamily[f] == nil {
			return []any{}
		}
		return byFamily[f]
	}
	info := map[string]any{"day_huoyue": view.Root.DayHuoyue, "week_huoyue": view.Root.WeekHuoyue, "day_award": claimFlags(view.Root.DayAward, 5), "week_award": claimFlags(view.Root.WeekAward, 2)}
	out := map[string]any{"extra_info": map[string]any{"daily_left_time": max(int64(0), modes.DayBegins(view.Root.Day+1).Unix()-at.Unix()), "huoyue_info": info}}
	if family != 0 {
		out["mission_list"] = list(family)
		return out
	}
	for f, key := range map[objective.StockFamily]string{objective.Daily: "daily_mission_", objective.GrowMain: "mainline_mission_", objective.Story: "story_mission_", objective.Partner: "partner_mission_"} {
		if f == objective.Partner {
			out[key] = partnerHooks
		} else {
			out[key] = list(f)
		}
	}
	if view.Activity != nil {
		for _, rule := range view.Activity.Rules {
			points, claimed := view.Root.DayHuoyue, view.Root.DayAward
			if rule.Period == "WEEK" {
				points, claimed = view.Root.WeekHuoyue, view.Root.WeekAward
			}
			if points >= rule.Medal && !slices.Contains(claimed, rule.Index) {
				marks[2701] = true
				break
			}
		}
	}
	redmarkList := []int64{}
	for _, id := range []int64{2701, 2702, 2704, 2706} {
		if marks[id] {
			redmarkList = append(redmarkList, id)
		}
	}
	out["redmarks_"] = map[string]any{"27": map[string]any{"function_id": int64(27), "redmark_list": redmarkList}}
	return out
}

func (m MissionMaterializer) definitionTx(ctx context.Context, q tx.Queryer, instance objective.Instance) (objective.MissionDefinition, error) {
	definitions, err := m.Catalog.MissionDefinitionsTx(ctx, q, instance.ContentRevision)
	if err != nil {
		return objective.MissionDefinition{}, err
	}
	for _, definition := range definitions {
		if definition.ProgramID == instance.ProgramID && definition.ObjectiveID == instance.ObjectiveID && definition.DefinitionRevision == instance.DefinitionRevision {
			return definition, definition.Validate()
		}
	}
	return objective.MissionDefinition{}, ErrObjectiveNotFound
}

func (s Service) ClaimMission(ctx context.Context, actor identity.ActorContext, id int64, hint string, op operation.Context) (ObjectiveClaimResult, error) {
	timed, err := s.missionOperation(ctx, op)
	if err != nil {
		return ObjectiveClaimResult{}, err
	}
	scope, err := missionScope(actor.PlayerID, timed)
	if err != nil {
		return ObjectiveClaimResult{}, err
	}
	definitions, err := s.Missions.Catalog.MissionDefinitionsTx(ctx, s.MissionFresh, scope.ContentRevision)
	if err != nil {
		return ObjectiveClaimResult{}, err
	}
	var selected objective.MissionDefinition
	for _, d := range definitions {
		if d.ObjectiveID == id {
			selected = d
			break
		}
	}
	if selected.ObjectiveID == 0 {
		return s.ClaimObjectiveByID(ctx, actor, id, hint, op)
	}
	hero := int64(0)
	if selected.Family == objective.Partner {
		hero, err = strconv.ParseInt(strings.TrimPrefix(hint, "hero:"), 10, 64)
		if err != nil || hero <= 0 {
			return ObjectiveClaimResult{}, ErrMissionRefused
		}
	} else if hint != "" {
		return ObjectiveClaimResult{}, ErrMissionRefused
	}
	generation, err := selected.MissionGeneration(scope.DecisionAt, hero)
	if err != nil {
		return ObjectiveClaimResult{}, err
	}
	identity := receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(actor.PlayerID), Domain: "objective", Operation: "mission-claim", SemanticKey: missionOccurrence(id, generation)}
	fingerprint, _ := receipt.FingerprintRequest(map[string]any{"table_id": id, "generation": generation})
	var out ObjectiveClaimResult
	replay := false
	result, err := s.Runner.Run(ctx, timed.Operation(), s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: identity, Fingerprint: fingerprint}, func(ctx context.Context, tr tx.Scope) error {
		if err := s.Store.FenceActorTx(ctx, tr.Tx, actor, scope.DecisionAt); err != nil {
			return err
		}
		view, err := s.Missions.MaterializeTx(ctx, tr.Tx, scope)
		if err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(ctx, tr.Tx, identity); err != nil {
			return err
		} else if ok {
			if prior.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: identity}
			}
			replay = true
			changes.Missions(ctx, MissionProjection(view, scope.DecisionAt, 0))
			return json.Unmarshal(prior.ResultPayload, &out)
		}
		var instance objective.Instance
		for _, row := range view.Instances {
			if row.ObjectiveID == id && row.GenerationID == generation {
				instance = row
				break
			}
		}
		if instance.ObjectiveID == 0 {
			return ErrMissionRefused
		}
		definition, err := s.Missions.definitionTx(ctx, tr.Tx, instance)
		if err != nil {
			return err
		}
		observed := scope
		observed.ContentRevision = instance.ContentRevision
		observation, err := s.Missions.Observations.ObserveMissionTx(ctx, tr.Tx, observed, definition, hero)
		if err != nil {
			return err
		}
		if !observation.GatePassed || !s.Missions.bindingAvailable(definition) || definition.Strategy == "TEMPORAL_ENTITLEMENT" && observation.Value < definition.Target {
			return ErrMissionRefused
		}
		next, err := objective.Claim(instance, scope.DecisionAt)
		if err != nil {
			return ErrMissionRefused
		}
		progression, err := s.Store.ReadProgressionTx(ctx, tr.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		rule, err := s.Content.ResolveProgressionPolicyTx(ctx, tr.Tx, instance.ContentRevision)
		if err != nil {
			return err
		}
		privilege, err := s.Privileges.SnapshotTx(ctx, tr.Tx, actor.PlayerID, scope.DecisionAt)
		if err != nil {
			return err
		}
		plan, err := definition.RewardFor(progression.Level, int64(len(rule.Rows)), privilege.VIPLevel)
		if err != nil {
			return err
		}
		claimOp, err := missionRewardOperation(timed.Operation(), instance.ContentRevision)
		if err != nil {
			return err
		}
		if len(plan.Lines) > 0 {
			plan.PlayerID = actor.PlayerID
			plan.Source = grant.SourceIdentity{Domain: "objective", Operation: "claim", BusinessKey: fmt.Sprintf("%s:%d:%s:%s", instance.ProgramID, id, generation, instance.DefinitionRevision), PolicyVersion: definition.Reward.Source.PolicyVersion}
			gr, err := s.SettleGrantTx(ctx, tr.Tx, actor, plan, claimOp, GrantTxOptions{AllowOverflowMail: true})
			if err != nil {
				return err
			}
			out = ObjectiveClaimResult{Awards: gr.Awards, Grant: &gr}
		} else {
			out = ObjectiveClaimResult{Awards: []Award{}}
		}
		out.Huoyue = definition.Huoyue
		if err := s.Store.SaveObjectiveTx(ctx, tr.Tx, next, instance.StateVersion); err != nil {
			return err
		}
		root := view.Root
		if root.DayHuoyue > math.MaxInt64-definition.Huoyue || root.WeekHuoyue > math.MaxInt64-definition.Huoyue || root.BattlepassScore > math.MaxInt64-definition.Presentation.BattlepassScore {
			return errors.New("mission medal overflow")
		}
		root.DayHuoyue += definition.Huoyue
		root.WeekHuoyue += definition.Huoyue
		root.BattlepassScore += definition.Presentation.BattlepassScore
		root.StateVersion++
		if err := s.Missions.Store.SaveMissionRootTx(ctx, tr.Tx, root, view.Root.StateVersion); err != nil {
			return err
		}
		updated, err := s.Missions.MaterializeTx(ctx, tr.Tx, scope)
		if err != nil {
			return err
		}
		changes.Missions(ctx, MissionProjection(updated, scope.DecisionAt, 0))
		raw, err := json.Marshal(out)
		if err != nil {
			return err
		}
		rr, err := receipt.New(claimOp, identity, "I5_OBJECTIVE", "gxb.i5.mission-claim.v1", raw, fingerprint)
		if err != nil {
			return err
		}
		rr.ActorAccountUID, rr.ContextID = string(actor.AccountUID), actor.ContextID.UUID()
		_, err = s.Receipts.PutTx(ctx, tr.Tx, rr)
		return err
	})
	if err != nil {
		return ObjectiveClaimResult{}, err
	}
	if result.Reconciled {
		r, ok := result.Evidence.(receipt.Receipt)
		if !ok {
			return ObjectiveClaimResult{}, errors.New("missing mission reconciliation receipt")
		}
		if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
			return ObjectiveClaimResult{}, err
		}
		replay = true
	}
	grants := []GrantResult{}
	if out.Grant != nil {
		grants = append(grants, *out.Grant)
	}
	out.Projection, err = s.projectSettlement(ctx, actor, projectionGrants(grants, out.Awards), op, replay)
	out.Replayed = replay
	return out, err
}

func missionRewardOperation(source operation.Context, revision string) (operation.Context, error) {
	refs := source.Policies.Refs()
	old, _ := source.Policies.Get("content")
	for i := range refs {
		if refs[i].Name == "content" {
			refs[i].Version = revision
		}
	}
	refs = append(refs, policy.Ref{Name: "mission-admission-content", Version: old})
	var err error
	source.Policies, err = policy.NewSet(refs...)
	return source, err
}
