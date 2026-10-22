//go:build postgres

// gxb-client-log prints one player's request journal, uploads and client log
// rows as time-ordered JSON lines (I85_CLIENT_LOG_INGEST_V1 operator view).
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"os"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/clientlogstore"
)

func run() error {
	if len(os.Args) < 2 || os.Args[1] != "timeline" {
		return errors.New("usage: gxb-client-log timeline -uid UID [-since RFC3339] [-limit N]")
	}
	flags := flag.NewFlagSet("timeline", flag.ContinueOnError)
	uid := flags.String("uid", "", "account uid")
	since := flags.String("since", "", "RFC3339 lower bound (default: 30 days ago)")
	limit := flags.Int("limit", 1000, "maximum lines")
	if err := flags.Parse(os.Args[2:]); err != nil {
		return err
	}
	if *uid == "" || *limit <= 0 {
		return errors.New("-uid and a positive -limit are required")
	}
	from := time.Now().Add(-30 * 24 * time.Hour)
	if *since != "" {
		parsed, err := time.Parse(time.RFC3339, *since)
		if err != nil {
			return err
		}
		from = parsed
	}
	dsn := os.Getenv("GXB_POSTGRES_DSN")
	if dsn == "" {
		return errors.New("GXB_POSTGRES_DSN required")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		return err
	}
	defer pool.Close()
	lines, err := clientlogstore.Store{Pool: pool.Raw()}.Timeline(ctx, *uid, from, *limit)
	if err != nil {
		return err
	}
	for _, line := range lines {
		fmt.Println(string(line))
	}
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
