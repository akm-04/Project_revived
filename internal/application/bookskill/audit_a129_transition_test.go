package bookskill

import (
	"context"
	"testing"
	"time"

	i5 "gxb.local/backend/v2/internal/application/i5"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type a129Costs struct{}

func (a129Costs) PrepareMaterialDebitTx(context.Context, tx.Tx, identity.PlayerID, i5.MaterialCost, operation.Context) (*i5.PreparedMaterialDebit, error) {
	return &i5.PreparedMaterialDebit{}, nil
}
func (a129Costs) ApplyMaterialDebitTx(context.Context, tx.Tx, *i5.PreparedMaterialDebit) (i5.MaterialDebitResult, error) {
	return i5.MaterialDebitResult{}, nil
}

type a129Recycle struct {
	snapshot map[string]any
	reads    int
}

func (r *a129Recycle) RecycleInfoTx(context.Context, tx.Queryer, identity.PlayerID, string, time.Time) (map[string]any, error) {
	r.reads++
	return r.snapshot, nil
}

func a129SpeedService() (*Service, *a44Owner, time.Time) {
	service, owner, _, at := a44Service(a44Catalog(true))
	service.Values = a44Values{}
	service.Costs = a129Costs{}
	owner.root.Facts.Buildings[3] = book.Building{Level: 1, Job: &book.Job{Occurrence: "a129", Revision: a44Revision, StartedAt: at, Duration: 60, Target: 2, Subject: 3}}
	return service, owner, at
}

func a129Speed(t *testing.T, service *Service, at time.Time) map[string]any {
	t.Helper()
	body, e := service.apply(context.Background(), nil, identity.ActorContext{PlayerID: 1}, Admission{DecisionAt: at, Actor: DurableActor{Player: 1}, Command: Command{Family: Speed, Type: 3}, ContentRevision: a44Revision})
	if e != nil {
		t.Fatal(e)
	}
	return body
}

// The stock RecycleWindow callback indexes reply.trash_info.energy and
// .energy_time after a type-3 speed-up; without them the paid success crashes
// the window while the upgrade itself already committed.
func TestA129RecycleSpeedCarriesTrashInfo(t *testing.T) {
	service, _, at := a129SpeedService()
	service.RecycleInfo = &a129Recycle{snapshot: map[string]any{"energy": int64(4321), "energy_time": int64(1234)}}
	body := a129Speed(t, service, at)
	if body["lev"] != int64(2) || body["type"] != int64(3) {
		t.Fatalf("building fields = %#v", body)
	}
	trash, ok := body["trash_info"].(map[string]any)
	if !ok {
		t.Fatalf("type-3 speed success lacks trash_info: %#v", body)
	}
	if trash["energy"] != int64(4321) || trash["energy_time"] != int64(1234) {
		t.Fatalf("trash_info = %#v", trash)
	}
}

func TestA129RecycleSnapshotComesFromTheProjectionAfterTheLevelChange(t *testing.T) {
	service, owner, at := a129SpeedService()
	recycle := &a129Recycle{snapshot: map[string]any{"energy": int64(4321), "energy_time": int64(1234)}}
	service.RecycleInfo = recycle
	body := a129Speed(t, service, at)
	if recycle.reads != 1 {
		t.Fatalf("projection reads = %d", recycle.reads)
	}
	if body["trash_info"] == nil {
		t.Fatalf("projection result absent: %#v", body)
	}
	if owner.root.Facts.Buildings[3].Level != 2 {
		t.Fatalf("speed did not apply the level: %#v", owner.root.Facts.Buildings[3])
	}
}

// REPLY_CONFORMANCE_V1 R3 checks MID 1077 unconditionally, so every building
// speed-up carries the projection; a Start is a different family and does not.
func TestA129EverySpeedSuccessCarriesTheSnapshotButStartDoesNot(t *testing.T) {
	service, owner, at := a129SpeedService()
	recycle := &a129Recycle{snapshot: map[string]any{"energy": int64(1), "energy_time": int64(2)}}
	service.RecycleInfo = recycle
	owner.root.Facts.Buildings[4] = book.Building{Level: 1, Job: &book.Job{Occurrence: "a129-shelf", Revision: a44Revision, StartedAt: at, Duration: 60, Target: 2, Subject: 4}}
	body, e := service.apply(context.Background(), nil, identity.ActorContext{PlayerID: 1}, Admission{DecisionAt: at, Actor: DurableActor{Player: 1}, Command: Command{Family: Speed, Type: 4}, ContentRevision: a44Revision})
	if e != nil {
		t.Fatal(e)
	}
	if _, present := body["trash_info"]; !present || recycle.reads != 1 {
		t.Fatalf("non-recycle speed lacks the required snapshot: %#v reads=%d", body, recycle.reads)
	}
	start, e := service.apply(context.Background(), nil, identity.ActorContext{PlayerID: 1}, Admission{DecisionAt: at, Actor: DurableActor{Player: 1}, Command: Command{Family: Start, Type: 1}, ContentRevision: a44Revision})
	if e != nil {
		t.Fatal(e)
	}
	if _, present := start["trash_info"]; present || recycle.reads != 1 {
		t.Fatalf("start grew the speed projection: %#v reads=%d", start, recycle.reads)
	}
}
