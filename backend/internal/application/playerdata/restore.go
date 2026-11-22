package playerdata

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"sort"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ErrRestoreRefused marks an export the target database must not accept. The
// command answers it with exit 3 and one line naming the reason.
var ErrRestoreRefused = errors.New("restore refused")

// ErrInvalidExport marks a file that is not a player export document.
var ErrInvalidExport = errors.New("invalid player export")

// RestoreStore executes the generated plan against the canonical tables. Every
// write runs in the restore's single transaction.
type RestoreStore interface {
	GooseVersion(context.Context, tx.Queryer) (int64, error)
	PlayerServer(context.Context, tx.Queryer, int64) (int32, bool, error)
	SelectRows(context.Context, tx.Queryer, string, int64) ([]json.RawMessage, error)
	Columns(context.Context, tx.Queryer, string) ([]string, error)
	PrimaryKey(context.Context, tx.Queryer, string) ([]string, error)
	InboundReferences(context.Context, tx.Queryer, string) ([]InboundReference, error)
	DeleteUnreferenced(context.Context, tx.Tx, string, string, []InboundReference, int64) error
	ReferencedRow(context.Context, tx.Queryer, string, InboundReference, json.RawMessage) (string, bool, error)
	InsertRow(context.Context, tx.Tx, string, []string, json.RawMessage) error
	UpdateRow(context.Context, tx.Tx, string, []string, []string, json.RawMessage) error
	SetRowVersion(context.Context, tx.Tx, string, []string, json.RawMessage, int64, time.Time) error
	EndPlayerSessions(context.Context, tx.Tx, int64, time.Time) (int, error)
	LiveSessionIDsForPlayerTx(context.Context, tx.Queryer, int64) ([]identity.SessionID, error)
}

// PlayerRoots is the shared player root lock seam every player command takes.
type PlayerRoots interface {
	LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error)
}

// MediaBlobs verifies that each profile media blob the export references still exists.
type MediaBlobs interface {
	BlobExists(string) (bool, error)
}

type RestoreService struct {
	Database tx.Beginner
	Store    RestoreStore
	Roots    PlayerRoots
	Blobs    MediaBlobs
}

type RestoreResult struct {
	PlayerID        int64 `json:"player_id"`
	LogicalServerID int32 `json:"logical_server_id"`
	Tables          int   `json:"tables"`
	Inserted        int   `json:"inserted"`
	Updated         int   `json:"updated"`
	SessionsEnded   int   `json:"sessions_ended"`
}

type restoreTable struct {
	table      PlanTable
	primaryKey []string
	inbound    []InboundReference
	before     map[string]int64
	kept       map[string]bool
}

func refused(format string, arguments ...any) error {
	return fmt.Errorf("%w: %s", ErrRestoreRefused, fmt.Sprintf(format, arguments...))
}

// Decode reads one export document and refuses trailing data.
func Decode(reader io.Reader) (Document, error) {
	decoder := json.NewDecoder(reader)
	decoder.DisallowUnknownFields()
	var document Document
	if err := decoder.Decode(&document); err != nil {
		return Document{}, fmt.Errorf("%w: %v", ErrInvalidExport, err)
	}
	if err := decoder.Decode(new(any)); !errors.Is(err, io.EOF) {
		return Document{}, fmt.Errorf("%w: trailing data", ErrInvalidExport)
	}
	return document, nil
}

