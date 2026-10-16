package i5

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/redeem"
	"gxb.local/backend/v2/internal/foundation/audit"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrUnsupportedGrantDestination = errors.New("grant destination belongs to an unimplemented owner")
	ErrMailNotFound                = errors.New("mail not found")
	ErrMailStackFull               = errors.New("mail attachment would exceed canonical stack capacity")
	ErrObjectiveNotFound           = errors.New("objective not found")
	ErrRedeemInvalid               = errors.New("invalid redeem code")
)

type Award struct {
	// TableID is required by stock bulk-award surfaces (MID370/MID230). A zero
	// value is intentionally preserved for named scalar resources rather than
	// inventing a numeric item identity.
	TableID     int64  `json:"table_id,omitempty"`
	ResourceKey string `json:"resource_key,omitempty"`
	ItemNum     int64  `json:"item_num"`
}

func (a Award) MailItem() any {
	if a.TableID > 0 {
		return a.TableID
	}
	return a.ResourceKey
}

type GrantProgressionEffect struct {
	BeforeLevel  int64 `json:"before_level"`
	AfterLevel   int64 `json:"after_level"`
	BeforeExp    int64 `json:"before_exp"`
	AfterExp     int64 `json:"after_exp"`
	RequestedExp int64 `json:"requested_exp"`
	EffectiveExp int64 `json:"effective_exp"`
	DiscardedExp int64 `json:"discarded_exp"`
	EnergyAward  int64 `json:"energy_award"`
}

type GrantTemporalEffect struct {
	ResourceKey   string `json:"resource_key"`
	BeforeAmount  int64  `json:"before_amount"`
	AfterAmount   int64  `json:"after_amount"`
	AnchorUnix    int64  `json:"anchor_unix"`
	PolicyVersion string `json:"policy_version"`
}

type GrantEffects struct {
	ContentRevision           string                   `json:"content_revision"`
	PlayerID                  int64                    `json:"player_id"`
	OperationID               string                   `json:"operation_id"`
	OperationStartedAt        time.Time                `json:"operation_started_at"`
	ProgressionCompatibility  string                   `json:"progression_compatibility,omitempty"`
	PrivilegeProviderRevision string                   `json:"privilege_provider_revision,omitempty"`
	FunctionProviderRevision  string                   `json:"function_provider_revision,omitempty"`
	Progression               []GrantProgressionEffect `json:"progression,omitempty"`
	Temporal                  []GrantTemporalEffect    `json:"temporal,omitempty"`
	EligibleFunctionIDs       []int64                  `json:"eligible_function_ids,omitempty"`
	NewFunctionIDs            []int64                  `json:"new_function_ids,omitempty"`
	ExtraDrops                []Award                  `json:"extra_drops,omitempty"`
}

type GrantResult struct {
	ReceiptID        string                 `json:"receipt_id"`
	Awards           []Award                `json:"awards"`
	Effects          *GrantEffects          `json:"effects,omitempty"`
	Materializations []GrantMaterialization `json:"materializations,omitempty"`
}

type MailListResult struct {
	MailList     []mail.Record
	Total        int64
	NewMailTotal int64
}

type MID369Result struct {
	Changed    bool                 `json:"changed"`
	IsNew      int64                `json:"is_new"`
	IsShown    int64                `json:"is_shown"`
	Rewards    []Award              `json:"rewards,omitempty"`
	Grant      *GrantResult         `json:"grant,omitempty"`
	Projection SettlementProjection `json:"-"`
	Replayed   bool                 `json:"-"`
}

type MID370Result struct {
	Awards     []Award              `json:"awards"`
	Mail       MailListResult       `json:"mail"`
	Grants     []GrantResult        `json:"grants,omitempty"`
	Projection SettlementProjection `json:"-"`
	Replayed   bool                 `json:"-"`
}

type ObjectiveClaimResult struct {
	Awards     []Award              `json:"awards,omitempty"`
	Huoyue     int64                `json:"huoyue,omitempty"`
	Grant      *GrantResult         `json:"grant,omitempty"`
	Projection SettlementProjection `json:"-"`
	Replayed   bool                 `json:"-"`
}

type RedeemResult struct {
	Awards     []Award              `json:"awards"`
	Grant      *GrantResult         `json:"grant,omitempty"`
	Projection SettlementProjection `json:"-"`
	Replayed   bool                 `json:"-"`
}

func decodeOuterObjectReceipt(r receipt.Receipt, v1Schema, v2Schema string, out any) error {
	switch r.ResultSchema {
	case v1Schema, v2Schema:
		return json.Unmarshal(r.ResultPayload, out)
	default:
		return fmt.Errorf("unsupported outer receipt schema %q", r.ResultSchema)
	}
}

func decodeRedeemReceipt(r receipt.Receipt, out *RedeemResult) error {
	switch r.ResultSchema {
	case "gxb.i5.redeem.v1":
		var awards []Award
		if err := json.Unmarshal(r.ResultPayload, &awards); err != nil {
			return err
		}
		*out = RedeemResult{Awards: awards}
		return nil
	case "gxb.i5.redeem.v2":
		return json.Unmarshal(r.ResultPayload, out)
	default:
		return fmt.Errorf("unsupported outer receipt schema %q", r.ResultSchema)
	}
}

func projectionGrants(explicit []GrantResult, awards []Award) []GrantResult {
	if len(explicit) > 0 {
		return explicit
	}
	if len(awards) == 0 {
		return nil
	}
	return []GrantResult{{Awards: append([]Award(nil), awards...)}}
}

type Service struct {
	Runner          tx.Runner
	Store           Store
	Content         ContentRuntime
	Privileges      PrivilegeSnapshotProvider
	Functions       FunctionAnnouncementProvider
	Directory       DirectoryLevelProjectionPort
	Backpack        BackpackReader
	PartnerEntities PartnerEntityMaterializer
	Spirits         SpiritMaterializer
	Receipts        receipt.Store
	ReceiptRead     receipt.Reader
	RedeemSecret    []byte
	Audit           audit.Emitter
	Profile         tx.Profile
}

var _ TxGrantSettler = Service{}

func DefaultProfile() tx.Profile {
	return tx.Profile{Name: "I5_PLAYER_WRITE", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}

func (s Service) profile() tx.Profile {
	if s.Profile.Name == "" {
		return DefaultProfile()
	}
	return s.Profile
}

func (s Service) validate() error {
	if s.Store == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return errors.New("I5 service ports incomplete")
	}
	return nil
}

func (s Service) SettleGrant(ctx context.Context, actor identity.ActorContext, plan grant.Plan, op operation.Context) (GrantResult, error) {
	if plan.PlayerID != actor.PlayerID {
		return GrantResult{}, errors.New("grant actor/player mismatch")
	}
	return s.runGrant(ctx, actor, plan, op, true)
}

// GrantTxOptions controls only orchestration behavior that is part of the
// canonical Grant contract. It never changes resource policy/content.
type GrantTxOptions struct {
	AllowOverflowMail bool
}

// SettleGrantTx settles one semantic Grant inside a caller-owned Wave-A
// transaction. It never begins, commits, rolls back, or retries a transaction.
// Later domains use this seam to keep source mutation + entitlement settlement
// atomic without reaching into I5 tables or nesting transactions.
func (s Service) SettleGrantTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, plan grant.Plan, op operation.Context, opts GrantTxOptions) (GrantResult, error) {
	if err := s.validate(); err != nil {
		return GrantResult{}, err
	}
	if t == nil {
		return GrantResult{}, errors.New("grant transaction required")
	}
	if plan.PlayerID != actor.PlayerID {
		return GrantResult{}, errors.New("grant actor/player mismatch")
	}
	return s.settleGrantTx(ctx, t, actor, plan, op, opts.AllowOverflowMail)
}

