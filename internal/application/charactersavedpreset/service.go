package charactersavedpreset

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	savedPresetReceiptSchema = "gxb.ca5.saved-preset-replace.v1"
	savedPresetPolicyVersion = "pass563-ca5-3-contract"
)

// ActorFencer is the accepted I3 liveness seam. CA5-3 does not own identity or
// gameplay-context lifecycle state.
type ActorFencer interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type MutationService struct {
	Runner      tx.Runner
	Store       Store
	Fencer      ActorFencer
	References  ReferenceOwners
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
}

type MutationResult struct {
	Wire         WireProjection
	StateVersion int64
	Mutated      bool
	Replayed     bool
}

type savedPresetReceiptResult struct {
	SaveTeam     string `json:"save_team"`
	SaveTeamName string `json:"save_team_name"`
	SavePet      string `json:"save_pet"`
	StateVersion int64  `json:"state_version"`
	Mutated      bool   `json:"mutated"`
}

type mutationLockPlan struct {
	Refs   ReferenceSet
	Heroes []keyedHero
	Pets   []keyedPet
	Root   lockkey.Key
}

func savedPresetProfile() tx.Profile {
	return tx.Profile{
		Name:               "CA5_3_SAVED_PRESET",
		AcquireTimeout:     2 * time.Second,
		LockTimeout:        2 * time.Second,
		StatementTimeout:   5 * time.Second,
		TransactionTimeout: 8 * time.Second,
		CleanupTimeout:     2 * time.Second,
		ReconcileTimeout:   5 * time.Second,
		OperationTimeout:   12 * time.Second,
	}
}

func (s MutationService) validate() error {
	if s.Runner.DB == nil || s.Store == nil || s.Fencer == nil || s.References.Heroes == nil || s.References.Pets == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return errors.New("saved preset: incomplete mutation service")
	}
	return nil
}

func savedPresetReceiptIdentity(playerID identity.PlayerID, op operation.Context) receipt.Identity {
	return receipt.Identity{
		OwnerKind:   "player",
		OwnerKey:    strconv.FormatInt(int64(playerID), 10),
		Domain:      "character-saved-preset",
		Operation:   "replace",
		SemanticKey: op.ID.String(),
	}
}

func savedPresetFingerprint(cmd Command) ([32]byte, error) {
	payload := map[string]any{
		"team_str":      cmd.TeamString,
		"team_name_str": cmd.TeamNameString,
		"pet_present":   cmd.PetPresent,
	}
	if cmd.PetPresent {
		payload["pet_str"] = cmd.PetString
	}
	return receipt.FingerprintRequest(payload)
}

func decodeSavedPresetReceipt(r receipt.Receipt) (MutationResult, error) {
	if r.ResultSchema != savedPresetReceiptSchema {
		return MutationResult{}, fmt.Errorf("saved preset: unsupported receipt schema %q", r.ResultSchema)
	}
	var stored savedPresetReceiptResult
	if err := json.Unmarshal(r.ResultPayload, &stored); err != nil {
		return MutationResult{}, err
	}
	if stored.StateVersion <= 0 {
		return MutationResult{}, errors.New("saved preset: invalid receipt result")
	}
	return MutationResult{
		Wire: WireProjection{
			SaveTeam:     stored.SaveTeam,
			SaveTeamName: stored.SaveTeamName,
			SavePet:      stored.SavePet,
		},
		StateVersion: stored.StateVersion,
		Mutated:      stored.Mutated,
		Replayed:     true,
	}, nil
}

func putSavedPresetReceipt(ctx context.Context, s MutationService, t tx.Tx, actor identity.ActorContext, op operation.Context, id receipt.Identity, fp [32]byte, result MutationResult) error {
	payload, err := json.Marshal(savedPresetReceiptResult{
		SaveTeam:     result.Wire.SaveTeam,
		SaveTeamName: result.Wire.SaveTeamName,
		SavePet:      result.Wire.SavePet,
		StateVersion: result.StateVersion,
		Mutated:      result.Mutated,
	})
	if err != nil {
		return err
	}
	rr, err := receipt.New(op, id, "CA5_3_SAVED_PRESET", savedPresetReceiptSchema, payload, fp)
	if err != nil {
		return err
	}
	rr.ActorAccountUID = string(actor.AccountUID)
	rr.ContextID = actor.ContextID.UUID()
	rr.PolicyVersion = savedPresetPolicyVersion
	_, err = s.Receipts.PutTx(ctx, t, rr)
	return err
}

