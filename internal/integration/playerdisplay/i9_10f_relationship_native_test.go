//go:build postgres

package playerdisplay_test

import (
	"errors"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/mentorstore"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestMentorRelationshipSlotsRollbackAndHistory(t *testing.T) {
	database := pool(t)
	first, second, third := actor(t, database), actor(t, database), actor(t, database)
	store := mentorstore.Store{}
	at := time.Now().UTC().Truncate(time.Microsecond)
	recordFor := func(teacher, student identity.PlayerID) mentor.Relationship {
		identifier, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		return mentor.Relationship{ID: identifier, Mentor: teacher, Student: student, Server: first.LogicalServerID, ContentRevision: strings.Repeat("a", 64), PolicyVersion: mentor.MinimumLevelGapPolicy, AcceptedAt: at, Version: 1}
	}
	begin := func() tx.Scope {
		transaction, err := database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
		if err != nil {
			t.Fatal(err)
		}
		t.Cleanup(func() { _ = transaction.Rollback(ctx) })
		return tx.Scope{Tx: transaction, Options: tx.Options{Isolation: tx.Serializable}}
	}
	firstPair := recordFor(first.PlayerID, second.PlayerID)
	scope := begin()
	if _, err := (i4store.PlayerRootLocker{}).LockPlayerRootsTx(ctx, scope.Tx, first.LogicalServerID, []identity.PlayerID{second.PlayerID, first.PlayerID}); err != nil {
		t.Fatal(err)
	}
	if err := store.InsertRelationshipTx(ctx, scope.Tx, firstPair); err != nil {
		t.Fatal(err)
	}
	if err := scope.Tx.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	scope = begin()
	active, err := store.ReadRelationshipsTx(ctx, scope.Tx, first.PlayerID, first.LogicalServerID)
	if err != nil || len(active) != 0 {
		t.Fatal("rollback", active, err)
	}
	_ = scope.Tx.Rollback(ctx)
	insert := func(record mentor.Relationship, wantSuccess bool) {
		scope := begin()
		if _, err := (i4store.PlayerRootLocker{}).LockPlayerRootsTx(ctx, scope.Tx, record.Server, []identity.PlayerID{record.Student, record.Mentor}); err != nil {
			t.Fatal(err)
		}
		err := store.InsertRelationshipTx(ctx, scope.Tx, record)
		if !wantSuccess {
			if tx.SQLState(err) != "23505" {
				t.Fatal("expected active-slot uniqueness refusal", err)
			}
			_ = scope.Tx.Rollback(ctx)
			return
		}
		if err != nil {
			t.Fatal(err)
		}
		if err = scope.Tx.Commit(ctx); err != nil {
			t.Fatal(err)
		}
	}
	insert(firstPair, true)
	insert(recordFor(first.PlayerID, third.PlayerID), false)
	insert(recordFor(third.PlayerID, second.PlayerID), false)
	insert(recordFor(second.PlayerID, first.PlayerID), false)
	secondPair := recordFor(second.PlayerID, third.PlayerID)
	insert(secondPair, true)
	scope = begin()
	active, err = store.ReadRelationshipsTx(ctx, scope.Tx, second.PlayerID, second.LogicalServerID)
	if err != nil || len(active) != 2 {
		t.Fatal("dual-role slots", len(active), err)
	}
	_ = scope.Tx.Rollback(ctx)
	scope = begin()
	if err = store.EndRelationshipTx(ctx, scope.Tx, firstPair, at.Add(time.Hour)); err != nil {
		t.Fatal(err)
	}
	if err = scope.Tx.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	scope = begin()
	if err = store.EndRelationshipTx(ctx, scope.Tx, firstPair, at.Add(2*time.Hour)); !errors.Is(err, mentor.ErrRelationshipConflict) {
		t.Fatal("stale end", err)
	}
	_ = scope.Tx.Rollback(ctx)
	reestablished := recordFor(first.PlayerID, second.PlayerID)
	insert(reestablished, true)
	var history int
	if err = database.QueryRow(ctx, "SELECT count(*) FROM mentor_relations WHERE mentor_id=$1", int64(first.PlayerID)).Scan(&history); err != nil || history != 2 {
		t.Fatal("history not retained", history, err)
	}
	var endedIdentifier, endedRevision, endedPolicy string
	var endedAccepted, endedAt time.Time
	var endedVersion int64
	if err = database.QueryRow(ctx, "SELECT relation_id::text,content_revision,policy_version,accepted_at,ended_at,state_version FROM mentor_relations WHERE relation_id=$1", firstPair.ID.String()).Scan(&endedIdentifier, &endedRevision, &endedPolicy, &endedAccepted, &endedAt, &endedVersion); err != nil {
		t.Fatal(err)
	}
	if endedIdentifier != firstPair.ID.String() || endedRevision != firstPair.ContentRevision || endedPolicy != firstPair.PolicyVersion || !endedAccepted.Equal(firstPair.AcceptedAt) || endedAt.Before(firstPair.AcceptedAt) || endedVersion != 2 {
		t.Fatal("ended row lost producer fields", endedIdentifier, endedRevision, endedPolicy, endedAccepted, endedAt, endedVersion)
	}
	if reestablished.ID == firstPair.ID {
		t.Fatal("re-established relation reused the history id")
	}
	readOnly, err := database.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true})
	if err != nil {
		t.Fatal(err)
	}
	defer readOnly.Rollback(ctx)
	if active, err = store.ReadRelationshipsTx(ctx, readOnly, second.PlayerID, second.LogicalServerID); err != nil || len(active) != 2 {
		t.Fatal("read-only snapshot", active, err)
	}
	if err = store.InsertRelationshipTx(ctx, readOnly, recordFor(third.PlayerID, first.PlayerID)); !errors.Is(err, mentor.ErrRelationship) {
		t.Fatal("read-only write admitted", err)
	}
}

