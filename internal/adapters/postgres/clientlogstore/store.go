// Package clientlogstore is the ClientLog owner's PostgreSQL adapter
// (migration 00076). Its writes never share a transaction with gameplay.
package clientlogstore

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	app "gxb.local/backend/v2/internal/application/clientlog"
	domain "gxb.local/backend/v2/internal/domain/clientlog"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{ Pool *pgxpool.Pool }

func (s Store) SaveGrant(ctx context.Context, grant app.Grant) error {
	_, err := s.Pool.Exec(ctx, `INSERT INTO client_log_capabilities(capability_digest,account_uid,player_id,logical_server_id,session_ref,issued_at,expires_at) VALUES($1,$2,$3,$4,$5,$6,$7)`,
		grant.Digest[:], grant.AccountUID, grant.PlayerID, grant.LogicalServerID, grant.SessionRef, grant.IssuedAt, grant.ExpiresAt)
	return err
}

func (s Store) Grant(ctx context.Context, digest [32]byte) (app.Grant, bool, error) {
	grant := app.Grant{Digest: digest}
	err := s.Pool.QueryRow(ctx, `SELECT account_uid,player_id,logical_server_id,session_ref,issued_at,expires_at FROM client_log_capabilities WHERE capability_digest=$1`, digest[:]).
		Scan(&grant.AccountUID, &grant.PlayerID, &grant.LogicalServerID, &grant.SessionRef, &grant.IssuedAt, &grant.ExpiresAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return app.Grant{}, false, nil
	}
	if err != nil {
		return app.Grant{}, false, err
	}
	return grant, true, nil
}

func owned(owner *app.Owner) (any, any, any) {
	if owner == nil {
		return nil, nil, nil
	}
	return owner.AccountUID, owner.PlayerID, owner.SessionRef
}

func nullableText(text string) any {
	if text == "" {
		return nil
	}
	return text
}

// SaveUpload stores the upload record and its rows in one transaction, so a
// 200 to the stock poster always means every row is durable.
func (s Store) SaveUpload(ctx context.Context, upload app.Upload) error {
	return pgx.BeginFunc(ctx, s.Pool, func(transaction pgx.Tx) error {
		accountUID, playerID, sessionRef := owned(upload.Owner)
		status := "PARSED"
		if upload.QuarantineReason != "" {
			status = "QUARANTINED"
		}
		_, err := transaction.Exec(ctx, `INSERT INTO client_log_uploads(upload_id,received_at,kind,account_uid,player_id,session_ref,attribution,status,quarantine_reason,retention_class,body_bytes,row_count,app_version,version,attachment_name,attachment,attachment_truncated,expires_at)
VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18)`,
			upload.ID.String(), upload.ReceivedAt, int16(upload.Kind), accountUID, playerID, sessionRef, string(upload.Attribution), status, nullableText(upload.QuarantineReason),
			string(upload.Class), upload.BodyBytes, len(upload.Rows), upload.AppVersion, upload.Version, nullableText(upload.AttachmentName), upload.Attachment, upload.AttachmentTruncated,
			upload.Class.ExpiresAt(upload.ReceivedAt))
		if err != nil {
			return err
		}
		batch := &pgx.Batch{}
		for ordinal, row := range upload.Rows {
			var extras any
			if row.Extras != nil {
				encoded, err := json.Marshal(row.Extras)
				if err != nil {
					return err
				}
				extras = encoded
			}
			batch.Queue(`INSERT INTO client_log_rows(upload_id,ordinal,received_at,account_uid,player_id,client_rowid,client_time,app_version,version,is_crash,dump,log,truncated,extras,retention_class,expires_at)
VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16)`,
				upload.ID.String(), ordinal, upload.ReceivedAt, accountUID, playerID, row.ClientRowID, row.ClientTime, row.AppVersion, row.Version, row.IsCrash, row.Dump, row.Log,
				row.Truncated, extras, string(row.Class), row.Class.ExpiresAt(upload.ReceivedAt))
		}
		return transaction.SendBatch(ctx, batch).Close()
	})
}

