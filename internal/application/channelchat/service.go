// Package channelchat prepares ephemeral ordinary messages using existing owner ports.
// Numeric MIDs, AMF, socket writers and canonical SQL remain at their adapter edges.
package channelchat

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
	"unicode/utf8"
)

var ErrInvalidMessage = errors.New("invalid ordinary channel message")
var ErrIncompleteRead = errors.New("channel read did not complete definitely")

func ValidateMessage(s string) error {
	if s == "" || !utf8.ValidString(s) || utf8.RuneCountInString(s) > 140 {
		return ErrInvalidMessage
	}
	return nil
}

// Reader never begins/commits and must bind every owner reader to the exact caller transaction.
type Reader interface {
	ReadTx(context.Context, tx.Tx, apprealtime.Admission, bool) (playerpresentation.Minimal, error)
}
type Service struct {
	Runner     tx.Runner
	Operations operation.Factory
	Reader     Reader
}

func ReadProfile() tx.Profile {
	return tx.Profile{Name: "channel-chat-read-v1", AcquireTimeout: 500 * time.Millisecond, LockTimeout: 500 * time.Millisecond, StatementTimeout: 1500 * time.Millisecond, TransactionTimeout: 2 * time.Second, CleanupTimeout: 500 * time.Millisecond, ReconcileTimeout: 500 * time.Millisecond, OperationTimeout: 3 * time.Second}
}
func (s Service) Prepare(ctx context.Context, a apprealtime.Admission, message string) (playerpresentation.Minimal, error) {
	if err := ValidateMessage(message); err != nil {
		return playerpresentation.Minimal{}, err
	}
	return s.read(ctx, a, true)
}
func (s Service) AuthorizeRecipient(ctx context.Context, a apprealtime.Admission) error {
	_, err := s.read(ctx, a, false)
	return err
}
func (s Service) read(ctx context.Context, a apprealtime.Admission, prepare bool) (playerpresentation.Minimal, error) {
	if s.Reader == nil {
		return playerpresentation.Minimal{}, ErrIncompleteRead
	}
	op, err := s.Operations.New(policy.Set{})
	if err != nil {
		return playerpresentation.Minimal{}, err
	}
	var private playerpresentation.Minimal
	result, err := s.Runner.Run(ctx, op, ReadProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		v, e := s.Reader.ReadTx(ctx, scope.Tx, a, prepare)
		if e == nil {
			private = v
		}
		return e
	})
	if err != nil {
		return playerpresentation.Minimal{}, err
	}
	if result.Outcome != tx.DefiniteCommit {
		return playerpresentation.Minimal{}, ErrIncompleteRead
	}
	return private, nil
}
