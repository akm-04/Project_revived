package compat

import (
	"context"
	"errors"
	"slices"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/playerroot"
	d "gxb.local/backend/v2/internal/domain/compat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fakeTag struct{}

func (fakeTag) RowsAffected() int64 { return 1 }

type fakeTx struct{}

func (fakeTx) QueryRow(context.Context, string, ...any) tx.Row { return nil }
func (fakeTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return fakeTag{}, nil
}
func (fakeTx) Commit(context.Context) error   { return nil }
func (fakeTx) Rollback(context.Context) error { return nil }

type fakeDatabase struct {
	transaction *fakeTx
	begins      int
}

func (f *fakeDatabase) Begin(context.Context, tx.Options) (tx.Tx, error) {
	f.begins++
	return f.transaction, nil
}

type fakeStore struct {
	preferences d.Preferences
	found       bool
	saved       int
	expected    int64
}

func (f *fakeStore) ReadTx(context.Context, tx.Queryer, identity.PlayerID) (d.Preferences, bool, error) {
	return f.preferences, f.found, nil
}

func (f *fakeStore) LockTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (d.Preferences, error) {
	return f.preferences, nil
}

func (f *fakeStore) SaveTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, preferences d.Preferences, expected int64, _ time.Time) error {
	f.saved++
	f.expected = expected
	f.preferences = preferences
	return nil
}

type fakeContent struct {
	revision string
	catalog  d.Catalog
	err      error
}

func (f fakeContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return f.revision, f.err
}

func (f fakeContent) MessagePushCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return f.catalog, f.err
}

type fakePlayers struct{}

func (fakePlayers) LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error) {
	return nil, nil
}

type fakeFence struct{}

func (fakeFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

func compatService(database *fakeDatabase, store *fakeStore) Service {
	return Service{
		Runner:  tx.Runner{DB: database},
		Fresh:   database.transaction,
		Store:   store,
		Content: fakeContent{revision: "revision", catalog: d.Catalog{MessagePushIDs: map[int64]struct{}{1: {}, 9: {}}}},
		Players: fakePlayers{},
		Fence:   fakeFence{},
	}
}

func compatActor() identity.ActorContext {
	return identity.ActorContext{LogicalServerID: 1, PlayerID: 100001}
}

func compatOperation(t *testing.T) operation.Context {
	t.Helper()
	at := time.Unix(1000, 0).UTC()
	return operation.Context{StartedAt: at}
}

func TestSetMessagePushAddsAndRemovesIdempotently(t *testing.T) {
	database := &fakeDatabase{transaction: &fakeTx{}}
	store := &fakeStore{preferences: d.Preferences{StateVersion: 3}}
	service := compatService(database, store)
	op := compatOperation(t)
	if err := service.SetMessagePush(context.Background(), compatActor(), 1, true, op); err != nil {
		t.Fatal(err)
	}
	if store.saved != 1 || store.expected != 3 || !slices.Equal(store.preferences.MessagePushIDs, []int64{1}) || store.preferences.StateVersion != 4 {
		t.Fatalf("add stored %+v saved=%d expected=%d", store.preferences, store.saved, store.expected)
	}
	if err := service.SetMessagePush(context.Background(), compatActor(), 1, true, op); err != nil {
		t.Fatal(err)
	}
	if store.saved != 1 {
		t.Fatalf("repeat add wrote %d times", store.saved)
	}
	if err := service.SetMessagePush(context.Background(), compatActor(), 1, false, op); err != nil {
		t.Fatal(err)
	}
	if store.saved != 2 || len(store.preferences.MessagePushIDs) != 0 {
		t.Fatalf("remove stored %+v saved=%d", store.preferences, store.saved)
	}
}

func TestSetMessagePushRejectsAnIdOutsideTheCatalog(t *testing.T) {
	database := &fakeDatabase{transaction: &fakeTx{}}
	store := &fakeStore{}
	service := compatService(database, store)
	for _, messageType := range []int64{0, -1, 2} {
		if err := service.SetMessagePush(context.Background(), compatActor(), messageType, true, compatOperation(t)); !errors.Is(err, d.ErrInvalidMessageType) {
			t.Fatalf("message_type %d = %v, want ErrInvalidMessageType", messageType, err)
		}
	}
	if database.begins != 0 || store.saved != 0 {
		t.Fatalf("invalid type opened %d transactions and saved %d", database.begins, store.saved)
	}
}

func TestFirstMainTouchWritesOnce(t *testing.T) {
	database := &fakeDatabase{transaction: &fakeTx{}}
	store := &fakeStore{preferences: d.Preferences{StateVersion: 1}}
	service := compatService(database, store)
	if err := service.FirstMainTouch(context.Background(), compatActor(), compatOperation(t)); err != nil {
		t.Fatal(err)
	}
	if store.saved != 1 || store.preferences.FirstMainTouch != 1 {
		t.Fatalf("first touch saved %d prefs %+v", store.saved, store.preferences)
	}
	if err := service.FirstMainTouch(context.Background(), compatActor(), compatOperation(t)); err != nil {
		t.Fatal(err)
	}
	if store.saved != 1 {
		t.Fatalf("repeat first touch wrote %d times", store.saved)
	}
}

func TestServiceWithoutWiringIsUnavailable(t *testing.T) {
	service := Service{}
	if err := service.FirstMainTouch(context.Background(), compatActor(), compatOperation(t)); !errors.Is(err, d.ErrUnavailable) {
		t.Fatalf("unwired service = %v", err)
	}
}
