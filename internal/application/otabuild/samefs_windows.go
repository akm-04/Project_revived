//go:build windows

package otabuild

import (
	"fmt"
	"path/filepath"
	"strings"
)

// sameFilesystem compares the volume names of two existing directories.
func sameFilesystem(left, right string) (bool, error) {
	leftVolume, err := volumeName(left)
	if err != nil {
		return false, err
	}
	rightVolume, err := volumeName(right)
	if err != nil {
		return false, err
	}
	return strings.EqualFold(leftVolume, rightVolume), nil
}

func volumeName(directory string) (string, error) {
	absolute, err := filepath.Abs(directory)
	if err != nil {
		return "", err
	}
	volume := filepath.VolumeName(absolute)
	if volume == "" {
		return "", fmt.Errorf("otabuild: no volume name for %s", directory)
	}
	return volume, nil
}
