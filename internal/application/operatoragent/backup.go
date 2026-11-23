package operatoragent

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"gxb.local/backend/v2/internal/application/operator"
)

const (
	// Backup environments and files.
	PostgresDSNVariable      = "GXB_POSTGRES_DSN"
	backupStateFileName      = "restore-state.json"
	backupPreRestoreFileName = "prerestore.json"
	backupPartialSuffix      = ".partial"
	backupDumpSuffix         = ".dump"
	backupManifestSuffix     = ".json"
	backupStampLayout        = "20060102T150405.000000000Z"

	BackupKindManual    = "manual"
	BackupKindSafety    = "safety"
	BackupKindPreUpdate = "pre-update"
	BackupKindPreDelete = "pre-delete"

	backupOperator = "root"
	// backupNameLimit is the G54 snapshot name length in characters.
	backupNameLimit = 80
)

var backupKinds = map[string]bool{
	BackupKindManual:    true,
	BackupKindSafety:    true,
	BackupKindPreUpdate: true,
	BackupKindPreDelete: true,
}

var backupIDPattern = regexp.MustCompile(`^[0-9]{8}T[0-9]{6}\.[0-9]{9}Z-(manual|safety|pre-update|pre-delete)$`)

// BackupManifest is <id>.json beside the dump (B2).
type BackupManifest struct {
	ID             string    `json:"id"`
	Kind           string    `json:"kind"`
	CreatedAt      time.Time `json:"created_at"`
	Database       string    `json:"database"`
	BackendVersion string    `json:"backend_version,omitempty"`
	BackendCommit  string    `json:"backend_commit,omitempty"`
	Migration      int64     `json:"migration"`
	Size           int64     `json:"size"`
	SHA256         string    `json:"sha256"`
	Reason         string    `json:"reason,omitempty"`
	Operator       string    `json:"operator,omitempty"`
	// Name and Pinned are the G54 keep mark: a pinned snapshot is never pruned
	// and stays out of every automatic step until it is unpinned.
	Name   string `json:"name,omitempty"`
	Pinned bool   `json:"pinned,omitempty"`
}

// BackupEntry is one list row: a manifest plus damage state and age.
type BackupEntry struct {
	BackupManifest
	Damaged       bool   `json:"damaged"`
	DamagedReason string `json:"damaged_reason,omitempty"`
	AgeSeconds    int64  `json:"age_seconds"`
}

// BackupList is backup.list (B3): newest first plus the newest age for the
// dashboard summary.
type BackupList struct {
	Directory        string        `json:"directory"`
	Keep             int           `json:"keep"`
	Backups          []BackupEntry `json:"backups"`
	NewestAgeSeconds *int64        `json:"newest_age_seconds"`
	// BackendMigration is the deployed backend's applied migration when it is
	// reachable; the restore dialog compares it with a snapshot's own number.
	BackendMigration *int64 `json:"backend_migration,omitempty"`
}

// PruneResult is backup.prune (B4).
type PruneResult struct {
	Keep              int      `json:"keep"`
	Removed           []string `json:"removed"`
	Kept              []string `json:"kept"`
	Damaged           []string `json:"damaged"`
	DroppedPreRestore string   `json:"dropped_prerestore,omitempty"`
}

// DatabaseTools is the pg toolchain port. The adapter resolves pg_dump,
// pg_restore and psql from the configured P2 folder or the agent's PATH.
type DatabaseTools interface {
	Dump(ctx context.Context, dsn, destination string) error
	VerifyDump(ctx context.Context, path string) error
	Restore(ctx context.Context, dsn, path string) error
	Execute(ctx context.Context, dsn, statement string) error
	Query(ctx context.Context, dsn, statement string) (string, error)
	Migrate(ctx context.Context, dsn, directory string) error
}

// BackupService runs the agent-side backup commands (B1-B7). It never opens
// the database itself: every statement goes through the pg toolchain.
type BackupService struct {
	Directory       string
	Keep            int
	EnvironmentFile string
	Tools           DatabaseTools
	ToolsError      error
	Operator        OperatorClient
	Backend         BackendControl
	Tokens          *TokenHolder
	Operations      *Operations
	Guard           *BackendGuard
	Log             *ToolLog
	Now             func() time.Time
	// MigrationsDirectory holds the forward-only goose migrations. It is
	// required only when a restore replaces an older snapshot than the deployed
	// backend's schema.
	MigrationsDirectory string
}

