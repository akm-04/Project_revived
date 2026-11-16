package playerdatastore

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/identitystore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/playerdata"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var _ playerdata.RestoreStore = Store{}

const (
	selectPlayerServer = `SELECT logical_server_id FROM players WHERE player_id=$1`
	selectColumns      = `SELECT COALESCE(jsonb_agg(column_name ORDER BY ordinal_position),'[]'::jsonb)::text FROM information_schema.columns WHERE table_schema='public' AND table_name=$1`
	selectPrimaryKey   = `SELECT COALESCE(jsonb_agg(attname ORDER BY position),'[]'::jsonb)::text FROM (SELECT a.attname,array_position(i.indkey::int2[],a.attnum::int2) AS position FROM pg_index i JOIN pg_attribute a ON a.attrelid=i.indrelid AND a.attnum=ANY(i.indkey) WHERE i.indrelid=to_regclass($1) AND i.indisprimary) keyed`
	selectInboundKeys  = `SELECT COALESCE(jsonb_agg(jsonb_build_object('constraint',conname,'table',child,'columns',child_columns,'references',parent_columns) ORDER BY conname),'[]'::jsonb)::text FROM (SELECT c.conname,c.conrelid::regclass::text AS child,jsonb_agg(a.attname ORDER BY s.ord) AS child_columns,jsonb_agg(fa.attname ORDER BY s.ord) AS parent_columns FROM pg_constraint c JOIN LATERAL generate_subscripts(c.conkey,1) s(ord) ON true JOIN pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=c.conkey[s.ord] JOIN pg_attribute fa ON fa.attrelid=c.confrelid AND fa.attnum=c.confkey[s.ord] WHERE c.contype='f' AND c.confrelid=to_regclass($1) GROUP BY c.conrelid,c.conname,c.conkey,c.confkey) keys`
)

func (Store) PlayerServer(ctx context.Context, query tx.Queryer, playerID int64) (int32, bool, error) {
	var server int32
	err := query.QueryRow(ctx, selectPlayerServer, playerID).Scan(&server)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return 0, false, nil
	}
	if err != nil {
		return 0, false, err
	}
	return server, true, nil
}

func (Store) Columns(ctx context.Context, query tx.Queryer, table string) ([]string, error) {
	return queryStrings(ctx, query, selectColumns, table)
}

func (Store) PrimaryKey(ctx context.Context, query tx.Queryer, table string) ([]string, error) {
	return queryStrings(ctx, query, selectPrimaryKey, table)
}

// InboundReferences lists every foreign key pointing at the table, including
// keys from restore tables whose surviving rows the delete must not break.
func (Store) InboundReferences(ctx context.Context, query tx.Queryer, table string) ([]playerdata.InboundReference, error) {
	var raw string
	if err := query.QueryRow(ctx, selectInboundKeys, table).Scan(&raw); err != nil {
		return nil, err
	}
	var references []playerdata.InboundReference
	if err := json.Unmarshal([]byte(raw), &references); err != nil {
		return nil, err
	}
	if references == nil {
		references = []playerdata.InboundReference{}
	}
	return references, nil
}

func queryStrings(ctx context.Context, query tx.Queryer, statement string, argument string) ([]string, error) {
	var raw string
	if err := query.QueryRow(ctx, statement, argument).Scan(&raw); err != nil {
		return nil, err
	}
	var values []string
	if err := json.Unmarshal([]byte(raw), &values); err != nil {
		return nil, err
	}
	if values == nil {
		values = []string{}
	}
	return values, nil
}

// DeleteUnreferenced turns the plan selection into a delete and excludes every
// row another owner's row still points at.
func (Store) DeleteUnreferenced(ctx context.Context, transaction tx.Tx, table, selection string, inbound []playerdata.InboundReference, playerID int64) error {
	statement, err := deleteStatement(selection, inbound)
	if err != nil {
		return fmt.Errorf("%s: %w", table, err)
	}
	_, err = transaction.Exec(ctx, statement, playerArgument(selection, playerID))
	return err
}

