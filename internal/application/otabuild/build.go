// Package otabuild materialises the OTA client tree, applies the pinned client
// patches and writes the immutable volume-split release artifact
// (I11A_OTA_RELEASE_V1 rulings 2, 3, 5 and 8-10). It touches no network and no
// database; the agent registers the returned row through ota.register_build.
package otabuild

import (
	"archive/zip"
	"bytes"
	"context"
	"crypto/md5"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync/atomic"

	"gxb.local/backend/v2/internal/domain/otarelease"
)

// Input is one build request. StockBaseline is the extracted stock client tree
// (a directory holding assets/src_32 and assets/src_64) or its zip archive;
// it supplies the catalogue and the origin carriers. StockSource is the
// decompiled stock Lua tree the patches read and hash.
type Input struct {
	Lane          string
	Version       string
	Rollback      bool
	StockBaseline string
	StockSource   string
	ClientTree    string
	Origins       map[string]string
	UpdatesDir    string
	StagingDir    string
	// ResPath is the P1 asset folder settings.json names; the assets lane reads
	// its exact-current files there (I11A_1_PLAN "L4c decisions").
	ResPath string
	// RecoveredResPath is the asset-recovery lane folder settings.json names; a
	// code lazy refresh resolves recovered files only there (OA-9).
	RecoveredResPath string
	// StockCatalog is the catalogue source when the stock baseline has no
	// version.json (for example a Lua-only zip); empty means StockBaseline. The
	// assets lane and a code lazy refresh both read it.
	StockCatalog string
	// LazyRefresh makes the code lane rewrite lazyFile.json from the stock
	// catalogue minus the ACTIVE assets release's delivered paths, keeping a
	// marker for every undelivered row (L4f, OA-8).
	LazyRefresh bool
	// AssetsSidecar is the ACTIVE assets release's res sidecar that a code
	// lazy refresh reads; required when LazyRefresh is set.
	AssetsSidecar string
	// PriorPaths are the manifest paths every registered code-lane release
	// shipped, read from the agent's release ledger. A code build adds back any
	// path the new package lacks, with its stock content, because the client
	// keeps a file a later release no longer contains.
	PriorPaths []string
	// VolumeByteLimit is the per-volume cap; zero means the default 99 MB.
	VolumeByteLimit int64
}

// Result is one finished build: the ota.register_build payload plus the report
// the agent records in the operation.
type Result struct {
	Request otarelease.BuildRequest
	Report  Report
}

// Refusal kinds the agent maps to AGENT_* errors. Every refusal wraps exactly
// one of them so callers can use errors.Is.
var (
	ErrInvalidLane             = errors.New("otabuild: unknown lane")
	ErrInvalidVersion          = errors.New("otabuild: invalid version")
	ErrInvalidInput            = errors.New("otabuild: invalid build input")
	ErrEmptyPackage            = errors.New("otabuild: the release package has no file")
	ErrDuplicatePath           = errors.New("otabuild: a client path is shipped twice")
	ErrUpdateSceneForbidden    = errors.New("otabuild: UpdateScene.lua stays in the APK")
	ErrOriginMismatch          = errors.New("otabuild: a packaged origin differs from the configured origins")
	ErrOriginsMissing          = errors.New("otabuild: an origin carrier is packaged without configured origins")
	ErrAbiMismatch             = errors.New("otabuild: the stock src_32 and src_64 copies differ")
	ErrStockHashMismatch       = errors.New("otabuild: the stock target does not match its pinned sha256")
	ErrPatchKind               = errors.New("otabuild: unknown patch kind")
	ErrInvalidPatch            = errors.New("otabuild: invalid patch definition")
	ErrPatchAnchor             = errors.New("otabuild: patch anchor is missing or not unique")
	ErrVolumeLimit             = errors.New("otabuild: the package does not fit the stock volume limits")
	ErrTargetExists            = errors.New("otabuild: the release artifact already exists")
	ErrCatalogInvalid          = errors.New("otabuild: the stock version.json is not usable")
	ErrResPathMissing          = errors.New("otabuild: the res_path is empty or not a readable folder")
	ErrRecoveredResPathMissing = errors.New("otabuild: the recovered_res_path is not a readable folder")
	ErrNoExactAssets           = errors.New("otabuild: no exact-current asset file was found")
	ErrAssetCollision          = errors.New("otabuild: two asset rows land on one zip name")
	// ErrBuildIO is a transient read/write defect (short copy, disk fault); the
	// agent maps it to a temporary refusal (L4f fix 8).
	ErrBuildIO = errors.New("otabuild: the build could not read or write its files")
)

