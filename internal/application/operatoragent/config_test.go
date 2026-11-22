package operatoragent

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func writeAgentConfig(t *testing.T, contents string) string {
	t.Helper()
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
	return root
}

func TestLoadConfigRefusesUnknownField(t *testing.T) {
	root := writeAgentConfig(t, `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"},"surprise":1}`)
	_, err := LoadConfig(root)
	if err == nil || !strings.Contains(err.Error(), "unknown field") {
		t.Fatalf("want an unknown-field error, got %v", err)
	}
}

func TestLoadConfigRefusesNonLoopback(t *testing.T) {
	cases := map[string]string{
		"public listen":        `{"listen":"0.0.0.0:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`,
		"public operator addr": `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"10.0.0.5:8091"}}`,
	}
	for name, contents := range cases {
		t.Run(name, func(t *testing.T) {
			root := writeAgentConfig(t, contents)
			if _, err := LoadConfig(root); err == nil {
				t.Fatal("want a refusal for a non-loopback address")
			}
		})
	}
}

func TestLoadConfigAcceptsLoopback(t *testing.T) {
	root := writeAgentConfig(t, `{"listen":"127.0.0.1:8090","ota_root":"/srv/ota","backend":{"binary":"/bin/x","env_file":"/srv/env","operator_addr":"[::1]:8091"}}`)
	config, err := LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.OTARoot != "/srv/ota" || config.Backend.OperatorAddr != "[::1]:8091" {
		t.Fatalf("config = %+v", config)
	}
}

func TestLoadConfigErrorCarriesNoValue(t *testing.T) {
	root := writeAgentConfig(t, `{"listen":5,"ota_root":"postgres://alice:hunter2@db/x","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`)
	_, err := LoadConfig(root)
	if err == nil {
		t.Fatal("want a decode error")
	}
	for _, secret := range []string{"alice", "hunter2", "db/x"} {
		if strings.Contains(err.Error(), secret) {
			t.Fatalf("error text leaked %q: %v", secret, err)
		}
	}
}

func TestReadEnvFile(t *testing.T) {
	path := filepath.Join(t.TempDir(), "backend.env")
	contents := "# comment\n\nGXB_POSTGRES_DSN=postgres://user:pass@host/db?sslmode=disable\nGXB_PLAIN=a=b=c\n# trailing comment\n"
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
	entries, err := ReadEnvFile(path)
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"GXB_POSTGRES_DSN=postgres://user:pass@host/db?sslmode=disable", "GXB_PLAIN=a=b=c"}
	if len(entries) != len(want) {
		t.Fatalf("entries = %v", entries)
	}
	for index, entry := range want {
		if entries[index] != entry {
			t.Fatalf("entry %d = %q, want %q", index, entries[index], entry)
		}
	}
}

func TestEnvFileErrorAndLogCarryNoValue(t *testing.T) {
	directory := t.TempDir()
	path := filepath.Join(directory, "backend.env")
	contents := "GXB_POSTGRES_DSN=postgres://alice:hunter2@db/x\nnot-a-pair\n"
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
	_, err := ReadEnvFile(path)
	if err == nil {
		t.Fatal("want a parse error")
	}
	for _, secret := range []string{"alice", "hunter2", "postgres://"} {
		if strings.Contains(err.Error(), secret) {
			t.Fatalf("error text leaked %q: %v", secret, err)
		}
	}

	good := filepath.Join(directory, "good.env")
	if err := os.WriteFile(good, []byte("GXB_POSTGRES_DSN=postgres://alice:hunter2@db/x\nGXB_API_PASSWORD=swordfish\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	entries, err := ReadEnvFile(good)
	if err != nil {
		t.Fatal(err)
	}
	detail := map[string]any{}
	for _, entry := range entries {
		key, value, _ := strings.Cut(entry, "=")
		detail[key] = value
	}
	var buffer bytes.Buffer
	NewToolLog(&buffer, func() time.Time { return time.Unix(0, 0) }).Write("backend.start", "env", "ok", detail)
	line := buffer.String()
	for _, secret := range []string{"alice", "hunter2", "swordfish"} {
		if strings.Contains(line, secret) {
			t.Fatalf("tool log leaked %q: %s", secret, line)
		}
	}
	var parsed map[string]any
	if err := json.Unmarshal(bytes.TrimSpace(buffer.Bytes()), &parsed); err != nil {
		t.Fatalf("log line is not JSON: %v", err)
	}
}
