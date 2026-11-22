//go:build !windows

package main

import (
	"errors"
	"fmt"
	"syscall"
)

// applyLimits caps the worker before it reads any input. Every limit except the
// two that must be zero is required.
func applyLimits(memory, cpu, files uint64) error {
	limits := []struct {
		resource int
		value    uint64
	}{{syscall.RLIMIT_AS, memory}, {syscall.RLIMIT_CPU, cpu}, {syscall.RLIMIT_NOFILE, files}, {syscall.RLIMIT_FSIZE, 0}, {syscall.RLIMIT_CORE, 0}}
	for _, limit := range limits {
		if limit.value == 0 && limit.resource != syscall.RLIMIT_FSIZE && limit.resource != syscall.RLIMIT_CORE {
			return errors.New("every resource limit is required")
		}
		if err := syscall.Setrlimit(limit.resource, &syscall.Rlimit{Cur: limit.value, Max: limit.value}); err != nil {
			return fmt.Errorf("setrlimit: %w", err)
		}
	}
	return nil
}
