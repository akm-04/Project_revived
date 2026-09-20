package characterhero

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrHeroContentInactive = errors.New("CA2 Hero content capability inactive")
var ErrAppearanceContentInactive = errors.New("CA7 appearance content capability inactive")

type Store interface {
	ReadRoot(context.Context, identity.PlayerID) (character.HeroRoot, error)
	ListHeroes(context.Context, identity.PlayerID) ([]character.Hero, error)
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (character.HeroRoot, error)
	SaveSortTypeTx(context.Context, tx.Tx, character.HeroRoot, int64) error
}
type HeroAppearanceStore interface {
	ListHeroSkinEntitlements(context.Context, identity.PlayerID, int64) ([]character.HeroSkinEntitlement, error)
	ListHeroLIVEEntitlements(context.Context, identity.PlayerID, int64) ([]character.HeroLIVEEntitlement, error)
}

type ActorFencer interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type ContentGate interface {
	HeroCoreActive(context.Context) (string, bool, error)
	HeroKind(context.Context, string, int64) (character.HeroKind, error)
}

type HeroRosterProjectionContent interface {
	HeroEquipmentRevision(context.Context, string) (bool, error)
	HeroFumoRevision(context.Context, string) (bool, error)
	HeroEquipmentPosition(context.Context, string, int64, int64, int64) (character.HeroEquipmentPosition, error)
	HeroFumoTarget(context.Context, string, character.EquipmentTemplateID) (character.HeroFumoTarget, error)
}

type HeroRosterView struct {
	Hero       character.Hero
	FumoLevels character.HeroFumoSlots
	Appearance characterasset.EffectiveHeroAppearance
}

type Service struct {
	Runner                    tx.Runner
	Timed                     appgeneration.TimedRunner
	Store                     Store
	Fencer                    ActorFencer
	Content                   ContentGate
	Receipts                  receipt.Store
	ReceiptRead               receipt.Reader
	ProgressionStore          ProgressionStore
	Progression               ProgressionContent
	Economy                   appi5.TxHeroProgressionDebiter
	Backpack                  appi5.BackpackReader
	AcquisitionStore          AcquisitionStore
	Acquisition               AcquisitionContent
	MaterialCosts             appi5.TxMaterialCostDebiter
	PlayerLevel               appi5.TxPlayerLevelReader
	Capacity                  CapacityAuthorizer
	Equipment                 EquipmentOperationContent
	EquipmentResources        appi5.TxHeroEquipmentResourceDebiter
	Fumo                      FumoOperationContent
	Promotion                 HeroPromotionContent
	PromotionResources        appi5.TxHeroPromotionResourceSettler
	StrictRestoration         appi5.TxStrictRestorationSettler
	MaxHeroColorPolicy        MaxHeroColorPolicyProvider
	RestorationModifier       RestorationModifier
	RosterProjection          HeroRosterProjectionContent
	AppearanceStore           HeroAppearanceStore
	Appearance                characterasset.AppearanceContent
	AppearanceMutationStore   HeroAppearanceMutationStore
	AppearanceMutationContent HeroAppearanceMutationContent
	LIVEMutationStore         HeroLIVEMutationStore
}

