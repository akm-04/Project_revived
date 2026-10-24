package tx

import (
	"gxb.local/backend/v2/internal/foundation/operation"
	"time"
)

type Event struct {
	Operation operation.Context
	Profile   string
	Attempt   int
	Phase     string
	Outcome   CommitOutcome
	SQLState  string
	Duration  time.Duration
}
type Hooks interface{ OnEvent(Event) }
type NopHooks struct{}

func (NopHooks) OnEvent(Event) {}
