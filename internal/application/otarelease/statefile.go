package otarelease

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"sync"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// releaseStateFileName is the OTA release record beside settings.json. The
// player database holds no OTA release or activation row, so a restore or a
// redeploy of the database leaves the published OTA untouched.
const releaseStateFileName = "releases.json"

// NoAssetsExitCode is the process exit status of a backend that refused to open
// the game listener because no ACTIVE assets release is published.
const NoAssetsExitCode = 78

// maxActiveStateReleases keeps one ACTIVE read at 16 rows (OTA_AMENDMENTS OA-1);
// a read fails closed rather than silently drop a live release.
const maxActiveStateReleases = 16

// stateSchemaVersion marks the release file's layout. A document without it is
// not an empty record: it is a corrupt or foreign file and fails closed.
const stateSchemaVersion = 1

var errInvalidState = errors.New("otarelease: invalid OTA release state")

// StoredRelease is one release row plus the lifecycle timestamps ota.status and
// the OA-10 rollback-reuse audit trail keep.
type StoredRelease struct {
	domain.RawRelease
	BuiltAt      *time.Time `json:"built_at,omitempty"`
	PublishedAt  *time.Time `json:"published_at,omitempty"`
	SupersededAt *time.Time `json:"superseded_at,omitempty"`
	WithdrawnAt  *time.Time `json:"withdrawn_at,omitempty"`
	ReplacedAt   *time.Time `json:"replaced_at,omitempty"`
	ReplacedBy   *int64     `json:"replaced_by,omitempty"`
}

// StoredActivation is one activation record; ID is the revision every
// maintenance command names as expected_revision.
type StoredActivation struct {
	ID         int64     `json:"id"`
	ReleaseID  int64     `json:"release_id"`
	Version    string    `json:"version"`
	Action     string    `json:"action"`
	CommandKey string    `json:"command_key"`
	At         time.Time `json:"at"`
}

// StateDocument is the whole contents of releases.json. Applied keeps one
// command's reply: the operator bus retries a transaction body on a serializable
// abort, and a retried OTA command must not apply its file change twice.
type StateDocument struct {
	Version     int                       `json:"version"`
	Releases    []StoredRelease           `json:"releases"`
	Activations []StoredActivation        `json:"activations"`
	Applied     map[string]AppliedReceipt `json:"applied,omitempty"`
}

// AppliedReceipt is the release file's record of one command reply. The module
// and payload digest bind the semantic key to the command that wrote it, because
// the file outlives an operator SQL row a database restore can remove
// (I11A_OPERATOR_COMMANDS_V1 ruling 3).
type AppliedReceipt struct {
	ModuleCommand string          `json:"module_command,omitempty"`
	PayloadSHA256 string          `json:"payload_sha256,omitempty"`
	Result        json.RawMessage `json:"result,omitempty"`
}

// UnmarshalJSON reads a receipt written before receipts carried a module and
// digest: the stored value is then the result alone.
func (receipt *AppliedReceipt) UnmarshalJSON(data []byte) error {
	var fields map[string]json.RawMessage
	if err := json.Unmarshal(data, &fields); err != nil {
		return err
	}
	if _, recorded := fields["result"]; !recorded {
		receipt.Result = append(json.RawMessage(nil), data...)
		return nil
	}
	type receiptFields AppliedReceipt
	return json.Unmarshal(data, (*receiptFields)(receipt))
}

// StateFile owns <ota_root>/releases.json. It implements the release read,
// command, status and lookup stores, so those paths never open a database row.
type StateFile struct {
	Root string

	mu sync.Mutex
}

func NewStateFile(root string) *StateFile {
	return &StateFile{Root: root}
}

// Path is the release file this StateFile owns.
func (f *StateFile) Path() string {
	if f == nil {
		return ""
	}
	return filepath.Join(f.Root, releaseStateFileName)
}

