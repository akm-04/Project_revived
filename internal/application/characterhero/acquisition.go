package characterhero

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"sort"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrHeroCapacityUnavailable = errors.New("character hero: capacity policy unavailable")
	ErrHeroCapacityExceeded    = errors.New("character hero: capacity exceeded")
	ErrHeroDuplicateOrigin     = errors.New("character hero: origin already owned")
	ErrHeroAcquisitionInvalid  = errors.New("character hero: acquisition request invalid")
	ErrHeroVowsLevel           = errors.New("character hero: Vows player level requirement not met")
)

// CapacityAuthorizer is intentionally policy-only. CA2-3 has no qualified
// production capacity owner, lock or persistence model; production wiring must
// therefore leave this seam nil until that separate authority is recovered.
type CapacityAuthorizer interface {
	AuthorizeHeroAddition(identity.PlayerID, int, int) error
}

type AcquisitionStore interface {
	ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (character.HeroRoot, error)
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (character.HeroRoot, error)
	ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error)
	LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error)
	SaveRootAllocatorTx(context.Context, tx.Tx, character.HeroRoot, int64) error
	InsertHeroTx(context.Context, tx.Tx, character.Hero) error
}

type AcquisitionContent interface {
	HeroAcquisitionByItemTx(context.Context, tx.Queryer, string, int64) (character.HeroAcquisitionTemplate, error)
	HeroNormalSummonTx(context.Context, tx.Queryer, string, int64) (character.HeroNormalSummonPolicy, error)
	HeroTemplateProgressionTx(context.Context, tx.Queryer, string, int64) (character.HeroTemplateProgression, error)
	HeroSuperPrerequisitesTx(context.Context, tx.Queryer, string, int64) ([]int64, error)
	HeroVowsRequiredLevelTx(context.Context, tx.Queryer, string) (int64, error)
}

type acquisitionReceipt struct {
	PartnerID               int64  `json:"partner_id"`
	TableID                 int64  `json:"table_id"`
	OriginTableID           int64  `json:"origin_table_id"`
	Star                    int64  `json:"star"`
	Level                   int64  `json:"level"`
	Exp                     int64  `json:"exp"`
	Color                   int64  `json:"color"`
	CreationContentRevision string `json:"creation_content_revision"`
	StateVersion            int64  `json:"state_version"`
	Kind                    string `json:"kind"`
}

func (s Service) validateAcquisition() error {
	if err := s.validate(); err != nil {
		return err
	}
	if s.Progression == nil || s.AcquisitionStore == nil || s.Acquisition == nil || s.MaterialCosts == nil || s.PlayerLevel == nil {
		return errors.New("character hero: incomplete CA2-3 acquisition service")
	}
	if s.Capacity == nil {
		return ErrHeroCapacityUnavailable
	}
	return nil
}

func heroFromReceipt(r acquisitionReceipt, pid identity.PlayerID, now operation.Context) (character.Hero, error) {
	h := character.Hero{PlayerID: pid, PartnerID: r.PartnerID, TableID: r.TableID, OriginTableID: r.OriginTableID, Kind: character.HeroKind(r.Kind), Star: r.Star, Level: r.Level, Exp: r.Exp, Color: r.Color, CreationContentRevision: r.CreationContentRevision, StateVersion: r.StateVersion, CreatedAt: now.StartedAt.UTC(), UpdatedAt: now.StartedAt.UTC()}
	if err := h.Validate(); err != nil {
		return character.Hero{}, err
	}
	return h, nil
}

func encodeAcquisitionReceipt(h character.Hero) ([]byte, error) {
	return json.Marshal(acquisitionReceipt{PartnerID: h.PartnerID, TableID: h.TableID, OriginTableID: h.OriginTableID, Star: h.Star, Level: h.Level, Exp: h.Exp, Color: h.Color, CreationContentRevision: h.CreationContentRevision, StateVersion: h.StateVersion, Kind: string(h.Kind)})
}

func newHero(pid identity.PlayerID, partnerID int64, t character.HeroAcquisitionTemplate, star int64, revision string, op operation.Context) (character.Hero, error) {
	if partnerID <= 0 || t.TableID <= 0 || t.OriginTableID != t.TableID || star < 1 || star > character.MaxHeroStar || len(revision) != 64 || op.StartedAt.IsZero() {
		return character.Hero{}, ErrHeroAcquisitionInvalid
	}
	h := character.Hero{PlayerID: pid, PartnerID: partnerID, TableID: t.TableID, OriginTableID: t.OriginTableID, Kind: t.Kind, Star: star, Level: 1, Exp: 0, Color: 1, CreationContentRevision: revision, StateVersion: 1, CreatedAt: op.StartedAt.UTC(), UpdatedAt: op.StartedAt.UTC()}
	if err := h.Validate(); err != nil {
		return character.Hero{}, err
	}
	return h, nil
}

