package backpack

import (
	"errors"
	"sort"

	"gxb.local/backend/v2/internal/domain/economy"
)

// Build projects canonical ordinary stack ownership into the stock LOAD_BACKPACK
// shape consumed by current src_64/app/model/Backpack.lua.
//
// SOURCE_FACT: stock `time` is the stack's first acquisition/start timestamp.
// Current Backpack.addItem merges later quantities without replacing that
// timestamp, therefore UpdatedAt must never be projected here.
func Build(stacks []economy.StackState) (map[string]any, error) {
	rows := make([]economy.StackState, len(stacks))
	copy(rows, stacks)
	sort.Slice(rows, func(i, j int) bool { return rows[i].ItemID < rows[j].ItemID })

	out := make([]any, 0, len(rows))
	for _, s := range rows {
		if err := s.Validate(); err != nil {
			return nil, err
		}
		if s.Quantity <= 0 {
			return nil, errors.New("backpack projection encountered non-positive durable stack")
		}
		out = append(out, map[string]any{
			"table_id": s.ItemID,
			"item_num": s.Quantity,
			"time":     s.AcquiredAt.UTC().Unix(),
		})
	}
	return map[string]any{
		"sort_type":   int64(0),
		"list":        out,
		"spirit_list": []any{},
	}, nil
}
