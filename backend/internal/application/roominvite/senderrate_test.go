package roominvite

import (
	"gxb.local/backend/v2/internal/domain/identity"
	"testing"
	"time"
)

func TestSenderRateLimiterBurstThenRefill(t *testing.T) {
	limiter := NewSenderRateLimiter(3*time.Second, 3)
	at := time.Unix(1_800_000_000, 0)
	sender := identity.PlayerID(100001)
	for i := 0; i < 3; i++ {
		if !limiter.Allow(sender, at) {
			t.Fatalf("burst invite %d refused", i+1)
		}
	}
	if limiter.Allow(sender, at) {
		t.Fatal("fourth invite inside the same instant admitted")
	}
	if limiter.Allow(sender, at.Add(time.Second)) {
		t.Fatal("invite admitted before one refill interval elapsed")
	}
	if !limiter.Allow(sender, at.Add(3*time.Second)) {
		t.Fatal("refilled token refused")
	}
	if !limiter.Allow(identity.PlayerID(100002), at) {
		t.Fatal("a second sender inherited the first sender's bucket")
	}
}

func TestSenderRateLimiterBoundsTrackedSenders(t *testing.T) {
	limiter := NewSenderRateLimiter(time.Second, 1)
	at := time.Unix(1_800_000_000, 0)
	for i := 0; i < maxTrackedSenders+10; i++ {
		limiter.Allow(identity.PlayerID(100001+int64(i)), at)
	}
	if len(limiter.buckets) > maxTrackedSenders {
		t.Fatalf("tracked senders=%d above cap %d", len(limiter.buckets), maxTrackedSenders)
	}
}
