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

// PlanUpdate is the pure MID 2 scheduler of ruling 4. It fails closed with
// ErrInvalidRelease when an active row is malformed, so no partial plan is
// ever served (local_update.py:395-400).
func PlanUpdate(request PlanRequest, publicEngineURL string, rows []RawRelease) (UpdatePlan, error) {
	if request.AppVersion != StockAppVersion {
		return UpdatePlan{UnknownAppVersion: true}, nil
	}
	releases, err := ParseReleases(rows)
	if err != nil {
		return UpdatePlan{}, err
	}
	current, hasCurrent := parseClientVersion(request.ClientVersion)
	selected := selectReleases(releases, current, hasCurrent)
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

// selectReleases applies ruling 4: the asset bootstrap when the client is
// below it, the newest cumulative code release when newer than the client, and
// every newer catalog release, all in ascending version order.
func selectReleases(releases []Release, current Version, hasCurrent bool) []Release {
	selected := make([]Release, 0, 3)
	if asset, found := newestActive(releases, LaneAssets); found && newerThan(asset.Version, current, hasCurrent) {
		selected = append(selected, asset)
	}
	if code, found := newestActive(releases, LaneCode); found && newerThan(code.Version, current, hasCurrent) {
		selected = append(selected, code)
	}
	for _, release := range releases {
		if release.Lane == LaneCatalog && release.State == StateActive && newerThan(release.Version, current, hasCurrent) {
			selected = append(selected, release)
		}
	}
	sort.SliceStable(selected, func(left, right int) bool {
		return selected[left].Version.Compare(selected[right].Version) < 0
	})
	return selected
}

func newestActive(releases []Release, lane Lane) (Release, bool) {
	var newest Release
	found := false
	for _, release := range releases {
		if release.Lane != lane || release.State != StateActive {
			continue
		}
		if !found || release.Version.Compare(newest.Version) > 0 {
			newest = release
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
