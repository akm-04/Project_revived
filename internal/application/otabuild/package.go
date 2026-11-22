package otabuild

import (
	"archive/zip"
	"fmt"
	"os"
)

// msDos1980JanuaryFirst is the fixed MS-DOS date 1980-01-01, the earliest a
// zip header can encode. Fixing it keeps the archive byte-identical across
// builds; Modified stays zero so the writer adds no timestamp extra field.
const msDos1980JanuaryFirst uint16 = 33

// writeAssembled writes the deterministic package zip: sorted entries, fixed
// date, deflate, no extra fields (I11A_1_PLAN "Builder decisions").
func writeAssembled(path string, entries []packageEntry) (int64, error) {
	file, err := os.Create(path)
	if err != nil {
		return 0, fmt.Errorf("otabuild: create package: %w", err)
	}
	writer := zip.NewWriter(file)
	for _, entry := range entries {
		header := &zip.FileHeader{
			Name:         entry.path,
			Method:       zip.Deflate,
			ModifiedDate: msDos1980JanuaryFirst,
		}
		header.SetMode(0o644)
		target, err := writer.CreateHeader(header)
		if err != nil {
			file.Close()
			return 0, fmt.Errorf("otabuild: create zip entry %q: %w", entry.path, err)
		}
		if _, err := target.Write(entry.content); err != nil {
			file.Close()
			return 0, fmt.Errorf("otabuild: write zip entry %q: %w", entry.path, err)
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
