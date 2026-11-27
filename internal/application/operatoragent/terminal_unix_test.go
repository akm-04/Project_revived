//go:build linux

package operatoragent

import (
	"bytes"
	"errors"
	"strings"
	"testing"
	"time"

	"golang.org/x/sys/unix"
)

func newCatTerminalService(t *testing.T, idle time.Duration) (*TerminalService, *bytes.Buffer) {
	t.Helper()
	output := &bytes.Buffer{}
	service := NewTerminalService(NewToolLog(output, time.Now), time.Now)
	service.ShellPath = "/bin/cat"
	service.Environment = []string{"PATH=/usr/bin:/bin", "TERM=xterm-256color"}
	service.IdleTimeout = idle
	t.Cleanup(service.Shutdown)
	return service, output
}

func waitFor(t *testing.T, timeout time.Duration, condition func() bool) bool {
	t.Helper()
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if condition() {
			return true
		}
		time.Sleep(10 * time.Millisecond)
	}
	return condition()
}

func TestTerminalOpenRefusesNonLoopbackListen(t *testing.T) {
	service, _ := newCatTerminalService(t, 0)
	for _, address := range []string{"0.0.0.0:8090", "192.168.1.10:8090", "not-an-address"} {
		_, err := service.Open("session", address)
		var refusal *Refusal
		if !errors.As(err, &refusal) || refusal.Code != CodeTerminalDisabled {
			t.Fatalf("%s: err = %v", address, err)
		}
	}
	if service.ActiveCount() != 0 {
		t.Fatalf("terminals = %d", service.ActiveCount())
	}
}

func TestTerminalEchoRoundTripWithCat(t *testing.T) {
	service, _ := newCatTerminalService(t, 0)
	opened, err := service.Open("session", "127.0.0.1:8090")
	if err != nil {
		t.Fatal(err)
	}
	attachment, err := service.Attach("session", opened.TerminalID)
	if err != nil {
		t.Fatal(err)
	}
	defer attachment.Release()
	if err := service.WriteInput("session", opened.TerminalID, []byte("hello\n")); err != nil {
		t.Fatal(err)
	}
	var received strings.Builder
	deadline := time.After(5 * time.Second)
	for !strings.Contains(received.String(), "hello") {
		select {
		case chunk := <-attachment.Chunks:
			received.Write(chunk)
		case <-deadline:
			t.Fatalf("the terminal echoed %q", received.String())
		}
	}
	if err := service.Resize("session", opened.TerminalID, 100, 40); err != nil {
		t.Fatal(err)
	}
	if err := service.Close("session", opened.TerminalID); err != nil {
		t.Fatal(err)
	}
	if service.ActiveCount() != 0 {
		t.Fatalf("terminals after close = %d", service.ActiveCount())
	}
}

func TestTerminalIdleTimeoutKillsTheProcess(t *testing.T) {
	service, _ := newCatTerminalService(t, 50*time.Millisecond)
	opened, err := service.Open("session", "127.0.0.1:8090")
	if err != nil {
		t.Fatal(err)
	}
	if !waitFor(t, 5*time.Second, func() bool { return service.ActiveCount() == 0 }) {
		t.Fatal("the idle terminal was not closed")
	}
	if !waitFor(t, 5*time.Second, func() bool { return errors.Is(unix.Kill(opened.PID, 0), unix.ESRCH) }) {
		t.Fatalf("the idle shell pid %d is still alive", opened.PID)
	}
}

func TestTerminalCloseIsIdempotent(t *testing.T) {
	service, _ := newCatTerminalService(t, 0)
	opened, err := service.Open("session", "127.0.0.1:8090")
	if err != nil {
		t.Fatal(err)
	}
	for attempt := 0; attempt < 2; attempt++ {
		if err := service.Close("session", opened.TerminalID); err != nil {
			t.Fatalf("close %d: %v", attempt, err)
		}
	}
	if err := service.Close("session", "0000000000000000000000000000000000000000000000000000000000000000"); err != nil {
		t.Fatalf("unknown close: %v", err)
	}
}

func TestTerminalCloseSessionEndsOnlyItsOwnersTerminal(t *testing.T) {
	service, output := newCatTerminalService(t, 0)
	first, err := service.Open("session-a", "127.0.0.1:8090")
	if err != nil {
		t.Fatal(err)
	}
	second, err := service.Open("session-b", "127.0.0.1:8090")
	if err != nil {
		t.Fatal(err)
	}
	service.CloseSession("session-a", "logout")
	if _, err := service.Attach("session-a", first.TerminalID); err == nil {
		t.Fatal("the logged-out session's terminal survived")
	}
	if err := service.WriteInput("session-b", second.TerminalID, []byte("still here\n")); err != nil {
		t.Fatalf("another session's terminal was closed: %v", err)
	}
	if service.ActiveCount() != 1 {
		t.Fatalf("terminals = %d", service.ActiveCount())
	}
	if !strings.Contains(output.String(), `"reason":"logout"`) {
		t.Fatalf("the close reason was not logged: %s", output.String())
	}
}

func TestTerminalCloseAllEndsEveryTerminal(t *testing.T) {
	service, _ := newCatTerminalService(t, 0)
	for _, token := range []string{"session-a", "session-b"} {
		if _, err := service.Open(token, "127.0.0.1:8090"); err != nil {
			t.Fatal(err)
		}
	}
	service.CloseAll("password changed")
	if service.ActiveCount() != 0 {
		t.Fatalf("terminals = %d", service.ActiveCount())
	}
}

func TestTerminalIsOnePerSessionAndAtMostThree(t *testing.T) {
	service, _ := newCatTerminalService(t, 0)
	first, err := service.Open("session-a", "127.0.0.1:8090")
	if err != nil {
		t.Fatal(err)
	}
	_, err = service.Open("session-a", "127.0.0.1:8090")
	var refusal *Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodeTerminalExists {
		t.Fatalf("second open on one session: %v", err)
	}
	for _, token := range []string{"session-b", "session-c"} {
		if _, err := service.Open(token, "127.0.0.1:8090"); err != nil {
			t.Fatal(err)
		}
	}
	_, err = service.Open("session-d", "127.0.0.1:8090")
	if !errors.As(err, &refusal) || refusal.Code != CodeTerminalLimit {
		t.Fatalf("fourth open: %v", err)
	}
	if err := service.Close("session-a", first.TerminalID); err != nil {
		t.Fatal(err)
	}
}

func TestTerminalEnvironmentRemovesSecrets(t *testing.T) {
	environment := TerminalEnvironment([]string{
		"PATH=/usr/bin",
		"HOME=/home/operator",
		"TERM=old",
		"PGPASSWORD=secret",
		"GXB_DATABASE_DSN=postgres://user:pass@host/db",
		"API_KEY=secret",
		"AWS_ACCESS_KEY_ID=secret",
		"SAFE_VAR=kept",
	})
	joined := strings.Join(environment, "\n")
	for _, forbidden := range []string{"PGPASSWORD", "GXB_DATABASE_DSN", "API_KEY", "AWS_ACCESS_KEY_ID", "TERM=old"} {
		if strings.Contains(joined, forbidden) {
			t.Fatalf("the environment kept %s:\n%s", forbidden, joined)
		}
	}
	for _, required := range []string{"PATH=/usr/bin", "HOME=/home/operator", "SAFE_VAR=kept", "TERM=xterm-256color"} {
		if !strings.Contains(joined, required) {
			t.Fatalf("the environment lost %s:\n%s", required, joined)
		}
	}
}
