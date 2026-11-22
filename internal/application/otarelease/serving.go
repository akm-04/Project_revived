package otarelease

import (
	"context"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"os"
	"path"
	"path/filepath"
	"strings"
	"sync"
	"time"

	domain "gxb.local/backend/v2/internal/domain/otarelease"
)

// ServingRefreshInterval is the plan's bound: the servable set is re-read from
// the database at most every 5 s, and immediately through Refresh on publish.
const ServingRefreshInterval = 5 * time.Second

const (
	maxMD5CacheEntries  = 4_096
	resSidecarSuffix    = ".res.json"
	maxLoggedSidecars   = 256
	updatesDirectory    = "updates"
	resourceURLPathPart = "/res/"
)

// Serving is the OTA serving view of the active releases: the servable volume
// names, the lazy res index, and the discovery/minimum answers.
type Serving struct {
	Load            func(context.Context) ([]domain.RawRelease, error)
	Root            string
	Settings        *SettingsValue
	PublicEngineURL string
	Ledger          *Ledger
	Now             func() time.Time

	mu          sync.Mutex
	snapshot    *servingSnapshot
	refreshedAt time.Time

	md5Mu    sync.Mutex
	md5Cache map[md5CacheKey]string

	logMu          sync.Mutex
	loggedSidecars map[string]struct{}
}

// resAsset is one sidecar row. The client asks for its basename plus md5.
type resAsset struct {
	Path string `json:"path"`
	MD5  string `json:"md5"`
	Size int64  `json:"size"`
}

type resSidecar struct {
	Entries []resAsset `json:"entries"`
}

type servingSnapshot struct {
	volumes            map[domain.Lane]map[string]struct{}
	resources          map[string][]resAsset
	assetsActive       bool
	assetsIndexEntries int
	resPathUsable      bool
	active             domain.ActiveRelease
}

type md5CacheKey struct {
	path     string
	size     int64
	modified int64
}

// Refresh re-reads the active set and every sidecar. An unreadable or malformed
// sidecar only drops that release's lazy entries; the volume set still serves.
func (s *Serving) Refresh(ctx context.Context) error {
	if s == nil || s.Load == nil {
		return errors.New("otarelease: serving has no active-release source")
	}
	rows, err := s.Load(ctx)
	if err != nil {
		return err
	}
	releases, err := domain.ParseReleases(rows)
	if err != nil {
		return err
	}
	active, err := domain.ActiveSet(rows)
	if err != nil {
		return err
	}
	snapshot := &servingSnapshot{
		volumes:   map[domain.Lane]map[string]struct{}{},
		resources: map[string][]resAsset{},
		active:    active,
	}
	for _, release := range releases {
		if release.State != domain.StateActive {
			continue
		}
		names := snapshot.volumes[release.Lane]
		if names == nil {
			names = map[string]struct{}{}
			snapshot.volumes[release.Lane] = names
		}
		for _, volume := range release.Volumes {
			names[volume.Name] = struct{}{}
		}
		added := s.addSidecar(snapshot, release)
		if release.Lane == domain.LaneAssets {
			snapshot.assetsActive = true
			snapshot.assetsIndexEntries += added
		}
	}
	if resPath := s.resPath(); resPath != "" {
		if readableDirectory(resPath) {
			snapshot.resPathUsable = true
		} else {
			s.logResPathOnce(resPath)
		}
	}
	s.mu.Lock()
	s.snapshot = snapshot
	s.refreshedAt = s.now()
	s.mu.Unlock()
	return nil
}

func (s *Serving) addSidecar(snapshot *servingSnapshot, release domain.Release) int {
	if s.Root == "" {
		return 0
	}
	sidecarPath := filepath.Join(s.Root, updatesDirectory, string(release.Lane), release.PackageBase+resSidecarSuffix)
	data, err := os.ReadFile(sidecarPath)
	if err != nil {
		if !errors.Is(err, os.ErrNotExist) {
			s.logSidecarOnce(sidecarPath, err)
		}
		return 0
	}
	var sidecar resSidecar
	if err := json.Unmarshal(data, &sidecar); err != nil {
		s.logSidecarOnce(sidecarPath, err)
		return 0
	}
	seen := map[string]struct{}{}
	added := 0
	for _, entry := range sidecar.Entries {
		clean, ok := validResourcePath(entry.Path)
		if !ok || !validMD5(entry.MD5) {
			continue
		}
		identity := clean + "\x00" + entry.MD5
		if _, duplicate := seen[identity]; duplicate {
			continue
		}
		seen[identity] = struct{}{}
		entry.Path = clean
		key := resourceKey(clean, entry.MD5)
		snapshot.resources[key] = append(snapshot.resources[key], entry)
		added++
	}
	return added
}

