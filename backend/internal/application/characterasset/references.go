package characterasset

import (
	"context"
	"encoding/binary"
	"errors"
	"sort"
	"strings"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	HeroInstanceOwnerKind    = "character.hero-instance"
	PetInstanceOwnerKind     = "character.pet-instance"
	SavedPresetRootOwnerKind = "character.saved-preset-root"
	SavedPresetRootLockRank  = uint16(440)
)

var (
	ErrReferenceNotFound     = errors.New("character asset: reference not found")
	ErrReferenceInUse        = errors.New("character asset: reference in use")
	ErrInvalidReferenceGuard = errors.New("character asset: invalid reference guard plan")
)

func orderedInt64Bytes(v int64) []byte {
	return lockkey.Int64(v).Raw()
}

func compositeReferenceIdentity(pid identity.PlayerID, instanceID int64) (lockkey.Identity, error) {
	if !pid.Valid() || instanceID <= 0 {
		return lockkey.Identity{}, lockkey.ErrInvalidKey
	}
	out := make([]byte, 0, 16)
	out = append(out, orderedInt64Bytes(int64(pid))...)
	out = append(out, orderedInt64Bytes(instanceID)...)
	return lockkey.Bytes(out), nil
}

func decodeOrderedInt64(raw []byte) int64 {
	return int64(binary.BigEndian.Uint64(raw) ^ (uint64(1) << 63))
}

func decodeReferenceIdentity(id lockkey.Identity) (identity.PlayerID, int64, error) {
	if id.Kind != lockkey.IdentityBytes {
		return 0, 0, lockkey.ErrInvalidKey
	}
	raw := id.Raw()
	if len(raw) != 16 {
		return 0, 0, lockkey.ErrInvalidKey
	}
	pid := identity.PlayerID(decodeOrderedInt64(raw[:8]))
	instanceID := decodeOrderedInt64(raw[8:])
	if !pid.Valid() || instanceID <= 0 {
		return 0, 0, lockkey.ErrInvalidKey
	}
	return pid, instanceID, nil
}

func HeroReferenceLockKey(ref character.HeroRef) (lockkey.Key, error) {
	if err := ref.Validate(); err != nil {
		return lockkey.Key{}, err
	}
	id, err := compositeReferenceIdentity(ref.PlayerID, ref.PartnerID)
	if err != nil {
		return lockkey.Key{}, err
	}
	return lockkey.New(character.HeroInstanceLockRank, HeroInstanceOwnerKind, id)
}

func PetReferenceLockKey(ref character.PetRef) (lockkey.Key, error) {
	if err := ref.Validate(); err != nil {
		return lockkey.Key{}, err
	}
	id, err := compositeReferenceIdentity(ref.PlayerID, ref.PetID)
	if err != nil {
		return lockkey.Key{}, err
	}
	return lockkey.New(character.PetInstanceLockRank, PetInstanceOwnerKind, id)
}

func SavedPresetRootLockKey(pid identity.PlayerID) (lockkey.Key, error) {
	if !pid.Valid() {
		return lockkey.Key{}, lockkey.ErrInvalidKey
	}
	return lockkey.New(SavedPresetRootLockRank, SavedPresetRootOwnerKind, lockkey.Int64(int64(pid)))
}

func HeroReferenceFromLockKey(k lockkey.Key) (character.HeroRef, error) {
	if k.DomainRank != character.HeroInstanceLockRank || k.OwnerKind != HeroInstanceOwnerKind {
		return character.HeroRef{}, lockkey.ErrInvalidKey
	}
	pid, instanceID, err := decodeReferenceIdentity(k.Identity)
	if err != nil {
		return character.HeroRef{}, err
	}
	ref := character.HeroRef{PlayerID: pid, PartnerID: instanceID}
	return ref, ref.Validate()
}

func PetReferenceFromLockKey(k lockkey.Key) (character.PetRef, error) {
	if k.DomainRank != character.PetInstanceLockRank || k.OwnerKind != PetInstanceOwnerKind {
		return character.PetRef{}, lockkey.ErrInvalidKey
	}
	pid, instanceID, err := decodeReferenceIdentity(k.Identity)
	if err != nil {
		return character.PetRef{}, err
	}
	ref := character.PetRef{PlayerID: pid, PetID: instanceID}
	return ref, ref.Validate()
}

func SavedPresetRootPlayerFromLockKey(k lockkey.Key) (identity.PlayerID, error) {
	if k.DomainRank != SavedPresetRootLockRank || k.OwnerKind != SavedPresetRootOwnerKind || k.Identity.Kind != lockkey.IdentityInt64 {
		return 0, lockkey.ErrInvalidKey
	}
	raw := k.Identity.Raw()
	if len(raw) != 8 {
		return 0, lockkey.ErrInvalidKey
	}
	pid := identity.PlayerID(decodeOrderedInt64(raw))
	if !pid.Valid() {
		return 0, lockkey.ErrInvalidKey
	}
	return pid, nil
}

