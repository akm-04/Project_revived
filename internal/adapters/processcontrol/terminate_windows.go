//go:build windows

package processcontrol

import (
	"os/exec"
	"syscall"

	"golang.org/x/sys/windows"
)

func prepare(command *exec.Cmd) {
	command.SysProcAttr = &syscall.SysProcAttr{CreationFlags: windows.CREATE_NEW_PROCESS_GROUP}
}

// terminate sends CTRL_BREAK to the child's process group; the caller kills it
// after the grace period when that does not work.
func terminate(command *exec.Cmd) {
	if err := windows.GenerateConsoleCtrlEvent(windows.CTRL_BREAK_EVENT, uint32(command.Process.Pid)); err != nil {
		_ = command.Process.Kill()
	}
}
