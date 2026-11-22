//go:build windows

package combatworker

import "os/exec"

// configureProcess refuses to launch: the worker's isolation needs POSIX
// process groups and resource limits, and there is no unsandboxed fallback.
func configureProcess(*exec.Cmd) error {
	return permanent("the combat worker requires Unix process groups; Windows is not supported")
}

// killProcessGroup is unreachable while configureProcess refuses to launch.
func killProcessGroup(int) {}