type restoreState struct {
	Phase      string    `json:"phase"`
	Database   string    `json:"database"`
	Restored   string    `json:"restored"`
	PreRestore string    `json:"pre_restore"`
	Stamp      string    `json:"stamp"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type preRestoreRetention struct {
	Database  string    `json:"database"`
	CreatedAt time.Time `json:"created_at"`
}

// Settings reports the effective backup settings (P3, B1).
func (service BackupService) Settings() BackupList {
	return BackupList{Directory: service.Directory, Keep: service.keep()}
}

func (service BackupService) keep() int {
	if service.Keep < 1 {
		return DefaultBackupKeep
	}
	return service.Keep
}

func (service BackupService) now() time.Time {
	if service.Now == nil {
		return time.Now()
	}
	return service.Now()
}

func (service BackupService) log(op, step, outcome string, detail any) {
	if service.Log == nil {
		return
	}
	service.Log.Write(op, step, outcome, detail)
}

// SnapshotOptions is one backup.snapshot request: the kind and reason plus the
// G54 optional name and keep mark.
type SnapshotOptions struct {
	Kind   string
	Reason string
	Name   string
	Pinned bool
}

// Snapshot takes a live pg_dump snapshot (B2). It is an Operations journal
// entry (L6) and prunes after success (B4).
func (service BackupService) Snapshot(ctx context.Context, options SnapshotOptions) (Operation, error) {
	if !backupKinds[options.Kind] {
		return Operation{}, Refuse(CodeBackupKindInvalid, "unknown backup kind")
	}
	name, err := normalizeSnapshotName(options.Name, options.Pinned)
	if err != nil {
		return Operation{}, err
	}
	if !service.Guard.TryLock() {
		return Operation{}, Refuse(CodeBackendBusy, "a backend operation is already running")
	}
	defer service.Guard.Unlock()
	return service.snapshot(ctx, options.Kind, options.Reason, name, options.Pinned)
}

// normalizeSnapshotName trims the G54 name and enforces 1-80 printable
// characters. An empty name is allowed only for a normal snapshot.
func normalizeSnapshotName(name string, pinned bool) (string, error) {
	trimmed := strings.TrimSpace(name)
	if trimmed == "" {
		if pinned {
			return "", Refuse(CodeBackupNameInvalid, "a pinned snapshot needs a name of 1 to 80 printable characters")
		}
		return "", nil
	}
	if utf8.RuneCountInString(trimmed) > backupNameLimit {
		return "", Refuse(CodeBackupNameInvalid, "the snapshot name must hold at most 80 characters")
	}
	for _, character := range trimmed {
		if !unicode.IsPrint(character) {
			return "", Refuse(CodeBackupNameInvalid, "the snapshot name must hold printable characters only")
		}
	}
	return trimmed, nil
}

// SnapshotBeforeDestructive is the one helper other operations call before a
// destructive step (B7); the caller already holds the backend guard.
func (service BackupService) SnapshotBeforeDestructive(ctx context.Context, reason string) (Operation, error) {
	return service.snapshot(ctx, BackupKindPreDelete, reason, "", false)
}

func (service BackupService) snapshot(ctx context.Context, kind, reason, name string, pinned bool) (Operation, error) {
	if err := service.ready(); err != nil {
		return Operation{}, err
	}
	dsn, err := service.dsn()
	if err != nil {
		return Operation{}, err
	}
	database, err := DatabaseNameFromDSN(dsn)
	if err != nil {
		return Operation{}, Refuse(CodeBackupDSNInvalid, "the backend DSN names no database")
	}
	id := service.now().UTC().Format(backupStampLayout) + "-" + kind
	partialPath := filepath.Join(service.Directory, id+backupDumpSuffix+backupPartialSuffix)
	dumpPath := filepath.Join(service.Directory, id+backupDumpSuffix)
	manifestPath := filepath.Join(service.Directory, id+backupManifestSuffix)

	var version operator.VersionInfo
	var manifest BackupManifest
	steps := []Step{
		{Name: "read backend version", Run: func(ctx context.Context) (any, error) {
			loaded, err := service.Operator.Version(ctx)
			if err != nil {
				return nil, err
			}
			version = loaded
			return map[string]any{"migration": loaded.Migration}, nil
		}},
		{Name: "dump database", Run: func(ctx context.Context) (any, error) {
			if err := service.Tools.Dump(ctx, dsn, partialPath); err != nil {
				return nil, Temporarily(CodeBackupToolFailed, MaskString(err.Error()))
			}
			return nil, nil
		}},
		{Name: "verify dump", Run: func(ctx context.Context) (any, error) {
			if err := service.Tools.VerifyDump(ctx, partialPath); err != nil {
				return nil, Temporarily(CodeBackupToolFailed, MaskString(err.Error()))
			}
			digest, size, err := digestFile(partialPath)
			if err != nil {
				return nil, Temporarily(CodeBackupFailed, "the dump cannot be read: "+err.Error())
			}
			if err := os.Rename(partialPath, dumpPath); err != nil {
				return nil, Temporarily(CodeBackupFailed, "the dump cannot be renamed: "+err.Error())
			}
			manifest = BackupManifest{
				ID:             id,
				Kind:           kind,
				CreatedAt:      service.now().UTC(),
				Database:       database,
				BackendVersion: stringValue(version.BackendVersion),
				BackendCommit:  stringValue(version.GitCommit),
				Migration:      version.Migration,
				Size:           size,
				SHA256:         digest,
				Reason:         reason,
				Operator:       backupOperator,
				Name:           name,
				Pinned:         pinned,
			}
			return map[string]any{"sha256": digest, "size": size}, nil
		}},
		{Name: "write manifest", Run: func(context.Context) (any, error) {
			if err := writeBackupManifest(manifestPath, manifest); err != nil {
				return nil, Temporarily(CodeBackupFailed, "the manifest cannot be written: "+err.Error())
			}
			return manifest, nil
		}},
		{Name: "prune", Run: func(ctx context.Context) (any, error) {
			pruned, err := service.prune(ctx)
			if err != nil {
				return nil, err
			}
			return map[string]any{"manifest": manifest, "prune": pruned}, nil
		}},
	}
	operation, err := service.Operations.RunKeyed(ctx, "backup.snapshot", "", snapshotRequest(kind, reason, name, pinned), steps)
	if err != nil {
		_ = os.Remove(partialPath)
		return operation, err
	}
	service.log("backup.snapshot", "finish", "done", map[string]any{"id": id, "size": manifest.Size, "pinned": pinned})
	return operation, nil
}

func snapshotRequest(kind, reason, name string, pinned bool) json.RawMessage {
	encoded, _ := json.Marshal(map[string]any{"kind": kind, "reason": reason, "name": name, "pin": pinned})
	return encoded
}

// List answers backup.list (B3). A dump without a manifest, or with a sha
// mismatch, is shown damaged and is never restored.
func (service BackupService) List(ctx context.Context) (BackupList, error) {
	entries, err := service.entries()
	if err != nil {
		return BackupList{}, err
	}
	list := BackupList{Directory: service.Directory, Keep: service.keep(), Backups: entries}
	if len(entries) > 0 && !entries[0].CreatedAt.IsZero() {
		age := int64(service.now().Sub(entries[0].CreatedAt).Seconds())
		if age < 0 {
			age = 0
		}
		list.NewestAgeSeconds = &age
	}
	return list, nil
}

// Pin names a snapshot and keeps it out of every future prune (G54). The
// manifest sidecar is replaced atomically, so an interrupted pin leaves the
// old manifest.
func (service BackupService) Pin(id, name string) (BackupManifest, error) {
	normalized, err := normalizeSnapshotName(name, true)
	if err != nil {
		return BackupManifest{}, err
	}
	manifest, err := service.keepableManifest(id)
	if err != nil {
		return BackupManifest{}, err
	}
	manifest.Name = normalized
	manifest.Pinned = true
	if err := writeBackupManifest(filepath.Join(service.Directory, id+backupManifestSuffix), manifest); err != nil {
		return BackupManifest{}, Temporarily(CodeBackupFailed, "the manifest cannot be written: "+err.Error())
	}
	service.log("backup.pin", "pin", "done", map[string]any{"id": id, "name": normalized})
	return manifest, nil
}

// Unpin returns a pinned snapshot to normal pruning; the name is kept.
func (service BackupService) Unpin(id string) (BackupManifest, error) {
	manifest, err := service.keepableManifest(id)
	if err != nil {
		return BackupManifest{}, err
	}
	manifest.Pinned = false
	if err := writeBackupManifest(filepath.Join(service.Directory, id+backupManifestSuffix), manifest); err != nil {
		return BackupManifest{}, Temporarily(CodeBackupFailed, "the manifest cannot be written: "+err.Error())
	}
	service.log("backup.pin", "unpin", "done", map[string]any{"id": id})
	return manifest, nil
}

// keepableManifest reads the manifest pin and unpin change. A dump without a
// readable manifest naming the id is unknown, never a newly invented manifest.
func (service BackupService) keepableManifest(id string) (BackupManifest, error) {
	if !backupIDPattern.MatchString(id) {
		return BackupManifest{}, Refuse(CodeBackupUnknown, "no such snapshot")
	}
	manifest, err := readBackupManifest(filepath.Join(service.Directory, id+backupManifestSuffix))
	if err != nil || manifest.ID != id {
		return BackupManifest{}, Refuse(CodeBackupUnknown, "no such snapshot")
	}
	return manifest, nil
}

// Prune keeps the newest backup_keep snapshots (B4), never deletes the newest,
// a pinned snapshot, a snapshot an unfinished operation references, or a
// damaged dump without listing it. It also drops a retained prerestore database
// once the backend is healthy again.
func (service BackupService) Prune(ctx context.Context) (Operation, error) {
	if !service.Guard.TryLock() {
		return Operation{}, Refuse(CodeBackendBusy, "a backend operation is already running")
	}
	defer service.Guard.Unlock()
	operation, err := service.Operations.Run(ctx, "backup.prune", []Step{
		{Name: "prune snapshots", Run: func(ctx context.Context) (any, error) {
			return service.prune(ctx)
		}},
	})
	return operation, err
}

func (service BackupService) prune(ctx context.Context) (PruneResult, error) {
	entries, err := service.entries()
	if err != nil {
		return PruneResult{}, err
	}
	referenced := service.runningRequestText()
	keep := service.keep()
	result := PruneResult{Keep: keep, Removed: []string{}, Kept: []string{}, Damaged: []string{}}
	for index, entry := range entries {
		protected := index == 0 || entry.Damaged || entry.Pinned || strings.Contains(referenced, entry.ID)
		if entry.Damaged {
			result.Damaged = append(result.Damaged, entry.ID)
		}
		if protected || index < keep {
			result.Kept = append(result.Kept, entry.ID)
			continue
		}
		if err := service.removeSnapshot(entry.ID); err != nil {
			return result, err
		}
		result.Removed = append(result.Removed, entry.ID)
	}
	dropped, err := service.dropRetainedPreRestore(ctx)
	if err != nil {
		return result, err
	}
	result.DroppedPreRestore = dropped
	return result, nil
}

func (service BackupService) removeSnapshot(id string) error {
	if !backupIDPattern.MatchString(id) {
		return nil
	}
	for _, suffix := range []string{backupDumpSuffix, backupManifestSuffix} {
		if err := os.Remove(filepath.Join(service.Directory, id+suffix)); err != nil && !errors.Is(err, os.ErrNotExist) {
			return err
		}
	}
	service.log("backup.prune", "remove", "done", map[string]any{"id": id})
	return nil
}

// runningRequestText returns the request text of every RUNNING operation; a
// prune never deletes a snapshot such an operation references.
func (service BackupService) runningRequestText() string {
	if service.Operations == nil {
		return ""
	}
	entries, err := os.ReadDir(service.Operations.Directory)
	if err != nil {
		return ""
	}
	var text strings.Builder
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != backupManifestSuffix {
			continue
		}
		contents, readErr := os.ReadFile(filepath.Join(service.Operations.Directory, entry.Name()))
		if readErr != nil {
			continue
		}
		var operation Operation
		if json.Unmarshal(contents, &operation) != nil || operation.State != OperationRunning {
			continue
		}
		text.Write(operation.Request)
	}
	return text.String()
}

func (service BackupService) entries() ([]BackupEntry, error) {
	directoryEntries, err := os.ReadDir(service.Directory)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return []BackupEntry{}, nil
		}
		return nil, err
	}
	seen := map[string]bool{}
	entries := make([]BackupEntry, 0, len(directoryEntries))
	for _, directoryEntry := range directoryEntries {
		if directoryEntry.IsDir() || filepath.Ext(directoryEntry.Name()) != backupDumpSuffix {
			continue
		}
		id := strings.TrimSuffix(directoryEntry.Name(), backupDumpSuffix)
		if !backupIDPattern.MatchString(id) {
			continue
		}
		seen[id] = true
		entries = append(entries, service.entry(id))
	}
	for _, directoryEntry := range directoryEntries {
		if directoryEntry.IsDir() || filepath.Ext(directoryEntry.Name()) != backupManifestSuffix {
			continue
		}
		id := strings.TrimSuffix(directoryEntry.Name(), backupManifestSuffix)
		if !backupIDPattern.MatchString(id) || seen[id] {
			continue
		}
		entries = append(entries, service.entry(id))
	}
	sort.SliceStable(entries, func(left, right int) bool {
		return entries[left].CreatedAt.After(entries[right].CreatedAt)
	})
	for index := range entries {
		if entries[index].CreatedAt.IsZero() {
			continue
		}
		age := int64(service.now().Sub(entries[index].CreatedAt).Seconds())
		if age < 0 {
			age = 0
		}
		entries[index].AgeSeconds = age
	}
	return entries, nil
}

func (service BackupService) entry(id string) BackupEntry {
	dumpPath := filepath.Join(service.Directory, id+backupDumpSuffix)
	manifestPath := filepath.Join(service.Directory, id+backupManifestSuffix)
	manifest, err := readBackupManifest(manifestPath)
	if err != nil {
		return BackupEntry{BackupManifest: BackupManifest{ID: id}, Damaged: true, DamagedReason: "the manifest is missing or unreadable"}
	}
	if manifest.ID != id {
		return BackupEntry{BackupManifest: BackupManifest{ID: id}, Damaged: true, DamagedReason: "the manifest names another snapshot"}
	}
	digest, size, err := digestFile(dumpPath)
	if err != nil {
		return BackupEntry{BackupManifest: manifest, Damaged: true, DamagedReason: "the dump is missing or unreadable"}
	}
	if digest != manifest.SHA256 || size != manifest.Size {
		return BackupEntry{BackupManifest: manifest, Damaged: true, DamagedReason: "the dump does not match the manifest"}
	}
	return BackupEntry{BackupManifest: manifest}
}

// Restore is B5: verify, safety snapshot, stop, restore into a new database,
// swap by rename, start and wait for health. A failure before the swap leaves
// the original database in place; a failure after it renames back. Every step
// is journaled (L6).
func (service BackupService) Restore(ctx context.Context, id, reason string) (Operation, error) {
	if !service.Guard.TryLock() {
		return Operation{}, Refuse(CodeBackendBusy, "a backend operation is already running")
	}
	defer service.Guard.Unlock()
	if err := service.ready(); err != nil {
		return Operation{}, err
	}
	manifest, dumpPath, err := service.verifySnapshot(id)
	if err != nil {
		return Operation{}, err
	}
	dsn, err := service.dsn()
	if err != nil {
		return Operation{}, err
	}
	adminDSN, err := AdminDSN(dsn)
	if err != nil {
		return Operation{}, Refuse(CodeBackupDSNInvalid, "the backend DSN names no database")
	}
	database, _ := DatabaseNameFromDSN(dsn)
	stamp := service.now().UTC().Format("20060102T150405")
	restoredDatabase := database + "_restore_" + stamp
	preRestoreDatabase := database + "_prerestore_" + stamp
	statePath := filepath.Join(service.Directory, backupStateFileName)
	safety := Operation{}
	swapped := false
	var deployedMigration int64
	var restoredDSN string

	steps := []Step{
		{Name: "verify snapshot", Run: func(ctx context.Context) (any, error) {
			deployed, err := service.Operator.Version(ctx)
			if err != nil {
				return nil, err
			}
			deployedMigration = deployed.Migration
			if manifest.Migration > deployed.Migration {
				return nil, Refuse(CodeBackupMigrationTooNew, fmt.Sprintf("the snapshot migration %d is newer than the deployed backend migration %d", manifest.Migration, deployed.Migration))
			}
			if manifest.Migration < deployed.Migration && service.MigrationsDirectory == "" {
				return nil, Refuse(CodeBackupToolsMissing, "the snapshot is older than the backend schema and the migrations folder is not configured")
			}
			return map[string]any{"migration": deployed.Migration, "snapshot_migration": manifest.Migration}, nil
		}},
		{Name: "safety snapshot", Run: func(ctx context.Context) (any, error) {
			operation, err := service.snapshot(ctx, BackupKindSafety, "before restore "+id, "", false)
			if err != nil {
				return nil, err
			}
			safety = operation
			return operation.Result, nil
		}},
		{Name: "stop backend", Run: func(context.Context) (any, error) {
			return nil, service.Backend.Stop()
		}},
		{Name: "restore into new database", Run: func(ctx context.Context) (any, error) {
			state := restoreState{Phase: "restoring", Database: database, Restored: restoredDatabase, PreRestore: preRestoreDatabase, Stamp: stamp, UpdatedAt: service.now().UTC()}
			if err := service.writeState(statePath, state); err != nil {
				return nil, err
			}
			if err := service.Tools.Execute(ctx, adminDSN, `CREATE DATABASE "`+restoredDatabase+`"`); err != nil {
				_ = os.Remove(statePath)
				service.startOriginal()
				return nil, Temporarily(CodeBackupToolFailed, MaskString(err.Error()))
			}
			candidate, err := DSNWithDatabase(dsn, restoredDatabase)
			if err != nil {
				return nil, Refuse(CodeBackupDSNInvalid, "the backend DSN cannot name another database")
			}
			restoredDSN = candidate
			if err := service.Tools.Restore(ctx, restoredDSN, dumpPath); err != nil {
				_ = service.Tools.Execute(ctx, adminDSN, `DROP DATABASE IF EXISTS "`+restoredDatabase+`"`)
				_ = os.Remove(statePath)
				service.startOriginal()
				return nil, Temporarily(CodeBackupToolFailed, MaskString(err.Error()))
			}
			return map[string]any{"database": restoredDatabase}, nil
		}},
		{Name: "migrate restored database", Run: func(ctx context.Context) (any, error) {
			if manifest.Migration >= deployedMigration {
				return map[string]any{"migration": manifest.Migration}, nil
			}
			if err := service.Tools.Migrate(ctx, restoredDSN, service.MigrationsDirectory); err != nil {
				_ = service.Tools.Execute(ctx, adminDSN, `DROP DATABASE IF EXISTS "`+restoredDatabase+`"`)
				_ = os.Remove(statePath)
				service.startOriginal()
				return nil, Temporarily(CodeBackupToolFailed, MaskString(err.Error()))
			}
			service.log("backup.restore", "migrate", "done", map[string]any{"snapshot_migration": manifest.Migration, "deployment_migration": deployedMigration})
			return map[string]any{"from": manifest.Migration, "to": deployedMigration}, nil
		}},
		{Name: "swap databases", Run: func(ctx context.Context) (any, error) {
			state := restoreState{Phase: "swapping", Database: database, Restored: restoredDatabase, PreRestore: preRestoreDatabase, Stamp: stamp, UpdatedAt: service.now().UTC()}
			if err := service.writeState(statePath, state); err != nil {
				_ = os.Remove(statePath)
				service.startOriginal()
				return nil, err
			}
			if err := service.renameDatabase(ctx, adminDSN, database, preRestoreDatabase); err != nil {
				_ = os.Remove(statePath)
				service.startOriginal()
				return nil, Temporarily(CodeBackupToolFailed, MaskString(err.Error()))
			}
			if err := service.renameDatabase(ctx, adminDSN, restoredDatabase, database); err != nil {
				if rollbackErr := service.renameDatabase(ctx, adminDSN, preRestoreDatabase, database); rollbackErr != nil {
					return nil, Temporarily(CodeBackupRestoreRefused, "the swap failed and the original database could not be renamed back; an agent restart finishes recovery")
				}
				_ = os.Remove(statePath)
				service.startOriginal()
				return nil, Temporarily(CodeBackupToolFailed, MaskString(err.Error()))
			}
			swapped = true
			state.Phase = "swapped"
			state.UpdatedAt = service.now().UTC()
			_ = service.writeState(statePath, state)
			return map[string]any{"database": database}, nil
		}},
		{Name: "start backend and wait", Run: func(ctx context.Context) (any, error) {
			if err := StartBackend(service.Backend, service.Tokens, false); err != nil {
				if rollbackErr := service.rollbackSwap(ctx, adminDSN, database, preRestoreDatabase, stamp); rollbackErr != nil {
					return nil, Temporarily(CodeBackupRestoreRefused, "the restored database did not start and the rollback failed; an agent restart finishes recovery")
				}
				return nil, err
			}
			if err := service.writePreRestoreRetention(preRestoreDatabase); err != nil {
				return nil, err
			}
			_ = os.Remove(statePath)
			return map[string]any{"database": database, "safety_snapshot": safety.ID}, nil
		}},
	}
	operation, err := service.Operations.RunKeyed(ctx, "backup.restore", "", restoreRequest(id, reason), steps)
	if err != nil && swapped && operation.FailedStep == "start backend and wait" {
		service.log("backup.restore", "rollback", "failed", map[string]any{"id": id})
	}
	return operation, err
}

func (service BackupService) rollbackSwap(ctx context.Context, adminDSN, database, preRestoreDatabase, stamp string) error {
	_ = service.Backend.Stop()
	failedDatabase := database + "_failed_" + stamp
	if err := service.renameDatabase(ctx, adminDSN, database, failedDatabase); err != nil {
		return err
	}
	if err := service.renameDatabase(ctx, adminDSN, preRestoreDatabase, database); err != nil {
		return err
	}
	return service.startOriginal()
}

func (service BackupService) startOriginal() error {
	return StartBackend(service.Backend, service.Tokens, false)
}

func (service BackupService) renameDatabase(ctx context.Context, adminDSN, from, to string) error {
	if err := service.Tools.Execute(ctx, adminDSN, terminateConnections(from)); err != nil {
		return err
	}
	return service.Tools.Execute(ctx, adminDSN, `ALTER DATABASE "`+from+`" RENAME TO "`+to+`"`)
}

func terminateConnections(database string) string {
	return `SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '` + strings.ReplaceAll(database, "'", "''") + `' AND pid <> pg_backend_pid()`
}

