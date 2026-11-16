package bookskill

import (
	"context"
	"testing"
	"time"

	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type a44MakeInfo struct{}

func (a44MakeInfo) MakeInfoTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (map[string]any, map[string]any, error) {
	return map[string]any{"is_making": int64(0)}, map[string]any{"is_making": int64(0)}, nil
}

func readSnapshotService(t *testing.T) (*Service, *a44Owner, time.Time) {
	t.Helper()
	service, owner, _, at := a44Service(a44Catalog(true))
	service.MakeInfo = a44MakeInfo{}
	service.Values = a44Values{}
	return service, owner, at
}

func TestBookReadSnapshotAnswersIdleWithoutWriting(t *testing.T) {
	service, owner, at := readSnapshotService(t)
	body, due, err := service.readSnapshot(context.Background(), a44Queryer{}, 1, 1056, a44Revision, at)
	if err != nil {
		t.Fatal(err)
	}
	if due || body == nil {
		t.Fatalf("idle snapshot due=%v body=%#v", due, body)
	}
	if _, ok := body["building_list"]; !ok {
		t.Fatalf("idle snapshot lost the building list: %#v", body)
	}
	if owner.writes != 0 {
		t.Fatalf("idle snapshot wrote the owner %d times", owner.writes)
	}
}

func TestBookReadSnapshotSettlesCloneOnly(t *testing.T) {
	service, owner, at := readSnapshotService(t)
	owner.root.Facts.Buildings[1] = book.Building{Level: 1, Job: &book.Job{Occurrence: "a44", Revision: a44Revision, StartedAt: at.Add(-time.Hour), Duration: 60, Target: 2, Subject: 1}}
	body, due, err := service.readSnapshot(context.Background(), a44Queryer{}, 1, 1056, a44Revision, at)
	if err != nil {
		t.Fatal(err)
	}
	if !due || body != nil {
		t.Fatalf("due snapshot due=%v body=%#v", due, body)
	}
	if owner.writes != 0 {
		t.Fatalf("due snapshot wrote the owner %d times", owner.writes)
	}
	stored := owner.root.Facts.Buildings[1]
	if stored.Level != 1 || stored.Job == nil {
		t.Fatalf("due snapshot persisted the settle: %+v", stored)
	}
}
