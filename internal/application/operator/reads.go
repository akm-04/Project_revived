package operator

import (
	"context"
	"fmt"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// CodeReadInvalid is the refusal of a malformed operator read query.
const CodeReadInvalid = "OPERATOR_READ_INVALID"

const (
	defaultAuditLimit = 50
	maxAuditLimit     = 200
)

// AuditFilter is the operator.audit.list query (ruling 6).
type AuditFilter struct {
	From        *time.Time
	To          *time.Time
	Module      string
	Principal   string
	SemanticKey string
	Limit       int
	Cursor      *AuditCursor
}

// AuditCursor is the (created_at, semantic_key) position of the last row.
type AuditCursor struct {
	CreatedAt   time.Time
	SemanticKey string
}

func (cursor AuditCursor) String() string {
	return cursor.CreatedAt.UTC().Format(time.RFC3339Nano) + "|" + cursor.SemanticKey
}

// ParseAuditCursor reads the opaque cursor the page returned.
func ParseAuditCursor(text string) (*AuditCursor, error) {
	createdText, semanticKey, found := strings.Cut(text, "|")
	if !found || semanticKey == "" {
		return nil, Refuse(CodeReadInvalid, "cursor is not a (created_at, semantic_key) position", nil)
	}
	createdAt, err := time.Parse(time.RFC3339Nano, createdText)
	if err != nil {
		return nil, Refuse(CodeReadInvalid, fmt.Sprintf("cursor time %q is not RFC3339: %v", createdText, err), nil)
	}
	return &AuditCursor{CreatedAt: createdAt, SemanticKey: semanticKey}, nil
}

// AuditPage is the operator.audit.list reply, newest first.
type AuditPage struct {
	Commands   []Record `json:"commands"`
	NextCursor string   `json:"next_cursor,omitempty"`
}

// AuditReader is the operator_commands read port. It returns at most filter.Limit rows.
type AuditReader interface {
	ListCommandsTx(context.Context, tx.Queryer, AuditFilter) ([]Record, error)
}

// AuditService pages the audit log in one read-only transaction.
type AuditService struct {
	Runner     tx.Runner
	Operations operation.Factory
	Reader     AuditReader
}

func (s AuditService) List(ctx context.Context, filter AuditFilter) (AuditPage, error) {
	if s.Reader == nil || s.Runner.DB == nil {
		return AuditPage{}, ErrUnavailable
	}
	if filter.Limit == 0 {
		filter.Limit = defaultAuditLimit
	}
	if filter.Limit < 1 || filter.Limit > maxAuditLimit {
		return AuditPage{}, Refuse(CodeReadInvalid, fmt.Sprintf("limit must be between 1 and %d", maxAuditLimit), nil)
	}
	current, err := s.Operations.New(policy.Set{})
	if err != nil {
		return AuditPage{}, err
	}
	requested := filter.Limit
	filter.Limit = requested + 1
	var rows []Record
	_, err = s.Runner.Run(ctx, current, readProfile("operator-audit-read-v1"), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		loaded, readErr := s.Reader.ListCommandsTx(ctx, scope.Tx, filter)
		if readErr == nil {
			rows = loaded
		}
		return readErr
	})
	if err != nil {
		return AuditPage{}, err
	}
	page := AuditPage{Commands: rows}
	if len(rows) > requested {
		page.Commands = rows[:requested]
		last := page.Commands[len(page.Commands)-1]
		page.NextCursor = AuditCursor{CreatedAt: last.CreatedAt, SemanticKey: last.SemanticKey}.String()
	}
	if page.Commands == nil {
		page.Commands = []Record{}
	}
	return page, nil
}

func readProfile(name string) tx.Profile {
	return tx.Profile{Name: name, AcquireTimeout: 500 * time.Millisecond, LockTimeout: 500 * time.Millisecond, StatementTimeout: 1500 * time.Millisecond, TransactionTimeout: 2 * time.Second, CleanupTimeout: 500 * time.Millisecond, ReconcileTimeout: 500 * time.Millisecond, OperationTimeout: 3 * time.Second}
}
