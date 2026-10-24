package dormstore

import (
	"context"
	"encoding/binary"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const RootOwnerKind = "dorm-house.root"

func RootLockKey(pid identity.PlayerID) (lockkey.Key, error) {
	if !pid.Valid() {
		return lockkey.Key{}, dorm.ErrInvalidFacts
	}
	return lockkey.New(dorm.RootLockRank, RootOwnerKind, lockkey.Int64(int64(pid)))
}
func (Store) ProviderID() string { return "dorm-house-residency" }
func (s Store) PreflightHeroRemovalTx(ctx context.Context, q tx.Queryer, ref character.HeroRef) (characterasset.ReferenceGuardPlan, error) {
	if ref.Validate() != nil {
		return characterasset.ReferenceGuardPlan{}, dorm.ErrInvalidFacts
	}
	// Plan even when currently absent: a concurrent residency creator cannot
	// bypass a guard by racing the preflight lookup.
	k, e := RootLockKey(ref.PlayerID)
	if e != nil {
		return characterasset.ReferenceGuardPlan{}, e
	}
	return characterasset.ReferenceGuardPlan{ProviderID: s.ProviderID(), Locks: []lockkey.Key{k}}, nil
}
func (s Store) LockReferenceGuardKeyTx(ctx context.Context, t tx.Tx, k lockkey.Key) error {
	if k.DomainRank != dorm.RootLockRank || k.OwnerKind != RootOwnerKind || k.Identity.Kind != lockkey.IdentityInt64 || len(k.Identity.Raw()) != 8 {
		return characterasset.ErrInvalidReferenceGuard
	}
	pid := identity.PlayerID(int64(binary.BigEndian.Uint64(k.Identity.Raw()) ^ (uint64(1) << 63)))
	_, e := s.LockRootTx(ctx, t, pid)
	return e
}
func (s Store) ValidateHeroRemovalLockedTx(ctx context.Context, t tx.Tx, ref character.HeroRef, plan characterasset.ReferenceGuardPlan) error {
	if e := characterasset.ValidateReferenceGuardPlan(s.ProviderID(), plan); e != nil {
		return e
	}
	k, e := RootLockKey(ref.PlayerID)
	if e != nil || len(plan.Locks) != 1 || lockkey.Compare(k, plan.Locks[0]) != 0 {
		return characterasset.ErrInvalidReferenceGuard
	}
	f, e := s.ReadHeroTx(ctx, t, ref)
	if e != nil {
		return e
	}
	if f.HouseID != 0 {
		return characterasset.ErrReferenceInUse
	}
	// Retained nonresident equipment is inactive. It does not make every Girl
	// busy; retirement leaves a historical facet and alive consumers reject it.
	return nil
}

var _ characterasset.HeroRemovalGuard = Store{}
