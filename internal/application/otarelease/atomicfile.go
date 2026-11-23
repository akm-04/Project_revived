package otarelease

import (
	"errors"
	"os"
	"path/filepath"
)

// writeFileAtomically replaces path with data: the temp file is written and
// fsynced, renamed over the target, then the folder is fsynced, so a crash
// leaves either the old file or the new one, never a half-written record.
func writeFileAtomically(path string, data []byte) error {
	_, err := publishTempFile(path, data, false)
	return err
}

// writeFileExclusively publishes data at path only while no file is there yet,
// so a seed never replaces a state file another writer already created. It
// reports false when the target exists.
func writeFileExclusively(path string, data []byte) (bool, error) {
	return publishTempFile(path, data, true)
}

func publishTempFile(path string, data []byte, exclusive bool) (bool, error) {
	directory := filepath.Dir(path)
	temporary, err := os.CreateTemp(directory, "."+filepath.Base(path)+"-*.tmp")
	if err != nil {
		return false, err
	}
	temporaryName := temporary.Name()
	removeTemporary := func() { _ = os.Remove(temporaryName) }
	if _, err := temporary.Write(data); err != nil {
		_ = temporary.Close()
		removeTemporary()
		return false, err
	}
	if err := temporary.Sync(); err != nil {
		_ = temporary.Close()
		removeTemporary()
		return false, err
	}
	if err := temporary.Close(); err != nil {
		removeTemporary()
		return false, err
	}
	if exclusive {
		if err := os.Link(temporaryName, path); err != nil {
			removeTemporary()
			if errors.Is(err, os.ErrExist) {
				return false, nil
			}
			return false, err
		}
		removeTemporary()
	} else if err := os.Rename(temporaryName, path); err != nil {
		removeTemporary()
		return false, err
	}
	if err := syncDirectory(directory); err != nil {
		return false, err
	}
	return true, nil
}

func syncDirectory(path string) error {
	directory, err := os.Open(path)
	if err != nil {
		return err
	}
	defer directory.Close()
	return directory.Sync()
}
