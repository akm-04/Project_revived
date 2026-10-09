//go:build postgres

package guildbroadcaststore

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/content/registry"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"testing"
	"time"
)

func TestRealPostgresSourceRoundtripAndRestoreHole(t *testing.T) {
	dsn := os.Getenv("GXB_I7A8_WORKING_DSN")
	if dsn == "" {
		t.Skip("scoped working-copy real PostgreSQL check requires explicit DSN")
	}
	c, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	at := time.Date(2026, 10, 9, 9, 0, 0, 123456789, time.UTC)
	op, e := (operation.Factory{Clock: clock.Fixed{T: at}}).New(policy.Set{})
	if e != nil {
		t.Fatal(e)
	}
	bundle, e := registry.LoadBuiltinBundle()
	if e != nil {
		t.Fatal(e)
	}
	reg := registry.Service{Runner: tx.Runner{DB: p}, Repo: contentstore.Store{}, Fresh: p, Providers: registry.DefaultProviderSet()}
	if _, e = reg.EnsureBuiltinInstalled(c, op, bundle); e != nil {
		t.Fatal(e)
	}
	pol, e := (contentstore.Store{}).ReadBroadcastPolicy(c, p, bundle.RevisionID())
	if e != nil {
		t.Fatal(e)
	}
	refs, e := policy.NewSet(policy.Ref{Name: "content", Version: pol.Revision}, policy.Ref{Name: "guild-core", Version: pol.GuildCoreRevision}, policy.Ref{Name: "guild-broadcast", Version: pol.PolicyID})
	if e != nil {
		t.Fatal(e)
	}
	op.Policies = refs
	decision := at.Truncate(time.Microsecond)
	s := gb.Source{Operation: op, GuildID: 1000001, Server: 1, LeaderID: 100001, LeaderName: "", NameSnapshotChangedAt: decision, DecisionAt: decision, ContentRevision: pol.Revision, GuildCoreRevision: pol.GuildCoreRevision, PolicyID: pol.PolicyID, Request: gb.Request{Title: "title", Content: "body"}, Recipients: []gb.Member{{PlayerID: 100001, JoinEventID: 1, JoinedAt: decision}, {PlayerID: 100002, JoinEventID: 2, JoinedAt: decision}}}
	expected, e := s.Fingerprint()
	if e != nil {
		t.Fatal(e)
	}
	rid := receipt.Identity{OwnerKind: "player", OwnerKey: "100001", Domain: "guild-broadcast", Operation: "submit", SemanticKey: op.ID.String()}
	fp, e := receipt.FingerprintRequest(s.Request)
	if e != nil {
		t.Fatal(e)
	}
	rr, e := receipt.New(op, rid, "I7A8A_GUILD_SOURCE", "gxb.guild-broadcast.submit.v1", []byte(`{}`), fp)
	if e != nil {
		t.Fatal(e)
	}
	x, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer x.Rollback(context.Background())
	if e = (Store{}).InsertSourceTx(c, x, s, rr.ID); e != nil {
		t.Fatal(e)
	}
	for _, m := range s.Recipients {
		b := gb.Binding{SourceID: op.ID, RecipientID: m.PlayerID, State: gb.Pending, LastEnqueueAt: decision, NextWakeupAt: decision.Add(time.Minute)}
		if e = (Store{}).InsertBindingTx(c, x, b, m); e != nil {
			t.Fatal(e)
		}
	}
	if _, e = (kernelstore.Store{}).PutTx(c, x, rr); e != nil {
		t.Fatal(e)
	}
	if e = x.Commit(c); e != nil {
		t.Fatal(e)
	}
	got, ok, e := (Store{}).ReadSourceTx(c, p, op.ID)
	if e != nil || !ok {
		t.Fatal(ok, e)
	}
	actual, e := got.Fingerprint()
	if e != nil || actual != expected || !got.Operation.StartedAt.Equal(op.StartedAt) {
		t.Fatal("source/context precision changed", e)
	}
	b, ok, e := (Store{}).ReadBindingTx(c, p, op.ID, s.LeaderID)
	if e != nil || !ok || b.State != gb.Pending {
		t.Fatal(b, ok, e)
	}
	// A restored source with a missing roster row must fail closed; no synthesis.
	x, e = p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	if _, e = x.Exec(c, `DELETE FROM guild_broadcast_recipients WHERE source_id=$1::uuid AND recipient_player_id=$2`, op.ID.String(), int64(s.Recipients[1].PlayerID)); e != nil {
		t.Fatal(e)
	}
	if e = x.Commit(c); e != nil {
		t.Fatal(e)
	}
	if _, _, e = (Store{}).ReadSourceTx(c, p, op.ID); e == nil {
		t.Fatal("partial restore hole accepted")
	}
	t.Log("Real PG source+binding+receipt commit, exact context nanoseconds, empty-name snapshot, and restore-hole conflict verified; River/source-service/target-Mail gates NOT_RUN")
}
