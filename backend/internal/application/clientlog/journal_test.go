package clientlog

import (
	"context"
	"net/http"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/observability"
)

type recordingJournalStore struct {
	rows []JournalRow
}

func (store *recordingJournalStore) SaveGrant(context.Context, Grant) error { return nil }

func (store *recordingJournalStore) Grant(context.Context, [32]byte) (Grant, bool, error) {
	return Grant{}, false, nil
}

func (store *recordingJournalStore) SaveUpload(context.Context, Upload) error { return nil }

func (store *recordingJournalStore) SaveJournal(_ context.Context, rows []JournalRow) error {
	store.rows = append(store.rows, rows...)
	return nil
}

func (store *recordingJournalStore) PurgeExpired(context.Context, time.Time, int, int) (int64, error) {
	return 0, nil
}

func TestJournalFlushWritesQueuedRows(t *testing.T) {
	store := &recordingJournalStore{}
	journal := NewJournal(store, observability.NopMetrics{})
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan struct{})
	go func() {
		journal.Run(ctx)
		close(done)
	}()
	journal.Record(observability.RequestRecord{ReceivedAt: time.Now(), HTTPStatus: http.StatusOK})
	journal.Flush(ctx)
	if len(store.rows) != 1 {
		t.Fatalf("flushed rows = %d", len(store.rows))
	}
	cancel()
	<-done
}

func TestJournalRowCarriesTheReplayFlag(t *testing.T) {
	row := journalRow(observability.RequestRecord{HTTPStatus: http.StatusOK, Replay: true})
	if !row.Replay {
		t.Fatal("replay flag was dropped from the journal row")
	}
	if plain := journalRow(observability.RequestRecord{HTTPStatus: http.StatusOK}); plain.Replay {
		t.Fatal("an ordinary dispatch was marked as a replay")
	}
}
