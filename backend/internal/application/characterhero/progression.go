package characterhero

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"sort"
	"strconv"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrHeroProgressionContentInactive = errors.New("CA2-2 Hero progression content capability inactive")
	ErrHeroNotFound                   = errors.New("character hero: Hero not found")
	ErrHeroExpMax                     = errors.New("character hero: Hero EXP already at source-qualified maximum")
	ErrHeroEvolutionUnavailable       = errors.New("character hero: evolution unavailable")
	ErrHeroPrerequisites              = errors.New("character hero: Super Hero prerequisites not met")
)

type ProgressionStore interface {
	ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error)
	LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error)
	SaveHeroProgressionTx(context.Context, tx.Tx, character.Hero, int64) error
	SaveHeroStateTx(context.Context, tx.Tx, character.Hero, int64) error
}

type ProgressionContent interface {
	HeroProgressionActive(context.Context) (string, bool, error)
	HeroProgressionRevision(context.Context, string) (bool, error)
	HeroExpItemTx(context.Context, tx.Queryer, string, int64) (int64, error)
	HeroMaxLevelTx(context.Context, tx.Queryer, string, int64) (int64, error)
	HeroExpPolicyTx(context.Context, tx.Queryer, string, int64) ([]character.HeroExpThreshold, error)
	HeroTemplateProgressionTx(context.Context, tx.Queryer, string, int64) (character.HeroTemplateProgression, error)
	HeroNormalEvolutionTx(context.Context, tx.Queryer, string, int64) (character.HeroEvolutionPolicy, error)
	HeroSuperEvolutionTx(context.Context, tx.Queryer, string, int64) (character.HeroEvolutionPolicy, error)
	HeroSuperPrerequisitesTx(context.Context, tx.Queryer, string, int64) ([]int64, error)
	HeroPieceMappings(context.Context, string) ([]character.HeroPieceMapping, error)
}

type ExpResult struct {
	PartnerID int64
	Level     int64
	Exp       int64
	Remaining map[int64]int64
}

type progressionReceipt struct {
	PartnerID int64            `json:"partner_id"`
	Star      int64            `json:"star"`
	Level     int64            `json:"level"`
	Exp       int64            `json:"exp"`
	Remaining map[string]int64 `json:"remaining,omitempty"`
}

func (s Service) validateProgression() error {
	if err := s.validate(); err != nil {
		return err
	}
	if s.ProgressionStore == nil || s.Progression == nil || s.Economy == nil || s.Backpack == nil {
		return errors.New("character hero: incomplete CA2-2 progression service")
	}
	return nil
}

func (s Service) bindProgressionContent(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	if op.ID.IsZero() || op.StartedAt.IsZero() {
		return operation.Context{}, "", errors.New("character hero: invalid operation context")
	}
	if revision, ok := op.Policies.Get("content"); ok {
		good, err := s.Progression.HeroProgressionRevision(ctx, revision)
		if err != nil {
			return operation.Context{}, "", err
		}
		if !good {
			return operation.Context{}, "", ErrHeroProgressionContentInactive
		}
		return op, revision, nil
	}
	revision, good, err := s.Progression.HeroProgressionActive(ctx)
	if err != nil {
		return operation.Context{}, "", err
	}
	if !good {
		return operation.Context{}, "", ErrHeroProgressionContentInactive
	}
	refs := op.Policies.Refs()
	refs = append(refs, policy.Ref{Name: "content", Version: revision})
	set, err := policy.NewSet(refs...)
	if err != nil {
		return operation.Context{}, "", err
	}
	op.Policies = set
	return op, revision, nil
}

func heroReceiptID(actor identity.ActorContext, operationName string, op operation.Context) receipt.Identity {
	return receipt.Identity{
		OwnerKind:   "player",
		OwnerKey:    strconv.FormatInt(int64(actor.PlayerID), 10),
		Domain:      "character-hero",
		Operation:   operationName,
		SemanticKey: op.ID.String(),
	}
}

func decodeProgressionReceipt(r receipt.Receipt) (progressionReceipt, error) {
	var out progressionReceipt
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PartnerID <= 0 || out.Star < 1 || out.Star > character.MaxHeroStar || out.Level <= 0 || out.Exp < 0 {
		return out, errors.New("character hero: invalid progression receipt payload")
	}
	return out, nil
}

