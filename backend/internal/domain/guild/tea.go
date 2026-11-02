package guild

import (
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// Wish is one member's day-stable Tea Party request (I9_GUILD_ACTIVITY_V1 C13).
type Wish struct {
	PlayerID   identity.PlayerID
	GameDay    int64
	ItemID     int64
	NeedNum    int64
	CurrentNum int64
}

func (w Wish) Validate() error {
	if !w.PlayerID.Valid() || w.GameDay <= 0 || w.ItemID <= 0 || w.NeedNum <= 0 || w.CurrentNum < 0 || w.CurrentNum > w.NeedNum {
		return errors.New("invalid guild tea wish")
	}
	return nil
}

// Gift is one scroll a donor gave to a receiver's wish on a day. The row is the
// once-per-donor-per-receiver-per-day guard and the claim idempotency key.
type Gift struct {
	ReceiverID identity.PlayerID
	DonorID    identity.PlayerID
	GameDay    int64
	ItemID     int64
	ClaimedAt  *time.Time
}

func (g Gift) Validate() error {
	if !g.ReceiverID.Valid() || !g.DonorID.Valid() || g.ReceiverID == g.DonorID || g.GameDay <= 0 || g.ItemID <= 0 {
		return errors.New("invalid guild tea gift")
	}
	return nil
}