var journalColumns = []string{"received_at", "account_uid", "player_id", "session_ref", "mid", "outcome", "error_code", "http_status", "latency_microseconds",
	"request_bytes", "response_bytes", "error_class", "cause", "raw_envelope", "request_sha256", "replay", "retention_class", "expires_at"}

func (s Store) SaveJournal(ctx context.Context, rows []app.JournalRow) error {
	_, err := s.Pool.CopyFrom(ctx, pgx.Identifier{"request_journal"}, journalColumns, pgx.CopyFromSlice(len(rows), func(index int) ([]any, error) {
		row := rows[index]
		accountUID, playerID, sessionRef := owned(row.Owner)
		return []any{row.ReceivedAt, accountUID, playerID, sessionRef, row.MID, string(row.Outcome), row.ErrorCode, row.HTTPStatus, row.Latency.Microseconds(),
			row.RequestBytes, row.ResponseBytes, nullableText(row.ErrorClass), nullableText(row.Cause), row.RawEnvelope, row.RequestSHA256, row.Replay, string(row.Class),
			row.Class.ExpiresAt(row.ReceivedAt)}, nil
	}))
	return err
}

var purgedTables = []string{"request_journal", "client_log_rows", "client_log_uploads", "client_log_capabilities"}

// PurgeExpired deletes at most batch expired rows from each table. The R8 cap
// (U4) shortens each retention class' window to min(owner window, retention
// days); zero keeps the owner's windows alone.
func (s Store) PurgeExpired(ctx context.Context, now time.Time, retentionDays, batch int) (int64, error) {
	var total int64
	for _, table := range purgedTables {
		query := fmt.Sprintf(`DELETE FROM %[1]s WHERE ctid IN (SELECT ctid FROM %[1]s WHERE expires_at<=$1 LIMIT $2)`, table)
		arguments := []any{now, batch}
		if table != "client_log_capabilities" && retentionDays > 0 {
			routineCutoff := now.Add(-cappedWindow(domain.RoutineRetention, retentionDays))
			incidentCutoff := now.Add(-cappedWindow(domain.IncidentRetention, retentionDays))
			query = fmt.Sprintf(`DELETE FROM %[1]s WHERE ctid IN (
SELECT ctid FROM %[1]s
WHERE expires_at<=$1 OR (retention_class='ROUTINE' AND received_at<$2) OR (retention_class<>'ROUTINE' AND received_at<$3)
ORDER BY expires_at
LIMIT $4)`, table)
			arguments = []any{now, routineCutoff, incidentCutoff, batch}
		}
		tag, err := s.Pool.Exec(ctx, query, arguments...)
		if err != nil {
			return total, err
		}
		total += tag.RowsAffected()
	}
	return total, nil
}

func cappedWindow(ownerWindow time.Duration, retentionDays int) time.Duration {
	window := time.Duration(retentionDays) * 24 * time.Hour
	if window < ownerWindow {
		return window
	}
	return ownerWindow
}