func (s Service) runGrant(ctx context.Context, actor identity.ActorContext, plan grant.Plan, op operation.Context, fenceActor bool) (GrantResult, error) {
	if err := s.validate(); err != nil {
		return GrantResult{}, err
	}
	fp, err := receiptFingerprintForGrant(plan)
	if err != nil {
		return GrantResult{}, err
	}
	boundOp := op
	var out GrantResult
	resolver := grantUnknownCommitResolver{Reader: s.ReceiptRead, Plan: plan, FP: fp}
	res, err := s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, resolver, func(txctx context.Context, scope tx.Scope) error {
		if fenceActor {
			if err := s.Store.FenceActorTx(txctx, scope.Tx, actor, op.StartedAt); err != nil {
				return err
			}
		}
		prepared, err := s.prepareGrantOperationTx(txctx, scope.Tx, plan, boundOp)
		if err != nil {
			return err
		}
		boundOp = prepared
		got, err := s.SettleGrantTx(txctx, scope.Tx, actor, plan, boundOp, GrantTxOptions{AllowOverflowMail: true})
		if err == nil {
			out = got
		}
		return err
	})
	if err != nil {
		return GrantResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			out, err = decodeGrantReceiptResult(r)
			if err != nil {
				return GrantResult{}, err
			}
		}
	}
	return out, nil
}

func (s Service) settleGrantTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, plan grant.Plan, op operation.Context, allowOverflowMail bool) (GrantResult, error) {
	id, _, err := plan.ReceiptIdentities()
	if err != nil {
		return GrantResult{}, err
	}
	fp, err := receiptFingerprintForGrant(plan)
	if err != nil {
		return GrantResult{}, err
	}
	if prior, ok, err := s.findGrantReceiptTx(ctx, t, plan, fp); err != nil {
		return GrantResult{}, err
	} else if ok {
		return decodeGrantReceiptResult(prior)
	}

	contentRevision, err := requireContentRevision(op)
	if err != nil {
		return GrantResult{}, err
	}
	now := op.StartedAt.UTC()
	pf, err := s.preflightGrantTx(ctx, t, plan, contentRevision, grantPreflightOptions{AllowOverflowMail: allowOverflowMail}, now)
	if err != nil {
		return GrantResult{}, err
	}
	if err := s.acquireGrantLocksTx(ctx, t, plan.PlayerID, pf, now); err != nil {
		return GrantResult{}, err
	}
	// A waiter can observe no receipt before blocking on owner locks and then
	// resume after the winning semantic transaction commits. Recheck while the
	// complete owner suffix is held so replay never applies effects twice.
	if prior, ok, err := s.findGrantReceiptTx(ctx, t, plan, fp); err != nil {
		return GrantResult{}, err
	} else if ok {
		return decodeGrantReceiptResult(prior)
	}
	if err := s.validatePartnerEntityLockedTx(ctx, t, pf); err != nil {
		return GrantResult{}, err
	}
	// The new SocialGift scalar retains accepted StartedAt semantics and refuses
	// time/version regression before any grant mutation. Other resources are unchanged.
	for _, line := range plan.Lines {
		if line.Kind == grant.ScalarCurrency && line.ResourceKey == "friendship_coin" {
			balance, exists, err := s.Store.ReadScalarTx(ctx, t, plan.PlayerID, line.ResourceKey)
			if err != nil {
				return GrantResult{}, err
			}
			if exists && (op.StartedAt.Before(balance.UpdatedAt) || balance.StateVersion == math.MaxInt64) {
				return GrantResult{}, errors.New("SocialGift scalar clock/version regression")
			}
		}
	}
	return s.applyPreparedGrantTx(ctx, t, actor, plan, op, allowOverflowMail, contentRevision, pf, id, fp)
}

