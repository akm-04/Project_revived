//go:build !windows

package combatworker

import (
	"os/exec"
	"syscall"
)

// configureProcess puts the worker in its own process group and makes the
// kernel kill it when the launcher dies (I8-2B).
func configureProcess(command *exec.Cmd) error {
	command.SysProcAttr = &syscall.SysProcAttr{Setpgid: true, Pdeathsig: syscall.SIGKILL}
	return nil
}

// killProcessGroup kills the worker and every process it spawned.
func killProcessGroup(pid int) {
	_ = syscall.Kill(-pid, syscall.SIGKILL)
}
