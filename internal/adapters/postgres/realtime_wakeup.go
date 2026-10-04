//go:build postgres

package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	appwakeup "gxb.local/backend/v2/internal/application/realtimewakeup"
)

type pgWakeupFactory struct{ pool *Pool }

func (f pgWakeupFactory) Acquire(ctx context.Context) (wakeupSession, error) {
	if f.pool == nil || f.pool.raw == nil {
		return nil, errors.New("nil PostgreSQL pool for realtime wakeup listener")
	}
	conn, err := f.pool.raw.Acquire(ctx)
	if err != nil {
		return nil, err
	}
	return &pgWakeupSession{conn: conn}, nil
}

type pgWakeupSession struct{ conn *pgxpool.Conn }

func (s *pgWakeupSession) Listen(ctx context.Context) error {
	if s == nil || s.conn == nil {
		return errors.New("nil realtime wakeup session")
	}
	_, err := s.conn.Exec(ctx, `LISTEN gxb1_realtime_wakeup_v1`)
	return normalize(err)
}
func (s *pgWakeupSession) Wait(ctx context.Context) (string, error) {
	if s == nil || s.conn == nil {
		return "", errors.New("nil realtime wakeup session")
	}
	n, err := s.conn.Conn().WaitForNotification(ctx)
	if err != nil {
		return "", normalize(err)
	}
	if n.Channel != RealtimeWakeupChannel {
		return "", fmt.Errorf("unexpected realtime wakeup channel %q", n.Channel)
	}
	return n.Payload, nil
}
func (s *pgWakeupSession) Close() {
	if s != nil && s.conn != nil {
		s.conn.Release()
		s.conn = nil
	}
}

// RealtimeWakeupListener uses an independently acquired PostgreSQL session. It
// never borrows RealtimeOwnerGuard.conn and therefore cannot alter advisory-lock
// ownership semantics.
type RealtimeWakeupListener struct {
	Pool       *Pool
	Registry   appwakeup.Registry
	RetryDelay time.Duration
}

func (l RealtimeWakeupListener) Run(ctx context.Context) error {
	delay := l.RetryDelay
	if delay == 0 {
		delay = DefaultRealtimeWakeupRetryDelay
	}
	if delay < 0 {
		return errors.New("negative realtime wakeup retry delay")
	}
	return runRealtimeWakeupListener(ctx, pgWakeupFactory{pool: l.Pool}, l.Registry, delay)
}
