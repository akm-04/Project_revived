package otarelease

import (
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"strings"
)

// Lane is one immutable artifact line. Assets and catalog releases are loud,
// the cumulative code lane is silent (ruling 1).
type Lane string

const (
	LaneAssets  Lane = "assets"
	LaneCode    Lane = "code"
	LaneCatalog Lane = "catalog"
)

func ParseLane(text string) (Lane, error) {
	lane := Lane(text)
	switch lane {
	case LaneAssets, LaneCode, LaneCatalog:
		return lane, nil
	}
	return "", fmt.Errorf("otarelease: unknown lane %q", text)
}

// Silent reports whether the client applies the lane without the update prompt.
func (l Lane) Silent() bool { return l == LaneCode }

// State is the release lifecycle of ruling 2.
type State string

const (
	StateBuilt      State = "BUILT"
	StateActive     State = "ACTIVE"
	StateSuperseded State = "SUPERSEDED"
	StateWithdrawn  State = "WITHDRAWN"
)

func ParseState(text string) (State, error) {
	state := State(text)
	switch state {
	case StateBuilt, StateActive, StateSuperseded, StateWithdrawn:
		return state, nil
	}
	return "", fmt.Errorf("otarelease: unknown state %q", text)
}

// PackageVolume is one entry of the row's package_files array (I11A_1_PLAN
// "Release row shapes"). The client appends ".NNN" to the descriptor resource.
type PackageVolume struct {
	Name   string `json:"name"`
	Size   int64  `json:"size"`
	MD5    string `json:"md5"`
	SHA256 string `json:"sha256"`
}

// ManifestEntry is one shipped client path inside the assembled zip.
type ManifestEntry struct {
	Path string `json:"path"`
	Size int64  `json:"size"`
	MD5  string `json:"md5"`
}

// Release is a validated ota_releases row.
type Release struct {
	Version     Version
	Lane        Lane
	State       State
	PackageBase string
	Volumes     []PackageVolume
	TotalSize   int64
	MD5         string
	SHA256      string
	Manifest    []ManifestEntry
}

// RawRelease is the store's read shape, JSON-tagged for the jsonb aggregate.
type RawRelease struct {
	Version      string          `json:"version"`
	Lane         string          `json:"lane"`
	State        string          `json:"state"`
	PackageFiles json.RawMessage `json:"package_files"`
	TotalSize    int64           `json:"total_size"`
	MD5          string          `json:"md5"`
	SHA256       string          `json:"sha256"`
	Manifest     json.RawMessage `json:"manifest"`
}

// ErrInvalidRelease marks a database row that violates the release row shape.
// The planner fails closed on it and never serves a partial plan.
var ErrInvalidRelease = errors.New("otarelease: invalid release row")

const (
	// maxVolumeBytes is ruling 5: the stock client cannot take a larger volume.
	maxVolumeBytes int64 = 99_000_000
	// MaxTotalBytes keeps the total under 2^31-1 (ruling 5, migration 00184).
	MaxTotalBytes int64 = 2_147_483_647
)

var (
	md5Pattern    = regexp.MustCompile(`^[0-9a-f]{32}$`)
	sha256Pattern = regexp.MustCompile(`^[0-9a-f]{64}$`)
)

// ParseReleases validates every row. Any bad row fails the whole read, so a
// caller never builds a plan from a partially valid active set.
func ParseReleases(rows []RawRelease) ([]Release, error) {
	releases := make([]Release, 0, len(rows))
	for _, row := range rows {
		release, err := ParseRelease(row)
		if err != nil {
			return nil, err
		}
		releases = append(releases, release)
	}
	return releases, nil
}

// ParseRelease validates one ota_releases row against the lead's row shape,
// including its manifest.
func ParseRelease(row RawRelease) (Release, error) {
	release, err := ParseReleaseWithoutManifest(row)
	if err != nil {
		return Release{}, err
	}
	manifest, err := parseManifest(row.Manifest)
	if err != nil {
		return Release{}, err
	}
	release.Manifest = manifest
	return release, nil
}

