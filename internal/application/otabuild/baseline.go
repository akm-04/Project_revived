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

// stockFile reads the src_64 copy of a client path and checks the src_32 copy
// is byte-identical (ruling 8). A real ABI difference needs a new owner
// decision, so the build refuses it.
func stockFile(baseline stockBaseline, clientPath string) ([]byte, error) {
	path64 := stockPrefix64 + clientPath
	path32 := stockPrefix32 + clientPath
	content64, err := baseline.read(path64)
	if err != nil {
		return nil, err
	}
	content32, err := baseline.read(path32)
	if err != nil {
		return nil, err
	}
	if !bytes.Equal(content64, content32) {
		return nil, fmt.Errorf("%w: %s", ErrAbiMismatch, clientPath)
	}
	return content64, nil
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
