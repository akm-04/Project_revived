package main

import (
	"os"
	"strings"
	"testing"
)

// TestLaunchersExecTheInstalledOperator keeps the thin gxb-ops launchers honest:
// they pass every argument through and name the operator root, and they never
// rebuild or replace gxb-operator.
func TestLaunchersExecTheInstalledOperator(t *testing.T) {
	shell, err := os.ReadFile("gxb-ops")
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"exec", "gxb-operator", `"$@"`, "GXB_OPERATOR_ROOT"} {
		if !strings.Contains(string(shell), want) {
			t.Fatalf("gxb-ops lacks %q:\n%s", want, shell)
		}
	}
	command, err := os.ReadFile("gxb-ops.cmd")
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"gxb-operator.exe", "%*", "GXB_OPERATOR_ROOT"} {
		if !strings.Contains(string(command), want) {
			t.Fatalf("gxb-ops.cmd lacks %q:\n%s", want, command)
		}
	}
}