func expResultFromReceipt(r progressionReceipt) ExpResult {
	out := ExpResult{PartnerID: r.PartnerID, Level: r.Level, Exp: r.Exp, Remaining: map[int64]int64{}}
	for k, v := range r.Remaining {
		if id, err := strconv.ParseInt(k, 10, 64); err == nil && id > 0 && v >= 0 {
			out.Remaining[id] = v
		}
	}
	return out
}

func multiplyExp(value, count int64) (int64, error) {
	if value <= 0 || count <= 0 || value > math.MaxInt64/count {
		return 0, errors.New("character hero: EXP item multiplication overflow")
	}
	return value * count, nil
}

func (s Service) UseExpItem(ctx context.Context, actor identity.ActorContext, partnerID, itemID, count int64, op operation.Context) (ExpResult, error) {
	return s.useExp(ctx, actor, partnerID, []appi5.HeroExpItemDebit{{ItemID: itemID, Count: count}}, "use-exp-item", op)
}

func (s Service) UseExpItems(ctx context.Context, actor identity.ActorContext, partnerID int64, items []appi5.HeroExpItemDebit, op operation.Context) (ExpResult, error) {
	return s.useExp(ctx, actor, partnerID, items, "use-exp-items", op)
}

func (s Service) useExp(ctx context.Context, actor identity.ActorContext, partnerID int64, items []appi5.HeroExpItemDebit, operationName string, op operation.Context) (ExpResult, error) {
	if err := s.validateProgression(); err != nil {
		return ExpResult{}, err
	}
	if !actor.PlayerID.Valid() || partnerID <= 0 || len(items) == 0 || len(items) > 5 {
		return ExpResult{}, errors.New("character hero: invalid EXP operation")
	}
	for _, x := range items {
		if x.ItemID <= 0 || x.Count <= 0 {
			return ExpResult{}, errors.New("character hero: invalid EXP item")
		}
	}
	boundOp, revision, err := s.bindProgressionContent(ctx, op)
	if err != nil {
		return ExpResult{}, err
	}
	id := heroReceiptID(actor, operationName, boundOp)
	fp, err := receipt.FingerprintRequest(map[string]any{"partner_id": partnerID, "items": items})
	if err != nil {
		return ExpResult{}, err
	}
	var result ExpResult
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
			decoded, err := decodeProgressionReceipt(prior)
			if err != nil {
				return err
			}
			result = expResultFromReceipt(decoded)
			return nil
		}

		seen := make(map[int64]struct{}, len(items))
		totalExp := int64(0)
		for _, x := range items {
			if _, ok := seen[x.ItemID]; ok {
				return fmt.Errorf("character hero: duplicate EXP item %d", x.ItemID)
			}
			seen[x.ItemID] = struct{}{}
			unit, err := s.Progression.HeroExpItemTx(txctx, scope.Tx, revision, x.ItemID)
			if err != nil {
				return err
			}
			add, err := multiplyExp(unit, x.Count)
			if err != nil {
				return err
			}
			if add > math.MaxInt64-totalExp {
				return errors.New("character hero: total EXP overflow")
			}
			totalExp += add
		}

		hero, err := s.ProgressionStore.LockHeroByPartnerIDTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		debit, err := s.Economy.DebitHeroExpItemsTx(txctx, scope.Tx, actor.PlayerID, items, boundOp)
		if err != nil {
			return err
		}
		maxLevel, err := s.Progression.HeroMaxLevelTx(txctx, scope.Tx, revision, debit.PlayerLevel)
		if err != nil {
			return err
		}
		thresholds, err := s.Progression.HeroExpPolicyTx(txctx, scope.Tx, revision, maxLevel)
		if err != nil {
			return err
		}
		if hero.Level >= maxLevel || hero.Exp >= thresholds[len(thresholds)-1].TotalExp {
			return ErrHeroExpMax
		}
		old := hero.StateVersion
		next, err := hero.AddSourceEXP(totalExp, maxLevel, thresholds, boundOp.StartedAt)
		if err != nil {
			return err
		}
		if err := s.ProgressionStore.SaveHeroProgressionTx(txctx, scope.Tx, next, old); err != nil {
			return err
		}
		remaining := make(map[string]int64, len(debit.Stacks))
		result = ExpResult{PartnerID: next.PartnerID, Level: next.Level, Exp: next.Exp, Remaining: make(map[int64]int64, len(debit.Stacks))}
		for _, st := range debit.Stacks {
			remaining[strconv.FormatInt(st.ItemID, 10)] = st.Quantity
			result.Remaining[st.ItemID] = st.Quantity
		}
		payload, err := json.Marshal(progressionReceipt{PartnerID: next.PartnerID, Star: next.Star, Level: next.Level, Exp: next.Exp, Remaining: remaining})
		if err != nil {
			return err
		}
		rr, err := receipt.New(boundOp, id, "CA2_HERO_PROGRESSION", "gxb.ca2.hero-exp.v1", payload, fp)
		if err != nil {
			return err
		}
		rr.ActorAccountUID = string(actor.AccountUID)
		rr.ContextID = actor.ContextID.UUID()
		rr.PolicyVersion = "pass516-ca2-2"
		_, err = s.Receipts.PutTx(txctx, scope.Tx, rr)
		return err
	})
	return result, err
}

