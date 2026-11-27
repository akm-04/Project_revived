package otarelease

import (
	"os"
	"path/filepath"
)

// writeFileAtomically replaces path with data: the temp file is written and
// fsynced, renamed over the target, then the folder is fsynced, so a crash
// leaves either the old file or the new one, never a half-written record.
func writeFileAtomically(path string, data []byte) error {
	directory := filepath.Dir(path)
	temporary, err := os.CreateTemp(directory, "."+filepath.Base(path)+"-*.tmp")
	if err != nil {
		return err
	}
	temporaryName := temporary.Name()
	removeTemporary := func() { _ = os.Remove(temporaryName) }
	if _, err := temporary.Write(data); err != nil {
		_ = temporary.Close()
		removeTemporary()
		return err
	}
	if err := temporary.Sync(); err != nil {
		_ = temporary.Close()
		removeTemporary()
		return err
	}
	if err := temporary.Close(); err != nil {
		removeTemporary()
		return err
	}
	if err := os.Rename(temporaryName, path); err != nil {
		removeTemporary()
		return err
	}
	return syncDirectory(directory)
}

func syncDirectory(path string) error {
	directory, err := os.Open(path)
	if err != nil {
		return err
	}
	defer directory.Close()
	return directory.Sync()
}