func (s *Serving) logOnce(key, message string) {
	s.logMu.Lock()
	defer s.logMu.Unlock()
	if s.loggedSidecars == nil {
		s.loggedSidecars = map[string]struct{}{}
	}
	if _, logged := s.loggedSidecars[key]; logged {
		return
	}
	if len(s.loggedSidecars) >= maxLoggedSidecars {
		return
	}
	s.loggedSidecars[key] = struct{}{}
	log.Print(message)
}

func (s *Serving) logSidecarOnce(sidecarPath string, cause error) {
	s.logOnce("sidecar\x00"+sidecarPath, fmt.Sprintf("ota res sidecar %s unusable: %v", sidecarPath, cause))
}

func (s *Serving) logResPathOnce(resPath string) {
	s.logOnce("res-path\x00"+resPath, fmt.Sprintf("ota res_path %s is not a readable folder", resPath))
}

func (s *Serving) now() time.Time {
	if s == nil || s.Now == nil {
		return time.Now()
	}
	return s.Now()
}

// current returns a snapshot no older than ServingRefreshInterval. A failed
// refresh with a previous snapshot keeps serving that set rather than turning a
// database blip into 404s the client retries.
func (s *Serving) current(ctx context.Context) (*servingSnapshot, error) {
	s.mu.Lock()
	snapshot := s.snapshot
	fresh := snapshot != nil && s.now().Sub(s.refreshedAt) < ServingRefreshInterval
	s.mu.Unlock()
	if fresh {
		return snapshot, nil
	}
	if err := s.Refresh(ctx); err != nil {
		if snapshot != nil {
			log.Printf("ota serving refresh failed, keeping the previous set: %v", err)
			return snapshot, nil
		}
		return nil, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.snapshot, nil
}

// OpenVolume serves one file named by an ACTIVE release's package_files. The
// name must be in the database-derived set, so path tricks, BUILT/SUPERSEDED/
// WITHDRAWN names and other lanes are not found.
func (s *Serving) OpenVolume(ctx context.Context, laneText, name string) (io.ReadSeekCloser, time.Time, bool, error) {
	lane, err := domain.ParseLane(laneText)
	if err != nil || !validVolumeName(name) || s.Root == "" {
		return nil, time.Time{}, false, nil
	}
	snapshot, err := s.current(ctx)
	if err != nil {
		return nil, time.Time{}, false, err
	}
	if _, servable := snapshot.volumes[lane][name]; !servable {
		return nil, time.Time{}, false, nil
	}
	file, modTime, err := openRegular(filepath.Join(s.Root, updatesDirectory, string(lane), name))
	if errors.Is(err, os.ErrNotExist) {
		return nil, time.Time{}, false, nil
	}
	if err != nil {
		return nil, time.Time{}, false, err
	}
	return file, modTime, true, nil
}

// OpenResource resolves the client's "<basename>.<md5>" against the union res
// index, verifies the bytes, and records the served hit or the miss.
func (s *Serving) OpenResource(ctx context.Context, asset string) (io.ReadSeekCloser, time.Time, string, bool, error) {
	if s == nil || s.Root == "" || s.lazyFetchOff() {
		return nil, time.Time{}, "", false, nil
	}
	expectedMD5 := requestMD5(asset)
	snapshot, err := s.current(ctx)
	if err != nil {
		return nil, time.Time{}, "", false, err
	}
	candidates := snapshot.resources[asset]
	if len(candidates) == 0 {
		s.recordMiss(asset, expectedMD5)
		return nil, time.Time{}, "", false, nil
	}
	resPath := s.resPath()
	for _, candidate := range candidates {
		file, modTime, err := s.openVerified(resPath, candidate)
		if err != nil {
			continue
		}
		s.recordServed(candidate.Path)
		return file, modTime, candidate.Path, true, nil
	}
	s.recordMiss(candidates[0].Path, expectedMD5)
	return nil, time.Time{}, "", false, nil
}

func (s *Serving) openVerified(resPath string, asset resAsset) (io.ReadSeekCloser, time.Time, error) {
	if resPath == "" {
		return nil, time.Time{}, errors.New("otarelease: res_path is not configured")
	}
	clean, ok := validResourcePath(asset.Path)
	if !ok {
		return nil, time.Time{}, errors.New("otarelease: unsafe res path")
	}
	resolvedRoot, err := filepath.EvalSymlinks(resPath)
	if err != nil {
		return nil, time.Time{}, err
	}
	fullPath := filepath.Join(resolvedRoot, filepath.FromSlash(clean))
	resolvedPath, err := filepath.EvalSymlinks(fullPath)
	if err != nil {
		return nil, time.Time{}, err
	}
	if !withinDirectory(resolvedRoot, resolvedPath) {
		return nil, time.Time{}, errors.New("otarelease: res path escapes res_path")
	}
	file, err := os.Open(resolvedPath)
	if err != nil {
		return nil, time.Time{}, err
	}
	info, err := file.Stat()
	if err != nil || !info.Mode().IsRegular() {
		file.Close()
		return nil, time.Time{}, errors.New("otarelease: res entry is not a regular file")
	}
	actual, err := s.verifiedMD5(file, resolvedPath, info)
	if err != nil {
		file.Close()
		return nil, time.Time{}, err
	}
	if actual != asset.MD5 {
		file.Close()
		return nil, time.Time{}, errors.New("otarelease: res md5 mismatch")
	}
	if _, err := file.Seek(0, io.SeekStart); err != nil {
		file.Close()
		return nil, time.Time{}, err
	}
	return file, info.ModTime(), nil
}

// verifiedMD5 hashes once per (path, size, mtime). The backend never writes
// these files, so a stable stat means stable bytes.
func (s *Serving) verifiedMD5(file *os.File, fullPath string, info os.FileInfo) (string, error) {
	key := md5CacheKey{path: fullPath, size: info.Size(), modified: info.ModTime().UnixNano()}
	s.md5Mu.Lock()
	cached, present := s.md5Cache[key]
	s.md5Mu.Unlock()
	if present {
		return cached, nil
	}
	digest := md5.New()
	if _, err := io.Copy(digest, file); err != nil {
		return "", err
	}
	actual := hex.EncodeToString(digest.Sum(nil))
	s.md5Mu.Lock()
	if s.md5Cache == nil {
		s.md5Cache = map[md5CacheKey]string{}
	}
	if len(s.md5Cache) >= maxMD5CacheEntries {
		for victim := range s.md5Cache {
			delete(s.md5Cache, victim)
			break
		}
	}
	s.md5Cache[key] = actual
	s.md5Mu.Unlock()
	return actual, nil
}

func (s *Serving) resPath() string {
	if s == nil || s.Settings == nil {
		return ""
	}
	return s.Settings.Get().ResPath
}

// lazyFetchOff is the operator kill switch: "off" stops /res serving as well as
// discovery (OA-3).
func (s *Serving) lazyFetchOff() bool {
	if s == nil || s.Settings == nil {
		return false
	}
	return s.Settings.Get().LazyFetch == domain.LazyFetchOff
}

func withinDirectory(root, candidate string) bool {
	relative, err := filepath.Rel(root, candidate)
	if err != nil {
		return false
	}
	return relative != ".." && !strings.HasPrefix(relative, ".."+string(os.PathSeparator))
}

func (s *Serving) recordServed(resourcePath string) {
	if s.Ledger != nil {
		s.Ledger.RecordServed(resourcePath, s.now())
	}
}

func (s *Serving) recordMiss(resourcePath, md5 string) {
	if s.Ledger != nil {
		s.Ledger.RecordMiss(resourcePath, md5, s.now())
	}
}

// ResDownloadURL is MID 20480 discovery (ruling 6): the /res/ base exactly when
// lazy fetch is effective, otherwise "".
func (s *Serving) ResDownloadURL(ctx context.Context) (string, error) {
	if s == nil || s.Root == "" || s.Settings == nil {
		return "", nil
	}
	settings := s.Settings.Get()
	if settings.LazyFetch == domain.LazyFetchOff || settings.ResPath == "" {
		return "", nil
	}
	snapshot, err := s.current(ctx)
	if err != nil {
		return "", err
	}
	if !settings.LazyFetchEnabled(snapshot.assetsActive) || !snapshot.resPathUsable || snapshot.assetsIndexEntries == 0 {
		return "", nil
	}
	return strings.TrimRight(s.PublicEngineURL, "/") + resourceURLPathPart, nil
}

// Covers is the ARCHITECTURE section 4 seam EVENTS calls before scheduling.
func (s *Serving) Covers(ctx context.Context, request domain.CoversRequest) (domain.CoversResult, error) {
	snapshot, err := s.current(ctx)
	if err != nil {
		return domain.CoversResult{}, err
	}
	resPath := s.resPath()
	present := func(asset domain.LazyAsset) bool {
		for _, candidate := range snapshot.resources[resourceKey(asset.Path, asset.MD5)] {
			file, _, err := s.openVerified(resPath, candidate)
			if err == nil {
				file.Close()
				return true
			}
		}
		return false
	}
	return domain.EvaluateCovers(request, snapshot.active.ClientPaths, snapshot.active.CodeVersion, present), nil
}

// VerifyActiveVolumes is the startup check: every ACTIVE volume must exist under
// the root with its registered size, or an advertised descriptor would 404.
func VerifyActiveVolumes(releases []domain.Release, root string) error {
	for _, release := range releases {
		for _, volume := range release.Volumes {
			filePath := filepath.Join(root, updatesDirectory, string(release.Lane), volume.Name)
			info, err := os.Stat(filePath)
			if err != nil {
				return fmt.Errorf("OTA release %s volume %s: %w", release.Version, volume.Name, err)
			}
			if !info.Mode().IsRegular() {
				return fmt.Errorf("OTA release %s volume %s is not a regular file", release.Version, volume.Name)
			}
			if info.Size() != volume.Size {
				return fmt.Errorf("OTA release %s volume %s is %d bytes, registered %d", release.Version, volume.Name, info.Size(), volume.Size)
			}
		}
	}
	return nil
}

func resourceKey(resourcePath, md5 string) string {
	return path.Base(resourcePath) + "." + md5
}

func requestMD5(asset string) string {
	dot := strings.LastIndexByte(asset, '.')
	if dot <= 0 || dot == len(asset)-1 {
		return ""
	}
	if !validMD5(asset[dot+1:]) {
		return ""
	}
	return asset[dot+1:]
}

func validMD5(text string) bool {
	if len(text) != 32 || strings.ToLower(text) != text {
		return false
	}
	_, err := hex.DecodeString(text)
	return err == nil
}

// validResourcePath is the V1 rule: no backslashes, no absolute path, and no
// "." or ".." segments, including ones a clean step would collapse.
func validResourcePath(value string) (string, bool) {
	if value == "" || strings.ContainsRune(value, '\\') || strings.IndexByte(value, 0) >= 0 {
		return "", false
	}
	if strings.HasPrefix(value, "/") || path.Clean(value) != value {
		return "", false
	}
	for part := range strings.SplitSeq(value, "/") {
		if part == "" || part == "." || part == ".." {
			return "", false
		}
	}
	return value, true
}

func validVolumeName(name string) bool {
	return name != "" && name != "." && name != ".." && !strings.ContainsAny(name, "/\\\x00")
}

func openRegular(filePath string) (io.ReadSeekCloser, time.Time, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, time.Time{}, err
	}
	info, err := file.Stat()
	if err != nil {
		file.Close()
		return nil, time.Time{}, err
	}
	if !info.Mode().IsRegular() {
		file.Close()
		return nil, time.Time{}, os.ErrNotExist
	}
	return file, info.ModTime(), nil
}
