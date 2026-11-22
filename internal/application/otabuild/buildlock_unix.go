//go:build !windows

package otabuild

import (
	"fmt"
	"os"
	"path/filepath"

	"golang.org/x/sys/unix"
)

// buildLock serializes every build of one OTA root, in this process and across
// agent processes (L4f fix 1).
type buildLock struct {
	file *os.File
}

func acquireBuildLock(updatesRoot string) (*buildLock, error) {
	path := filepath.Join(updatesRoot, ".lock")
	file, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0o644)
	if err != nil {
		return nil, fmt.Errorf("otabuild: open build lock: %w", err)
	}
	if err := unix.Flock(int(file.Fd()), unix.LOCK_EX); err != nil {
		file.Close()
		return nil, fmt.Errorf("otabuild: lock build: %w", err)
	}
	return &buildLock{file: file}, nil
}

func (lock *buildLock) release() {
	_ = unix.Flock(int(lock.file.Fd()), unix.LOCK_UN)
	_ = lock.file.Close()
}
