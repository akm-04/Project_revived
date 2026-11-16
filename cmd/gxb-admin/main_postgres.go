//go:build postgres

package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/auditstore"
	"gxb.local/backend/v2/internal/adapters/postgres/identitystore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	"gxb.local/backend/v2/internal/domain/identity"
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

type revokeTarget struct {
	session identity.SessionID
	player  identity.PlayerID
}

func (t revokeTarget) kind() string {
	if t.player.Valid() {
		return "player"
	}
	return "session"
}

func (t revokeTarget) key() string {
	if t.player.Valid() {
		return strconv.FormatInt(int64(t.player), 10)
	}
	return t.session.UUID().String()
}

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
	target, err := resolveTarget(ctx, pool, command)
	if err != nil {
		emitRefusal(ctx, pool, command, revokeTarget{session: command.Session, player: command.Player}, operationContext)
		return err
	}
	event := audit.Event{
		OccurredAt:    operationContext.StartedAt.UTC(),
		ActorKind:     "AdminOperator",
		ActorID:       command.Operator,
		Action:        revokeSessionAction,
		TargetKind:    target.kind(),
		TargetKey:     target.key(),
		Outcome:       "SUCCEEDED",
		ReasonCode:    command.Reason,
		CorrelationID: operationContext.ID.String(),
		PolicyVersion: revokeSessionPolicy,
	}
	service := appidentity.Service{
		Runner:      tx.Runner{DB: pool},
		Store:       identitystore.Store{},
		Receipts:    kernelstore.Store{},
		ReceiptRead: kernelstore.Reader{Queryer: pool},
		Audit:       auditstore.Store{},
	}
	result, err := service.RevokeSession(ctx, appidentity.RevokeSessionCommand{SessionID: target.session, Reason: command.Reason, Audit: &event}, operationContext)
	if err != nil {
		emitRefusal(ctx, pool, command, target, operationContext)
		return fmt.Errorf("revoke-session refused: %w", err)
	}
	fmt.Printf("revoked session %s for %s %s by %s\n", result.SessionID, target.kind(), target.key(), command.Operator)
	return nil
}

func resolveTarget(ctx context.Context, pool *pg.Pool, command revokeSessionArgs) (revokeTarget, error) {
	if command.Player <= 0 {
		return revokeTarget{session: command.Session}, nil
	}
	sessions, err := (identitystore.Store{}).FindLiveSessionsByPlayer(ctx, pool, command.Player)
	if err != nil {
		return revokeTarget{}, fmt.Errorf("revoke-session: player %d sessions: %w", command.Player, err)
	}
	switch len(sessions) {
	case 0:
		return revokeTarget{}, fmt.Errorf("revoke-session refused: player %d has no live session", command.Player)
	case 1:
		return revokeTarget{player: command.Player, session: sessions[0]}, nil
	default:
		return revokeTarget{}, fmt.Errorf("revoke-session refused: player %d has %d live sessions; name one with -session", command.Player, len(sessions))
	}
}

func emitRefusal(ctx context.Context, pool *pg.Pool, command revokeSessionArgs, target revokeTarget, operationContext operation.Context) {
	auditstore.Emitter{Pool: pool}.Emit(context.WithoutCancel(ctx), audit.Event{
		OccurredAt:    operationContext.StartedAt.UTC(),
		ActorKind:     "AdminOperator",
		ActorID:       command.Operator,
		Action:        revokeSessionAction,
		TargetKind:    target.kind(),
		TargetKey:     target.key(),
		Outcome:       "REFUSED",
		ReasonCode:    command.Reason,
		CorrelationID: operationContext.ID.String(),
		PolicyVersion: revokeSessionPolicy,
	})
}