func hasOrigin(heroes []character.Hero, origin int64) bool {
	for _, h := range heroes {
		if h.OriginTableID == origin {
			return true
		}
	}
	return false
}

func advanceRoot(root character.HeroRoot, additions int, op operation.Context) (character.HeroRoot, error) {
	if root.Validate() != nil || additions <= 0 || op.StartedAt.IsZero() {
		return character.HeroRoot{}, ErrHeroAcquisitionInvalid
	}
	root.NextPartnerID += int64(additions)
	root.StateVersion++
	root.UpdatedAt = op.StartedAt.UTC()
	return root, root.Validate()
}

func (s Service) SummonNormal(ctx context.Context, actor identity.ActorContext, tableID, stoneID, stoneNum int64, op operation.Context) (character.Hero, error) {
	if err := s.validateAcquisition(); err != nil {
		return character.Hero{}, err
	}
	if !actor.PlayerID.Valid() || tableID <= 0 || stoneID <= 0 || stoneNum <= 0 {
		return character.Hero{}, ErrHeroAcquisitionInvalid
	}
	boundOp, revision, err := s.bindProgressionContent(ctx, op)
	if err != nil {
		return character.Hero{}, err
	}
	id := heroReceiptID(actor, "stone-summon", boundOp)
	fp, err := receipt.FingerprintRequest(map[string]any{"table_id": tableID, "stone": stoneID, "stone_num": stoneNum})
	if err != nil {
		return character.Hero{}, err
	}
	var result character.Hero
	_, err = s.Runner.Run(ctx, boundOp, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, boundOp.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			var ar acquisitionReceipt
			if err := json.Unmarshal(prior.ResultPayload, &ar); err != nil {
				return err
			}
			result, err = heroFromReceipt(ar, actor.PlayerID, boundOp)
			return err
		}
		policy, err := s.Acquisition.HeroNormalSummonTx(txctx, scope.Tx, revision, tableID)
		if err != nil {
			return err
		}
		if policy.Template.Kind != character.NormalHero || stoneID != policy.Template.FragmentItemID || stoneNum != policy.FragmentCount {
			return ErrHeroAcquisitionInvalid
		}
		root, err := s.AcquisitionStore.LockRootTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		heroes, err := s.AcquisitionStore.ListHeroesTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		if hasOrigin(heroes, policy.Template.OriginTableID) {
			return ErrHeroDuplicateOrigin
		}
		if err := s.Capacity.AuthorizeHeroAddition(actor.PlayerID, len(heroes), 1); err != nil {
			return err
		}
		_, err = s.MaterialCosts.DebitMaterialCostTx(txctx, scope.Tx, actor.PlayerID, appi5.MaterialCost{Scalars: []appi5.ScalarMaterialCost{{ResourceKey: "mana", Amount: policy.Mana}}, Stacks: []appi5.StackMaterialCost{{ItemID: policy.Template.FragmentItemID, Amount: policy.FragmentCount}}}, boundOp)
		if err != nil {
			return err
		}
		h, err := newHero(actor.PlayerID, root.NextPartnerID, policy.Template, policy.Template.InitialStar, revision, boundOp)
		if err != nil {
			return err
		}
		if err := s.AcquisitionStore.InsertHeroTx(txctx, scope.Tx, h); err != nil {
			return err
		}
		nextRoot, err := advanceRoot(root, 1, boundOp)
		if err != nil {
			return err
		}
		if err := s.AcquisitionStore.SaveRootAllocatorTx(txctx, scope.Tx, nextRoot, root.StateVersion); err != nil {
			return err
		}
		payload, err := encodeAcquisitionReceipt(h)
		if err != nil {
			return err
		}
		rr, err := receipt.New(boundOp, id, "CA2_HERO_ACQUISITION", "gxb.ca2.hero-acquisition.v1", payload, fp)
		if err != nil {
			return err
		}
		rr.ActorAccountUID = string(actor.AccountUID)
		rr.ContextID = actor.ContextID.UUID()
		rr.PolicyVersion = "pass518-ca2-3"
		if _, err := s.Receipts.PutTx(txctx, scope.Tx, rr); err != nil {
			return err
		}
		result = h
		return nil
	})
	return result, err
}