// Timeline returns one uid's journal rows, uploads and client rows in time
// order as JSON objects (I85_REQUEST_JOURNAL_V1 R5).
func (s Store) Timeline(ctx context.Context, accountUID string, since time.Time, limit int) ([]json.RawMessage, error) {
	rows, err := s.Pool.Query(ctx, `SELECT entry FROM (
 SELECT received_at, 0 AS source, lpad(journal_id::text,20,'0') AS ordering, jsonb_build_object('source','journal','received_at',received_at,'player_id',player_id,'session_ref',session_ref,'mid',mid,'outcome',outcome,'error_code',error_code,'http_status',http_status,'latency_microseconds',latency_microseconds,'error_class',error_class,'cause',cause,'raw_envelope',encode(raw_envelope,'escape'),'replay',replay) AS entry
 FROM request_journal WHERE account_uid=$1 AND received_at>=$2
 UNION ALL
 SELECT received_at, 1, upload_id::text, jsonb_build_object('source','upload','received_at',received_at,'upload_id',upload_id,'kind',kind,'attribution',attribution,'status',status,'quarantine_reason',quarantine_reason,'retention_class',retention_class,'row_count',row_count,'attachment_name',attachment_name,'attachment_bytes',length(attachment))
 FROM client_log_uploads WHERE account_uid=$1 AND received_at>=$2
 UNION ALL
 SELECT received_at, 2, upload_id::text||':'||lpad(ordinal::text,6,'0'), jsonb_build_object('source','client_row','received_at',received_at,'upload_id',upload_id,'client_rowid',client_rowid,'client_time',client_time,'app_version',app_version,'version',version,'is_crash',is_crash,'dump',dump,'log',log,'truncated',truncated,'extras',extras,'retention_class',retention_class)
 FROM client_log_rows WHERE account_uid=$1 AND received_at>=$2
) timeline ORDER BY received_at, source, ordering LIMIT $3`, accountUID, since, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []json.RawMessage
	for rows.Next() {
		var entry []byte
		if err := rows.Scan(&entry); err != nil {
			return nil, err
		}
		out = append(out, entry)
	}
	return out, rows.Err()
}

const journalEntryColumns = `journal_id,received_at,player_id,session_ref,mid,outcome,error_code,http_status,latency_microseconds,error_class,cause,raw_envelope,replay`

// rawPGXTransaction is the pgx view of the foundation transaction. The port only
// exposes QueryRow, and this owner needs a bounded multi-row read.
type rawPGXTransaction interface{ RawPGX() pgx.Tx }

func rawTransaction(transaction tx.Tx) (pgx.Tx, error) {
	raw, ok := transaction.(rawPGXTransaction)
	if !ok {
		return nil, errors.New("clientlogstore: the transaction does not expose pgx")
	}
	return raw.RawPGX(), nil
}

func scanJournalEntry(row pgx.Row) (app.JournalEntry, error) {
	var entry app.JournalEntry
	var playerID *int64
	var sessionRef, errorClass, cause *string
	var mid *int
	var errorCode *int64
	var rawEnvelope []byte
	err := row.Scan(&entry.JournalID, &entry.ReceivedAt, &playerID, &sessionRef, &mid, &entry.Outcome, &errorCode,
		&entry.HTTPStatus, &entry.LatencyMicroseconds, &errorClass, &cause, &rawEnvelope, &entry.Replay)
	if err != nil {
		return app.JournalEntry{}, err
	}
	entry.PlayerID = playerID
	entry.SessionRef = sessionRef
	entry.MID = mid
	entry.ErrorCode = errorCode
	if errorClass != nil {
		entry.ErrorClass = *errorClass
	}
	if cause != nil {
		entry.Cause = *cause
	}
	entry.RawEnvelope = string(rawEnvelope)
	return entry, nil
}

// JournalPage returns one newest-first page of the request journal, bounded by
// the filter and the cursor (I85_REQUEST_JOURNAL_V1 R5, operator logs.timeline).
func (s Store) JournalPage(ctx context.Context, transaction tx.Tx, filter app.JournalFilter) ([]app.JournalEntry, error) {
	raw, err := rawTransaction(transaction)
	if err != nil {
		return nil, err
	}
	var cursorTime *time.Time
	if filter.Cursor.Present {
		cursorTime = &filter.Cursor.ReceivedAt
	}
	rows, err := raw.Query(ctx, `SELECT `+journalEntryColumns+`
FROM request_journal
WHERE ($1 = '' OR account_uid = $1)
AND ($2 = 0 OR player_id = $2)
AND ($3::timestamptz IS NULL OR received_at >= $3)
AND ($4::timestamptz IS NULL OR received_at <= $4)
AND (coalesce(cardinality($5::text[]), 0) = 0 OR outcome = ANY($5))
AND ($6 = 0 OR mid = $6)
AND ($7::timestamptz IS NULL OR (received_at, journal_id) < ($7::timestamptz, $8))
ORDER BY received_at DESC, journal_id DESC
LIMIT $9`,
		filter.AccountUID, filter.PlayerID, filter.From, filter.To, filter.Outcomes, filter.MID, cursorTime, filter.Cursor.JournalID, filter.Limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	entries := make([]app.JournalEntry, 0, filter.Limit)
	for rows.Next() {
		entry, scanErr := scanJournalEntry(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		entries = append(entries, entry)
	}
	return entries, rows.Err()
}

// JournalTail returns the rows newer than the cursor, oldest first for the live
// view (operator logs.tail).
func (s Store) JournalTail(ctx context.Context, transaction tx.Tx, filter app.JournalFilter) ([]app.JournalEntry, error) {
	raw, err := rawTransaction(transaction)
	if err != nil {
		return nil, err
	}
	var cursorTime *time.Time
	if filter.Cursor.Present {
		cursorTime = &filter.Cursor.ReceivedAt
	}
	rows, err := raw.Query(ctx, `SELECT `+journalEntryColumns+`
FROM request_journal
WHERE ($1 = '' OR account_uid = $1)
AND ($2 = 0 OR player_id = $2)
AND (coalesce(cardinality($3::text[]), 0) = 0 OR outcome = ANY($3))
AND ($4::timestamptz IS NULL OR (received_at, journal_id) > ($4::timestamptz, $5))
ORDER BY received_at ASC, journal_id ASC
LIMIT $6`,
		filter.AccountUID, filter.PlayerID, filter.Outcomes, cursorTime, filter.Cursor.JournalID, filter.Limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	entries := make([]app.JournalEntry, 0, filter.Limit)
	for rows.Next() {
		entry, scanErr := scanJournalEntry(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		entries = append(entries, entry)
	}
	return entries, rows.Err()
}

// ClearJournalTx deletes matching journal, upload and client rows in bounded
// batches, so an operator clear never runs one unbounded delete.
//
// shortcut: at most clearBatchSize batches per table per call, upgrade when logs outgrow that.
func (s Store) ClearJournalTx(ctx context.Context, transaction tx.Tx, filter app.ClearFilter, batch int) (int64, error) {
	if batch <= 0 {
		batch = 5000
	}
	tables := []string{"request_journal", "client_log_rows", "client_log_uploads"}
	var total int64
	for _, table := range tables {
		condition, arguments := clearCondition(filter)
		for range app.MaxClearBatches {
			query := fmt.Sprintf(`DELETE FROM %[1]s WHERE ctid IN (SELECT ctid FROM %[1]s WHERE %[2]s LIMIT $%[3]d)`, table, condition, len(arguments)+1)
			limited := append(append([]any(nil), arguments...), batch)
			tag, err := transaction.Exec(ctx, query, limited...)
			if err != nil {
				return total, err
			}
			total += tag.RowsAffected()
			if tag.RowsAffected() < int64(batch) {
				break
			}
		}
	}
	return total, nil
}

// clearCondition builds the shared delete predicate; all three log tables carry
// account_uid, player_id and received_at.
func clearCondition(filter app.ClearFilter) (string, []any) {
	if filter.Before != nil {
		return "received_at < $1", []any{*filter.Before}
	}
	if filter.AccountUID != "" && filter.PlayerID != 0 {
		return "(account_uid = $1 OR player_id = $2)", []any{filter.AccountUID, filter.PlayerID}
	}
	if filter.AccountUID != "" {
		return "account_uid = $1", []any{filter.AccountUID}
	}
	if filter.PlayerID != 0 {
		return "player_id = $1", []any{filter.PlayerID}
	}
	return "true", nil
}
