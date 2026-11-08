//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/gmquestionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/generation"
	questions "gxb.local/backend/v2/internal/application/gmquestion"
	domain "gxb.local/backend/v2/internal/domain/gmquestion"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func questionService(database *pg.Pool) questions.Service {
	return questions.Service{Timed: generation.TimedRunner{Binder: generation.Binder{Time: pg.AuthoritativeTime{Queryer: database}}, Runner: tx.Runner{DB: database}}, Fence: i5store.Store{Queryer: database}, Players: i4store.PlayerRootLocker{}, Owner: gmquestionstore.Store{}, Directory: i4store.TransactionDiscoveryReader{}, Receipts: kernelstore.Store{}, ReceiptReader: kernelstore.Reader{Queryer: database}}
}
func questionCount(t *testing.T, database *pg.Pool, player identity.PlayerID) int {
	t.Helper()
	var count int
	if err := database.QueryRow(ctx, "SELECT count(*) FROM player_gm_questions WHERE player_id=$1", int64(player)).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}
func TestGMQuestionAtomicReplayPrivacyAndReceiptRollback(t *testing.T) {
	database := pool(t)
	player := actor(t, database)
	other := actor(t, database)
	service := questionService(database)
	current := op()
	message := "  Need help 世界  "
	if _, err := service.Ask(ctx, player, message, current); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Ask(ctx, player, message, current); err != nil {
		t.Fatal("replay", err)
	}
	if questionCount(t, database, player.PlayerID) != 1 {
		t.Fatal("replay duplicated question")
	}
	if _, err := service.Ask(ctx, player, "different", current); err == nil {
		t.Fatal("conflicting replay accepted")
	} else {
		var conflict *receipt.ConflictError
		if !errors.As(err, &conflict) {
			t.Fatal(err)
		}
	}
	rows, err := service.List(ctx, player, op())
	if err != nil || len(rows) != 1 || rows[0].Question.Message != message || rows[0].Profile.PlayerID != player.PlayerID {
		t.Fatal(rows, err)
	}
	private, err := service.List(ctx, other, op())
	if err != nil || len(private) != 0 {
		t.Fatal("foreign question leaked", private, err)
	}
	service.Receipts = rejectedExchangeReceipt{}
	if _, err := service.Ask(ctx, player, "must rollback", op()); !errors.Is(err, receiptFailure) {
		t.Fatal(err)
	}
	if questionCount(t, database, player.PlayerID) != 1 {
		t.Fatal("receipt failure left question")
	}
}
func TestGMQuestionConcurrentSameAndDistinctOperations(t *testing.T) {
	database := pool(t)
	player := actor(t, database)
	service := questionService(database)
	current := op()
	failures := make(chan error, 2)
	var group sync.WaitGroup
	for index := 0; index < 2; index++ {
		group.Add(1)
		go func() { defer group.Done(); _, err := service.Ask(ctx, player, "same", current); failures <- err }()
	}
	group.Wait()
	close(failures)
	for err := range failures {
		if err != nil {
			t.Fatal(err)
		}
	}
	if questionCount(t, database, player.PlayerID) != 1 {
		t.Fatal("concurrent replay duplicated")
	}
	failures = make(chan error, 2)
	for index := 0; index < 2; index++ {
		group.Add(1)
		go func(index int) {
			defer group.Done()
			_, err := service.Ask(ctx, player, fmt.Sprint("distinct ", index), op())
			failures <- err
		}(index)
	}
	group.Wait()
	close(failures)
	for err := range failures {
		if err != nil {
			t.Fatal(err)
		}
	}
	if questionCount(t, database, player.PlayerID) != 3 {
		t.Fatal("distinct operation lost")
	}
}
func TestGMQuestionUnknownCommitUsesFreshReceipt(t *testing.T) {
	database := pool(t)
	for _, committed := range []bool{true, false} {
		player := actor(t, database)
		service := questionService(database)
		fault := &exchangeCommitDatabase{Beginner: database, commit: committed}
		service.Timed.Runner.DB = fault
		_, err := service.Ask(ctx, player, "ambiguous acknowledgement", op())
		if committed && err != nil {
			t.Fatal("committed receipt not recovered", err)
		}
		if !committed {
			var unknown *tx.UnknownCommitError
			if !errors.As(err, &unknown) {
				t.Fatal("absence treated as abort", err)
			}
		}
		expected := 0
		if committed {
			expected = 1
		}
		if questionCount(t, database, player.PlayerID) != expected || fault.begins != 1 {
			t.Fatal("ambiguous operation replayed or compensated", expected, fault.begins)
		}
	}
}
func TestGMQuestionHistoryBoundDoesNotPruneFacts(t *testing.T) {
	database := pool(t)
	player := actor(t, database)
	service := questionService(database)
	for index := 0; index < 105; index++ {
		if _, err := service.Ask(ctx, player, fmt.Sprint("question ", index), op()); err != nil {
			t.Fatal(err)
		}
	}
	rows, err := service.List(ctx, player, op())
	if err != nil || len(rows) != 100 || rows[0].Question.Message != "question 5" || rows[99].Question.Message != "question 104" {
		t.Fatal("history order/bound", len(rows), err)
	}
	if questionCount(t, database, player.PlayerID) != 105 {
		t.Fatal("history read pruned durable facts")
	}
	for index := 1; index < len(rows); index++ {
		if rows[index].Question.AskedAt.Before(rows[index-1].Question.AskedAt) {
			t.Fatal("history reversed")
		}
	}
}

