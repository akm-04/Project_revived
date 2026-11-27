package operatoragent

import (
	"errors"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
)

// MaxFileListEntries bounds one folder listing the GUI path picker shows; a
// larger folder reports truncated and the operator narrows the folder.
const MaxFileListEntries = 2000

const directoryReadChunk = 256

// FileListRequest is the agent.fs.list query: one folder, and whether files
// are listed beside its folders.
type FileListRequest struct {
	Path      string
	ShowFiles bool
}

// FileEntry is one name in a folder. The picker gets no content, size or mode.
type FileEntry struct {
	Name  string `json:"name"`
	IsDir bool   `json:"is_dir"`
}

// FileListing is the agent.fs.list answer. Parent is empty at a filesystem
// root; DriveRoots is present only on Windows.
type FileListing struct {
	Path       string      `json:"path"`
	Parent     string      `json:"parent"`
	Entries    []FileEntry `json:"entries"`
	DriveRoots []string    `json:"drive_roots,omitempty"`
	Truncated  bool        `json:"truncated"`
}

// FileBrowser lists folders for the GUI path picker. It never opens a file:
// only the entries' names and whether each is a folder leave the agent.
type FileBrowser struct {
	// Root is the agent root folder, the empty path's start.
	Root string
}

// List answers one folder. A relative path is read from the agent root; an
// empty path is the root. A missing, unreadable or non-folder path is a
// permanent refusal the operator reads as plain words.
func (browser FileBrowser) List(request FileListRequest) (FileListing, error) {
	root, err := filepath.Abs(browser.Root)
	if err != nil || browser.Root == "" {
		return FileListing{}, Refuse(CodePathUnreadable, "the agent root folder is not configured")
	}
	target := strings.TrimSpace(request.Path)
	if target == "" {
		target = root
	}
	if !filepath.IsAbs(target) {
		target = filepath.Join(root, target)
	}
	target = filepath.Clean(target)
	info, err := os.Stat(target)
	if err != nil {
		return FileListing{}, Refuse(CodePathUnreadable, target+" does not exist or cannot be read")
	}
	if !info.IsDir() {
		return FileListing{}, Refuse(CodePathNotFolder, target+" is a file, not a folder")
	}
	directory, err := os.Open(target)
	if err != nil {
		return FileListing{}, Refuse(CodePathUnreadable, target+" cannot be read")
	}
	defer directory.Close()
	entries, truncated, err := readFolderEntries(directory, target, request.ShowFiles)
	if err != nil {
		return FileListing{}, err
	}
	parent := filepath.Dir(target)
	if parent == target {
		parent = ""
	}
	return FileListing{
		Path:       target,
		Parent:     parent,
		Entries:    entries,
		DriveRoots: windowsDriveRoots(),
		Truncated:  truncated,
	}, nil
}

// readFolderEntries reads at most MaxFileListEntries visible entries and stops
// one entry past the limit, so truncated is exact without reading a whole
// very large folder.
func readFolderEntries(directory *os.File, path string, showFiles bool) ([]FileEntry, bool, error) {
	entries := make([]FileEntry, 0, MaxFileListEntries)
	for {
		chunk, readErr := directory.ReadDir(directoryReadChunk)
		for _, entry := range chunk {
			name := entry.Name()
			if strings.HasPrefix(name, ".") {
				continue
			}
			isDirectory := entryIsDirectory(path, entry)
			if !isDirectory && !showFiles {
				continue
			}
			entries = append(entries, FileEntry{Name: name, IsDir: isDirectory})
			if len(entries) > MaxFileListEntries {
				return sortedEntries(entries[:MaxFileListEntries]), true, nil
			}
		}
		if errors.Is(readErr, io.EOF) {
			break
		}
		if readErr != nil {
			return nil, false, Refuse(CodePathUnreadable, path+" cannot be read")
		}
		if len(chunk) == 0 {
			break
		}
	}
	return sortedEntries(entries), false, nil
}

// entryIsDirectory follows a symlink, so a linked folder still opens in the
// picker. A broken link stays a file.
func entryIsDirectory(path string, entry os.DirEntry) bool {
	if entry.IsDir() {
		return true
	}
	if entry.Type()&os.ModeSymlink == 0 {
		return false
	}
	info, err := os.Stat(filepath.Join(path, entry.Name()))
	return err == nil && info.IsDir()
}

// sortedEntries puts folders first, then names case-insensitively; names that
// differ only by case keep a stable order.
func sortedEntries(entries []FileEntry) []FileEntry {
	sort.SliceStable(entries, func(left, right int) bool {
		if entries[left].IsDir != entries[right].IsDir {
			return entries[left].IsDir
		}
		leftName := strings.ToLower(entries[left].Name)
		rightName := strings.ToLower(entries[right].Name)
		if leftName != rightName {
			return leftName < rightName
		}
		return entries[left].Name < entries[right].Name
	})
	return entries
}

// windowsDriveRoots is the A:..Z: list that exists, so the picker can switch
// drives; Linux has one root and no list.
func windowsDriveRoots() []string {
	if runtime.GOOS != "windows" {
		return nil
	}
	roots := make([]string, 0, 26)
	for letter := 'A'; letter <= 'Z'; letter++ {
		root := string(letter) + ":\\"
		if info, err := os.Stat(root); err == nil && info.IsDir() {
			roots = append(roots, root)
		}
	}
	return roots
}
