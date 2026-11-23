package otabuild

import (
	"bytes"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path"
	"path/filepath"
	"sort"
	"strings"

	"gxb.local/backend/v2/internal/domain/otarelease"
)

// The assets lane is the Go port of V1's bulk writable bootstrap: the stock
// catalogue is the only authority for path, md5 and size, the package is the
// exact-current force=0 res/web files plus a reconciled lazyFile.json, and it
// carries no version.json (I11A_1_PLAN "L4c decisions").

const lazyFileMember = "lazyFile.json"

// catalogMember is the client's own load-on-demand catalogue, which the client
// promotes from src_32/src_64 to its writable root at the next boot. A lazy
// refresh ships it so a recovered file (different bytes) is requested at its own
// md5 instead of the lost stock one.
const catalogMember = "version.json"

// catalogRow is one version.json row. Only the fields the collection and the
// lazy state need are decoded; the stock file also carries rows for src_32 and
// src_64, which the assets lane ignores.
type catalogRow struct {
	Path    string          `json:"path"`
	MD5     string          `json:"md5"`
	Size    int64           `json:"size"`
	Force   int             `json:"force"`
	Version json.RawMessage `json:"version,omitempty"`
}

// assetFile is one exact-current file found on disk. source is the resolved
// path (the bytes that are shipped) and relative is the candidate path relative
// to res_path (the res index row and the V1 alias source).
type assetFile struct {
	source      string
	relative    string
	catalogPath string
	archiveName string
	size        int64
	md5         string
}

// Report is the build report the agent records in the operation: the collection
// counts, the physical bytes and the first 100 missing and mismatching paths
// (I11A_1_PLAN "L4c decisions").
type Report struct {
	Lane           string   `json:"lane"`
	Version        string   `json:"version"`
	Considered     int      `json:"considered"`
	Exact          int      `json:"exact"`
	Missing        int      `json:"missing"`
	Mismatching    int      `json:"mismatching"`
	PhysicalBytes  int64    `json:"physical_bytes"`
	LazyConsidered int      `json:"lazy_considered"`
	LazySupplied   int      `json:"lazy_supplied"`
	LazyRetained   int      `json:"lazy_retained"`
	LazyRecovered  int      `json:"lazy_recovered"`
	MissingSample  []string `json:"missing_sample"`
	MismatchSample []string `json:"mismatch_sample"`
}

const reportSampleLimit = 100

type lazyStateSummary struct {
	considered int
	supplied   int
	retained   int
}

// assetsPackage reads the stock catalogue, collects the exact-current files and
// produces the package entries (found files plus lazyFile.json) and the res
// sidecar entries.
func assetsPackage(resPath, version string, baseline stockBaseline) ([]packageEntry, []resSidecarEntry, Report, error) {
	report := Report{Lane: string(otarelease.LaneAssets), Version: version, MissingSample: []string{}, MismatchSample: []string{}}
	rows, err := readCatalog(baseline)
	if err != nil {
		return nil, nil, report, err
	}
	root, err := resolveResRoot(resPath)
	if err != nil {
		return nil, nil, report, err
	}
	files, summary, err := collectExactAssets(rows, root)
	if err != nil {
		return nil, nil, report, err
	}
	supplied := make(map[string]struct{}, len(files))
	for _, file := range files {
		supplied[file.catalogPath] = struct{}{}
		report.PhysicalBytes += file.size
	}
	lazyMap, lazySummary, err := buildLazyMap(rows, supplied)
	if err != nil {
		return nil, nil, report, err
	}
	if lazySummary.supplied != len(files) {
		return nil, nil, report, fmt.Errorf("%w: %d exact files but %d supplied lazy rows", ErrCatalogInvalid, len(files), lazySummary.supplied)
	}
	lazyBytes, err := marshalLazyFile(lazyMap)
	if err != nil {
		return nil, nil, report, err
	}
	report.Considered = summary.considered
	report.Exact = len(files)
	report.Missing = summary.missing
	report.Mismatching = summary.mismatching
	report.LazyConsidered = lazySummary.considered
	report.LazySupplied = lazySummary.supplied
	report.LazyRetained = lazySummary.retained
	report.MissingSample = sample(summary.missingPaths)
	report.MismatchSample = sample(summary.mismatchPaths)

	entries := make([]packageEntry, 0, len(files)+1)
	sidecar := make([]resSidecarEntry, 0, len(files))
	for _, file := range files {
		entries = append(entries, packageEntry{path: file.archiveName, source: file.source, size: file.size, md5: file.md5})
		sidecar = append(sidecar, resSidecarEntry{Path: file.relative, MD5: file.md5, Size: file.size})
	}
	entries = append(entries, packageEntry{path: lazyFileMember, content: lazyBytes, size: int64(len(lazyBytes)), md5: md5Hex(lazyBytes)})
	sort.Slice(entries, func(left, right int) bool { return entries[left].path < entries[right].path })
	sort.Slice(sidecar, func(left, right int) bool { return sidecar[left].Path < sidecar[right].Path })
	return entries, sidecar, report, nil
}

