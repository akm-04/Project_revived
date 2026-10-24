package guildbroadcast

import (
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/obligation"
	"testing"
	"time"
)

func TestFiniteReferenceTampering(t *testing.T) {
	id, _ := ids.NewUUID()
	base, e := MailObligation(id, 100001, time.Date(2026, 10, 9, 9, 0, 0, 0, time.UTC))
	if e != nil {
		t.Fatal(e)
	}
	if _, _, e = DecodeMailObligation(base); e != nil {
		t.Fatal(e)
	}
	for _, change := range []func(*obligation.Obligation){func(o *obligation.Obligation) { o.Kind = "unknown" }, func(o *obligation.Obligation) { o.Profile = "unknown" }, func(o *obligation.Obligation) { o.Queue = "other" }, func(o *obligation.Obligation) { o.SemanticKey = "other" }, func(o *obligation.Obligation) {
		o.Args = []byte(`{"source_id":"` + id.String() + `","recipient_id":100001,"title":"forged"}`)
	}, func(o *obligation.Obligation) {
		o.Args = []byte(`{"source_id":"` + id.String() + `","recipient_id":100001,"recipient_id":100002}`)
	}} {
		o := base
		change(&o)
		if _, _, e = DecodeMailObligation(o); e == nil {
			t.Fatal("tampered routing evidence accepted")
		}
	}
}
