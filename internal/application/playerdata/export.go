package playerdata

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/foundation/tx"
)

const ExportFormat = 1

const blobSuffix = ".png"

// Reader executes the generated plan's selections and reads the migration version.
type Reader interface {
	GooseVersion(context.Context, tx.Queryer) (int64, error)
	SelectRows(context.Context, tx.Queryer, string, int64) ([]json.RawMessage, error)
}

type Service struct {
	Database tx.Beginner
	Reader   Reader
}

type Document struct {
	Format          int         `json:"format"`
	SchemaVersion   int64       `json:"schema_version"`
	PlayerID        int64       `json:"player_id"`
	LogicalServerID int32       `json:"logical_server_id"`
	ExportedAt      time.Time   `json:"exported_at"`
	PlanSHA256      string      `json:"plan_sha256"`
	BlobKeys        []string    `json:"blob_keys"`
	Tables          []TableRows `json:"tables"`
}

type TableRows struct {
	Table  string            `json:"table"`
	Action string            `json:"action"`
	Rows   []json.RawMessage `json:"rows"`
}

// Export reads every plan table in one REPEATABLE READ READ ONLY transaction.
// Rows stay verbatim: they are the selected whole-row JSON, never a store decode.
func (service Service) Export(ctx context.Context, plan Plan, planDigest string, playerID int64, exportedAt time.Time) (Document, error) {
	if playerID <= 0 {
		return Document{}, fmt.Errorf("%w: invalid player id %d", ErrPlayerNotFound, playerID)
	}
	if service.Database == nil || service.Reader == nil {
		return Document{}, errors.New("player export requires a database and reader")
	}
	transaction, err := service.Database.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true})
	if err != nil {
		return Document{}, err
	}
	committed := false
	defer func() {
		if !committed {
			_ = transaction.Rollback(ctx)
		}
	}()

	schemaVersion, err := service.Reader.GooseVersion(ctx, transaction)
	if err != nil {
		return Document{}, fmt.Errorf("read migration version: %w", err)
	}
	document := Document{
		Format:        ExportFormat,
		SchemaVersion: schemaVersion,
		PlayerID:      playerID,
		ExportedAt:    exportedAt.UTC(),
		PlanSHA256:    planDigest,
		BlobKeys:      []string{},
		Tables:        make([]TableRows, 0, len(plan.Tables)),
	}
	blobKeys := map[string]bool{}
	for _, table := range plan.Tables {
		rows, err := service.Reader.SelectRows(ctx, transaction, table.Select, playerID)
		if err != nil {
			return Document{}, fmt.Errorf("%s: %w", table.Table, err)
		}
		if rows == nil {
			rows = []json.RawMessage{}
		}
		if table.Table == PlayersTable {
			if len(rows) == 0 {
				return Document{}, fmt.Errorf("%w: %d", ErrPlayerNotFound, playerID)
			}
			var header struct {
				LogicalServerID int32 `json:"logical_server_id"`
			}
			if err := json.Unmarshal(rows[0], &header); err != nil {
				return Document{}, fmt.Errorf("read player header: %w", err)
			}
			document.LogicalServerID = header.LogicalServerID
		}
		if table.Table == MediaHistoryTable {
			keys, err := referencedBlobKeys(rows)
			if err != nil {
				return Document{}, err
			}
			for _, key := range keys {
				blobKeys[key] = true
			}
		}
		document.Tables = append(document.Tables, TableRows{Table: table.Table, Action: table.Action, Rows: rows})
	}
	for key := range blobKeys {
		document.BlobKeys = append(document.BlobKeys, key)
	}
	sort.Strings(document.BlobKeys)

	if err := transaction.Commit(ctx); err != nil {
		return Document{}, err
	}
	committed = true
	return document, nil
}

// referencedBlobKeys maps each media history row's immutable asset to the
// ProfileAssetStore key blobs/<sha256>.png.
func referencedBlobKeys(rows []json.RawMessage) ([]string, error) {
	keys := make([]string, 0, len(rows))
	for _, raw := range rows {
		var row struct {
			Reference struct {
				Asset struct {
					SHA256 string `json:"sha256"`
				} `json:"asset"`
			} `json:"reference"`
		}
		if err := json.Unmarshal(raw, &row); err != nil {
			return nil, fmt.Errorf("read media history reference: %w", err)
		}
		if row.Reference.Asset.SHA256 == "" {
			return nil, errors.New("media history row has no asset digest")
		}
		keys = append(keys, row.Reference.Asset.SHA256+blobSuffix)
	}
	return keys, nil
}

func Encode(writer io.Writer, document Document) error {
	encoder := json.NewEncoder(writer)
	encoder.SetEscapeHTML(false)
	return encoder.Encode(document)
}
