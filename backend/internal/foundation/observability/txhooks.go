package observability

import (
	"fmt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type TxHooks struct{ Metrics Metrics }

func (h TxHooks) OnEvent(e tx.Event) {
	m := h.Metrics
	if m == nil {
		m = NopMetrics{}
	}
	labels, err := NewLabels(Pair{"profile", e.Profile}, Pair{"phase", e.Phase}, Pair{"outcome", e.Outcome.String()}, Pair{"sql_class", sqlClass(e.SQLState)})
	if err != nil {
		return
	}
	m.Observe("gxb_tx_phase_duration", labels, e.Duration)
	if e.Outcome == tx.UnknownCommitOutcome {
		m.Counter("gxb_unknown_commit_total", labels, 1)
	}
}
func sqlClass(s string) string {
	switch s {
	case "":
		return "none"
	case "40001":
		return "serialization"
	case "40P01":
		return "deadlock"
	case "57014":
		return "timeout"
	default:
		if len(s) == 5 {
			return "sqlstate_" + s[:2]
		}
		return "other"
	}
}
func SafeSQLState(s string) string {
	if len(s) == 5 {
		return s
	}
	return fmt.Sprintf("invalid")
}
