package config

import (
	"strings"
	"testing"
)

func TestSecretRedacted(t *testing.T) {
	c := Config{Environment: "test", PostgresDSN: Secret("postgres://user:supersecret@db/gxb")}
	s := c.String()
	if strings.Contains(s, "supersecret") || strings.Contains(s, "postgres://") {
		t.Fatalf("secret leaked: %q", s)
	}
	if !strings.Contains(s, "[REDACTED]") {
		t.Fatalf("redaction marker absent: %q", s)
	}
}