func sample(paths []string) []string {
	if len(paths) > reportSampleLimit {
		return paths[:reportSampleLimit]
	}
	return paths
}

// readCatalog reads the official catalogue and refuses when the two stock ABIs
// disagree (ruling 8: the copies are byte-identical; an ABI difference needs a
// new owner decision).
func readCatalog(baseline stockBaseline) ([]catalogRow, error) {
	content64, err := baseline.read(stockPrefix64 + "version.json")
	if err != nil {
		return nil, fmt.Errorf("%w: version.json: %v", ErrCatalogInvalid, err)
	}
	content32, err := baseline.read(stockPrefix32 + "version.json")
	if err != nil {
		return nil, fmt.Errorf("%w: version.json: %v", ErrCatalogInvalid, err)
	}
	if !bytes.Equal(content64, content32) {
		return nil, fmt.Errorf("%w: version.json", ErrAbiMismatch)
	}
	decoder := json.NewDecoder(bytes.NewReader(content64))
	var rows []catalogRow
	if err := decoder.Decode(&rows); err != nil {
		return nil, fmt.Errorf("%w: version.json: %v", ErrCatalogInvalid, err)
	}
	var trailing json.RawMessage
	if err := decoder.Decode(&trailing); !errorsIsEOF(err) {
		return nil, fmt.Errorf("%w: version.json has trailing data", ErrCatalogInvalid)
	}
	for _, row := range rows {
		if row.Path == "" {
			continue
		}
		if !validCatalogPath(normalizeCatalogPath(row.Path)) {
			return nil, fmt.Errorf("%w: unsafe catalogue path %q", ErrCatalogInvalid, row.Path)
		}
	}
	return rows, nil
}

// validCatalogPath rejects an empty, "." or ".." segment anywhere in a
// catalogue path, so a row cannot ship outside res/ or overwrite lazyFile.json
// (L4f fix 3).
func validCatalogPath(value string) bool {
	if value == "" || strings.HasPrefix(value, "/") {
		return false
	}
	for part := range strings.SplitSeq(value, "/") {
		if part == "" || part == "." || part == ".." {
			return false
		}
	}
	return true
}

func errorsIsEOF(err error) bool {
	return err == io.EOF
}

type resRoot struct {
	lexical  string
	resolved string
}

// resolveResRoot refuses an unset or unreadable res_path and resolves the folder
// once, so a symlinked root cannot make containment checks disagree.
func resolveResRoot(resPath string) (resRoot, error) {
	if resPath == "" {
		return resRoot{}, fmt.Errorf("%w: settings.json has no res_path", ErrResPathMissing)
	}
	info, err := os.Stat(resPath)
	if err != nil || !info.IsDir() {
		return resRoot{}, fmt.Errorf("%w: %s is not a readable folder", ErrResPathMissing, resPath)
	}
	resolved, err := filepath.EvalSymlinks(resPath)
	if err != nil {
		return resRoot{}, fmt.Errorf("%w: %s: %v", ErrResPathMissing, resPath, err)
	}
	return resRoot{lexical: resPath, resolved: resolved}, nil
}