func TestMentorOverlappingPairWaitsOnCanonicalPlayerRoot(t *testing.T) {
	database := pool(t)
	teacher, firstStudent, secondStudent := actor(t, database), actor(t, database), actor(t, database)
	newRecord := func(student identity.PlayerID) mentor.Relationship {
		identifier, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		return mentor.Relationship{ID: identifier, Mentor: teacher.PlayerID, Student: student, Server: teacher.LogicalServerID, ContentRevision: strings.Repeat("b", 64), PolicyVersion: mentor.MinimumLevelGapPolicy, AcceptedAt: time.Now().UTC().Truncate(time.Microsecond), Version: 1}
	}
	firstRecord, secondRecord := newRecord(firstStudent.PlayerID), newRecord(secondStudent.PlayerID)
	options := tx.Options{Isolation: tx.Serializable}
	firstTransaction, err := database.Begin(ctx, options)
	if err != nil {
		t.Fatal(err)
	}
	defer firstTransaction.Rollback(ctx)
	if _, err = (i4store.PlayerRootLocker{}).LockPlayerRootsTx(ctx, firstTransaction, teacher.LogicalServerID, []identity.PlayerID{firstStudent.PlayerID, teacher.PlayerID}); err != nil {
		t.Fatal(err)
	}
	if err = (mentorstore.Store{}).InsertRelationshipTx(ctx, firstTransaction, firstRecord); err != nil {
		t.Fatal(err)
	}
	competitor, err := database.Begin(ctx, options)
	if err != nil {
		t.Fatal(err)
	}
	defer competitor.Rollback(ctx)
	var backendProcess int
	if err = competitor.QueryRow(ctx, "SELECT pg_backend_pid()").Scan(&backendProcess); err != nil {
		t.Fatal(err)
	}
	result := make(chan error, 1)
	go func() {
		_, failure := (i4store.PlayerRootLocker{}).LockPlayerRootsTx(ctx, competitor, teacher.LogicalServerID, []identity.PlayerID{secondStudent.PlayerID, teacher.PlayerID})
		if failure == nil {
			failure = (mentorstore.Store{}).InsertRelationshipTx(ctx, competitor, secondRecord)
		}
		_ = competitor.Rollback(ctx)
		result <- failure
	}()
	observed := false
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		if err = database.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM pg_stat_activity WHERE pid=$1 AND wait_event_type='Lock' AND query ILIKE '%FROM players%FOR UPDATE%')", backendProcess).Scan(&observed); err != nil {
			t.Fatal(err)
		}
		if observed {
			break
		}
		time.Sleep(10 * time.Millisecond)
	}
	if !observed {
		t.Fatal("competitor never observed waiting on actual canonical315 row lock")
	}
	if err = firstTransaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	select {
	case err = <-result:
		if tx.SQLState(err) != "23505" && tx.SQLState(err) != "40001" {
			t.Fatal("second pair did not refuse occupied slot", err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("competing transaction did not finish after lock release")
	}
	var count int
	if err = database.QueryRow(ctx, "SELECT count(*) FROM mentor_relations WHERE mentor_id=$1 AND ended_at IS NULL", int64(teacher.PlayerID)).Scan(&count); err != nil || count != 1 {
		t.Fatal("active-slot invariant", count, err)
	}
}
