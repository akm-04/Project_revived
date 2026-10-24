package characterpractice

import (
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

func TestRootValidateRejectsEveryPartialDailyProvenanceTuple(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	base := Root{PlayerID: identity.PlayerID(7), StateVersion: 1, CreatedAt: now, UpdatedAt: now}
	epoch := now
	vip := int64(0)
	parts := []func(*Root){
		func(r *Root) { r.DailyEpochStartAt = &epoch },
		func(r *Root) { r.DailyEpochPolicyVersion = DailyEpochPolicyV1 },
		func(r *Root) { r.BlessVIPLevelAtEpoch = &vip },
		func(r *Root) { r.BlessPrivilegeProviderRevision = "vip-test/v1" },
		func(r *Root) { r.BlessContentRevision = strings.Repeat("a", 64) },
	}
	for i, set := range parts {
		r := base
		set(&r)
		if err := r.Validate(); err == nil {
			t.Fatalf("partial provenance component %d unexpectedly valid: %#v", i, r)
		}
	}

	complete := base
	for _, set := range parts {
		set(&complete)
	}
	if err := complete.Validate(); err != nil {
		t.Fatalf("complete provenance rejected: %v", err)
	}
}
