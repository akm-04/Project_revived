package otabuild

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"gxb.local/backend/v2/internal/domain/otarelease"
)

// lazyRefreshPackage rebuilds the code lane's lazyFile.json with the assets
// lane's own rule (buildLazyMap): the stock catalogue rows are the input and the
// ACTIVE assets release's delivered paths are `supplied`. force=1 and delivered
// rows get no marker; every other force=0 row keeps one. A row whose file is
// recovered under recovered_res_path carries that file's md5 and size and is
// added to the code release's res sidecar, so /res serves it at that md5
// (OA-8, OA-9).
//
// The same recovered rows are returned as a catalogue document: the client
// builds every load-on-demand URL from version.json (AssetDownload.getDownloadInfo_,
// basename.md5) and verifies the download against it, so a recovered file whose
// bytes differ from the stock catalogue can only be fetched once the client's
// version.json carries its md5 and size. A shipped src_32/src_64 version.json is
// promoted to the client's own catalogue at the next boot
// (UpdateScene_64.lua:424-462), which is the silent-patch route for it.
func lazyRefreshPackage(recoveredResPath, sidecarPath string, catalogBaseline stockBaseline, version string) ([]byte, []byte, []resSidecarEntry, Report, error) {
	report := Report{Lane: string(otarelease.LaneCode), Version: version, MissingSample: []string{}, MismatchSample: []string{}}
	rows, err := readCatalog(catalogBaseline)
	if err != nil {
		return nil, nil, nil, report, err
	}
	root, err := resolveRecoveredResRoot(recoveredResPath)
	if err != nil {
		return nil, nil, nil, report, err
	}
	deliveredEntries, err := readResourceSidecar(sidecarPath)
	if err != nil {
		return nil, nil, nil, report, err
	}
	supplied, err := deliveredCataloguePaths(deliveredEntries)
	if err != nil {
		return nil, nil, nil, report, err
	}
	if len(supplied) == 0 {
		return nil, nil, nil, report, fmt.Errorf("%w: the active assets release delivered no file", ErrNoExactAssets)
	}
	rows, sidecar, recovered, err := recoveredLazyRows(rows, supplied, root)
	if err != nil {
		return nil, nil, nil, report, err
	}
	extras, err := readExtraCatalogue(root)
	if err != nil {
		return nil, nil, nil, report, err
	}
	rows, sidecar, err = appendExtraRows(rows, sidecar, extras)
	if err != nil {
		return nil, nil, nil, report, err
	}
	lazyMap, summary, err := buildLazyMap(rows, supplied)
	if err != nil {
		return nil, nil, nil, report, err
	}
	if err := checkDeliveredUnmarked(lazyMap, supplied); err != nil {
		return nil, nil, nil, report, err
	}
	if len(lazyMap) == 0 {
		return nil, nil, nil, report, fmt.Errorf("%w: the lazy refresh would ship no marker", ErrCatalogInvalid)
	}
	report.LazyConsidered = summary.considered
	report.LazySupplied = summary.supplied
	report.LazyRetained = summary.retained
	report.LazyRecovered = recovered
	lazyBytes, err := marshalLazyFile(lazyMap)
	if err != nil {
		return nil, nil, nil, report, err
	}
	catalogBytes, err := marshalCatalog(rows)
	if err != nil {
		return nil, nil, nil, report, err
	}
	sort.Slice(sidecar, func(left, right int) bool { return sidecar[left].Path < sidecar[right].Path })
	return lazyBytes, catalogBytes, sidecar, report, nil
}

// marshalCatalog serialises the refreshed rows in the stock file's shape so the
// client can read it as its own catalogue.
func marshalCatalog(rows []catalogRow) ([]byte, error) {
	encoded, err := marshalNoEscape(rows)
	if err != nil {
		return nil, err
	}
	return append(encoded, '\n'), nil
}

// deliveredCataloguePaths maps the assets release's res-index paths to the
// catalogue paths buildLazyMap compares against.
func deliveredCataloguePaths(entries []resSidecarEntry) (map[string]struct{}, error) {
	supplied := make(map[string]struct{}, len(entries))
	for _, entry := range entries {
		resourcePath := normalizeCatalogPath(entry.Path)
		if !validCatalogPath(resourcePath) || !validMD5(strings.ToLower(entry.MD5)) {
			return nil, fmt.Errorf("%w: asset sidecar row %q", ErrCatalogInvalid, entry.Path)
		}
		supplied[cataloguePathFromResource(resourcePath)] = struct{}{}
	}
	return supplied, nil
}

