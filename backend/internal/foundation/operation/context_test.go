package operation

import (
	"bytes"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/policy"
	"testing"
	"time"
)

func TestContextStableEntropyAndPolicyAcrossAttempts(t *testing.T) {
	p, _ := policy.NewSet(policy.Ref{Name: "gacha", Version: "v7"})
	f := Factory{Clock: clock.Fixed{T: time.Date(2026, 9, 6, 3, 0, 0, 0, time.FixedZone("x", 8*3600))}, Random: bytes.NewReader(make([]byte, 128))}
	c, err := f.New(p)
	if err != nil {
		t.Fatal(err)
	}
	if c.StartedAt.Location() != time.UTC {
		t.Fatal("not UTC")
	}
	a, b := c.Derive("draw", 9), c.Derive("draw", 9)
	if a != b {
		t.Fatal("entropy changed")
	}
	if a == c.Derive("draw", 10) {
		t.Fatal("ordinal not separated")
	}
	if v, ok := c.Policies.Get("gacha"); !ok || v != "v7" {
		t.Fatal("policy missing")
	}
}