func (s Service) applyPreparedGrantTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, plan grant.Plan, op operation.Context, allowOverflowMail bool, contentRevision string, pf grantPreflight, id receipt.Identity, fp [32]byte) (GrantResult, error) {
	now := op.StartedAt.UTC()
	materializations, err := s.materializePartnerEntityTx(ctx, t, pf, op)
	if err != nil {
		return GrantResult{}, err
	}
	spirits, err := s.materializeSpiritTx(ctx, t, pf, op)
	if err != nil {
		return GrantResult{}, err
	}
	materializations = append(materializations, spirits...)
	awards := make([]Award, 0, len(plan.Lines))
	effects := &GrantEffects{ContentRevision: contentRevision, PlayerID: int64(plan.PlayerID), OperationID: op.ID.String(), OperationStartedAt: now}
	if s.Functions != nil {
		effects.FunctionProviderRevision = s.Functions.ProviderRevision()
	}
	for _, prepared := range pf.Lines {
		ordinal, line, policy := prepared.Ordinal, prepared.Line, prepared.Policy
		award := Award{TableID: policy.WireTableID, ResourceKey: line.ResourceKey, ItemNum: line.Amount}
		switch line.Kind {
		case grant.ScalarCurrency:
			st, exists, err := s.Store.LockScalarTx(ctx, t, plan.PlayerID, line.ResourceKey, now)
			if err != nil {
				return GrantResult{}, err
			}
			if !exists {
				st = economy.ScalarBalance{PlayerID: plan.PlayerID, ResourceKey: line.ResourceKey, Amount: line.Amount, StateVersion: 1, UpdatedAt: now}
			} else {
				st, err = st.Credit(line.Amount, now)
				if err != nil {
					return GrantResult{}, err
				}
			}
			if err := s.Store.SaveScalarTx(ctx, t, st, exists); err != nil {
				return GrantResult{}, err
			}

		case grant.Temporal:
			st, exists, err := s.Store.LockTemporalTx(ctx, t, plan.PlayerID, line.ResourceKey)
			if err != nil {
				return GrantResult{}, err
			}
			if !exists {
				return GrantResult{}, economy.ErrUnknownResource
			}
			before := st
			var temporalPolicy economy.TemporalPolicy
			providerRevision := ""
			switch {
			case policy.Temporal != nil:
				temporalPolicy = *policy.Temporal
			case policy.Descriptor != nil:
				if st.ContentRevision == "" || st.ContentRevision != policy.Descriptor.Revision {
					return GrantResult{}, ErrContentRevisionConflict
				}
				var progressionPolicy player.ProgressionPolicy
				var level int64 = 1
				if policy.Descriptor.CapRule == "PLAYER_LEVEL_ENERGY" {
					if pf.ProgressionPolicy == nil {
						return GrantResult{}, errors.New("progression policy missing for dynamic Energy cap")
					}
					progressionPolicy = *pf.ProgressionPolicy
					prog, err := s.Store.LockProgressionTx(ctx, t, plan.PlayerID)
					if err != nil {
						return GrantResult{}, err
					}
					level = prog.Level
				}
				temporalPolicy, providerRevision, err = s.resolveTemporalPolicyTx(ctx, t, plan.PlayerID, *policy.Descriptor, progressionPolicy, level, now)
				if err != nil {
					return GrantResult{}, err
				}
			default:
				return GrantResult{}, economy.ErrInvalidTemporalPolicy
			}
			st, err = st.Credit(line.Amount, now, temporalPolicy)
			if err != nil {
				return GrantResult{}, err
			}
			if st.StateVersion != before.StateVersion {
				if err := s.Store.SaveTemporalTx(ctx, t, st); err != nil {
					return GrantResult{}, err
				}
			}
			effects.Temporal = append(effects.Temporal, temporalEffect(line.ResourceKey, before, st))
			if providerRevision != "" && providerRevision != policy.PolicyVersion {
				effects.PrivilegeProviderRevision = providerRevision
			}

		case grant.StackItem:
			if policy.Stack == nil {
				return GrantResult{}, economy.ErrUnknownResource
			}
			award.ResourceKey = ""
			st, exists, err := s.Store.LockStackTx(ctx, t, plan.PlayerID, line.ItemID, now)
			if err != nil {
				return GrantResult{}, err
			}
			if !exists {
				st = economy.StackState{PlayerID: plan.PlayerID, ItemID: line.ItemID, Quantity: 0, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
			}
			cr, err := st.PlanCredit(line.Amount, *policy.Stack, now)
			if err != nil {
				return GrantResult{}, err
			}
			if cr.Overflow > 0 && !allowOverflowMail {
				return GrantResult{}, ErrMailStackFull
			}
			if cr.Fit > 0 {
				if err := s.Store.SaveStackTx(ctx, t, cr.State, exists); err != nil {
					return GrantResult{}, err
				}
			}
			if cr.Overflow > 0 {
				sourceKey, err := plan.OverflowMailSourceKey(line.ItemID, ordinal)
				if err != nil {
					return GrantResult{}, err
				}
				over := line
				over.Amount = cr.Overflow
				if _, err := s.createMailTx(ctx, t, plan.PlayerID, mail.Normal, "GRANT_OVERFLOW", sourceKey, "", "System", "", []grant.Line{over}, now, nil, plan.Source.PolicyVersion); err != nil {
					return GrantResult{}, err
				}
				award.ItemNum = cr.Fit
			}

		case grant.PlayerExp:
			if pf.ProgressionPolicy == nil || pf.FunctionPolicy == nil || pf.EnergyDescriptor == nil {
				return GrantResult{}, errors.New("R5 PlayerExp preflight incomplete")
			}
			prog, err := s.Store.LockProgressionTx(ctx, t, plan.PlayerID)
			if err != nil {
				return GrantResult{}, err
			}
			transition, err := pf.ProgressionPolicy.PlanCreditExp(prog, line.Amount, now)
			if err != nil {
				return GrantResult{}, err
			}

			energy, exists, err := s.Store.LockTemporalTx(ctx, t, plan.PlayerID, "energy")
			if err != nil {
				return GrantResult{}, err
			}
			if !exists || energy.ContentRevision == "" || energy.ContentRevision != contentRevision {
				return GrantResult{}, ErrContentRevisionConflict
			}
			energyBefore := energy
			oldEnergyPolicy, _, err := s.resolveTemporalPolicyTx(ctx, t, plan.PlayerID, *pf.EnergyDescriptor, *pf.ProgressionPolicy, transition.Before.Level, now)
			if err != nil {
				return GrantResult{}, err
			}
			newEnergyPolicy, _, err := s.resolveTemporalPolicyTx(ctx, t, plan.PlayerID, *pf.EnergyDescriptor, *pf.ProgressionPolicy, transition.After.Level, now)
			if err != nil {
				return GrantResult{}, err
			}
			energy, err = energy.ApplyLevelTransition(transition.AwardEnergy, now, oldEnergyPolicy, newEnergyPolicy)
			if err != nil {
				return GrantResult{}, err
			}

			functionVersion, err := s.Store.LockFunctionStateTx(ctx, t, plan.PlayerID)
			if err != nil {
				return GrantResult{}, err
			}
			eligible, err := pureLevelEligibility(*pf.FunctionPolicy, plan.PlayerID, transition.After.Level, now)
			if err != nil {
				return GrantResult{}, err
			}
			newEligible := make([]player.FunctionEligibility, 0, len(eligible))
			functionChanged := false
			semanticKey := plan.Source.SemanticKey()
			for _, e := range eligible {
				e.SourceFactKey = fmt.Sprintf("r5:function-eligibility:v1:%s:%d", semanticKey, e.FunctionID)
				inserted, err := s.Store.InsertFunctionEligibilityTx(ctx, t, e)
				if err != nil {
					return GrantResult{}, err
				}
				if inserted {
					newEligible = append(newEligible, e)
					functionChanged = true
				}
			}
			announced, err := s.Functions.Announce(ctx, plan.PlayerID, *pf.FunctionPolicy, newEligible)
			if err != nil {
				return GrantResult{}, err
			}
			byID := make(map[int64]player.FunctionEligibility, len(newEligible))
			for _, e := range newEligible {
				byID[e.FunctionID] = e
			}
			newlyUnlocked := make([]int64, 0, len(announced))
			for _, functionID := range announced {
				e, ok := byID[functionID]
				if !ok {
					return GrantResult{}, errors.New("function provider announced unqualified function")
				}
				inserted, err := s.Store.InsertFunctionUnlockTx(ctx, t, player.FunctionUnlock{PlayerID: plan.PlayerID, FunctionID: functionID, OpenedAt: now, SourceFactKey: e.SourceFactKey, StateVersion: 1})
				if err != nil {
					return GrantResult{}, err
				}
				functionChanged = functionChanged || inserted
				if inserted {
					newlyUnlocked = append(newlyUnlocked, functionID)
				}
				if inserted && functionID == 38 {
					if pf.PetStarterPolicy == nil {
						return GrantResult{}, errors.New("Pet starter policy missing for Function 38")
					}
					itemID := pf.PetStarterPolicy.StarterEggItemID
					line := grant.Line{Kind: grant.StackItem, ItemID: itemID, Amount: 1}
					rp, err := s.Content.ResolveResourceTx(ctx, t, contentRevision, line)
					if err != nil || rp.Stack == nil {
						if err == nil {
							err = economy.ErrUnknownResource
						}
						return GrantResult{}, err
					}
					st, exists, err := s.Store.LockStackTx(ctx, t, plan.PlayerID, itemID, now)
					if err != nil {
						return GrantResult{}, err
					}
					if !exists {
						st = economy.StackState{PlayerID: plan.PlayerID, ItemID: itemID, Quantity: 0, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
					}
					if st.Quantity == 0 {
						cr, err := st.PlanCredit(1, *rp.Stack, now)
						if err != nil {
							return GrantResult{}, err
						}
						if cr.Fit != 1 || cr.Overflow != 0 {
							return GrantResult{}, errors.New("Pet starter egg cannot fit canonical stack")
						}
						if err := s.Store.SaveStackTx(ctx, t, cr.State, exists); err != nil {
							return GrantResult{}, err
						}
						effects.ExtraDrops = append(effects.ExtraDrops, Award{TableID: itemID, ItemNum: 1})
					}
				}
			}
			if functionChanged {
				if err := s.Store.AdvanceFunctionStateTx(ctx, t, plan.PlayerID, functionVersion, now); err != nil {
					return GrantResult{}, err
				}
			}

			dir, err := s.Directory.LockTx(ctx, t, plan.PlayerID)
			if err != nil {
				return GrantResult{}, err
			}
			if dir.Level != transition.Before.Level {
				return GrantResult{}, errors.New("directory level projection drift requires R6 repair")
			}

			if transition.After.StateVersion != transition.Before.StateVersion {
				if err := s.Store.SaveProgressionTx(ctx, t, transition.After, transition.Before.StateVersion); err != nil {
					return GrantResult{}, err
				}
			}
			if energy.StateVersion != energyBefore.StateVersion {
				if err := s.Store.SaveTemporalTx(ctx, t, energy); err != nil {
					return GrantResult{}, err
				}
			}
			if transition.After.Level != transition.Before.Level {
				if err := s.Directory.SetLevelTx(ctx, t, plan.PlayerID, dir.StateVersion, transition.After.Level, op); err != nil {
					return GrantResult{}, err
				}
			}

			effects.ProgressionCompatibility = transition.CompatibilityPolicy
			effects.Progression = append(effects.Progression, GrantProgressionEffect{
				BeforeLevel: transition.Before.Level, AfterLevel: transition.After.Level,
				BeforeExp: transition.Before.Exp, AfterExp: transition.After.Exp,
				RequestedExp: transition.RequestedExp, EffectiveExp: transition.EffectiveExp,
				DiscardedExp: transition.DiscardedExp, EnergyAward: transition.AwardEnergy,
			})
			effects.Temporal = append(effects.Temporal, temporalEffect("energy", energyBefore, energy))
			for _, e := range newEligible {
				effects.EligibleFunctionIDs = append(effects.EligibleFunctionIDs, e.FunctionID)
			}
			effects.NewFunctionIDs = append(effects.NewFunctionIDs, newlyUnlocked...)

		case grant.PartnerEntity:
			// The typed provider already materialized the complete batch before
			// fungible writes. CA1 deliberately emits no generic stock Award for
			// entity lines; CA2+ must qualify stock projection before activation.
			continue
		case grant.SpecializedDomain:
			if line.Domain != "spirit" || pf.Spirit == nil {
				return GrantResult{}, ErrUnsupportedGrantDestination
			}
			continue
		default:
			return GrantResult{}, economy.ErrUnknownResource
		}
		if award.ItemNum > 0 {
			awards = append(awards, award)
		}
	}

	out := GrantResult{Awards: awards, Effects: effects, Materializations: materializations}
	// Fungible-only grants retain the exact accepted v2 schema. Typed entity
	// materialization advances only those receipts to v3 so legacy stock paths
	// remain byte-semantically stable.
	schema := "gxb.i5.grant.v2"
	if len(materializations) > 0 {
		schema = "gxb.i5.grant.v3"
	}
	// Allocate the receipt first, then make its id part of the terminal payload so
	// replay/reconciliation can reconstruct dependent redemption rows exactly.
	rr, err := receipt.New(op, id, "I5_GRANT", schema, json.RawMessage(`{"pending":true}`), fp)
	if err != nil {
		return GrantResult{}, err
	}
	out.ReceiptID = rr.ID.String()
	raw, err := json.Marshal(out)
	if err != nil {
		return GrantResult{}, err
	}
	rr.ResultPayload = raw
	rr.PolicyVersion = plan.Source.PolicyVersion
	rr.ActorAccountUID = string(actor.AccountUID)
	rr.ContextID = actor.ContextID.UUID()
	put, err := s.Receipts.PutTx(ctx, t, rr)
	if err != nil {
		return GrantResult{}, err
	}
	if !put.Inserted {
		return decodeGrantReceiptResult(put.Receipt)
	}
	return out, nil
}

func (s Service) createMailTx(ctx context.Context, t tx.Tx, playerID identity.PlayerID, ns mail.Namespace, sourceKind, sourceKey, title, sender, body string, lines []grant.Line, now time.Time, expires *time.Time, policyVersion string) (mail.Record, error) {
	wireID, err := s.Store.AllocateMailWireIDTx(ctx, t, playerID, ns)
	if err != nil {
		return mail.Record{}, err
	}
	uid, err := ids.NewUUID()
	if err != nil {
		return mail.Record{}, err
	}
	attachments := make([]mail.Attachment, 0, len(lines))
	for i, line := range lines {
		attachments = append(attachments, mail.Attachment{Ordinal: i, Line: line})
	}
	r := mail.Record{MailUUID: uid, Recipient: playerID, Address: mail.Address{Namespace: ns, WireID: wireID}, SourceKind: sourceKind, SourceKey: sourceKey, Title: title, Sender: sender, Body: body, CreatedAt: now.UTC(), ExpiresAt: expires, Shown: true, Platform: mail.AnyPlatform, CompatibilityPolicyVersion: policyVersion, StateVersion: 1, Attachments: attachments}
	if err := r.Validate(); err != nil {
		return mail.Record{}, err
	}
	if err := s.Store.InsertMailTx(ctx, t, r); err != nil {
		return mail.Record{}, err
	}
	return r, nil
}

func (s Service) SaveStory(ctx context.Context, actor identity.ActorContext, storyID, storyState, guideID int64, op operation.Context) error {
	if err := s.validate(); err != nil {
		return err
	}
	semantic := sha256.Sum256([]byte(fmt.Sprintf("%d\x00%d\x00%d", storyID, storyState, guideID)))
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "player-core", Operation: "save-story", SemanticKey: hex.EncodeToString(semantic[:])}
	fp, err := receipt.FingerprintRequest(map[string]any{"story_id": storyID, "story_state": storyState, "guide_id": guideID})
	if err != nil {
		return err
	}
	_, err = s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Store.FenceActorTx(txctx, scope.Tx, actor, op.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			return nil
		}
		cur, err := s.Store.LockStoryTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		old := cur.StateVersion
		next, terminal, err := player.SaveStory(cur, storyID, storyState, guideID, op.StartedAt)
		if err != nil {
			return err
		}
		if next.StateVersion != old {
			if err := s.Store.SaveStoryTx(txctx, scope.Tx, next, old); err != nil {
				return err
			}
		}
		if terminal {
			if err := s.Store.ClearFirstEntryPendingTx(txctx, scope.Tx, actor.PlayerID); err != nil {
				return err
			}
		}
		rr, err := receipt.New(op, id, "I5_PLAYER_CORE", "gxb.i5.story.v1", json.RawMessage(`{"ok":true}`), fp)
		if err != nil {
			return err
		}
		rr.ActorAccountUID, rr.ContextID, rr.PolicyVersion = string(actor.AccountUID), actor.ContextID.UUID(), "pass415-story-v1"
		_, err = s.Receipts.PutTx(txctx, scope.Tx, rr)
		return err
	})
	return err
}

