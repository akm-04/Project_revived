//go:build !windows

package processcontrol

import (
	"os/exec"
	"syscall"
)

func prepare(*exec.Cmd) {}

// terminate sends SIGTERM; the caller kills the child after the grace period.
func terminate(command *exec.Cmd) {
	_ = command.Process.Signal(syscall.SIGTERM)
}