// markerSerial keeps the incomplete-marker names of two builds in one process
// apart even when they share a version and digest (L4f fix 1).
var markerSerial atomic.Uint64

// defaultVolumeByteLimit is ruling 5's per-volume cap when Input does not set
// one.
const defaultVolumeByteLimit int64 = 99_000_000

const maxTotalBytes int64 = 2_147_483_647

// Build validates the input, assembles the lane's package, splits it into
// volumes and commits the immutable artifacts into UpdatesDir. It returns the
// ota.register_build payload plus the build report.
func Build(ctx context.Context, input Input) (Result, error) {
	lane, version, err := validateInput(input)
	if err != nil {
		return Result{}, err
	}
	lock, err := acquireBuildLock(filepath.Dir(input.UpdatesDir))
	if err != nil {
		return Result{}, err
	}
	defer lock.release()
	if err := sweepInterruptedBuilds(input.UpdatesDir, input.StagingDir); err != nil {
		return Result{}, err
	}
	baseline, closeBaseline, err := openBaseline(input.StockBaseline)
	if err != nil {
		return Result{}, err
	}
	defer closeBaseline()
	catalogBaseline := baseline
	if (lane == otarelease.LaneAssets || input.LazyRefresh) && input.StockCatalog != "" {
		var closeCatalog func()
		catalogBaseline, closeCatalog, err = openBaseline(input.StockCatalog)
		if err != nil {
			return Result{}, err
		}
		defer closeCatalog()
	}

	report := Report{Lane: string(lane), Version: version.String(), MissingSample: []string{}, MismatchSample: []string{}, RevertedSample: []string{}, UnrevertableSample: []string{}}
	var entries []packageEntry
	var sidecar []resSidecarEntry
	if lane == otarelease.LaneAssets {
		entries, sidecar, report, err = assetsPackage(input.ResPath, version.String(), catalogBaseline)
	} else {
		var reverted revertSummary
		entries, reverted, err = codeEntries(input)
		if err == nil && input.LazyRefresh {
			var lazyBytes, catalogBytes []byte
			lazyBytes, catalogBytes, sidecar, report, err = lazyRefreshPackage(input.RecoveredResPath, input.AssetsSidecar, catalogBaseline, version.String())
			if err == nil {
				entries = append(entries, packageEntry{path: lazyFileMember, content: lazyBytes, size: int64(len(lazyBytes)), md5: md5Hex(lazyBytes)})
				for _, prefix := range []string{"src_32/", "src_64/"} {
					entries = append(entries, packageEntry{path: prefix + catalogMember, content: catalogBytes, size: int64(len(catalogBytes)), md5: md5Hex(catalogBytes)})
				}
				sort.Slice(entries, func(left, right int) bool { return entries[left].path < entries[right].path })
			}
		}
		report.Reverted = len(reverted.restored)
		report.RevertedSample = sample(reverted.restored)
		report.Unrevertable = len(reverted.unrevertable)
		report.UnrevertableSample = sample(reverted.unrevertable)
	}
	if err != nil {
		return Result{}, err
	}
	if err := ctx.Err(); err != nil {
		return Result{}, err
	}

	if err := os.MkdirAll(input.StagingDir, 0o755); err != nil {
		return Result{}, fmt.Errorf("otabuild: staging directory: %w", err)
	}
	staging, err := os.MkdirTemp(input.StagingDir, "build-*")
	if err != nil {
		return Result{}, fmt.Errorf("otabuild: staging directory: %w", err)
	}
	defer os.RemoveAll(staging)

	assembled := filepath.Join(staging, "package.zip")
	totalSize, err := writeAssembled(assembled, entries, archiveMethod(lane))
	if err != nil {
		return Result{}, err
	}
	if err := ctx.Err(); err != nil {
		return Result{}, err
	}
	digest, err := fileDigest(assembled)
	if err != nil {
		return Result{}, err
	}

	volumeByteLimit := input.VolumeByteLimit
	if volumeByteLimit <= 0 {
		volumeByteLimit = defaultVolumeByteLimit
	}
	sizes, err := planVolumeSizes(totalSize, volumeByteLimit)
	if err != nil {
		return Result{}, err
	}
	volumes, err := writeVolumes(staging, version.String(), digest.sha256, sizes)
	if err != nil {
		return Result{}, err
	}

	request, err := buildRequest(lane, version, input.Rollback, volumes, digest, totalSize, entries)
	if err != nil {
		return Result{}, err
	}
	if _, err := request.Release(); err != nil {
		return Result{}, fmt.Errorf("otabuild: built row is invalid: %w", err)
	}
	packageBase := fmt.Sprintf("%s-%s.zip", version.String(), digest.sha256[:12])
	artifacts, err := volumeArtifacts(volumes)
	if err != nil {
		return Result{}, err
	}
	if lane == otarelease.LaneAssets || input.LazyRefresh {
		sidecarArtifact, err := stageSidecar(staging, packageBase, sidecar)
		if err != nil {
			return Result{}, err
		}
		artifacts = append(artifacts, sidecarArtifact)
	}
	marker := fmt.Sprintf("%s-%s-%d-%d.incomplete", version.String(), digest.sha256[:12], os.Getpid(), markerSerial.Add(1))
	if err := commitArtifacts(staging, input.UpdatesDir, marker, artifacts); err != nil {
		return Result{}, err
	}
	return Result{Request: request, Report: report}, nil
}