func profile() tx.Profile {
	return tx.Profile{Name: "CA2_HERO_CORE", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}
func (s Service) validate() error {
	if s.Runner.DB == nil || s.Store == nil || s.Fencer == nil || s.Content == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return errors.New("character hero: incomplete service")
	}
	return nil
}
func (s Service) requireActive(ctx context.Context) error {
	_, ok, err := s.Content.HeroCoreActive(ctx)
	if err != nil {
		return err
	}
	if !ok {
		return ErrHeroContentInactive
	}
	return nil
}
func (s Service) Roster(ctx context.Context, actor identity.ActorContext) (character.HeroRoot, []character.Hero, error) {
	if err := s.validate(); err != nil {
		return character.HeroRoot{}, nil, err
	}
	if !actor.PlayerID.Valid() {
		return character.HeroRoot{}, nil, errors.New("character hero: invalid actor")
	}
	if err := s.requireActive(ctx); err != nil {
		return character.HeroRoot{}, nil, err
	}
	root, err := s.Store.ReadRoot(ctx, actor.PlayerID)
	if err != nil {
		return root, nil, err
	}
	heroes, err := s.Store.ListHeroes(ctx, actor.PlayerID)
	if err != nil {
		return root, nil, err
	}
	for i := range heroes {
		kind, err := s.Content.HeroKind(ctx, heroes[i].CreationContentRevision, heroes[i].TableID)
		if err != nil {
			return root, nil, err
		}
		heroes[i].Kind = kind
		if err := heroes[i].Validate(); err != nil {
			return root, nil, err
		}
	}
	return root, heroes, nil
}
func (s Service) RosterView(ctx context.Context, actor identity.ActorContext, observedAt time.Time) (character.HeroRoot, []HeroRosterView, error) {
	if err := s.validate(); err != nil {
		return character.HeroRoot{}, nil, err
	}
	if !actor.PlayerID.Valid() || observedAt.IsZero() {
		return character.HeroRoot{}, nil, errors.New("character hero: invalid actor or observation time")
	}
	if s.RosterProjection == nil || s.AppearanceStore == nil || s.Appearance == nil {
		return character.HeroRoot{}, nil, errors.New("character hero: roster projection unavailable")
	}
	revision, ok, err := s.Content.HeroCoreActive(ctx)
	if err != nil {
		return character.HeroRoot{}, nil, err
	}
	if !ok {
		return character.HeroRoot{}, nil, ErrHeroContentInactive
	}
	if good, err := s.RosterProjection.HeroEquipmentRevision(ctx, revision); err != nil {
		return character.HeroRoot{}, nil, err
	} else if !good {
		return character.HeroRoot{}, nil, ErrHeroEquipmentContentInactive
	}
	if good, err := s.RosterProjection.HeroFumoRevision(ctx, revision); err != nil {
		return character.HeroRoot{}, nil, err
	} else if !good {
		return character.HeroRoot{}, nil, ErrHeroFumoContentInactive
	}
	if good, err := s.Appearance.AppearanceRevision(ctx, revision); err != nil {
		return character.HeroRoot{}, nil, err
	} else if !good {
		return character.HeroRoot{}, nil, ErrAppearanceContentInactive
	}
	root, err := s.Store.ReadRoot(ctx, actor.PlayerID)
	if err != nil {
		return root, nil, err
	}
	heroes, err := s.Store.ListHeroes(ctx, actor.PlayerID)
	if err != nil {
		return root, nil, err
	}
	out := make([]HeroRosterView, 0, len(heroes))
	for i := range heroes {
		kind, err := s.Content.HeroKind(ctx, heroes[i].CreationContentRevision, heroes[i].TableID)
		if err != nil {
			return root, nil, err
		}
		heroes[i].Kind = kind
		if err := heroes[i].Validate(); err != nil {
			return root, nil, err
		}
		view := HeroRosterView{Hero: heroes[i]}
		if kind == character.NormalHero {
			levels, err := s.deriveFumoLevelsRead(ctx, revision, heroes[i])
			if err != nil {
				return root, nil, err
			}
			view.FumoLevels = levels
		}
		skins, err := s.AppearanceStore.ListHeroSkinEntitlements(ctx, actor.PlayerID, heroes[i].PartnerID)
		if err != nil {
			return root, nil, err
		}
		lives, err := s.AppearanceStore.ListHeroLIVEEntitlements(ctx, actor.PlayerID, heroes[i].PartnerID)
		if err != nil {
			return root, nil, err
		}
		appearance, err := characterasset.BuildEffectiveHeroAppearance(ctx, revision, heroes[i], skins, lives, observedAt, s.Appearance)
		if err != nil {
			return root, nil, err
		}
		view.Appearance = appearance
		out = append(out, view)
	}
	return root, out, nil
}

func (s Service) SaveSortType(ctx context.Context, actor identity.ActorContext, sortType int64, op operation.Context) error {
	if err := s.validate(); err != nil {
		return err
	}
	if !actor.PlayerID.Valid() || op.ID.IsZero() || op.StartedAt.IsZero() || sortType < 0 || sortType > character.MaxSortType {
		return errors.New("character hero: invalid sort operation")
	}
	if err := s.requireActive(ctx); err != nil {
		return err
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "character-hero", Operation: "save-sort-type", SemanticKey: op.ID.String()}
	fp, err := receipt.FingerprintRequest(map[string]any{"sort_type": sortType})
	if err != nil {
		return err
	}
	_, err = s.Runner.Run(ctx, op, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, op.StartedAt); err != nil {
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
		root, err := s.Store.LockRootTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		old := root.StateVersion
		if root.SortType != sortType {
			root.SortType = sortType
			root.StateVersion++
			root.UpdatedAt = op.StartedAt.UTC()
			if err := s.Store.SaveSortTypeTx(txctx, scope.Tx, root, old); err != nil {
				return err
			}
		}
		payload, _ := json.Marshal(map[string]any{"sort_type": sortType})
		rr, err := receipt.New(op, id, "CA2_HERO_CORE", "gxb.ca2.sort.v1", payload, fp)
		if err != nil {
			return err
		}
		rr.ActorAccountUID = string(actor.AccountUID)
		rr.ContextID = actor.ContextID.UUID()
		rr.PolicyVersion = "pass513-ca2-1"
		_, err = s.Receipts.PutTx(txctx, scope.Tx, rr)
		return err
	})
	return err
}
