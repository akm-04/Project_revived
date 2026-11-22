package main

import (
	"errors"
	"fmt"
	"os"
	"strings"
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "gxb-operator: "+err.Error())
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) == 0 {
		usage()
		return errors.New("a command is required")
	}
	invocation, err := parseInvocation(args)
	if err != nil {
		return err
	}
	switch invocation.command {
	case "agent":
		return runAgent(invocation.root, invocation.arguments)
	case "setup", "login", "logout", "backend", "cmd", "read", "ota", "backup", "op", "modules", "log":
		return runClientCommand(invocation.root, invocation.command, invocation.arguments)
	default:
		usage()
		return fmt.Errorf("unknown command %q", invocation.command)
	}
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

func usage() {
	fmt.Fprint(os.Stderr, `usage:
  gxb-operator [--root DIR] agent
  gxb-operator setup
  gxb-operator login
  gxb-operator logout
  gxb-operator backend start [--closed] | stop | status
  gxb-operator cmd <module.command> --reason <text> [--key <key>] [json payload]
  gxb-operator read <module.read> [k=v ...]
  gxb-operator ota build --lane <code|assets|catalog> --version <v> [--rollback] [--no-wait]
  gxb-operator ota publish <version> --reason <text> [--key <key>]
  gxb-operator ota withdraw <version> --reason <text> [--key <key>]
  gxb-operator backup snapshot [--kind manual|safety|pre-update|pre-delete] --reason <text>
  gxb-operator backup list
  gxb-operator backup prune --reason <text>
  gxb-operator backup restore <id> --reason <text>
  gxb-operator backup update-backend --reason <text>
  gxb-operator op status <id>
  gxb-operator modules [--json]
  gxb-operator log tail [-n N]
`)
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
