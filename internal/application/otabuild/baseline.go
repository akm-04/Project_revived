package otabuild

import (
	"archive/zip"
	"bytes"
	"fmt"
	"io"
	"os"
	"path"
	"path/filepath"
	"strings"
)

// stockBaseline reads the configured stock client tree, either an extracted
// directory or the plaintext zip the operator saved.
type stockBaseline interface {
	read(member string) ([]byte, error)
}

const (
	stockPrefix32 = "assets/src_32/"
	stockPrefix64 = "assets/src_64/"
)

func openBaseline(source string) (stockBaseline, func(), error) {
	info, err := os.Stat(source)
	if err != nil {
		return nil, nil, fmt.Errorf("%w: stock baseline: %v", ErrInvalidInput, err)
	}
	if info.IsDir() {
		return directoryBaseline{root: source}, func() {}, nil
	}
	reader, err := zip.OpenReader(source)
	if err != nil {
		return nil, nil, fmt.Errorf("%w: stock baseline zip: %v", ErrInvalidInput, err)
	}
	index := make(map[string]*zip.File, len(reader.File))
	for _, file := range reader.File {
		if file.FileInfo().IsDir() {
			continue
		}
		index[file.Name] = file
	}
	return zipBaseline{files: index}, func() { reader.Close() }, nil
}

type directoryBaseline struct {
	root string
}

func (baseline directoryBaseline) read(member string) ([]byte, error) {
	content, err := os.ReadFile(filepath.Join(baseline.root, filepath.FromSlash(member)))
	if err != nil {
		return nil, fmt.Errorf("otabuild: stock baseline %s: %w", member, err)
	}
	return content, nil
}

type zipBaseline struct {
	files map[string]*zip.File
}

func (baseline zipBaseline) read(member string) ([]byte, error) {
	file, ok := baseline.files[member]
	if !ok {
		return nil, fmt.Errorf("otabuild: stock baseline has no %s", member)
	}
	reader, err := file.Open()
	if err != nil {
		return nil, fmt.Errorf("otabuild: stock baseline %s: %w", member, err)
	}
	defer reader.Close()
	var buffer bytes.Buffer
	if _, err := io.Copy(&buffer, reader); err != nil {
		return nil, fmt.Errorf("otabuild: stock baseline %s: %w", member, err)
	}
	return buffer.Bytes(), nil
}

// stockSource is the decompiled stock Lua tree at client paths. Patch pins are
// hashes of this source, never of the APK's src_32/src_64 LuaJIT bytecode,
// which differs by ABI (I11A_OTA_RELEASE_V1 ruling 8).
type stockSource struct {
	root string
}

func (source stockSource) read(clientPath string) ([]byte, error) {
	target := filepath.Join(source.root, filepath.FromSlash(clientPath))
	info, err := os.Lstat(target)
	if err != nil {
		return nil, fmt.Errorf("otabuild: stock source %s: %w", clientPath, err)
	}
	if info.Mode()&os.ModeSymlink != 0 {
		return nil, fmt.Errorf("%w: stock source %s is a symlink", ErrInvalidInput, clientPath)
	}
	resolvedRoot, err := filepath.EvalSymlinks(source.root)
	if err != nil {
		return nil, fmt.Errorf("%w: stock source root: %v", ErrInvalidInput, err)
	}
	resolved, err := filepath.EvalSymlinks(target)
	if err != nil {
		return nil, fmt.Errorf("otabuild: stock source %s: %w", clientPath, err)
	}
	relative, err := filepath.Rel(resolvedRoot, resolved)
	if err != nil || relative == ".." || strings.HasPrefix(relative, ".."+string(os.PathSeparator)) {
		return nil, fmt.Errorf("%w: stock source %s escapes its root", ErrInvalidInput, clientPath)
	}
	content, err := os.ReadFile(resolved)
	if err != nil {
		return nil, fmt.Errorf("otabuild: stock source %s: %w", clientPath, err)
	}
	return content, nil
}

// cleanStockMember normalises a patch target and rejects anything that could
// escape the stock tree.
func cleanStockMember(target string) (string, error) {
	cleaned := path.Clean(strings.ReplaceAll(target, `\`, "/"))
	if cleaned == "." || strings.HasPrefix(cleaned, "../") || strings.HasPrefix(cleaned, "/") {
		return "", fmt.Errorf("%w: unsafe target %q", ErrInvalidPatch, target)
	}
	return cleaned, nil
}
