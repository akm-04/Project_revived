//go:build postgres

package dormstore_test

import (
	"context"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/character"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"testing"
	"time"
)

// This is a targeted owner/schema foundation check, not genuine Dorm command,
// Character initialization, economic, admission or stock-client qualification.
func TestDormNativeOwnerRoundtripRollbackAndPreservation(t *testing.T) {
	dsn := os.Getenv("GXB_I7C2C_DSN")
	if dsn == "" {
		t.Skip("GXB_I7C2C_DSN required")
	}
	ctx := context.Background()
	pool, e := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "i7c2c-owner-working"})
	if e != nil {
		t.Fatal(e)
	}
	defer pool.Close()
	s := dormstore.Store{Queryer: pool}
	pid := identity.PlayerID(777309)
	ref := character.HeroRef{PlayerID: pid, PartnerID: 1}
	var now time.Time
	if e = pool.QueryRow(ctx, `SELECT clock_timestamp()`).Scan(&now); e != nil {
		t.Fatal(e)
	}
	defer func() {
		tr, e := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
		if e != nil {
			t.Error(e)
			return
		}
		defer tr.Rollback(ctx)
		for _, sql := range []string{`DELETE FROM player_dorm_heroes WHERE player_id=$1`, `DELETE FROM player_dorm_rooms WHERE player_id=$1`, `DELETE FROM player_dorm_roots WHERE player_id=$1`} {
			if _, e = tr.Exec(ctx, sql, int64(pid)); e != nil {
				t.Error(e)
				return
			}
		}
		if e = tr.Commit(ctx); e != nil {
			t.Error(e)
		}
	}()
	cat, e := builtin.Load()
	if e != nil {
		t.Fatal(e)
	}
	revision := cat.RevisionID()
	tr, e := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if e = s.EnsureRootTx(ctx, tr, pid, revision, now); e != nil {
		t.Fatal(e)
	}
	root, e := s.LockRootTx(ctx, tr, pid)
	if e != nil {
		t.Fatal(e)
	}
	lounge, e := s.ReadRoomTx(ctx, tr, pid, 1)
	if e != nil || lounge.TableID != dorm.LoungeTemplate || lounge.MainType != 1 {
		t.Fatal(lounge, e)
	}
	// Domain fixture is assembled from the actual qualified source payload. It is
	// sufficient for owner storage; it is not a replacement content-registry test.
	rule := cat.DormInputs.Rooms[1]
	var dresser builtin.DormFurnitureRule
	for _, f := range cat.DormInputs.Furniture {
		if f.ItemID == rule.Dresser {
			dresser = f
			break
		}
	}
	c := dorm.Catalog{Rooms: map[int64]dorm.RoomRule{rule.TableID: {TableID: rule.TableID, MainType: rule.MainType, Length: rule.Length, Width: rule.Width, Height: rule.Height, Dresser: rule.Dresser}}, Types: map[int64]dorm.TypeRule{2: {Residents: 1}}, Furniture: map[int64]dorm.FurnitureRule{dresser.ItemID: {ItemID: dresser.ItemID, Floor: dresser.Floor, Length: dresser.Length, Width: dresser.Width, Height: dresser.Height, Panels: dresser.Panels, CanRotate: dresser.CanRotate}}}
	rooms, e := s.ListRoomsTx(ctx, tr, pid)
	if e != nil {
		t.Fatal(e)
	}
	next, room, e := c.NewRoom(root, rooms, rule.TableID, 1, 1, revision, now)
	if e != nil {
		t.Fatal(e)
	}
	// Same floor/slot in Lounge and Normal must coexist (class-scoped identity).
	if e = s.InsertRoomTx(ctx, tr, room); e != nil {
		t.Fatal(e)
	}
	if e = s.SaveRootTx(ctx, tr, next, root.StateVersion); e != nil {
		t.Fatal(e)
	}
	if e = s.InitFreshHeroTx(ctx, tr, ref, now); e != nil {
		t.Fatal(e)
	}
	f, e := s.ReadHeroTx(ctx, tr, ref)
	if e != nil {
		t.Fatal(e)
	}
	f.HouseID = room.ID
	f.Equipment[2] = 1
	f.StateVersion++
	if e = s.SaveHeroTx(ctx, tr, f, 1); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	persisted, e := s.ReadHeroTx(ctx, pool, ref)
	if e != nil || persisted.HouseID != room.ID || persisted.Equipment[2] != 1 {
		t.Fatal(persisted, e)
	}
	rr, e := s.ReadRoomTx(ctx, pool, pid, room.ID)
	if e != nil || len(rr.Residents) != 1 || rr.Residents[0] != ref.PartnerID {
		t.Fatal(rr, e)
	}
	tr, e = pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	changed := persisted
	changed.HouseID = 0
	changed.StateVersion++
	if e = s.SaveHeroTx(ctx, tr, changed, persisted.StateVersion); e != nil {
		t.Fatal(e)
	}
	if e = tr.Rollback(ctx); e != nil {
		t.Fatal(e)
	}
	after, e := s.ReadHeroTx(ctx, pool, ref)
	if e != nil || after.HouseID != persisted.HouseID || after.StateVersion != persisted.StateVersion {
		t.Fatal("rollback changed membership", after, e)
	}
	tr, e = pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if e = s.EnsureRootTx(ctx, tr, pid, revision, now.Add(time.Hour)); e != nil {
		t.Fatal(e)
	}
	if e = s.EnsureHeroTx(ctx, tr, ref, now.Add(time.Hour)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	after, e = s.ReadHeroTx(ctx, pool, ref)
	if e != nil || after.Equipment != persisted.Equipment || after.HouseID != persisted.HouseID || after.StateVersion != persisted.StateVersion {
		t.Fatal("backfill overwrote explicit facts", after, e)
	}
	again, e := s.ReadRootTx(ctx, pool, pid)
	if e != nil || again.StateVersion != next.StateVersion || again.NextHouseID != next.NextHouseID {
		t.Fatal(again, e)
	}
}
