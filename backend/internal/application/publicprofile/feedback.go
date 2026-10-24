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

// SPACE composition is reserved for6. Caller owns privacy and lock planning;
// this exact scoped provider discovers no active revision/clock or transaction.
type CommentReader interface {
	ObserveCommentsTx(context.Context, tx.Scope, identity.PlayerID, identity.PlayerID, string, time.Time, int64, int64, bool) (profilefeedback.CommentObservation, error)
}