// Restore replaces the target player's restorable rows with the export, in one
// transaction: refusals first, the player's sessions end, the player root lock,
// deletes in reverse plan order, verbatim inserts in plan order, the version
// bump, then a live-session recheck. Sessions end before the root so the order
// matches gameplay (identity fence, then root) and cannot deadlock with it.
func (service RestoreService) Restore(ctx context.Context, plan Plan, planDigest string, targetPlayerID int64, document Document, at time.Time) (RestoreResult, error) {
	if service.Database == nil || service.Store == nil || service.Roots == nil {
		return RestoreResult{}, errors.New("player restore requires a database, store and root locker")
	}
	exportedServer, err := service.validate(plan, planDigest, targetPlayerID, document)
	if err != nil {
		return RestoreResult{}, err
	}
	if err := service.checkBlobs(document); err != nil {
		return RestoreResult{}, err
	}

	transaction, err := service.Database.Begin(ctx, tx.Options{})
	if err != nil {
		return RestoreResult{}, err
	}
	restored := false
	defer func() {
		if !restored {
			_ = transaction.Rollback(ctx)
		}
	}()

	schemaVersion, err := service.Store.GooseVersion(ctx, transaction)
	if err != nil {
		return RestoreResult{}, fmt.Errorf("read migration version: %w", err)
	}
	if document.SchemaVersion != schemaVersion {
		return RestoreResult{}, refused("export schema version %d, database schema version %d", document.SchemaVersion, schemaVersion)
	}
	targetServer, found, err := service.Store.PlayerServer(ctx, transaction, targetPlayerID)
	if err != nil {
		return RestoreResult{}, fmt.Errorf("read target player: %w", err)
	}
	if !found {
		return RestoreResult{}, refused("player %d not found", targetPlayerID)
	}
	if int32(exportedServer) != targetServer {
		return RestoreResult{}, refused("export is for server %d, player %d is on server %d", exportedServer, targetPlayerID, targetServer)
	}
	ended, err := service.Store.EndPlayerSessions(ctx, transaction, targetPlayerID, at)
	if err != nil {
		return RestoreResult{}, err
	}
	roots, err := service.Roots.LockPlayerRootsTx(ctx, transaction, identity.LogicalServerID(targetServer), []identity.PlayerID{identity.PlayerID(targetPlayerID)})
	if err != nil {
		return RestoreResult{}, err
	}
	if len(roots) != 1 || int64(roots[0].PlayerID) != targetPlayerID || roots[0].LogicalServerID != identity.LogicalServerID(targetServer) {
		return RestoreResult{}, refused("player %d is not on server %d", targetPlayerID, targetServer)
	}

	tables := make([]restoreTable, len(plan.Tables))
	for index, table := range plan.Tables {
		tables[index] = restoreTable{table: table}
	}
	exported := tableRowsByPlan(plan, document)
	if err := service.deleteRestorableRows(ctx, transaction, exported, targetPlayerID, tables); err != nil {
		return RestoreResult{}, err
	}
	result, err := service.insertExportedRows(ctx, transaction, exported, tables, at)
	if err != nil {
		return RestoreResult{}, err
	}
	if err := service.verifyExportedOwnership(ctx, transaction, exported, tables, targetPlayerID); err != nil {
		return RestoreResult{}, err
	}
	liveSessions, err := service.Store.LiveSessionIDsForPlayerTx(ctx, transaction, targetPlayerID)
	if err != nil {
		return RestoreResult{}, err
	}
	if len(liveSessions) != 0 {
		return RestoreResult{}, refused("player logged in during the restore; retry")
	}
	if err := transaction.Commit(ctx); err != nil {
		return RestoreResult{}, err
	}
	restored = true
	result.PlayerID = targetPlayerID
	result.LogicalServerID = int32(targetServer)
	result.Tables = countRestoreTables(plan)
	result.SessionsEnded = ended
	return result, nil
}

// validate checks the header and the plan binding before any table is touched.
func (service RestoreService) validate(plan Plan, planDigest string, targetPlayerID int64, document Document) (int32, error) {
	if document.Format != ExportFormat {
		return 0, refused("export format %d is not supported", document.Format)
	}
	if targetPlayerID <= 0 {
		return 0, refused("restore requires the target player")
	}
	if document.PlayerID != targetPlayerID {
		return 0, refused("export is for player %d, target is player %d", document.PlayerID, targetPlayerID)
	}
	if document.PlanSHA256 != planDigest {
		return 0, refused("export plan %s does not match the current plan %s", document.PlanSHA256, planDigest)
	}
	if len(document.Tables) != len(plan.Tables) {
		return 0, refused("export has %d tables, the plan has %d", len(document.Tables), len(plan.Tables))
	}
	for index, table := range plan.Tables {
		exported := document.Tables[index]
		if exported.Table != table.Table || exported.Action != table.Action {
			return 0, refused("export table %d is %s/%s, the plan says %s/%s", index, exported.Table, exported.Action, table.Table, table.Action)
		}
	}
	playerRow, err := exportedPlayerRow(document)
	if err != nil {
		return 0, err
	}
	var exportedPlayerID int64
	var exportedServer int32
	if err := json.Unmarshal(playerRow["player_id"], &exportedPlayerID); err != nil {
		return 0, refused("export players row has no player id")
	}
	if err := json.Unmarshal(playerRow["logical_server_id"], &exportedServer); err != nil {
		return 0, refused("export players row has no logical server")
	}
	if exportedPlayerID != targetPlayerID {
		return 0, refused("export players row is for player %d, target is player %d", exportedPlayerID, targetPlayerID)
	}
	if exportedServer != document.LogicalServerID {
		return 0, refused("export header says server %d but its players row says server %d", document.LogicalServerID, exportedServer)
	}
	keys, err := documentBlobKeys(document)
	if err != nil {
		return 0, err
	}
	if !equalStrings(keys, document.BlobKeys) {
		return 0, refused("export blob keys do not match its media history rows")
	}
	return document.LogicalServerID, nil
}

