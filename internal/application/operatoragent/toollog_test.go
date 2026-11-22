package operatoragent

import (
	"bytes"
	"strings"
	"testing"
	"time"
)

func TestToolLogMasksSecretsEverywhere(t *testing.T) {
	var buffer bytes.Buffer
	log := NewToolLog(&buffer, func() time.Time { return time.Unix(0, 0) })
	log.Write("login", "session", "ok", map[string]any{
		"token":        "token-value-1",
		"password":     "password-value-2",
		"passwd":       "passwd-value-3",
		"secret":       "secret-value-4",
		"dsn":          "dsn-value-5",
		"semantic_key": "key-value-6",
		"nested":       map[string]any{"secret": "nested-value-7"},
		"list":         []any{"postgres://alice:hunter2@db/x"},
		"ordinary":     "kept",
	})
	line := buffer.String()
	for _, secret := range []string{"token-value-1", "password-value-2", "passwd-value-3", "secret-value-4", "dsn-value-5", "key-value-6", "nested-value-7", "alice", "hunter2"} {
		if strings.Contains(line, secret) {
			t.Fatalf("log line leaked %q: %s", secret, line)
		}
	}
	if !strings.Contains(line, `"ordinary":"kept"`) {
		t.Fatalf("non-secret detail was lost: %s", line)
	}
	if strings.Count(line, "***") < 7 {
		t.Fatalf("expected masked values: %s", line)
	}
}
