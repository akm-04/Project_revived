//go:build postgres

package compat_test

import (
	"context"
	"fmt"
	"net/url"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/foundation/ids"
)

func compatOpenPool(t *testing.T, dsn string) *pg.Pool {
	t.Helper()
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	return pool
}

func compatDisposableDatabase(t *testing.T, baseDSN string) (string, func()) {
	t.Helper()
	if baseDSN == "" {
		t.Fatal("GXB_I9_11D_DSN required")
	}
	base, err := url.Parse(baseDSN)
	if err != nil {
		t.Fatal(err)
	}
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	name := "compat_backfill_" + strings.ReplaceAll(id.String(), "-", "")
	compatRunTool(t, "createdb", "--maintenance-db", baseDSN, name)
	target := *base
	target.Path = "/" + name
	return target.String(), func() {
		exec.Command("dropdb", "--force", "--maintenance-db", baseDSN, name).Run()
	}
}

func compatRunTool(t *testing.T, name string, arguments ...string) string {
	t.Helper()
	output, err := exec.Command(name, arguments...).CombinedOutput()
	if err != nil {
		t.Fatal(compatUserinfo.ReplaceAllString(fmt.Sprintf("%s %v: %v %s", name, arguments, err, output), "://[REDACTED]@"))
	}
	return string(output)
}

var compatUserinfo = regexp.MustCompile(`://[^/\s]*@`)

func compatMigrationsRoot(t *testing.T) string {
	t.Helper()
	_, file, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("caller unavailable")
	}
	return filepath.Clean(filepath.Join(filepath.Dir(file), "..", "..", "..", "migrations"))
}