func (service RestoreService) checkBlobs(document Document) error {
	for _, key := range document.BlobKeys {
		if service.Blobs == nil {
			return refused("media blob %s cannot be verified without a profile media root", key)
		}
		exists, err := service.Blobs.BlobExists(key)
		if err != nil {
			return fmt.Errorf("verify media blob %s: %w", key, err)
		}
		if !exists {
			return refused("media blob %s is missing", key)
		}
	}
	return nil
}

// deleteRestorableRows deletes the player's current rows in reverse plan order,
// keeping every row another owner's row points at, and refuses an inbound
// reference whose row the export lacks.
func (service RestoreService) deleteRestorableRows(ctx context.Context, transaction tx.Tx, exported map[string][]json.RawMessage, playerID int64, tables []restoreTable) error {
	for index := len(tables) - 1; index >= 0; index-- {
		current := &tables[index]
		if current.table.Action != ActionRestore {
			continue
		}
		primaryKey, err := service.Store.PrimaryKey(ctx, transaction, current.table.Table)
		if err != nil {
			return fmt.Errorf("%s primary key: %w", current.table.Table, err)
		}
		if len(primaryKey) == 0 {
			return fmt.Errorf("plan table %s has no primary key", current.table.Table)
		}
		current.primaryKey = primaryKey
		// The catalog is authoritative: a restore-table row kept because some
		// other row points at it also keeps the parents it points at.
		inbound, err := service.Store.InboundReferences(ctx, transaction, current.table.Table)
		if err != nil {
			return fmt.Errorf("%s inbound keys: %w", current.table.Table, err)
		}
		current.inbound = inbound
		current.before = map[string]int64{}
		beforeRows, err := service.Store.SelectRows(ctx, transaction, current.table.Select, playerID)
		if err != nil {
			return fmt.Errorf("%s current rows: %w", current.table.Table, err)
		}
		for _, row := range beforeRows {
			key, err := rowKey(row, primaryKey)
			if err != nil {
				return fmt.Errorf("%s: %w", current.table.Table, err)
			}
			version, err := rowStateVersion(row, current.table.Versioned.StateVersion)
			if err != nil {
				return fmt.Errorf("%s: %w", current.table.Table, err)
			}
			current.before[key] = version
		}
		if err := service.Store.DeleteUnreferenced(ctx, transaction, current.table.Table, current.table.Select, current.inbound, playerID); err != nil {
			return fmt.Errorf("%s delete: %w", current.table.Table, err)
		}
		keptRows, err := service.Store.SelectRows(ctx, transaction, current.table.Select, playerID)
		if err != nil {
			return fmt.Errorf("%s kept rows: %w", current.table.Table, err)
		}
		exportedKeys, err := rowKeys(exported[current.table.Table], primaryKey, current.table.Table)
		if err != nil {
			return err
		}
		current.kept = map[string]bool{}
		for _, row := range keptRows {
			key, err := rowKey(row, primaryKey)
			if err != nil {
				return fmt.Errorf("%s: %w", current.table.Table, err)
			}
			if !exportedKeys[key] {
				reference, err := service.referencingRow(ctx, transaction, *current, row)
				if err != nil {
					return err
				}
				return refused("%s row %s is referenced by %s and the export lacks it", current.table.Table, keyLabel(key, primaryKey), reference)
			}
			current.kept[key] = true
		}
	}
	return nil
}