func canonicalPartnerSort(ids []int64) {
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
}

func (s Service) Evolve(ctx context.Context, actor identity.ActorContext, partnerID int64, op operation.Context) error {
	if err := s.validateProgression(); err != nil {
		return err
	}
	if !actor.PlayerID.Valid() || partnerID <= 0 {
		return errors.New("character hero: invalid evolution operation")
	}
	boundOp, revision, err := s.bindProgressionContent(ctx, op)
	if err != nil {
		return err
	}
	id := heroReceiptID(actor, "evolve", boundOp)
	fp, err := receipt.FingerprintRequest(map[string]any{"partner_id": partnerID})
	if err != nil {
		return err
	}
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
			_, err := decodeProgressionReceipt(prior)
			return err
		}

		heroes, err := s.ProgressionStore.ListHeroesTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		var snapshot character.Hero
		found := false
		for _, h := range heroes {
			if h.PartnerID == partnerID {
				snapshot, found = h, true
				break
			}
		}
		if !found {
			return ErrHeroNotFound
		}
		template, err := s.Progression.HeroTemplateProgressionTx(txctx, scope.Tx, revision, snapshot.TableID)
		if err != nil {
			return err
		}
		targetStar := snapshot.Star + 1
		if targetStar > character.MaxHeroStar {
			return ErrHeroEvolutionUnavailable
		}
		var evo character.HeroEvolutionPolicy
		var prereqOrigins []int64
		switch template.Kind {
		case character.NormalHero:
			if targetStar > 5 {
				return ErrHeroEvolutionUnavailable
			}
			evo, err = s.Progression.HeroNormalEvolutionTx(txctx, scope.Tx, revision, targetStar)
		case character.SuperHero:
			evo, err = s.Progression.HeroSuperEvolutionTx(txctx, scope.Tx, revision, targetStar)
			if err == nil && targetStar <= 5 {
				prereqOrigins, err = s.Progression.HeroSuperPrerequisitesTx(txctx, scope.Tx, revision, template.OriginTableID)
			}
		default:
			return ErrHeroEvolutionUnavailable
		}
		if err != nil {
			return err
		}

		// CA2-3 can create Heroes, so Super low-star prerequisite membership must
		// be stabilized by the Character HeroRoot before discovering the rank-410
		// prerequisite identities. This preserves 400 -> 410 ordering and lets us
		// re-evaluate all star predicates from locked rows without roster races.
		if template.Kind == character.SuperHero && targetStar <= 5 {
			if _, err := s.Store.LockRootTx(txctx, scope.Tx, actor.PlayerID); err != nil {
				return err
			}
			heroes, err = s.ProgressionStore.ListHeroesTx(txctx, scope.Tx, actor.PlayerID)
			if err != nil {
				return err
			}
		}
		lockIDs := []int64{partnerID}
		wanted := make(map[int64]struct{}, len(prereqOrigins))
		for _, origin := range prereqOrigins {
			wanted[origin] = struct{}{}
		}
		if len(wanted) > 0 {
			for _, h := range heroes {
				if _, ok := wanted[h.OriginTableID]; ok && h.PartnerID != partnerID {
					lockIDs = append(lockIDs, h.PartnerID)
				}
			}
		}
		canonicalPartnerSort(lockIDs)
		locked := make(map[int64]character.Hero, len(lockIDs))
		for _, id := range lockIDs {
			h, err := s.ProgressionStore.LockHeroByPartnerIDTx(txctx, scope.Tx, actor.PlayerID, id)
			if err != nil {
				return err
			}
			locked[id] = h
		}
		hero := locked[partnerID]
		if hero.StateVersion != snapshot.StateVersion || hero.Star != snapshot.Star || hero.TableID != snapshot.TableID {
			return tx.MarkDefiniteAbort(errors.New("character hero: evolution snapshot changed before lock"))
		}
		if hero.Star+1 != targetStar {
			return tx.MarkDefiniteAbort(errors.New("character hero: evolution star changed before lock"))
		}
		if template.Kind == character.SuperHero && targetStar <= 5 {
			qualifying := int64(0)
			for _, h := range locked {
				if h.PartnerID == partnerID {
					continue
				}
				if _, ok := wanted[h.OriginTableID]; ok && h.Star == 5 {
					qualifying++
				}
			}
			if qualifying < evo.NeedHeroNum {
				return ErrHeroPrerequisites
			}
			// Source low-star Super/Vows progression is prerequisite-only.
			if evo.FragmentCount != 0 || evo.Mana != 0 {
				return errors.New("character hero: invalid low-star Super evolution cost")
			}
		}

		if evo.FragmentCount > 0 && template.FragmentItemID <= 0 {
			return errors.New("character hero: evolution fragment mapping unavailable")
		}
		fragmentItemID := int64(0)
		if evo.FragmentCount > 0 {
			fragmentItemID = template.FragmentItemID
		}
		if _, err := s.Economy.DebitHeroEvolutionTx(txctx, scope.Tx, actor.PlayerID, evo.Mana, fragmentItemID, evo.FragmentCount, boundOp); err != nil {
			return err
		}
		old := hero.StateVersion
		next, err := hero.EvolveOneStar(boundOp.StartedAt)
		if err != nil {
			return err
		}
		if err := s.ProgressionStore.SaveHeroProgressionTx(txctx, scope.Tx, next, old); err != nil {
			return err
		}
		payload, err := json.Marshal(progressionReceipt{PartnerID: next.PartnerID, Star: next.Star, Level: next.Level, Exp: next.Exp})
		if err != nil {
			return err
		}
		rr, err := receipt.New(boundOp, id, "CA2_HERO_PROGRESSION", "gxb.ca2.evolve.v1", payload, fp)
		if err != nil {
			return err
		}
		rr.ActorAccountUID = string(actor.AccountUID)
		rr.ContextID = actor.ContextID.UUID()
		rr.PolicyVersion = "pass516-ca2-2"
		_, err = s.Receipts.PutTx(txctx, scope.Tx, rr)
		return err
	})
	return err
}

