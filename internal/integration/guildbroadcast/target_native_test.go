//go:build postgres

package guildbroadcast_test

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildbroadcaststore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/guildbroadcast"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/registry"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"strconv"
	"testing"
	"time"
)

type commitFaultDB struct {
	DB    tx.Beginner
	After bool
}
type commitFaultTx struct {
	tx.Tx
	After bool
}

func (d commitFaultDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	t, e := d.DB.Begin(c, o)
	if e != nil {
		return nil, e
	}
	return commitFaultTx{t, d.After}, nil
}
func (t commitFaultTx) Commit(c context.Context) error {
	if t.After {
		if e := t.Tx.Commit(c); e != nil {
			return e
		}
	}
	return errors.New("injected transport failure at COMMIT boundary")
}

func TestRealGuildBroadcastTargetLifecycle(t *testing.T) {
	dsn := os.Getenv("GXB_I7A8_WORKING_DSN")
	if dsn == "" {
		t.Skip("explicit disposable PostgreSQL DSN required")
	}
	c, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	at := time.Date(2026, 10, 9, 12, 0, 0, 123456789, time.UTC)
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
	op.Policies, e = policy.NewSet(policy.Ref{Name: "content", Version: pol.Revision}, policy.Ref{Name: "guild-core", Version: pol.GuildCoreRevision}, policy.Ref{Name: "guild-broadcast", Version: pol.PolicyID})
	if e != nil {
		t.Fatal(e)
	}
	// Allocate fixture roots from the retained server cursor; do not reset it or
	// truncate any accepted table. All fixture SQL is confined to this test DB.
	seed, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer seed.Rollback(context.Background())
	var first int64
	if e = seed.QueryRow(c, `UPDATE logical_servers SET next_player_id=next_player_id+4,state_version=state_version+1 WHERE logical_server_id=1 AND next_player_id+4<=max_player_id RETURNING next_player_id-4`).Scan(&first); e != nil {
		t.Fatal(e)
	}
	var accounts []ids.UUID
	pids := make([]identity.PlayerID, 4)
	for i := range pids {
		pids[i] = identity.PlayerID(first + int64(i))
		aid, _ := ids.NewUUID()
		accounts = append(accounts, aid)
		if _, e = seed.Exec(c, `INSERT INTO accounts(account_id,status,created_at,account_uid) VALUES($1::uuid,'ACTIVE',$2,$3)`, aid.String(), at, aid.String()); e != nil {
			t.Fatal(e)
		}
		if _, e = seed.Exec(c, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,1,$3,'native-guild-mail-fixture')`, int64(pids[i]), aid.String(), at); e != nil {
			t.Fatal(e)
		}
	}
	if e = seed.Commit(c); e != nil {
		t.Fatal(e)
	}
	makeSource := func() gb.Source {
		o, e := (operation.Factory{Clock: clock.Fixed{T: at}}).New(op.Policies)
		if e != nil {
			t.Fatal(e)
		}
		decision := at.Truncate(time.Microsecond)
		s := gb.Source{Operation: o, GuildID: 1000001, Server: 1, LeaderID: pids[0], LeaderName: "saved leader", NameSnapshotChangedAt: decision, DecisionAt: decision, ContentRevision: pol.Revision, GuildCoreRevision: pol.GuildCoreRevision, PolicyID: pol.PolicyID, Request: gb.Request{Title: "saved title", Content: "saved body"}}
		for i, pid := range pids {
			s.Recipients = append(s.Recipients, gb.Member{PlayerID: pid, JoinEventID: int64(i + 1), JoinedAt: decision})
		}
		x, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
		if e != nil {
			t.Fatal(e)
		}
		defer x.Rollback(context.Background())
		raw, _ := json.Marshal(app.SubmitResult{SourceID: o.ID, RecipientCount: len(pids)})
		fp, _ := receipt.FingerprintRequest(s.Request)
		rid := receipt.Identity{OwnerKind: "player", OwnerKey: fmtPID(pids[0]), Domain: "guild-broadcast", Operation: "submit", SemanticKey: o.ID.String()}
		rr, e := receipt.New(o, rid, "I7A8A_GUILD_SOURCE", "gxb.guild-broadcast.submit.v1", raw, fp)
		if e != nil {
			t.Fatal(e)
		}
		rr.PolicyVersion = s.PolicyID
		rr.ActorAccountUID = accounts[0].String()
		if e = (guildbroadcaststore.Store{}).InsertSourceTx(c, x, s, rr.ID); e != nil {
			t.Fatal(e)
		}
		for _, m := range s.Recipients {
			b := gb.Binding{SourceID: o.ID, RecipientID: m.PlayerID, State: gb.Pending, LastEnqueueAt: decision, NextWakeupAt: decision.Add(time.Minute)}
			if e = (guildbroadcaststore.Store{}).InsertBindingTx(c, x, b, m); e != nil {
				t.Fatal(e)
			}
		}
		if _, e = (kernelstore.Store{}).PutTx(c, x, rr); e != nil {
			t.Fatal(e)
		}
		if e = x.Commit(c); e != nil {
			t.Fatal(e)
		}
		return s
	}
	service := i5.GuildBroadcastMailService{Runner: tx.Runner{DB: p}, Reads: tx.Runner{DB: p}, Sources: app.ImmutableSourceReader{Store: guildbroadcaststore.Store{}, Receipts: kernelstore.Store{}, Content: contentstore.Store{}}, Players: i4store.PlayerRootLocker{}, Mail: i5store.Store{}, Receipts: kernelstore.Store{}}
	s := makeSource()
	proof, e := service.Materialize(c, s.Operation.ID, pids[1])
	if e != nil || proof.State != gb.Delivered {
		t.Fatal(proof, e)
	}
	m, ok, e := (i5store.Store{}).ReadGuildBroadcastMailTx(c, p, pids[1], s.Operation.ID)
	if e != nil || !ok || m.Title != s.Request.Title || m.Sender != s.LeaderName || m.CreatedAt.UnixMicro() != s.DecisionAt.UnixMicro() || len(m.Attachments) != 0 || !m.Shown {
		t.Fatal(m, ok, e)
	}
	// A read/hidden Mail is still the same semantic completion.
	x, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer x.Rollback(context.Background())
	now := at.Truncate(time.Microsecond)
	m.ReadAt = &now
	m.Shown = false
	m.StateVersion++
	if e = (i5store.Store{}).SaveMailStateTx(c, x, m, m.StateVersion-1); e != nil {
		t.Fatal(e)
	}
	if e = x.Commit(c); e != nil {
		t.Fatal(e)
	}
	again, e := service.Materialize(c, s.Operation.ID, pids[1])
	if e != nil || again != proof {
		t.Fatal("replay identity changed", again, e)
	}
	m, _, e = (i5store.Store{}).ReadGuildBroadcastMailTx(c, p, pids[1], s.Operation.ID)
	if e != nil || m.ReadAt == nil || m.Shown {
		t.Fatal("replay reset Mail state", m, e)
	}
	var next int64
	if e = p.QueryRow(c, `SELECT next_wire_id FROM mail_namespace_counters WHERE recipient_player_id=$1 AND namespace='NORMAL'`, int64(pids[1])).Scan(&next); e != nil || next != proof.WireID+1 {
		t.Fatal("replay allocated again", next, e)
	}
	// Source ACK is separate and recovers an existing target result. It cannot
	// reset read/shown state or allocate another counter value.
	delivery := app.Delivery{Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Reads: tx.Runner{DB: p}, Store: guildbroadcaststore.Store{}, Sources: app.ImmutableSourceReader{Store: guildbroadcaststore.Store{}, Receipts: kernelstore.Store{}, Content: contentstore.Store{}}, Target: service}
	if e = delivery.Deliver(c, s.Operation.ID, pids[1]); e != nil {
		t.Fatal("separate ACK", e)
	}
	ack, _, e := (guildbroadcaststore.Store{}).ReadBindingTx(c, p, s.Operation.ID, pids[1])
	if e != nil || ack.State != gb.Delivered || ack.TargetReceiptID != proof.ReceiptID || ack.MailID != proof.MailID || ack.WireID != proof.WireID {
		t.Fatal("ACK proof differs", ack, e)
	}
	if e = delivery.Deliver(c, s.Operation.ID, pids[1]); e != nil {
		t.Fatal("ACK replay", e)
	}
	lostAck := delivery
	lostAck.Timed.Runner.DB = commitFaultDB{DB: p, After: true}
	if e = lostAck.Deliver(c, s.Operation.ID, pids[1]); e != nil {
		t.Fatal("ACK positive UNKNOWN", e)
	}
	// Commit succeeded but transport reply was lost: fresh complete proof returns
	// the same Mail, while source binding remains PENDING until its owner ACK.
	lost := service
	lost.Runner.DB = commitFaultDB{DB: p, After: true}
	postCommit, e := lost.Materialize(c, s.Operation.ID, pids[0])
	if e != nil || postCommit.State != gb.Delivered {
		t.Fatal("complete positive commit proof", postCommit, e)
	}
	b, _, e := (guildbroadcaststore.Store{}).ReadBindingTx(c, p, s.Operation.ID, pids[0])
	if e != nil || b.State != gb.Pending {
		t.Fatal("target committed source ACK prematurely", b, e)
	}
	// Restarting owner composition from a committed target and PENDING source
	// recovers exactly the previous target proof, then marks only the source.
	if e = delivery.Deliver(c, s.Operation.ID, pids[0]); e != nil {
		t.Fatal("target commit / pending source resume", e)
	}
	resumed, _, e := (guildbroadcaststore.Store{}).ReadBindingTx(c, p, s.Operation.ID, pids[0])
	if e != nil || resumed.TargetReceiptID != postCommit.ReceiptID || resumed.State != gb.Delivered {
		t.Fatal(resumed, e)
	}
	// No commit and absent target proof remains UNKNOWN; no blind redo.
	absentSource := makeSource()
	absent := service
	absent.Runner.DB = commitFaultDB{DB: p}
	_, e = absent.Materialize(c, absentSource.Operation.ID, pids[3])
	var unknown *tx.UnknownCommitError
	if !errors.As(e, &unknown) {
		t.Fatal("absence authorized replay", e)
	}
	_, ok, e = (i5store.Store{}).ReadGuildBroadcastMailTx(c, p, pids[3], absentSource.Operation.ID)
	if e != nil || ok {
		t.Fatal("ambiguous absent transaction produced Mail", ok, e)
	}
	// Overflow must fail before allocating. It must not leave Mail or receipt.
	overflowSource := makeSource()
	if _, e = fixtureExec(c, p, `INSERT INTO mail_namespace_counters(recipient_player_id,namespace,next_wire_id,state_version) VALUES($1,'NORMAL',9007199254740992,1)`, int64(pids[3])); e != nil {
		t.Fatal(e)
	}
	if _, e = service.Materialize(c, overflowSource.Operation.ID, pids[3]); e == nil {
		t.Fatal("wire overflow accepted")
	}
	if e = p.QueryRow(c, `SELECT next_wire_id FROM mail_namespace_counters WHERE recipient_player_id=$1 AND namespace='NORMAL'`, int64(pids[3])).Scan(&next); e != nil || next != 9007199254740992 {
		t.Fatal("overflow advanced counter", next, e)
	}
	_, ok, e = (i5store.Store{}).ReadGuildBroadcastMailTx(c, p, pids[3], overflowSource.Operation.ID)
	if e != nil || ok {
		t.Fatal("overflow created Mail", ok, e)
	}
	// Source facts survive player deletion; typed allocator-backed absence creates
	// only a terminal receipt, no namespace or Mail.
	if _, e = fixtureExec(c, p, `DELETE FROM players WHERE player_id=$1`, int64(pids[2])); e != nil {
		t.Fatal(e)
	}
	gone, e := service.Materialize(c, s.Operation.ID, pids[2])
	if e != nil || gone.State != gb.RecipientGone || gone.WireID != 0 || !gone.MailID.IsZero() {
		t.Fatal(gone, e)
	}
	goneAgain, e := service.Materialize(c, s.Operation.ID, pids[2])
	if e != nil || goneAgain != gone {
		t.Fatal("gone replay", goneAgain, e)
	}
	var count int
	if e = p.QueryRow(c, `SELECT count(*) FROM mail_namespace_counters WHERE recipient_player_id=$1`, int64(pids[2])).Scan(&count); e != nil || count != 0 {
		t.Fatal("gone prepared namespace", count, e)
	}
	// Partial restored target pair must stop rather than recreate at a new ID.
	if _, e = fixtureExec(c, p, `DELETE FROM mail_records WHERE mail_uuid=$1::uuid`, proof.MailID.String()); e != nil {
		t.Fatal(e)
	}
	if _, e = service.Materialize(c, s.Operation.ID, pids[1]); !errors.Is(e, i5.ErrGuildBroadcastConflict) {
		t.Fatal("delivered receipt/missing Mail hole accepted", e)
	}
	if e = p.QueryRow(c, `SELECT next_wire_id FROM mail_namespace_counters WHERE recipient_player_id=$1 AND namespace='NORMAL'`, int64(pids[1])).Scan(&next); e != nil || next != proof.WireID+1 {
		t.Fatal("restore hole allocated again", next, e)
	}
	// Historical delivered meaning survives typed recipient deletion. No
	// new Mail or namespace is manufactured after its original cascade deletion.
	if _, e = fixtureExec(c, p, `DELETE FROM players WHERE player_id=$1`, int64(pids[0])); e != nil {
		t.Fatal(e)
	}
	historical, e := service.Materialize(c, s.Operation.ID, pids[0])
	if e != nil || historical != postCommit || historical.State != gb.Delivered {
		t.Fatal("historical delivered deletion proof", historical, e)
	}
	if e = p.QueryRow(c, `SELECT count(*) FROM mail_namespace_counters WHERE recipient_player_id=$1`, int64(pids[0])).Scan(&count); e != nil || count != 0 {
		t.Fatal("historical delivery recreated namespace", count, e)
	}
	if e = delivery.Deliver(c, s.Operation.ID, pids[0]); e != nil {
		t.Fatal("historical source ACK replay after deletion", e)
	}
	t.Log("real PG target commit/replay/read-shown preservation/positive UNKNOWN/absence UNKNOWN/overflow/typed deleted recipient/restore-hole verified; separate source ACK and restart composition verified; production process kill, River worker and full gate NOT_RUN")
}

func fmtPID(pid identity.PlayerID) string { return strconv.FormatInt(int64(pid), 10) }

func fixtureExec(c context.Context, p tx.Beginner, sql string, args ...any) (tx.CommandTag, error) {
	x, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		return nil, e
	}
	defer x.Rollback(context.Background())
	tag, e := x.Exec(c, sql, args...)
	if e != nil {
		return tag, e
	}
	return tag, x.Commit(c)
}
