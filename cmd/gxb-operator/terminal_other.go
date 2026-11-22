//go:build !windows && !linux

package main

// readPassword on other systems reads from stdin without hiding echo.
func readPassword(prompt string) (string, error) {
	return readLine(prompt)
}
