//go:build postgres

package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	ftx "gxb.local/backend/v2/internal/foundation/tx"
)

type PoolSettings struct {
	MaxConns          int32
	MinConns          int32
	MaxConnLifetime   time.Duration
	MaxConnIdleTime   time.Duration
	HealthCheckPeriod time.Duration
	ApplicationName   string
}
type Pool struct{ raw *pgxpool.Pool }

func (s PoolSettings) Validate() error {
	if s.MaxConns <= 0 {
		return errors.New("MaxConns must be positive")
	}
	if s.MinConns < 0 || s.MinConns > s.MaxConns {
		return errors.New("MinConns must be between zero and MaxConns")
	}
	if s.MaxConnLifetime <= 0 {
		return errors.New("MaxConnLifetime must be finite and positive")
	}
	if s.MaxConnIdleTime <= 0 {
		return errors.New("MaxConnIdleTime must be finite and positive")
	}
	if s.HealthCheckPeriod <= 0 {
		return errors.New("HealthCheckPeriod must be finite and positive")
	}
	return nil
}

func Open(ctx context.Context, dsn string, s PoolSettings) (*Pool, error) {
	cfg, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, err
	}
	if err := s.Validate(); err != nil {
		return nil, err
	}
	cfg.MaxConns = s.MaxConns
	cfg.MinConns = s.MinConns
	cfg.MaxConnLifetime = s.MaxConnLifetime
	cfg.MaxConnIdleTime = s.MaxConnIdleTime
	cfg.HealthCheckPeriod = s.HealthCheckPeriod
	if cfg.ConnConfig.RuntimeParams == nil {
		cfg.ConnConfig.RuntimeParams = map[string]string{}
	}
	cfg.ConnConfig.RuntimeParams["timezone"] = "UTC"
	if s.ApplicationName != "" {
		cfg.ConnConfig.RuntimeParams["application_name"] = s.ApplicationName
	}
	p, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, err
	}
	return &Pool{raw: p}, nil
}
func (p *Pool) Close()                         { p.raw.Close() }
func (p *Pool) Ping(ctx context.Context) error { return p.raw.Ping(ctx) }
func (p *Pool) Begin(ctx context.Context, o ftx.Options) (ftx.Tx, error) {
	raw, err := p.raw.BeginTx(ctx, pgx.TxOptions{IsoLevel: iso(o.Isolation), AccessMode: access(o.ReadOnly)})
	if err != nil {
		return nil, normalize(err)
	}
	return &wrappedTx{raw: raw}, nil
}
func (p *Pool) QueryRow(ctx context.Context, q string, args ...any) ftx.Row {
	return wrappedRow{row: p.raw.QueryRow(ctx, q, args...)}
}
func (p *Pool) Raw() *pgxpool.Pool { return p.raw }

type wrappedTx struct{ raw pgx.Tx }

func (t *wrappedTx) Exec(ctx context.Context, q string, args ...any) (ftx.CommandTag, error) {
	tag, err := t.raw.Exec(ctx, q, args...)
	return tag, normalize(err)
}
func (t *wrappedTx) QueryRow(ctx context.Context, q string, args ...any) ftx.Row {
	return wrappedRow{row: t.raw.QueryRow(ctx, q, args...)}
}
func (t *wrappedTx) Commit(ctx context.Context) error   { return normalize(t.raw.Commit(ctx)) }
func (t *wrappedTx) Rollback(ctx context.Context) error { return normalize(t.raw.Rollback(ctx)) }
func (t *wrappedTx) RawPGX() pgx.Tx                     { return t.raw }

type wrappedRow struct{ row pgx.Row }

func (r wrappedRow) Scan(dest ...any) error { return normalize(r.row.Scan(dest...)) }
func iso(i ftx.Isolation) pgx.TxIsoLevel {
	switch i {
	case ftx.Serializable:
		return pgx.Serializable
	case ftx.RepeatableRead:
		return pgx.RepeatableRead
	default:
		return pgx.ReadCommitted
	}
}
func access(ro bool) pgx.TxAccessMode {
	if ro {
		return pgx.ReadOnly
	}
	return pgx.ReadWrite
}
func normalize(err error) error {
	if errors.Is(err, pgx.ErrTxCommitRollback) {
		return ftx.MarkDefiniteAbort(err)
	}
	if errors.Is(err, pgx.ErrNoRows) {
		return kernelstore.ErrNoRows
	}
	return err
}

func UnwrapTx(t ftx.Tx) (pgx.Tx, bool) {
	x, ok := t.(interface{ RawPGX() pgx.Tx })
	if !ok {
		return nil, false
	}
	return x.RawPGX(), true
}
