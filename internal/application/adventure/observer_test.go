package adventure

import (
	"context"
	"fmt"
	"testing"
	"time"

	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type occurrenceStore struct {
	active   map[int64]struct{}
	inserted []d.Occurrence
}

func (s *occurrenceStore) ActiveTypesTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (map[int64]struct{}, error) {
	return s.active, nil
}

func (s *occurrenceStore) InsertOccurrenceTx(_ context.Context, _ tx.Tx, occurrence d.Occurrence) (bool, error) {
	s.inserted = append(s.inserted, occurrence)
	s.active[occurrence.EventType] = struct{}{}
	return true, nil
}

func triggerOperation() operation.Context {
	var seed [32]byte
	for index := range seed {
		seed[index] = byte(index + 7)
	}
	return operation.Context{StartedAt: time.Unix(1700000000, 0).UTC(), EntropySeed: seed}
}

func triggeringFact(t *testing.T, op operation.Context, start int) objective.Fact {
	t.Helper()
	event, ok := d.EventForFactKind(objective.CampaignSweepKind)
	if !ok {
		t.Fatal("sweep kind has no event")
	}
	for index := start; index < start+10000; index++ {
		fact := objective.Fact{PlayerID: identity.PlayerID(7001), SourceDomain: "campaign", SourceBusinessKey: fmt.Sprintf("sweep-%d", index), Kind: objective.CampaignSweepKind, Delta: 1}
		key, err := fact.Key()
		if err != nil {
			t.Fatal(err)
		}
		ok, err := d.Roll(event, key, op)
		if err != nil {
			t.Fatal(err)
		}
		if ok {
			return fact
		}
	}
	t.Fatal("no triggering sweep fact found")
	return objective.Fact{}
}

type wakeCounter struct{ calls int }

func (w *wakeCounter) WakeAdventureNotice(context.Context, tx.Execer, identity.PlayerID) error {
	w.calls++
	return nil
}

const favorPartner int64 = 10001001

func triggeringIntimacyFact(t *testing.T, op operation.Context, start int) objective.Fact {
	t.Helper()
	event, ok := d.EventForFactKind(objective.IntimacyImprovedKind)
	if !ok || event.ID != d.EventFavor {
		t.Fatalf("intimacy fact has no Adventure 10002 event: %+v", event)
	}
	for index := start; index < start+10000; index++ {
		fact := objective.Fact{PlayerID: identity.PlayerID(7001), SourceDomain: "library", SourceBusinessKey: fmt.Sprintf("gift-%d", index), Kind: objective.IntimacyImprovedKind, Delta: 1, Value: favorPartner}
		key, err := fact.Key()
		if err != nil {
			t.Fatal(err)
		}
		hit, err := d.Roll(event, key, op)
		if err != nil {
			t.Fatal(err)
		}
		if hit {
			return fact
		}
	}
	t.Fatal("no triggering intimacy fact found")
	return objective.Fact{}
}

type favorReader struct {
	allowed bool
	reads   int
}

func (f *favorReader) FavorOccurrenceTx(context.Context, tx.Queryer, identity.PlayerID, int64) (bool, error) {
	f.reads++
	return f.allowed, nil
}

func TestObserverFavorFactWakesOncePerActiveOccurrence(t *testing.T) {
	op := triggerOperation()
	store := &occurrenceStore{active: map[int64]struct{}{}}
	wake := &wakeCounter{}
	favor := &favorReader{allowed: true}
	observer := Observer{Store: store, Wake: wake, Favor: favor}
	fact := triggeringIntimacyFact(t, op, 0)
	if err := observer.ObserveTx(context.Background(), nil, op, fact); err != nil {
		t.Fatal(err)
	}
	if len(store.inserted) != 1 || store.inserted[0].EventType != d.EventFavor || wake.calls != 1 {
		t.Fatalf("favor occurrence %+v wake %d", store.inserted, wake.calls)
	}
	if store.inserted[0].SpecialData != favorPartner {
		t.Fatalf("favor special_data %d want partner %d", store.inserted[0].SpecialData, favorPartner)
	}
	if err := observer.ObserveTx(context.Background(), nil, op, fact); err != nil {
		t.Fatal(err)
	}
	if len(store.inserted) != 1 || wake.calls != 1 {
		t.Fatalf("active favor occurrence repeated: %+v wake %d", store.inserted, wake.calls)
	}
	store.active = map[int64]struct{}{}
	if err := observer.ObserveTx(context.Background(), nil, op, triggeringIntimacyFact(t, op, 20000)); err != nil {
		t.Fatal(err)
	}
	if len(store.inserted) != 2 || wake.calls != 2 {
		t.Fatalf("expired favor occurrence did not trigger: %+v wake %d", store.inserted, wake.calls)
	}
}

// C4: no occurrence at the Library favor limit, and no occurrence for a fact
// that carries no partner id.
func TestObserverFavorFactRequiresOwnedPartnerBelowLimit(t *testing.T) {
	op := triggerOperation()
	store := &occurrenceStore{active: map[int64]struct{}{}}
	favor := &favorReader{allowed: false}
	observer := Observer{Store: store, Favor: favor}
	if err := observer.ObserveTx(context.Background(), nil, op, triggeringIntimacyFact(t, op, 0)); err != nil {
		t.Fatal(err)
	}
	if len(store.inserted) != 0 || favor.reads != 1 {
		t.Fatalf("at-limit favor inserted %+v reads %d", store.inserted, favor.reads)
	}
	noPartner := triggeringIntimacyFact(t, op, 0)
	noPartner.Value = 0
	if err := observer.ObserveTx(context.Background(), nil, op, noPartner); err != nil {
		t.Fatal(err)
	}
	if len(store.inserted) != 0 || favor.reads != 1 {
		t.Fatalf("partnerless favor inserted %+v reads %d", store.inserted, favor.reads)
	}
}

func TestObserverInsertsOneActiveOccurrencePerType(t *testing.T) {
	op := triggerOperation()
	store := &occurrenceStore{active: map[int64]struct{}{}}
	observer := Observer{Store: store}
	fact := triggeringFact(t, op, 0)
	if err := observer.ObserveTx(context.Background(), nil, op, fact); err != nil {
		t.Fatal(err)
	}
	if len(store.inserted) != 1 || store.inserted[0].EventType != d.EventDefense {
		t.Fatalf("inserted %+v", store.inserted)
	}
	if store.inserted[0].EndTime.Sub(store.inserted[0].OccurredAt) != 10800*time.Second {
		t.Fatalf("lifetime %s", store.inserted[0].EndTime.Sub(store.inserted[0].OccurredAt))
	}
	if err := observer.ObserveTx(context.Background(), nil, op, fact); err != nil {
		t.Fatal(err)
	}
	if len(store.inserted) != 1 {
		t.Fatal("one active occurrence per type must refuse the second insert")
	}
	store.active = map[int64]struct{}{}
	if err := observer.ObserveTx(context.Background(), nil, op, triggeringFact(t, op, 20000)); err != nil {
		t.Fatal(err)
	}
	if len(store.inserted) != 2 {
		t.Fatal("an expired type must be able to trigger again")
	}
}
