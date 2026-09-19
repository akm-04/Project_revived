package observability

import (
	"testing"
)

func TestRedactionAndMetricCardinality(t *testing.T) {
	got := RedactFields(map[string]any{"player_id": int64(9), "Authorization": "Bearer x", "chat_content": "hi", "domain": "shop"})
	if got["Authorization"] != Redacted || got["chat_content"] != Redacted {
		t.Fatalf("redaction=%v", got)
	}
	if got["player_id"] != int64(9) {
		t.Fatal("nonsecret log correlation removed")
	}
	if _, err := NewLabels(Pair{"player_id", "9"}); err == nil {
		t.Fatal("player metric label accepted")
	}
	if _, err := NewLabels(Pair{"domain", "shop"}, Pair{"outcome", "ok"}); err != nil {
		t.Fatal(err)
	}
}
