package retentionstore

import (
	"testing"
	"time"
)

func clearPolicyEnvironment(t *testing.T) {
	t.Helper()
	for _, name := range []string{
		RetentionDaysEnvironment,
		CacheRetentionDaysEnvironment,
		RetentionRunBudgetEnvironment,
		ProfileMediaHistoryDaysEnvironment,
	} {
		t.Setenv(name, "")
	}
}

func TestRetentionDaysPolicy(t *testing.T) {
	clearPolicyEnvironment(t)
	got, err := PoliciesFromEnvironment()
	if err != nil {
		t.Fatalf("default: %v", err)
	}
	if got.RetentionDays != DefaultRetentionDays {
		t.Fatalf("default retention days=%d want %d", got.RetentionDays, DefaultRetentionDays)
	}

	clearPolicyEnvironment(t)
	t.Setenv(RetentionDaysEnvironment, "10")
	got, err = PoliciesFromEnvironment()
	if err != nil {
		t.Fatalf("tunable: %v", err)
	}
	if got.RetentionDays != 10 {
		t.Fatalf("tunable retention days=%d want 10", got.RetentionDays)
	}

	for _, raw := range []string{"0", "16", "not-a-day"} {
		clearPolicyEnvironment(t)
		t.Setenv(RetentionDaysEnvironment, raw)
		if _, err = PoliciesFromEnvironment(); err == nil {
			t.Fatalf("%s=%q was accepted", RetentionDaysEnvironment, raw)
		}
	}
}

func TestCacheRetentionDaysPolicy(t *testing.T) {
	clearPolicyEnvironment(t)
	got, err := PoliciesFromEnvironment()
	if err != nil {
		t.Fatalf("default: %v", err)
	}
	if got.CacheRetentionDays != DefaultCacheRetentionDays {
		t.Fatalf("default cache days=%d want %d", got.CacheRetentionDays, DefaultCacheRetentionDays)
	}

	clearPolicyEnvironment(t)
	t.Setenv(CacheRetentionDaysEnvironment, "7")
	got, err = PoliciesFromEnvironment()
	if err != nil {
		t.Fatalf("tunable: %v", err)
	}
	if got.CacheRetentionDays != 7 {
		t.Fatalf("tunable cache days=%d want 7", got.CacheRetentionDays)
	}

	for _, raw := range []string{"0", "16"} {
		clearPolicyEnvironment(t)
		t.Setenv(CacheRetentionDaysEnvironment, raw)
		if _, err = PoliciesFromEnvironment(); err == nil {
			t.Fatalf("%s=%q was accepted", CacheRetentionDaysEnvironment, raw)
		}
	}
}

func TestRetentionRunBudgetPolicy(t *testing.T) {
	clearPolicyEnvironment(t)
	got, err := PoliciesFromEnvironment()
	if err != nil {
		t.Fatalf("default: %v", err)
	}
	if got.RunBudget != DefaultRetentionRunBudget {
		t.Fatalf("default budget=%s want %s", got.RunBudget, DefaultRetentionRunBudget)
	}

	clearPolicyEnvironment(t)
	t.Setenv(RetentionRunBudgetEnvironment, "45s")
	got, err = PoliciesFromEnvironment()
	if err != nil {
		t.Fatalf("tunable: %v", err)
	}
	if got.RunBudget != 45*time.Second {
		t.Fatalf("tunable budget=%s want 45s", got.RunBudget)
	}

	for _, raw := range []string{"500ms", "6m", "soon"} {
		clearPolicyEnvironment(t)
		t.Setenv(RetentionRunBudgetEnvironment, raw)
		if _, err = PoliciesFromEnvironment(); err == nil {
			t.Fatalf("%s=%q was accepted", RetentionRunBudgetEnvironment, raw)
		}
	}
}

func TestProfileMediaHistoryRetentionPolicy(t *testing.T) {
	clearPolicyEnvironment(t)
	got, err := PoliciesFromEnvironment()
	if err != nil {
		t.Fatalf("default: %v", err)
	}
	if got.ProfileMediaHistoryDays != DefaultProfileMediaHistoryDays {
		t.Fatalf("default media days=%d want %d", got.ProfileMediaHistoryDays, DefaultProfileMediaHistoryDays)
	}

	clearPolicyEnvironment(t)
	t.Setenv(ProfileMediaHistoryDaysEnvironment, "10")
	got, err = PoliciesFromEnvironment()
	if err != nil {
		t.Fatalf("tunable: %v", err)
	}
	if got.ProfileMediaHistoryDays != 10 {
		t.Fatalf("tunable media days=%d want 10", got.ProfileMediaHistoryDays)
	}

	for _, raw := range []string{"0", "16"} {
		clearPolicyEnvironment(t)
		t.Setenv(ProfileMediaHistoryDaysEnvironment, raw)
		if _, err = PoliciesFromEnvironment(); err == nil {
			t.Fatalf("%s=%q was accepted", ProfileMediaHistoryDaysEnvironment, raw)
		}
	}
}
