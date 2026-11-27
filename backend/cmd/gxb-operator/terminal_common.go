package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

// stdinReader is shared so a piped setup with two password lines is not lost to
// a per-call buffer.
var stdinReader = bufio.NewReader(os.Stdin)

func readLine(prompt string) (string, error) {
	fmt.Fprint(os.Stderr, prompt)
	line, err := stdinReader.ReadString('\n')
	if err != nil && line == "" {
		return "", err
	}
	return strings.TrimRight(line, "\r\n"), nil
}

func trimLine(line string) string { return strings.TrimRight(line, "\r\n") }
