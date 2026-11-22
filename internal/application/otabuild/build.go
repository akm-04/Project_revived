// Package otabuild materialises the OTA client tree, applies the pinned client
// patches and writes the immutable volume-split release artifact
// (I11A_OTA_RELEASE_V1 rulings 2, 3, 5 and 8-10). It touches no network and no
// database; the agent registers the returned row through ota.register_build.
package otabuild

import (
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

	"gxb.local/backend/v2/internal/domain/otarelease"
)

// Input is one build request. StockBaseline is the extracted stock client tree
// (a directory holding assets/src_32 and assets/src_64) or its zip archive.
type Input struct {
	Lane          string
	Version       string
	Rollback      bool
	StockBaseline string
	ClientTree    string
	Origins       map[string]string
	UpdatesDir    string
	StagingDir    string
}

// Refusal kinds the agent maps to AGENT_* errors. Every refusal wraps exactly
// one of them so callers can use errors.Is.
var (
	ErrAssetsLaneUnsupported = errors.New("otabuild: the assets lane is not built yet")
	ErrInvalidLane           = errors.New("otabuild: unknown lane")
	ErrInvalidVersion        = errors.New("otabuild: invalid version")
	ErrInvalidInput          = errors.New("otabuild: invalid build input")
	ErrEmptyPackage          = errors.New("otabuild: the release package has no file")
	ErrDuplicatePath         = errors.New("otabuild: a client path is shipped twice")
	ErrUpdateSceneForbidden  = errors.New("otabuild: UpdateScene.lua stays in the APK")
	ErrOriginMismatch        = errors.New("otabuild: a packaged origin differs from the configured origins")
	ErrOriginsMissing        = errors.New("otabuild: an origin carrier is packaged without configured origins")
	ErrAbiMismatch           = errors.New("otabuild: the stock src_32 and src_64 copies differ")
	ErrStockHashMismatch     = errors.New("otabuild: the stock target does not match its pinned sha256")
	ErrPatchKind             = errors.New("otabuild: unknown patch kind")
	ErrInvalidPatch          = errors.New("otabuild: invalid patch definition")
	ErrPatchAnchor           = errors.New("otabuild: patch anchor is missing or not unique")
	ErrVolumeLimit           = errors.New("otabuild: the package does not fit the stock volume limits")
	ErrTargetExists          = errors.New("otabuild: the release artifact already exists")
)

// volumeByteLimit is ruling 5's per-volume cap; tests lower it to exercise the
// split without a multi-megabyte fixture.
var volumeByteLimit int64 = 99_000_000

const maxTotalBytes int64 = 2_147_483_647

// Build validates the input, assembles the package, splits it into volumes and
// renames them into UpdatesDir. It returns the ota.register_build payload.
func Build(ctx context.Context, input Input) (otarelease.BuildRequest, error) {
	lane, version, err := validateInput(input)
	if err != nil {
		return otarelease.BuildRequest{}, err
	}
	if err := sweepInterruptedBuilds(input.UpdatesDir, input.StagingDir); err != nil {
		return otarelease.BuildRequest{}, err
	}
	baseline, closeBaseline, err := openBaseline(input.StockBaseline)
	if err != nil {
		return otarelease.BuildRequest{}, err
	}
	defer closeBaseline()

	files, err := collectPackage(input.ClientTree, baseline)
	if err != nil {
		return otarelease.BuildRequest{}, err
	}
	if err := checkOriginGuard(files, input.Origins); err != nil {
		return otarelease.BuildRequest{}, err
	}
	if err := ctx.Err(); err != nil {
		return otarelease.BuildRequest{}, err
	}

	entries := packageEntries(files)
	if err := os.MkdirAll(input.StagingDir, 0o755); err != nil {
		return otarelease.BuildRequest{}, fmt.Errorf("otabuild: staging directory: %w", err)
	}
	staging, err := os.MkdirTemp(input.StagingDir, "build-*")
	if err != nil {
		return otarelease.BuildRequest{}, fmt.Errorf("otabuild: staging directory: %w", err)
	}
	defer os.RemoveAll(staging)

	assembled := filepath.Join(staging, "package.zip")
	totalSize, err := writeAssembled(assembled, entries)
	if err != nil {
		return otarelease.BuildRequest{}, err
	}
	if err := ctx.Err(); err != nil {
		return otarelease.BuildRequest{}, err
	}
	digest, err := fileDigest(assembled)
	if err != nil {
		return otarelease.BuildRequest{}, err
	}

	sizes, err := planVolumeSizes(totalSize, volumeByteLimit)
	if err != nil {
		return otarelease.BuildRequest{}, err
	}
	volumes, err := writeVolumes(staging, version.String(), digest.sha256, sizes)
	if err != nil {
		return otarelease.BuildRequest{}, err
	}

	request, err := buildRequest(lane, version, input.Rollback, volumes, digest, totalSize, entries)
	if err != nil {
		return otarelease.BuildRequest{}, err
	}
	if _, err := request.Release(); err != nil {
		return otarelease.BuildRequest{}, fmt.Errorf("otabuild: built row is invalid: %w", err)
	}
	marker := fmt.Sprintf("%s-%s.incomplete", version.String(), digest.sha256[:12])
	if err := commitVolumes(staging, input.UpdatesDir, marker, volumes); err != nil {
		return otarelease.BuildRequest{}, err
	}
	return request, nil
}

