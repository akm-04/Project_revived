package i5

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// I5 owns these canonical prerequisite observations. The caller holds a pinned
// snapshot/instant and plans progression/function locks when composing writes.
type DormFunctionFact struct {
	FunctionID    int64     `json:"function_id"`
	StateVersion  int64     `json:"state_version"`
	SourceFactKey string    `json:"source_fact_key"`
	OpenedAt      time.Time `json:"opened_at"`
}
type DormPlayerState struct {
	Player              identity.PlayerID
	Level, LevelVersion int64
	UpdatedAt           time.Time
	Functions           map[int64]DormFunctionFact
}
type DormPlayerStateReader interface {
	ReadDormPlayerStateTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (DormPlayerState, error)
}

// StackUsageQuery supplies a minimum retained quantity from another canonical
// owner. Queryer belongs to I5's caller transaction. It acquires no lower owner
// lock or transaction and must fail on missing/unqualified required state.
type StackUsageQuery interface {
	MinimumRetainedStackTx(context.Context, tx.Queryer, identity.PlayerID, int64) (int64, error)
}