type collectionSummary struct {
	considered    int
	missing       int
	mismatching   int
	missingPaths  []string
	mismatchPaths []string
}

// collectExactAssets is the Go port of collect_exact_bulk_assets. A row is
// considered when it is force=0, carries a res/web/ path and a valid md5; the
// first candidate whose md5 equals the row's is the exact file.
func collectExactAssets(rows []catalogRow, root resRoot) ([]assetFile, collectionSummary, error) {
	files := make([]assetFile, 0, len(rows))
	seenArchive := map[string]struct{}{}
	summary := collectionSummary{}
	for _, row := range rows {
		if row.Force != 0 {
			continue
		}
		catalogPath := normalizeCatalogPath(row.Path)
		md5 := strings.ToLower(row.MD5)
		if !strings.HasPrefix(catalogPath, "res/web/") || !validMD5(md5) {
			continue
		}
		summary.considered++
		exact, relative, foundMismatch := findExactFile(root, catalogPath, md5)
		if exact == "" {
			if foundMismatch {
				summary.mismatching++
				summary.mismatchPaths = append(summary.mismatchPaths, catalogPath)
			} else {
				summary.missing++
				summary.missingPaths = append(summary.missingPaths, catalogPath)
			}
			continue
		}
		archiveName, err := bulkArchiveName(catalogPath)
		if err != nil {
			return nil, summary, err
		}
		if _, duplicate := seenArchive[archiveName]; duplicate {
			return nil, summary, fmt.Errorf("%w: %s", ErrAssetCollision, archiveName)
		}
		seenArchive[archiveName] = struct{}{}
		info, err := os.Stat(exact)
		if err != nil || !info.Mode().IsRegular() {
			return nil, summary, fmt.Errorf("%w: %s: %v", ErrInvalidInput, catalogPath, err)
		}
		files = append(files, assetFile{source: exact, relative: relative, catalogPath: catalogPath, archiveName: archiveName, size: info.Size(), md5: md5})
	}
	if len(files) == 0 {
		return nil, summary, ErrNoExactAssets
	}
	return files, summary, nil
}