func findSavedPresetReceipt(ctx context.Context, reader receipt.Reader, id receipt.Identity, fp [32]byte) (MutationResult, bool, error) {
	got, ok, err := reader.Find(ctx, id)
	if err != nil || !ok {
		return MutationResult{}, ok, err
	}
	if !bytes.Equal(got.RequestFingerprint[:], fp[:]) {
		return MutationResult{}, false, &receipt.ConflictError{Identity: id}
	}
	out, err := decodeSavedPresetReceipt(got)
	return out, true, err
}

func findSavedPresetReceiptTx(ctx context.Context, store receipt.Store, q tx.Queryer, id receipt.Identity, fp [32]byte) (MutationResult, bool, error) {
	got, ok, err := store.FindTx(ctx, q, id)
	if err != nil || !ok {
		return MutationResult{}, ok, err
	}
	if !bytes.Equal(got.RequestFingerprint[:], fp[:]) {
		return MutationResult{}, false, &receipt.ConflictError{Identity: id}
	}
	out, err := decodeSavedPresetReceipt(got)
	return out, true, err
}

func resolveCommandAgainst(current character.SavedPresetAggregate, cmd Command, full []character.SavedPresetLane) ([]character.SavedPresetLane, error) {
	if cmd.FullForm() {
		return cloneSavedPresetLanes(full), nil
	}
	return ResolveLegacyDelete(current, cmd)
}

func (s MutationService) buildLockPlan(playerID identity.PlayerID, old, desired []character.SavedPresetLane) (mutationLockPlan, error) {
	refs := UnionReferences(CollectReferences(old), CollectReferences(desired))
	plan := mutationLockPlan{Refs: refs}
	for _, ref := range refs.Heroes {
		if ref.PlayerID != playerID {
			return mutationLockPlan{}, errors.New("saved preset: foreign Hero reference")
		}
		k, err := s.References.Heroes.HeroReferenceLockKey(ref)
		if err != nil {
			return mutationLockPlan{}, err
		}
		if k.DomainRank != character.HeroInstanceLockRank {
			return mutationLockPlan{}, errors.New("saved preset: invalid Hero reference lock rank")
		}
		plan.Heroes = append(plan.Heroes, keyedHero{ref: ref, key: k})
	}
	for _, ref := range refs.Pets {
		if ref.PlayerID != playerID {
			return mutationLockPlan{}, errors.New("saved preset: foreign Pet reference")
		}
		k, err := s.References.Pets.PetReferenceLockKey(ref)
		if err != nil {
			return mutationLockPlan{}, err
		}
		if k.DomainRank != character.PetInstanceLockRank {
			return mutationLockPlan{}, errors.New("saved preset: invalid Pet reference lock rank")
		}
		plan.Pets = append(plan.Pets, keyedPet{ref: ref, key: k})
	}
	sort.Slice(plan.Heroes, func(i, j int) bool { return lockkey.Compare(plan.Heroes[i].key, plan.Heroes[j].key) < 0 })
	sort.Slice(plan.Pets, func(i, j int) bool { return lockkey.Compare(plan.Pets[i].key, plan.Pets[j].key) < 0 })
	root, err := characterasset.SavedPresetRootLockKey(playerID)
	if err != nil {
		return mutationLockPlan{}, err
	}
	plan.Root = root
	if len(plan.Heroes) > 0 && len(plan.Pets) > 0 && plan.Heroes[len(plan.Heroes)-1].key.DomainRank >= plan.Pets[0].key.DomainRank {
		return mutationLockPlan{}, errors.New("saved preset: invalid Hero/Pet lock ordering")
	}
	if len(plan.Heroes) > 0 && plan.Heroes[len(plan.Heroes)-1].key.DomainRank >= plan.Root.DomainRank {
		return mutationLockPlan{}, errors.New("saved preset: invalid Hero/root lock ordering")
	}
	if len(plan.Pets) > 0 && plan.Pets[len(plan.Pets)-1].key.DomainRank >= plan.Root.DomainRank {
		return mutationLockPlan{}, errors.New("saved preset: invalid Pet/root lock ordering")
	}
	return plan, nil
}

func (s MutationService) acquirePlan(ctx context.Context, t tx.Tx, plan mutationLockPlan) error {
	for _, x := range plan.Heroes {
		if err := s.References.Heroes.LockHeroReferenceKeyTx(ctx, t, x.key, x.ref); err != nil {
			return err
		}
	}
	for _, x := range plan.Pets {
		if err := s.References.Pets.LockPetReferenceKeyTx(ctx, t, x.key, x.ref); err != nil {
			return err
		}
	}
	return nil
}