// Load reads the file; a missing file or an unconfigured root is an empty
// record. A corrupt file is a hard error, so no caller serves a partial set.
func (f *StateFile) Load() (StateDocument, error) {
	if f == nil || f.Root == "" {
		return StateDocument{}, nil
	}
	data, err := os.ReadFile(f.Path())
	if errors.Is(err, os.ErrNotExist) {
		return StateDocument{}, nil
	}
	if err != nil {
		return StateDocument{}, err
	}
	var document StateDocument
	if err := json.Unmarshal(data, &document); err != nil {
		return StateDocument{}, fmt.Errorf("otarelease: %s: %w", f.Path(), err)
	}
	if document.Version != stateSchemaVersion {
		return StateDocument{}, fmt.Errorf("otarelease: %s: unsupported release state version %d", f.Path(), document.Version)
	}
	return document, nil
}

// Save replaces the file atomically: a temp file in the same folder, fsynced,
// then a rename and a folder fsync, so a reader never sees a half-written
// record and a crash leaves the previous or the new one.
func (f *StateFile) Save(document StateDocument) error {
	if f == nil || f.Root == "" {
		return errors.New("otarelease: OTA root is not configured")
	}
	data, err := encodedState(document)
	if err != nil {
		return err
	}
	return writeFileAtomically(f.Path(), data)
}

func encodedState(document StateDocument) ([]byte, error) {
	document.Version = stateSchemaVersion
	data, err := json.MarshalIndent(document, "", "  ")
	if err != nil {
		return nil, err
	}
	return append(data, '\n'), nil
}

// HasActiveAssets reports whether any ACTIVE assets release is published.
func (f *StateFile) HasActiveAssets() (bool, error) {
	document, err := f.Load()
	if err != nil {
		return false, err
	}
	for _, release := range document.Releases {
		if release.State == string(domain.StateActive) && release.Lane == string(domain.LaneAssets) {
			return true, nil
		}
	}
	return false, nil
}

// AppliedResult is the reply a command with this semantic key already made. A
// receipt bound to another module or payload is refused, never replayed; a
// result-only entry written before receipts carried a digest replays only for
// the same module and is logged.
func (f *StateFile) AppliedResult(commandKey, moduleCommand, payloadSHA256 string) (json.RawMessage, bool, error) {
	if commandKey == "" {
		return nil, false, nil
	}
	document, err := f.Load()
	if err != nil {
		return nil, false, err
	}
	return appliedResultFrom(document, commandKey, moduleCommand, payloadSHA256)
}

func appliedResultFrom(document StateDocument, commandKey, moduleCommand, payloadSHA256 string) (json.RawMessage, bool, error) {
	receipt, found := document.Applied[commandKey]
	if !found {
		return nil, false, nil
	}
	if !receipt.matches(moduleCommand, payloadSHA256) {
		return nil, false, operator.Refuse(operator.CodeKeyReused, "this semantic key was used with another command or payload", nil)
	}
	if receipt.PayloadSHA256 == "" {
		log.Printf("ota release file replayed legacy receipt %q for %s without a payload digest", commandKey, moduleCommand)
	}
	return receipt.Result, true, nil
}

func (receipt AppliedReceipt) matches(moduleCommand, payloadSHA256 string) bool {
	if receipt.PayloadSHA256 != "" {
		return receipt.ModuleCommand == moduleCommand && receipt.PayloadSHA256 == payloadSHA256
	}
	recorded := receipt.ModuleCommand
	if recorded == "" {
		recorded = legacyReceiptModule(receipt.Result)
	}
	return recorded != "" && recorded == moduleCommand
}

// legacyReceiptModule recovers the module command that produced a result-only
// receipt, so such an entry keeps replaying only for the same module.
func legacyReceiptModule(result json.RawMessage) string {
	var build BuildResult
	if err := json.Unmarshal(result, &build); err == nil && build.Lane != "" {
		return commandRegisterBuild
	}
	var activation Activation
	if err := json.Unmarshal(result, &activation); err != nil || activation.ActivationID == 0 {
		return ""
	}
	switch activation.Action {
	case "PUBLISH":
		return commandPublish
	case "WITHDRAW":
		return commandWithdraw
	}
	return ""
}

