package characterhero

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// HeroRosterTxContent is the exact-revision, caller-queryer content surface
// needed to reconstruct stock Hero roster views inside another owner's
// transaction (notably MID1 bootstrap projection).
type HeroRosterTxContent interface {
	HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error)
	heroFumoPositionTxReader
	heroFumoTargetTxReader
	characterasset.AppearanceTxContent
}

// HeroRosterTxAppearanceStore is the owner-scoped durable appearance surface
// borrowed by read-only projection. It does not grant mutation ownership.
type HeroRosterTxAppearanceStore interface {
	ListHeroSkinEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.HeroSkinEntitlement, error)
	ListHeroLIVEEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.HeroLIVEEntitlement, error)
}

// BuildRosterViewsTx enriches already-owned Hero rows for stock projection
// without opening a second transaction or changing durable state. Hero kind is
// resolved from each row's immutable creation revision, while current Fumo and
// appearance projection use the caller-pinned active roster revision. Timed
// appearance is qualified once at observedAt for the whole caller operation.
func BuildRosterViewsTx(ctx context.Context, q tx.Queryer, rosterRevision string, heroes []character.Hero, observedAt time.Time, store HeroRosterTxAppearanceStore, content HeroRosterTxContent) ([]HeroRosterView, error) {
	if q == nil || store == nil || content == nil || len(rosterRevision) != 64 || observedAt.IsZero() {
		return nil, errors.New("character hero: invalid roster projection input")
	}
	out := make([]HeroRosterView, 0, len(heroes))
	for i := range heroes {
		h := heroes[i]
		kind, err := content.HeroKindTx(ctx, q, h.CreationContentRevision, h.TableID)
		if err != nil {
			return nil, err
		}
		h.Kind = kind
		if err := h.Validate(); err != nil {
			return nil, err
		}
		view := HeroRosterView{Hero: h}
		if kind == character.NormalHero {
			levels, err := deriveFumoLevelsTxWith(ctx, q, rosterRevision, h, content, content)
			if err != nil {
				return nil, err
			}
			view.FumoLevels = levels
		}
		skins, err := store.ListHeroSkinEntitlementsTx(ctx, q, h.PlayerID, h.PartnerID)
		if err != nil {
			return nil, err
		}
		lives, err := store.ListHeroLIVEEntitlementsTx(ctx, q, h.PlayerID, h.PartnerID)
		if err != nil {
			return nil, err
		}
		appearance, err := characterasset.BuildEffectiveHeroAppearanceTx(ctx, q, rosterRevision, h, skins, lives, observedAt, content)
		if err != nil {
			return nil, err
		}
		view.Appearance = appearance
		out = append(out, view)
	}
	return out, nil
}
