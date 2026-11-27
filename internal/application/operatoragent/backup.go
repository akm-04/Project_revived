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
	"strconv"
	"strings"
	"sync"
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
	BackupKindScheduled = "scheduled"

	backupOperator = "root"
	// backupNameLimit is the G54 snapshot name length in characters.
	backupNameLimit = 80
)

var backupKinds = map[string]bool{
	BackupKindManual:    true,
	BackupKindSafety:    true,
	BackupKindPreUpdate: true,
	BackupKindPreDelete: true,
	BackupKindScheduled: true,
}

var backupIDPattern = regexp.MustCompile(`^[0-9]{8}T[0-9]{6}\.[0-9]{9}Z-(manual|safety|pre-update|pre-delete|scheduled)$`)

// backupScheduleTick bounds how often the schedule asks whether a snapshot is
// due; the interval itself is measured from the newest automatic snapshot.
const backupScheduleTick = time.Minute

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
	// Accounts, Players and NewestAccountCreatedAt are the pre-dump facts S2.2
	// records, so the restore preview can name what the snapshot does not hold.
	Accounts               int64      `json:"accounts"`
	Players                int64      `json:"players"`
	NewestAccountCreatedAt *time.Time `json:"newest_account_created_at,omitempty"`
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
	Schedule         string        `json:"schedule"`
	Backups          []BackupEntry `json:"backups"`
	NewestAgeSeconds *int64        `json:"newest_age_seconds"`
	// BackendMigration is the deployed backend's applied migration when it is
	// reachable; the restore dialog compares it with a snapshot's own number.
	BackendMigration *int64 `json:"backend_migration,omitempty"`
	// KeepPrune maps each selectable keep value to the automatic snapshots
	// lowering to it would remove, so the GUI confirm does not re-derive the
	// prune rule from the snapshot list.
	KeepPrune map[string]int `json:"keep_prune,omitempty"`
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

// JournalFlusher writes the client-log journal rows queued so far; flushing is
// best effort and a failure is logged, never fatal (S2.3).
type JournalFlusher interface {
	FlushJournal(context.Context) error
}

// snapshotFacts is the pre-dump account state recorded in the manifest.
type snapshotFacts struct {
	Accounts               int64
	Players                int64
	NewestAccountCreatedAt *time.Time
}

// BackupService runs the agent-side backup commands (B1-B7). It never opens
// the database itself: every statement goes through the pg toolchain.
type BackupService struct {
	Directory string
	// Root is the agent root; setting the backup folder, the keep value or the
	// schedule persists it in <root>/agent.json.
	Root string
	Keep int
	// Schedule is the scheduled automatic snapshot interval; nil is the default
	// 24h and a non-nil zero turns the schedule off.
	Schedule        *time.Duration
	Max             int
	EnvironmentFile string
	Tools           DatabaseTools
	ToolsError      error
	Operator        OperatorClient
	Backend         BackendControl
	Tokens          *TokenHolder
	Operations      *Operations
	Guard           *BackendGuard
	Log             *ToolLog
	// Journal is the client-log journal flush S2.3 runs before a manual or
	// scheduled snapshot; nil skips it.
	Journal JournalFlusher
	Now     func() time.Time
	// MigrationsDirectory holds the forward-only goose migrations. It is
	// required only when a restore replaces an older snapshot than the deployed
	// backend's schema. It is a captured value; production sets ConfigRoot
	// instead, so each restore reads agent.json again.
	MigrationsDirectory string
	// ConfigRoot is the agent root holding agent.json; every restore resolves
	// backend.migrations_dir from it.
	ConfigRoot string
	// settingsLock guards Directory, Keep and Schedule: the HTTP handlers set
	// them while the schedule goroutine reads them at every tick. Every method
	// has a pointer receiver, so the lock is never copied.
	settingsLock sync.RWMutex
}

func (service *BackupService) lockSettingsRead() func() {
	service.settingsLock.RLock()
	return service.settingsLock.RUnlock
}

func (service *BackupService) lockSettingsWrite() func() {
	service.settingsLock.Lock()
	return service.settingsLock.Unlock
}

func (service *BackupService) directory() string {
	unlock := service.lockSettingsRead()
	defer unlock()
	return service.Directory
}

func (service *BackupService) writeDirectory(directory string) {
	unlock := service.lockSettingsWrite()
	defer unlock()
	service.Directory = directory
}

func (service *BackupService) writeSchedule(interval time.Duration) {
	unlock := service.lockSettingsWrite()
	defer unlock()
	service.Schedule = &interval
}

func (service *BackupService) writeKeep(keep int) {
	unlock := service.lockSettingsWrite()
	defer unlock()
	service.Keep = keep
}