// RecordApplied stores the command's reply in the same file as its release
// change, so a body retried by the bus replays instead of applying again.
func (f *StateFile) RecordApplied(commandKey, moduleCommand, payloadSHA256 string, result any) error {
	if commandKey == "" {
		return errInvalidState
	}
	return f.mutate(func(document *StateDocument) error {
		return recordAppliedIn(document, commandKey, moduleCommand, payloadSHA256, result)
	})
}

func (f *StateFile) ListActiveTx(context.Context, tx.Queryer) ([]domain.RawRelease, error) {
	return f.listActive(true)
}

func (f *StateFile) ListActiveDescriptorsTx(context.Context, tx.Queryer) ([]domain.RawRelease, error) {
	return f.listActive(false)
}

func (f *StateFile) listActive(withManifest bool) ([]domain.RawRelease, error) {
	document, err := f.Load()
	if err != nil {
		return nil, err
	}
	rows := make([]domain.RawRelease, 0, len(document.Releases))
	for _, release := range document.Releases {
		if release.State != string(domain.StateActive) {
			continue
		}
		row := release.RawRelease
		if !withManifest {
			row.Manifest = nil
		}
		rows = append(rows, row)
	}
	if len(rows) > maxActiveStateReleases {
		return nil, errInvalidState
	}
	if err := sortRawReleases(rows); err != nil {
		return nil, err
	}
	return rows, nil
}

func (f *StateFile) ReleaseStatusTx(_ context.Context, _ tx.Queryer, version string) (bool, string, string, error) {
	if version == "" {
		return false, "", "", errInvalidState
	}
	document, err := f.Load()
	if err != nil {
		return false, "", "", err
	}
	exists, lane, state := releaseStatusFromDocument(document, version)
	return exists, lane, state, nil
}

func (f *StateFile) ReleaseTx(_ context.Context, _ tx.Queryer, version string) (*domain.RawRelease, error) {
	if version == "" {
		return nil, errInvalidState
	}
	document, err := f.Load()
	if err != nil {
		return nil, err
	}
	return releaseFromDocument(document, version), nil
}

func (f *StateFile) LockLaneTx(_ context.Context, _ tx.Tx, lane domain.Lane, version string) ([]domain.RawRelease, error) {
	if lane == "" || version == "" {
		return nil, errInvalidState
	}
	document, err := f.Load()
	if err != nil {
		return nil, err
	}
	return lockLaneInDocument(document, lane, version)
}

func (f *StateFile) ActiveRevisionTx(context.Context, tx.Queryer) (int64, error) {
	document, err := f.Load()
	if err != nil {
		return 0, err
	}
	return highestActivationID(document), nil
}

func (f *StateFile) InsertBuildTx(_ context.Context, _ tx.Tx, release domain.Release, commandKey string, at time.Time) error {
	if commandKey == "" || at.IsZero() {
		return errInvalidState
	}
	return f.mutate(func(document *StateDocument) error {
		return insertBuildIn(document, release, at)
	})
}

func (f *StateFile) ReuseBuildTx(_ context.Context, _ tx.Tx, replacedID int64, release domain.Release, commandKey string, at time.Time) error {
	if replacedID <= 0 || commandKey == "" || at.IsZero() {
		return errInvalidState
	}
	return f.mutate(func(document *StateDocument) error {
		return reuseBuildIn(document, replacedID, release, at)
	})
}

