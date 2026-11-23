//go:build !linux && !windows

package operatoragent

const terminalUnsupportedMessage = "the terminal is not available on this platform yet"

// openShellProcess refuses on the other systems: only Linux is proven for now.
func openShellProcess(string, string, []string) (shellProcess, error) {
	return nil, errTerminalUnsupported
}
