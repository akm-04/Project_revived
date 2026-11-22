//go:build postgres

package main

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/auditstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/restorestore"
	"gxb.local/backend/v2/internal/foundation/audit"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	restoreEpochBeginAction     = "operations.restore-epoch.begin"
	restoreEpochReconcileAction = "operations.restore-epoch.reconcile"
	restoreEpochPolicy          = "gxb.operations.restore-epoch.v1"
)

func restoreEpochProfile() tx.Profile {
	return tx.Profile{Name: "RESTORE_EPOCH_WRITE", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}

func runRestoreEpoch(ctx context.Context, arguments []string, dsn string) error {
	command, err := parseRestoreEpochArgs(arguments)
	if err != nil {
		return err
	}
	if strings.TrimSpace(dsn) == "" {
		return errors.New("GXB_POSTGRES_DSN required: refusing to run an unaudited operator command without a database")
	}
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "gxb-admin"})
	if err != nil {
		return err
	}
	defer pool.Close()
	operationContext, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		return err
	}
	action := restoreEpochBeginAction
	if command.Action == "reconcile" {
		action = restoreEpochReconcileAction
	}
	var epoch restorestore.Epoch
	_, err = (tx.Runner{DB: pool}).Run(ctx, operationContext, restoreEpochProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(txCtx context.Context, scope tx.Scope) error {
		var bodyErr error
		if command.Action == "begin" {
			epoch, bodyErr = (restorestore.Store{}).InsertTx(txCtx, scope.Tx, command.Backup, command.Operator)
		} else {
			epoch, bodyErr = (restorestore.Store{}).ReconcileTx(txCtx, scope.Tx, command.Epoch, command.Operator, command.Note)
		}
		if bodyErr != nil {
			return bodyErr
		}
		return (auditstore.Store{}).InsertTx(txCtx, scope.Tx, audit.Event{
			OccurredAt:    operationContext.StartedAt.UTC(),
			ActorKind:     "AdminOperator",
			ActorID:       command.Operator,
			Action:        action,
			TargetKind:    "restore_epoch",
			TargetKey:     strconv.FormatInt(epoch.Epoch, 10),
			Outcome:       "SUCCEEDED",
			CorrelationID: operationContext.ID.String(),
			PolicyVersion: restoreEpochPolicy,
		})
	})
	if err != nil {
		if command.Action == "reconcile" && errors.Is(err, kernelstore.ErrNoRows) {
			emitRestoreEpochRefusal(ctx, pool, command, operationContext)
			return fmt.Errorf("restore-epoch reconcile refused: epoch %d is unknown or already reconciled", command.Epoch)
		}
		return err
	}
	if command.Action == "begin" {
		fmt.Printf("restore epoch %d open for backup %s by %s\n", epoch.Epoch, epoch.BackupLabel, command.Operator)
		return nil
	}
	fmt.Printf("restore epoch %d reconciled by %s\n", epoch.Epoch, command.Operator)
	return nil
}

func emitRestoreEpochRefusal(ctx context.Context, pool *pg.Pool, command restoreEpochArgs, operationContext operation.Context) {
	auditstore.Emitter{Pool: pool}.Emit(context.WithoutCancel(ctx), audit.Event{
		OccurredAt:    operationContext.StartedAt.UTC(),
		ActorKind:     "AdminOperator",
		ActorID:       command.Operator,
		Action:        restoreEpochReconcileAction,
		TargetKind:    "restore_epoch",
		TargetKey:     strconv.FormatInt(command.Epoch, 10),
		Outcome:       "REFUSED",
		CorrelationID: operationContext.ID.String(),
		PolicyVersion: restoreEpochPolicy,
	})
}