// ParseReleaseWithoutManifest validates only the columns the MID 2 plan reads;
// the manifest is read by the ActiveRelease path only.
func ParseReleaseWithoutManifest(row RawRelease) (Release, error) {
	version, err := ParseVersion(row.Version)
	if err != nil {
		return Release{}, invalid(err)
	}
	lane, err := ParseLane(row.Lane)
	if err != nil {
		return Release{}, invalid(err)
	}
	state, err := ParseState(row.State)
	if err != nil {
		return Release{}, invalid(err)
	}
	if !md5Pattern.MatchString(row.MD5) || !sha256Pattern.MatchString(row.SHA256) {
		return Release{}, invalid(errors.New("release hashes are not lowercase hex"))
	}
	volumes, packageBase, err := parseVolumes(row.PackageFiles, version, row.SHA256)
	if err != nil {
		return Release{}, err
	}
	total := int64(0)
	for _, volume := range volumes {
		total += volume.Size
	}
	if row.TotalSize <= 0 || row.TotalSize >= MaxTotalBytes || total != row.TotalSize {
		return Release{}, invalid(fmt.Errorf("volumes total %d do not match total_size %d", total, row.TotalSize))
	}
	return Release{
		Version:     version,
		Lane:        lane,
		State:       state,
		PackageBase: packageBase,
		Volumes:     volumes,
		TotalSize:   row.TotalSize,
		MD5:         row.MD5,
		SHA256:      row.SHA256,
	}, nil
}

func invalid(err error) error {
	return fmt.Errorf("%w: %v", ErrInvalidRelease, err)
}

// parseVolumes requires names .001..NNN without gaps that share the
// "<version>-<sha256[:12]>.zip" base.
func parseVolumes(raw json.RawMessage, version Version, sha256 string) ([]PackageVolume, string, error) {
	var volumes []PackageVolume
	if err := json.Unmarshal(raw, &volumes); err != nil {
		return nil, "", invalid(err)
	}
	if len(volumes) == 0 {
		return nil, "", invalid(errors.New("release has no package volume"))
	}
	packageBase := ""
	for index, volume := range volumes {
		base, err := volumeBase(volume.Name, index+1)
		if err != nil {
			return nil, "", err
		}
		if packageBase == "" {
			packageBase = base
		}
		if base != packageBase {
			return nil, "", invalid(fmt.Errorf("volume %q does not share the package base", volume.Name))
		}
		if volume.Size <= 0 || volume.Size > maxVolumeBytes {
			return nil, "", invalid(fmt.Errorf("volume %q size %d is outside the stock limit", volume.Name, volume.Size))
		}
		if int64(float32(volume.Size)) != volume.Size {
			return nil, "", invalid(fmt.Errorf("volume %q size %d is not float32-exact", volume.Name, volume.Size))
		}
		if !md5Pattern.MatchString(volume.MD5) || !sha256Pattern.MatchString(volume.SHA256) {
			return nil, "", invalid(fmt.Errorf("volume %q hashes are not lowercase hex", volume.Name))
		}
	}
	expected := fmt.Sprintf("%s-%s.zip", version.String(), sha256[:12])
	if packageBase != expected {
		return nil, "", invalid(fmt.Errorf("package base %q is not %q", packageBase, expected))
	}
	return volumes, packageBase, nil
}

func volumeBase(name string, position int) (string, error) {
	dot := strings.LastIndexByte(name, '.')
	if dot <= 0 {
		return "", invalid(fmt.Errorf("volume name %q has no .NNN suffix", name))
	}
	suffix := name[dot+1:]
	if suffix != fmt.Sprintf("%03d", position) {
		return "", invalid(fmt.Errorf("volume name %q is not volume %03d", name, position))
	}
	return name[:dot], nil
}

// parseManifest requires {"files":[...]} sorted by path with no duplicates.
func parseManifest(raw json.RawMessage) ([]ManifestEntry, error) {
	var document struct {
		Files []ManifestEntry `json:"files"`
	}
	if err := json.Unmarshal(raw, &document); err != nil {
		return nil, invalid(err)
	}
	manifest := make([]ManifestEntry, 0, len(document.Files))
	previous := ""
	for _, entry := range document.Files {
		if entry.Path == "" || (previous != "" && entry.Path <= previous) {
			return nil, invalid(fmt.Errorf("manifest path %q is empty, unsorted or duplicated", entry.Path))
		}
		if entry.Size < 0 || !md5Pattern.MatchString(entry.MD5) {
			return nil, invalid(fmt.Errorf("manifest entry %q is not a file with a lowercase md5", entry.Path))
		}
		previous = entry.Path
		manifest = append(manifest, entry)
	}
	return manifest, nil
}
