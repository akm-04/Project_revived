package guildbroadcast

import (
	"gxb.local/backend/v2/internal/foundation/ids"
	"testing"
	"time"
)

func TestStoredJsonbReferenceNormalizationRemainsFinite(t *testing.T) {
	id, _ := ids.NewUUID()
	o, e := MailObligation(id, 100001, time.Now().UTC())
	if e != nil {
		t.Fatal(e)
	}
	canonical := append([]byte(nil), o.Args...)
	o.Args = []byte(`{"recipient_id": 100001, "source_id": "` + id.String() + `"}`)
	if ValidateObligation(o) == nil {
		t.Fatal("raw producer canonical check weakened")
	}
	got, e := NormalizeStoredObligation(o)
	if e != nil || string(got.Args) != string(canonical) {
		t.Fatal(got, e)
	}
	for _, raw := range []string{
		`{"recipient_id":100001,"recipient_id":100002,"source_id":"` + id.String() + `"}`,
		`{"recipient_id":100001,"source_id":"` + id.String() + `","title":"forged"}`,
		`{"recipient_id":"100001","source_id":"` + id.String() + `"}`,
		`{"recipient_id":100002,"source_id":"` + id.String() + `"}`,
	} {
		bad := o
		bad.Args = []byte(raw)
		if _, e := NormalizeStoredObligation(bad); e == nil {
			t.Fatal("stored reference tampering accepted", raw)
		}
	}
	bad := o
	bad.Queue = "other"
	if _, e := NormalizeStoredObligation(bad); e == nil {
		t.Fatal("queue tampering accepted")
	}
	bad = o
	bad.Profile = "other"
	if _, e := NormalizeStoredObligation(bad); e == nil {
		t.Fatal("profile tampering accepted")
	}
}
