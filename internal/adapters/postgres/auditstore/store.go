// Package auditstore persists the durable operator audit trail (AC397-25).
// It is OPERATIONAL data, not a player table and not a second write authority.
package auditstore

import (
	"context"
	"errors"
	"log"

	"gxb.local/backend/v2/internal/foundation/audit"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const insertEvent = `INSERT INTO operator_audit_events(occurred_at,actor_kind,actor_id,action,target_kind,target_key,outcome,reason_code,correlation_id,policy_version) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`

type Store struct{}

func (Store) InsertTx(ctx context.Context, transaction tx.Tx, event audit.Event) error {
	if transaction == nil {
		return errors.New("nil audit transaction")
	}
	if err := event.Validate(); err != nil {
		return err
	}
	_, err := transaction.Exec(ctx, insertEvent, event.OccurredAt.UTC(), event.ActorKind, event.ActorID, event.Action, event.TargetKind, event.TargetKey, event.Outcome, event.ReasonCode, event.CorrelationID, event.PolicyVersion)
	return err
}

// Emitter writes audit events after their canonical transaction, in its own
// transaction. The port has no error return, so a failed write is logged; the
// canonical mutation is not rolled back by audit failure (AC397-25 keeps audit
// out of the write authority).
type Emitter struct {
	Pool tx.Beginner
}

func (e Emitter) Emit(ctx context.Context, event audit.Event) {
	if e.Pool == nil {
		log.Printf("audit: event actor=%q action=%q target=%q dropped: no database", event.ActorID, event.Action, event.TargetKey)
		return
	}
	transaction, err := e.Pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		log.Printf("audit: event actor=%q action=%q target=%q dropped: %v", event.ActorID, event.Action, event.TargetKey, err)
		return
	}
	if err = (Store{}).InsertTx(ctx, transaction, event); err != nil {
		_ = transaction.Rollback(context.WithoutCancel(ctx))
		log.Printf("audit: event actor=%q action=%q target=%q dropped: %v", event.ActorID, event.Action, event.TargetKey, err)
		return
	}
	if err = transaction.Commit(ctx); err != nil {
		log.Printf("audit: event actor=%q action=%q target=%q commit: %v", event.ActorID, event.Action, event.TargetKey, err)
	}
}

var _ audit.Emitter = Emitter{}
