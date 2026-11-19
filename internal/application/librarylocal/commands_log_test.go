package librarylocal

import (
	"context"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type dialogueCountLibrary struct {
	LibraryPort
	count        int64
	logs         []int64
	rejectLogRow bool
}

func (l *dialogueCountLibrary) BumpHeroDialogueCountTx(context.Context, tx.Tx, identity.PlayerID, int64) (int64, error) {
	previous := l.count
	l.count++
	return previous, nil
}

func (l *dialogueCountLibrary) InsertHeroLogTx(_ context.Context, _ tx.Tx, f library.HeroLogFact) (bool, error) {
	if l.rejectLogRow {
		return false, library.ErrInvalidFacts
	}
	l.logs = append(l.logs, f.LogID)
	return true, nil
}

type dropCounter map[string]uint64

func (c dropCounter) Counter(name string, _ observability.Labels, delta uint64) { c[name] += delta }
func (dropCounter) Observe(string, observability.Labels, time.Duration)         {}

// A-168 S16: the counter, not the distinct dialog rows, drives the type-7
// milestones, so 19 distinct completions and 11 repeats reach 70003.
func TestDialogueCompletionCountsRepeatsToThirty(t *testing.T) {
	owner := &dialogueCountLibrary{count: 19}
	service := Service{Library: owner, Metrics: dropCounter{}}
	for repeat := 0; repeat < 11; repeat++ {
		if err := service.recordDialogueCompletionTx(context.Background(), nil, 7, 3, time.Now()); err != nil {
			t.Fatalf("repeat %d: %v", repeat, err)
		}
	}
	if owner.count != 30 {
		t.Fatalf("count=%d want 30", owner.count)
	}
	if !reflect.DeepEqual(owner.logs, []int64{70003}) {
		t.Fatalf("logs=%v want [70003]", owner.logs)
	}
}

// A-168 S16: the fiftieth completion reaches 70004 once.
func TestDialogueCompletionFiftiethWritesMilestoneOnce(t *testing.T) {
	owner := &dialogueCountLibrary{count: 49}
	service := Service{Library: owner, Metrics: dropCounter{}}
	if err := service.recordDialogueCompletionTx(context.Background(), nil, 7, 3, time.Now()); err != nil {
		t.Fatal(err)
	}
	if err := service.recordDialogueCompletionTx(context.Background(), nil, 7, 3, time.Now()); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(owner.logs, []int64{70004}) {
		t.Fatalf("logs=%v want [70004]", owner.logs)
	}
}

// A-023 (D1): an invalid milestone row is dropped and counted, not fatal to
// the completed talk or its counter.
func TestDialogueCompletionDropsInvalidRowAndKeepsCount(t *testing.T) {
	counter := dropCounter{}
	owner := &dialogueCountLibrary{rejectLogRow: true}
	service := Service{Library: owner, Metrics: counter}
	if err := service.recordDialogueCompletionTx(context.Background(), nil, 7, 3, time.Now()); err != nil {
		t.Fatalf("invalid diary row failed the talk: %v", err)
	}
	if owner.count != 1 {
		t.Fatalf("count=%d want 1", owner.count)
	}
	if counter["girls_log_dropped"] != 1 {
		t.Fatalf("dropped counter=%d want 1", counter["girls_log_dropped"])
	}
}