func normalizeCatalogPath(value string) string {
	return strings.ReplaceAll(value, `\`, "/")
}

// findExactFile tries the four V1 candidates in order and returns the resolved
// path (the bytes that are shipped) plus the candidate path relative to
// res_path. foundMismatch reports that a regular candidate existed but none
// carried the catalogue md5.
func findExactFile(root resRoot, catalogPath, md5 string) (string, string, bool) {
	foundMismatch := false
	for _, candidate := range assetCandidates(root.lexical, catalogPath) {
		info, err := os.Stat(candidate)
		if err != nil || !info.Mode().IsRegular() {
			continue
		}
		resolved, ok := withinResRoot(root, candidate)
		if !ok {
			continue
		}
		actual, err := md5File(resolved)
		if err != nil {
			continue
		}
		if actual == md5 {
			relative, err := filepath.Rel(root.lexical, candidate)
			if err != nil {
				continue
			}
			return resolved, filepath.ToSlash(relative), false
		}
		foundMismatch = true
	}
	return "", "", foundMismatch
}

// assetCandidates is _current_asset_candidates: the catalogue path, the path
// without "res/", the /web/ -> / alias under res/, and the plain alias.
func assetCandidates(resPath, catalogPath string) []string {
	parts := strings.Split(catalogPath, "/")
	candidates := make([]string, 0, 4)
	seen := map[string]struct{}{}
	add := func(relative []string) {
		if len(relative) == 0 {
			return
		}
		joined := strings.Join(relative, "/")
		if _, duplicate := seen[joined]; duplicate {
			return
		}
		seen[joined] = struct{}{}
		candidates = append(candidates, filepath.Join(resPath, filepath.FromSlash(joined)))
	}
	add(parts)
	if len(parts) > 0 && parts[0] == "res" {
		add(parts[1:])
	}
	if len(parts) >= 2 && parts[0] == "res" && parts[1] == "web" {
		add(append([]string{"res"}, parts[2:]...))
		add(parts[2:])
	}
	return candidates
}

// bulkArchiveName is the stock writable alias: res/web/<rest> -> res/<rest>.
func bulkArchiveName(catalogPath string) (string, error) {
	parts := strings.Split(catalogPath, "/")
	if len(parts) < 3 || parts[0] != "res" || parts[1] != "web" {
		return "", fmt.Errorf("%w: %s", ErrCatalogInvalid, catalogPath)
	}
	return path.Join(append([]string{"res"}, parts[2:]...)...), nil
}

// withinResRoot refuses a symlink whose target leaves res_path. The candidate
// is returned resolved, so the hash and the zip read the same bytes.
func withinResRoot(root resRoot, candidate string) (string, bool) {
	resolved, err := filepath.EvalSymlinks(candidate)
	if err != nil {
		return "", false
	}
	relative, err := filepath.Rel(root.resolved, resolved)
	if err != nil || relative == ".." || strings.HasPrefix(relative, ".."+string(os.PathSeparator)) {
		return "", false
	}
	return resolved, true
}

func md5File(filename string) (string, error) {
	file, err := os.Open(filename)
	if err != nil {
		return "", err
	}
	defer file.Close()
	digest := md5.New()
	if _, err := io.Copy(digest, file); err != nil {
		return "", err
	}
	return hex.EncodeToString(digest.Sum(nil)), nil
}

func validMD5(text string) bool {
	if len(text) != 32 || strings.ToLower(text) != text {
		return false
	}
	_, err := hex.DecodeString(text)
	return err == nil
}

// lazyKey is V1 lazy_key: "__lazy__" plus the path with "/" replaced by "___".
func lazyKey(catalogPath string) (string, error) {
	normalized := strings.Trim(strings.ReplaceAll(catalogPath, `\`, "/"), "/")
	if normalized == "" {
		return "", fmt.Errorf("%w: lazy path is empty", ErrCatalogInvalid)
	}
	return "__lazy__" + strings.Join(strings.Split(normalized, "/"), "___"), nil
}

type lazyValuePayload struct {
	Size    int64           `json:"size"`
	MD5     string          `json:"md5"`
	Path    string          `json:"path"`
	Version json.RawMessage `json:"version,omitempty"`
}

// lazyValue encodes one marker value exactly as V1 lazy_value: compact JSON in
// the key order size, md5, path[, version], with Lua's nil-omission rule.
func lazyValue(row catalogRow) (string, error) {
	payload := lazyValuePayload{
		Size: row.Size,
		MD5:  strings.ToLower(row.MD5),
		Path: normalizeCatalogPath(row.Path),
	}
	if len(row.Version) > 0 && string(row.Version) != "null" {
		payload.Version = row.Version
	}
	encoded, err := marshalNoEscape(payload)
	if err != nil {
		return "", fmt.Errorf("%w: lazy value: %v", ErrCatalogInvalid, err)
	}
	return string(encoded), nil
}

// buildLazyMap is V1 build_lazy_map: force=1 rows are never markers, supplied
// exact rows have none, every other force=0 row keeps its stock marker.
func buildLazyMap(rows []catalogRow, supplied map[string]struct{}) (map[string]string, lazyStateSummary, error) {
	lazyMap := make(map[string]string)
	summary := lazyStateSummary{}
	for _, row := range rows {
		if row.Force == 1 {
			continue
		}
		catalogPath := normalizeCatalogPath(row.Path)
		if catalogPath == "" {
			continue
		}
		summary.considered++
		if _, exact := supplied[catalogPath]; exact {
			summary.supplied++
			continue
		}
		key, err := lazyKey(catalogPath)
		if err != nil {
			return nil, summary, err
		}
		value, err := lazyValue(row)
		if err != nil {
			return nil, summary, err
		}
		lazyMap[key] = value
		summary.retained++
	}
	if summary.supplied+summary.retained != summary.considered {
		return nil, summary, fmt.Errorf("%w: lazy-state accounting mismatch", ErrCatalogInvalid)
	}
	return lazyMap, summary, nil
}

// marshalLazyFile serializes the map with sorted keys and no HTML escaping so
// the same catalogue always produces the same bytes. V1 writes the same map
// with indent=2 and insertion order; the plan pins this compact sorted form
// because the client decodes it with cjson, and the values are V1's.
func marshalLazyFile(lazyMap map[string]string) ([]byte, error) {
	encoded, err := marshalNoEscape(lazyMap)
	if err != nil {
		return nil, err
	}
	return append(encoded, '\n'), nil
}

// marshalNoEscape is V1's json.dumps(..., ensure_ascii=False): no HTML
// escaping, and U+2028/U+2029 stay raw instead of Go's \u2028/\u2029 escapes.
func marshalNoEscape(value any) ([]byte, error) {
	var buffer bytes.Buffer
	encoder := json.NewEncoder(&buffer)
	encoder.SetEscapeHTML(false)
	if err := encoder.Encode(value); err != nil {
		return nil, err
	}
	encoded := bytes.TrimSuffix(buffer.Bytes(), []byte("\n"))
	return unescapeLineSeparators(encoded), nil
}

// unescapeLineSeparators turns a JSON \u2028 or \u2029 escape into the raw rune.
// A backslash that is itself escaped (an even run) is left alone.
func unescapeLineSeparators(encoded []byte) []byte {
	output := make([]byte, 0, len(encoded))
	for index := 0; index < len(encoded); {
		if encoded[index] != '\\' {
			output = append(output, encoded[index])
			index++
			continue
		}
		run := 0
		for index+run < len(encoded) && encoded[index+run] == '\\' {
			run++
		}
		escape := ""
		if run%2 == 1 && index+run+5 <= len(encoded) {
			escape = string(encoded[index+run : index+run+5])
		}
		var separator rune
		switch escape {
		case "u2028":
			separator = '\u2028'
		case "u2029":
			separator = '\u2029'
		default:
			output = append(output, encoded[index:index+run]...)
			index += run
			continue
		}
		output = append(output, encoded[index:index+run-1]...)
		output = append(output, []byte(string(separator))...)
		index += run + 5
	}
	return output
}

// resSidecarEntry is one lazy res index row; its Path is relative to res_path.
type resSidecarEntry struct {
	Path string `json:"path"`
	MD5  string `json:"md5"`
	Size int64  `json:"size"`
}

type resSidecarDocument struct {
	Entries []resSidecarEntry `json:"entries"`
}

// stageSidecar writes the res index beside the volumes in staging and returns
// its commit descriptor. The backend reads it as
// updates/<lane>/<package base>.res.json (I11A_OTA_RELEASE_V1 ruling 6).
func stageSidecar(staging, packageBase string, entries []resSidecarEntry) (artifact, error) {
	if entries == nil {
		entries = []resSidecarEntry{}
	}
	encoded, err := json.Marshal(resSidecarDocument{Entries: entries})
	if err != nil {
		return artifact{}, fmt.Errorf("otabuild: res sidecar: %w", err)
	}
	encoded = append(encoded, '\n')
	name := packageBase + ".res.json"
	target := filepath.Join(staging, name)
	file, err := os.Create(target)
	if err != nil {
		return artifact{}, fmt.Errorf("otabuild: create res sidecar: %w", err)
	}
	if _, err := file.Write(encoded); err != nil {
		file.Close()
		return artifact{}, fmt.Errorf("otabuild: write res sidecar: %w", err)
	}
	if err := file.Sync(); err != nil {
		file.Close()
		return artifact{}, fmt.Errorf("otabuild: sync res sidecar: %w", err)
	}
	if err := file.Close(); err != nil {
		return artifact{}, fmt.Errorf("otabuild: close res sidecar: %w", err)
	}
	return artifact{Name: name, Size: int64(len(encoded)), SHA256: sha256Hex(encoded)}, nil
}