func (s Service) CreateVows(ctx context.Context, actor identity.ActorContext, tableID int64, op operation.Context) (character.Hero, error) {
	if err := s.validateAcquisition(); err != nil {
		return character.Hero{}, err
	}
	if !actor.PlayerID.Valid() || tableID <= 0 {
		return character.Hero{}, ErrHeroAcquisitionInvalid
	}
	boundOp, revision, err := s.bindProgressionContent(ctx, op)
	if err != nil {
		return character.Hero{}, err
	}
	id := heroReceiptID(actor, "create-vows", boundOp)
	fp, err := receipt.FingerprintRequest(map[string]any{"table_id": tableID})
	if err != nil {
		return character.Hero{}, err
	}
	var result character.Hero
	_, err = s.Runner.Run(ctx, boundOp, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, boundOp.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			var ar acquisitionReceipt
			if err := json.Unmarshal(prior.ResultPayload, &ar); err != nil {
				return err
			}
			result, err = heroFromReceipt(ar, actor.PlayerID, boundOp)
			return err
		}
		tmpl, err := s.Acquisition.HeroTemplateProgressionTx(txctx, scope.Tx, revision, tableID)
		if err != nil {
			return err
		}
		if tmpl.Kind != character.SuperHero || tmpl.OriginTableID != tableID {
			return ErrHeroAcquisitionInvalid
		}
		prereqs, err := s.Acquisition.HeroSuperPrerequisitesTx(txctx, scope.Tx, revision, tableID)
		if err != nil {
			return err
		}
		requiredLevel, err := s.Acquisition.HeroVowsRequiredLevelTx(txctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		root, err := s.AcquisitionStore.LockRootTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		heroes, err := s.AcquisitionStore.ListHeroesTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		if hasOrigin(heroes, tableID) {
			return ErrHeroDuplicateOrigin
		}
		byOrigin := make(map[int64]character.Hero, len(heroes))
		for _, h := range heroes {
			byOrigin[h.OriginTableID] = h
		}
		ids := make([]int64, 0, len(prereqs))
		for _, origin := range prereqs {
			h, ok := byOrigin[origin]
			if !ok {
				return ErrHeroPrerequisites
			}
			ids = append(ids, h.PartnerID)
		}
		canonicalPartnerSort(ids)
		locked := make(map[int64]character.Hero, len(ids))
		for _, partnerID := range ids {
			h, err := s.AcquisitionStore.LockHeroByPartnerIDTx(txctx, scope.Tx, actor.PlayerID, partnerID)
			if err != nil {
				return err
			}
			locked[h.OriginTableID] = h
		}
		qualifying := int64(0)
		for _, origin := range prereqs {
			h, ok := locked[origin]
			if !ok {
				return ErrHeroPrerequisites
			}
			if h.Star == 5 {
				qualifying++
			}
		}
		if qualifying == 0 {
			return ErrHeroPrerequisites
		}
		level, err := s.PlayerLevel.PlayerLevelTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		if level < requiredLevel {
			return ErrHeroVowsLevel
		}
		if err := s.Capacity.AuthorizeHeroAddition(actor.PlayerID, len(heroes), 1); err != nil {
			return err
		}
		at := character.HeroAcquisitionTemplate{TableID: tableID, OriginTableID: tableID, Kind: character.SuperHero, InitialStar: tmpl.InitialStar, FragmentItemID: tmpl.FragmentItemID}
		h, err := newHero(actor.PlayerID, root.NextPartnerID, at, qualifying, revision, boundOp)
		if err != nil {
			return err
		}
		if err := s.AcquisitionStore.InsertHeroTx(txctx, scope.Tx, h); err != nil {
			return err
		}
		nextRoot, err := advanceRoot(root, 1, boundOp)
		if err != nil {
			return err
		}
		if err := s.AcquisitionStore.SaveRootAllocatorTx(txctx, scope.Tx, nextRoot, root.StateVersion); err != nil {
			return err
		}
		payload, err := encodeAcquisitionReceipt(h)
		if err != nil {
			return err
		}
		rr, err := receipt.New(boundOp, id, "CA2_HERO_ACQUISITION", "gxb.ca2.hero-acquisition.v1", payload, fp)
		if err != nil {
			return err
		}
		rr.ActorAccountUID = string(actor.AccountUID)
		rr.ContextID = actor.ContextID.UUID()
		rr.PolicyVersion = "pass518-ca2-3"
		if _, err := s.Receipts.PutTx(txctx, scope.Tx, rr); err != nil {
			return err
		}
		result = h
		return nil
	})
	return result, err
}

// ensure deterministic same-rank lock ordering is numeric for Int64 Hero IDs.
func sortedPartnerIDs(in []int64) []int64 {
	out := append([]int64(nil), in...)
	sort.Slice(out, func(i, j int) bool { return out[i] < out[j] })
	return out
}
