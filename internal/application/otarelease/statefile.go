package otarelease

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"sync"
	"time"

	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
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

var errInvalidState = errors.New("otarelease: invalid OTA release state")

// StoredRelease is one release row plus the timestamps ota.status reports.
type StoredRelease struct {
	domain.RawRelease
	BuiltAt      *time.Time `json:"built_at,omitempty"`
	PublishedAt  *time.Time `json:"published_at,omitempty"`
	SupersededAt *time.Time `json:"superseded_at,omitempty"`
	WithdrawnAt  *time.Time `json:"withdrawn_at,omitempty"`
}

// StoredActivation is one ota_activations row; ID is the revision every
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
	Releases    []StoredRelease            `json:"releases"`
	Activations []StoredActivation         `json:"activations"`
	Applied     map[string]json.RawMessage `json:"applied,omitempty"`
}

// StateExporter reads the database rows once, when the file does not exist yet.
type StateExporter interface {
	ExportStateTx(context.Context, tx.Queryer) (StateDocument, error)
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
	return document, nil
}

// Save replaces the file atomically: a temp file in the same folder then a
// rename, so a reader never sees a half-written record.
func (f *StateFile) Save(document StateDocument) error {
	if f == nil || f.Root == "" {
		return errors.New("otarelease: OTA root is not configured")
	}
	data, err := json.MarshalIndent(document, "", "  ")
	if err != nil {
		return err
	}
	temporary, err := os.CreateTemp(f.Root, ".releases-*.json")
	if err != nil {
		return err
	}
	temporaryName := temporary.Name()
	cleanup := func() {
		_ = temporary.Close()
		_ = os.Remove(temporaryName)
	}
	if _, err := temporary.Write(append(data, '\n')); err != nil {
		cleanup()
		return err
	}
	if err := temporary.Close(); err != nil {
		_ = os.Remove(temporaryName)
		return err
	}
	if err := os.Rename(temporaryName, f.Path()); err != nil {
		_ = os.Remove(temporaryName)
		return err
	}
	return nil
}

// Seed imports the database rows once, when the release file does not exist
// yet, and leaves the file untouched afterwards. A database restore therefore
// never rewrites the live OTA.
func (f *StateFile) Seed(ctx context.Context, runner tx.Runner, exporter StateExporter) (bool, error) {
	if f == nil || f.Root == "" || exporter == nil || runner.DB == nil {
		return false, nil
	}
	if _, err := os.Stat(f.Path()); err == nil {
		return false, nil
	} else if !errors.Is(err, os.ErrNotExist) {
		return false, err
	}
	current, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		return false, err
	}
	var document StateDocument
	_, err = runner.Run(ctx, current, ReadProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		loaded, readErr := exporter.ExportStateTx(ctx, scope.Tx)
		if readErr == nil {
			document = loaded
		}
		return readErr
	})
	if err != nil {
		return false, err
	}
	if err := f.Save(document); err != nil {
		return false, err
	}
	return true, nil
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

// AppliedResult is the reply a command with this semantic key already made.
func (f *StateFile) AppliedResult(commandKey string) (json.RawMessage, bool, error) {
	if commandKey == "" {
		return nil, false, nil
	}
	document, err := f.Load()
	if err != nil {
		return nil, false, err
	}
	result, found := document.Applied[commandKey]
	return result, found, nil
}

// RecordApplied stores the command's reply in the same file as its release
// change, so a body retried by the bus replays instead of applying again.
func (f *StateFile) RecordApplied(commandKey string, result any) error {
	if commandKey == "" {
		return errInvalidState
	}
	encoded, err := json.Marshal(result)
	if err != nil {
		return err
	}
	return f.mutate(func(document *StateDocument) error {
		if document.Applied == nil {
			document.Applied = map[string]json.RawMessage{}
		}
		document.Applied[commandKey] = encoded
		return nil
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
	for _, release := range document.Releases {
		if release.Version == version && release.State != string(domain.StateReplaced) {
			return true, release.Lane, release.State, nil
		}
	}
	return false, "", "", nil
}

func (f *StateFile) ReleaseTx(_ context.Context, _ tx.Queryer, version string) (*domain.RawRelease, error) {
	if version == "" {
		return nil, errInvalidState
	}
	document, err := f.Load()
	if err != nil {
		return nil, err
	}
	for _, release := range document.Releases {
		if release.Version == version && release.State != string(domain.StateReplaced) {
			row := release.RawRelease
			return &row, nil
		}
	}
	return nil, nil
}

func (f *StateFile) LockLaneTx(_ context.Context, _ tx.Tx, lane domain.Lane, version string) ([]domain.RawRelease, error) {
	if lane == "" || version == "" {
		return nil, errInvalidState
	}
	document, err := f.Load()
	if err != nil {
		return nil, err
	}
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
		stored, err := storedRelease(release, nextReleaseID(*document), at)
		if err != nil {
			return err
		}
		document.Releases = append(document.Releases, stored)
		return nil
	})
}

