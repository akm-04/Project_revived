package main

import (
	"io"
	"os"
	"strings"
	"testing"
)

func TestHelpSpellingsPrintUsageToStdoutAndSucceed(t *testing.T) {
	for _, arguments := range [][]string{{"help"}, {"--help"}, {"-h"}} {
		t.Run(strings.Join(arguments, " "), func(t *testing.T) {
			file, err := os.CreateTemp(t.TempDir(), "stdout")
			if err != nil {
				t.Fatal(err)
			}
			original := os.Stdout
			os.Stdout = file
			runErr := run(arguments)
			os.Stdout = original
			if runErr != nil {
				t.Fatalf("run(%v) = %v", arguments, runErr)
			}
			if _, err := file.Seek(0, io.SeekStart); err != nil {
				t.Fatal(err)
			}
			output, err := io.ReadAll(file)
			if err != nil {
				t.Fatal(err)
			}
			if !strings.HasPrefix(string(output), "usage:\n") || !strings.Contains(string(output), "gxb-operator setup") {
				t.Fatalf("stdout = %q", output)
			}
		})
	}
}

func TestExtractRootFallsBackToTheEnvironment(t *testing.T) {
	t.Setenv("GXB_OPERATOR_ROOT", "/tmp/from-environment")
	root, remaining, err := extractRoot([]string{"read", "dashboard.summary"})
	if err != nil {
		t.Fatal(err)
	}
	if root != "/tmp/from-environment" || len(remaining) != 2 {
		t.Fatalf("root = %q remaining = %v", root, remaining)
	}
	root, _, err = extractRoot([]string{"--root", "/tmp/explicit", "agent"})
	if err != nil {
		t.Fatal(err)
	}
	if root != "/tmp/explicit" {
		t.Fatalf("--root did not win over the environment: %q", root)
	}
}

func TestParseInvocationStripsRootBeforeDispatch(t *testing.T) {
	t.Setenv("GXB_OPERATOR_ROOT", "")
	cases := []struct {
		name      string
		args      []string
		root      string
		command   string
		arguments []string
	}{
		{name: "root before the command", args: []string{"--root", "/tmp/op", "agent"}, root: "/tmp/op", command: "agent"},
		{name: "root after the command", args: []string{"agent", "--root", "/tmp/op"}, root: "/tmp/op", command: "agent"},
		{name: "root equals after the command", args: []string{"cmd", "ota.publish", "--root=/tmp/op"}, root: "/tmp/op", command: "cmd", arguments: []string{"ota.publish"}},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			invocation, err := parseInvocation(testCase.args)
			if err != nil {
				t.Fatal(err)
			}
			if invocation.root != testCase.root || invocation.command != testCase.command {
				t.Fatalf("got root %q command %q", invocation.root, invocation.command)
			}
			if len(invocation.arguments) != len(testCase.arguments) {
				t.Fatalf("arguments = %v, want %v", invocation.arguments, testCase.arguments)
			}
			for index := range invocation.arguments {
				if invocation.arguments[index] != testCase.arguments[index] {
					t.Fatalf("arguments = %v, want %v", invocation.arguments, testCase.arguments)
				}
			}
		})
	}
}

func TestParseInvocationNeedsCommandAndRoot(t *testing.T) {
	t.Setenv("GXB_OPERATOR_ROOT", "")
	if _, err := parseInvocation([]string{"--root", "/tmp/op"}); err == nil {
		t.Fatal("a missing command was accepted")
	}
	if _, err := parseInvocation([]string{"agent"}); err == nil {
		t.Fatal("a missing root was accepted")
	}
}
