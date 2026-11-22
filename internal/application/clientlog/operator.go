package clientlog

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Operator log console (OPERATOR_BACKUPS_LOGS_DESIGN C1d, C2, C4).
const (
	LogsClearCommand = "logs.clear"

	CodeLogsSource = "OPERATOR_LOG_SOURCE"
	CodeLogsScope  = "OPERATOR_LOG_SCOPE"
	CodeLogsTarget = "OPERATOR_LOG_TARGET"

	MaxJournalLimit = 200

	clearBatchSize  = 10_000
	MaxClearBatches = 20
)

// JournalEntry is one redacted request_journal row served to the operator
// timeline. The stored row is already redacted at ingest.
type JournalEntry struct {
	ReceivedAt          time.Time `json:"received_at"`
	PlayerID            *int64    `json:"player_id,omitempty"`
	SessionRef          *string   `json:"session_ref,omitempty"`
	MID                 *int      `json:"mid,omitempty"`
	Outcome             string    `json:"outcome"`
	ErrorCode           *int64    `json:"error_code,omitempty"`
	HTTPStatus          int       `json:"http_status"`
	LatencyMicroseconds int64     `json:"latency_microseconds"`
	ErrorClass          string    `json:"error_class,omitempty"`
	Cause               string    `json:"cause,omitempty"`
	RawEnvelope         string    `json:"raw_envelope,omitempty"`
	Replay              bool      `json:"replay"`
	JournalID           int64     `json:"-"`
}

// JournalFilter is one bounded timeline or tail query.
type JournalFilter struct {
	AccountUID string
	PlayerID   int64
	From       *time.Time
	To         *time.Time
	Outcomes   []string
	MID        int
	Limit      int
	Cursor     JournalCursor
}

// JournalCursor continues a page after one row.
type JournalCursor struct {
	ReceivedAt time.Time
	JournalID  int64
	Present    bool
}

func formatJournalCursor(entry JournalEntry) string {
	return entry.ReceivedAt.UTC().Format(time.RFC3339Nano) + "|" + strconv.FormatInt(entry.JournalID, 10)
}

// ParseJournalCursor reads a cursor this server issued.
func ParseJournalCursor(value string) (JournalCursor, error) {
	index := strings.LastIndex(value, "|")
	if index <= 0 {
		return JournalCursor{}, operator.Refuse(operator.CodeReadInvalid, "cursor is not a timeline cursor", nil)
	}
	receivedAt, err := time.Parse(time.RFC3339Nano, value[:index])
	if err != nil {
		return JournalCursor{}, operator.Refuse(operator.CodeReadInvalid, "cursor is not a timeline cursor", nil)
	}
	journalID, err := strconv.ParseInt(value[index+1:], 10, 64)
	if err != nil {
		return JournalCursor{}, operator.Refuse(operator.CodeReadInvalid, "cursor is not a timeline cursor", nil)
	}
	return JournalCursor{ReceivedAt: receivedAt, JournalID: journalID, Present: true}, nil
}

// JournalPage is the logs.timeline reply.
type JournalPage struct {
	Entries    []JournalEntry `json:"entries"`
	NextCursor string         `json:"next_cursor,omitempty"`
}

// JournalTail is the logs.tail reply for the client source.
type JournalTail struct {
	Entries    []JournalEntry `json:"entries"`
	NextCursor string         `json:"next_cursor,omitempty"`
}

// JournalReader is the PostgreSQL read port of the client log owner.
type JournalReader interface {
	JournalPage(ctx context.Context, transaction tx.Tx, filter JournalFilter) ([]JournalEntry, error)
	JournalTail(ctx context.Context, transaction tx.Tx, filter JournalFilter) ([]JournalEntry, error)
}

// JournalClearer removes redacted journal rows in bounded batches.
type JournalClearer interface {
	ClearJournalTx(ctx context.Context, transaction tx.Tx, filter ClearFilter, batch int) (int64, error)
}

// ClearFilter is one bounded delete scope.
type ClearFilter struct {
	AccountUID string
	PlayerID   int64
	Before     *time.Time
	Limit      int
}

// LogsReadService answers logs.timeline and logs.tail from the journal.
type LogsReadService struct {
	Runner     tx.Runner
	Operations operation.Factory
	Reader     JournalReader
}

func logsReadProfile() tx.Profile {
	return tx.Profile{Name: "operator-logs-read", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 20 * time.Second, TransactionTimeout: 60 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 120 * time.Second}
}

// Timeline answers one newest-first page.
func (service LogsReadService) Timeline(ctx context.Context, filter JournalFilter) (JournalPage, error) {
	if service.Reader == nil || service.Runner.DB == nil {
		return JournalPage{}, operator.ErrUnavailable
	}
	filter.Limit = journalLimit(filter.Limit)
	var entries []JournalEntry
	current, err := service.Operations.New(policy.Set{})
	if err != nil {
		return JournalPage{}, err
	}
	_, err = service.Runner.Run(ctx, current, logsReadProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		var readErr error
		entries, readErr = service.Reader.JournalPage(ctx, scope.Tx, filter)
		return readErr
	})
	if err != nil {
		return JournalPage{}, err
	}
	page := JournalPage{Entries: entries}
	if len(entries) == filter.Limit {
		page.NextCursor = formatJournalCursor(entries[len(entries)-1])
	}
	if page.Entries == nil {
		page.Entries = []JournalEntry{}
	}
	return page, nil
}

