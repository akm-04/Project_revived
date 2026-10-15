package spiritstore

import (
	"context"
	"encoding/binary"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	spirit "gxb.local/backend/v2/internal/domain/spirit"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const RootOwnerKind = "spirit.root"

func RootLockKey(pid identity.PlayerID) (lockkey.Key, error) {
	if !pid.Valid() {
		return lockkey.Key{}, spirit.ErrInvalid
	}
	return lockkey.New(spirit.RootLockRank, RootOwnerKind, lockkey.Int64(int64(pid)))
}
func (Store) ProviderID() string { return "spirit-instance-bindings" }
func (s Store) PreflightHeroRemovalTx(ctx context.Context, q tx.Queryer, ref character.HeroRef) (characterasset.ReferenceGuardPlan, error) {
	if ref.Validate() != nil {
		return characterasset.ReferenceGuardPlan{}, spirit.ErrInvalid
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
	if k.DomainRank != spirit.RootLockRank || k.OwnerKind != RootOwnerKind || k.Identity.Kind != lockkey.IdentityInt64 || len(k.Identity.Raw()) != 8 {
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
	f, e := s.ReadHeroTx(ctx, t, ref.PlayerID, ref.PartnerID)
	if e != nil {
		return e
	}
	for _, id := range f.Facts.Slots {
		if id > 0 {
			return characterasset.ErrReferenceInUse
		}
	}

	return nil
}

var _ characterasset.HeroRemovalGuard = Store{}