// HeroPieces projects canonical I5 fragment stacks into the source MID67 map:
// numeric-string Hero origin table_id -> currently owned fragment quantity.
func (s Service) HeroPieces(ctx context.Context, actor identity.ActorContext) (map[int64]int64, error) {
	if err := s.validateProgression(); err != nil {
		return nil, err
	}
	if !actor.PlayerID.Valid() {
		return nil, errors.New("character hero: invalid Hero pieces actor")
	}
	revision, ok, err := s.Progression.HeroProgressionActive(ctx)
	if err != nil {
		return nil, err
	}
	if !ok {
		return nil, ErrHeroProgressionContentInactive
	}
	mappings, err := s.Progression.HeroPieceMappings(ctx, revision)
	if err != nil {
		return nil, err
	}
	stacks, err := s.Backpack.ListStacks(ctx, actor.PlayerID)
	if err != nil {
		return nil, err
	}
	byItem := make(map[int64]int64, len(stacks))
	for _, st := range stacks {
		if st.Quantity > 0 {
			byItem[st.ItemID] = st.Quantity
		}
	}
	out := make(map[int64]int64)
	for _, m := range mappings {
		if qty := byItem[m.ItemID]; qty > 0 {
			out[m.OriginTableID] = qty
		}
	}
	return out, nil
}
