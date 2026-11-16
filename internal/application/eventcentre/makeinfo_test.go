package eventcentre

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	ec "gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type makeInfoOwner struct {
	root   ec.Root
	exists bool
	reads  int
}

func (o *makeInfoOwner) ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (ec.Root, bool, error) {
	o.reads++
	return o.root, o.exists, nil
}
func (*makeInfoOwner) LockRootTx(context.Context, tx.Tx, identity.PlayerID) (ec.Root, bool, error) {
	return ec.Root{}, false, errors.New("makeinfo fixture does not lock")
}
func (*makeInfoOwner) EnsureRootTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time) error {
	return errors.New("makeinfo fixture does not ensure")
}
func (*makeInfoOwner) SaveRootTx(context.Context, tx.Tx, ec.Root, int64) error {
	return errors.New("makeinfo fixture never saves")
}
func (*makeInfoOwner) InsertBoardReportTx(context.Context, tx.Tx, identity.PlayerID, int64, string, time.Time) error {
	return errors.New("makeinfo fixture does not insert reports")
}
func (*makeInfoOwner) ReadBoardReportTx(context.Context, tx.Queryer, identity.PlayerID, int64) (string, bool, error) {
	return "", false, errors.New("makeinfo fixture does not read reports")
}
func (*makeInfoOwner) DeleteBoardReportsExceptTx(context.Context, tx.Tx, identity.PlayerID, []int64) error {
	return errors.New("makeinfo fixture does not delete reports")
}

func makeInfoRoot(at time.Time) ec.Root {
	facts := Seed()
	return ec.Root{Player: 1, Version: 1, Revision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", Facts: facts, CreatedAt: at.Add(-time.Hour), UpdatedAt: at.Add(-time.Hour)}
}

func makeInfoJob(itemID, duration int64, startedAt time.Time) *ec.MakeJob {
	return &ec.MakeJob{Occurrence: "makeinfo", ItemID: itemID, StartedAt: startedAt, Duration: duration, Cost: []ec.ResourceAmount{{ID: 13, Amount: 2}}}
}

func idleDeskWire() map[string]any {
	return map[string]any{"is_making": int64(0), "make_need_time": int64(0), "make_start_time": int64(0), "make_item": int64(0)}
}

func idlePetWire() map[string]any {
	return map[string]any{"is_making": int64(0), "make_need_time": int64(0), "make_start_time": int64(0), "make_item": int64(0), "pet_id": int64(0)}
}

func TestMakeInfoTxMissingRootReturnsIdleWire(t *testing.T) {
	owner := &makeInfoOwner{}
	desk, pet, err := Service{Owner: owner}.MakeInfoTx(context.Background(), nil, 1, time.Now().UTC())
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(desk, idleDeskWire()) {
		t.Fatalf("desk idle wire = %#v", desk)
	}
	if !reflect.DeepEqual(pet, idlePetWire()) {
		t.Fatalf("pet idle wire = %#v", pet)
	}
}

func TestMakeInfoTxDeskJobInProgress(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	owner := &makeInfoOwner{exists: true, root: makeInfoRoot(at)}
	startedAt := at.Add(-100 * time.Second)
	owner.root.Facts.Desk.Job = makeInfoJob(130001001, 3600, startedAt)
	desk, pet, err := Service{Owner: owner}.MakeInfoTx(context.Background(), nil, 1, at)
	if err != nil {
		t.Fatal(err)
	}
	want := map[string]any{"is_making": int64(1), "make_item": int64(0), "making_item": int64(130001001), "make_need_time": int64(3600), "make_start_time": startedAt.Unix()}
	if !reflect.DeepEqual(desk, want) {
		t.Fatalf("desk in-progress wire = %#v", desk)
	}
	if !reflect.DeepEqual(pet, map[string]any{"is_making": int64(0), "make_item": int64(0), "making_item": int64(0), "make_need_time": int64(0), "make_start_time": int64(0), "pet_id": int64(0)}) {
		t.Fatalf("pet idle wire = %#v", pet)
	}
	if owner.root.Facts.Desk.Job == nil {
		t.Fatal("MakeInfoTx saved the settled clone")
	}
}

func TestMakeInfoTxFinishedMakeShowsPendingItemOnTheCloneOnly(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	owner := &makeInfoOwner{exists: true, root: makeInfoRoot(at)}
	owner.root.Facts.Desk.Job = makeInfoJob(130001001, 3600, at.Add(-4000*time.Second))
	desk, _, err := Service{Owner: owner}.MakeInfoTx(context.Background(), nil, 1, at)
	if err != nil {
		t.Fatal(err)
	}
	want := map[string]any{"is_making": int64(0), "make_item": int64(130001001), "making_item": int64(0), "make_need_time": int64(0), "make_start_time": int64(0)}
	if !reflect.DeepEqual(desk, want) {
		t.Fatalf("desk finished wire = %#v", desk)
	}
	if owner.root.Facts.Desk.Job == nil || owner.root.Facts.Desk.PendingItem != 0 {
		t.Fatal("MakeInfoTx saved the settled clone")
	}
}

func TestMakeInfoTxPetJobCarriesPetID(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	owner := &makeInfoOwner{exists: true, root: makeInfoRoot(at)}
	startedAt := at.Add(-30 * time.Second)
	job := makeInfoJob(2210001, 600, startedAt)
	job.PetID = 7
	owner.root.Facts.Pet.Job = job
	owner.root.Facts.Pet.PetID = 7
	desk, pet, err := Service{Owner: owner}.MakeInfoTx(context.Background(), nil, 1, at)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(desk, map[string]any{"is_making": int64(0), "make_item": int64(0), "making_item": int64(0), "make_need_time": int64(0), "make_start_time": int64(0)}) {
		t.Fatalf("desk idle wire = %#v", desk)
	}
	want := map[string]any{"is_making": int64(1), "make_item": int64(0), "making_item": int64(2210001), "make_need_time": int64(600), "make_start_time": startedAt.Unix(), "pet_id": int64(7)}
	if !reflect.DeepEqual(pet, want) {
		t.Fatalf("pet in-progress wire = %#v", pet)
	}
}

func TestMakeInfoTxRejectsStaleObservationTime(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	owner := &makeInfoOwner{exists: true, root: makeInfoRoot(at)}
	owner.root.Facts.Desk.Job = makeInfoJob(130001001, 3600, at.Add(time.Minute))
	if _, _, err := (Service{Owner: owner}).MakeInfoTx(context.Background(), nil, 1, at); !errors.Is(err, ec.ErrStaleTime) {
		t.Fatalf("stale observation = %v", err)
	}
}
