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
	"request_bytes", "response_bytes", "error_class", "cause", "raw_envelope", "request_sha256", "retention_class", "expires_at"}

func (s Store) SaveJournal(ctx context.Context, rows []app.JournalRow) error {
	_, err := s.Pool.CopyFrom(ctx, pgx.Identifier{"request_journal"}, journalColumns, pgx.CopyFromSlice(len(rows), func(index int) ([]any, error) {
		row := rows[index]
		accountUID, playerID, sessionRef := owned(row.Owner)
		return []any{row.ReceivedAt, accountUID, playerID, sessionRef, row.MID, string(row.Outcome), row.ErrorCode, row.HTTPStatus, row.Latency.Microseconds(),
			row.RequestBytes, row.ResponseBytes, nullableText(row.ErrorClass), nullableText(row.Cause), row.RawEnvelope, row.RequestSHA256, string(row.Class),
			row.Class.ExpiresAt(row.ReceivedAt)}, nil
	}))
	return err
}

var purgedTables = []string{"request_journal", "client_log_rows", "client_log_uploads", "client_log_capabilities"}

// PurgeExpired deletes at most batch expired rows from each table.
func (s Store) PurgeExpired(ctx context.Context, now time.Time, batch int) (int64, error) {
	var total int64
	for _, table := range purgedTables {
		tag, err := s.Pool.Exec(ctx, fmt.Sprintf(`DELETE FROM %[1]s WHERE ctid IN (SELECT ctid FROM %[1]s WHERE expires_at<=$1 LIMIT $2)`, table), now, batch)
		if err != nil {
			return total, err
		}
		total += tag.RowsAffected()
	}
	return total, nil
}

// Timeline returns one uid's journal rows, uploads and client rows in time
// order as JSON objects (I85_REQUEST_JOURNAL_V1 R5).
func (s Store) Timeline(ctx context.Context, accountUID string, since time.Time, limit int) ([]json.RawMessage, error) {
	rows, err := s.Pool.Query(ctx, `SELECT entry FROM (
 SELECT received_at, 0 AS source, lpad(journal_id::text,20,'0') AS ordering, jsonb_build_object('source','journal','received_at',received_at,'player_id',player_id,'session_ref',session_ref,'mid',mid,'outcome',outcome,'error_code',error_code,'http_status',http_status,'latency_microseconds',latency_microseconds,'error_class',error_class,'cause',cause,'raw_envelope',encode(raw_envelope,'escape')) AS entry
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