func (s Service) ListBackpack(ctx context.Context, actor identity.ActorContext) ([]economy.StackState, error) {
	if s.Backpack == nil || !actor.PlayerID.Valid() {
		return nil, errors.New("backpack list input invalid")
	}
	return s.Backpack.ListStacks(ctx, actor.PlayerID)
}

func (s Service) ListMail(ctx context.Context, actor identity.ActorContext, now time.Time, limit int) (MailListResult, error) {
	if s.Store == nil || !actor.PlayerID.Valid() || now.IsZero() {
		return MailListResult{}, errors.New("mail list input invalid")
	}
	if limit <= 0 || limit > 200 {
		limit = 20
	}
	records, total, newTotal, err := s.Store.ListMail(ctx, actor.PlayerID, now.UTC(), limit)
	return MailListResult{MailList: records, Total: total, NewMailTotal: newTotal}, err
}

func (s Service) ClaimMail(ctx context.Context, actor identity.ActorContext, addr mail.Address, op operation.Context) (MID369Result, error) {
	if err := s.validate(); err != nil {
		return MID369Result{}, err
	}
	if err := addr.Validate(); err != nil {
		return MID369Result{}, err
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "mail", Operation: "claim", SemanticKey: addr.String()}
	fp, _ := receipt.FingerprintRequest(addr)
	var out MID369Result
	boundOp := op
	recognizedReplay := false
	res, err := s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Store.FenceActorTx(txctx, scope.Tx, actor, op.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			recognizedReplay = true
			return decodeOuterObjectReceipt(prior, "gxb.i5.mail369.v1", "gxb.i5.mail369.v2", &out)
		}
		r, err := s.Store.LockMailTx(txctx, scope.Tx, actor.PlayerID, addr)
		if err != nil {
			return err
		}
		oldVersion := r.StateVersion
		wasNew := r.ReadAt == nil
		now := op.StartedAt.UTC()
		awards := []Award{}
		var nested *GrantResult
		if len(r.Attachments) > 0 {
			if !r.Claimable(now) {
				return errors.New("mail attachments are not claimable")
			}
			lines := make([]grant.Line, 0, len(r.Attachments))
			for _, a := range r.Attachments {
				lines = append(lines, a.Line)
			}
			plan := grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "mail", Operation: "claim", BusinessKey: r.MailUUID.String(), PolicyVersion: r.CompatibilityPolicyVersion}, Lines: lines}
			prepared, err := s.prepareGrantOperationTx(txctx, scope.Tx, plan, boundOp)
			if err != nil {
				return err
			}
			boundOp = prepared
			gr, err := s.SettleGrantTx(txctx, scope.Tx, actor, plan, boundOp, GrantTxOptions{AllowOverflowMail: false})
			if err != nil {
				return err
			}
			awards = gr.Awards
			nested = &gr
			t := now
			r.ClaimedAt, r.ReadAt, r.Shown = &t, &t, false
		} else if r.ReadAt == nil {
			t := now
			r.ReadAt = &t
		}
		if r.ReadAt != nil || r.ClaimedAt != nil {
			r.StateVersion++
			if err := s.Store.SaveMailStateTx(txctx, scope.Tx, r, oldVersion); err != nil {
				return err
			}
		}
		out = MID369Result{Changed: true, IsShown: boolInt(r.Shown), Rewards: awards, Grant: nested}
		if !wasNew || r.ReadAt != nil {
			out.IsNew = 0
		} else {
			out.IsNew = 1
		}
		raw, _ := json.Marshal(out)
		rr, err := receipt.New(boundOp, id, "I5_MAIL", "gxb.i5.mail369.v2", raw, fp)
		if err != nil {
			return err
		}
		rr.ActorAccountUID, rr.ContextID, rr.PolicyVersion = string(actor.AccountUID), actor.ContextID.UUID(), r.CompatibilityPolicyVersion
		put, err := s.Receipts.PutTx(txctx, scope.Tx, rr)
		if err != nil {
			return err
		}
		if !put.Inserted {
			recognizedReplay = true
			return decodeOuterObjectReceipt(put.Receipt, "gxb.i5.mail369.v1", "gxb.i5.mail369.v2", &out)
		}
		return nil
	})
	if err != nil {
		return MID369Result{}, err
	}
	if res.Reconciled {
		recognizedReplay = true
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			if err := decodeOuterObjectReceipt(r, "gxb.i5.mail369.v1", "gxb.i5.mail369.v2", &out); err != nil {
				return MID369Result{}, err
			}
		}
	}
	grants := []GrantResult{}
	if out.Grant != nil {
		grants = append(grants, *out.Grant)
	}
	proj, err := s.projectSettlement(ctx, actor, projectionGrants(grants, out.Rewards), op, recognizedReplay)
	if err != nil {
		return MID369Result{}, err
	}
	out.Projection, out.Replayed = proj, recognizedReplay
	return out, nil
}

