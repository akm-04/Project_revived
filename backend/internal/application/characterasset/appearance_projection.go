package characterasset

import (
	"context"
	"errors"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// QualifiedSkinEntitlement is the effective, content-qualified skin ownership
// projected at one observation instant. ExpiresAt=nil means permanent.
type QualifiedSkinEntitlement struct {
	ModelID   int64
	ExpiresAt *time.Time
}

// QualifiedLIVEState is durable paid type-2 LIVE state after content/family
// qualification. Type-1 automatic dynamic-card behaviour never appears here.
type QualifiedLIVEState struct {
	ModelID int64
	IsShow  bool
}

// EffectiveHeroAppearance separates durable raw selector intent from the
// content/time-qualified state safe to expose to stock clients and CA8.
type EffectiveHeroAppearance struct {
	OwnerStateVersion int64
	ObservedAt        time.Time
	CurrentSkinID     int64
	IllusionSkinID    int64
	Skins             []QualifiedSkinEntitlement
	LIVE              []QualifiedLIVEState
}

func (v EffectiveHeroAppearance) Validate() error {
	if v.OwnerStateVersion <= 0 || v.ObservedAt.IsZero() || v.CurrentSkinID < 0 || v.IllusionSkinID < -1 {
		return errors.New("character asset: invalid effective Hero appearance")
	}
	seenSkin := map[int64]struct{}{}
	for _, skin := range v.Skins {
		if skin.ModelID <= 0 {
			return errors.New("character asset: invalid qualified skin")
		}
		if _, dup := seenSkin[skin.ModelID]; dup {
			return errors.New("character asset: duplicate qualified skin")
		}
		seenSkin[skin.ModelID] = struct{}{}
		if skin.ExpiresAt != nil && skin.ExpiresAt.IsZero() {
			return errors.New("character asset: invalid qualified skin expiry")
		}
	}
	seenLIVE := map[int64]struct{}{}
	for _, live := range v.LIVE {
		if live.ModelID <= 0 {
			return errors.New("character asset: invalid qualified LIVE state")
		}
		if _, dup := seenLIVE[live.ModelID]; dup {
			return errors.New("character asset: duplicate qualified LIVE state")
		}
		seenLIVE[live.ModelID] = struct{}{}
	}
	return nil
}

// EffectivePetAppearance is Pet-owner appearance state qualified against the
// active appearance revision. A stale/unqualified raw active style projects 0.
type EffectivePetAppearance struct {
	OwnerStateVersion int64
	ObservedAt        time.Time
	ActiveStyle       int64
	OwnedStyles       []int64
}

func (v EffectivePetAppearance) Validate() error {
	if v.OwnerStateVersion <= 0 || v.ObservedAt.IsZero() || v.ActiveStyle < 0 {
		return errors.New("character asset: invalid effective Pet appearance")
	}
	seen := map[int64]struct{}{}
	for _, id := range v.OwnedStyles {
		if id <= 0 {
			return errors.New("character asset: invalid qualified Pet style")
		}
		if _, dup := seen[id]; dup {
			return errors.New("character asset: duplicate qualified Pet style")
		}
		seen[id] = struct{}{}
	}
	if v.ActiveStyle > 0 {
		if _, ok := seen[v.ActiveStyle]; !ok {
			return errors.New("character asset: active Pet style not owned")
		}
	}
	return nil
}

type AppearanceReadContent interface {
	AppearanceSkin(context.Context, string, int64) (AppearanceSkinDefinition, bool, error)
	AppearanceLIVE(context.Context, string, int64) (AppearanceLIVEDefinition, bool, error)
	AppearancePetStyle(context.Context, string, int64) (AppearancePetStyleDefinition, bool, error)
}

type AppearanceTxContent interface {
	AppearanceSkinTx(context.Context, tx.Queryer, string, int64) (AppearanceSkinDefinition, bool, error)
	AppearanceLIVETx(context.Context, tx.Queryer, string, int64) (AppearanceLIVEDefinition, bool, error)
	AppearancePetStyleTx(context.Context, tx.Queryer, string, int64) (AppearancePetStyleDefinition, bool, error)
}

type skinLookup func(int64) (AppearanceSkinDefinition, bool, error)
type liveLookup func(int64) (AppearanceLIVEDefinition, bool, error)
type petStyleLookup func(int64) (AppearancePetStyleDefinition, bool, error)

func BuildEffectiveHeroAppearance(ctx context.Context, revision string, h character.Hero, skins []character.HeroSkinEntitlement, lives []character.HeroLIVEEntitlement, observedAt time.Time, content AppearanceReadContent) (EffectiveHeroAppearance, error) {
	if content == nil {
		return EffectiveHeroAppearance{}, errors.New("character asset: nil appearance read content")
	}
	return buildEffectiveHeroAppearance(h, skins, lives, observedAt,
		func(modelID int64) (AppearanceSkinDefinition, bool, error) {
			return content.AppearanceSkin(ctx, revision, modelID)
		},
		func(modelID int64) (AppearanceLIVEDefinition, bool, error) {
			return content.AppearanceLIVE(ctx, revision, modelID)
		},
	)
}

func BuildEffectiveHeroAppearanceTx(ctx context.Context, q tx.Queryer, revision string, h character.Hero, skins []character.HeroSkinEntitlement, lives []character.HeroLIVEEntitlement, observedAt time.Time, content AppearanceTxContent) (EffectiveHeroAppearance, error) {
	if q == nil || content == nil {
		return EffectiveHeroAppearance{}, errors.New("character asset: invalid appearance transaction content")
	}
	return buildEffectiveHeroAppearance(h, skins, lives, observedAt,
		func(modelID int64) (AppearanceSkinDefinition, bool, error) {
			return content.AppearanceSkinTx(ctx, q, revision, modelID)
		},
		func(modelID int64) (AppearanceLIVEDefinition, bool, error) {
			return content.AppearanceLIVETx(ctx, q, revision, modelID)
		},
	)
}

func buildEffectiveHeroAppearance(h character.Hero, skins []character.HeroSkinEntitlement, lives []character.HeroLIVEEntitlement, observedAt time.Time, skinDef skinLookup, liveDef liveLookup) (EffectiveHeroAppearance, error) {
	if h.Validate() != nil || len(h.CreationContentRevision) != 64 || observedAt.IsZero() || skinDef == nil || liveDef == nil {
		return EffectiveHeroAppearance{}, errors.New("character asset: invalid Hero appearance qualification input")
	}
	at := observedAt.UTC()
	effective := make(map[int64]QualifiedSkinEntitlement, len(skins))
	for _, ent := range skins {
		if ent.PlayerID != h.PlayerID || ent.PartnerID != h.PartnerID || ent.Validate() != nil || !ent.EffectiveAt(at) {
			continue
		}
		def, ok, err := skinDef(ent.ModelID)
		if err != nil {
			return EffectiveHeroAppearance{}, err
		}
		if !ok || def.Validate() != nil || def.HeroOriginTableID != h.OriginTableID {
			continue
		}
		if _, dup := effective[ent.ModelID]; dup {
			return EffectiveHeroAppearance{}, errors.New("character asset: duplicate durable Hero skin entitlement")
		}
		q := QualifiedSkinEntitlement{ModelID: ent.ModelID}
		if ent.ExpiresAt != nil {
			t := ent.ExpiresAt.UTC()
			q.ExpiresAt = &t
		}
		effective[ent.ModelID] = q
	}
	models := make([]int64, 0, len(effective))
	for modelID := range effective {
		models = append(models, modelID)
	}
	sort.Slice(models, func(i, j int) bool { return models[i] < models[j] })
	qualifiedSkins := make([]QualifiedSkinEntitlement, 0, len(models))
	for _, modelID := range models {
		qualifiedSkins = append(qualifiedSkins, effective[modelID])
	}

	current := h.CurrentSkinID
	if current > 0 {
		if _, ok := effective[current]; !ok {
			current = 0
		}
	}
	illusion := h.IllusionSkinID
	if illusion > 1 {
		if _, ok := effective[illusion]; !ok {
			illusion = character.DefaultIllusionSkinID
		}
	}

	qualifiedLIVE := make([]QualifiedLIVEState, 0, len(lives))
	if h.Kind == character.NormalHero {
		seen := make(map[int64]struct{}, len(lives))
		for _, ent := range lives {
			if ent.PlayerID != h.PlayerID || ent.PartnerID != h.PartnerID || ent.Validate() != nil {
				continue
			}
			def, ok, err := liveDef(ent.ModelID)
			if err != nil {
				return EffectiveHeroAppearance{}, err
			}
			if !ok || def.Validate() != nil || def.HeroOriginTableID != h.OriginTableID {
				continue
			}
			if _, dup := seen[ent.ModelID]; dup {
				return EffectiveHeroAppearance{}, errors.New("character asset: duplicate durable Hero LIVE entitlement")
			}
			seen[ent.ModelID] = struct{}{}
			qualifiedLIVE = append(qualifiedLIVE, QualifiedLIVEState{ModelID: ent.ModelID, IsShow: ent.IsShow})
		}
		sort.Slice(qualifiedLIVE, func(i, j int) bool { return qualifiedLIVE[i].ModelID < qualifiedLIVE[j].ModelID })
	}

	out := EffectiveHeroAppearance{OwnerStateVersion: h.StateVersion, ObservedAt: at, CurrentSkinID: current, IllusionSkinID: illusion, Skins: qualifiedSkins, LIVE: qualifiedLIVE}
	return out, out.Validate()
}

func BuildEffectivePetAppearance(ctx context.Context, revision string, p character.Pet, styles []character.PetStyleEntitlement, observedAt time.Time, content AppearanceReadContent) (EffectivePetAppearance, error) {
	if content == nil {
		return EffectivePetAppearance{}, errors.New("character asset: nil appearance read content")
	}
	return buildEffectivePetAppearance(p, styles, observedAt, func(styleItemID int64) (AppearancePetStyleDefinition, bool, error) {
		return content.AppearancePetStyle(ctx, revision, styleItemID)
	})
}

func BuildEffectivePetAppearanceTx(ctx context.Context, q tx.Queryer, revision string, p character.Pet, styles []character.PetStyleEntitlement, observedAt time.Time, content AppearanceTxContent) (EffectivePetAppearance, error) {
	if q == nil || content == nil {
		return EffectivePetAppearance{}, errors.New("character asset: invalid Pet appearance transaction content")
	}
	return buildEffectivePetAppearance(p, styles, observedAt, func(styleItemID int64) (AppearancePetStyleDefinition, bool, error) {
		return content.AppearancePetStyleTx(ctx, q, revision, styleItemID)
	})
}

func buildEffectivePetAppearance(p character.Pet, styles []character.PetStyleEntitlement, observedAt time.Time, styleDef petStyleLookup) (EffectivePetAppearance, error) {
	if p.ValidatePersistent() != nil || observedAt.IsZero() || styleDef == nil {
		return EffectivePetAppearance{}, errors.New("character asset: invalid Pet appearance qualification input")
	}
	at := observedAt.UTC()
	owned := make(map[int64]struct{}, len(styles))
	for _, ent := range styles {
		if ent.PlayerID != p.PlayerID || ent.PetID != p.PetID || ent.Validate() != nil {
			continue
		}
		def, ok, err := styleDef(ent.StyleItemID)
		if err != nil {
			return EffectivePetAppearance{}, err
		}
		if !ok || def.Validate() != nil || def.PetOriginTableID != p.OriginTableID {
			continue
		}
		if _, dup := owned[ent.StyleItemID]; dup {
			return EffectivePetAppearance{}, errors.New("character asset: duplicate durable Pet style entitlement")
		}
		owned[ent.StyleItemID] = struct{}{}
	}
	ids := make([]int64, 0, len(owned))
	for id := range owned {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	active := p.ActiveStyle
	if active > 0 {
		if _, ok := owned[active]; !ok {
			active = 0
		}
	}
	out := EffectivePetAppearance{OwnerStateVersion: p.StateVersion, ObservedAt: at, ActiveStyle: active, OwnedStyles: ids}
	return out, out.Validate()
}
