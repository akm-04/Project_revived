package otarelease

import "sort"

// LazyAsset is one lazy-fetch requirement of an EVENTS occurrence.
type LazyAsset struct {
	Path string `json:"path"`
	MD5  string `json:"md5"`
}

// CoversRequest is the ARCHITECTURE section 4 requirement set: client paths the
// occurrence ships, lazy assets it fetches, and the minimum code release.
type CoversRequest struct {
	ClientPaths    []string    `json:"client_paths"`
	LazyAssets     []LazyAsset `json:"lazy_assets"`
	MinCodeVersion string      `json:"min_code_version"`
}

// CoversResult is COVERED, or the exact lists that are not.
type CoversResult struct {
	Status             string      `json:"status"`
	MissingClientPaths []string    `json:"missing_client_paths,omitempty"`
	MissingLazyAssets  []LazyAsset `json:"missing_lazy_assets,omitempty"`
	MissingCodeVersion string      `json:"missing_code_version,omitempty"`
}

const (
	CoversCovered = "COVERED"
	CoversMissing = "MISSING"
)

// EvaluateCovers is the pure part of Covers: an unreadable lazy asset is the
// caller's lazyPresent answer, so this decision is testable without a disk.
func EvaluateCovers(request CoversRequest, clientPaths []string, codeVersion *Version, lazyPresent func(LazyAsset) bool) CoversResult {
	result := CoversResult{Status: CoversCovered}
	shipped := make(map[string]struct{}, len(clientPaths))
	for _, path := range clientPaths {
		shipped[path] = struct{}{}
	}
	for _, path := range request.ClientPaths {
		if _, ok := shipped[path]; !ok {
			result.MissingClientPaths = append(result.MissingClientPaths, path)
		}
	}
	for _, asset := range request.LazyAssets {
		if lazyPresent == nil || !lazyPresent(asset) {
			result.MissingLazyAssets = append(result.MissingLazyAssets, asset)
		}
	}
	if request.MinCodeVersion != "" {
		minimum, err := ParseVersion(request.MinCodeVersion)
		if err != nil || codeVersion == nil || codeVersion.Compare(minimum) < 0 {
			result.MissingCodeVersion = request.MinCodeVersion
		}
	}
	sort.Strings(result.MissingClientPaths)
	if len(result.MissingClientPaths) > 0 || len(result.MissingLazyAssets) > 0 || result.MissingCodeVersion != "" {
		result.Status = CoversMissing
	}
	return result
}
