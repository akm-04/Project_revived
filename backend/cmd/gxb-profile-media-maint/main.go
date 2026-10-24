//go:build postgres && linux

package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	backup "gxb.local/backend/v2/internal/adapters/profilemediabackup"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"os/exec"
	"time"
)

func run() error {
	mode := flag.String("mode", "verify", "verify|gc|backup|restore")
	root := flag.String("root", os.Getenv("GXB_PROFILE_MEDIA_ROOT"), "absolute owned media root")
	bundle := flag.String("bundle", "", "absolute bundle directory")
	offline := flag.Bool("offline", false, "operator confirms all DB writers/publishers/GC stopped for entire backup/restore")
	pgdump := flag.String("pg-dump", "pg_dump", "pinned pg_dump executable")
	pgrestore := flag.String("pg-restore", "pg_restore", "pinned pg_restore executable")
	flag.Parse()
	c := context.Background()
	dsn := os.Getenv("GXB_POSTGRES_DSN")
	if dsn == "" {
		return errors.New("GXB_POSTGRES_DSN required")
	}
	p, e := pg.Open(c, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		return e
	}
	defer p.Close()
	if *mode == "restore" {
		if !*offline {
			return errors.New("restore requires offline procedure")
		}
		var count int64
		if e = p.QueryRow(c, `SELECT count(*) FROM pg_catalog.pg_tables WHERE schemaname NOT IN('pg_catalog','information_schema')`).Scan(&count); e != nil {
			return e
		}
		if count != 0 {
			return errors.New("restore destination DB must be empty")
		}
		e = backup.RestoreIntoEmpty(c, *bundle, *root, true, func(c context.Context, path string) error {
			cmd := exec.CommandContext(c, *pgrestore, "--exit-on-error", "--no-owner", "--dbname", dsn, path)
			cmd.Stdout = os.Stderr
			cmd.Stderr = os.Stderr
			return cmd.Run()
		})
		if e != nil {
			return e
		}
	}
	b, e := blobstore.NewLocal(*root)
	if e != nil {
		return e
	}
	m := app.MediaMaintenance{Service: app.MediaService{Commands: app.CommandService{Reads: tx.Runner{DB: p}, Roots: app.RootService{Store: publicprofilestore.Store{}}, Receipts: kernelstore.Store{}, Content: contentstore.Store{}}, Media: publicprofilestore.Store{}, Blobs: b}, Receipts: kernelstore.Store{}}
	switch *mode {
	case "verify":
		return m.Validate(c)
	case "gc":
		r, e := m.Collect(c)
		if e != nil {
			return e
		}
		return json.NewEncoder(os.Stdout).Encode(r)
	case "backup":
		return backup.Backup(c, m, *bundle, *offline, func(c context.Context, path string) error {
			cmd := exec.CommandContext(c, *pgdump, "--format=custom", "--no-owner", "--file", path, dsn)
			cmd.Stdout = os.Stderr
			cmd.Stderr = os.Stderr
			return cmd.Run()
		})
	case "restore":
		return backup.VerifyRestored(c, m, *bundle)
	default:
		return fmt.Errorf("unknown maintenance mode")
	}
}
func main() {
	if e := run(); e != nil {
		fmt.Fprintln(os.Stderr, e)
		os.Exit(1)
	}
}