// UpdateBackend is B6: a pre-update snapshot plus a backend stop; the operator
// swaps the binary and presses Start.
func (service BackupService) UpdateBackend(ctx context.Context, reason string) (Operation, error) {
	if !service.Guard.TryLock() {
		return Operation{}, Refuse(CodeBackendBusy, "a backend operation is already running")
	}
	defer service.Guard.Unlock()
	if err := service.ready(); err != nil {
		return Operation{}, err
	}
	steps := []Step{
		{Name: "pre-update snapshot", Run: func(ctx context.Context) (any, error) {
			operation, err := service.snapshot(ctx, BackupKindPreUpdate, reason, "", false)
			if err != nil {
				return nil, err
			}
			return operation.Result, nil
		}},
		{Name: "stop backend", Run: func(context.Context) (any, error) {
			return nil, service.Backend.Stop()
		}},
		{Name: "swap the binary", Run: func(context.Context) (any, error) {
			return map[string]string{"next": "swap the backend binary, then start the backend"}, nil
		}},
	}
	return service.Operations.RunKeyed(ctx, "backup.update_backend", "", snapshotRequest("", reason, "", false), steps)
}

func (service BackupService) ready() error {
	if service.Tools == nil {
		if service.ToolsError != nil {
			return Refuse(CodeBackupToolsMissing, "the pg toolchain is unavailable: "+MaskString(service.ToolsError.Error()))
		}
		return Refuse(CodeBackupToolsMissing, "the pg toolchain is unavailable")
	}
	if service.Operations == nil {
		return Temporarily(CodeBackupFailed, "the operations journal is unavailable")
	}
	return nil
}

