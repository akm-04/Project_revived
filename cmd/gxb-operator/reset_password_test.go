package main

import (
	"bufio"
	"errors"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

func feedStdin(t *testing.T, text string) {
	t.Helper()
	previous := stdinReader
	stdinReader = bufio.NewReader(strings.NewReader(text))
	t.Cleanup(func() { stdinReader = previous })
}

func TestRunResetPasswordWritesTheRootFileDirectly(t *testing.T) {
	root := t.TempDir()
	credentials := operatoragent.NewCredentials(root)
	if err := credentials.Setup("original-password"); err != nil {
		t.Fatal(err)
	}
	feedStdin(t, "replacement-password\nreplacement-password\n")
	if err := runResetPassword(root); err != nil {
		t.Fatal(err)
	}
	if err := credentials.Verify("replacement-password"); err != nil {
		t.Fatalf("the reset password was refused: %v", err)
	}
	if err := credentials.Verify("original-password"); err == nil {
		t.Fatal("the old password still works")
	}
}

func TestRunResetPasswordRefusesMismatchAndKeepsThePassword(t *testing.T) {
	root := t.TempDir()
	credentials := operatoragent.NewCredentials(root)
	if err := credentials.Setup("original-password"); err != nil {
		t.Fatal(err)
	}
	feedStdin(t, "replacement-password\nother-password\n")
	err := runResetPassword(root)
	if err == nil || !strings.Contains(err.Error(), "do not match") {
		t.Fatalf("mismatch: %v", err)
	}
	if err := credentials.Verify("original-password"); err != nil {
		t.Fatalf("a refused reset altered the password: %v", err)
	}
}

func TestRunResetPasswordRefusesAShortPassword(t *testing.T) {
	root := t.TempDir()
	credentials := operatoragent.NewCredentials(root)
	if err := credentials.Setup("original-password"); err != nil {
		t.Fatal(err)
	}
	feedStdin(t, "short\nshort\n")
	err := runResetPassword(root)
	var refusal *operatoragent.Refusal
	if !errors.As(err, &refusal) || refusal.Code != operatoragent.CodePasswordTooShort {
		t.Fatalf("short reset: %v", err)
	}
}

func TestRunResetPasswordNeedsAnExistingPassword(t *testing.T) {
	feedStdin(t, "replacement-password\nreplacement-password\n")
	err := runResetPassword(t.TempDir())
	var refusal *operatoragent.Refusal
	if !errors.As(err, &refusal) || refusal.Code != operatoragent.CodeSetupRequired {
		t.Fatalf("reset before setup: %v", err)
	}
}