func (s Service) ClaimMailBatch(ctx context.Context, actor identity.ActorContext, addrs []mail.Address, op operation.Context) (MID370Result, error) {
	ordered, err := mail.CanonicalAddresses(addrs)
	if err != nil || len(ordered) == 0 {
		return MID370Result{}, errors.New("empty or invalid mail batch")
	}
	key, err := mail.BatchSemanticKey(actor.PlayerID, ordered)
	if err != nil {
		return MID370Result{}, err
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "mail", Operation: "batch-claim", SemanticKey: key}
	fp, _ := receipt.FingerprintRequest(ordered)
	var out MID370Result
	boundOp := op
	recognizedReplay := false
	res, err := s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Store.FenceActorTx(txctx, scope.Tx, actor, op.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			recognizedReplay = true
			return decodeOuterObjectReceipt(prior, "gxb.i5.mail370.v1", "gxb.i5.mail370.v2", &out)
		}
		awards := []Award{}
		grants := []GrantResult{}
		for _, addr := range ordered {
			r, err := s.Store.LockMailTx(txctx, scope.Tx, actor.PlayerID, addr)
			if err != nil {
				if errors.Is(err, ErrMailNotFound) {
					continue
				}
				return err
			}
			if r.ClaimedAt != nil || len(r.Attachments) == 0 || !r.Claimable(op.StartedAt) {
				continue
			}
			lines := make([]grant.Line, 0, len(r.Attachments))
			for _, a := range r.Attachments {
				lines = append(lines, a.Line)
			}
			plan := grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "mail", Operation: "claim", BusinessKey: r.MailUUID.String(), PolicyVersion: r.CompatibilityPolicyVersion}, Lines: lines}
			prepared, err := s.prepareGrantOperationTx(txctx, scope.Tx, plan, boundOp)
			if err != nil {
				return err
			}
			boundOp = prepared
			gr, err := s.SettleGrantTx(txctx, scope.Tx, actor, plan, boundOp, GrantTxOptions{AllowOverflowMail: false})
			if err != nil {
				return err
			}
			grants = append(grants, gr)
			old := r.StateVersion
			t := op.StartedAt.UTC()
			r.ReadAt, r.ClaimedAt, r.Shown, r.StateVersion = &t, &t, false, r.StateVersion+1
			if err := s.Store.SaveMailStateTx(txctx, scope.Tx, r, old); err != nil {
				return err
			}
			awards = append(awards, gr.Awards...)
		}
		list, total, fresh, err := s.Store.ListMailTx(txctx, scope.Tx, actor.PlayerID, op.StartedAt.UTC(), 20)
		if err != nil {
			return err
		}
		out = MID370Result{Awards: awards, Mail: MailListResult{MailList: list, Total: total, NewMailTotal: fresh}, Grants: grants}
		raw, _ := json.Marshal(out)
		rr, err := receipt.New(boundOp, id, "I5_MAIL", "gxb.i5.mail370.v2", raw, fp)
		if err != nil {
			return err
		}
		rr.ActorAccountUID, rr.ContextID, rr.PolicyVersion = string(actor.AccountUID), actor.ContextID.UUID(), "r5-mail-v2"
		put, err := s.Receipts.PutTx(txctx, scope.Tx, rr)
		if err != nil {
			return err
		}
		if !put.Inserted {
			recognizedReplay = true
			return decodeOuterObjectReceipt(put.Receipt, "gxb.i5.mail370.v1", "gxb.i5.mail370.v2", &out)
		}
		return nil
	})
	if err != nil {
		return MID370Result{}, err
	}
	if res.Reconciled {
		recognizedReplay = true
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			if err := decodeOuterObjectReceipt(r, "gxb.i5.mail370.v1", "gxb.i5.mail370.v2", &out); err != nil {
				return MID370Result{}, err
			}
		}
	}
	proj, err := s.projectSettlement(ctx, actor, projectionGrants(out.Grants, out.Awards), op, recognizedReplay)
	if err != nil {
		return MID370Result{}, err
	}
	out.Projection, out.Replayed = proj, recognizedReplay
	return out, nil
}

func (s Service) ListObjectives(ctx context.Context, actor identity.ActorContext, family objective.StockFamily, now time.Time) ([]objective.Instance, []ObjectiveDefinition, error) {
	if s.Store == nil || !actor.PlayerID.Valid() || now.IsZero() {
		return nil, nil, errors.New("objective list input invalid")
	}
	instances, storedDefs, err := s.Store.ListObjectives(ctx, actor.PlayerID, family, now.UTC())
	if err != nil {
		return nil, nil, err
	}
	if len(instances) != len(storedDefs) {
		return nil, nil, errors.New("objective list definition cardinality mismatch")
	}
	outI := make([]objective.Instance, 0, len(instances))
	outD := make([]ObjectiveDefinition, 0, len(instances))
	for i, inst := range instances {
		def, err := s.resolveObjectiveDefinition(ctx, inst, storedDefs[i])
		if err != nil {
			return nil, nil, err
		}
		if def.Family != family {
			continue
		}
		outI = append(outI, inst)
		outD = append(outD, def)
	}
	return outI, outD, nil
}

