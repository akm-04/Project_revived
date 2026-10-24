package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const authoritativeTimeQuery = "SELECT clock_timestamp()"

// AuthoritativeTime reads PostgreSQL wall time for durable I6A temporal
// decisions. It deliberately does not use transaction_timestamp()/now(), whose
// value is tied to transaction start, because binding occurs before the owner
// Runner retry loop and must be sampled once from the database.
type AuthoritativeTime struct{ Queryer tx.Queryer }

func (a AuthoritativeTime) Now(ctx context.Context) (time.Time, error) {
	if a.Queryer == nil {
		return time.Time{}, errors.New("nil PostgreSQL time queryer")
	}
	var at time.Time
	if err := a.Queryer.QueryRow(ctx, authoritativeTimeQuery).Scan(&at); err != nil {
		return time.Time{}, fmt.Errorf("read PostgreSQL authoritative time: %w", err)
	}
	if at.IsZero() {
		return time.Time{}, errors.New("PostgreSQL authoritative time is zero")
	}
	return at.UTC(), nil
}

var _ appgeneration.TimeAuthority = AuthoritativeTime{}
