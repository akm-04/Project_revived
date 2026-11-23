package operatoragent

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"testing"
)

func writeListingRoot(t *testing.T) string {
	t.Helper()
	root := t.TempDir()
	for _, folder := range []string{"Beta", "alpha", ".hidden"} {
		if err := os.Mkdir(filepath.Join(root, folder), 0o755); err != nil {
			t.Fatal(err)
		}
	}
	for _, file := range []string{"b.txt", "A.txt", ".secret"} {
		if err := os.WriteFile(filepath.Join(root, file), []byte("x"), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	return root
}

func listedNames(entries []FileEntry) []string {
	names := make([]string, 0, len(entries))
	for _, entry := range entries {
		names = append(names, entry.Name)
	}
	return names
}

func TestFileBrowserListSortsFoldersFirstCaseInsensitivelyAndHidesDotEntries(t *testing.T) {
	root := writeListingRoot(t)
	listing, err := (FileBrowser{Root: root}).List(FileListRequest{ShowFiles: true})
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"alpha", "Beta", "A.txt", "b.txt"}
	got := listedNames(listing.Entries)
	if fmt.Sprint(got) != fmt.Sprint(want) {
		t.Fatalf("entries = %v, want %v", got, want)
	}
	if !listing.Entries[0].IsDir || !listing.Entries[1].IsDir || listing.Entries[2].IsDir || listing.Entries[3].IsDir {
		t.Fatalf("is_dir flags = %+v", listing.Entries)
	}
	for _, entry := range listing.Entries {
		if entry.Name == ".hidden" || entry.Name == ".secret" {
			t.Fatalf("a hidden entry was listed: %+v", entry)
		}
	}
	if listing.Path != root || listing.Truncated {
		t.Fatalf("listing = %+v", listing)
	}
}

func TestFileBrowserListFolderModeLeavesFilesOut(t *testing.T) {
	root := writeListingRoot(t)
	listing, err := (FileBrowser{Root: root}).List(FileListRequest{})
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"alpha", "Beta"}
	if got := listedNames(listing.Entries); fmt.Sprint(got) != fmt.Sprint(want) {
		t.Fatalf("entries = %v, want %v", got, want)
	}
}

func TestFileBrowserListEmptyPathStartsAtTheAgentRootAndRelativePathJoinsIt(t *testing.T) {
	root := writeListingRoot(t)
	browser := FileBrowser{Root: root}
	empty, err := browser.List(FileListRequest{})
	if err != nil {
		t.Fatal(err)
	}
	if empty.Path != root {
		t.Fatalf("empty path resolved to %q, want %q", empty.Path, root)
	}
	relative, err := browser.List(FileListRequest{Path: "alpha"})
	if err != nil {
		t.Fatal(err)
	}
	if relative.Path != filepath.Join(root, "alpha") {
		t.Fatalf("relative path resolved to %q", relative.Path)
	}
}

func TestFileBrowserListParentIsEmptyAtTheVolumeRoot(t *testing.T) {
	volumeRoot := filepath.VolumeName(t.TempDir()) + string(filepath.Separator)
	listing, err := (FileBrowser{Root: t.TempDir()}).List(FileListRequest{Path: volumeRoot})
	if err != nil {
		t.Fatal(err)
	}
	if listing.Path != volumeRoot || listing.Parent != "" {
		t.Fatalf("root listing path = %q parent = %q", listing.Path, listing.Parent)
	}
}

func TestFileBrowserListRefusesAMissingFolderAndAFile(t *testing.T) {
	root := t.TempDir()
	_, err := (FileBrowser{Root: root}).List(FileListRequest{Path: filepath.Join(root, "missing")})
	var refusal *Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodePathUnreadable || refusal.Message == "" {
		t.Fatalf("missing folder error = %v", err)
	}
	file := filepath.Join(root, "a-file")
	if writeErr := os.WriteFile(file, []byte("x"), 0o644); writeErr != nil {
		t.Fatal(writeErr)
	}
	_, err = (FileBrowser{Root: root}).List(FileListRequest{Path: file})
	if !errors.As(err, &refusal) || refusal.Code != CodePathNotFolder {
		t.Fatalf("file error = %v", err)
	}
}

func TestFileBrowserListTruncatesAtTheLimit(t *testing.T) {
	root := t.TempDir()
	for index := 0; index <= MaxFileListEntries; index++ {
		name := fmt.Sprintf("file-%04d", index)
		if err := os.WriteFile(filepath.Join(root, name), nil, 0o644); err != nil {
			t.Fatal(err)
		}
	}
	listing, err := (FileBrowser{Root: root}).List(FileListRequest{ShowFiles: true})
	if err != nil {
		t.Fatal(err)
	}
	if len(listing.Entries) != MaxFileListEntries || !listing.Truncated {
		t.Fatalf("entries = %d truncated = %v", len(listing.Entries), listing.Truncated)
	}
	if listing.Entries[0].Name != "file-0000" || listing.Entries[len(listing.Entries)-1].Name != "file-1999" {
		t.Fatalf("truncated window = %q..%q", listing.Entries[0].Name, listing.Entries[len(listing.Entries)-1].Name)
	}
}

func TestFileBrowserListOpensALinkedFolder(t *testing.T) {
	root := t.TempDir()
	target := t.TempDir()
	if err := os.Symlink(target, filepath.Join(root, "linked")); err != nil {
		t.Skipf("symlinks are unavailable: %v", err)
	}
	listing, err := (FileBrowser{Root: root}).List(FileListRequest{})
	if err != nil {
		t.Fatal(err)
	}
	if len(listing.Entries) != 1 || !listing.Entries[0].IsDir {
		t.Fatalf("linked folder listing = %+v", listing.Entries)
	}
}