func (s Service) ClaimObjective(ctx context.Context, actor identity.ActorContext, family objective.StockFamily, objectiveID int64, generationID string, op operation.Context) (ObjectiveClaimResult, error) {
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "objective", Operation: "claim", SemanticKey: fmt.Sprintf("%d:%d:%s", family, objectiveID, generationID)}
	fp, _ := receipt.FingerprintRequest(map[string]any{"family": int64(family), "objective_id": objectiveID, "generation_id": generationID})
	var out ObjectiveClaimResult
	boundOp := op
	recognizedReplay := false
	res, err := s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Store.FenceActorTx(txctx, scope.Tx, actor, op.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			recognizedReplay = true
			return decodeOuterObjectReceipt(prior, "gxb.i5.objective-claim.v1", "gxb.i5.objective-claim.v2", &out)
		}
		inst, storedDef, err := s.Store.LockObjectiveTx(txctx, scope.Tx, actor.PlayerID, family, objectiveID, generationID)
		if err != nil {
			return err
		}
		def, err := s.resolveObjectiveDefinitionTx(txctx, scope.Tx, inst, storedDef)
		if err != nil || def.Family != family {
			if err != nil {
				return err
			}
			return ErrObjectiveNotFound
		}
		if inst.ContentRevision != "" {
			boundOp, err = bindContentRevision(boundOp, inst.ContentRevision)
			if err != nil {
				return err
			}
		}
		old := inst.StateVersion
		next, err := objective.Claim(inst, op.StartedAt)
		if err != nil {
			return err
		}
		plan := def.Reward
		plan.PlayerID = actor.PlayerID
		plan.Source = grant.SourceIdentity{Domain: "objective", Operation: "claim", BusinessKey: fmt.Sprintf("%s:%d:%s:%s", inst.ProgramID, inst.ObjectiveID, inst.GenerationID, inst.DefinitionRevision), PolicyVersion: def.Reward.Source.PolicyVersion}
		prepared, err := s.prepareGrantOperationTx(txctx, scope.Tx, plan, boundOp)
		if err != nil {
			return err
		}
		boundOp = prepared
		gr, err := s.SettleGrantTx(txctx, scope.Tx, actor, plan, boundOp, GrantTxOptions{AllowOverflowMail: true})
		if err != nil {
			return err
		}
		if err := s.Store.SaveObjectiveTx(txctx, scope.Tx, next, old); err != nil {
			return err
		}
		out = ObjectiveClaimResult{Awards: gr.Awards, Huoyue: def.Huoyue, Grant: &gr}
		raw, _ := json.Marshal(out)
		rr, err := receipt.New(boundOp, id, "I5_OBJECTIVE", "gxb.i5.objective-claim.v2", raw, fp)
		if err != nil {
			return err
		}
		rr.ActorAccountUID, rr.ContextID, rr.PolicyVersion = string(actor.AccountUID), actor.ContextID.UUID(), def.Definition.DefinitionRevision
		put, err := s.Receipts.PutTx(txctx, scope.Tx, rr)
		if err != nil {
			return err
		}
		if !put.Inserted {
			recognizedReplay = true
			return decodeOuterObjectReceipt(put.Receipt, "gxb.i5.objective-claim.v1", "gxb.i5.objective-claim.v2", &out)
		}
		return nil
	})
	if err != nil {
		return ObjectiveClaimResult{}, err
	}
	if res.Reconciled {
		recognizedReplay = true
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			if err := decodeOuterObjectReceipt(r, "gxb.i5.objective-claim.v1", "gxb.i5.objective-claim.v2", &out); err != nil {
				return ObjectiveClaimResult{}, err
			}
		}
	}
	grants := []GrantResult{}
	if out.Grant != nil {
		grants = append(grants, *out.Grant)
	}
	proj, err := s.projectSettlement(ctx, actor, projectionGrants(grants, out.Awards), op, recognizedReplay)
	if err != nil {
		return ObjectiveClaimResult{}, err
	}
	out.Projection, out.Replayed = proj, recognizedReplay
	return out, nil
}

func (s Service) ClaimObjectiveByID(ctx context.Context, actor identity.ActorContext, objectiveID int64, generationHint string, op operation.Context) (ObjectiveClaimResult, error) {
	if objectiveID <= 0 {
		return ObjectiveClaimResult{}, ErrObjectiveNotFound
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "objective", Operation: "stock-claim", SemanticKey: fmt.Sprintf("%d:%s", objectiveID, generationHint)}
	fp, _ := receipt.FingerprintRequest(map[string]any{"objective_id": objectiveID, "generation_hint": generationHint})
	var out ObjectiveClaimResult
	boundOp := op
	recognizedReplay := false
	res, err := s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Store.FenceActorTx(txctx, scope.Tx, actor, op.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			recognizedReplay = true
			return decodeOuterObjectReceipt(prior, "gxb.i5.objective-stock-claim.v1", "gxb.i5.objective-stock-claim.v2", &out)
		}
		inst, storedDef, err := s.Store.LockObjectiveForClaimTx(txctx, scope.Tx, actor.PlayerID, objectiveID, generationHint)
		if err != nil {
			return err
		}
		def, err := s.resolveObjectiveDefinitionTx(txctx, scope.Tx, inst, storedDef)
		if err != nil {
			return err
		}
		if inst.ContentRevision != "" {
			boundOp, err = bindContentRevision(boundOp, inst.ContentRevision)
			if err != nil {
				return err
			}
		}
		old := inst.StateVersion
		next, err := objective.Claim(inst, op.StartedAt)
		if err != nil {
			return err
		}
		plan := def.Reward
		plan.PlayerID = actor.PlayerID
		plan.Source = grant.SourceIdentity{Domain: "objective", Operation: "claim", BusinessKey: fmt.Sprintf("%s:%d:%s:%s", inst.ProgramID, inst.ObjectiveID, inst.GenerationID, inst.DefinitionRevision), PolicyVersion: def.Reward.Source.PolicyVersion}
		prepared, err := s.prepareGrantOperationTx(txctx, scope.Tx, plan, boundOp)
		if err != nil {
			return err
		}
		boundOp = prepared
		gr, err := s.SettleGrantTx(txctx, scope.Tx, actor, plan, boundOp, GrantTxOptions{AllowOverflowMail: true})
		if err != nil {
			return err
		}
		if err := s.Store.SaveObjectiveTx(txctx, scope.Tx, next, old); err != nil {
			return err
		}
		out = ObjectiveClaimResult{Awards: gr.Awards, Huoyue: def.Huoyue, Grant: &gr}
		raw, _ := json.Marshal(out)
		rr, err := receipt.New(boundOp, id, "I5_OBJECTIVE", "gxb.i5.objective-stock-claim.v2", raw, fp)
		if err != nil {
			return err
		}
		rr.ActorAccountUID, rr.ContextID, rr.PolicyVersion = string(actor.AccountUID), actor.ContextID.UUID(), def.Definition.DefinitionRevision
		put, err := s.Receipts.PutTx(txctx, scope.Tx, rr)
		if err != nil {
			return err
		}
		if !put.Inserted {
			recognizedReplay = true
			return decodeOuterObjectReceipt(put.Receipt, "gxb.i5.objective-stock-claim.v1", "gxb.i5.objective-stock-claim.v2", &out)
		}
		return nil
	})
	if err != nil {
		return ObjectiveClaimResult{}, err
	}
	if res.Reconciled {
		recognizedReplay = true
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			if err := decodeOuterObjectReceipt(r, "gxb.i5.objective-stock-claim.v1", "gxb.i5.objective-stock-claim.v2", &out); err != nil {
				return ObjectiveClaimResult{}, err
			}
		}
	}
	grants := []GrantResult{}
	if out.Grant != nil {
		grants = append(grants, *out.Grant)
	}
	proj, err := s.projectSettlement(ctx, actor, projectionGrants(grants, out.Awards), op, recognizedReplay)
	if err != nil {
		return ObjectiveClaimResult{}, err
	}
	out.Projection, out.Replayed = proj, recognizedReplay
	return out, nil
}

// ApplyObjectiveFactTx is the I5 same-transaction hook for later source owners.
// The caller supplies a definition selected from canonical content policy; raw
// MIDs are never facts and this function does not open a nested transaction.
func (s Service) ApplyObjectiveFactTx(ctx context.Context, t tx.Tx, def ObjectiveDefinition, inst objective.Instance, fact objective.Fact, op operation.Context) (objective.Instance, bool, error) {
	key, err := fact.Key()
	if err != nil {
		return objective.Instance{}, false, err
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(fact.PlayerID), 10), Domain: "objective-fact", Operation: def.Definition.ProgramID, SemanticKey: key + ":" + strconv.FormatInt(def.Definition.ObjectiveID, 10)}
	fp, _ := receipt.FingerprintRequest(fact)
	if prior, ok, err := s.Receipts.FindTx(ctx, t, id); err != nil {
		return objective.Instance{}, false, err
	} else if ok {
		if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
			return objective.Instance{}, false, &receipt.ConflictError{Identity: id}
		}
		return inst, false, nil
	}
	if inst.ContentRevision != "" {
		revision, err := requireContentRevision(op)
		if err != nil {
			return objective.Instance{}, false, err
		}
		if revision != inst.ContentRevision {
			return objective.Instance{}, false, ErrContentRevisionConflict
		}
	}
	if err := validateObjectivePair(inst, def); err != nil {
		return objective.Instance{}, false, err
	}
	old := inst.StateVersion
	next, changed, err := objective.ApplyFact(inst, def.Definition, fact, op.StartedAt)
	if err != nil || !changed {
		return next, changed, err
	}
	if err := s.Store.SaveObjectiveTx(ctx, t, next, old); err != nil {
		return objective.Instance{}, false, err
	}
	rr, err := receipt.New(op, id, "I5_OBJECTIVE_FACT", "gxb.i5.objective-fact.v1", json.RawMessage(`{"applied":true}`), fp)
	if err != nil {
		return objective.Instance{}, false, err
	}
	rr.PolicyVersion = def.Definition.DefinitionRevision
	_, err = s.Receipts.PutTx(ctx, t, rr)
	return next, true, err
}