// codeEntries collects the cumulative code/catalog package, restores the
// previously shipped paths its patch set no longer produces, and applies the
// origin guard.
func codeEntries(input Input) ([]packageEntry, revertSummary, error) {
	files, err := collectPackage(input.ClientTree, stockSource{root: input.StockSource})
	if err != nil {
		return nil, revertSummary{}, err
	}
	reverted, err := restorePriorPaths(input.PriorPaths, input.StockSource, files)
	if err != nil {
		return nil, revertSummary{}, err
	}
	if err := checkOriginGuard(files, input.Origins); err != nil {
		return nil, revertSummary{}, err
	}
	return packageEntries(files), reverted, nil
}

// revertSummary is the build's revert set: the prior paths put back from stock
// and the ones stock cannot supply.
type revertSummary struct {
	restored     []string
	unrevertable []string
}

// restorePriorPaths adds back, from the stock source, every client path an
// earlier code release shipped that this package lacks. The client only replaces
// files a release contains, so a removed patch would otherwise leave its old
// copy on devices forever.
func restorePriorPaths(priorPaths []string, stockRoot string, files map[string][]byte) (revertSummary, error) {
	summary := revertSummary{restored: []string{}, unrevertable: []string{}}
	visited := make(map[string]struct{}, len(priorPaths))
	for _, clientPath := range priorPaths {
		relative, generated := relativeStockPath(clientPath)
		if generated {
			continue
		}
		if _, done := visited[relative]; done {
			continue
		}
		visited[relative] = struct{}{}
		if _, shipped := files[relative]; shipped {
			continue
		}
		if stockRoot == "" {
			summary.unrevertable = append(summary.unrevertable, relative)
			continue
		}
		content, err := stockSource{root: stockRoot}.read(relative)
		if errors.Is(err, os.ErrNotExist) {
			summary.unrevertable = append(summary.unrevertable, relative)
			continue
		}
		if err != nil {
			return revertSummary{}, err
		}
		if err := addPackageFile(files, relative, content); err != nil {
			return revertSummary{}, err
		}
		summary.restored = append(summary.restored, relative)
	}
	return summary, nil
}

