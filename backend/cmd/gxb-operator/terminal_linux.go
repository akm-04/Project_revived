//go:build linux

package main

import (
	"fmt"
	"os"

	"golang.org/x/sys/unix"
)

// readPassword turns echo off on the terminal; when stdin is not a terminal it
// reads a line from stdin (I11A_1_PLAN "Agent decisions").
func readPassword(prompt string) (string, error) {
	fd := int(os.Stdin.Fd())
	state, err := unix.IoctlGetTermios(fd, unix.TCGETS)
	if err != nil {
		return readLine(prompt)
	}
	hidden := *state
	hidden.Lflag &^= unix.ECHO
	if err := unix.IoctlSetTermios(fd, unix.TCSETS, &hidden); err != nil {
		return readLine(prompt)
	}
	fmt.Fprint(os.Stderr, prompt)
	line, readErr := stdinReader.ReadString('\n')
	_ = unix.IoctlSetTermios(fd, unix.TCSETS, state)
	fmt.Fprintln(os.Stderr)
	if readErr != nil && line == "" {
		return "", readErr
	}
	return trimLine(line), nil
}
