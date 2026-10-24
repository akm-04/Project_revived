//go:build postgres && river

package riveradapter

import (
	"context"
	"github.com/riverqueue/river/riverdriver/riverpgxv5"
	"github.com/riverqueue/river/rivermigrate"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"os"
	"testing"
	"time"
)

func TestPreparePublicationRiver(t *testing.T) {
	dsn := os.Getenv("GXB_I7A9_DSN")
	if dsn == "" || os.Getenv("GXB_I7A9_PREPARE_PROCESS") != "1" {
		t.Skip("explicit inherited process fixture setup")
	}
	c := context.Background()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	m, e := rivermigrate.New(riverpgxv5.New(p.Raw()), nil)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = m.Migrate(c, rivermigrate.DirectionUp, nil); e != nil {
		t.Fatal(e)
	}
}