// relativeStockPath maps a release manifest path onto the stock source member a
// patch reads. The lazy file and catalog are generated members, not stock
// files, so they are never reverted.
func relativeStockPath(clientPath string) (string, bool) {
	if clientPath == lazyFileMember {
		return "", true
	}
	for _, prefix := range []string{"src_32/", "src_64/"} {
		if !strings.HasPrefix(clientPath, prefix) {
			continue
		}
		relative := strings.TrimPrefix(clientPath, prefix)
		if relative == catalogMember {
			return "", true
		}
		return relative, false
	}
	return clientPath, false
}

func archiveMethod(lane otarelease.Lane) uint16 {
	if lane == otarelease.LaneAssets {
		return zip.Store
	}
	return zip.Deflate
}

func validateInput(input Input) (otarelease.Lane, otarelease.Version, error) {
	lane, err := otarelease.ParseLane(input.Lane)
	if err != nil {
		return "", otarelease.Version{}, fmt.Errorf("%w: %v", ErrInvalidLane, err)
	}
	version, err := otarelease.ParseVersion(input.Version)
	if err != nil {
		return "", otarelease.Version{}, fmt.Errorf("%w: %v", ErrInvalidVersion, err)
	}
	if input.StockBaseline == "" || input.ClientTree == "" || input.UpdatesDir == "" || input.StagingDir == "" {
		return "", otarelease.Version{}, fmt.Errorf("%w: baseline, client tree, updates and staging are required", ErrInvalidInput)
	}
	if lane == otarelease.LaneAssets {
		if _, err := resolveResRoot(input.ResPath); err != nil {
			return "", otarelease.Version{}, err
		}
	}
	if input.LazyRefresh {
		if lane != otarelease.LaneCode {
			return "", otarelease.Version{}, fmt.Errorf("%w: lazy refresh is a code-lane input", ErrInvalidInput)
		}
		if input.AssetsSidecar == "" {
			return "", otarelease.Version{}, fmt.Errorf("%w: lazy refresh needs the active assets sidecar", ErrInvalidInput)
		}
		if _, err := resolveRecoveredResRoot(input.RecoveredResPath); err != nil {
			return "", otarelease.Version{}, err
		}
	}
	if input.StockSource != "" {
		info, err := os.Stat(input.StockSource)
		if err != nil || !info.IsDir() {
			return "", otarelease.Version{}, fmt.Errorf("%w: stock_source is not a readable directory", ErrInvalidInput)
		}
	}
	patched, err := PatchesPresent(input.ClientTree)
	if err != nil {
		return "", otarelease.Version{}, fmt.Errorf("%w: %v", ErrInvalidInput, err)
	}
	if patched && input.StockSource == "" {
		return "", otarelease.Version{}, fmt.Errorf("%w: the client tree has a patch but no stock_source", ErrInvalidInput)
	}
	if err := requireSameFilesystem(input.StagingDir, input.UpdatesDir); err != nil {
		return "", otarelease.Version{}, err
	}
	return lane, version, nil
}

// requireSameFilesystem refuses staging the volumes on a filesystem other than
// the updates directory: the immutable commit renames, and a rename cannot
// cross devices.
func requireSameFilesystem(stagingDir, updatesDir string) error {
	for _, directory := range []string{stagingDir, updatesDir} {
		if err := os.MkdirAll(directory, 0o755); err != nil {
			return fmt.Errorf("%w: create %s: %v", ErrInvalidInput, directory, err)
		}
	}
	same, err := sameFilesystem(stagingDir, updatesDir)
	if err != nil {
		return fmt.Errorf("%w: compare filesystems: %v", ErrInvalidInput, err)
	}
	if !same {
		return fmt.Errorf("%w: staging and updates are on different filesystems", ErrInvalidInput)
	}
	return nil
}