func deleteStatement(selection string, inbound []playerdata.InboundReference) (string, error) {
	const prefix = "SELECT * FROM "
	if !strings.HasPrefix(selection, prefix) {
		return "", errors.New("plan selection does not start with SELECT * FROM")
	}
	body := strings.TrimPrefix(selection, prefix)
	whereAt := strings.Index(body, " WHERE ")
	if whereAt < 0 {
		return "", errors.New("plan selection has no WHERE")
	}
	from := strings.TrimSpace(body[:whereAt])
	condition := body[whereAt+len(" WHERE "):]
	qualifier, err := selectionQualifier(from)
	if err != nil {
		return "", err
	}
	var builder strings.Builder
	builder.WriteString("DELETE FROM ")
	builder.WriteString(from)
	builder.WriteString(" WHERE (")
	builder.WriteString(condition)
	builder.WriteString(")")
	for _, key := range inbound {
		builder.WriteString(" AND NOT EXISTS (SELECT 1 FROM ")
		builder.WriteString(quoteIdentifier(key.Table))
		builder.WriteString(" i WHERE ")
		for index, column := range key.Columns {
			if index > 0 {
				builder.WriteString(" AND ")
			}
			builder.WriteString("i.")
			builder.WriteString(quoteIdentifier(column))
			builder.WriteString(" = ")
			builder.WriteString(qualifier)
			builder.WriteString(".")
			builder.WriteString(quoteIdentifier(key.References[index]))
		}
		builder.WriteString(")")
	}
	return builder.String(), nil
}

// selectionQualifier returns the name a delete uses for the selected table:
// its alias when the generated selection has one, else the quoted table name.
func selectionQualifier(from string) (string, error) {
	fields := strings.Fields(from)
	switch len(fields) {
	case 1:
		return fields[0], nil
	case 2:
		return fields[1], nil
	case 3:
		if fields[1] == "AS" {
			return fields[2], nil
		}
	}
	return "", errors.New("plan selection has an unexpected FROM clause")
}

// ReferencedRow names one row of another owner that points at the export row.
func (Store) ReferencedRow(ctx context.Context, query tx.Queryer, table string, inbound playerdata.InboundReference, row json.RawMessage) (string, bool, error) {
	conditions := make([]string, len(inbound.Columns))
	for index, column := range inbound.Columns {
		conditions[index] = "i." + quoteIdentifier(column) + " = r." + quoteIdentifier(inbound.References[index])
	}
	statement := "SELECT to_jsonb(i)::text FROM " + quoteIdentifier(inbound.Table) + " i JOIN jsonb_populate_record(NULL::" + quoteIdentifier(table) + ",$1::jsonb) r ON " + strings.Join(conditions, " AND ") + " LIMIT 1"
	var reference string
	err := query.QueryRow(ctx, statement, string(row)).Scan(&reference)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return "", false, nil
	}
	if err != nil {
		return "", false, err
	}
	return reference, true, nil
}

func (Store) InsertRow(ctx context.Context, transaction tx.Tx, table string, columns []string, row json.RawMessage) error {
	statement := "INSERT INTO " + quoteIdentifier(table) + " (" + quotedList(columns) + ") OVERRIDING SYSTEM VALUE SELECT " +
		quotedList(columns) + " FROM jsonb_populate_record(NULL::" + quoteIdentifier(table) + ",$1::jsonb)"
	_, err := transaction.Exec(ctx, statement, string(row))
	return err
}

func (Store) UpdateRow(ctx context.Context, transaction tx.Tx, table string, columns, primaryKey []string, row json.RawMessage) error {
	assignments := make([]string, len(columns))
	for index, column := range columns {
		assignments[index] = "s." + quoteIdentifier(column)
	}
	statement := "UPDATE " + quoteIdentifier(table) + " d SET (" + quotedList(columns) + ") = (" + strings.Join(assignments, ",") + ") FROM jsonb_populate_record(NULL::" +
		quoteIdentifier(table) + ",$1::jsonb) s WHERE " + keyCondition("d", "s", primaryKey)
	_, err := transaction.Exec(ctx, statement, string(row))
	return err
}

