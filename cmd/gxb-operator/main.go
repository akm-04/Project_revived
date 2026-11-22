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
	switch args[0] {
	case "agent":
		return runAgent(args[1:])
	case "setup", "login", "logout", "backend", "cmd", "read", "ota", "op", "log":
		return runClientCommand(args[0], args[1:])
	default:
		usage()
		return fmt.Errorf("unknown command %q", args[0])
	}
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
  gxb-operator ota publish <version> --reason <text> [--key <key>]
  gxb-operator ota withdraw <version> --reason <text> [--key <key>]
  gxb-operator op status <id>
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