func (service BackupService) dsn() (string, error) {
	if service.EnvironmentFile != "" {
		lines, err := ReadEnvFile(service.EnvironmentFile)
		if err != nil {
			return "", Temporarily(CodeBackupDSNMissing, "the backend env file is unreadable")
		}
		for _, line := range lines {
			key, value, found := strings.Cut(line, "=")
			if found && key == PostgresDSNVariable && value != "" {
				return value, nil
			}
		}
	}
	if value := os.Getenv(PostgresDSNVariable); value != "" {
		return value, nil
	}
	return "", Refuse(CodeBackupDSNMissing, "the backend DSN is not configured")
}

func (service BackupService) verifySnapshot(id string) (BackupManifest, string, error) {
	if !backupIDPattern.MatchString(id) {
		return BackupManifest{}, "", Refuse(CodeBackupUnknown, "no such snapshot")
	}
	manifest, err := readBackupManifest(filepath.Join(service.Directory, id+backupManifestSuffix))
	if err != nil {
		return BackupManifest{}, "", Refuse(CodeBackupUnknown, "no such snapshot")
	}
	dumpPath := filepath.Join(service.Directory, id+backupDumpSuffix)
	digest, size, err := digestFile(dumpPath)
	if err != nil {
		return BackupManifest{}, "", Refuse(CodeBackupDamaged, "the snapshot dump is unreadable")
	}
	if digest != manifest.SHA256 || size != manifest.Size {
		return BackupManifest{}, "", Refuse(CodeBackupDamaged, "the snapshot does not match its manifest")
	}
	return manifest, dumpPath, nil
}

