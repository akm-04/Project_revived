//go:build postgres

package missions_test

import (
	"context"
	"errors"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	ps "gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	cp "gxb.local/backend/v2/internal/application/commerceprivilege"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func chargeForMissions(p *pg.Pool, service i5.Service) cp.Charge {
	return cp.Charge{
		Timed:       gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}},
		Fresh:       p,
		Fence:       i5store.Store{Queryer: p},
		Facts:       i5.ObjectiveFacts{Owner: service, Open: i5store.Store{Queryer: p}},
		Store:       ps.Store{},
		Content:     contentstore.Store{Queryer: p},
		Grants:      service,
		Effects:     i5.PrivilegeTransitionOwner{Store: i5store.Store{}, Content: contentstore.Store{Queryer: p}},
		Directory:   i4store.DirectoryLevelProjection{},
		Receipts:    kernelstore.Store{},
		ReceiptRead: kernelstore.Reader{Queryer: p},
	}
}

func missionChargeTap(t *testing.T, p *pg.Pool, charge cp.Charge, a identity.ActorContext, chargeID int64) {
	t.Helper()
	if _, err := charge.Tap(context.Background(), a, cp.TapRequest{ChargeID: chargeID, IntentID: "i910g-mission-" + time.Now().UTC().Format("150405.000000000")}, runtimeOperation(t, time.Now().UTC())); err != nil {
		t.Fatal("mission charge tap", chargeID, err)
	}
}

func TestI910GMonthAndPrivilegeCardMissionClaims(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	stamp, err := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	a := runtimeActor(t, p, stamp.Add(-time.Minute))
	if _, err = p.Raw().Exec(ctx, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',1000,1,clock_timestamp()-interval '1 day') ON CONFLICT(player_id,resource_key)DO UPDATE SET amount=excluded.amount,updated_at=excluded.updated_at`, int64(a.PlayerID)); err != nil {
		t.Fatal(err)
	}
	ticker := &missionClock{at: stamp}
	service := runtimeService(p, ticker)
	charge := chargeForMissions(p, service)
	claim := func(id int64) error {
		at, clockErr := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
		if clockErr != nil {
			return clockErr
		}
		ticker.at = at
		_, claimErr := service.ClaimMission(ctx, a, id, "", runtimeOperation(t, at))
		return claimErr
	}
	if err = claim(10010); !errors.Is(err, i5.ErrMissionRefused) {
		t.Fatalf("month card gate without card: %v", err)
	}
	missionChargeTap(t, p, charge, a, 80001010)
	if err = claim(10010); !errors.Is(err, i5.ErrMissionRefused) {
		t.Fatalf("month card gate with privilege card only: %v", err)
	}
	if err = claim(10036); err != nil {
		t.Fatalf("privilege card claim: %v", err)
	}
	var quantity int64
	if err = p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=50001013`, int64(a.PlayerID)).Scan(&quantity); err != nil || quantity != 40 {
		t.Fatalf("privilege sweep tickets: %d %v", quantity, err)
	}
	missionChargeTap(t, p, charge, a, 80001001)
	before := crystalTotal(t, p, a)
	if err = claim(10010); err != nil {
		t.Fatalf("month card claim: %v", err)
	}
	if got := crystalTotal(t, p, a); got != before+120 {
		t.Fatalf("month card reward: %d -> %d", before, got)
	}
	root, err := service.Missions.Store.ReadMissionRootTx(ctx, p, a.PlayerID)
	if err != nil || root.DayHuoyue != 20 {
		t.Fatalf("month card medal: %+v %v", root, err)
	}
}

func crystalTotal(t *testing.T, p *pg.Pool, a identity.ActorContext) int64 {
	t.Helper()
	var amount int64
	if err := p.QueryRow(context.Background(), `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&amount); err != nil {
		t.Fatal(err)
	}
	return amount
}
