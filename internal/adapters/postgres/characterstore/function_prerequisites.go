package characterstore

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type FunctionPrerequisites struct {
	Store
	Content interface {
		HeroKindsTx(context.Context, tx.Queryer, string, []int64) (map[int64]character.HeroKind, error)
	}
}

func (reader FunctionPrerequisites) ReadCharacterFunctionPrerequisitesTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID, revision string, at time.Time) (app.CharacterFunctionObservation, error) {
	result := app.CharacterFunctionObservation{Player: player, Revision: revision, ObservedAt: at}
	if query == nil || reader.Content == nil || !player.Valid() || len(revision) != 64 || at.IsZero() {
		return result, character.ErrRawAwakeningUnavailable
	}
	root, err := reader.ReadRootTx(requestContext, query, player)
	if err != nil {
		return result, err
	}
	if root.Validate() != nil || at.Before(gen.EffectiveObservation(at, root.UpdatedAt)) {
		return result, character.ErrRawAwakeningUnavailable
	}
	result.PopulationVersion = root.StateVersion
	heroes, err := reader.ListHeroesTx(requestContext, query, player)
	if err != nil {
		return result, err
	}
	tableIDs := make([]int64, 0, len(heroes))
	for _, hero := range heroes {
		tableIDs = append(tableIDs, hero.TableID)
	}
	kinds, err := reader.Content.HeroKindsTx(requestContext, query, revision, tableIDs)
	if err != nil {
		return result, err
	}
	awakeningPartners := make([]int64, 0, len(heroes))
	for _, hero := range heroes {
		if kind, ok := kinds[hero.TableID]; ok && (kind == character.NormalHero || kind == character.SuperHero) && hero.Level >= 100 {
			awakeningPartners = append(awakeningPartners, hero.PartnerID)
		}
	}
	awakenings, err := (RawAwakeningStore{}).ListRawAwakeningsTx(requestContext, query, player, awakeningPartners)
	if err != nil {
		return result, err
	}
	for _, hero := range heroes {
		kind, ok := kinds[hero.TableID]
		if !ok {
			return result, character.ErrRawAwakeningUnavailable
		}
		hero.Kind = kind
		if hero.PlayerID != player || hero.Validate() != nil || at.Before(gen.EffectiveObservation(at, hero.UpdatedAt)) {
			return result, character.ErrRawAwakeningUnavailable
		}
		if kind != character.NormalHero && kind != character.SuperHero {
			continue
		}
		result.OwnedGirls++
		if hero.Level < 100 {
			continue
		}
		raw, found := awakenings[hero.PartnerID]
		if !found {
			continue
		}
		if raw.Validate() != nil || raw.CreationContentRevision != hero.CreationContentRevision || !raw.BirthAt.Equal(hero.CreatedAt) || at.Before(gen.EffectiveObservation(at, raw.UpdatedAt)) {
			return result, character.ErrRawAwakeningUnavailable
		}
		result.EmblemReady = result.EmblemReady || raw.RawStage == 3
	}
	return result, nil
}