// resolveRecoveredResRoot resolves the optional recovery folder; empty means the
// build has no recovered files, a set but unusable folder is refused (OA-9).
func resolveRecoveredResRoot(recoveredResPath string) (resRoot, error) {
	if recoveredResPath == "" {
		return resRoot{}, nil
	}
	root, err := resolveResRoot(recoveredResPath)
	if err != nil {
		return resRoot{}, fmt.Errorf("%w: %v", ErrRecoveredResPathMissing, err)
	}
	return root, nil
}

// recoveredLazyRows replaces a marker row's catalogue md5 and size with the
// file found under recovered_res_path and returns the sidecar rows for every
// marker. An unrecovered row keeps its catalogue row and points at the path the
// recovery lane will supply (res/web/... -> web/...).
func recoveredLazyRows(rows []catalogRow, supplied map[string]struct{}, root resRoot) ([]catalogRow, []resSidecarEntry, int, error) {
	adjusted := make([]catalogRow, len(rows))
	copy(adjusted, rows)
	sidecar := make([]resSidecarEntry, 0, len(rows))
	recovered := 0
	for index := range adjusted {
		row := &adjusted[index]
		if row.Force == 1 {
			continue
		}
		catalogPath := normalizeCatalogPath(row.Path)
		if catalogPath == "" {
			continue
		}
		if _, delivered := supplied[catalogPath]; delivered {
			continue
		}
		relative, size, md5Text, found, err := recoveredFile(root, catalogPath)
		if err != nil {
			return nil, nil, 0, err
		}
		if found {
			row.MD5 = md5Text
			row.Size = size
			recovered++
			sidecar = append(sidecar, resSidecarEntry{Path: relative, MD5: md5Text, Size: size})
			continue
		}
		sidecar = append(sidecar, resSidecarEntry{Path: strings.TrimPrefix(catalogPath, "res/"), MD5: strings.ToLower(row.MD5), Size: row.Size})
	}
	return adjusted, sidecar, recovered, nil
}

// checkDeliveredUnmarked fails closed when the map and delivered set overlap.
func checkDeliveredUnmarked(lazyMap map[string]string, supplied map[string]struct{}) error {
	for catalogPath := range supplied {
		key, err := lazyKey(catalogPath)
		if err != nil {
			continue
		}
		if _, marked := lazyMap[key]; marked {
			return fmt.Errorf("%w: the delivered path %q kept a lazy marker", ErrCatalogInvalid, catalogPath)
		}
	}
	return nil
}

func readResourceSidecar(path string) ([]resSidecarEntry, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil, fmt.Errorf("%w: the active assets sidecar is missing: %v", ErrNoExactAssets, err)
		}
		return nil, fmt.Errorf("%w: active assets sidecar: %v", ErrBuildIO, err)
	}
	var document resSidecarDocument
	if err := json.Unmarshal(content, &document); err != nil {
		return nil, fmt.Errorf("%w: active assets sidecar: %v", ErrCatalogInvalid, err)
	}
	return document.Entries, nil
}

// recoveredFile finds the current file for a catalogue row through the same
// candidate forms the assets lane collects, and returns its path relative to
// recovered_res_path plus its current size and md5.
func recoveredFile(root resRoot, catalogPath string) (string, int64, string, bool, error) {
	if root.lexical == "" {
		return "", 0, "", false, nil
	}
	for _, candidate := range assetCandidates(root.lexical, catalogPath) {
		info, err := os.Stat(candidate)
		if err != nil || !info.Mode().IsRegular() {
			continue
		}
		resolved, ok := withinResRoot(root, candidate)
		if !ok {
			continue
		}
		size, md5Text, err := digestFile(resolved)
		if err != nil {
			return "", 0, "", false, err
		}
		relative, err := filepath.Rel(root.lexical, candidate)
		if err != nil {
			return "", 0, "", false, fmt.Errorf("%w: asset path: %v", ErrBuildIO, err)
		}
		return filepath.ToSlash(relative), size, md5Text, true, nil
	}
	return "", 0, "", false, nil
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