func (service BackupService) writeState(path string, state restoreState) error {
	encoded, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return err
	}
	if err := writeOperationRecord(path, encoded); err != nil {
		return Temporarily(CodeBackupFailed, "the restore state cannot be written: "+err.Error())
	}
	return nil
}

func (service BackupService) writePreRestoreRetention(database string) error {
	encoded, err := json.MarshalIndent(preRestoreRetention{Database: database, CreatedAt: service.now().UTC()}, "", "  ")
	if err != nil {
		return err
	}
	return writeOperationRecord(filepath.Join(service.Directory, backupPreRestoreFileName), encoded)
}

// dropRetainedPreRestore drops the prerestore database only after the backend
// is running healthy; otherwise it keeps the marker for the next prune.
func (service BackupService) dropRetainedPreRestore(ctx context.Context) (string, error) {
	path := filepath.Join(service.Directory, backupPreRestoreFileName)
	contents, err := os.ReadFile(path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return "", nil
		}
		return "", err
	}
	var retention preRestoreRetention
	if json.Unmarshal(contents, &retention) != nil || retention.Database == "" {
		return "", os.Remove(path)
	}
	if service.Backend == nil || !service.Backend.Status().Running {
		return "", nil
	}
	dsn, err := service.dsn()
	if err != nil {
		return "", err
	}
	adminDSN, err := AdminDSN(dsn)
	if err != nil {
		return "", err
	}
	if err := service.Tools.Execute(ctx, adminDSN, `DROP DATABASE IF EXISTS "`+retention.Database+`"`); err != nil {
		return "", Temporarily(CodeBackupToolFailed, MaskString(err.Error()))
	}
	if err := os.Remove(path); err != nil {
		return "", err
	}
	service.log("backup.prune", "drop_prerestore", "done", map[string]any{"database": retention.Database})
	return retention.Database, nil
}

