//go:build postgres

package dormstore_test

import (
	"context"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/characterasset"
	appdorm "gxb.local/backend/v2/internal/application/dormhouse"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"testing"
	"time"
)

// Real owner/value/reference/content ports with explicit fixture prerequisites.
// No activation, wire/paid admission, genuine Character creation/removal or race
// qualification is claimed by this focused working-state check.
func TestDormNativeStockRetentionAndReferencePorts(t *testing.T) {
	dsn := os.Getenv("GXB_I7C2C_DSN")
	if dsn == "" {
		t.Skip("GXB_I7C2C_DSN required")
	}
	ctx := context.Background()
	p, e := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "i7c2c-composition-working"})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	bundle, e := registry.LoadBuiltinBundle()
	if e != nil {
		t.Fatal(e)
	}
	op, e := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if e != nil {
		t.Fatal(e)
	}
	cs := contentstore.Store{Queryer: p}
	service := registry.Service{Runner: tx.Runner{DB: p}, Repo: cs, Fresh: p, Providers: registry.DefaultProviderSet()}
	if _, e = service.EnsureBuiltinInstalled(ctx, op, bundle); e != nil {
		t.Fatal(e)
	}
	// This installs/validates immutable content only. It deliberately does not
	// switch activation before the complete owning deployment/backfill gate.
	owner := dormstore.Store{Queryer: p}
	usage := appdorm.FurnitureUsage{Owner: owner, Content: cs}
	values := i5store.Store{Queryer: p, StackUsage: usage}
	var fixturePID, fixturePartner int64
	if e = p.QueryRow(ctx, `SELECT h.player_id,h.partner_id FROM player_heroes h JOIN player_economy_owners e USING(player_id) ORDER BY h.player_id,h.partner_id LIMIT 1`).Scan(&fixturePID, &fixturePartner); e != nil {
		t.Fatal("accepted49 canonical prerequisite fixture required", e)
	}
	pid := identity.PlayerID(fixturePID)
	ref := character.HeroRef{PlayerID: pid, PartnerID: fixturePartner}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	var now time.Time
	if e = tr.QueryRow(ctx, `SELECT clock_timestamp()`).Scan(&now); e != nil {
		t.Fatal(e)
	}
	c, e := cs.DormCatalogTx(ctx, tr, bundle.RevisionID())
	if e != nil {
		t.Fatal(e)
	}
	if e = owner.EnsureRootTx(ctx, tr, pid, bundle.RevisionID(), now); e != nil {
		t.Fatal(e)
	}
	root, e := owner.LockRootTx(ctx, tr, pid)
	if e != nil {
		t.Fatal(e)
	}
	rooms, e := owner.ListRoomsTx(ctx, tr, pid)
	if e != nil {
		t.Fatal(e)
	}
	next, room, e := c.NewRoom(root, rooms, 1000002, 1, 1, bundle.RevisionID(), now)
	if e != nil {
		t.Fatal(e)
	}
	if e = owner.InsertRoomTx(ctx, tr, room); e != nil {
		t.Fatal(e)
	}
	if e = owner.SaveRootTx(ctx, tr, next, root.StateVersion); e != nil {
		t.Fatal(e)
	}
	if e = owner.InitFreshHeroTx(ctx, tr, ref, now); e != nil {
		t.Fatal(e)
	}
	if e = values.LockEconomyOwnerTx(ctx, tr, pid); e != nil {
		t.Fatal(e)
	}
	stack := economy.StackState{PlayerID: pid, ItemID: 50031013, Quantity: 2, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
	oldStack, existed, e := values.LockStackTx(ctx, tr, pid, stack.ItemID, now)
	if e != nil {
		t.Fatal(e)
	}
	if existed {
		stack.StateVersion = oldStack.StateVersion + 1
		stack.AcquiredAt = oldStack.AcquiredAt
	}
	if e = values.SaveStackTx(ctx, tr, stack, existed); e != nil {
		t.Fatal(e)
	}
	room.Layout["50031013#4#1#0"] = ""
	layout, e := c.ValidateLayout(room.TableID, 0, room.Layout)
	if e != nil {
		t.Fatal(e)
	}
	room.Comfort = layout.Comfort
	room.StateVersion++
	if e = owner.SaveRoomTx(ctx, tr, room, 1); e != nil {
		t.Fatal(e)
	}
	minimum, e := usage.MinimumRetainedStackTx(ctx, tr, pid, stack.ItemID)
	if e != nil || minimum != 1 {
		t.Fatal(minimum, e)
	}
	free, e := usage.MinimumRetainedStackTx(ctx, tr, pid, c.Rooms[room.TableID].Dresser)
	if e != nil || free != 0 {
		t.Fatal("built-in dresser charged", free, e)
	}
	depleted := stack
	depleted.Quantity = 0
	depleted.StateVersion++
	if e = values.SaveStackTx(ctx, tr, depleted, true); e == nil {
		t.Fatal("save-to-zero bypassed placed use")
	}
	if e = values.DeleteStackTx(ctx, tr, depleted); e == nil {
		t.Fatal("delete bypassed placed use")
	}
	current, ok, e := values.LockStackTx(ctx, tr, pid, stack.ItemID, now)
	if e != nil || !ok || current.Quantity != 2 || current.StateVersion != stack.StateVersion {
		t.Fatal(current, ok, e)
	}
	retained := stack
	retained.Quantity = 1
	retained.StateVersion++
	if e = values.SaveStackTx(ctx, tr, retained, true); e != nil {
		t.Fatal(e)
	}
	f, e := owner.ReadHeroTx(ctx, tr, ref)
	if e != nil {
		t.Fatal(e)
	}
	f.HouseID = room.ID
	f.Equipment[0] = 1
	f.StateVersion++
	if e = owner.SaveHeroTx(ctx, tr, f, 1); e != nil {
		t.Fatal(e)
	}
	plan, e := owner.PreflightHeroRemovalTx(ctx, tr, ref)
	if e != nil {
		t.Fatal(e)
	}
	if e = owner.ValidateHeroRemovalLockedTx(ctx, tr, ref, plan); !errors.Is(e, characterasset.ErrReferenceInUse) {
		t.Fatal("resident removal unguarded", e)
	}
	f.HouseID = 0
	f.StateVersion++
	if e = owner.SaveHeroTx(ctx, tr, f, 2); e != nil {
		t.Fatal(e)
	}
	if e = owner.ValidateHeroRemovalLockedTx(ctx, tr, ref, plan); e != nil {
		t.Fatal("inactive retained equipment makes Hero busy", e)
	}
	if _, e = usage.MinimumRetainedStackTx(ctx, tr, identity.PlayerID(777399), stack.ItemID); e == nil {
		t.Fatal("missing root manufactured zero usage")
	}
	// The whole fixture remains rolled back. Exact final command and concurrency
	// evidence will run later on the intended frozen combined candidate.
}