func (s Service) Redeem(ctx context.Context, actor identity.ActorContext, rawCode, platform string, op operation.Context) (RedeemResult, error) {
	if err := s.validate(); err != nil {
		return RedeemResult{}, err
	}
	normalized, err := redeem.Normalize(rawCode, redeem.ExactCode)
	if err != nil {
		return RedeemResult{}, ErrRedeemInvalid
	}
	digest, err := redeem.LookupDigest(s.RedeemSecret, normalized)
	if err != nil {
		return RedeemResult{}, err
	}
	// No raw code enters the semantic key, receipt payload or durable logs.
	semantic := hex.EncodeToString(digest[:]) + ":" + strconv.FormatInt(int64(actor.PlayerID), 10)
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "redeem", Operation: "stock-mid230", SemanticKey: semantic}
	fp, _ := receipt.FingerprintRequest(map[string]any{"digest": digest[:], "platform": platform})
	var out RedeemResult
	recognizedReplay := false
	boundOp := op
	res, err := s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Store.FenceActorTx(txctx, scope.Tx, actor, op.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			recognizedReplay = true
			return decodeRedeemReceipt(prior, &out)
		}
		code, campaign, rewardPlan, err := s.Store.LockRedeemByDigestTx(txctx, scope.Tx, digest)
		if err != nil {
			return ErrRedeemInvalid
		}
		if code.Status != "ACTIVE" || campaign.PerSubjectCap != 1 {
			// Stock MID230 has no semantic slot/nonce. Multiple uses of the same
			// code by the same subject cannot be distinguished from retry.
			return ErrRedeemInvalid
		}
		subjectType, subjectID, err := redeemSubject(campaign.Campaign.Subject, actor)
		if err != nil {
			return ErrRedeemInvalid
		}
		if _, exists, err := s.Store.FindRedemptionTx(txctx, scope.Tx, code.CodeID, string(subjectType), subjectID, 1); err != nil {
			return err
		} else if exists {
			return ErrRedeemInvalid
		}
		if campaign.TotalCap != nil {
			count, err := s.Store.CountCampaignRedemptionsTx(txctx, scope.Tx, campaign.CampaignID)
			if err != nil {
				return err
			}
			if count >= *campaign.TotalCap {
				return ErrRedeemInvalid
			}
		}

		rewardPlan.PlayerID = actor.PlayerID
		rewardPlan.Source = grant.SourceIdentity{Domain: "redeem", Operation: "redeem", BusinessKey: code.CodeID + ":" + string(subjectType) + ":" + subjectID, Occurrence: "1", PolicyVersion: campaign.Campaign.PolicyVersion}
		prepared, err := s.prepareGrantOperationTx(txctx, scope.Tx, rewardPlan, boundOp)
		if err != nil {
			return err
		}
		boundOp = prepared

		grantID, _, err := rewardPlan.ReceiptIdentities()
		if err != nil {
			return err
		}
		grantFP, err := receiptFingerprintForGrant(rewardPlan)
		if err != nil {
			return err
		}
		var (
			gr              GrantResult
			grantReplay     bool
			grantPF         grantPreflight
			contentRevision string
		)
		if prior, ok, err := s.findGrantReceiptTx(txctx, scope.Tx, rewardPlan, grantFP); err != nil {
			return err
		} else if ok {
			gr, err = decodeGrantReceiptResult(prior)
			if err != nil {
				return err
			}
			grantReplay = true
		} else {
			contentRevision, err = requireContentRevision(boundOp)
			if err != nil {
				return err
			}
			// CA1-R0: Redeem must acquire the complete lower-to-higher Grant
			// suffix before it reads progression eligibility. Force the accepted
			// 710 progression lock into that suffix even when the reward itself
			// does not otherwise depend on progression. This removes the latent
			// progression(710)->economy(700) inversion in the Pass509 flow.
			grantPF, err = s.preflightGrantTx(txctx, scope.Tx, rewardPlan, contentRevision, grantPreflightOptions{AllowOverflowMail: true, ForceProgression: true}, op.StartedAt.UTC())
			if err != nil {
				return err
			}
			if err := s.acquireGrantLocksTx(txctx, scope.Tx, actor.PlayerID, grantPF, op.StartedAt.UTC()); err != nil {
				return err
			}
			// If a semantic winner became visible while this transaction waited
			// for owner locks, replay it and skip provider/fungible mutation.
			if prior, ok, err := s.findGrantReceiptTx(txctx, scope.Tx, rewardPlan, grantFP); err != nil {
				return err
			} else if ok {
				gr, err = decodeGrantReceiptResult(prior)
				if err != nil {
					return err
				}
				grantReplay = true
			}
		}

		prog, err := s.Store.LockProgressionTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		ra := redeem.Actor{PlayerID: actor.PlayerID, AccountID: actor.AccountID, LogicalServerID: actor.LogicalServerID, Level: prog.Level}
		if err := redeem.Eligible(campaign.Campaign, ra, op.StartedAt.UTC()); err != nil {
			return ErrRedeemInvalid
		}
		if !grantReplay {
			if err := s.validatePartnerEntityLockedTx(txctx, scope.Tx, grantPF); err != nil {
				return err
			}
			gr, err = s.applyPreparedGrantTx(txctx, scope.Tx, actor, rewardPlan, boundOp, true, contentRevision, grantPF, grantID, grantFP)
			if err != nil {
				return err
			}
		}
		redemptionID, err := ids.NewUUID()
		if err != nil {
			return err
		}
		red := Redemption{RedemptionID: redemptionID.String(), CodeID: code.CodeID, SubjectType: string(subjectType), SubjectID: subjectID, Slot: 1, PlayerID: actor.PlayerID, AccountID: actor.AccountID, LogicalServerID: actor.LogicalServerID, RewardBundleRevisionID: campaign.RewardBundleRevisionID, GrantReceiptID: gr.ReceiptID, RedeemedAt: op.StartedAt.UTC(), Platform: platform, PolicyVersion: campaign.Campaign.PolicyVersion}
		if err := s.Store.InsertRedemptionTx(txctx, scope.Tx, red); err != nil {
			return err
		}
		if err := s.Store.AdvanceRedeemCodeTx(txctx, scope.Tx, code); err != nil {
			return err
		}
		out = RedeemResult{Awards: gr.Awards, Grant: &gr}
		raw, _ := json.Marshal(out)
		rr, err := receipt.New(boundOp, id, "I5_REDEEM", "gxb.i5.redeem.v2", raw, fp)
		if err != nil {
			return err
		}
		rr.ActorAccountUID, rr.ContextID, rr.PolicyVersion = string(actor.AccountUID), actor.ContextID.UUID(), campaign.Campaign.PolicyVersion
		put, err := s.Receipts.PutTx(txctx, scope.Tx, rr)
		if err != nil {
			return err
		}
		if !put.Inserted {
			recognizedReplay = true
			return decodeRedeemReceipt(put.Receipt, &out)
		}
		return nil
	})
	if err != nil {
		if errors.Is(err, ErrRedeemInvalid) {
			return RedeemResult{}, ErrRedeemInvalid
		}
		return RedeemResult{}, err
	}
	if res.Reconciled {
		recognizedReplay = true
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			if err := decodeRedeemReceipt(r, &out); err != nil {
				return RedeemResult{}, err
			}
		}
	}
	grants := []GrantResult{}
	if out.Grant != nil {
		grants = append(grants, *out.Grant)
	}
	proj, err := s.projectSettlement(ctx, actor, projectionGrants(grants, out.Awards), op, recognizedReplay)
	if err != nil {
		return RedeemResult{}, err
	}
	out.Projection, out.Replayed = proj, recognizedReplay
	return out, nil
}