// RecoverRestore finishes a restore interrupted by an agent restart. It
// leaves the database in one known state: the original serving (rollback) or
// the restored database mounted with the prerestore retained.
func (service BackupService) RecoverRestore(ctx context.Context) error {
	path := filepath.Join(service.Directory, backupStateFileName)
	contents, err := os.ReadFile(path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil
		}
		return err
	}
	var state restoreState
	if err := json.Unmarshal(contents, &state); err != nil {
		return os.Remove(path)
	}
	if service.Tools == nil {
		return Refuse(CodeBackupToolsMissing, "a restore was interrupted and the pg toolchain is unavailable")
	}
	dsn, err := service.dsn()
	if err != nil {
		return err
	}
	adminDSN, err := AdminDSN(dsn)
	if err != nil {
		return err
	}
	switch state.Phase {
	case "restoring":
		if err := service.dropDatabase(ctx, adminDSN, state.Restored); err != nil {
			return err
		}
	case "swapping":
		databaseExists, err := service.databaseExists(ctx, adminDSN, state.Database)
		if err != nil {
			return err
		}
		if err := service.dropDatabase(ctx, adminDSN, state.Restored); err != nil {
			return err
		}
		if !databaseExists {
			if err := service.renameDatabase(ctx, adminDSN, state.PreRestore, state.Database); err != nil {
				return err
			}
		}
	case "swapped":
		databaseExists, err := service.databaseExists(ctx, adminDSN, state.Database)
		if err != nil {
			return err
		}
		if databaseExists {
			if err := service.writePreRestoreRetention(state.PreRestore); err != nil {
				return err
			}
		} else if err := service.renameDatabase(ctx, adminDSN, state.PreRestore, state.Database); err != nil {
			return err
		}
	default:
		return fmt.Errorf("unknown restore phase %q", state.Phase)
	}
	_ = service.dropDatabase(ctx, adminDSN, state.Database+"_failed_"+state.Stamp)
	if err := os.Remove(path); err != nil {
		return err
	}
	service.log("backup.restore", "recover", "done", map[string]any{"phase": state.Phase})
	return nil
}

