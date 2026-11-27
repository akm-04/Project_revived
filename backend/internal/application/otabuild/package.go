package otabuild

import (
	"archive/zip"
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"io"
	"os"
)

// msDos1980JanuaryFirst is the fixed MS-DOS date 1980-01-01, the earliest a
// zip header can encode. Fixing it keeps the archive byte-identical across
// builds; Modified stays zero so the writer adds no timestamp extra field.
const msDos1980JanuaryFirst uint16 = 33

// writeAssembled writes the deterministic package zip: sorted entries, fixed
// date, the lane's method (deflate for code, stored for assets), no extra
// fields (I11A_1_PLAN "Builder decisions", "L4c decisions").
func writeAssembled(path string, entries []packageEntry, method uint16) (int64, error) {
	file, err := os.Create(path)
	if err != nil {
		return 0, fmt.Errorf("otabuild: create package: %w", err)
	}
	writer := zip.NewWriter(file)
	for _, entry := range entries {
		header := &zip.FileHeader{
			Name:               entry.path,
			Method:             method,
			ModifiedDate:       msDos1980JanuaryFirst,
			UncompressedSize64: uint64(entry.size),
		}
		header.SetMode(0o644)
		target, err := writer.CreateHeader(header)
		if err != nil {
			file.Close()
			return 0, fmt.Errorf("otabuild: create zip entry %q: %w", entry.path, err)
		}
		if err := copyEntry(target, entry); err != nil {
			file.Close()
			return 0, err
		}
	}
	if err := writer.Close(); err != nil {
		file.Close()
		return 0, fmt.Errorf("otabuild: close package zip: %w", err)
	}
	if err := file.Sync(); err != nil {
		file.Close()
		return 0, fmt.Errorf("otabuild: sync package: %w", err)
	}
	if err := file.Close(); err != nil {
		return 0, fmt.Errorf("otabuild: close package: %w", err)
	}
	info, err := os.Stat(path)
	if err != nil {
		return 0, fmt.Errorf("otabuild: stat package: %w", err)
	}
	return info.Size(), nil
}

// copyEntry streams the entry and verifies its md5 while writing, so a file
// that changed after collection can never ship different bytes than the
// manifest records (L4f fix 4). It hashes the same single read it writes.
func copyEntry(target io.Writer, entry packageEntry) error {
	source, err := entry.open()
	if err != nil {
		return fmt.Errorf("%w: %v", ErrBuildIO, err)
	}
	defer source.Close()
	digest := md5.New()
	written, err := io.Copy(io.MultiWriter(target, digest), source)
	if err != nil {
		return fmt.Errorf("%w: write zip entry %q: %v", ErrBuildIO, entry.path, err)
	}
	if written != entry.size {
		return fmt.Errorf("%w: zip entry %q has %d of %d bytes", ErrBuildIO, entry.path, written, entry.size)
	}
	if actual := hex.EncodeToString(digest.Sum(nil)); actual != entry.md5 {
		return fmt.Errorf("%w: zip entry %q changed while copying", ErrBuildIO, entry.path)
	}
	return nil
}
