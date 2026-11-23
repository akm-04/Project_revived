package otarelease

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Refusal codes of the OTA commands (I11A_OPERATOR_COMMANDS_V1 ruling 4).
const (
	CodePayloadInvalid   = "OTA_PAYLOAD_INVALID"
	CodeVersionExists    = "OTA_VERSION_EXISTS"
	CodeRollbackRequired = "OTA_ROLLBACK_REQUIRED"
	// CodeBuildVersionNotNext refuses a version on another major.minor line than
	// the lane's active release (or the highest built one when nothing is
	// active): a changed line reads as a new APK to the client (G23).
	CodeBuildVersionNotNext = "OTA_BUILD_VERSION_NOT_NEXT"
	CodeVolumeMissing       = "OTA_VOLUME_MISSING"
	CodeReleaseUnknown      = "OTA_RELEASE_UNKNOWN"
	CodeStateInvalid        = "OTA_STATE_INVALID"
	CodeRevisionRequired    = "OTA_REVISION_REQUIRED"
	CodeRootUnavailable     = "OTA_ROOT_UNAVAILABLE"
	CodeActiveLimit         = "OTA_ACTIVE_LIMIT"
	// CodeRollbackBelowAssets refuses a code rollback at or below the active
	// assets release: a cleared client would install the code release before the
	// asset bootstrap the plan needs (OA-10 clause 3).
	CodeRollbackBelowAssets = "OTA_ROLLBACK_BELOW_ASSETS"
)

// maxActiveCatalogReleases keeps one ACTIVE read at 16 rows: one code, one
// assets and at most this many catalog releases (OTA_AMENDMENTS OA-1).
const maxActiveCatalogReleases = 14

// CommandStore is the write side of ota_releases and ota_activations. Every
// method runs in the bus transaction, so lock order is the bus row first, then
// the lane's release rows ordered by version, then the activation insert.
type CommandStore interface {
	ReleaseTx(context.Context, tx.Queryer, string) (*domain.RawRelease, error)
	LockLaneTx(context.Context, tx.Tx, domain.Lane, string) ([]domain.RawRelease, error)
	ActiveRevisionTx(context.Context, tx.Queryer) (int64, error)
	InsertBuildTx(context.Context, tx.Tx, domain.Release, string, time.Time) error
	// ReuseBuildTx marks the row whose number a rollback reuse takes over as
	// REPLACED and inserts the new BUILT row, replaced_by the old id, in one
	// transaction (OA-10 clause 2).
	ReuseBuildTx(context.Context, tx.Tx, int64, domain.Release, string, time.Time) error
	SupersedeLaneTx(context.Context, tx.Tx, domain.Lane, time.Time) ([]string, error)
	ActivateTx(context.Context, tx.Tx, string, string, time.Time) error
	WithdrawTx(context.Context, tx.Tx, string, time.Time) error
	InsertActivationTx(context.Context, tx.Tx, ActivationRow) (int64, error)
}

// Commands applies the ota.* commands; Root is the OTA root the operator passed.
type Commands struct {
	Store CommandStore
	Root  string
}

// BuildResult is the ota.register_build reply.
type BuildResult struct {
	Version  string `json:"version"`
	Lane     string `json:"lane"`
	State    string `json:"state"`
	Rollback bool   `json:"rollback"`
	Warning  string `json:"warning,omitempty"`
}

// Activation is the ota.publish / ota.withdraw reply and the history mirror's
// source.
type Activation struct {
	ActivationID int64     `json:"activation_id"`
	Version      string    `json:"version"`
	Action       string    `json:"action"`
	State        string    `json:"state"`
	Superseded   []string  `json:"superseded,omitempty"`
	At           time.Time `json:"at"`
}

// ActivationRow is one ota_activations insert. ReleaseID is the release row's
// surrogate id, so an activation never names a REPLACED row (OA-10).
type ActivationRow struct {
	ReleaseID  int64
	Version    string
	Action     string
	CommandKey string
	At         time.Time
}

type releasePayload struct {
	Version string `json:"version"`
}

// Handlers registers the three OTA commands on the operator bus.
func (commands Commands) Handlers() map[string]operator.Handler {
	return map[string]operator.Handler{
		"ota.register_build": commands.registerBuildHandler,
		"ota.publish":        commands.publishHandler,
		"ota.withdraw":       commands.withdrawHandler,
	}
}

