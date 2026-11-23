//go:build windows

package operatoragent

const terminalUnsupportedMessage = "the terminal is not available on Windows yet"

// openShellProcess refuses on Windows: the agent has no pseudo terminal there.
func openShellProcess(string, string, []string) (shellProcess, error) {
	return nil, errTerminalUnsupported
}