func (f *StateFile) SupersedeLaneTx(_ context.Context, _ tx.Tx, lane domain.Lane, at time.Time) ([]string, error) {
	if lane == "" || at.IsZero() {
		return nil, errInvalidState
	}
	var versions []string
	err := f.mutate(func(document *StateDocument) error {
		superseded, applyErr := supersedeLaneIn(document, lane, at)
		versions = superseded
		return applyErr
	})
	if err != nil {
		return nil, err
	}
	return versions, nil
}

func (f *StateFile) ActivateTx(_ context.Context, _ tx.Tx, version, commandKey string, at time.Time) error {
	if version == "" || commandKey == "" || at.IsZero() {
		return errInvalidState
	}
	return f.mutate(func(document *StateDocument) error {
		return activateIn(document, version, at)
	})
}

func (f *StateFile) WithdrawTx(_ context.Context, _ tx.Tx, version string, at time.Time) error {
	if version == "" || at.IsZero() {
		return errInvalidState
	}
	return f.mutate(func(document *StateDocument) error {
		return withdrawIn(document, version, at)
	})
}

func (f *StateFile) InsertActivationTx(_ context.Context, _ tx.Tx, activation ActivationRow) (int64, error) {
	if !validActivation(activation) {
		return 0, errInvalidState
	}
	var id int64
	err := f.mutate(func(document *StateDocument) error {
		id = insertActivationIn(document, activation)
		return nil
	})
	if err != nil {
		return 0, err
	}
	return id, nil
}

// BeginCommand loads the document once and holds the file lock until Commit or
// Rollback, so an operator command's several store calls become one atomic
// rewrite instead of one rename per call.
func (f *StateFile) BeginCommand() (CommandTransaction, error) {
	if f == nil {
		return nil, errors.New("otarelease: OTA state is not configured")
	}
	f.mu.Lock()
	document, err := f.Load()
	if err != nil {
		f.mu.Unlock()
		return nil, err
	}
	return &commandTransaction{file: f, document: document}, nil
}

type commandTransaction struct {
	file     *StateFile
	document StateDocument
	closed   bool
}

func (transaction *commandTransaction) finish() {
	if transaction.closed {
		return
	}
	transaction.closed = true
	transaction.file.mu.Unlock()
}

func (transaction *commandTransaction) Commit() error {
	defer transaction.finish()
	return transaction.file.Save(transaction.document)
}

func (transaction *commandTransaction) Rollback() {
	transaction.finish()
}

func (transaction *commandTransaction) ReleaseTx(_ context.Context, _ tx.Queryer, version string) (*domain.RawRelease, error) {
	if version == "" {
		return nil, errInvalidState
	}
	return releaseFromDocument(transaction.document, version), nil
}

func (transaction *commandTransaction) LockLaneTx(_ context.Context, _ tx.Tx, lane domain.Lane, version string) ([]domain.RawRelease, error) {
	if lane == "" || version == "" {
		return nil, errInvalidState
	}
	return lockLaneInDocument(transaction.document, lane, version)
}

func (transaction *commandTransaction) ActiveRevisionTx(context.Context, tx.Queryer) (int64, error) {
	return highestActivationID(transaction.document), nil
}

func (transaction *commandTransaction) InsertBuildTx(_ context.Context, _ tx.Tx, release domain.Release, commandKey string, at time.Time) error {
	if commandKey == "" || at.IsZero() {
		return errInvalidState
	}
	return insertBuildIn(&transaction.document, release, at)
}

func (transaction *commandTransaction) ReuseBuildTx(_ context.Context, _ tx.Tx, replacedID int64, release domain.Release, commandKey string, at time.Time) error {
	if replacedID <= 0 || commandKey == "" || at.IsZero() {
		return errInvalidState
	}
	return reuseBuildIn(&transaction.document, replacedID, release, at)
}

func (transaction *commandTransaction) SupersedeLaneTx(_ context.Context, _ tx.Tx, lane domain.Lane, at time.Time) ([]string, error) {
	if lane == "" || at.IsZero() {
		return nil, errInvalidState
	}
	return supersedeLaneIn(&transaction.document, lane, at)
}