func redeemSubject(t redeem.SubjectType, actor identity.ActorContext) (redeem.SubjectType, string, error) {
	switch t {
	case redeem.PlayerSubject:
		return t, strconv.FormatInt(int64(actor.PlayerID), 10), nil
	case redeem.AccountSubject:
		return t, actor.AccountID.UUID().String(), nil
	case redeem.PlayerOnLogicalServer:
		return t, fmt.Sprintf("%d:%d", actor.LogicalServerID, actor.PlayerID), nil
	case redeem.GlobalSingleUse:
		return t, "GLOBAL", nil
	default:
		return "", "", errors.New("unknown redeem subject")
	}
}

type AdminOperator struct {
	ID         string
	ReasonCode string
}

func (a AdminOperator) Validate() error {
	if strings.TrimSpace(a.ID) == "" || strings.TrimSpace(a.ReasonCode) == "" {
		return errors.New("admin operator identity and reason are required")
	}
	return nil
}

type AdminMailResult struct {
	MailUUID  string       `json:"mail_uuid"`
	Address   mail.Address `json:"address"`
	ReceiptID string       `json:"receipt_id"`
}

// AdminGrant is the I5 canonical operator seam. I11 owns authenticated operator
// transport and durable control-plane audit storage; it must call this command
// rather than editing economy rows. Target gameplay liveness is deliberately not
// required for an operator entitlement.
func (s Service) AdminGrant(ctx context.Context, admin AdminOperator, target identity.PlayerID, commandKey, policyVersion string, lines []grant.Line, op operation.Context) (GrantResult, error) {
	if err := admin.Validate(); err != nil {
		return GrantResult{}, err
	}
	if !target.Valid() || strings.TrimSpace(commandKey) == "" || strings.TrimSpace(policyVersion) == "" || s.Audit == nil {
		return GrantResult{}, errors.New("admin grant command incomplete or audit unavailable")
	}
	plan := grant.Plan{PlayerID: target, Source: grant.SourceIdentity{Domain: "admin", Operation: "grant", BusinessKey: admin.ID + ":" + commandKey, PolicyVersion: policyVersion}, Lines: append([]grant.Line(nil), lines...)}
	got, err := s.runGrant(ctx, identity.ActorContext{PlayerID: target}, plan, op, false)
	outcome := "COMMITTED"
	if err != nil {
		outcome = "REJECTED"
	}
	s.Audit.Emit(context.WithoutCancel(ctx), audit.Event{OccurredAt: op.StartedAt.UTC(), ActorKind: "AdminOperator", ActorID: admin.ID, Action: "grant", TargetKind: "player", TargetKey: strconv.FormatInt(int64(target), 10), Outcome: outcome, ReasonCode: admin.ReasonCode, CorrelationID: op.ID.String()})
	return got, err
}

// AdminSendMail creates the durable entitlement through the Mail owner. Bulk or
// cross-server recipient resolution belongs to I11; each resolved recipient is
// delivered through this same semantic command.
func (s Service) AdminSendMail(ctx context.Context, admin AdminOperator, target identity.PlayerID, ns mail.Namespace, commandKey, title, sender, body, policyVersion string, lines []grant.Line, expires *time.Time, op operation.Context) (AdminMailResult, error) {
	if err := admin.Validate(); err != nil {
		return AdminMailResult{}, err
	}
	if err := s.validate(); err != nil {
		return AdminMailResult{}, err
	}
	if !target.Valid() || !ns.Valid() || strings.TrimSpace(commandKey) == "" || strings.TrimSpace(policyVersion) == "" || s.Audit == nil {
		return AdminMailResult{}, errors.New("admin mail command incomplete or audit unavailable")
	}
	for _, line := range lines {
		if err := line.Validate(); err != nil {
			return AdminMailResult{}, err
		}
	}
	semanticRaw := admin.ID + "\x00" + commandKey
	semanticHash := sha256.Sum256([]byte(semanticRaw))
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(target), 10), Domain: "admin-mail", Operation: "deliver", SemanticKey: hex.EncodeToString(semanticHash[:])}
	fp, err := receipt.FingerprintRequest(map[string]any{"admin": admin.ID, "target": int64(target), "namespace": ns.String(), "title": title, "sender": sender, "body": body, "policy_version": policyVersion, "lines": lines, "expires": expires})
	if err != nil {
		return AdminMailResult{}, err
	}
	var out AdminMailResult
	res, err := s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			return json.Unmarshal(prior.ResultPayload, &out)
		}
		r, err := s.createMailTx(txctx, scope.Tx, target, ns, "ADMIN", "admin:"+admin.ID+":"+commandKey, title, sender, body, lines, op.StartedAt.UTC(), expires, policyVersion)
		if err != nil {
			return err
		}
		rr, err := receipt.New(op, id, "I5_ADMIN_MAIL", "gxb.i5.admin-mail.v1", json.RawMessage(`{"pending":true}`), fp)
		if err != nil {
			return err
		}
		out = AdminMailResult{MailUUID: r.MailUUID.String(), Address: r.Address, ReceiptID: rr.ID.String()}
		raw, err := json.Marshal(out)
		if err != nil {
			return err
		}
		rr.ResultPayload, rr.PolicyVersion = raw, policyVersion
		put, err := s.Receipts.PutTx(txctx, scope.Tx, rr)
		if err != nil {
			return err
		}
		if !put.Inserted {
			return json.Unmarshal(put.Receipt.ResultPayload, &out)
		}
		return nil
	})
	if err == nil && res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			err = json.Unmarshal(r.ResultPayload, &out)
		}
	}
	outcome := "COMMITTED"
	if err != nil {
		outcome = "REJECTED"
	}
	s.Audit.Emit(context.WithoutCancel(ctx), audit.Event{OccurredAt: op.StartedAt.UTC(), ActorKind: "AdminOperator", ActorID: admin.ID, Action: "mail.deliver", TargetKind: "player", TargetKey: strconv.FormatInt(int64(target), 10), Outcome: outcome, ReasonCode: admin.ReasonCode, CorrelationID: op.ID.String()})
	return out, err
}

func boolInt(v bool) int64 {
	if v {
		return 1
	}
	return 0
}

// StockBulkAwards requires numeric table_id. Named scalar resources are valid
// MID369 rewards but cannot be fabricated into MID370/MID230 numeric identities.
func StockBulkAwards(in []Award) ([]map[string]any, error) {
	out := make([]map[string]any, 0, len(in))
	for _, a := range in {
		if a.ItemNum <= 0 {
			continue
		}
		if a.TableID <= 0 {
			return nil, fmt.Errorf("numeric stock table_id unavailable for resource %q", a.ResourceKey)
		}
		out = append(out, map[string]any{"table_id": a.TableID, "item_num": a.ItemNum})
	}
	return out, nil
}

// StockRepresentableBulkAwards preserves the stock numeric award collection
// without inventing table IDs for semantic effects (for example PlayerExp).
// Those effects are projected through the global economy_ sideband instead.
func StockRepresentableBulkAwards(in []Award) []map[string]any {
	out := make([]map[string]any, 0, len(in))
	for _, a := range in {
		if a.ItemNum <= 0 || a.TableID <= 0 {
			continue
		}
		out = append(out, map[string]any{"table_id": a.TableID, "item_num": a.ItemNum})
	}
	return out
}

func StockMID369Rewards(in []Award) []map[string]any {
	out := make([]map[string]any, 0, len(in))
	for _, a := range in {
		if a.ItemNum <= 0 {
			continue
		}
		item := a.MailItem()
		if a.TableID <= 0 && a.ResourceKey == "" {
			continue
		}
		out = append(out, map[string]any{"item": item, "num": a.ItemNum})
	}
	return out
}

func sanitizeProgramID(s string) string { return strings.TrimSpace(s) }