// Replace executes stock MID1793 semantics over the CA5-2 canonical aggregate.
// It owns no Hero/Pet persistence and performs no timed-gameplay decision.
func (s MutationService) Replace(ctx context.Context, actor identity.ActorContext, cmd Command, op operation.Context) (MutationResult, error) {
	if err := s.validate(); err != nil {
		return MutationResult{}, err
	}
	if !actor.PlayerID.Valid() || op.ID.IsZero() || op.StartedAt.IsZero() {
		return MutationResult{}, errors.New("saved preset: invalid mutation request")
	}

	var full []character.SavedPresetLane
	var err error
	if cmd.FullForm() {
		full, err = ParseFullCommand(actor.PlayerID, cmd)
	} else {
		err = ValidateLegacyCommandShape(actor.PlayerID, cmd)
	}
	if err != nil {
		return MutationResult{}, err
	}

	id := savedPresetReceiptIdentity(actor.PlayerID, op)
	fp, err := savedPresetFingerprint(cmd)
	if err != nil {
		return MutationResult{}, err
	}
	if prior, ok, err := findSavedPresetReceipt(ctx, s.ReceiptRead, id, fp); err != nil {
		return MutationResult{}, err
	} else if ok {
		return prior, nil
	}

	var out MutationResult
	// The accepted foundation default is READ COMMITTED when correctness is closed
	// by explicit canonical owner locks/fences. CA5-3 already closes the complete
	// Hero(410)->Pet(430)->SavedPresetRoot(440) synchronization plan, rereads and
	// re-resolves after the root lock, enforces Covers(plan), CASes the root, and
	// records the semantic receipt in the same transaction. PostgreSQL 18.6 native
	// A03 evidence showed SERIALIZABLE could repeatedly cancel otherwise-correct
	// converged same-player operations as SSI pivots at receipt insertion. Keep the
	// explicit lock/CAS contract as the serialization mechanism and use the
	// foundation-default isolation rather than masking that SSI pattern with a
	// larger retry budget.
	res, err := s.Runner.Run(ctx, op, savedPresetProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, op.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := findSavedPresetReceiptTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			out = prior
			return nil
		}

		preflight, err := s.Store.ReadSavedPresetAggregateTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		// Full-form desired state is fixed by the request. A legacy pet-less delete
		// can only preserve/remove current lanes, so its complete synchronization
		// plan is the preflight old-reference set; do not reject ambiguity/staleness
		// from an unlocked snapshot. Resolve legacy intent only after the root lock.
		preDesired := full
		if !cmd.FullForm() {
			preDesired = preflight.Lanes
		}
		plan, err := s.buildLockPlan(actor.PlayerID, preflight.Lanes, preDesired)
		if err != nil {
			return err
		}
		if err := s.acquirePlan(txctx, scope.Tx, plan); err != nil {
			return err
		}
		lockedRoot, err := s.Store.LockSavedPresetRootTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}

		// A waiter can miss another same-op receipt before blocking on canonical
		// owner locks. Recheck after the root lock before any mutation.
		if prior, ok, err := findSavedPresetReceiptTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			out = prior
			return nil
		}

		locked, err := s.Store.ReadSavedPresetAggregateTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		if locked.Root.StateVersion != lockedRoot.StateVersion {
			return tx.MarkDefiniteAbort(errors.New("saved preset: root changed during locked reread"))
		}
		desiredLanes, err := resolveCommandAgainst(locked, cmd, full)
		if err != nil {
			return err
		}
		observed := UnionReferences(CollectReferences(locked.Lanes), CollectReferences(desiredLanes))
		if !plan.Refs.Covers(observed) {
			return tx.MarkDefiniteAbort(errors.New("saved preset: locked reread revealed unplanned reference"))
		}

		mutated := !SavedPresetLanesEqual(locked.Lanes, desiredLanes)
		resultAgg := locked
		if mutated {
			desired := character.SavedPresetAggregate{Root: locked.Root, Lanes: cloneSavedPresetLanes(desiredLanes)}
			desired.Root.StateVersion = locked.Root.StateVersion + 1
			desired.Root.UpdatedAt = op.StartedAt.UTC()
			if err := s.Store.ReplaceSavedPresetAggregateTx(txctx, scope.Tx, desired, locked.Root.StateVersion); err != nil {
				return err
			}
			resultAgg = desired
		}
		wire, err := ProjectWire(resultAgg)
		if err != nil {
			return err
		}
		out = MutationResult{Wire: wire, StateVersion: resultAgg.Root.StateVersion, Mutated: mutated}
		return putSavedPresetReceipt(txctx, s, scope.Tx, actor, op, id, fp, out)
	})
	if err != nil {
		return MutationResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			out, err = decodeSavedPresetReceipt(r)
			if err != nil {
				return MutationResult{}, err
			}
		}
	}
	return out, nil
}