func (f *StateFile) ReuseBuildTx(_ context.Context, _ tx.Tx, replacedID int64, release domain.Release, commandKey string, at time.Time) error {
	if replacedID <= 0 || commandKey == "" || at.IsZero() {
		return errInvalidState
	}
	return f.mutate(func(document *StateDocument) error {
		found := false
		for index := range document.Releases {
			row := &document.Releases[index]
			if row.ID == replacedID && row.State != string(domain.StateReplaced) {
				row.State = string(domain.StateReplaced)
				found = true
				break
			}
		}
		if !found {
			return errors.New("otarelease: the reused release is already replaced")
		}
		stored, err := storedRelease(release, nextReleaseID(*document), at)
		if err != nil {
			return err
		}
		document.Releases = append(document.Releases, stored)
		return nil
	})
}

func (f *StateFile) SupersedeLaneTx(_ context.Context, _ tx.Tx, lane domain.Lane, at time.Time) ([]string, error) {
	if lane == "" || at.IsZero() {
		return nil, errInvalidState
	}
	var versions []string
	err := f.mutate(func(document *StateDocument) error {
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
		return sortVersionTexts(versions)
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
	})
}

func (f *StateFile) WithdrawTx(_ context.Context, _ tx.Tx, version string, at time.Time) error {
	if version == "" || at.IsZero() {
		return errInvalidState
	}
	return f.mutate(func(document *StateDocument) error {
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
	})
}

func (f *StateFile) InsertActivationTx(_ context.Context, _ tx.Tx, activation ActivationRow) (int64, error) {
	if activation.ReleaseID <= 0 || activation.Version == "" || activation.Action == "" || activation.CommandKey == "" || activation.At.IsZero() {
		return 0, errInvalidState
	}
	var id int64
	err := f.mutate(func(document *StateDocument) error {
		id = highestActivationID(*document) + 1
		document.Activations = append(document.Activations, StoredActivation{
			ID: id, ReleaseID: activation.ReleaseID, Version: activation.Version,
			Action: activation.Action, CommandKey: activation.CommandKey, At: activation.At.UTC(),
		})
		return nil
	})
	if err != nil {
		return 0, err
	}
	return id, nil
}

// ReadStatusTx folds the file into the ota.status snapshot. The serving
// counters and misses are telemetry and stay in their database tables; they are
// read through the caller's read-only transaction.
func (f *StateFile) ReadStatusTx(ctx context.Context, query tx.Queryer) (StatusSnapshot, error) {
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
	if query != nil {
		if err := readLedgerStatus(ctx, query, &snapshot); err != nil {
			return StatusSnapshot{}, err
		}
	}
	return snapshot, nil
}

const readServedCounters = `SELECT COALESCE(jsonb_agg(jsonb_build_object('path',path,'hits',hits) ORDER BY hits DESC, path),'[]'::jsonb)::text
FROM (SELECT path,sum(hits) AS hits FROM ota_asset_served_daily GROUP BY path ORDER BY hits DESC, path LIMIT $1) served`

const readAssetMisses = `SELECT COALESCE(jsonb_agg(jsonb_build_object(
	'path',path,'md5',md5,'first_seen',first_seen,'last_seen',last_seen,'hits',hits,'first_uid',first_uid) ORDER BY hits DESC, path),'[]'::jsonb)::text
FROM (SELECT path,md5,first_seen,last_seen,hits,first_uid FROM ota_asset_misses ORDER BY hits DESC, path LIMIT $1) misses`

func readLedgerStatus(ctx context.Context, query tx.Queryer, snapshot *StatusSnapshot) error {
	var servedRaw, missesRaw string
	if err := query.QueryRow(ctx, readServedCounters, StatusServedLimit+1).Scan(&servedRaw); err != nil {
		return err
	}
	if err := json.Unmarshal([]byte(servedRaw), &snapshot.Served); err != nil {
		return err
	}
	if err := query.QueryRow(ctx, readAssetMisses, StatusMissesLimit+1).Scan(&missesRaw); err != nil {
		return err
	}
	return json.Unmarshal([]byte(missesRaw), &snapshot.Misses)
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
