//go:build postgres

package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// RealtimeOwnerAdvisoryKey is a V2 implementation namespace, not recovered
// gameplay truth. It encodes "GXB1RTOW" as a stable positive int64 key.
const RealtimeOwnerAdvisoryKey int64 = 0x4758423152544f57

const DefaultRealtimeOwnerHealthInterval = 5 * time.Second

var ErrRealtimeOwnerAlreadyHeld = errors.New("realtime single-owner lease already held")

// RealtimeOwnerGuard holds one PostgreSQL session advisory lock for the process
// lifetime. R6 deliberately enforces the currently supported single realtime
// owner instead of pretending the in-memory connection registry is a
// distributed ownership mechanism.
type RealtimeOwnerGuard struct {
	conn *pgxpool.Conn
	key  int64
}

func AcquireRealtimeOwner(ctx context.Context, p *Pool) (*RealtimeOwnerGuard, error) {
	return acquireSessionOwner(ctx, p, RealtimeOwnerAdvisoryKey, ErrRealtimeOwnerAlreadyHeld)
}

// GuildBroadcastOwnerAdvisoryKey is a separate finite worker namespace (GXB1GBOW).
// It never claims the Realtime owner key or enables another obligation owner.
const GuildBroadcastOwnerAdvisoryKey int64 = 0x4758423147424f57

var ErrGuildBroadcastOwnerAlreadyHeld = errors.New("Guild broadcast single-worker owner already held")

func AcquireGuildBroadcastOwner(ctx context.Context, p *Pool) (*RealtimeOwnerGuard, error) {
	return acquireSessionOwner(ctx, p, GuildBroadcastOwnerAdvisoryKey, ErrGuildBroadcastOwnerAlreadyHeld)
}

func acquireSessionOwner(ctx context.Context, p *Pool, key int64, held error) (*RealtimeOwnerGuard, error) {
	if p == nil || p.raw == nil {
		return nil, errors.New("nil PostgreSQL pool for realtime ownership")
	}
	conn, err := p.raw.Acquire(ctx)
	if err != nil {
		return nil, err
	}
	var ok bool
	if err := conn.QueryRow(ctx, `SELECT pg_try_advisory_lock($1)`, key).Scan(&ok); err != nil {
		conn.Release()
		return nil, normalize(err)
	}
	if !ok {
		conn.Release()
		return nil, held
	}
	return &RealtimeOwnerGuard{conn: conn, key: key}, nil
}

// RunHealthPulses proves the dedicated lock-owning PostgreSQL session remains
// alive. Session advisory locks disappear with their owning connection, so a
// lost pulse is a process-fatal ownership loss rather than permission to keep
// serving through unrelated pool connections.
func (g *RealtimeOwnerGuard) RunHealthPulses(ctx context.Context, interval time.Duration) error {
	if g == nil || g.conn == nil {
		return errors.New("realtime owner guard is not active")
	}
	if interval <= 0 {
		return errors.New("realtime owner health interval must be positive")
	}
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
			var one int
			if err := g.conn.QueryRow(ctx, `SELECT 1`).Scan(&one); err != nil {
				return normalize(err)
			}
			if one != 1 {
				return errors.New("realtime owner health probe returned unexpected value")
			}
		}
	}
}

func (g *RealtimeOwnerGuard) Close() error {
	if g == nil || g.conn == nil {
		return nil
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	_, err := g.conn.Exec(ctx, `SELECT pg_advisory_unlock($1)`, g.key)
	g.conn.Release()
	g.conn = nil
	return normalize(err)
}
