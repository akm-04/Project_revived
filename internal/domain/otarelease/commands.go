package otarelease

import (
	"encoding/json"
	"errors"
)

// BuildRequest is the ota.register_build payload (I11A_OTA_RELEASE_V1 ruling 3,
// I11A_1_PLAN "Release row shapes").
type BuildRequest struct {
	Version      string          `json:"version"`
	Lane         string          `json:"lane"`
	PackageFiles json.RawMessage `json:"package_files"`
	TotalSize    int64           `json:"total_size"`
	MD5          string          `json:"md5"`
	SHA256       string          `json:"sha256"`
	Manifest     json.RawMessage `json:"manifest"`
	Rollback     bool            `json:"rollback"`
}

// RollbackWarning is owner answer 5, recorded with a rollback registration.
const RollbackWarning = "installed clients will not step down by themselves: players must clear the app's data or reinstall to take the rolled-back release"

var ErrInvalidBuild = errors.New("otarelease: invalid build payload")

// Release validates a new build with the same row rules as a read row and
// returns it in the BUILT state.
func (request BuildRequest) Release() (Release, error) {
	version, err := ParseVersion(request.Version)
	if err != nil {
		return Release{}, errors.Join(ErrInvalidBuild, err)
	}
	lane, err := ParseLane(request.Lane)
	if err != nil {
		return Release{}, errors.Join(ErrInvalidBuild, err)
	}
	release, err := ParseRelease(RawRelease{
		Version:      version.String(),
		Lane:         string(lane),
		State:        string(StateBuilt),
		PackageFiles: request.PackageFiles,
		TotalSize:    request.TotalSize,
		MD5:          request.MD5,
		SHA256:       request.SHA256,
		Manifest:     request.Manifest,
	})
	if err != nil {
		return Release{}, err
	}
	return release, nil
}

// LowersActive reports whether candidate is below the lane's active version,
// which needs the operator's rollback flag (ruling 3).
func LowersActive(candidate Version, active *Version) bool {
	return active != nil && candidate.Compare(*active) < 0
}