// collectPackage returns the client-path files the lane ships: every file under
// ClientTree/src plus every pinned patch output. A path shipped twice is
// refused, because the cumulative code lane must be unambiguous.
func collectPackage(clientTree string, source stockSource) (map[string][]byte, error) {
	files := make(map[string][]byte)
	sourceTree := filepath.Join(clientTree, "src")
	added, err := collectSource(sourceTree, files)
	if err != nil {
		return nil, err
	}
	patched, err := collectPatches(filepath.Join(clientTree, "patches"), source, files)
	if err != nil {
		return nil, err
	}
	if added+patched == 0 {
		return nil, ErrEmptyPackage
	}
	return files, nil
}

func collectSource(source string, files map[string][]byte) (int, error) {
	info, err := os.Stat(source)
	if errors.Is(err, os.ErrNotExist) {
		return 0, nil
	}
	if err != nil {
		return 0, fmt.Errorf("otabuild: client source: %w", err)
	}
	if !info.IsDir() {
		return 0, fmt.Errorf("%w: client source %q is not a directory", ErrInvalidInput, source)
	}
	added := 0
	err = filepath.WalkDir(source, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.IsDir() {
			return nil
		}
		if entry.Type()&os.ModeSymlink != 0 {
			return fmt.Errorf("%w: symlink %q in the client tree", ErrInvalidInput, path)
		}
		relative, err := filepath.Rel(source, path)
		if err != nil {
			return err
		}
		content, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		clientPath := filepath.ToSlash(relative)
		if err := addPackageFile(files, clientPath, content); err != nil {
			return err
		}
		added++
		return nil
	})
	if err != nil {
		return 0, fmt.Errorf("otabuild: client source: %w", err)
	}
	return added, nil
}

func addPackageFile(files map[string][]byte, clientPath string, content []byte) error {
	if !safeClientPath(clientPath) {
		return fmt.Errorf("%w: unsafe client path %q", ErrInvalidInput, clientPath)
	}
	if forbiddenFromPackage(clientPath) {
		return fmt.Errorf("%w: %s", ErrUpdateSceneForbidden, clientPath)
	}
	if _, exists := files[clientPath]; exists {
		return fmt.Errorf("%w: %s", ErrDuplicatePath, clientPath)
	}
	files[clientPath] = content
	return nil
}

func forbiddenFromPackage(clientPath string) bool {
	base := clientPath
	if index := strings.LastIndexByte(base, '/'); index >= 0 {
		base = base[index+1:]
	}
	return base == "UpdateScene.lua" || base == "UpdateScene_64.lua"
}

