package i5

import (
	"context"
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/foundation/receipt"
)

type sqlStateError string

func (e sqlStateError) Error() string    { return string(e) }
func (e sqlStateError) SQLState() string { return string(e) }

func TestIsPermanentGrantRefusal(t *testing.T) {
	permanent := []error{
		economy.ErrUnknownResource,
		economy.ErrStackCapacity,
		economy.ErrInvalidTemporalPolicy,
		economy.ErrInvalidDailyFloor,
		ErrUnsupportedGrantDestination,
		ErrMailStackFull,
		ErrContentRevisionConflict,
		ErrGrantDualReceiptConflict,
		&receipt.ConflictError{},
		sqlStateError("23503"),
	}
	for _, err := range permanent {
		if !IsPermanentGrantRefusal(err) {
			t.Fatalf("%v was classified transient", err)
		}
	}
	transient := []error{
		nil,
		errors.New("connection reset"),
		context.Canceled,
		sqlStateError("40001"),
	}
	for _, err := range transient {
		if IsPermanentGrantRefusal(err) {
			t.Fatalf("%v was classified permanent", err)
		}
	}
}
