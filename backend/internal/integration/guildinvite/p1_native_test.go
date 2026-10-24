//go:build postgres

package guildinvite_test

import (
	"context"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"os"
	"testing"
	"time"
)

func database(t *testing.T) (context.Context, *postgres.Pool) {
	t.Helper()
	dsn := os.Getenv("GXB_I7A8B_P1_DSN")
	if dsn == "" {
		t.Skip("explicit disposable38 P1 working database required")
	}
	c, cancel := context.WithTimeout(context.Background(), time.Minute)
	t.Cleanup(cancel)
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	t.Cleanup(p.Close)
	return c, p
}

func mustOp(t *testing.T, refs policy.Set) operation.Context {
	t.Helper()
	op, e := (operation.Factory{Clock: clock.System{}}).New(refs)
	if e != nil {
		t.Fatal(e)
	}
	return op
}

func TestWorkingP1RetainedGenerationAggregateAndRollback(t *testing.T) {
	c, p := database(t)
	tr, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(c)
	k := kernelstore.Store{}
	gid := guild.ID(1000001)
	target := identity.PlayerID(100002)
	before, e := k.GuildInviteGenerationHighWaterTx(c, tr, gid, target)
	if e != nil {
		t.Fatal(e)
	}
	put := func(key string) {
		t.Helper()
		rr, e := receipt.New(mustOp(t, policy.Set{}), receipt.Identity{OwnerKind: "guild", OwnerKey: fmt.Sprint(gid), Domain: "guild", Operation: "invite", SemanticKey: key}, "I6C_GUILD", "gxb.i6c.guild.invite.v1", json.RawMessage(`{"guild_id":1000001}`), [32]byte{1})
		if e != nil {
			t.Fatal(e)
		}
		if _, e = k.PutTx(c, tr, rr); e != nil {
			t.Fatal(e)
		}
	}
	put("actorver:1:target:100002:gen:9223372036854775807")
	high, e := k.GuildInviteGenerationHighWaterTx(c, tr, gid, target)
	if e != nil || high != math.MaxInt64 {
		t.Fatal(high, e)
	}
	if _, e = gi.NextGeneration(0, 0, high); e == nil {
		t.Fatal("exhaustion reused generation")
	}
	put("actorver:01:target:100003:gen:4")
	if _, e = k.GuildInviteGenerationHighWaterTx(c, tr, gid, target); e == nil {
		t.Fatal("malformed other-target history evaded complete scoped validation")
	}
	if e = tr.Rollback(c); e != nil {
		t.Fatal(e)
	}
	after, e := k.GuildInviteGenerationHighWaterTx(c, p, gid, target)
	if e != nil || after != before {
		t.Fatal("rollback retained semantic generation", before, after, e)
	}
}
