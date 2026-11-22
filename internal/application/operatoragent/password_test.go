package operatoragent

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestChangePasswordRefusesWrongShortAndSame(t *testing.T) {
	credentials := NewCredentials(t.TempDir())
	if err := credentials.Setup("original-password"); err != nil {
		t.Fatal(err)
	}
	if err := credentials.ChangePassword("wrong-password", "replacement-password"); err == nil || refusalCode(t, err) != CodeLoginRefused {
		t.Fatalf("wrong current password: %v", err)
	}
	if err := credentials.ChangePassword("original-password", "short"); err == nil || refusalCode(t, err) != CodePasswordTooShort {
		t.Fatalf("too short: %v", err)
	}
	if err := credentials.ChangePassword("original-password", "original-password"); err == nil || refusalCode(t, err) != CodePasswordSame {
		t.Fatalf("same password: %v", err)
	}
	if err := credentials.Verify("original-password"); err != nil {
		t.Fatalf("a refused change altered the password: %v", err)
	}
}

func TestChangePasswordWritesTheNewHash(t *testing.T) {
	credentials := NewCredentials(t.TempDir())
	if err := credentials.Setup("original-password"); err != nil {
		t.Fatal(err)
	}
	before, err := os.ReadFile(filepath.Join(credentials.Root, PasswordFileName))
	if err != nil {
		t.Fatal(err)
	}
	if err := credentials.ChangePassword("original-password", "replacement-password"); err != nil {
		t.Fatal(err)
	}
	after, err := os.ReadFile(filepath.Join(credentials.Root, PasswordFileName))
	if err != nil {
		t.Fatal(err)
	}
	if string(before) == string(after) {
		t.Fatal("the password file did not change")
	}
	if err := credentials.Verify("original-password"); err == nil {
		t.Fatal("the old password still works")
	}
	if err := credentials.Verify("replacement-password"); err != nil {
		t.Fatalf("the new password was refused: %v", err)
	}
}

func TestChangePasswordEndsEveryLiveSession(t *testing.T) {
	credentials := NewCredentials(t.TempDir())
	if err := credentials.Setup("original-password"); err != nil {
		t.Fatal(err)
	}
	generation, err := credentials.Generation()
	if err != nil {
		t.Fatal(err)
	}
	sessions := NewSessions(func() time.Time { return time.Unix(0, 0) })
	token, _, err := sessions.Login(generation)
	if err != nil {
		t.Fatal(err)
	}
	if !sessions.Authorize(token, generation) {
		t.Fatal("the fresh session was refused")
	}
	if err := credentials.ChangePassword("original-password", "replacement-password"); err != nil {
		t.Fatal(err)
	}
	newGeneration, err := credentials.Generation()
	if err != nil {
		t.Fatal(err)
	}
	if newGeneration == generation {
		t.Fatal("the password generation did not change")
	}
	if sessions.Authorize(token, newGeneration) {
		t.Fatal("a session minted before the change was accepted")
	}
}

func TestOfflineResetEndsLiveSessionsOnTheNextRequest(t *testing.T) {
	credentials := NewCredentials(t.TempDir())
	if err := credentials.Setup("original-password"); err != nil {
		t.Fatal(err)
	}
	generation, err := credentials.Generation()
	if err != nil {
		t.Fatal(err)
	}
	sessions := NewSessions(func() time.Time { return time.Unix(0, 0) })
	token, _, err := sessions.Login(generation)
	if err != nil {
		t.Fatal(err)
	}
	if err := credentials.ResetPassword("offline-reset-password"); err != nil {
		t.Fatal(err)
	}
	newGeneration, err := credentials.Generation()
	if err != nil {
		t.Fatal(err)
	}
	if sessions.Authorize(token, newGeneration) {
		t.Fatal("a live session survived an offline reset")
	}
	if err := credentials.Verify("original-password"); err == nil {
		t.Fatal("the old password still works after the reset")
	}
	if err := credentials.Verify("offline-reset-password"); err != nil {
		t.Fatalf("the reset password was refused: %v", err)
	}
}

func TestResetPasswordNeedsAnExistingPassword(t *testing.T) {
	credentials := NewCredentials(t.TempDir())
	if err := credentials.ResetPassword("offline-reset-password"); err == nil || refusalCode(t, err) != CodeSetupRequired {
		t.Fatalf("reset before setup: %v", err)
	}
	if err := credentials.Setup("original-password"); err != nil {
		t.Fatal(err)
	}
	if err := credentials.ResetPassword("short"); err == nil || refusalCode(t, err) != CodePasswordTooShort {
		t.Fatalf("reset too short: %v", err)
	}
}

func TestSetupRefusesAPasswordBelowTheMinimum(t *testing.T) {
	credentials := NewCredentials(t.TempDir())
	if err := credentials.Setup("short"); err == nil || refusalCode(t, err) != CodePasswordTooShort {
		t.Fatalf("short setup: %v", err)
	}
}