func (transaction *commandTransaction) ActivateTx(_ context.Context, _ tx.Tx, version, commandKey string, at time.Time) error {
	if version == "" || commandKey == "" || at.IsZero() {
		return errInvalidState
	}
	return activateIn(&transaction.document, version, at)
}

func (transaction *commandTransaction) WithdrawTx(_ context.Context, _ tx.Tx, version string, at time.Time) error {
	if version == "" || at.IsZero() {
		return errInvalidState
	}
	return withdrawIn(&transaction.document, version, at)
}

func (transaction *commandTransaction) InsertActivationTx(_ context.Context, _ tx.Tx, activation ActivationRow) (int64, error) {
	if !validActivation(activation) {
		return 0, errInvalidState
	}
	return insertActivationIn(&transaction.document, activation), nil
}

func (transaction *commandTransaction) AppliedResult(commandKey, moduleCommand, payloadSHA256 string) (json.RawMessage, bool, error) {
	if commandKey == "" {
		return nil, false, nil
	}
	return appliedResultFrom(transaction.document, commandKey, moduleCommand, payloadSHA256)
}

func (transaction *commandTransaction) RecordApplied(commandKey, moduleCommand, payloadSHA256 string, result any) error {
	if commandKey == "" {
		return errInvalidState
	}
	return recordAppliedIn(&transaction.document, commandKey, moduleCommand, payloadSHA256, result)
}

func releaseFromDocument(document StateDocument, version string) *domain.RawRelease {
	for _, release := range document.Releases {
		if release.Version == version && release.State != string(domain.StateReplaced) {
			row := release.RawRelease
			return &row
		}
	}
	return nil
}

func releaseStatusFromDocument(document StateDocument, version string) (bool, string, string) {
	for _, release := range document.Releases {
		if release.Version == version && release.State != string(domain.StateReplaced) {
			return true, release.Lane, release.State
		}
	}
	return false, "", ""
}

func lockLaneInDocument(document StateDocument, lane domain.Lane, version string) ([]domain.RawRelease, error) {
	rows := make([]domain.RawRelease, 0)
	for _, release := range document.Releases {
		if release.State == string(domain.StateReplaced) || release.Lane != string(lane) {
			continue
		}
		if release.State == string(domain.StateActive) || release.State == string(domain.StateBuilt) || release.Version == version {
			rows = append(rows, release.RawRelease)
		}
	}
	if err := sortRawReleases(rows); err != nil {
		return nil, err
	}
	return rows, nil
}

func insertBuildIn(document *StateDocument, release domain.Release, at time.Time) error {
	stored, err := storedRelease(release, nextReleaseID(*document), at)
	if err != nil {
		return err
	}
	document.Releases = append(document.Releases, stored)
	return nil
}

func reuseBuildIn(document *StateDocument, replacedID int64, release domain.Release, at time.Time) error {
	newID := nextReleaseID(*document)
	found := false
	for index := range document.Releases {
		row := &document.Releases[index]
		if row.ID == replacedID && row.State != string(domain.StateReplaced) {
			replacedAt := at.UTC()
			row.State = string(domain.StateReplaced)
			row.ReplacedAt = &replacedAt
			row.ReplacedBy = &newID
			found = true
			break
		}
	}
	if !found {
		return errors.New("otarelease: the reused release is already replaced")
	}
	stored, err := storedRelease(release, newID, at)
	if err != nil {
		return err
	}
	document.Releases = append(document.Releases, stored)
	return nil
}

func supersedeLaneIn(document *StateDocument, lane domain.Lane, at time.Time) ([]string, error) {
	var versions []string
	supersededAt := at.UTC()
	for index := range document.Releases {
		row := &document.Releases[index]
		if row.Lane != string(lane) || row.State != string(domain.StateActive) {
			continue
		}
		row.State = string(domain.StateSuperseded)
		row.SupersededAt = &supersededAt
		versions = append(versions, row.Version)
	}
	if err := sortVersionTexts(versions); err != nil {
		return nil, err
	}
	return versions, nil
}

