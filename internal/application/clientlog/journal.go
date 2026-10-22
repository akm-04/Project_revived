package clientlog

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"strings"
	"time"

	domain "gxb.local/backend/v2/internal/domain/clientlog"
	"gxb.local/backend/v2/internal/foundation/observability"
)

// JournalRow is one stored request journal row.
type JournalRow struct {
	ReceivedAt    time.Time
	Owner         *Owner
	MID           *int
	Outcome       domain.Outcome
	ErrorCode     *int64
	HTTPStatus    int
	Latency       time.Duration
	RequestBytes  int64
	ResponseBytes int64
	ErrorClass    string
	Cause         string
	RawEnvelope   []byte
	RequestSHA256 []byte
	Class         domain.RetentionClass
}

// Journal batching (D46).
const (
	journalQueueSize     = 4096
	journalBatchSize     = 256
	journalFlushInterval = 250 * time.Millisecond
)

var droppedLabels, _ = observability.NewLabels(observability.Pair{Key: "domain", Value: "client_observability"})

// Journal turns edge records into journal rows and writes them in batches off
// the request path. A full queue or failed write drops rows and counts them;
// it never fails or slows a request (R4).
type Journal struct {
	store   Store
	metrics observability.Metrics
	queue   chan JournalRow
}

func NewJournal(store Store, metrics observability.Metrics) *Journal {
	if metrics == nil {
		metrics = observability.NopMetrics{}
	}
	return &Journal{store: store, metrics: metrics, queue: make(chan JournalRow, journalQueueSize)}
}

// Record implements observability.RequestJournal.
func (j *Journal) Record(record observability.RequestRecord) {
	select {
	case j.queue <- journalRow(record):
	default:
		j.metrics.Counter("client_observability_journal_dropped", droppedLabels, 1)
	}
}

// Run writes queued rows until ctx ends, then flushes what is queued.
func (j *Journal) Run(ctx context.Context) {
	ticker := time.NewTicker(journalFlushInterval)
	defer ticker.Stop()
	pending := make([]JournalRow, 0, journalBatchSize)
	for {
		select {
		case row := <-j.queue:
			pending = append(pending, row)
			if len(pending) >= journalBatchSize {
				pending = j.flush(ctx, pending)
			}
		case <-ticker.C:
			pending = j.flush(ctx, pending)
		case <-ctx.Done():
			j.drain(pending)
			return
		}
	}
}

func (j *Journal) drain(pending []JournalRow) {
	for {
		select {
		case row := <-j.queue:
			pending = append(pending, row)
		default:
			flushContext, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()
			j.flush(flushContext, pending)
			return
		}
	}
}

func (j *Journal) flush(ctx context.Context, pending []JournalRow) []JournalRow {
	if len(pending) == 0 {
		return pending
	}
	if err := j.store.SaveJournal(ctx, pending); err != nil {
		j.metrics.Counter("client_observability_journal_dropped", droppedLabels, uint64(len(pending)))
	}
	return pending[:0]
}

func journalRow(record observability.RequestRecord) JournalRow {
	outcome := outcomeOf(record)
	row := JournalRow{
		ReceivedAt: record.ReceivedAt, Outcome: outcome, HTTPStatus: record.HTTPStatus, Latency: record.Latency,
		RequestBytes: record.RequestBytes, ResponseBytes: record.ResponseBytes, RequestSHA256: record.RequestSHA256, Class: outcome.Class(),
	}
	if record.Actor.AccountUID != "" {
		row.Owner = &Owner{AccountUID: record.Actor.AccountUID, PlayerID: record.Actor.PlayerID, SessionRef: domain.SessionReference(record.Actor.SessionID)}
	}
	if record.HasMID {
		mid := record.MID
		row.MID = &mid
	}
	if record.ErrorCode != 0 {
		code := record.ErrorCode
		row.ErrorCode = &code
	}
	if record.Cause != nil && outcome != domain.OutcomeOK {
		row.ErrorClass = errorClass(record.Cause)
		row.Cause, _ = domain.Truncate(observability.RedactText(record.Cause.Error()), domain.MaxCauseBytes)
	}
	if outcome.KeepsRawEnvelope() && len(record.Raw) > 0 {
		raw, _ := domain.Truncate(observability.RedactText(unescapeForm(record.Raw)), domain.MaxRawEnvelopeBytes)
		row.RawEnvelope = []byte(raw)
	}
	return row
}

func outcomeOf(record observability.RequestRecord) domain.Outcome {
	switch record.Disposition {
	case observability.RequestUnknownMID:
		return domain.OutcomeUnknownMID
	case observability.RequestUndecodable:
		return domain.OutcomeUndecodable
	default:
		return domain.OutcomeOf(record.HTTPStatus, record.ErrorCode)
	}
}

// unescapeForm turns the stock payload=<url-encoded JSON> body into readable
// text so secret values can be masked; undecodable escapes stay as sent.
func unescapeForm(raw []byte) string {
	text, err := url.QueryUnescape(string(raw))
	if err != nil {
		return string(raw)
	}
	return text
}

// errorClass names the Go types along the unwrap chain, with the SQLSTATE
// class when a database error is present (D47).
func errorClass(err error) string {
	var parts []string
	for current := err; current != nil && len(parts) < 8; current = errors.Unwrap(current) {
		parts = append(parts, fmt.Sprintf("%T", current))
		if coded, hasState := current.(interface{ SQLState() string }); hasState {
			parts = append(parts, "sqlstate:"+observability.SafeSQLState(coded.SQLState()))
		}
	}
	return strings.Join(parts, " > ")
}
