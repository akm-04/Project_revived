package adventure

import (
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// SingleAttempt is one frozen Fantasy-single start (2421) and its attested
// 2422 result. The Combat attempt is the battle owner; this row is the
// Adventure-side replay identity.
type SingleAttempt struct {
	ID         string            `json:"attempt_id"`
	PlayerID   identity.PlayerID `json:"player_id"`
	EventType  int64             `json:"event_type"`
	OccurredAt time.Time         `json:"occurred_at"`
	CreatedAt  time.Time         `json:"created_at"`
	Resolved   bool              `json:"resolved"`
	Damage     int64             `json:"damage"`
}

func (a SingleAttempt) Validate() error {
	if strings.TrimSpace(a.ID) == "" || !a.PlayerID.Valid() || a.EventType != EventIllusion || a.OccurredAt.IsZero() || a.CreatedAt.IsZero() || a.Damage < 0 {
		return ErrInvalid
	}
	return nil
}