func activateIn(document *StateDocument, version string, at time.Time) error {
	publishedAt := at.UTC()
	for index := range document.Releases {
		row := &document.Releases[index]
		if row.Version != version || row.State != string(domain.StateBuilt) {
			continue
		}
		row.State = string(domain.StateActive)
		row.PublishedAt = &publishedAt
		return nil
	}
	return errors.New("otarelease: release is not BUILT")
}

func withdrawIn(document *StateDocument, version string, at time.Time) error {
	withdrawnAt := at.UTC()
	for index := range document.Releases {
		row := &document.Releases[index]
		if row.Version != version || row.State != string(domain.StateActive) {
			continue
		}
		row.State = string(domain.StateWithdrawn)
		row.WithdrawnAt = &withdrawnAt
		return nil
	}
	return errors.New("otarelease: release is not ACTIVE")
}

func validActivation(activation ActivationRow) bool {
	return activation.ReleaseID > 0 && activation.Version != "" && activation.Action != "" && activation.CommandKey != "" && !activation.At.IsZero()
}

func insertActivationIn(document *StateDocument, activation ActivationRow) int64 {
	id := highestActivationID(*document) + 1
	document.Activations = append(document.Activations, StoredActivation{
		ID: id, ReleaseID: activation.ReleaseID, Version: activation.Version,
		Action: activation.Action, CommandKey: activation.CommandKey, At: activation.At.UTC(),
	})
	return id
}

func recordAppliedIn(document *StateDocument, commandKey, moduleCommand, payloadSHA256 string, result any) error {
	encoded, err := json.Marshal(result)
	if err != nil {
		return err
	}
	if document.Applied == nil {
		document.Applied = map[string]AppliedReceipt{}
	}
	document.Applied[commandKey] = AppliedReceipt{ModuleCommand: moduleCommand, PayloadSHA256: payloadSHA256, Result: encoded}
	return nil
}

// ReadStatusTx folds the file into the ota.status snapshot. The serving
// counters and misses are telemetry and stay in their database tables, so the
// status service reads them through its ledger port instead.
func (f *StateFile) ReadStatusTx(context.Context, tx.Queryer) (StatusSnapshot, error) {
	document, err := f.Load()
	if err != nil {
		return StatusSnapshot{}, err
	}
	snapshot := StatusSnapshot{Revision: highestActivationID(document)}
	for _, release := range document.Releases {
		switch release.State {
		case string(domain.StateActive):
			snapshot.Active = append(snapshot.Active, ActiveRow{Version: release.Version, Lane: release.Lane, TotalSize: release.TotalSize, PublishedAt: release.PublishedAt})
		case string(domain.StateBuilt):
			builtAt := time.Time{}
			if release.BuiltAt != nil {
				builtAt = *release.BuiltAt
			}
			snapshot.Built = append(snapshot.Built, BuiltRelease{Version: release.Version, Lane: release.Lane, TotalSize: release.TotalSize, BuiltAt: builtAt})
		}
	}
	if err := sortActiveRows(snapshot.Active); err != nil {
		return StatusSnapshot{}, err
	}
	if err := sortBuiltReleases(snapshot.Built); err != nil {
		return StatusSnapshot{}, err
	}
	snapshot.Active = boundRows(snapshot.Active, StatusActiveLimit+1)
	snapshot.Built = boundRows(snapshot.Built, StatusBuiltLimit+1)
	activations := append([]StoredActivation(nil), document.Activations...)
	sort.SliceStable(activations, func(left, right int) bool { return activations[left].ID > activations[right].ID })
	for index, activation := range activations {
		if index >= StatusActivationLimit+1 {
			break
		}
		snapshot.Activations = append(snapshot.Activations, ActivationStatus{ID: activation.ID, Version: activation.Version, Action: activation.Action, CommandKey: activation.CommandKey, At: activation.At})
	}
	for _, release := range document.Releases {
		snapshot.Versions = append(snapshot.Versions, release.Version)
	}
	if err := sortVersionsDescending(snapshot.Versions); err != nil {
		return StatusSnapshot{}, err
	}
	snapshot.Versions = boundRows(snapshot.Versions, StatusVersionLimit)
	return snapshot, nil
}

