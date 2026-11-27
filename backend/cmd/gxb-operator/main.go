package main

import (
	"errors"
	"fmt"
	"io"
	"os"
	"strings"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "gxb-operator: "+err.Error())
		os.Exit(1)
	}
}

func run(args []string) error {
	if wantsHelp(args) {
		fmt.Fprint(os.Stdout, operatoragent.CLIUsageText())
		return nil
	}
	if len(args) == 0 {
		usage(os.Stderr)
		return errors.New("a command is required")
	}
	invocation, err := parseInvocation(args)
	if err != nil {
		return err
	}
	switch invocation.command {
	case "agent":
		return runAgent(invocation.root, invocation.arguments)
	case "setup", "login", "logout", "reset-password", "backend", "cmd", "read", "ota", "backup", "op", "modules", "log", "paths", "silent-patch", "res":
		return runClientCommand(invocation.root, invocation.command, invocation.arguments)
	case "sdk-import":
		return runSDKImport(invocation.root, invocation.arguments)
	default:
		usage(os.Stderr)
		return fmt.Errorf("unknown command %q", invocation.command)
	}
}

// wantsHelp accepts the three spellings the owner asked for, without needing a
// root. The bare "help" word counts only in command position, so a future
// command argument named "help" is not stolen.
func wantsHelp(args []string) bool {
	for index := 0; index < len(args); index++ {
		argument := args[index]
		if argument == "--help" || argument == "-h" {
			return true
		}
		if argument == "--root" {
			index++
			continue
		}
		if strings.HasPrefix(argument, "--root=") {
			continue
		}
		return argument == "help"
	}
	return false
}

type invocation struct {
	root      string
	command   string
	arguments []string
}

// parseInvocation strips --root from anywhere before dispatch, so the
// documented "gxb-operator [--root DIR] agent" shape works.
func parseInvocation(args []string) (invocation, error) {
	root, remaining, err := extractRoot(args)
	if err != nil {
		return invocation{}, err
	}
	if len(remaining) == 0 {
		return invocation{}, errors.New("a command is required")
	}
	return invocation{root: root, command: remaining[0], arguments: remaining[1:]}, nil
}

func usage(writer io.Writer) {
	fmt.Fprint(writer, operatoragent.CLIUsageText())
}

// extractRoot accepts --root before or after the command so the CLI reads like
// the GUI: one root folder, everything else positional.
func extractRoot(args []string) (string, []string, error) {
	root := os.Getenv("GXB_OPERATOR_ROOT")
	remaining := make([]string, 0, len(args))
	for index := 0; index < len(args); index++ {
		argument := args[index]
		if argument == "--root" {
			if index+1 >= len(args) {
				return "", nil, errors.New("--root needs a directory")
			}
			root = args[index+1]
			index++
			continue
		}
		if value, found := strings.CutPrefix(argument, "--root="); found {
			root = value
			continue
		}
		remaining = append(remaining, argument)
	}
	if root == "" {
		return "", nil, errors.New("--root or GXB_OPERATOR_ROOT is required")
	}
	return root, remaining, nil
}
