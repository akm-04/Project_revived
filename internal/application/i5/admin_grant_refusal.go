package i5

import (
	"errors"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// permanentGrantRefusals are the owner refusals that say the recipient can
// never receive this grant, so a bulk job counts it refused instead of
// retrying forever.
var permanentGrantRefusals = []error{
	economy.ErrUnknownResource,
	economy.ErrStackCapacity,
	economy.ErrInvalidTemporalPolicy,
	economy.ErrInvalidDailyFloor,
	ErrUnsupportedGrantDestination,
	ErrMailStackFull,
	ErrContentRevisionConflict,
	ErrGrantDualReceiptConflict,
}

// IsPermanentGrantRefusal reports whether AdminGrant refused this grant for
// good. Everything else (database, timeout, context, lock, an unclassified
// error) is transient: the caller must retry the same recipient.
func IsPermanentGrantRefusal(err error) bool {
	if err == nil {
		return false
	}
	var conflict *receipt.ConflictError
	if errors.As(err, &conflict) {
		return true
	}
	for _, sentinel := range permanentGrantRefusals {
		if errors.Is(err, sentinel) {
			return true
		}
	}
	// A recipient with no canonical player root breaks the grant's foreign key;
	// no retry can create that player.
	return tx.SQLState(err) == "23503"
}
