package otabuild

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

// patchDefinition is patch.json. The decoder refuses unknown fields, so a
// typo cannot silently drop an instruction.
type patchDefinition struct {
	Target        string            `json:"target"`
	StockSHA256   string            `json:"stock_sha256"`
	Kind          string            `json:"kind"`
	Anchor        string            `json:"anchor"`
	Insert        string            `json:"insert"`
	Substitutions map[string]string `json:"substitutions"`
	Origin        string            `json:"origin"`
}

var stockHashPattern = regexp.MustCompile(`^[0-9a-f]{64}$`)

// patchKinds is the registered Go implementation per patch kind. A new
// patch.json kind needs a function here, never a script.
var patchKinds = map[string]func(patchDefinition, []byte, []byte) ([]byte, error){
	"insert_before_final_return": insertBeforeFinalReturn,
}

func collectPatches(patchesRoot string, baseline stockBaseline, files map[string][]byte) (int, error) {
	entries, err := os.ReadDir(patchesRoot)
	if errors.Is(err, os.ErrNotExist) {
		return 0, nil
	}
	if err != nil {
		return 0, fmt.Errorf("otabuild: patches directory: %w", err)
	}
	added := 0
	for _, entry := range entries {
		// A symlinked patch directory would otherwise be skipped and the release
		// would ship without its client change.
		if !entry.IsDir() {
			if isDocumentationFile(entry) {
				continue
			}
			return 0, fmt.Errorf("%w: unexpected entry %q in patches", ErrInvalidPatch, entry.Name())
		}
		directory := filepath.Join(patchesRoot, entry.Name())
		target, content, err := applyPatchDirectory(directory, baseline)
		if err != nil {
			return 0, fmt.Errorf("otabuild: patch %s: %w", entry.Name(), err)
		}
		if err := addPackageFile(files, target, content); err != nil {
			return 0, err
		}
		added++
	}
	return added, nil
}

// isDocumentationFile allows the top-level README the old layout keeps beside
// patch directories; every other non-directory entry is refused.
func isDocumentationFile(entry os.DirEntry) bool {
	if !entry.Type().IsRegular() {
		return false
	}
	return entry.Name() == "README" || entry.Name() == "README.md"
}

func applyPatchDirectory(directory string, baseline stockBaseline) (string, []byte, error) {
	definition, err := readPatchDefinition(filepath.Join(directory, "patch.json"))
	if err != nil {
		return "", nil, err
	}
	target, err := cleanStockMember(definition.Target)
	if err != nil {
		return "", nil, err
	}
	stock, err := stockFile(baseline, target)
	if err != nil {
		return "", nil, err
	}
	if sha256Hex(stock) != definition.StockSHA256 {
		return "", nil, fmt.Errorf("%w: %s", ErrStockHashMismatch, target)
	}
	overlay, err := readPatchOverlay(directory, definition.Insert)
	if err != nil {
		return "", nil, err
	}
	kind, ok := patchKinds[definition.Kind]
	if !ok {
		return "", nil, fmt.Errorf("%w: %q", ErrPatchKind, definition.Kind)
	}
	applied, err := kind(definition, stock, overlay)
	if err != nil {
		return "", nil, err
	}
	return target, applied, nil
}

func readPatchDefinition(path string) (patchDefinition, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return patchDefinition{}, fmt.Errorf("%w: read patch.json: %v", ErrInvalidPatch, err)
	}
	decoder := json.NewDecoder(bytes.NewReader(content))
	decoder.DisallowUnknownFields()
	var definition patchDefinition
	if err := decoder.Decode(&definition); err != nil {
		return patchDefinition{}, fmt.Errorf("%w: patch.json: %v", ErrInvalidPatch, err)
	}
	var trailing json.RawMessage
	if err := decoder.Decode(&trailing); !errors.Is(err, io.EOF) {
		return patchDefinition{}, fmt.Errorf("%w: patch.json has trailing data", ErrInvalidPatch)
	}
	if definition.Target == "" || definition.Kind == "" || definition.Insert == "" || definition.Anchor == "" {
		return patchDefinition{}, fmt.Errorf("%w: target, kind, insert and anchor are required", ErrInvalidPatch)
	}
	if !stockHashPattern.MatchString(definition.StockSHA256) {
		return patchDefinition{}, fmt.Errorf("%w: stock_sha256 is not lowercase hex", ErrInvalidPatch)
	}
	return definition, nil
}

func readPatchOverlay(directory, insert string) ([]byte, error) {
	member, err := cleanStockMember(insert)
	if err != nil {
		return nil, err
	}
	content, err := os.ReadFile(filepath.Join(directory, filepath.FromSlash(member)))
	if err != nil {
		return nil, fmt.Errorf("%w: read overlay %q: %v", ErrInvalidPatch, insert, err)
	}
	return content, nil
}

// insertBeforeFinalReturn reproduces the retired Python generator byte for
// byte: read with universal newlines (CRLF -> LF), substitute the overlay, then
// insert it before the single final `return` anchor line.
func insertBeforeFinalReturn(definition patchDefinition, stockBytes, overlayBytes []byte) ([]byte, error) {
	stock := []byte(normalizeNewlines(stockBytes))
	patched := normalizeNewlines(overlayBytes)
	placeholders := make([]string, 0, len(definition.Substitutions))
	for placeholder := range definition.Substitutions {
		placeholders = append(placeholders, placeholder)
	}
	sort.Strings(placeholders)
	for _, placeholder := range placeholders {
		if !strings.Contains(patched, placeholder) {
			return nil, fmt.Errorf("%w: overlay has no substitution %q", ErrInvalidPatch, placeholder)
		}
		patched = strings.ReplaceAll(patched, placeholder, definition.Substitutions[placeholder])
	}
	anchor := regexp.QuoteMeta(definition.Anchor)
	occurrences := regexp.MustCompile(`(?m)^`+anchor+`[ \t\r]*$`).FindAllIndex(stock, -1)
	if len(occurrences) != 1 {
		return nil, fmt.Errorf("%w: %q appears %d times", ErrPatchAnchor, definition.Anchor, len(occurrences))
	}
	// The anchor must be the last non-whitespace line, like the stock file.
	final := regexp.MustCompile(`(\r?\n)` + anchor + `(\s*)\z`).FindSubmatchIndex(stock)
	if final == nil {
		return nil, fmt.Errorf("%w: %q is not the final line", ErrPatchAnchor, definition.Anchor)
	}
	leading := string(stock[final[2]:final[3]])
	trailing := stock[final[4]:final[5]]
	output := make([]byte, 0, len(stock)+len(patched)+len(definition.Anchor)+4)
	output = append(output, stock[:final[2]]...)
	output = append(output, leading...)
	output = append(output, strings.TrimRight(patched, "\n")...)
	output = append(output, "\n\n"...)
	output = append(output, definition.Anchor...)
	output = append(output, trailing...)
	return output, nil
}

// normalizeNewlines matches Python's universal-newline text mode, which the
// retired generator used for both inputs.
func normalizeNewlines(content []byte) string {
	text := strings.ReplaceAll(string(content), "\r\n", "\n")
	return strings.ReplaceAll(text, "\r", "\n")
}
