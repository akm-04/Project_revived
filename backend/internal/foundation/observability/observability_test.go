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

func TestRedactTextMasksSecretValues(t *testing.T) {
	cases := map[string]string{
		`{"mid":7,"token":"abc123","region":2}`:      `{"mid":7,"token":"[REDACTED]","region":2}`,
		`dial failed: login_token=zz9 sid=s1 code=4`: `dial failed: login_token=[REDACTED] sid=[REDACTED] code=4`,
		`postgres: no rows`:                          `postgres: no rows`,
	}
	for in, want := range cases {
		if got := RedactText(in); got != want {
			t.Errorf("RedactText(%q) = %q, want %q", in, got, want)
		}
	}
}