func validateInput(input Input) (otarelease.Lane, otarelease.Version, error) {
	lane, err := otarelease.ParseLane(input.Lane)
	if err != nil {
		return "", otarelease.Version{}, fmt.Errorf("%w: %v", ErrInvalidLane, err)
	}
	if lane == otarelease.LaneAssets {
		return "", otarelease.Version{}, ErrAssetsLaneUnsupported
	}
	version, err := otarelease.ParseVersion(input.Version)
	if err != nil {
		return "", otarelease.Version{}, fmt.Errorf("%w: %v", ErrInvalidVersion, err)
	}
	if input.StockBaseline == "" || input.ClientTree == "" || input.UpdatesDir == "" || input.StagingDir == "" {
		return "", otarelease.Version{}, fmt.Errorf("%w: baseline, client tree, updates and staging are required", ErrInvalidInput)
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
func collectPackage(clientTree string, baseline stockBaseline) (map[string][]byte, error) {
	files := make(map[string][]byte)
	source := filepath.Join(clientTree, "src")
	added, err := collectSource(source, files)
	if err != nil {
		return nil, err
	}
	patched, err := collectPatches(filepath.Join(clientTree, "patches"), baseline, files)
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

type packageEntry struct {
	path    string
	content []byte
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
			entries = append(entries, packageEntry{path: prefix + path, content: files[path]})
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
	content, err := os.ReadFile(path)
	if err != nil {
		return digestSet{}, fmt.Errorf("otabuild: read assembled package: %w", err)
	}
	return digestSet{md5: md5Hex(content), sha256: sha256Hex(content)}, nil
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
			Size: int64(len(entry.content)),
			MD5:  md5Hex(entry.content),
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
		return otarelease.PackageVolume{}, fmt.Errorf("otabuild: write volume: %w", err)
	}
	if written != size {
		file.Close()
		return otarelease.PackageVolume{}, fmt.Errorf("%w: volume %q has %d of %d bytes", ErrVolumeLimit, filepath.Base(path), written, size)
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

// commitVolumes refuses an existing artifact before it moves anything, then
// renames every staged volume into the lane directory (immutable: ruling 2).
// The marker lists the volumes being published; while it exists the set is
// incomplete, and an error rolls the moved volumes back so no partial set can
// poison a later build.
func commitVolumes(staging, updatesDir, marker string, volumes []otarelease.PackageVolume) error {
	if err := os.MkdirAll(updatesDir, 0o755); err != nil {
		return fmt.Errorf("otabuild: updates directory: %w", err)
	}
	for _, volume := range volumes {
		target := filepath.Join(updatesDir, volume.Name)
		if _, err := os.Lstat(target); err == nil {
			return fmt.Errorf("%w: %s", ErrTargetExists, volume.Name)
		} else if !errors.Is(err, os.ErrNotExist) {
			return fmt.Errorf("otabuild: check target: %w", err)
		}
	}
	markerPath := filepath.Join(updatesDir, marker)
	if err := writeIncompleteMarker(markerPath, volumes); err != nil {
		return err
	}
	moved := make([]string, 0, len(volumes))
	rollback := func() {
		for _, name := range moved {
			_ = os.Remove(filepath.Join(updatesDir, name))
		}
		_ = os.Remove(markerPath)
		_ = syncDirectory(updatesDir)
	}
	for _, volume := range volumes {
		if err := renameFile(filepath.Join(staging, volume.Name), filepath.Join(updatesDir, volume.Name)); err != nil {
			rollback()
			return fmt.Errorf("otabuild: move volume: %w", err)
		}
		moved = append(moved, volume.Name)
	}
	if err := syncDirectory(updatesDir); err != nil {
		rollback()
		return err
	}
	if err := os.Remove(markerPath); err != nil {
		rollback()
		return fmt.Errorf("otabuild: remove incomplete marker: %w", err)
	}
	if err := syncDirectory(updatesDir); err != nil {
		rollback()
		return err
	}
	return nil
}

func writeIncompleteMarker(path string, volumes []otarelease.PackageVolume) error {
	names := make([]string, 0, len(volumes))
	for _, volume := range volumes {
		names = append(names, volume.Name)
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
