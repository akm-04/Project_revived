package realtimewakeup

import "testing"

func TestDuplicateEnvelopeFieldsRejected(t *testing.T) {
	for _, s := range []string{`{"v":1,"v":1,"route":"social.reload.v1","ref":"x"}`, `{"v":1,"route":"old","route":"social.reload.v1","ref":"x"}`, `{"v":1,"route":"social.reload.v1","ref":"x","ref":"y"}`} {
		if _, e := Decode([]byte(s)); e == nil {
			t.Fatal(s)
		}
	}
}
