//go:build windows

package main

import "errors"

// applyLimits refuses to run: the worker's isolation needs POSIX resource
// limits, and there is no unsandboxed fallback.
func applyLimits(uint64, uint64, uint64) error {
	return errors.New("the combat worker is not supported on Windows: it needs POSIX resource limits")
}
