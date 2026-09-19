package characterhero

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// HeroRosterTxContent is the exact-revision, caller-queryer content surface
// needed to reconstruct stock Hero roster views inside another owner's
// transaction (notably MID1 bootstrap projection).
type HeroRosterTxContent interface {
	HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error)
	heroFumoPositionTxReader
	heroFumoTargetTxReader
}

// BuildRosterViewsTx enriches already-owned Hero rows for stock projection
// without opening a second transaction or changing durable state. Hero kind is
// resolved from each row's immutable creation revision, while current Fumo
// projection uses the caller-pinned active roster revision exactly like MID49.
func BuildRosterViewsTx(ctx context.Context, q tx.Queryer, rosterRevision string, heroes []character.Hero, content HeroRosterTxContent) ([]HeroRosterView, error) {
	if q == nil || content == nil || len(rosterRevision) != 64 {
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
		out = append(out, view)
	}
	return out, nil
}