func (service BackupService) dropDatabase(ctx context.Context, adminDSN, database string) error {
	if err := service.Tools.Execute(ctx, adminDSN, terminateConnections(database)); err != nil {
		return err
	}
	return service.Tools.Execute(ctx, adminDSN, `DROP DATABASE IF EXISTS "`+database+`"`)
}

func (service BackupService) databaseExists(ctx context.Context, adminDSN, database string) (bool, error) {
	answer, err := service.Tools.Query(ctx, adminDSN, `SELECT 1 FROM pg_database WHERE datname = '`+strings.ReplaceAll(database, "'", "''")+`'`)
	if err != nil {
		return false, err
	}
	return strings.TrimSpace(answer) == "1", nil
}

// DatabaseNameFromDSN reads the database name from a URL or key/value DSN.
// Error text never quotes the DSN.
func DatabaseNameFromDSN(dsn string) (string, error) {
	if strings.Contains(dsn, "://") {
		parsed, err := url.Parse(dsn)
		if err != nil {
			return "", errors.New("the DSN is not a URL")
		}
		name := strings.TrimPrefix(parsed.Path, "/")
		if name == "" {
			return "", errors.New("the DSN names no database")
		}
		return name, nil
	}
	for _, field := range strings.Fields(dsn) {
		key, value, found := strings.Cut(field, "=")
		if found && key == "dbname" && value != "" {
			return strings.Trim(value, `'"`), nil
		}
	}
	return "", errors.New("the DSN names no database")
}