func TestDormNativeOldSnapshotStockReservation(t *testing.T) {
	dsn := os.Getenv("GXB_I7C2C_DSN")
	if dsn == "" {
		t.Skip("GXB_I7C2C_DSN required")
	}
	ctx := context.Background()
	p, e := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "i7c2c-snapshot-working"})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	bundle, e := registry.LoadBuiltinBundle()
	if e != nil {
		t.Fatal(e)
	}
	cs := contentstore.Store{Queryer: p}
	owner := dormstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p, StackUsage: appdorm.FurnitureUsage{Owner: owner, Content: cs}}
	var rawPID int64
	if e = p.QueryRow(ctx, `SELECT player_id FROM player_economy_owners ORDER BY player_id LIMIT 1`).Scan(&rawPID); e != nil {
		t.Fatal(e)
	}
	pid := identity.PlayerID(rawPID)
	setup, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer setup.Rollback(ctx)
	var now time.Time
	if e = setup.QueryRow(ctx, `SELECT clock_timestamp()`).Scan(&now); e != nil {
		t.Fatal(e)
	}
	if e = owner.EnsureRootTx(ctx, setup, pid, bundle.RevisionID(), now); e != nil {
		t.Fatal(e)
	}
	root, e := owner.LockRootTx(ctx, setup, pid)
	if e != nil {
		t.Fatal(e)
	}
	rooms, e := owner.ListRoomsTx(ctx, setup, pid)
	if e != nil {
		t.Fatal(e)
	}
	c, e := cs.DormCatalogTx(ctx, setup, bundle.RevisionID())
	if e != nil {
		t.Fatal(e)
	}
	next, room, e := c.NewRoom(root, rooms, 1000002, 1, 1, bundle.RevisionID(), now)
	if e != nil {
		t.Fatal(e)
	}
	if e = owner.InsertRoomTx(ctx, setup, room); e != nil {
		t.Fatal(e)
	}
	if e = owner.SaveRootTx(ctx, setup, next, root.StateVersion); e != nil {
		t.Fatal(e)
	}
	if e = values.LockEconomyOwnerTx(ctx, setup, pid); e != nil {
		t.Fatal(e)
	}
	original, existed, e := values.LockStackTx(ctx, setup, pid, 50031013, now)
	if e != nil {
		t.Fatal(e)
	}
	stack := economy.StackState{PlayerID: pid, ItemID: 50031013, Quantity: 10, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
	if existed {
		stack.StateVersion = original.StateVersion + 1
		stack.AcquiredAt = original.AcquiredAt
	}
	if e = values.SaveStackTx(ctx, setup, stack, existed); e != nil {
		t.Fatal(e)
	}
	if e = setup.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	defer func() {
		tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
		if e != nil {
			t.Error(e)
			return
		}
		defer tr.Rollback(ctx)
		if existed {
			_, e = tr.Exec(ctx, `UPDATE player_item_stacks SET quantity=$3,state_version=$4,acquired_at=$5,updated_at=$6 WHERE player_id=$1 AND item_id=$2`, int64(pid), original.ItemID, original.Quantity, original.StateVersion, original.AcquiredAt, original.UpdatedAt)
		} else {
			_, e = tr.Exec(ctx, `DELETE FROM player_item_stacks WHERE player_id=$1 AND item_id=50031013`, int64(pid))
		}
		if e != nil {
			t.Error(e)
			return
		}
		if _, e = tr.Exec(ctx, `DELETE FROM player_dorm_rooms WHERE player_id=$1`, int64(pid)); e != nil {
			t.Error(e)
			return
		}
		if _, e = tr.Exec(ctx, `DELETE FROM player_dorm_roots WHERE player_id=$1`, int64(pid)); e != nil {
			t.Error(e)
			return
		}
		if e = tr.Commit(ctx); e != nil {
			t.Error(e)
		}
	}()
	// A captures its snapshot before B reserves furniture. A must not commit a
	// stale zero-use observation after B has committed a placement/stock read.
	a, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer a.Rollback(ctx)
	if _, e = owner.ReadRootTx(ctx, a, pid); e != nil {
		t.Fatal(e)
	}
	b, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer b.Rollback(ctx)
	br, e := owner.LockRootTx(ctx, b, pid)
	if e != nil {
		t.Fatal(e)
	}
	if e = values.LockEconomyOwnerTx(ctx, b, pid); e != nil {
		t.Fatal(e)
	}
	if _, ok, e := values.LockStackTx(ctx, b, pid, stack.ItemID, now); e != nil || !ok {
		t.Fatal(ok, e)
	}
	room.Layout["50031013#4#1#0"] = ""
	lr, e := c.ValidateLayout(room.TableID, 0, room.Layout)
	if e != nil {
		t.Fatal(e)
	}
	room.Comfort = lr.Comfort
	room.StateVersion++
	if e = owner.SaveRoomTx(ctx, b, room, 1); e != nil {
		t.Fatal(e)
	}
	br.StateVersion++
	if e = owner.SaveRootTx(ctx, b, br, br.StateVersion-1); e != nil {
		t.Fatal(e)
	}
	if e = b.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	if e = values.LockEconomyOwnerTx(ctx, a, pid); e != nil {
		t.Fatal(e)
	}
	depleted := stack
	depleted.Quantity = 0
	depleted.StateVersion++
	failure := values.SaveStackTx(ctx, a, depleted, true)
	if failure == nil {
		failure = a.Commit(ctx)
	}
	var sqlstate interface{ SQLState() string }
	if !errors.As(failure, &sqlstate) || sqlstate.SQLState() != "40001" {
		t.Fatalf("old snapshot failed to abort canonically: %v", failure)
	}
	if e = a.Rollback(ctx); e != nil {
		t.Fatal(e)
	}
	read, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer read.Rollback(ctx)
	observed, ok, e := values.LockStackTx(ctx, read, pid, stack.ItemID, now)
	if e != nil || !ok || observed.Quantity != 10 {
		t.Fatal(observed, ok, e)
	}
	minimum, e := values.StackUsage.MinimumRetainedStackTx(ctx, read, pid, stack.ItemID)
	if e != nil || minimum != 1 {
		t.Fatal(minimum, e)
	}
}