func (commands Commands) registerBuildHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var request domain.BuildRequest
	if err := decodePayload(command.Payload, &request); err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	return commands.RegisterBuild(ctx, scope.Tx, command.Envelope.SemanticKey, request, scope.Operation.StartedAt)
}

func (commands Commands) publishHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var request releasePayload
	if err := decodePayload(command.Payload, &request); err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	activation, err := commands.Publish(ctx, scope.Tx, command.Envelope.SemanticKey, command.Envelope.ExpectedRevision, request.Version, scope.Operation.StartedAt)
	if err != nil {
		return nil, err
	}
	return activation, nil
}

func (commands Commands) withdrawHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var request releasePayload
	if err := decodePayload(command.Payload, &request); err != nil {
		return nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	activation, err := commands.Withdraw(ctx, scope.Tx, command.Envelope.SemanticKey, command.Envelope.ExpectedRevision, request.Version, scope.Operation.StartedAt)
	if err != nil {
		return nil, err
	}
	return activation, nil
}

func decodePayload(payload json.RawMessage, target any) error {
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return fmt.Errorf("the payload does not match the command: %w", err)
	}
	return nil
}

// RegisterBuild validates and stores a finished build as BUILT. A forward build
// refuses any used number; a rollback build with the clear-data acknowledgement
// may reuse a number whose release is neither ACTIVE nor BUILT, keeping the old
// row as REPLACED (OA-10).
func (commands Commands) RegisterBuild(ctx context.Context, transaction tx.Tx, commandKey string, request domain.BuildRequest, at time.Time) (BuildResult, error) {
	if transaction == nil || commandKey == "" || at.IsZero() {
		return BuildResult{}, operator.ErrUnavailable
	}
	release, err := request.Release()
	if err != nil {
		return BuildResult{}, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	existing, err := commands.Store.ReleaseTx(ctx, transaction, release.Version.String())
	if err != nil {
		return BuildResult{}, err
	}
	reusing := existing != nil
	if reusing {
		if !request.Rollback || !reusableRelease(existing) {
			return BuildResult{}, operator.Refuse(CodeVersionExists, usedNumberMessage(existing), usedNumberDetail(existing))
		}
	}
	// Lock order: a code rollback reads the assets lane before its own lane, the
	// one direction in which two lanes are ever locked together.
	var activeAssets *domain.Version
	if release.Lane == domain.LaneCode && request.Rollback {
		rows, err := commands.Store.LockLaneTx(ctx, transaction, domain.LaneAssets, release.Version.String())
		if err != nil {
			return BuildResult{}, err
		}
		if assetsActive, _, err := laneVersions(rows); err != nil {
			return BuildResult{}, err
		} else {
			activeAssets = assetsActive
		}
	}
	rows, err := commands.Store.LockLaneTx(ctx, transaction, release.Lane, release.Version.String())
	if err != nil {
		return BuildResult{}, err
	}
	active, highestBuilt, err := laneVersions(rows)
	if err != nil {
		return BuildResult{}, err
	}
	line := active
	if line == nil {
		line = highestBuilt
	}
	if line != nil && !release.Version.SameLine(*line) {
		return BuildResult{}, operator.Refuse(CodeBuildVersionNotNext, fmt.Sprintf("keep %d.%d and change only the last number", line.Major, line.Minor), nil)
	}
	if domain.LowersActive(release.Version, active) && !request.Rollback {
		return BuildResult{}, operator.Refuse(CodeRollbackRequired, "the release number is below the lane's active release; set rollback to register it: "+domain.RollbackWarning, map[string]string{"active_version": active.String()})
	}
	if reusing && (active == nil || release.Version.Compare(*active) >= 0) {
		return BuildResult{}, operator.Refuse(CodeRollbackRequired, "a reused release number must be below the lane's active release", nil)
	}
	if release.Lane == domain.LaneCode && request.Rollback && activeAssets != nil && release.Version.Compare(*activeAssets) <= 0 {
		return BuildResult{}, operator.Refuse(CodeRollbackBelowAssets, fmt.Sprintf("the code rollback %s must stay above the active assets release %s: a cleared client installs the code release before its asset bootstrap", release.Version, *activeAssets), map[string]string{"assets_version": activeAssets.String()})
	}
	if err := commands.verifyVolumes(release); err != nil {
		return BuildResult{}, err
	}
	if reusing {
		if err := commands.Store.ReuseBuildTx(ctx, transaction, existing.ID, release, commandKey, at); err != nil {
			return BuildResult{}, err
		}
	} else if err := commands.Store.InsertBuildTx(ctx, transaction, release, commandKey, at); err != nil {
		return BuildResult{}, err
	}
	result := BuildResult{Version: release.Version.String(), Lane: string(release.Lane), State: string(domain.StateBuilt), Rollback: domain.LowersActive(release.Version, active)}
	if result.Rollback {
		result.Warning = domain.RollbackWarning
	}
	return result, nil
}

// reusableRelease reports whether a used number may be taken over by a rollback
// build: its release is neither ACTIVE nor BUILT (OA-10 clause 1).
func reusableRelease(row *domain.RawRelease) bool {
	return row.State != string(domain.StateActive) && row.State != string(domain.StateBuilt)
}

func usedNumberMessage(row *domain.RawRelease) string {
	return fmt.Sprintf("the release number is already used by the %s release (%s); a new release never reuses a number: a client that installed a number never downloads it again", row.Lane, row.State)
}

func usedNumberDetail(row *domain.RawRelease) map[string]string {
	return map[string]string{"version": row.Version, "lane": row.Lane, "state": row.State}
}

// Publish activates a BUILT release (I11A_1_PLAN "Command semantics").
func (commands Commands) Publish(ctx context.Context, transaction tx.Tx, commandKey string, expectedRevision *int64, versionText string, at time.Time) (Activation, error) {
	locked, lane, laneRows, err := commands.lockTarget(ctx, transaction, versionText)
	if err != nil {
		return Activation{}, err
	}
	if err := commands.checkRevision(ctx, transaction, expectedRevision); err != nil {
		return Activation{}, err
	}
	if locked.State != string(domain.StateBuilt) {
		return Activation{}, operator.Refuse(CodeStateInvalid, "only a BUILT release can be published", map[string]string{"state": locked.State})
	}
	release, err := domain.ParseReleaseWithoutManifest(locked)
	if err != nil {
		return Activation{}, err
	}
	if err := commands.verifyVolumes(release); err != nil {
		return Activation{}, err
	}
	if lane == domain.LaneCatalog && countActive(laneRows) >= maxActiveCatalogReleases {
		return Activation{}, operator.Refuse(CodeActiveLimit, "the catalog lane already has the maximum number of ACTIVE releases; withdraw one first", map[string]int{"limit": maxActiveCatalogReleases})
	}
	var superseded []string
	if lane != domain.LaneCatalog {
		superseded, err = commands.Store.SupersedeLaneTx(ctx, transaction, lane, at)
		if err != nil {
			return Activation{}, err
		}
	}
	if err := commands.Store.ActivateTx(ctx, transaction, release.Version.String(), commandKey, at); err != nil {
		return Activation{}, err
	}
	activationID, err := commands.Store.InsertActivationTx(ctx, transaction, ActivationRow{ReleaseID: locked.ID, Version: release.Version.String(), Action: "PUBLISH", CommandKey: commandKey, At: at})
	if err != nil {
		return Activation{}, err
	}
	return Activation{ActivationID: activationID, Version: release.Version.String(), Action: "PUBLISH", State: string(domain.StateActive), Superseded: superseded, At: at}, nil
}

// Withdraw stops advertising an ACTIVE release; nothing is reactivated.
func (commands Commands) Withdraw(ctx context.Context, transaction tx.Tx, commandKey string, expectedRevision *int64, versionText string, at time.Time) (Activation, error) {
	locked, _, _, err := commands.lockTarget(ctx, transaction, versionText)
	if err != nil {
		return Activation{}, err
	}
	if err := commands.checkRevision(ctx, transaction, expectedRevision); err != nil {
		return Activation{}, err
	}
	if locked.State != string(domain.StateActive) {
		return Activation{}, operator.Refuse(CodeStateInvalid, "only an ACTIVE release can be withdrawn", map[string]string{"state": locked.State})
	}
	release, err := domain.ParseReleaseWithoutManifest(locked)
	if err != nil {
		return Activation{}, err
	}
	if err := commands.Store.WithdrawTx(ctx, transaction, release.Version.String(), at); err != nil {
		return Activation{}, err
	}
	activationID, err := commands.Store.InsertActivationTx(ctx, transaction, ActivationRow{ReleaseID: locked.ID, Version: release.Version.String(), Action: "WITHDRAW", CommandKey: commandKey, At: at})
	if err != nil {
		return Activation{}, err
	}
	return Activation{ActivationID: activationID, Version: release.Version.String(), Action: "WITHDRAW", State: string(domain.StateWithdrawn), At: at}, nil
}

// lockTarget reads the target to find its lane, then locks that lane's ACTIVE
// rows plus the target, ordered by version, and returns the target row and the
// locked set.
func (commands Commands) lockTarget(ctx context.Context, transaction tx.Tx, versionText string) (domain.RawRelease, domain.Lane, []domain.RawRelease, error) {
	version, err := domain.ParseVersion(versionText)
	if err != nil {
		return domain.RawRelease{}, "", nil, operator.Refuse(CodePayloadInvalid, err.Error(), nil)
	}
	target, err := commands.Store.ReleaseTx(ctx, transaction, version.String())
	if err != nil {
		return domain.RawRelease{}, "", nil, err
	}
	if target == nil {
		return domain.RawRelease{}, "", nil, operator.Refuse(CodeReleaseUnknown, "the release number does not exist", map[string]string{"version": version.String()})
	}
	lane, err := domain.ParseLane(target.Lane)
	if err != nil {
		return domain.RawRelease{}, "", nil, err
	}
	rows, err := commands.Store.LockLaneTx(ctx, transaction, lane, version.String())
	if err != nil {
		return domain.RawRelease{}, "", nil, err
	}
	for _, row := range rows {
		if row.Version == version.String() {
			return row, lane, rows, nil
		}
	}
	return domain.RawRelease{}, "", nil, operator.Refuse(CodeReleaseUnknown, "the release number does not exist", map[string]string{"version": version.String()})
}

func countActive(rows []domain.RawRelease) int {
	count := 0
	for _, row := range rows {
		if row.State == string(domain.StateActive) {
			count++
		}
	}
	return count
}

func (commands Commands) checkRevision(ctx context.Context, transaction tx.Queryer, expected *int64) error {
	if expected == nil {
		return operator.Refuse(CodeRevisionRequired, "expected_revision is required for this command", nil)
	}
	current, err := commands.Store.ActiveRevisionTx(ctx, transaction)
	if err != nil {
		return err
	}
	if *expected != current {
		return operator.StaleRevision(current)
	}
	return nil
}

func (commands Commands) verifyVolumes(release domain.Release) error {
	if commands.Root == "" {
		return operator.Refuse(CodeRootUnavailable, "the OTA root is not configured, so the release volumes cannot be verified", nil)
	}
	for _, volume := range release.Volumes {
		path := filepath.Join(commands.Root, "updates", string(release.Lane), volume.Name)
		info, err := os.Stat(path)
		if err != nil || !info.Mode().IsRegular() || info.Size() != volume.Size {
			return operator.Refuse(CodeVolumeMissing, "a release volume is missing or has another size under the OTA root", map[string]string{"volume": volume.Name})
		}
	}
	return nil
}

// laneVersions returns the lane's highest ACTIVE version and its highest BUILT
// one. The active version decides a rollback; when nothing is active the
// highest built version names the line a new build must keep (G23).
func laneVersions(rows []domain.RawRelease) (*domain.Version, *domain.Version, error) {
	var active, highestBuilt *domain.Version
	for _, row := range rows {
		version, err := domain.ParseVersion(row.Version)
		if err != nil {
			return nil, nil, err
		}
		switch row.State {
		case string(domain.StateActive):
			if active == nil || version.Compare(*active) > 0 {
				active = &version
			}
		case string(domain.StateBuilt):
			if highestBuilt == nil || version.Compare(*highestBuilt) > 0 {
				highestBuilt = &version
			}
		}
	}
	return active, highestBuilt, nil
}