type heldQuestionInsert struct {
	gmquestionstore.Store
	entered chan int32
	release chan struct{}
	once    sync.Once
}

func (owner *heldQuestionInsert) InsertQuestionTx(ctx context.Context, transaction tx.Tx, question domain.Question) error {
	var pauseError error
	owner.once.Do(func() {
		var identifier int32
		if err := transaction.QueryRow(ctx, "SELECT pg_backend_pid()").Scan(&identifier); err != nil {
			pauseError = err
			return
		}
		owner.entered <- identifier
		select {
		case <-owner.release:
		case <-ctx.Done():
			pauseError = ctx.Err()
		}
	})
	if pauseError != nil {
		return pauseError
	}
	return owner.Store.InsertQuestionTx(ctx, transaction, question)
}

func TestGMQuestionForcedOverlapDifferentMessagesConflicts(t *testing.T) {
	database := pool(t)
	player := actor(t, database)
	first := questionService(database)
	second := questionService(database)
	owner := &heldQuestionInsert{entered: make(chan int32, 1), release: make(chan struct{})}
	first.Owner = owner
	var release sync.Once
	unblock := func() { release.Do(func() { close(owner.release) }) }
	defer unblock()
	current := op()
	firstResult := make(chan error, 1)
	secondResult := make(chan error, 1)
	go func() { _, err := first.Ask(ctx, player, "first winner", current); firstResult <- err }()
	var holder int32
	select {
	case holder = <-owner.entered:
	case err := <-firstResult:
		t.Fatal("first insert did not reach barrier", err)
	case <-time.After(3 * time.Second):
		t.Fatal("insert barrier timeout")
	}
	go func() { _, err := second.Ask(ctx, player, "different same operation", current); secondResult <- err }()
	deadline := time.NewTimer(2 * time.Second)
	defer deadline.Stop()
	ticker := time.NewTicker(10 * time.Millisecond)
	defer ticker.Stop()
	waiting := false
	for !waiting {
		select {
		case err := <-secondResult:
			t.Fatal("second ask did not overlap", err)
		case <-deadline.C:
			t.Fatal("no actual PostgreSQL lock wait observed")
		case <-ticker.C:
			var count int
			if err := database.QueryRow(ctx, "SELECT count(*) FROM pg_stat_activity WHERE $1=ANY(pg_blocking_pids(pid)) AND wait_event_type='Lock'", holder).Scan(&count); err != nil {
				t.Fatal(err)
			}
			waiting = count > 0
		}
	}
	t.Log("observed competing question transaction waiting on first transaction in PostgreSQL")
	unblock()
	if err := <-firstResult; err != nil {
		t.Fatal(err)
	}
	var conflict *receipt.ConflictError
	if err := <-secondResult; !errors.As(err, &conflict) {
		t.Fatal("different-message overlap did not return semantic conflict", err)
	}
	if questionCount(t, database, player.PlayerID) != 1 {
		t.Fatal("overlap produced more than one question")
	}
}
