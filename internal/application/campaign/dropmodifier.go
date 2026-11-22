package campaign

import (
	"context"
	"time"

	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// DropHook is one decoded event drop modifier (I11A_EVENTS_V1 ruling 10).
// Campaign owns the scope and stacking law; the adapter only decodes the hook
// the events owner serves.
type DropHook struct {
	Scope      string
	ItemKinds  []int64
	Multiplier int64
}

// DropModifiers reads the event hooks that are active on a server at one
// instant, inside the campaign transaction (owner answer 6: the owner reads,
// events never writes campaign tables).
type DropModifiers interface {
	DropHooksTx(context.Context, tx.Queryer, int64, time.Time) ([]DropHook, error)
}

// dropScope maps a campaign node type to the hook scope (EA-8): backend Normal
// is the client normal campaign, backend Super is its Elite campaign.
func dropScope(nodeType int64) string {
	switch nodeType {
	case d.Normal:
		return "normal"
	case d.Super:
		return "elite"
	default:
		return ""
	}
}

// dropMultipliers is the multiplier per item kind for one scope. Several
// RUNNING hooks matching the same kind take the largest, never the product
// (lead decision for E2).
func dropMultipliers(hooks []DropHook, scope string) map[int64]int64 {
	multipliers := map[int64]int64{}
	for _, hook := range hooks {
		if hook.Scope != scope || hook.Multiplier <= 1 {
			continue
		}
		for _, kind := range hook.ItemKinds {
			if hook.Multiplier > multipliers[kind] {
				multipliers[kind] = hook.Multiplier
			}
		}
	}
	return multipliers
}

// dropMultipliersTx is the modifier of a fresh roll on this node, empty when
// there is none. A first clear and a node outside normal/elite never multiply
// (EA-8).
func (s Mode) dropMultipliersTx(c context.Context, q tx.Queryer, a identity.ActorContext, nodeType int64, firstClear bool, at time.Time) (map[int64]int64, error) {
	scope := dropScope(nodeType)
	if firstClear || scope == "" || s.Drops == nil {
		return nil, nil
	}
	hooks, err := s.Drops.DropHooksTx(c, q, int64(a.LogicalServerID), at)
	if err != nil {
		return nil, err
	}
	return dropMultipliers(hooks, scope), nil
}

// dropItemKindsTx reads the client item_type of every row of one drop box, once
// per roll site. An id the revision lacks is absent and stays unmultiplied.
func (s Mode) dropItemKindsTx(c context.Context, q tx.Queryer, revision string, catalog d.Catalog, boxID int64, multipliers map[int64]int64) (map[int64]int64, error) {
	if len(multipliers) == 0 {
		return nil, nil
	}
	if s.Content == nil {
		return nil, d.ErrUnavailable
	}
	box, found := catalog.Box(boxID)
	if !found {
		return nil, nil
	}
	itemIDs := make([]int64, 0, len(box.Rows))
	seen := make(map[int64]struct{}, len(box.Rows))
	for _, row := range box.Rows {
		if _, duplicate := seen[row[0]]; duplicate {
			continue
		}
		seen[row[0]] = struct{}{}
		itemIDs = append(itemIDs, row[0])
	}
	if len(itemIDs) == 0 {
		return nil, nil
	}
	return s.Content.ItemKindsTx(c, q, revision, itemIDs)
}

// applyDropMultiplier multiplies only the listed kinds in place.
func applyDropMultiplier(items []d.Item, multipliers, kinds map[int64]int64) {
	if len(multipliers) == 0 || len(kinds) == 0 {
		return
	}
	for index := range items {
		if multiplier := multipliers[kinds[items[index].ItemID]]; multiplier > 1 {
			items[index].Num *= multiplier
		}
	}
}