func (f *StateFile) mutate(change func(*StateDocument) error) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	document, err := f.Load()
	if err != nil {
		return err
	}
	if err := change(&document); err != nil {
		return err
	}
	return f.Save(document)
}

func storedRelease(release domain.Release, id int64, at time.Time) (StoredRelease, error) {
	packageFiles, err := json.Marshal(release.Volumes)
	if err != nil {
		return StoredRelease{}, err
	}
	manifest, err := json.Marshal(map[string]any{"files": release.Manifest})
	if err != nil {
		return StoredRelease{}, err
	}
	builtAt := at.UTC()
	return StoredRelease{
		RawRelease: domain.RawRelease{
			ID: id, Version: release.Version.String(), Lane: string(release.Lane), State: string(domain.StateBuilt),
			PackageFiles: packageFiles, TotalSize: release.TotalSize, MD5: release.MD5, SHA256: release.SHA256, Manifest: manifest,
		},
		BuiltAt: &builtAt,
	}, nil
}

func nextReleaseID(document StateDocument) int64 {
	highest := int64(0)
	for _, release := range document.Releases {
		if release.ID > highest {
			highest = release.ID
		}
	}
	return highest + 1
}

func highestActivationID(document StateDocument) int64 {
	highest := int64(0)
	for _, activation := range document.Activations {
		if activation.ID > highest {
			highest = activation.ID
		}
	}
	return highest
}

func boundRows[T any](rows []T, bound int) []T {
	if len(rows) <= bound {
		return rows
	}
	return rows[:bound]
}

func sortRawReleases(rows []domain.RawRelease) error {
	return sortByVersion(rows, func(row domain.RawRelease) string { return row.Version })
}

func sortActiveRows(rows []ActiveRow) error {
	return sortByVersion(rows, func(row ActiveRow) string { return row.Version })
}

func sortBuiltReleases(rows []BuiltRelease) error {
	return sortByVersion(rows, func(row BuiltRelease) string { return row.Version })
}

func sortVersionsDescending(versions []string) error {
	parsed := make([]domain.Version, len(versions))
	for index, text := range versions {
		version, err := domain.ParseVersion(text)
		if err != nil {
			return err
		}
		parsed[index] = version
	}
	order := make([]int, len(versions))
	for index := range order {
		order[index] = index
	}
	sort.SliceStable(order, func(left, right int) bool {
		return parsed[order[left]].Compare(parsed[order[right]]) > 0
	})
	sorted := make([]string, len(versions))
	for position, source := range order {
		sorted[position] = versions[source]
	}
	copy(versions, sorted)
	return nil
}

func sortVersionTexts(versions []string) error {
	return sortByVersion(versions, func(text string) string { return text })
}

func sortByVersion[T any](items []T, textAt func(T) string) error {
	parsed := make([]domain.Version, len(items))
	for index, item := range items {
		version, err := domain.ParseVersion(textAt(item))
		if err != nil {
			return err
		}
		parsed[index] = version
	}
	order := make([]int, len(items))
	for index := range order {
		order[index] = index
	}
	sort.SliceStable(order, func(left, right int) bool {
		return parsed[order[left]].Compare(parsed[order[right]]) < 0
	})
	sorted := make([]T, len(items))
	for position, source := range order {
		sorted[position] = items[source]
	}
	copy(items, sorted)
	return nil
}
