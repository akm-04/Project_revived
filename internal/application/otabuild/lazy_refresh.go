package otabuild

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"gxb.local/backend/v2/internal/domain/otarelease"
)

// lazyRefreshResource is one lazy marker value for the silent refresh; it has
// the same shape as the assets lane's value minus the catalogue version.
type lazyRefreshResource struct {
	Size int64  `json:"size"`
	MD5  string `json:"md5"`
	Path string `json:"path"`
}

// lazyRefreshPackage rebuilds the code lane's lazyFile.json from the ACTIVE
// assets release's sidecar: a file recovered under res_path contributes its
// current md5 and size, an unrecovered entry keeps its sidecar row (L4f silent
// lazy refresh). It also returns the code release's res sidecar.
func lazyRefreshPackage(resPath, sidecarPath, version string) ([]byte, []resSidecarEntry, Report, error) {
	report := Report{Lane: string(otarelease.LaneCode), Version: version, MissingSample: []string{}, MismatchSample: []string{}}
	root, err := resolveResRoot(resPath)
	if err != nil {
		return nil, nil, report, err
	}
	entries, err := readResourceSidecar(sidecarPath)
	if err != nil {
		return nil, nil, report, err
	}
	lazyMap := make(map[string]string, len(entries))
	sidecar := make([]resSidecarEntry, 0, len(entries))
	for _, entry := range entries {
		resourcePath := normalizeCatalogPath(entry.Path)
		if !validCatalogPath(resourcePath) || !validMD5(strings.ToLower(entry.MD5)) {
			return nil, nil, report, fmt.Errorf("%w: asset sidecar row %q", ErrCatalogInvalid, entry.Path)
		}
		row := resSidecarEntry{Path: resourcePath, MD5: strings.ToLower(entry.MD5), Size: entry.Size}
		report.LazyConsidered++
		if resolved, found := recoveredFile(root, resourcePath); found {
			size, md5Text, digestErr := digestFile(resolved)
			if digestErr != nil {
				return nil, nil, report, digestErr
			}
			row.MD5, row.Size = md5Text, size
			report.LazySupplied++
		} else {
			report.LazyRetained++
		}
		clientPath := cataloguePathFromResource(resourcePath)
		value, valueErr := marshalNoEscape(lazyRefreshResource{Size: row.Size, MD5: row.MD5, Path: clientPath})
		if valueErr != nil {
			return nil, nil, report, fmt.Errorf("%w: lazy value: %v", ErrCatalogInvalid, valueErr)
		}
		key, keyErr := lazyKey(clientPath)
		if keyErr != nil {
			return nil, nil, report, keyErr
		}
		lazyMap[key] = string(value)
		sidecar = append(sidecar, row)
	}
	lazyBytes, err := marshalLazyFile(lazyMap)
	if err != nil {
		return nil, nil, report, err
	}
	sort.Slice(sidecar, func(left, right int) bool { return sidecar[left].Path < sidecar[right].Path })
	return lazyBytes, sidecar, report, nil
}

func readResourceSidecar(path string) ([]resSidecarEntry, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("%w: active assets sidecar: %v", ErrBuildIO, err)
	}
	var document resSidecarDocument
	if err := json.Unmarshal(content, &document); err != nil {
		return nil, fmt.Errorf("%w: active assets sidecar: %v", ErrCatalogInvalid, err)
	}
	return document.Entries, nil
}

// recoveredFile finds the current file for a sidecar row: the exact place the
// loud build found it, then the plan's res/ alias for a res/web/ path.
func recoveredFile(root resRoot, resourcePath string) (string, bool) {
	candidates := []string{filepath.Join(root.lexical, filepath.FromSlash(resourcePath))}
	if rest, isWeb := strings.CutPrefix(resourcePath, "res/web/"); isWeb {
		candidates = append(candidates, filepath.Join(root.lexical, "res", filepath.FromSlash(rest)))
	}
	for _, candidate := range candidates {
		info, err := os.Stat(candidate)
		if err != nil || !info.Mode().IsRegular() {
			continue
		}
		if resolved, ok := withinResRoot(root, candidate); ok {
			return resolved, true
		}
	}
	return "", false
}

// cataloguePathFromResource maps a res_path-relative candidate back to the
// client lazy path (res/web/...).
func cataloguePathFromResource(resourcePath string) string {
	switch {
	case strings.HasPrefix(resourcePath, "res/web/"):
		return resourcePath
	case strings.HasPrefix(resourcePath, "web/"):
		return "res/" + resourcePath
	case strings.HasPrefix(resourcePath, "res/"):
		return "res/web/" + strings.TrimPrefix(resourcePath, "res/")
	default:
		return "res/web/" + resourcePath
	}
}

func digestFile(path string) (int64, string, error) {
	file, err := os.Open(path)
	if err != nil {
		return 0, "", fmt.Errorf("%w: %v", ErrBuildIO, err)
	}
	defer file.Close()
	digest := md5.New()
	size, err := io.Copy(digest, file)
	if err != nil {
		return 0, "", fmt.Errorf("%w: %v", ErrBuildIO, err)
	}
	return size, hex.EncodeToString(digest.Sum(nil)), nil
}