// HeroReferenceOwner is the narrow cross-family seam for planning and acquiring
// one canonical Hero instance lock. It exposes identity only, not mutable Hero
// state, and may not discover another lock after acquisition begins.
type HeroReferenceOwner interface {
	HeroReferenceLockKey(character.HeroRef) (lockkey.Key, error)
	LockHeroReferenceKeyTx(context.Context, tx.Tx, lockkey.Key, character.HeroRef) error
}

// PetReferenceOwner is the Pet equivalent of HeroReferenceOwner.
type PetReferenceOwner interface {
	PetReferenceLockKey(character.PetRef) (lockkey.Key, error)
	LockPetReferenceKeyTx(context.Context, tx.Tx, lockkey.Key, character.PetRef) error
}

// ReferenceGuardPlan is read-only preflight output. Locks must be complete and
// stable even when the target is currently unreferenced if the provider can
// concurrently create a reference to that target.
type ReferenceGuardPlan struct {
	ProviderID string
	Locks      []lockkey.Key
}

// CanonicalReferenceGuardPlan preserves provider ownership while exposing the
// one globally ordered lock set an orchestrator must acquire before any locked
// revalidation or removal mutation.
type CanonicalReferenceGuardPlan struct {
	Providers []ReferenceGuardPlan
	Locks     []lockkey.Key
}

func CanonicalizeReferenceGuardPlans(plans []ReferenceGuardPlan) (CanonicalReferenceGuardPlan, error) {
	if len(plans) == 0 {
		return CanonicalReferenceGuardPlan{}, ErrInvalidReferenceGuard
	}
	providers := make([]ReferenceGuardPlan, 0, len(plans))
	providerIDs := make(map[string]struct{}, len(plans))
	claimed := make([]lockkey.Key, 0)
	for _, plan := range plans {
		id := strings.TrimSpace(plan.ProviderID)
		if id == "" || id != plan.ProviderID {
			return CanonicalReferenceGuardPlan{}, ErrInvalidReferenceGuard
		}
		if _, exists := providerIDs[id]; exists {
			return CanonicalReferenceGuardPlan{}, ErrInvalidReferenceGuard
		}
		providerIDs[id] = struct{}{}
		if len(plan.Locks) == 0 {
			return CanonicalReferenceGuardPlan{}, ErrInvalidReferenceGuard
		}
		locks, err := lockkey.Canonical(plan.Locks)
		if err != nil {
			return CanonicalReferenceGuardPlan{}, ErrInvalidReferenceGuard
		}
		for _, k := range locks {
			for _, prior := range claimed {
				if lockkey.Compare(k, prior) == 0 {
					return CanonicalReferenceGuardPlan{}, ErrInvalidReferenceGuard
				}
			}
			claimed = append(claimed, k)
		}
		providers = append(providers, ReferenceGuardPlan{ProviderID: id, Locks: locks})
	}
	sort.Slice(providers, func(i, j int) bool { return providers[i].ProviderID < providers[j].ProviderID })
	locks, err := lockkey.Canonical(claimed)
	if err != nil {
		return CanonicalReferenceGuardPlan{}, ErrInvalidReferenceGuard
	}
	return CanonicalReferenceGuardPlan{Providers: providers, Locks: locks}, nil
}

func ValidateReferenceGuardPlan(providerID string, plan ReferenceGuardPlan) error {
	if strings.TrimSpace(providerID) == "" || plan.ProviderID != providerID {
		return ErrInvalidReferenceGuard
	}
	_, err := CanonicalizeReferenceGuardPlans([]ReferenceGuardPlan{plan})
	return err
}

// ReferenceGuardProvider acquires exactly a key returned by its own preflight.
// It has no mutation or detach method by design.
type ReferenceGuardProvider interface {
	ProviderID() string
	LockReferenceGuardKeyTx(context.Context, tx.Tx, lockkey.Key) error
}

type HeroRemovalGuard interface {
	ReferenceGuardProvider
	PreflightHeroRemovalTx(context.Context, tx.Queryer, character.HeroRef) (ReferenceGuardPlan, error)
	ValidateHeroRemovalLockedTx(context.Context, tx.Tx, character.HeroRef, ReferenceGuardPlan) error
}

type PetRemovalGuard interface {
	ReferenceGuardProvider
	PreflightPetRemovalTx(context.Context, tx.Queryer, character.PetRef) (ReferenceGuardPlan, error)
	ValidatePetRemovalLockedTx(context.Context, tx.Tx, character.PetRef, ReferenceGuardPlan) error
}
