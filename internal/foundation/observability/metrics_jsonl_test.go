package observability

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestJSONLMetricsConfigRequiresExplicitBound(t *testing.T) {
	env := map[string]string{TxMetricsPathEnv: "/tmp/tx.jsonl"}
	getenv := func(k string) string { return env[k] }
	if _, _, err := JSONLMetricsConfigFromEnv(getenv); err == nil {
		t.Fatal("path without byte bound accepted")
	}
	env[TxMetricsMaxBytesEnv] = "4096"
	cfg, enabled, err := JSONLMetricsConfigFromEnv(getenv)
	if err != nil || !enabled || cfg.MaxBytes != 4096 || cfg.Path != "/tmp/tx.jsonl" {
		t.Fatalf("cfg=%+v enabled=%v err=%v", cfg, enabled, err)
	}
}

func TestJSONLMetricsIs0600BoundedAndContainsNoOperationIdentity(t *testing.T) {
	path := filepath.Join(t.TempDir(), "tx.jsonl")
	sink, err := NewJSONLMetrics(JSONLMetricsConfig{Path: path, MaxBytes: 1024})
	if err != nil {
		t.Fatal(err)
	}
	labels, err := NewLabels(Pair{"profile", "NORMAL_WRITE"}, Pair{"phase", "commit"}, Pair{"outcome", "definite_commit"}, Pair{"sql_class", "none"})
	if err != nil {
		t.Fatal(err)
	}
	for i := 0; i < 100; i++ {
		sink.Observe("gxb_tx_phase_duration", labels, 5*time.Millisecond)
	}
	if err := sink.Close(); err != nil {
		t.Fatal(err)
	}
	info, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if info.Size() > 1024 {
		t.Fatalf("sink exceeded byte bound: %d", info.Size())
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("mode=%o", info.Mode().Perm())
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if len(raw) == 0 || !strings.Contains(string(raw), `"profile":"NORMAL_WRITE"`) {
		t.Fatalf("unexpected capture: %q", raw)
	}
	for _, forbidden := range []string{"operation_id", "receipt", "player_id", "semantic_key"} {
		if strings.Contains(string(raw), forbidden) {
			t.Fatalf("forbidden identity %q leaked: %s", forbidden, raw)
		}
	}
}

func TestTxHooksWriteBoundedMetrics(t *testing.T) {
	path := filepath.Join(t.TempDir(), "tx.jsonl")
	sink, err := NewJSONLMetrics(JSONLMetricsConfig{Path: path, MaxBytes: 4096})
	if err != nil {
		t.Fatal(err)
	}
	TxHooks{Metrics: sink}.OnEvent(tx.Event{Profile: "NORMAL_WRITE", Phase: "reconcile_unknown", Outcome: tx.UnknownCommitOutcome, SQLState: "40001", Duration: time.Millisecond})
	if err := sink.Close(); err != nil {
		t.Fatal(err)
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	text := string(raw)
	if !strings.Contains(text, "gxb_tx_phase_duration") || !strings.Contains(text, "gxb_unknown_commit_total") || !strings.Contains(text, `"sql_class":"serialization"`) {
		t.Fatalf("missing tx metrics: %s", text)
	}
}
