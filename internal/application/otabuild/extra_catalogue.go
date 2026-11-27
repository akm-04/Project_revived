package otabuild

import (
	"encoding/csv"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

// extraCatalogueFile is the optional declaration the asset lane writes beside
// its recovered tree: one row per recovered file whose path the stock
// catalogue does not list. The stock catalogue is the only input the refresh
// rewrites, so without this file a recovered asset at a new path could never be
// requested by the client (the client builds every lazy URL from its catalogue).
const extraCatalogueFile = "_extra_catalogue.csv"

type extraCatalogueEntry struct {
	Path string
	MD5  string
	Size int64
}

// readExtraCatalogue loads and verifies the declared rows against the recovered
// tree. An absent file means no extra rows, so existing releases are unchanged.
func readExtraCatalogue(root resRoot) ([]extraCatalogueEntry, error) {
	if root.lexical == "" {
		return nil, nil
	}
	file, err := os.Open(filepath.Join(root.lexical, extraCatalogueFile))
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("%w: extra catalogue: %v", ErrBuildIO, err)
	}
	defer file.Close()

	records, err := csv.NewReader(file).ReadAll()
	if err != nil {
		return nil, fmt.Errorf("%w: extra catalogue: %v", ErrCatalogInvalid, err)
	}
	entries := make([]extraCatalogueEntry, 0, len(records))
	seen := make(map[string]struct{}, len(records))
	for index, record := range records {
		if index == 0 && len(record) == 3 && strings.TrimSpace(record[0]) == "path" {
			continue
		}
		if len(record) != 3 {
			return nil, fmt.Errorf("%w: extra catalogue row %d has %d fields", ErrCatalogInvalid, index+1, len(record))
		}
		path := strings.TrimSpace(record[0])
		digest := strings.ToLower(strings.TrimSpace(record[1]))
		if strings.Contains(path, `\`) {
			return nil, fmt.Errorf("%w: extra catalogue row %q contains a backslash", ErrCatalogInvalid, path)
		}
		path = normalizeCatalogPath(path)
		if !validCatalogPath(path) || !strings.HasPrefix(path, "res/") || !validMD5(digest) {
			return nil, fmt.Errorf("%w: extra catalogue row %q", ErrCatalogInvalid, path)
		}
		if _, duplicate := seen[path]; duplicate {
			return nil, fmt.Errorf("%w: duplicate extra catalogue row %q", ErrCatalogInvalid, path)
		}
		seen[path] = struct{}{}
		size, err := strconv.ParseInt(strings.TrimSpace(record[2]), 10, 64)
		if err != nil || size <= 0 {
			return nil, fmt.Errorf("%w: extra catalogue row %q size %q", ErrCatalogInvalid, path, record[2])
		}
		relative, actualSize, actualMD5, found, err := recoveredFile(root, path)
		if err != nil {
			return nil, err
		}
		if !found {
			return nil, fmt.Errorf("%w: extra catalogue file %q is missing", ErrCatalogInvalid, path)
		}
		if actualSize != size || actualMD5 != digest {
			return nil, fmt.Errorf("%w: extra catalogue row %q does not match %s", ErrCatalogInvalid, path, relative)
		}
		entries = append(entries, extraCatalogueEntry{Path: path, MD5: digest, Size: size})
	}
	return entries, nil
}

// appendExtraRows adds the declared rows as force-0 catalogue rows, with the
// matching res sidecar rows so /res can serve them. A declared path that the
// stock catalogue already lists is a mistake and fails closed.
func appendExtraRows(rows []catalogRow, sidecar []resSidecarEntry, extras []extraCatalogueEntry) ([]catalogRow, []resSidecarEntry, error) {
	if len(extras) == 0 {
		return rows, sidecar, nil
	}
	known := make(map[string]struct{}, len(rows))
	for _, row := range rows {
		known[normalizeCatalogPath(row.Path)] = struct{}{}
	}
	for _, extra := range extras {
		if _, exists := known[extra.Path]; exists {
			return nil, nil, fmt.Errorf("%w: extra catalogue row %q duplicates a stock row", ErrCatalogInvalid, extra.Path)
		}
		known[extra.Path] = struct{}{}
		rows = append(rows, catalogRow{Path: extra.Path, MD5: extra.MD5, Size: extra.Size, Force: 0})
		sidecar = append(sidecar, resSidecarEntry{
			Path: strings.TrimPrefix(extra.Path, "res/"),
			MD5:  extra.MD5,
			Size: extra.Size,
		})
	}
	return rows, sidecar, nil
}