func (service RestoreService) referencingRow(ctx context.Context, transaction tx.Tx, table restoreTable, row json.RawMessage) (string, error) {
	for _, inbound := range table.inbound {
		reference, found, err := service.Store.ReferencedRow(ctx, transaction, table.table.Table, inbound, row)
		if err != nil {
			return "", fmt.Errorf("%s inbound %s: %w", table.table.Table, inbound.Constraint, err)
		}
		if found {
			return reference, nil
		}
	}
	return "another owner's row", nil
}

func (service RestoreService) insertExportedRows(ctx context.Context, transaction tx.Tx, exported map[string][]json.RawMessage, tables []restoreTable, at time.Time) (RestoreResult, error) {
	result := RestoreResult{}
	for index := range tables {
		current := &tables[index]
		if current.table.Action != ActionRestore {
			continue
		}
		columns, err := service.Store.Columns(ctx, transaction, current.table.Table)
		if err != nil {
			return RestoreResult{}, fmt.Errorf("%s columns: %w", current.table.Table, err)
		}
		if len(current.primaryKey) == 0 {
			primaryKey, err := service.Store.PrimaryKey(ctx, transaction, current.table.Table)
			if err != nil {
				return RestoreResult{}, fmt.Errorf("%s primary key: %w", current.table.Table, err)
			}
			current.primaryKey = primaryKey
		}
		for _, row := range exported[current.table.Table] {
			key, err := rowKey(row, current.primaryKey)
			if err != nil {
				return RestoreResult{}, fmt.Errorf("%s: %w", current.table.Table, err)
			}
			if current.kept[key] {
				err = service.Store.UpdateRow(ctx, transaction, current.table.Table, columns, current.primaryKey, row)
				result.Updated++
			} else {
				err = service.Store.InsertRow(ctx, transaction, current.table.Table, columns, row)
				result.Inserted++
			}
			if err != nil {
				return RestoreResult{}, fmt.Errorf("%s write: %w", current.table.Table, err)
			}
			if !current.table.Versioned.StateVersion && !current.table.Versioned.UpdatedAt {
				continue
			}
			restoredVersion, err := rowStateVersion(row, current.table.Versioned.StateVersion)
			if err != nil {
				return RestoreResult{}, fmt.Errorf("%s: %w", current.table.Table, err)
			}
			next := int64(0)
			if current.table.Versioned.StateVersion {
				next = current.before[key]
				if restoredVersion > next {
					next = restoredVersion
				}
				next++
			}
			updatedAt := time.Time{}
			if current.table.Versioned.UpdatedAt {
				updatedAt = at.UTC()
			}
			if err := service.Store.SetRowVersion(ctx, transaction, current.table.Table, current.primaryKey, row, next, updatedAt); err != nil {
				return RestoreResult{}, fmt.Errorf("%s version: %w", current.table.Table, err)
			}
		}
	}
	return result, nil
}

// verifyExportedOwnership refuses when an exported restore row is not selected
// for the target player by the plan's own predicate. It runs after the writes,
// so a foreign row is refused before the transaction commits, and a subset
// test, so rows kept by the inbound guard need not be exported.
func (service RestoreService) verifyExportedOwnership(ctx context.Context, transaction tx.Queryer, exported map[string][]json.RawMessage, tables []restoreTable, playerID int64) error {
	for index := range tables {
		current := &tables[index]
		if current.table.Action != ActionRestore {
			continue
		}
		rows := exported[current.table.Table]
		if len(rows) == 0 {
			continue
		}
		selected, err := service.Store.SelectRows(ctx, transaction, current.table.Select, playerID)
		if err != nil {
			return fmt.Errorf("%s restored rows: %w", current.table.Table, err)
		}
		owned, err := rowKeys(selected, current.primaryKey, current.table.Table)
		if err != nil {
			return err
		}
		for _, row := range rows {
			key, err := rowKey(row, current.primaryKey)
			if err != nil {
				return fmt.Errorf("%s: %w", current.table.Table, err)
			}
			if !owned[key] {
				return refused("%s row %s does not belong to player %d", current.table.Table, keyLabel(key, current.primaryKey), playerID)
			}
		}
	}
	return nil
}

