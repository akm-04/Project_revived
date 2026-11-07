//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/i5"
	"strconv"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrecallstore"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
	recall "gxb.local/backend/v2/internal/application/socialrecall"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestRecallAwardRealI5AtomicRollbackOnce(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	caller := companionActor(t, database)
	target := companionActor(t, database)
	if _, err := privilegeService(database, database).ImportManual(ctx, authority(), importQ(target, "recall58-target-"+strconv.FormatInt(int64(target.PlayerID), 10), 1000), op()); err != nil {
		t.Fatal("qualified target privilege fixture", err)
	}
	content := contentstore.Store{Queryer: database}
	owner := socialrecallstore.Store{}
	at := time.Now().UTC()
	catalog, err := content.SocialRecallAwardCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	var identifier int64
	for key, spec := range catalog {
		if spec.Category == domain.CategoryCompletedTargets && spec.Threshold == 1 {
			identifier = key
		}
	}
	if identifier == 0 {
		t.Fatal("source lacks one-completion milestone")
	}
	current := op()
	current.Policies, err = policy.NewSet(policy.Ref{Name: "content", Version: revision}, policy.Ref{Name: "socialrecall", Version: recall.RecallPolicyVersion}, policy.Ref{Name: "roster-metrics", Version: characterasset.RosterMetricPolicy})
	if err != nil {
		t.Fatal(err)
	}
	transaction, err := database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	task, err := domain.NewTask(caller.PlayerID, target.PlayerID, caller.LogicalServerID, op().ID, at.Add(-time.Hour), 72*time.Hour, domain.Baseline{AcademyLevel: 1, OwnedHeroCount: 0, ChargeTotal: 0})
	if err != nil {
		t.Fatal(err)
	}
	record := recall.TaskRecord{Task: task, ContentRevision: revision, PolicyVersion: recall.RecallPolicyVersion, StateVersion: 1, UpdatedAt: task.StartedAt}
	if err := owner.InsertTaskTx(ctx, transaction, record); err != nil {
		t.Fatal(err)
	}
	completed, changed, err := record.Task.Complete(at.Add(-time.Minute))
	if err != nil || !changed {
		t.Fatal(err)
	}
	next := record
	next.Task = completed
	next.StateVersion++
	next.UpdatedAt = at.Add(-time.Minute)
	if err := owner.SaveRecallLoginTransitionTx(ctx, transaction, record, next); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	awarder := recall.Awarder{Players: i4store.PlayerRootLocker{}, Owner: owner, Content: content, Current: socialrecallstore.TargetReader{Progression: i5store.Store{Queryer: database}, Roster: characterstore.RosterMetricReader{Store: characterstore.Store{Queryer: database}, Content: content}, Privilege: commerceprivilege.Provider{Store: commerceprivilegestore.Store{}, Content: content}}, Grants: courseService(database, database).Grants}
	balance := func() int64 {
		var amount int64
		if err := database.QueryRow(ctx, "SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'", int64(caller.PlayerID)).Scan(&amount); err != nil {
			t.Fatal(err)
		}
		return amount
	}
	initial := balance()

	transaction, err = database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	scope := tx.Scope{Tx: transaction, Operation: current, Options: tx.Options{Isolation: tx.Serializable}, Attempt: 1}
	result, err := awarder.AwardTx(ctx, scope, caller, identifier, revision, at)
	if err != nil {
		t.Fatal(err)
	}
	if result.AwardID != identifier || len(result.Awarded) != 1 || result.Awarded[0] != identifier || result.Grant.ReceiptID == "" {
		t.Fatal("invalid award result", result)
	}
	if err := transaction.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	awarded, err := owner.AwardedIDsTx(ctx, database, caller.PlayerID, caller.LogicalServerID)
	if err != nil || len(awarded) != 0 || balance() != initial {
		t.Fatal("owner or value escaped rollback", awarded, err)
	}
	start := make(chan struct{})
	outcomes := make(chan error, 2)
	for index := 0; index < 2; index++ {
		attempt := op()
		attempt.Policies = current.Policies
		go func() {
			<-start
			_, err := (tx.Runner{DB: database}).Run(ctx, attempt, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true}, nil, func(ctx context.Context, scope tx.Scope) error {
				_, err := awarder.AwardTx(ctx, scope, caller, identifier, revision, scope.Operation.StartedAt)
				return err
			})
			outcomes <- err
		}()
	}
	close(start)
	winners, refusals := 0, 0
	for index := 0; index < 2; index++ {
		err := <-outcomes
		if err == nil {
			winners++
		} else if errors.Is(err, recall.ErrAwardRefused) {
			refusals++
		} else {
			t.Fatal("concurrent claim failed", err)
		}
	}
	if winners != 1 || refusals != 1 {
		t.Fatal("business entitlement was not once-only", winners, refusals)
	}

	expected := int64(0)
	for _, line := range catalog[identifier].Lines {
		if line.ResourceKey == "crystal" {
			expected += line.Amount
		}
	}
	if expected <= 0 || balance() != initial+expected {
		t.Fatal("canonical I5 crystal effect wrong", initial, balance(), expected)
	}
	transaction, err = database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	_, err = awarder.AwardTx(ctx, tx.Scope{Tx: transaction, Operation: current, Options: tx.Options{Isolation: tx.Serializable}, Attempt: 1}, caller, identifier, revision, at)
	if !errors.Is(err, recall.ErrAwardRefused) {
		t.Fatal("repeated business entitlement admitted", err)
	}

	if err := transaction.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	var itemAward int64
	for key, spec := range catalog {
		if spec.Category == domain.CategoryCharge && spec.Threshold == 900 {
			itemAward = key
		}
	}
	if itemAward == 0 {
		t.Fatal("source charge milestone missing")
	}
	quantity := func(identifier int64) int64 {
		var value int64
		if err := database.QueryRow(ctx, "SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)", int64(caller.PlayerID), identifier).Scan(&value); err != nil {
			t.Fatal(err)
		}
		return value
	}
	beforeItems := map[int64]int64{}
	beforeCrystal := balance()
	for _, line := range catalog[itemAward].Lines {
		if line.ItemID > 0 {
			beforeItems[line.ItemID] = quantity(line.ItemID)
		}
	}
	if len(beforeItems) == 0 {
		t.Fatal("source fixture lacks stack reward")
	}
	itemOperation := op()
	itemOperation.Policies = current.Policies
	transaction, err = database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	itemResult, err := awarder.AwardTx(ctx, tx.Scope{Tx: transaction, Operation: itemOperation, Options: tx.Options{Isolation: tx.Serializable}, Attempt: 1}, caller, itemAward, revision, itemOperation.StartedAt)
	if err != nil {
		t.Fatal("source stack+crystal award", err)
	}
	if len(itemResult.Awarded) != 2 {
		t.Fatal("new claim lost prior milestone", itemResult.Awarded)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	for _, line := range catalog[itemAward].Lines {
		if line.ItemID > 0 && quantity(line.ItemID) != beforeItems[line.ItemID]+line.Amount {
			t.Fatal("I5 stack reward wrong", line)
		}
		if line.ResourceKey == "crystal" && balance() != beforeCrystal+line.Amount {
			t.Fatal("I5 crystal reward wrong", line)
		}
	}
	snapshot, err := database.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true})
	if err != nil {
		t.Fatal(err)
	}
	defer snapshot.Rollback(ctx)
	observation, err := awarder.Current.ReadRecallCurrentTx(ctx, tx.Scope{Tx: snapshot, Operation: current, Options: tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, Attempt: 1}, target.PlayerID, revision, at)
	if err != nil || observation.Baseline.ChargeTotal != 1000 {
		t.Fatal("pure completed-target snapshot unavailable", observation, err)
	}
	if err := snapshot.Commit(ctx); err != nil {
		t.Fatal(err)
	}

}