func (Store) SetRowVersion(ctx context.Context, transaction tx.Tx, table string, primaryKey []string, row json.RawMessage, stateVersion int64, updatedAt time.Time) error {
	sets := make([]string, 0, 2)
	arguments := []any{string(row)}
	if stateVersion > 0 {
		arguments = append(arguments, stateVersion)
		sets = append(sets, fmt.Sprintf("state_version=$%d", len(arguments)))
	}
	if !updatedAt.IsZero() {
		arguments = append(arguments, updatedAt.UTC())
		sets = append(sets, fmt.Sprintf("updated_at=$%d", len(arguments)))
	}
	if len(sets) == 0 {
		return nil
	}
	statement := "UPDATE " + quoteIdentifier(table) + " d SET " + strings.Join(sets, ",") + " FROM jsonb_populate_record(NULL::" +
		quoteIdentifier(table) + ",$1::jsonb) s WHERE " + keyCondition("d", "s", primaryKey)
	_, err := transaction.Exec(ctx, statement, arguments...)
	return err
}

// EndPlayerSessions ends every live session and context of the player through
// the identity lifecycle operations, so later bearer lookups fail like a
// revoked session (U6).
func (Store) EndPlayerSessions(ctx context.Context, transaction tx.Tx, playerID int64, at time.Time) (int, error) {
	sessions, err := (identitystore.Store{}).LiveSessionIDsForPlayerTx(ctx, transaction, identity.PlayerID(playerID))
	if err != nil {
		return 0, err
	}
	store := identitystore.Store{}
	ended := 0
	for _, sessionID := range sessions {
		session, err := store.LockSessionTx(ctx, transaction, sessionID)
		if err != nil {
			return 0, err
		}
		contextState, err := store.LockLiveContextTx(ctx, transaction, sessionID)
		if err != nil {
			return 0, err
		}
		plan, err := identity.RevokeSession(session, contextState, nil, nil, at, "player-data-restore")
		if err != nil {
			return 0, err
		}
		if plan.Session.LivenessVersion != session.LivenessVersion {
			if err := store.SaveRevokedSessionTx(ctx, transaction, plan.Session, session.LivenessVersion); err != nil {
				return 0, err
			}
		}
		if plan.Context != nil {
			if err := store.SaveEndedContextTx(ctx, transaction, *plan.Context, contextState.LivenessVersion); err != nil {
				return 0, err
			}
		}
		if err := store.RevokeSessionCredentialsTx(ctx, transaction, sessionID, at); err != nil {
			return 0, err
		}
		if err := store.RevokeGameplayCredentialsTx(ctx, transaction, sessionID, at); err != nil {
			return 0, err
		}
		ended++
	}
	return ended, nil
}

func keyCondition(first, second string, primaryKey []string) string {
	conditions := make([]string, len(primaryKey))
	for index, column := range primaryKey {
		conditions[index] = first + "." + quoteIdentifier(column) + " = " + second + "." + quoteIdentifier(column)
	}
	return strings.Join(conditions, " AND ")
}

func quotedList(columns []string) string {
	quoted := make([]string, len(columns))
	for index, column := range columns {
		quoted[index] = quoteIdentifier(column)
	}
	return strings.Join(quoted, ",")
}

func quoteIdentifier(identifier string) string {
	return `"` + strings.ReplaceAll(identifier, `"`, `""`) + `"`
}

// playerArgument matches the plan's pinned owner column type: receipts key a
// player by text owner_key, every other owner column is bigint.
func playerArgument(selection string, playerID int64) any {
	if strings.Contains(selection, "$1::text") {
		return fmt.Sprint(playerID)
	}
	return playerID
}