func tableRowsByPlan(plan Plan, document Document) map[string][]json.RawMessage {
	out := make(map[string][]json.RawMessage, len(plan.Tables))
	for index, table := range plan.Tables {
		out[table.Table] = document.Tables[index].Rows
	}
	return out
}

func countRestoreTables(plan Plan) int {
	count := 0
	for _, table := range plan.Tables {
		if table.Action == ActionRestore {
			count++
		}
	}
	return count
}

func exportedPlayerRow(document Document) (map[string]json.RawMessage, error) {
	for _, table := range document.Tables {
		if table.Table != PlayersTable {
			continue
		}
		if len(table.Rows) != 1 {
			return nil, refused("export has %d %s rows, want 1", len(table.Rows), PlayersTable)
		}
		var row map[string]json.RawMessage
		if err := json.Unmarshal(table.Rows[0], &row); err != nil {
			return nil, refused("export %s row is not a JSON object", PlayersTable)
		}
		return row, nil
	}
	return nil, refused("export has no %s table", PlayersTable)
}

func documentBlobKeys(document Document) ([]string, error) {
	for _, table := range document.Tables {
		if table.Table != MediaHistoryTable {
			continue
		}
		keys, err := referencedBlobKeys(table.Rows)
		if err != nil {
			return nil, fmt.Errorf("%w: %v", ErrInvalidExport, err)
		}
		unique := make([]string, 0, len(keys))
		seen := map[string]bool{}
		for _, key := range keys {
			if seen[key] {
				continue
			}
			seen[key] = true
			unique = append(unique, key)
		}
		sort.Strings(unique)
		return unique, nil
	}
	return nil, nil
}

// rowKey identifies a row by its primary key values in raw JSON form. The
// generated export keeps one table's rows byte-stable, so equal keys are equal.
func rowKey(row json.RawMessage, columns []string) (string, error) {
	var fields map[string]json.RawMessage
	if err := json.Unmarshal(row, &fields); err != nil {
		return "", fmt.Errorf("%w: row is not a JSON object", ErrInvalidExport)
	}
	parts := make([]string, len(columns))
	for index, column := range columns {
		value, ok := fields[column]
		if !ok {
			return "", fmt.Errorf("%w: row has no primary key column %s", ErrInvalidExport, column)
		}
		parts[index] = string(value)
	}
	return strings.Join(parts, "\x1f"), nil
}

func rowKeys(rows []json.RawMessage, columns []string, table string) (map[string]bool, error) {
	keys := make(map[string]bool, len(rows))
	for _, row := range rows {
		key, err := rowKey(row, columns)
		if err != nil {
			return nil, fmt.Errorf("%s: %w", table, err)
		}
		keys[key] = true
	}
	return keys, nil
}

func keyLabel(key string, columns []string) string {
	values := strings.Split(key, "\x1f")
	parts := make([]string, 0, len(columns))
	for index, column := range columns {
		if index >= len(values) {
			break
		}
		parts = append(parts, column+"="+values[index])
	}
	return strings.Join(parts, ",")
}

func rowStateVersion(row json.RawMessage, versioned bool) (int64, error) {
	if !versioned {
		return 0, nil
	}
	var fields map[string]json.RawMessage
	if err := json.Unmarshal(row, &fields); err != nil {
		return 0, fmt.Errorf("%w: row is not a JSON object", ErrInvalidExport)
	}
	value, ok := fields["state_version"]
	if !ok {
		return 0, fmt.Errorf("%w: row has no state_version", ErrInvalidExport)
	}
	var version int64
	if err := json.Unmarshal(value, &version); err != nil {
		return 0, fmt.Errorf("%w: row state_version is not an integer", ErrInvalidExport)
	}
	return version, nil
}

func equalStrings(first, second []string) bool {
	if len(first) != len(second) {
		return false
	}
	for index := range first {
		if first[index] != second[index] {
			return false
		}
	}
	return true
}
