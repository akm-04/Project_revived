//go:build linux

package operatoragent

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"syscall"

	"golang.org/x/sys/unix"
)

const terminalUnsupportedMessage = "the terminal is not available on this platform yet"

// openShellProcess starts the shell on a new Linux pseudo terminal. The child
// leads its own session and process group, so closing the terminal kills every
// process it started.
func openShellProcess(shellPath, workingDirectory string, environment []string) (shellProcess, error) {
	master, err := os.OpenFile("/dev/ptmx", os.O_RDWR|syscall.O_NOCTTY, 0)
	if err != nil {
		return nil, err
	}
	closeOnError := func() {
		_ = master.Close()
	}
	if err := unix.IoctlSetPointerInt(int(master.Fd()), unix.TIOCSPTLCK, 0); err != nil {
		closeOnError()
		return nil, err
	}
	number, err := unix.IoctlGetInt(int(master.Fd()), unix.TIOCGPTN)
	if err != nil {
		closeOnError()
		return nil, err
	}
	slave, err := os.OpenFile(fmt.Sprintf("/dev/pts/%d", number), os.O_RDWR|syscall.O_NOCTTY, 0)
	if err != nil {
		closeOnError()
		return nil, err
	}
	if err := unix.IoctlSetWinsize(int(master.Fd()), unix.TIOCSWINSZ, &unix.Winsize{Row: 24, Col: 80}); err != nil {
		_ = slave.Close()
		closeOnError()
		return nil, err
	}
	command := exec.Command(shellPath)
	command.Dir = workingDirectory
	command.Env = environment
	command.Stdin = slave
	command.Stdout = slave
	command.Stderr = slave
	command.SysProcAttr = &syscall.SysProcAttr{Setsid: true, Setctty: true, Ctty: 0}
	if err := command.Start(); err != nil {
		_ = slave.Close()
		closeOnError()
		return nil, err
	}
	_ = slave.Close()
	return &linuxShellProcess{master: master, command: command}, nil
}

type linuxShellProcess struct {
	master  *os.File
	command *exec.Cmd
}

func (process *linuxShellProcess) Read(buffer []byte) (int, error) {
	return process.master.Read(buffer)
}

func (process *linuxShellProcess) Write(data []byte) (int, error) {
	return process.master.Write(data)
}

func (process *linuxShellProcess) Resize(columns, rows uint16) error {
	return unix.IoctlSetWinsize(int(process.master.Fd()), unix.TIOCSWINSZ, &unix.Winsize{Row: rows, Col: columns})
}

func (process *linuxShellProcess) Pid() int {
	return process.command.Process.Pid
}

func (process *linuxShellProcess) Kill() error {
	err := syscall.Kill(-process.command.Process.Pid, syscall.SIGKILL)
	if err == nil || errors.Is(err, syscall.ESRCH) {
		return nil
	}
	_ = process.command.Process.Kill()
	return err
}

func (process *linuxShellProcess) Wait() error {
	return process.command.Wait()
}

func (process *linuxShellProcess) Close() error {
	return process.master.Close()
}
