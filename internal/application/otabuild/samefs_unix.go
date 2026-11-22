//go:build !windows

package otabuild

import (
	"fmt"
	"os"
	"syscall"
)

// sameFilesystem compares the device ids of two existing directories.
func sameFilesystem(left, right string) (bool, error) {
	leftDevice, err := deviceID(left)
	if err != nil {
		return false, err
	}
	rightDevice, err := deviceID(right)
	if err != nil {
		return false, err
	}
	return leftDevice == rightDevice, nil
}

func deviceID(directory string) (uint64, error) {
	info, err := os.Stat(directory)
	if err != nil {
		return 0, err
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok {
		return 0, fmt.Errorf("otabuild: no device id for %s", directory)
	}
	return uint64(stat.Dev), nil
}