// migrationsDirectory resolves the forward-migration folder at restore time, so
// a backend.migrations_dir changed in agent.json applies without an agent
// restart.
func (service *BackupService) migrationsDirectory() (string, error) {
	if service.ConfigRoot == "" {
		return service.MigrationsDirectory, nil
	}
	config, err := ReadConfig(service.ConfigRoot)
	if err != nil {
		return "", Refuse(CodeBackupToolsMissing, "agent.json is unreadable: "+err.Error())
	}
	return config.MigrationsDirectory(), nil
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
func (service *BackupService) Settings() BackupList {
	return BackupList{Directory: service.directory(), Keep: service.keep(), Schedule: service.scheduleLabel()}
}

func (service *BackupService) scheduleInterval() time.Duration {
	unlock := service.lockSettingsRead()
	defer unlock()
	if service.Schedule == nil {
		return DefaultBackupEveryHours * time.Hour
	}
	return *service.Schedule
}

func (service *BackupService) scheduleLabel() string {
	label, _ := backupScheduleForHours(int(service.scheduleInterval() / time.Hour))
	return label
}

func (service *BackupService) keep() int {
	unlock := service.lockSettingsRead()
	defer unlock()
	if service.Keep < 1 {
		return DefaultBackupKeep
	}
	return service.Keep
}

func (service *BackupService) max() int {
	if service.Max < 1 {
		return DefaultBackupMax
	}
	return service.Max
}

func (service *BackupService) requireDirectory() error {
	if service.directory() == "" {
		return Refuse(CodeBackupPathMissing, "no backup folder is set; set one on the Backups page")
	}
	return nil
}

func (service *BackupService) now() time.Time {
	if service.Now == nil {
		return time.Now()
	}
	return service.Now()
}

func (service *BackupService) log(op, step, outcome string, detail any) {
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
func (service *BackupService) Snapshot(ctx context.Context, options SnapshotOptions) (Operation, error) {
	if !backupKinds[options.Kind] {
		return Operation{}, Refuse(CodeBackupKindInvalid, "unknown backup kind")
	}
	name, err := normalizeSnapshotName(options.Name, options.Pinned)
	if err != nil {
		return Operation{}, err
	}
	if err := service.requireDirectory(); err != nil {
		return Operation{}, err
	}
	if options.Kind == BackupKindManual {
		entries, err := service.entries()
		if err != nil {
			return Operation{}, Temporarily(CodeBackupFailed, "the backup folder cannot be read")
		}
		if len(entries) >= service.max() {
			return Operation{}, Refuse(CodeBackupCap, fmt.Sprintf("%d snapshots kept; delete or unpin one first", service.max()))
		}
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
func (service *BackupService) SnapshotBeforeDestructive(ctx context.Context, reason string) (Operation, error) {
	return service.snapshot(ctx, BackupKindPreDelete, reason, "", false)
}

func (service *BackupService) snapshot(ctx context.Context, kind, reason, name string, pinned bool) (Operation, error) {
	return service.snapshotKnownVersion(ctx, kind, reason, name, pinned, nil)
}

// snapshotKnownVersion takes the snapshot with an already-read backend version,
// so the safety snapshot of a stopped backend needs no live operator read.
func (service *BackupService) snapshotKnownVersion(ctx context.Context, kind, reason, name string, pinned bool, knownVersion *operator.VersionInfo) (Operation, error) {
	if err := service.requireDirectory(); err != nil {
		return Operation{}, err
	}
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
	directory := service.directory()
	partialPath := filepath.Join(directory, id+backupDumpSuffix+backupPartialSuffix)
	dumpPath := filepath.Join(directory, id+backupDumpSuffix)
	manifestPath := filepath.Join(directory, id+backupManifestSuffix)

	var version operator.VersionInfo
	var facts snapshotFacts
	var manifest BackupManifest
	steps := make([]Step, 0, 6)
	if kind == BackupKindManual || kind == BackupKindScheduled {
		steps = append(steps, Step{Name: "flush client log journal", Run: func(ctx context.Context) (any, error) {
			return service.flushJournal(ctx), nil
		}})
	}
	if knownVersion == nil {
		steps = append(steps, Step{Name: "read backend version", Run: func(ctx context.Context) (any, error) {
			loaded, err := service.Operator.Version(ctx)
			if err != nil {
				return nil, err
			}
			version = loaded
			return map[string]any{"migration": loaded.Migration}, nil
		}})
	} else {
		version = *knownVersion
	}
	steps = append(steps,
		Step{Name: "read snapshot facts", Run: func(ctx context.Context) (any, error) {
			loaded, err := service.readSnapshotFacts(ctx, dsn)
			if err != nil {
				service.log("backup.snapshot", "facts", "failed", map[string]any{"error": MaskString(err.Error())})
				return map[string]any{"recorded": false}, nil
			}
			facts = loaded
			return map[string]any{"accounts": facts.Accounts, "players": facts.Players}, nil
		}},
		Step{Name: "dump database", Run: func(ctx context.Context) (any, error) {
			if err := service.Tools.Dump(ctx, dsn, partialPath); err != nil {
				return nil, Temporarily(CodeBackupToolFailed, MaskString(err.Error()))
			}
			return nil, nil
		}},
		Step{Name: "verify dump", Run: func(ctx context.Context) (any, error) {
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
				ID:                     id,
				Kind:                   kind,
				CreatedAt:              service.now().UTC(),
				Database:               database,
				BackendVersion:         stringValue(version.BackendVersion),
				BackendCommit:          stringValue(version.GitCommit),
				Migration:              version.Migration,
				Size:                   size,
				SHA256:                 digest,
				Reason:                 reason,
				Operator:               backupOperator,
				Name:                   name,
				Pinned:                 pinned,
				Accounts:               facts.Accounts,
				Players:                facts.Players,
				NewestAccountCreatedAt: facts.NewestAccountCreatedAt,
			}
			return map[string]any{"sha256": digest, "size": size}, nil
		}},
		Step{Name: "write manifest", Run: func(context.Context) (any, error) {
			if err := writeBackupManifest(manifestPath, manifest); err != nil {
				return nil, Temporarily(CodeBackupFailed, "the manifest cannot be written: "+err.Error())
			}
			return manifest, nil
		}},
		Step{Name: "prune", Run: func(ctx context.Context) (any, error) {
			pruned, err := service.prune(ctx)
			if err != nil {
				return nil, err
			}
			return map[string]any{"manifest": manifest, "prune": pruned}, nil
		}},
	)
	operation, err := service.Operations.RunKeyed(ctx, "backup.snapshot", "", snapshotRequest(kind, reason, name, pinned), steps)
	if err != nil {
		_ = os.Remove(partialPath)
		return operation, err
	}
	service.log("backup.snapshot", "finish", "done", map[string]any{"id": id, "size": manifest.Size, "pinned": pinned})
	return operation, nil
}

const snapshotFactsQuery = `SELECT json_build_object('accounts',(SELECT count(*) FROM accounts),'players',(SELECT count(*) FROM players),'newest_account_created_at',(SELECT to_char(max(created_at) AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') FROM accounts))`

// readSnapshotFacts reads the pre-dump account state. A failed read is logged
// and the snapshot continues without the facts.
func (service *BackupService) readSnapshotFacts(ctx context.Context, dsn string) (snapshotFacts, error) {
	answer, err := service.Tools.Query(ctx, dsn, snapshotFactsQuery)
	if err != nil {
		return snapshotFacts{}, err
	}
	var reply struct {
		Accounts               int64  `json:"accounts"`
		Players                int64  `json:"players"`
		NewestAccountCreatedAt string `json:"newest_account_created_at"`
	}
	if err := json.Unmarshal([]byte(strings.TrimSpace(answer)), &reply); err != nil {
		return snapshotFacts{}, err
	}
	facts := snapshotFacts{Accounts: reply.Accounts, Players: reply.Players}
	if reply.NewestAccountCreatedAt != "" {
		parsed, err := time.Parse(time.RFC3339Nano, reply.NewestAccountCreatedAt)
		if err != nil {
			return snapshotFacts{}, err
		}
		facts.NewestAccountCreatedAt = &parsed
	}
	return facts, nil
}

// flushJournal is best effort (S2.3): a failure is logged and the snapshot runs.
func (service *BackupService) flushJournal(ctx context.Context) map[string]any {
	if service.Journal == nil {
		return map[string]any{"flushed": false}
	}
	if err := service.Journal.FlushJournal(ctx); err != nil {
		service.log("backup.snapshot", "flush journal", "failed", map[string]any{"error": MaskString(err.Error())})
		return map[string]any{"flushed": false}
	}
	return map[string]any{"flushed": true}
}

func snapshotRequest(kind, reason, name string, pinned bool) json.RawMessage {
	encoded, _ := json.Marshal(map[string]any{"kind": kind, "reason": reason, "name": name, "pin": pinned})
	return encoded
}

// List answers backup.list (B3). A dump without a manifest, or with a sha
// mismatch, is shown damaged and is never restored.
func (service *BackupService) List(ctx context.Context) (BackupList, error) {
	directory := service.directory()
	if directory == "" {
		return BackupList{Directory: "", Keep: service.keep(), Schedule: service.scheduleLabel(), Backups: []BackupEntry{}}, nil
	}
	entries, err := service.entries()
	if err != nil {
		return BackupList{}, err
	}
	list := BackupList{Directory: directory, Keep: service.keep(), Schedule: service.scheduleLabel(), Backups: entries, KeepPrune: keepPruneCounts(entries, service.runningRequestText())}
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
func (service *BackupService) Pin(id, name string) (BackupManifest, error) {
	normalized, err := normalizeSnapshotName(name, true)
	if err != nil {
		return BackupManifest{}, err
	}
	if !service.Guard.TryLock() {
		return BackupManifest{}, Refuse(CodeBackendBusy, "a backend operation is already running")
	}
	defer service.Guard.Unlock()
	manifest, err := service.keepableManifest(id)
	if err != nil {
		return BackupManifest{}, err
	}
	manifest.Name = normalized
	manifest.Pinned = true
	if err := writeBackupManifest(filepath.Join(service.directory(), id+backupManifestSuffix), manifest); err != nil {
		return BackupManifest{}, Temporarily(CodeBackupFailed, "the manifest cannot be written: "+err.Error())
	}
	service.log("backup.pin", "pin", "done", map[string]any{"id": id, "name": normalized})
	return manifest, nil
}

// Unpin returns a pinned snapshot to normal pruning; the name is kept.
func (service *BackupService) Unpin(id string) (BackupManifest, error) {
	if !service.Guard.TryLock() {
		return BackupManifest{}, Refuse(CodeBackendBusy, "a backend operation is already running")
	}
	defer service.Guard.Unlock()
	manifest, err := service.keepableManifest(id)
	if err != nil {
		return BackupManifest{}, err
	}
	manifest.Pinned = false
	if err := writeBackupManifest(filepath.Join(service.directory(), id+backupManifestSuffix), manifest); err != nil {
		return BackupManifest{}, Temporarily(CodeBackupFailed, "the manifest cannot be written: "+err.Error())
	}
	service.log("backup.pin", "unpin", "done", map[string]any{"id": id})
	return manifest, nil
}

// keepableManifest reads the manifest pin and unpin change. A dump without a
// readable manifest naming the id is unknown, never a newly invented manifest.
func (service *BackupService) keepableManifest(id string) (BackupManifest, error) {
	if !backupIDPattern.MatchString(id) {
		return BackupManifest{}, Refuse(CodeBackupUnknown, "no such snapshot")
	}
	manifest, err := readBackupManifest(filepath.Join(service.directory(), id+backupManifestSuffix))
	if err != nil || manifest.ID != id {
		return BackupManifest{}, Refuse(CodeBackupUnknown, "no such snapshot")
	}
	return manifest, nil
}

// BackupDeleteFailure is one refused snapshot of a delete request.
type BackupDeleteFailure struct {
	ID        string `json:"id"`
	ErrorCode string `json:"error_code"`
	Message   string `json:"message"`
}

// BackupDeleteResult reports every deletion of one request, so a partial
// failure still names what was deleted and why the rest stayed.
type BackupDeleteResult struct {
	Deleted []string              `json:"deleted"`
	Failed  []BackupDeleteFailure `json:"failed"`
}

// DeleteMany deletes each unpinned snapshot and reports a refusal per snapshot
// instead of stopping the request; a repeated id is deleted once.
func (service *BackupService) DeleteMany(ids []string, reason string) BackupDeleteResult {
	result := BackupDeleteResult{Deleted: []string{}, Failed: []BackupDeleteFailure{}}
	seen := map[string]bool{}
	for _, id := range ids {
		if seen[id] {
			continue
		}
		seen[id] = true
		manifest, err := service.Delete(id, reason)
		if err == nil {
			result.Deleted = append(result.Deleted, manifest.ID)
			continue
		}
		failure := BackupDeleteFailure{ID: id, Message: err.Error()}
		var refusal *Refusal
		var transient *Transient
		if errors.As(err, &refusal) {
			failure.ErrorCode = refusal.Code
			failure.Message = refusal.Message
		} else if errors.As(err, &transient) {
			failure.ErrorCode = transient.Code
			failure.Message = transient.Message
		}
		service.log("backup.delete", "delete", "failed", map[string]any{"id": id, "error_code": failure.ErrorCode})
		result.Failed = append(result.Failed, failure)
	}
	return result
}

// Delete removes one unpinned snapshot. A pinned, damaged or in-use snapshot is
// never deleted.
func (service *BackupService) Delete(id, reason string) (BackupManifest, error) {
	if !service.Guard.TryLock() {
		return BackupManifest{}, Refuse(CodeBackendBusy, "a backend operation is already running")
	}
	defer service.Guard.Unlock()
	manifest, err := service.keepableManifest(id)
	if err != nil {
		return BackupManifest{}, err
	}
	if manifest.Pinned {
		return BackupManifest{}, Refuse(CodeBackupPinned, "the snapshot is pinned; unpin it before deleting it")
	}
	if service.entry(id).Damaged {
		return BackupManifest{}, Refuse(CodeBackupDamaged, "a damaged snapshot is never deleted")
	}
	if strings.Contains(service.runningRequestText(), id) {
		return BackupManifest{}, Refuse(CodeBackendBusy, "the snapshot is used by a running operation")
	}
	if err := service.removeSnapshot(id); err != nil {
		return BackupManifest{}, Temporarily(CodeBackupFailed, "the snapshot cannot be deleted: "+err.Error())
	}
	service.log("backup.delete", "delete", "done", map[string]any{"id": id, "reason": reason})
	return manifest, nil
}

// SetPath validates and stores the snapshot folder in agent.json, then rescans
// it. The running agent uses the new folder at once, with no restart.
func (service *BackupService) SetPath(path string) (BackupList, error) {
	trimmed := strings.TrimSpace(path)
	if trimmed == "" {
		return BackupList{}, Refuse(CodeBackupPathInvalid, "the backup folder is required")
	}
	if service.Root == "" {
		return BackupList{}, Refuse(CodeBackupPathInvalid, "the agent root is not configured")
	}
	config, err := ReadConfig(service.Root)
	if err != nil {
		return BackupList{}, Refuse(CodeSettingsUnavailable, "agent.json is unreadable: "+err.Error())
	}
	config.BackupPath = trimmed
	if err := config.Validate(); err != nil {
		return BackupList{}, Refuse(CodeBackupPathInvalid, err.Error())
	}
	// Refuse a folder change while a snapshot or restore runs, so its later
	// steps cannot write into or list the new folder.
	if service.Guard != nil {
		if !service.Guard.TryLock() {
			return BackupList{}, Refuse(CodeBackendBusy, "a backend operation is already running")
		}
		defer service.Guard.Unlock()
	}
	if err := SaveConfig(service.Root, config); err != nil {
		return BackupList{}, Temporarily(CodeFailed, "agent.json cannot be written")
	}
	service.writeDirectory(config.BackupPath)
	service.log("backup.path", "set", "done", map[string]any{"directory": config.BackupPath})
	return service.List(context.Background())
}

// SetSchedule stores the scheduled automatic snapshot interval (1d, 7d, 15d,
// 30d or off) in agent.json; the running schedule reads it at the next tick.
func (service *BackupService) SetSchedule(value string) (BackupList, error) {
	normalized := strings.ToLower(strings.TrimSpace(value))
	hours, known := backupScheduleHours[normalized]
	if !known {
		return BackupList{}, Refuse(CodeSettingsInvalid, "the schedule must be 1d, 7d, 15d, 30d or off")
	}
	if err := service.saveBackupConfig(func(config *Config) { config.BackupEveryHours = &hours }); err != nil {
		return BackupList{}, err
	}
	interval := time.Duration(hours) * time.Hour
	service.writeSchedule(interval)
	service.log("backup.schedule", "set", "done", map[string]any{"schedule": normalized})
	return service.List(context.Background())
}

// BackupKeepResult is the backup.keep reply: the new retention and the
// automatic snapshots a lowering pruned.
type BackupKeepResult struct {
	Keep    int      `json:"keep"`
	Removed []string `json:"removed"`
}

// SetKeep stores the automatic retention (5, 10, 15 or 30) in agent.json and,
// when the value is lowered, prunes the excess automatic snapshots at once.
func (service *BackupService) SetKeep(value int) (BackupKeepResult, error) {
	if !backupKeepChoices[value] {
		return BackupKeepResult{}, Refuse(CodeSettingsInvalid, "backup_keep must be 5, 10, 15 or 30")
	}
	previous := service.keep()
	lowered := value < previous
	// Take the guard before saving a lowering: a busy backend would otherwise
	// persist the new value and then report the request as refused.
	if lowered && service.Guard != nil {
		if !service.Guard.TryLock() {
			return BackupKeepResult{}, Refuse(CodeBackendBusy, "a backend operation is already running")
		}
		defer service.Guard.Unlock()
	}
	if err := service.saveBackupConfig(func(config *Config) { config.BackupKeep = &value }); err != nil {
		return BackupKeepResult{}, err
	}
	service.writeKeep(value)
	result := BackupKeepResult{Keep: value, Removed: []string{}}
	if !lowered {
		service.log("backup.keep", "set", "done", map[string]any{"keep": value})
		return result, nil
	}
	pruned, err := service.prune(context.Background())
	if err != nil {
		return result, err
	}
	result.Removed = pruned.Removed
	service.log("backup.keep", "set", "done", map[string]any{"keep": value, "removed": len(pruned.Removed)})
	return result, nil
}

// saveBackupConfig applies change to agent.json after validating it and reports
// a refusal or a write failure.
func (service *BackupService) saveBackupConfig(change func(config *Config)) error {
	if service.Root == "" {
		return Refuse(CodeSettingsUnavailable, "the agent root is not configured")
	}
	config, err := ReadConfig(service.Root)
	if err != nil {
		return Refuse(CodeSettingsUnavailable, "agent.json is unreadable: "+err.Error())
	}
	change(&config)
	if err := config.Validate(); err != nil {
		return Refuse(CodeSettingsInvalid, err.Error())
	}
	if err := SaveConfig(service.Root, config); err != nil {
		return Temporarily(CodeFailed, "agent.json cannot be written")
	}
	return nil
}

// Prune keeps the newest backup_keep automatic snapshots: the scheduled, safety,
// pre-update and pre-delete kinds. Manual snapshots are never pruned. It never
// deletes the newest snapshot, a pinned snapshot, a snapshot an unfinished
// operation references, or a damaged dump without listing it. It also drops a
// retained prerestore database once the backend is healthy again.
func (service *BackupService) Prune(ctx context.Context) (Operation, error) {
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

// prunePlan marks the automatic entries prune removes at a keep value. The
// newest entry, a pinned or damaged one and one a running operation references
// stay; manual snapshots are never marked.
func prunePlan(entries []BackupEntry, keep int, referenced string) []bool {
	removed := make([]bool, len(entries))
	automaticSeen := 0
	for index, entry := range entries {
		if entry.Kind == BackupKindManual {
			continue
		}
		automaticSeen++
		protected := index == 0 || entry.Damaged || entry.Pinned || strings.Contains(referenced, entry.ID)
		if protected || automaticSeen <= keep {
			continue
		}
		removed[index] = true
	}
	return removed
}

// keepPruneCounts is the backup.list preview: how many automatic snapshots a
// lowering to each selectable keep value would remove.
func keepPruneCounts(entries []BackupEntry, referenced string) map[string]int {
	counts := map[string]int{}
	for keep := range backupKeepChoices {
		for _, removed := range prunePlan(entries, keep, referenced) {
			if removed {
				counts[strconv.Itoa(keep)]++
			}
		}
	}
	return counts
}

func (service *BackupService) prune(ctx context.Context) (PruneResult, error) {
	entries, err := service.entries()
	if err != nil {
		return PruneResult{}, err
	}
	keep := service.keep()
	plan := prunePlan(entries, keep, service.runningRequestText())
	result := PruneResult{Keep: keep, Removed: []string{}, Kept: []string{}, Damaged: []string{}}
	for index, entry := range entries {
		if entry.Damaged {
			result.Damaged = append(result.Damaged, entry.ID)
		}
		if entry.Kind == BackupKindManual || !plan[index] {
			result.Kept = append(result.Kept, entry.ID)
			continue
		}
		// A pin written after the plan was computed must still win.
		if manifest, recheckErr := readBackupManifest(filepath.Join(service.directory(), entry.ID+backupManifestSuffix)); recheckErr == nil && manifest.Pinned {
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

func (service *BackupService) removeSnapshot(id string) error {
	if !backupIDPattern.MatchString(id) {
		return nil
	}
	directory := service.directory()
	for _, suffix := range []string{backupDumpSuffix, backupManifestSuffix} {
		if err := os.Remove(filepath.Join(directory, id+suffix)); err != nil && !errors.Is(err, os.ErrNotExist) {
			return err
		}
	}
	service.log("backup.prune", "remove", "done", map[string]any{"id": id})
	return nil
}

// runningRequestText returns the request text of every RUNNING operation; a
// prune never deletes a snapshot such an operation references.
func (service *BackupService) runningRequestText() string {
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

func (service *BackupService) entries() ([]BackupEntry, error) {
	directory := service.directory()
	if directory == "" {
		return []BackupEntry{}, nil
	}
	directoryEntries, err := os.ReadDir(directory)
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
			// A foreign dump is shown as damaged: it is never restored or deleted.
			seen[id] = true
			entries = append(entries, BackupEntry{BackupManifest: BackupManifest{ID: id}, Damaged: true, DamagedReason: "the snapshot file name is not recognised"})
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

func (service *BackupService) entry(id string) BackupEntry {
	directory := service.directory()
	dumpPath := filepath.Join(directory, id+backupDumpSuffix)
	manifestPath := filepath.Join(directory, id+backupManifestSuffix)
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
func (service *BackupService) Restore(ctx context.Context, id, reason string) (Operation, error) {
	if err := service.requireDirectory(); err != nil {
		return Operation{}, err
	}
	if !service.Guard.TryLock() {
		return Operation{}, Refuse(CodeBackendBusy, "a backend operation is already running")
	}
	defer service.Guard.Unlock()
	steps, err := service.restoreSteps(id)
	if err != nil {
		return Operation{}, err
	}
	return service.Operations.RunKeyed(ctx, "backup.restore", "", restoreRequest(id, reason), steps)
}

// StartRestore starts B5 in the background and returns its RUNNING operation,
// so the agent API answers at once and the GUI streams the recorded steps. The
// guard is released after the steps finish, or at once when they cannot start.
func (service *BackupService) StartRestore(ctx context.Context, id, reason string) (Operation, error) {
	if err := service.requireDirectory(); err != nil {
		return Operation{}, err
	}
	if !service.Guard.TryLock() {
		return Operation{}, Refuse(CodeBackendBusy, "a backend operation is already running")
	}
	steps, err := service.restoreSteps(id)
	if err != nil {
		service.Guard.Unlock()
		return Operation{}, err
	}
	return service.Operations.StartWithRelease(ctx, "backup.restore", "", restoreRequest(id, reason), steps, service.Guard.Unlock)
}

// restoreSteps validates the snapshot and builds B5's steps; the caller holds
// the backend guard across them.
func (service *BackupService) restoreSteps(id string) ([]Step, error) {
	if err := service.ready(); err != nil {
		return nil, err
	}
	manifest, dumpPath, err := service.verifySnapshot(id)
	if err != nil {
		return nil, err
	}
	dsn, err := service.dsn()
	if err != nil {
		return nil, err
	}
	adminDSN, err := AdminDSN(dsn)
	if err != nil {
		return nil, Refuse(CodeBackupDSNInvalid, "the backend DSN names no database")
	}
	database, _ := DatabaseNameFromDSN(dsn)
	stamp := service.now().UTC().Format("20060102T150405")
	restoredDatabase := database + "_restore_" + stamp
	preRestoreDatabase := database + "_prerestore_" + stamp
	statePath := filepath.Join(service.directory(), backupStateFileName)
	safety := Operation{}
	var deployedMigration int64
	var restoredDSN string
	var migrationsDirectory string

	var deployed operator.VersionInfo
	steps := []Step{
		{Name: "verify snapshot", Run: func(ctx context.Context) (any, error) {
			loaded, err := service.Operator.Version(ctx)
			if err != nil {
				return nil, err
			}
			deployed = loaded
			deployedMigration = loaded.Migration
			migrationsDirectory, err = service.migrationsDirectory()
			if err != nil {
				return nil, err
			}
			if manifest.Migration > deployed.Migration {
				return nil, Refuse(CodeBackupMigrationTooNew, fmt.Sprintf("the snapshot migration %d is newer than the deployed backend migration %d", manifest.Migration, deployed.Migration))
			}
			if manifest.Migration < deployed.Migration && migrationsDirectory == "" {
				return nil, Refuse(CodeBackupToolsMissing, "the snapshot is older than the backend schema and the migrations folder is not configured")
			}
			return map[string]any{"migration": deployed.Migration, "snapshot_migration": manifest.Migration}, nil
		}},
		// S2.1: the safety snapshot covers the stopped database, not a live one.
		{Name: "stop backend", Run: func(context.Context) (any, error) {
			return nil, service.Backend.Stop()
		}},
		{Name: "safety snapshot", Run: func(ctx context.Context) (any, error) {
			operation, err := service.snapshotKnownVersion(ctx, BackupKindSafety, "before restore "+id, "", false, &deployed)
			if err != nil {
				if startErr := service.startOriginal(); startErr != nil {
					service.log("backup.restore", "start", "failed", map[string]any{"error": MaskString(startErr.Error())})
				}
				return nil, err
			}
			safety = operation
			return operation.Result, nil
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
			if err := service.Tools.Migrate(ctx, restoredDSN, migrationsDirectory); err != nil {
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
			state.Phase = "swapped"
			state.UpdatedAt = service.now().UTC()
			_ = service.writeState(statePath, state)
			return map[string]any{"database": database}, nil
		}},
		{Name: "start backend and wait", Run: func(ctx context.Context) (any, error) {
			if err := StartBackend(service.Backend, service.Tokens, false); err != nil {
				if refusal, ok := noAssetsRefusal(err); ok {
					// The restored data is good; only the open start is refused.
					// Complete the restore with the backend closed and the
					// guard's remedy instead of rolling the restore back.
					if retentionErr := service.writePreRestoreRetention(preRestoreDatabase); retentionErr != nil {
						return nil, retentionErr
					}
					_ = os.Remove(statePath)
					service.log("backup.restore", "backend", "closed", map[string]any{"code": refusal.Code, "message": refusal.Message})
					return map[string]any{
						"database": database, "safety_snapshot": safety.ID, "backend": "closed",
						"error_code": refusal.Code, "action": "start closed, publish an assets release, then open",
					}, nil
				}
				if rollbackErr := service.rollbackSwap(ctx, adminDSN, database, preRestoreDatabase, stamp); rollbackErr != nil {
					service.log("backup.restore", "rollback", "failed", map[string]any{"id": id})
					return nil, Temporarily(CodeBackupRestoreRefused, "the restored database did not start and the rollback failed; an agent restart finishes recovery")
				}
				service.log("backup.restore", "rollback", "failed", map[string]any{"id": id})
				return nil, err
			}
			if err := service.writePreRestoreRetention(preRestoreDatabase); err != nil {
				return nil, err
			}
			_ = os.Remove(statePath)
			return map[string]any{"database": database, "safety_snapshot": safety.ID}, nil
		}},
	}
	return steps, nil
}

// RestorePreview is backup.restore_preview (S2.2): what the live database holds
// that the snapshot does not, so the operator sees the loss before confirming.
type RestorePreview struct {
	ID               string    `json:"id"`
	Name             string    `json:"name,omitempty"`
	CreatedAt        time.Time `json:"created_at"`
	SnapshotAccounts int64     `json:"snapshot_accounts"`
	SnapshotPlayers  int64     `json:"snapshot_players"`
	LiveAccounts     int64     `json:"live_accounts"`
	LivePlayers      int64     `json:"live_players"`
	LostAccounts     int64     `json:"lost_accounts"`
	LostPlayers      int64     `json:"lost_players"`
	NewAccounts      []string  `json:"new_accounts"`
	NewAccountCount  int64     `json:"new_account_count"`
}

// RestorePreview lists the live accounts created after the snapshot (capped at
// 50) and the live-minus-snapshot counts.
func (service *BackupService) RestorePreview(ctx context.Context, name string) (RestorePreview, error) {
	if err := service.requireDirectory(); err != nil {
		return RestorePreview{}, err
	}
	if service.Tools == nil {
		return RestorePreview{}, Refuse(CodeBackupToolsMissing, "the pg toolchain is unavailable")
	}
	manifest, err := service.keepableManifest(name)
	if err != nil {
		return RestorePreview{}, err
	}
	dsn, err := service.dsn()
	if err != nil {
		return RestorePreview{}, err
	}
	boundary := manifest.CreatedAt
	if manifest.NewestAccountCreatedAt != nil {
		boundary = *manifest.NewestAccountCreatedAt
	}
	answer, err := service.Tools.Query(ctx, dsn, restorePreviewQuery(boundary))
	if err != nil {
		return RestorePreview{}, Temporarily(CodeBackupToolFailed, MaskString(err.Error()))
	}
	var reply struct {
		Accounts        int64    `json:"accounts"`
		Players         int64    `json:"players"`
		NewAccountCount int64    `json:"new_account_count"`
		NewAccounts     []string `json:"new_accounts"`
	}
	if err := json.Unmarshal([]byte(strings.TrimSpace(answer)), &reply); err != nil {
		return RestorePreview{}, Temporarily(CodeBackupToolFailed, "the preview query did not answer JSON")
	}
	preview := RestorePreview{
		ID: manifest.ID, Name: manifest.Name, CreatedAt: manifest.CreatedAt,
		SnapshotAccounts: manifest.Accounts, SnapshotPlayers: manifest.Players,
		LiveAccounts: reply.Accounts, LivePlayers: reply.Players,
		LostAccounts: reply.Accounts - manifest.Accounts, LostPlayers: reply.Players - manifest.Players,
		NewAccounts: reply.NewAccounts, NewAccountCount: reply.NewAccountCount,
	}
	if preview.LostAccounts < 0 {
		preview.LostAccounts = 0
	}
	if preview.LostPlayers < 0 {
		preview.LostPlayers = 0
	}
	if preview.NewAccounts == nil {
		preview.NewAccounts = []string{}
	}
	return preview, nil
}

func restorePreviewQuery(boundary time.Time) string {
	stamp := boundary.UTC().Format(time.RFC3339Nano)
	return `SELECT json_build_object('accounts',(SELECT count(*) FROM accounts),'players',(SELECT count(*) FROM players),'new_account_count',(SELECT count(*) FROM accounts WHERE created_at > '` + stamp + `'),'new_accounts',(SELECT coalesce(json_agg(account_uid),'[]'::json) FROM (SELECT account_uid FROM accounts WHERE created_at > '` + stamp + `' ORDER BY created_at, account_uid LIMIT 50) recent))`
}

func (service *BackupService) rollbackSwap(ctx context.Context, adminDSN, database, preRestoreDatabase, stamp string) error {
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

func (service *BackupService) startOriginal() error {
	err := StartBackend(service.Backend, service.Tokens, false)
	if err == nil {
		return nil
	}
	if refusal, ok := noAssetsRefusal(err); ok {
		// The original data is intact; only the open start is refused. Leave
		// the backend closed, the guard's own remedy, instead of stopped.
		service.log("backup", "start", "closed", map[string]any{"code": refusal.Code, "message": refusal.Message})
		return StartBackend(service.Backend, service.Tokens, true)
	}
	return err
}

// noAssetsRefusal reports whether an open start hit the release guard.
func noAssetsRefusal(err error) (*Refusal, bool) {
	var refusal *Refusal
	if errors.As(err, &refusal) && refusal.Code == CodeBackendNoAssetsRelease {
		return refusal, true
	}
	return nil, false
}

func (service *BackupService) renameDatabase(ctx context.Context, adminDSN, from, to string) error {
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
func (service *BackupService) UpdateBackend(ctx context.Context, reason string) (Operation, error) {
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

func (service *BackupService) ready() error {
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

func (service *BackupService) dsn() (string, error) {
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

func (service *BackupService) verifySnapshot(id string) (BackupManifest, string, error) {
	if !backupIDPattern.MatchString(id) {
		return BackupManifest{}, "", Refuse(CodeBackupUnknown, "no such snapshot")
	}
	manifest, err := readBackupManifest(filepath.Join(service.directory(), id+backupManifestSuffix))
	if err != nil {
		return BackupManifest{}, "", Refuse(CodeBackupUnknown, "no such snapshot")
	}
	dumpPath := filepath.Join(service.directory(), id+backupDumpSuffix)
	digest, size, err := digestFile(dumpPath)
	if err != nil {
		return BackupManifest{}, "", Refuse(CodeBackupDamaged, "the snapshot dump is unreadable")
	}
	if digest != manifest.SHA256 || size != manifest.Size {
		return BackupManifest{}, "", Refuse(CodeBackupDamaged, "the snapshot does not match its manifest")
	}
	return manifest, dumpPath, nil
}

func (service *BackupService) writeState(path string, state restoreState) error {
	encoded, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return err
	}
	if err := writeOperationRecord(path, encoded); err != nil {
		return Temporarily(CodeBackupFailed, "the restore state cannot be written: "+err.Error())
	}
	return nil
}

func (service *BackupService) writePreRestoreRetention(database string) error {
	encoded, err := json.MarshalIndent(preRestoreRetention{Database: database, CreatedAt: service.now().UTC()}, "", "  ")
	if err != nil {
		return err
	}
	return writeOperationRecord(filepath.Join(service.directory(), backupPreRestoreFileName), encoded)
}

// dropRetainedPreRestore drops the prerestore database only after the backend
// is running healthy; otherwise it keeps the marker for the next prune.
func (service *BackupService) dropRetainedPreRestore(ctx context.Context) (string, error) {
	directory := service.directory()
	if directory == "" {
		return "", nil
	}
	path := filepath.Join(directory, backupPreRestoreFileName)
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
func (service *BackupService) RecoverRestore(ctx context.Context) error {
	directory := service.directory()
	if directory == "" {
		return nil
	}
	path := filepath.Join(directory, backupStateFileName)
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

func (service *BackupService) dropDatabase(ctx context.Context, adminDSN, database string) error {
	if err := service.Tools.Execute(ctx, adminDSN, terminateConnections(database)); err != nil {
		return err
	}
	return service.Tools.Execute(ctx, adminDSN, `DROP DATABASE IF EXISTS "`+database+`"`)
}

func (service *BackupService) databaseExists(ctx context.Context, adminDSN, database string) (bool, error) {
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

// AutomaticBackupDue decides whether the scheduled automatic snapshot runs.
// interval 0 turns the schedule off, and a stopped backend is never dumped.
func AutomaticBackupDue(now, last time.Time, interval time.Duration, backendRunning bool) bool {
	if interval <= 0 || !backendRunning {
		return false
	}
	if last.IsZero() {
		return true
	}
	return !now.Before(last.Add(interval))
}

// newestAutomaticTime is the age base of the schedule: manual snapshots never
// satisfy the automatic cadence.
func newestAutomaticTime(entries []BackupEntry) time.Time {
	for _, entry := range entries {
		if entry.Kind != BackupKindManual {
			return entry.CreatedAt
		}
	}
	return time.Time{}
}

// RunBackupSchedule takes the scheduled automatic snapshot every interval while
// the backend runs. The interval is read at every tick, so a changed schedule
// applies without an agent restart. Tests check AutomaticBackupDue with an
// injected clock rather than waiting for a tick.
func RunBackupSchedule(ctx context.Context, service *BackupService) {
	if service == nil {
		return
	}
	ticker := time.NewTicker(backupScheduleTick)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			service.snapshotScheduled(ctx)
		}
	}
}

func (service *BackupService) snapshotScheduled(ctx context.Context) {
	interval := service.scheduleInterval()
	if interval <= 0 {
		return
	}
	backendRunning := service.Backend != nil && service.Backend.Status().Running
	entries, err := service.entries()
	if err != nil {
		service.log("backup.schedule", "list", "failed", map[string]any{"error": err.Error()})
		return
	}
	if !AutomaticBackupDue(service.now(), newestAutomaticTime(entries), interval, backendRunning) {
		return
	}
	operation, err := service.Snapshot(ctx, SnapshotOptions{Kind: BackupKindScheduled, Reason: "scheduled automatic snapshot"})
	if err != nil {
		service.log("backup.schedule", "snapshot", "failed", map[string]any{"error": err.Error()})
		return
	}
	service.log("backup.schedule", "snapshot", "done", map[string]any{"operation_id": operation.ID})
}
