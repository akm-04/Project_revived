//go:build postgres

package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/auditstore"
	"gxb.local/backend/v2/internal/adapters/postgres/identitystore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	"gxb.local/backend/v2/internal/foundation/audit"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	revokeSessionAction = "identity.session.revoke"
	revokeSessionPolicy = "gxb.identity.session-revoke.v1"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: gxb-admin revoke-session (-player ID | -session UUID) -operator NAME -reason CODE")
		fmt.Fprintln(os.Stderr, "       gxb-admin restore-epoch begin -backup LABEL -operator NAME")
		fmt.Fprintln(os.Stderr, "       gxb-admin restore-epoch reconcile -epoch N -operator NAME -note TEXT")
		os.Exit(2)
	}
	dsn := os.Getenv("GXB_POSTGRES_DSN")
	var err error
	switch os.Args[1] {
	case "revoke-session":
		err = run(context.Background(), os.Args[2:], dsn)
	case "restore-epoch":
		err = runRestoreEpoch(context.Background(), os.Args[2:], dsn)
	default:
		fmt.Fprintf(os.Stderr, "gxb-admin: unknown command %q\n", os.Args[1])
		os.Exit(2)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "gxb-admin:", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, arguments []string, dsn string) error {
	command, err := parseRevokeSessionArgs(arguments)
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
	service := appidentity.Service{
		Runner:      tx.Runner{DB: pool},
		Store:       identitystore.Store{},
		Receipts:    kernelstore.Store{},
		ReceiptRead: kernelstore.Reader{Queryer: pool},
		Audit:       auditstore.Store{},
	}
	named := appidentity.SessionTarget{Session: command.Session, Player: command.Player}
	target, err := service.ResolveSessionTarget(ctx, pool, command.Player, command.Session)
	if err != nil {
		emitRefusal(ctx, pool, command, named, operationContext)
		return err
	}
	event := audit.Event{
		OccurredAt:    operationContext.StartedAt.UTC(),
		ActorKind:     "AdminOperator",
		ActorID:       command.Operator,
		Action:        revokeSessionAction,
		TargetKind:    target.Kind(),
		TargetKey:     target.Key(),
		Outcome:       "SUCCEEDED",
		ReasonCode:    command.Reason,
		CorrelationID: operationContext.ID.String(),
		PolicyVersion: revokeSessionPolicy,
	}
	result, err := service.RevokeSession(ctx, appidentity.RevokeSessionCommand{SessionID: target.Session, Reason: command.Reason, Audit: &event}, operationContext)
	if err != nil {
		emitRefusal(ctx, pool, command, target, operationContext)
		return fmt.Errorf("revoke-session refused: %w", err)
	}
	fmt.Printf("revoked session %s for %s %s by %s\n", result.SessionID, target.Kind(), target.Key(), command.Operator)
	return nil
}

func emitRefusal(ctx context.Context, pool *pg.Pool, command revokeSessionArgs, target appidentity.SessionTarget, operationContext operation.Context) {
	auditstore.Emitter{Pool: pool}.Emit(context.WithoutCancel(ctx), audit.Event{
		OccurredAt:    operationContext.StartedAt.UTC(),
		ActorKind:     "AdminOperator",
		ActorID:       command.Operator,
		Action:        revokeSessionAction,
		TargetKind:    target.Kind(),
		TargetKey:     target.Key(),
		Outcome:       "REFUSED",
		ReasonCode:    command.Reason,
		CorrelationID: operationContext.ID.String(),
		PolicyVersion: revokeSessionPolicy,
	})
}
