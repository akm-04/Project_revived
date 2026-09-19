package postgres

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/tx"
)

type timeRow struct {
	at  time.Time
	err error
}

func (r timeRow) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}
	p, ok := dest[0].(*time.Time)
	if !ok {
		return errors.New("bad scan destination")
	}
	*p = r.at
	return nil
}

type timeQueryer struct {
	row   timeRow
	query string
	calls int
}

func (q *timeQueryer) QueryRow(context.Context, string, ...any) tx.Row {
	q.calls++
	return q.row
}

// captureQueryer records exact SQL independently of timeQueryer to keep the
// production query under a narrow regression check.
type captureQueryer struct {
	at    time.Time
	query string
}

func (q *captureQueryer) QueryRow(_ context.Context, query string, _ ...any) tx.Row {
	q.query = query
	return timeRow{at: q.at}
}

func TestAuthoritativeTimeUsesPostgresClockTimestampAndUTC(t *testing.T) {
	zone := time.FixedZone("db-session", 8*60*60)
	want := time.Date(2026, 9, 9, 18, 30, 0, 123, zone)
	q := &captureQueryer{at: want}
	got, err := (AuthoritativeTime{Queryer: q}).Now(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if q.query != "SELECT clock_timestamp()" {
		t.Fatalf("query=%q", q.query)
	}
	if got.Location() != time.UTC || !got.Equal(want) {
		t.Fatalf("got=%v location=%v", got, got.Location())
	}
}

func TestAuthoritativeTimeFailsClosed(t *testing.T) {
	if _, err := (AuthoritativeTime{}).Now(context.Background()); err == nil {
		t.Fatal("nil queryer succeeded")
	}
	boom := errors.New("db unavailable")
	q := &captureQueryer{}
	_ = q
	failing := &errorQueryer{err: boom}
	if _, err := (AuthoritativeTime{Queryer: failing}).Now(context.Background()); !errors.Is(err, boom) {
		t.Fatalf("got %v", err)
	}
	zero := &captureQueryer{at: time.Time{}}
	if _, err := (AuthoritativeTime{Queryer: zero}).Now(context.Background()); err == nil {
		t.Fatal("zero database time succeeded")
	}
}

type errorQueryer struct{ err error }

func (q *errorQueryer) QueryRow(context.Context, string, ...any) tx.Row { return timeRow{err: q.err} }