// Tail answers rows newer than the cursor, oldest first for a live view.
func (service LogsReadService) Tail(ctx context.Context, filter JournalFilter) (JournalTail, error) {
	if service.Reader == nil || service.Runner.DB == nil {
		return JournalTail{}, operator.ErrUnavailable
	}
	filter.Limit = journalLimit(filter.Limit)
	var entries []JournalEntry
	current, err := service.Operations.New(policy.Set{})
	if err != nil {
		return JournalTail{}, err
	}
	_, err = service.Runner.Run(ctx, current, logsReadProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		var readErr error
		entries, readErr = service.Reader.JournalTail(ctx, scope.Tx, filter)
		return readErr
	})
	if err != nil {
		return JournalTail{}, err
	}
	tail := JournalTail{Entries: entries}
	if len(entries) > 0 {
		tail.NextCursor = formatJournalCursor(entries[len(entries)-1])
	}
	if tail.Entries == nil {
		tail.Entries = []JournalEntry{}
	}
	return tail, nil
}

func journalLimit(limit int) int {
	if limit <= 0 {
		return 50
	}
	if limit > MaxJournalLimit {
		return MaxJournalLimit
	}
	return limit
}

// OutcomesForLevel maps the operator level filter onto journal outcomes. C3
// defines levels for tool and backend lines; for the client journal the
// outcome is the fact, so error is a client or server error and warn is an
// unknown MID or an undecodable request.
func OutcomesForLevel(level string) ([]string, error) {
	switch level {
	case "":
		return nil, nil
	case "info":
		return []string{"OK", "INACTIVE_MODE"}, nil
	case "warn":
		return []string{"UNKNOWN_MID", "UNDECODABLE"}, nil
	case "error":
		return []string{"CLIENT_ERROR", "SERVER_ERROR"}, nil
	default:
		return nil, operator.Refuse(operator.CodeReadInvalid, "level is one of info, warn or error", nil)
	}
}

// ClearPayload is the logs.clear payload (C4). The client source is the only
// one the backend owns; the agent clears its own process log.
type ClearPayload struct {
	Source    string `json:"source"`
	Scope     string `json:"scope"`
	PlayerID  int64  `json:"player_id,omitempty"`
	UID       string `json:"uid,omitempty"`
	OlderThan string `json:"older_than,omitempty"`
}

// ClearResult is the logs.clear reply.
type ClearResult struct {
	Source  string `json:"source"`
	Scope   string `json:"scope"`
	Removed int64  `json:"removed"`
}

// LogsCommands applies logs.clear on the operator bus.
type LogsCommands struct {
	Clearer JournalClearer
}

// Handlers returns the command handlers this module registers.
func (commands LogsCommands) Handlers() map[string]operator.Handler {
	return map[string]operator.Handler{LogsClearCommand: commands.clearHandler}
}

func (commands LogsCommands) clearHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var payload ClearPayload
	if err := decodeLogPayload(command.Payload, &payload); err != nil {
		return nil, operator.Refuse(operator.CodePayloadInvalid, err.Error(), nil)
	}
	filter, err := clearFilter(payload)
	if err != nil {
		return nil, err
	}
	if commands.Clearer == nil {
		return nil, operator.ErrUnavailable
	}
	removed, err := commands.Clearer.ClearJournalTx(ctx, scope.Tx, filter, clearBatchSize)
	if err != nil {
		return nil, err
	}
	return ClearResult{Source: "client", Scope: payload.Scope, Removed: removed}, nil
}

func clearFilter(payload ClearPayload) (ClearFilter, error) {
	if payload.Source != "" && payload.Source != "client" {
		return ClearFilter{}, operator.Refuse(CodeLogsSource, "the backend clears the client source only", nil)
	}
	var filter ClearFilter
	switch payload.Scope {
	case "all":
		return filter, nil
	case "player":
		if payload.UID == "" && payload.PlayerID == 0 {
			return ClearFilter{}, operator.Refuse(CodeLogsTarget, "the player scope needs uid or player_id", nil)
		}
		filter.AccountUID, filter.PlayerID = payload.UID, payload.PlayerID
		return filter, nil
	case "older_than":
		if payload.OlderThan == "" {
			return ClearFilter{}, operator.Refuse(CodeLogsTarget, "older_than is required for the older_than scope", nil)
		}
		boundary, err := time.Parse(time.RFC3339, payload.OlderThan)
		if err != nil {
			return ClearFilter{}, operator.Refuse(CodeLogsTarget, "older_than must be RFC3339", nil)
		}
		filter.Before = &boundary
		return filter, nil
	default:
		return ClearFilter{}, operator.Refuse(CodeLogsScope, "scope is one of all, player or older_than", nil)
	}
}

func decodeLogPayload(payload []byte, target any) error {
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return err
	}
	if err := decoder.Decode(&struct{}{}); err == nil {
		return errors.New("trailing data after the payload")
	}
	return nil
}
