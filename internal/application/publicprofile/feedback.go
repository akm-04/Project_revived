package publicprofile

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/profilefeedback"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// Optional future public-card consumer. Caller pins scope/revision/instant and
// plans Feedback392 after391. No full1829 projection is activated by this port.
type FeedbackReader interface {
	ObserveTx(context.Context, tx.Scope, identity.PlayerID, identity.PlayerID, string, time.Time) (profilefeedback.Observation, error)
}
