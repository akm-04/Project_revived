package agentapi

import (
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

// TestAgentRoutesAllUseAcquire is the PROVENANCE_AND_COVERAGE_V1 law C
// completeness check for the HTTP surface: no route may bypass the recovery
// refusal with a raw TryLock.
func TestAgentRoutesAllUseAcquire(t *testing.T) {
	files, err := filepath.Glob("*.go")
	if err != nil {
		t.Fatal(err)
	}
	for _, name := range files {
		if strings.HasSuffix(name, "_test.go") {
			continue
		}
		contents, readErr := os.ReadFile(name)
		if readErr != nil {
			t.Fatal(readErr)
		}
		if strings.Contains(string(contents), "Guard.TryLock()") {
			t.Fatalf("%s bypasses the recovery refusal with a raw TryLock", name)
		}
	}
}

func newRecoveryHandler(t *testing.T) (Handler, string, *operatoragent.BackendGuard) {
	t.Helper()
	credentials := operatoragent.NewCredentials(t.TempDir())
	if err := credentials.Setup("test password"); err != nil {
		t.Fatal(err)
	}
	sessions := operatoragent.NewSessions(time.Now)
	generation, err := credentials.Generation()
	if err != nil {
		t.Fatal(err)
	}
	session, _, err := sessions.Login(generation)
	if err != nil {
		t.Fatal(err)
	}
	guard := &operatoragent.BackendGuard{}
	guard.RequireRecovery()
	backup := &operatoragent.BackupService{Directory: t.TempDir(), Guard: guard, Now: time.Now}
	handler := Handler{
		Credentials: credentials,
		Sessions:    sessions,
		Backend:     newBlockingBackend(),
		Tokens:      &operatoragent.TokenHolder{},
		Backup:      backup,
		Listen:      testListen,
		Guard:       guard,
	}
	return handler, session, guard
}

func TestBackendRoutesRefuseWhileRestoreRecoveryIsPending(t *testing.T) {
	handler, session, _ := newRecoveryHandler(t)
	for name, route := range map[string]struct{ method, path, body string }{
		"start":   {http.MethodPost, "/agent/v1/backend/start", `{}`},
		"stop":    {http.MethodPost, "/agent/v1/backend/stop", ""},
		"restart": {http.MethodPost, "/agent/v1/backend/restart", `{}`},
	} {
		recorder := serveAgent(handler, route.method, route.path, session, route.body)
		if recorder.Code != http.StatusConflict || refusalCodeOf(t, recorder) != operatoragent.CodeBackupRecoveryRequired {
			t.Fatalf("%s during a pending recovery: %d %s", name, recorder.Code, recorder.Body)
		}
	}
	status := serveAgent(handler, http.MethodGet, "/agent/v1/backend/status", session, "")
	if status.Code != http.StatusOK {
		t.Fatalf("a read during a pending recovery: %d %s", status.Code, status.Body)
	}
}

func TestBackupRecoverRouteLiftsTheRecoveryRefusal(t *testing.T) {
	handler, session, guard := newRecoveryHandler(t)
	prune := serveAgent(handler, http.MethodPost, "/agent/v1/backup/prune", session, `{"reason":"maintenance"}`)
	if prune.Code != http.StatusConflict || refusalCodeOf(t, prune) != operatoragent.CodeBackupRecoveryRequired {
		t.Fatalf("prune during a pending recovery: %d %s", prune.Code, prune.Body)
	}
	recovered := serveAgent(handler, http.MethodPost, "/agent/v1/backup/recover", session, "")
	if recovered.Code != http.StatusOK {
		t.Fatalf("recover: %d %s", recovered.Code, recovered.Body)
	}
	if err := guard.Acquire(); err != nil {
		t.Fatalf("admission after recover: %v", err)
	}
	guard.Unlock()
}
