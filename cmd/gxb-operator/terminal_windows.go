//go:build windows

package main

import (
	"fmt"
	"os"

	"golang.org/x/sys/windows"
)

// readPassword turns echo off on the console; when stdin is not a console it
// reads a line from stdin (I11A_1_PLAN "Agent decisions").
func readPassword(prompt string) (string, error) {
	handle := windows.Handle(os.Stdin.Fd())
	var mode uint32
	if err := windows.GetConsoleMode(handle, &mode); err != nil {
		return readLine(prompt)
	}
	hidden := mode &^ windows.ENABLE_ECHO_INPUT
	if err := windows.SetConsoleMode(handle, hidden); err != nil {
		return readLine(prompt)
	}
	fmt.Fprint(os.Stderr, prompt)
	line, readErr := stdinReader.ReadString('\n')
	_ = windows.SetConsoleMode(handle, mode)
	fmt.Fprintln(os.Stderr)
	if readErr != nil && line == "" {
		return "", readErr
	}
	return trimLine(line), nil
}
