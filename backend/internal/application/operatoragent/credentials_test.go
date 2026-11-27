package operatoragent

import (
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func refusalCode(t *testing.T, err error) string {
	t.Helper()
	var refusal *Refusal
	if !errors.As(err, &refusal) {
		t.Fatalf("want a refusal, got %v", err)
	}
	return refusal.Code
}

func TestCredentialsSetupLoginAndExpiry(t *testing.T) {
	credentials := NewCredentials(t.TempDir())
	if err := credentials.Verify("anything"); err == nil || refusalCode(t, err) != CodeSetupRequired {
		t.Fatalf("verify before setup: %v", err)
	}
	if err := credentials.Setup("correct horse"); err != nil {
		t.Fatal(err)
	}
	info, err := os.Stat(filepath.Join(credentials.Root, PasswordFileName))
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("password file mode = %o", info.Mode().Perm())
	}
	if err := credentials.Setup("second"); err == nil || refusalCode(t, err) != CodeAlreadySetUp {
		t.Fatalf("second setup: %v", err)
	}
	if err := credentials.Verify("wrong"); err == nil || refusalCode(t, err) != CodeLoginRefused {
		t.Fatalf("wrong password: %v", err)
	}
	if err := credentials.Verify("correct horse"); err != nil {
		t.Fatalf("right password: %v", err)
	}

	generation, err := credentials.Generation()
	if err != nil {
		t.Fatal(err)
	}
	now := time.Date(2026, 11, 22, 10, 0, 0, 0, time.UTC)
	sessions := NewSessions(func() time.Time { return now })
	token, expiresAt, err := sessions.Login(generation)
	if err != nil || token == "" {
		t.Fatalf("login: %q %v", token, err)
	}
	if !expiresAt.Equal(now.Add(SessionLifetime)) {
		t.Fatalf("expires at %v", expiresAt)
	}
	if !sessions.Authorize(token, generation) {
		t.Fatal("a fresh token must be authorized")
	}
	now = now.Add(SessionLifetime + time.Minute)
	if sessions.Authorize(token, generation) {
		t.Fatal("an expired token must be refused")
	}
}
