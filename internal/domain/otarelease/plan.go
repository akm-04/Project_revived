package otarelease

import (
	"sort"
	"strings"
)

// StockAppVersion is the stock APK version name (ruling 4); it is the only
// app_v the scheduler knows.
const StockAppVersion = "1.631.0"

// PlanRequest is the MID 2 request: the client resource version, the APK
// version name and the platform id (UpdateScene_64.lua:1021-1028).
type PlanRequest struct {
	ClientVersion string
	AppVersion    string
	Platform      int64
}

// Descriptor is one MID 2 res row; the client downloads
// "<resource>.001".."<resource>.NNN" (UpdateScene_64.lua:1351).
type Descriptor struct {
	Version  string
	Volume   int
	Size     int64
	MD5      string
	Resource string
}

// UpdatePlan is the scheduler result. An empty Descriptors list is the stock
// no-update reply; UnknownAppVersion asks the caller for one ANOMALY log line.
type UpdatePlan struct {
	Descriptors       []Descriptor
	IsReview          bool
	UnknownAppVersion bool
}

// PlanUpdate is the pure MID 2 scheduler of ruling 4. Selection runs before
// validation: a defect in a selected release fails the whole plan, while an
// unselected row never affects MID 2. The manifest is not read on this path.
func PlanUpdate(request PlanRequest, publicEngineURL string, rows []RawRelease) (UpdatePlan, error) {
	if request.AppVersion != StockAppVersion {
		return UpdatePlan{UnknownAppVersion: true}, nil
	}
	current, hasCurrent := parseClientVersion(request.ClientVersion)
	selectedIndexes := selectReleaseIndexes(rows, current, hasCurrent)
	selected := make([]Release, 0, len(selectedIndexes))
	for _, index := range selectedIndexes {
		release, err := ParseReleaseWithoutManifest(rows[index])
		if err != nil {
			return UpdatePlan{}, err
		}
		selected = append(selected, release)
	}
	plan := UpdatePlan{Descriptors: make([]Descriptor, 0, len(selected))}
	for _, release := range selected {
		plan.Descriptors = append(plan.Descriptors, descriptorFor(release, publicEngineURL))
	}
	plan.IsReview = everyReleaseSilent(selected)
	return plan, nil
}

// ActiveRelease is the cross-contract view of ARCHITECTURE section 4: the
// active version per lane and the union of shipped client paths.
type ActiveRelease struct {
	CodeVersion    *Version
	AssetVersion   *Version
	CatalogVersion *Version
	ClientPaths    []string
}

// ActiveSet validates the rows and summarizes every ACTIVE release.
func ActiveSet(rows []RawRelease) (ActiveRelease, error) {
	releases, err := ParseReleases(rows)
	if err != nil {
		return ActiveRelease{}, err
	}
	var active ActiveRelease
	paths := map[string]struct{}{}
	for _, release := range releases {
		if release.State != StateActive {
			continue
		}
		switch release.Lane {
		case LaneCode:
			keepNewest(&active.CodeVersion, release.Version)
		case LaneAssets:
			keepNewest(&active.AssetVersion, release.Version)
		case LaneCatalog:
			keepNewest(&active.CatalogVersion, release.Version)
		}
		for _, entry := range release.Manifest {
			paths[entry.Path] = struct{}{}
		}
	}
	active.ClientPaths = make([]string, 0, len(paths))
	for path := range paths {
		active.ClientPaths = append(active.ClientPaths, path)
	}
	sort.Strings(active.ClientPaths)
	return active, nil
}

func keepNewest(current **Version, candidate Version) {
	if *current == nil || candidate.Compare(**current) > 0 {
		version := candidate
		*current = &version
	}
}

// releaseCandidate is the selection view of one row. A row whose version, lane
// or state does not parse cannot be selected, so selection skips it.
type releaseCandidate struct {
	index   int
	version Version
	lane    Lane
	state   State
}

func releaseCandidates(rows []RawRelease) []releaseCandidate {
	candidates := make([]releaseCandidate, 0, len(rows))
	for index, row := range rows {
		version, err := ParseVersion(row.Version)
		if err != nil {
			continue
		}
		lane, err := ParseLane(row.Lane)
		if err != nil {
			continue
		}
		state, err := ParseState(row.State)
		if err != nil {
			continue
		}
		candidates = append(candidates, releaseCandidate{index: index, version: version, lane: lane, state: state})
	}
	return candidates
}

// selectReleaseIndexes applies ruling 4: the asset bootstrap when the client is
// below it, the newest cumulative code release when newer than the client, and
// every newer catalog release, all in ascending version order.
func selectReleaseIndexes(rows []RawRelease, current Version, hasCurrent bool) []int {
	candidates := releaseCandidates(rows)
	selected := make([]releaseCandidate, 0, 3)
	if asset, found := newestActiveCandidate(candidates, LaneAssets); found && newerThan(asset.version, current, hasCurrent) {
		selected = append(selected, asset)
	}
	if code, found := newestActiveCandidate(candidates, LaneCode); found && newerThan(code.version, current, hasCurrent) {
		selected = append(selected, code)
	}
	for _, candidate := range candidates {
		if candidate.lane == LaneCatalog && candidate.state == StateActive && newerThan(candidate.version, current, hasCurrent) {
			selected = append(selected, candidate)
		}
	}
	sort.SliceStable(selected, func(left, right int) bool {
		return selected[left].version.Compare(selected[right].version) < 0
	})
	indexes := make([]int, 0, len(selected))
	for _, candidate := range selected {
		indexes = append(indexes, candidate.index)
	}
	return indexes
}

func newestActiveCandidate(candidates []releaseCandidate, lane Lane) (releaseCandidate, bool) {
	var newest releaseCandidate
	found := false
	for _, candidate := range candidates {
		if candidate.lane != lane || candidate.state != StateActive {
			continue
		}
		if !found || candidate.version.Compare(newest.version) > 0 {
			newest = candidate
			found = true
		}
	}
	return newest, found
}

// newerThan treats an empty or unparseable client version as older than every
// release, as V1 does (local_update.py:313-328, current_key is None).
func newerThan(version, current Version, hasCurrent bool) bool {
	return !hasCurrent || version.Compare(current) > 0
}

func parseClientVersion(text string) (Version, bool) {
	trimmed := strings.TrimSpace(text)
	if trimmed == "" {
		return Version{}, false
	}
	version, err := ParseVersion(trimmed)
	if err != nil {
		return Version{}, false
	}
	return version, true
}

func descriptorFor(release Release, publicEngineURL string) Descriptor {
	return Descriptor{
		Version:  release.Version.String(),
		Volume:   len(release.Volumes),
		Size:     release.TotalSize,
		MD5:      release.MD5,
		Resource: strings.TrimRight(publicEngineURL, "/") + "/updates/" + string(release.Lane) + "/" + release.PackageBase,
	}
}

func everyReleaseSilent(releases []Release) bool {
	if len(releases) == 0 {
		return false
	}
	for _, release := range releases {
		if !release.Lane.Silent() {
			return false
		}
	}
	return true
}
