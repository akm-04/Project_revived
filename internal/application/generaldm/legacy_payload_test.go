package generaldm

import (
	"bytes"
	_ "embed"
	"encoding/json"
	"testing"
)

// Produced by the unchanged63c3d3a/F2 serializer; provenance retained in6C checkpoint.
//
//go:embed testdata/legacy_intent.json
var legacyIntent []byte

func Test6CLegacyPayloadDigestAndFutureSnapshot(t *testing.T) {
	var i Intent
	if e := json.Unmarshal(legacyIntent, &i); e != nil {
		t.Fatal(e)
	}
	if e := i.Validate(); e != nil {
		t.Fatal(e)
	}
	out, e := json.Marshal(i)
	if e != nil || !bytes.Equal(out, legacyIntent) {
		t.Fatalf("legacy payload hash changed: %s %v", out, e)
	}
	i.SenderTitleInfo = "1001@0@0"
	i.SenderBubbleInfo = "10002@1700000010"
	if e = i.Validate(); e != nil {
		t.Fatal(e)
	}
	out, e = json.Marshal(i)
	if e != nil || !bytes.Contains(out, []byte(`"SenderTitleInfo":"1001@0@0"`)) {
		t.Fatal(string(out), e)
	}
	var reload Intent
	if e = json.Unmarshal(out, &reload); e != nil || reload.SenderTitleInfo != i.SenderTitleInfo || reload.SenderBubbleInfo != i.SenderBubbleInfo {
		t.Fatal(reload, e)
	}
	for _, bad := range []string{"1001@0@-1", "1001@0", "1001@0@0@extra", "1@0@9007199254740992"} {
		reload.SenderTitleInfo = bad
		if reload.Validate() == nil {
			t.Fatal("accepted malformed sender snapshot", bad)
		}
	}
}
