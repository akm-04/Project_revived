//go:build windows

package otabuild

import (
	"fmt"
	"os"
	"path/filepath"

	"golang.org/x/sys/windows"
)

// buildLock serializes every build of one OTA root, in this process and across
// agent processes (L4f fix 1).
type buildLock struct {
	file       *os.File
	overlapped windows.Overlapped
}

func acquireBuildLock(updatesRoot string) (*buildLock, error) {
	path := filepath.Join(updatesRoot, ".lock")
	file, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0o644)
	if err != nil {
		return nil, fmt.Errorf("otabuild: open build lock: %w", err)
	}
	lock := &buildLock{file: file}
	if err := windows.LockFileEx(windows.Handle(file.Fd()), windows.LOCKFILE_EXCLUSIVE_LOCK, 0, 1, 0, &lock.overlapped); err != nil {
		file.Close()
		return nil, fmt.Errorf("otabuild: lock build: %w", err)
	}
	return lock, nil
}

func (lock *buildLock) release() {
	_ = windows.UnlockFileEx(windows.Handle(lock.file.Fd()), 0, 1, 0, &lock.overlapped)
	_ = lock.file.Close()
}