// DSNWithDatabase returns the DSN pointed at another database on the same
// server (the restore and prerestore names).
func DSNWithDatabase(dsn, database string) (string, error) {
	if strings.Contains(dsn, "://") {
		parsed, err := url.Parse(dsn)
		if err != nil {
			return "", errors.New("the DSN is not a URL")
		}
		parsed.Path = "/" + database
		return parsed.String(), nil
	}
	fields := strings.Fields(dsn)
	replaced := make([]string, 0, len(fields)+1)
	found := false
	for _, field := range fields {
		key, _, isPair := strings.Cut(field, "=")
		if isPair && key == "dbname" {
			replaced = append(replaced, "dbname="+database)
			found = true
			continue
		}
		replaced = append(replaced, field)
	}
	if !found {
		return "", errors.New("the DSN names no database")
	}
	return strings.Join(replaced, " "), nil
}

// AdminDSN points the DSN at the maintenance database for CREATE, RENAME and
// DROP database statements.
func AdminDSN(dsn string) (string, error) {
	if _, err := DatabaseNameFromDSN(dsn); err != nil {
		return "", err
	}
	return DSNWithDatabase(dsn, "postgres")
}

func stringValue(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}

func digestFile(path string) (string, int64, error) {
	file, err := os.Open(path)
	if err != nil {
		return "", 0, err
	}
	defer file.Close()
	hash := sha256.New()
	size, err := io.Copy(hash, file)
	if err != nil {
		return "", 0, err
	}
	return hex.EncodeToString(hash.Sum(nil)), size, nil
}

func readBackupManifest(path string) (BackupManifest, error) {
	contents, err := os.ReadFile(path)
	if err != nil {
		return BackupManifest{}, err
	}
	var manifest BackupManifest
	if err := json.Unmarshal(contents, &manifest); err != nil {
		return BackupManifest{}, err
	}
	return manifest, nil
}

func writeBackupManifest(path string, manifest BackupManifest) error {
	encoded, err := json.MarshalIndent(manifest, "", "  ")
	if err != nil {
		return err
	}
	return writeOperationRecord(path, encoded)
}

func restoreRequest(id, reason string) json.RawMessage {
	encoded, _ := json.Marshal(map[string]string{"id": id, "reason": reason})
	return encoded
}