func safeClientPath(clientPath string) bool {
	if clientPath == "" || strings.HasPrefix(clientPath, "/") || strings.Contains(clientPath, `\`) {
		return false
	}
	for part := range strings.SplitSeq(clientPath, "/") {
		if part == "" || part == "." || part == ".." {
			return false
		}
	}
	return true
}

// packageEntry is one file inside the assembled zip. The code lane carries the
// bytes in memory; the assets lane streams a file from disk so a 1 GB bootstrap
// never has to fit in RAM.
type packageEntry struct {
	path    string
	content []byte
	source  string
	size    int64
	md5     string
}

func (entry packageEntry) open() (io.ReadCloser, error) {
	if entry.source == "" {
		return io.NopCloser(bytes.NewReader(entry.content)), nil
	}
	file, err := os.Open(entry.source)
	if err != nil {
		return nil, fmt.Errorf("otabuild: open %s: %w", entry.source, err)
	}
	return file, nil
}

// packageEntries writes every client file under both stock prefixes in sorted
// order (ruling 8: the ABIs are byte-identical, so one tree serves both).
func packageEntries(files map[string][]byte) []packageEntry {
	paths := make([]string, 0, len(files))
	for path := range files {
		paths = append(paths, path)
	}
	sort.Strings(paths)
	entries := make([]packageEntry, 0, 2*len(paths))
	for _, prefix := range []string{"src_32/", "src_64/"} {
		for _, path := range paths {
			content := files[path]
			entries = append(entries, packageEntry{path: prefix + path, content: content, size: int64(len(content)), md5: md5Hex(content)})
		}
	}
	sort.Slice(entries, func(left, right int) bool { return entries[left].path < entries[right].path })
	return entries
}

type digestSet struct {
	md5    string
	sha256 string
}

func fileDigest(path string) (digestSet, error) {
	file, err := os.Open(path)
	if err != nil {
		return digestSet{}, fmt.Errorf("otabuild: read assembled package: %w", err)
	}
	defer file.Close()
	md5Hash := md5.New()
	sha256Hash := sha256.New()
	if _, err := io.Copy(io.MultiWriter(md5Hash, sha256Hash), file); err != nil {
		return digestSet{}, fmt.Errorf("otabuild: read assembled package: %w", err)
	}
	return digestSet{md5: hex.EncodeToString(md5Hash.Sum(nil)), sha256: hex.EncodeToString(sha256Hash.Sum(nil))}, nil
}

func md5Hex(content []byte) string {
	sum := md5.Sum(content)
	return hex.EncodeToString(sum[:])
}

func sha256Hex(content []byte) string {
	sum := sha256.Sum256(content)
	return hex.EncodeToString(sum[:])
}

func buildRequest(lane otarelease.Lane, version otarelease.Version, rollback bool, volumes []otarelease.PackageVolume, digest digestSet, totalSize int64, entries []packageEntry) (otarelease.BuildRequest, error) {
	packageFiles, err := json.Marshal(volumes)
	if err != nil {
		return otarelease.BuildRequest{}, fmt.Errorf("otabuild: package files: %w", err)
	}
	manifest := make([]otarelease.ManifestEntry, 0, len(entries))
	for _, entry := range entries {
		manifest = append(manifest, otarelease.ManifestEntry{
			Path: entry.path,
			Size: entry.size,
			MD5:  entry.md5,
		})
	}
	manifestDocument, err := json.Marshal(struct {
		Files []otarelease.ManifestEntry `json:"files"`
	}{Files: manifest})
	if err != nil {
		return otarelease.BuildRequest{}, fmt.Errorf("otabuild: manifest: %w", err)
	}
	return otarelease.BuildRequest{
		Version:      version.String(),
		Lane:         string(lane),
		PackageFiles: packageFiles,
		TotalSize:    totalSize,
		MD5:          digest.md5,
		SHA256:       digest.sha256,
		Manifest:     manifestDocument,
		Rollback:     rollback,
	}, nil
}

// writeVolumes cuts the assembled zip and names every part after its sha256
// prefix; NNN starts at 001 with no gaps (ruling 5, I11A_1_PLAN "Release row
// shapes").
func writeVolumes(staging, version, sha256 string, sizes []int64) ([]otarelease.PackageVolume, error) {
	source, err := os.Open(filepath.Join(staging, "package.zip"))
	if err != nil {
		return nil, fmt.Errorf("otabuild: open assembled package: %w", err)
	}
	defer source.Close()
	volumes := make([]otarelease.PackageVolume, 0, len(sizes))
	for index, size := range sizes {
		name := fmt.Sprintf("%s-%s.zip.%03d", version, sha256[:12], index+1)
		volume, err := writeVolume(source, filepath.Join(staging, name), size)
		if err != nil {
			return nil, err
		}
		volume.Name = name
		volumes = append(volumes, volume)
	}
	return volumes, nil
}

func writeVolume(source io.Reader, path string, size int64) (otarelease.PackageVolume, error) {
	file, err := os.Create(path)
	if err != nil {
		return otarelease.PackageVolume{}, fmt.Errorf("otabuild: create volume: %w", err)
	}
	md5Hash := md5.New()
	sha256Hash := sha256.New()
	written, err := io.CopyN(io.MultiWriter(file, md5Hash, sha256Hash), source, size)
	if err != nil {
		file.Close()
		return otarelease.PackageVolume{}, fmt.Errorf("%w: write volume: %v", ErrBuildIO, err)
	}
	if written != size {
		file.Close()
		return otarelease.PackageVolume{}, fmt.Errorf("%w: volume %q has %d of %d bytes", ErrBuildIO, filepath.Base(path), written, size)
	}
	if err := file.Sync(); err != nil {
		file.Close()
		return otarelease.PackageVolume{}, fmt.Errorf("otabuild: sync volume: %w", err)
	}
	if err := file.Close(); err != nil {
		return otarelease.PackageVolume{}, fmt.Errorf("otabuild: close volume: %w", err)
	}
	return otarelease.PackageVolume{
		Size:   size,
		MD5:    hex.EncodeToString(md5Hash.Sum(nil)),
		SHA256: hex.EncodeToString(sha256Hash.Sum(nil)),
	}, nil
}

// renameFile is a variable so a test can inject a rename failure between
// volumes.
var renameFile = os.Rename

// artifact is one immutable file to commit: its name under UpdatesDir, its
// exact size and sha256. Content-addressed names make a rebuild of the same
// inputs repeat the same names.
type artifact struct {
	Name   string
	Size   int64
	SHA256 string
}

func volumeArtifacts(volumes []otarelease.PackageVolume) ([]artifact, error) {
	artifacts := make([]artifact, 0, len(volumes))
	for _, volume := range volumes {
		if len(volume.SHA256) != 64 {
			return nil, fmt.Errorf("%w: volume %s has no sha256", ErrVolumeLimit, volume.Name)
		}
		artifacts = append(artifacts, artifact{Name: volume.Name, Size: volume.Size, SHA256: volume.SHA256})
	}
	return artifacts, nil
}

// commitArtifacts refuses a target that differs from the staged file, counts an
// identical target (same size and full sha256) as already written, and renames
// the rest into the lane directory (ruling 2; idempotent retry in "L4c
// decisions"). The marker lists only the files being moved; while it exists the
// set is incomplete, and an error rolls the moved files back so no partial set
// can poison a later build.
func commitArtifacts(staging, updatesDir, marker string, artifacts []artifact) error {
	if err := os.MkdirAll(updatesDir, 0o755); err != nil {
		return fmt.Errorf("otabuild: updates directory: %w", err)
	}
	pending := make([]artifact, 0, len(artifacts))
	for _, candidate := range artifacts {
		matches, err := fileMatches(filepath.Join(updatesDir, candidate.Name), candidate.Size, candidate.SHA256)
		if err != nil && !errors.Is(err, os.ErrNotExist) {
			return fmt.Errorf("otabuild: check target: %w", err)
		}
		if err != nil {
			pending = append(pending, candidate)
			continue
		}
		if !matches {
			return fmt.Errorf("%w: %s", ErrTargetExists, candidate.Name)
		}
	}
	if len(pending) == 0 {
		return nil
	}
	markerPath := filepath.Join(updatesDir, marker)
	if err := writeIncompleteMarker(markerPath, pending); err != nil {
		return err
	}
	moved := make([]string, 0, len(pending))
	rollback := func() {
		for _, name := range moved {
			_ = os.Remove(filepath.Join(updatesDir, name))
		}
		_ = os.Remove(markerPath)
		_ = syncDirectory(updatesDir)
	}
	for _, candidate := range pending {
		if err := renameFile(filepath.Join(staging, candidate.Name), filepath.Join(updatesDir, candidate.Name)); err != nil {
			rollback()
			return fmt.Errorf("otabuild: move artifact: %w", err)
		}
		moved = append(moved, candidate.Name)
	}
	if err := syncDirectory(updatesDir); err != nil {
		rollback()
		return err
	}
	// A peer must never delete this build's unique marker, but a marker already
	// gone means the set is complete and must not be rolled back (L4f fix 1).
	if err := os.Remove(markerPath); err != nil && !errors.Is(err, os.ErrNotExist) {
		rollback()
		return fmt.Errorf("otabuild: remove incomplete marker: %w", err)
	}
	if err := syncDirectory(updatesDir); err != nil {
		rollback()
		return err
	}
	return nil
}

// fileMatches reports whether path holds exactly size bytes with the given
// sha256. A missing file is os.ErrNotExist; a size mismatch is a cheap false.
func fileMatches(path string, size int64, expectedSHA256 string) (bool, error) {
	file, err := os.Open(path)
	if err != nil {
		return false, err
	}
	defer file.Close()
	info, err := file.Stat()
	if err != nil {
		return false, err
	}
	if !info.Mode().IsRegular() || info.Size() != size {
		return false, nil
	}
	digest := sha256.New()
	if _, err := io.Copy(digest, file); err != nil {
		return false, err
	}
	return hex.EncodeToString(digest.Sum(nil)) == expectedSHA256, nil
}

func writeIncompleteMarker(path string, artifacts []artifact) error {
	names := make([]string, 0, len(artifacts))
	for _, candidate := range artifacts {
		names = append(names, candidate.Name)
	}
	file, err := os.OpenFile(path, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0o644)
	if err != nil {
		return fmt.Errorf("otabuild: create incomplete marker: %w", err)
	}
	if _, err := file.WriteString(strings.Join(names, "\n") + "\n"); err != nil {
		file.Close()
		return fmt.Errorf("otabuild: write incomplete marker: %w", err)
	}
	if err := file.Sync(); err != nil {
		file.Close()
		return fmt.Errorf("otabuild: sync incomplete marker: %w", err)
	}
	if err := file.Close(); err != nil {
		return fmt.Errorf("otabuild: close incomplete marker: %w", err)
	}
	return syncDirectory(filepath.Dir(path))
}

// sweepInterruptedBuilds clears what a crashed earlier build left: the volumes
// its marker lists and the staging scratch directory. The agent runs one build
// at a time (I11A_1_PLAN "Agent decisions": long ops), so this sweep cannot
// race a live build.
func sweepInterruptedBuilds(updatesDir, stagingDir string) error {
	markers, err := os.ReadDir(updatesDir)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("otabuild: read updates directory: %w", err)
	}
	for _, entry := range markers {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".incomplete") {
			continue
		}
		if err := removeIncompleteSet(updatesDir, filepath.Join(updatesDir, entry.Name())); err != nil {
			return err
		}
	}
	scratch, err := os.ReadDir(stagingDir)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("otabuild: read staging directory: %w", err)
	}
	for _, entry := range scratch {
		if !entry.IsDir() || !strings.HasPrefix(entry.Name(), "build-") {
			continue
		}
		if err := os.RemoveAll(filepath.Join(stagingDir, entry.Name())); err != nil {
			return fmt.Errorf("otabuild: clear staging scratch: %w", err)
		}
	}
	return nil
}

func removeIncompleteSet(updatesDir, markerPath string) error {
	content, err := os.ReadFile(markerPath)
	if err != nil {
		return fmt.Errorf("otabuild: read incomplete marker: %w", err)
	}
	for _, line := range strings.Split(string(content), "\n") {
		name := strings.TrimSpace(line)
		if name == "" {
			continue
		}
		if err := os.Remove(filepath.Join(updatesDir, filepath.Base(name))); err != nil && !errors.Is(err, os.ErrNotExist) {
			return fmt.Errorf("otabuild: remove incomplete volume: %w", err)
		}
	}
	if err := os.Remove(markerPath); err != nil && !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("otabuild: remove incomplete marker: %w", err)
	}
	return nil
}

func syncDirectory(path string) error {
	directory, err := os.Open(path)
	if err != nil {
		return fmt.Errorf("otabuild: open directory for sync: %w", err)
	}
	defer directory.Close()
	if err := directory.Sync(); err != nil {
		return fmt.Errorf("otabuild: sync directory: %w", err)
	}
	return nil
}
