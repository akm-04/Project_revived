-- +goose Up
-- owner: ClientLog
-- I8.5-3 client observability (I85_CLIENT_LOG_INGEST_V1, I85_REQUEST_JOURNAL_V1,
-- I85_LOG_RETENTION_V1). Stock clients post errorlog rows and crash dumps to the
-- MID1 log_url; the per-session capability in that URL attributes them to a uid.
-- Every HTTP stock request leaves one journal row. Rows carry their retention
-- class and expiry (ROUTINE 7 days, ERROR/ANOMALY 30 days, D34). No foreign keys:
-- observation rows must never take locks on gameplay roots, and unattributed
-- rows have no owner.
CREATE TABLE client_log_capabilities (
 capability_digest bytea PRIMARY KEY CHECK(length(capability_digest)=32),
 account_uid text NOT NULL CHECK(account_uid<>''),
 player_id bigint NOT NULL,
 logical_server_id integer NOT NULL,
 session_ref text NOT NULL CHECK(length(session_ref)=32),
 issued_at timestamptz NOT NULL,
 expires_at timestamptz NOT NULL CHECK(expires_at>issued_at)
);
CREATE INDEX client_log_capabilities_expiry ON client_log_capabilities(expires_at);
CREATE TABLE client_log_uploads (
 upload_id uuid PRIMARY KEY,
 received_at timestamptz NOT NULL,
 kind smallint NOT NULL CHECK(kind IN (0,1)),
 account_uid text NULL,
 player_id bigint NULL,
 session_ref text NULL,
 attribution text NOT NULL CHECK(attribution IN ('CAPABILITY','TOKEN','UNATTRIBUTED_MISSING','UNATTRIBUTED_UNKNOWN','UNATTRIBUTED_EXPIRED')),
 status text NOT NULL CHECK(status IN ('PARSED','QUARANTINED')),
 quarantine_reason text NULL,
 retention_class text NOT NULL CHECK(retention_class IN ('ROUTINE','ERROR','ANOMALY')),
 body_bytes integer NOT NULL CHECK(body_bytes>=0),
 row_count integer NOT NULL CHECK(row_count>=0),
 app_version text NOT NULL DEFAULT '',
 version text NOT NULL DEFAULT '',
 attachment_name text NULL,
 attachment bytea NULL,
 attachment_truncated boolean NOT NULL DEFAULT false,
 expires_at timestamptz NOT NULL,
 CHECK((status='QUARANTINED')=(quarantine_reason IS NOT NULL)),
 CHECK((account_uid IS NULL)=(attribution LIKE 'UNATTRIBUTED%'))
);
CREATE INDEX client_log_uploads_uid_time ON client_log_uploads(account_uid, received_at);
CREATE INDEX client_log_uploads_expiry ON client_log_uploads(expires_at);
CREATE TABLE client_log_rows (
 upload_id uuid NOT NULL,
 ordinal integer NOT NULL CHECK(ordinal>=0),
 received_at timestamptz NOT NULL,
 account_uid text NULL,
 player_id bigint NULL,
 client_rowid bigint NULL,
 client_time bigint NULL,
 app_version text NOT NULL DEFAULT '',
 version text NOT NULL DEFAULT '',
 is_crash boolean NOT NULL,
 dump text NOT NULL DEFAULT '',
 log text NOT NULL DEFAULT '',
 truncated boolean NOT NULL DEFAULT false,
 extras jsonb NULL,
 retention_class text NOT NULL CHECK(retention_class IN ('ROUTINE','ERROR','ANOMALY')),
 expires_at timestamptz NOT NULL,
 PRIMARY KEY(upload_id, ordinal)
);
CREATE INDEX client_log_rows_uid_time ON client_log_rows(account_uid, received_at);
CREATE INDEX client_log_rows_expiry ON client_log_rows(expires_at);
CREATE TABLE request_journal (
 journal_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 received_at timestamptz NOT NULL,
 account_uid text NULL,
 player_id bigint NULL,
 session_ref text NULL,
 mid integer NULL CHECK(mid IS NULL OR mid BETWEEN 0 AND 65535),
 outcome text NOT NULL CHECK(outcome IN ('OK','CLIENT_ERROR','SERVER_ERROR','UNKNOWN_MID','UNDECODABLE')),
 error_code bigint NULL,
 http_status integer NOT NULL,
 latency_microseconds bigint NOT NULL CHECK(latency_microseconds>=0),
 request_bytes bigint NOT NULL CHECK(request_bytes>=0),
 response_bytes bigint NOT NULL CHECK(response_bytes>=0),
 error_class text NULL,
 cause text NULL,
 raw_envelope bytea NULL CHECK(raw_envelope IS NULL OR length(raw_envelope)<=16384),
 request_sha256 bytea NULL,
 retention_class text NOT NULL CHECK(retention_class IN ('ROUTINE','ERROR','ANOMALY')),
 expires_at timestamptz NOT NULL
);
CREATE INDEX request_journal_uid_time ON request_journal(account_uid, received_at);
CREATE INDEX request_journal_expiry ON request_journal(expires_at);
