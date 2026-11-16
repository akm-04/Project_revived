package retentionstore

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

// PRIVATE_POLICY identifiers. Each has a registered document under docs/i9 and
// is refused at startup when its value falls outside the lead's range.
const (
	RetentionDaysPolicyID                = "R8_PRIVATE_RETENTION_DAYS_V1"
	CacheRetentionDaysPolicyID           = "R8_PRIVATE_CACHE_RETENTION_DAYS_V1"
	RetentionRunBudgetPolicyID           = "R8_PRIVATE_RETENTION_RUN_BUDGET_V1"
	ProfileMediaHistoryRetentionPolicyID = "PROFILE_MEDIA_HISTORY_RETENTION_V1"
	DefaultRetentionDays                 = 15
	DefaultCacheRetentionDays            = 1
	DefaultRetentionRunBudget            = 20 * time.Second
	DefaultProfileMediaHistoryDays       = 15
	MinimumRetentionDays                 = 1
	MaximumRetentionDays                 = 15
	MinimumRetentionRunBudget            = time.Second
	MaximumRetentionRunBudget            = 5 * time.Minute
	RetentionDaysEnvironment             = "GXB_RETENTION_DAYS"
	CacheRetentionDaysEnvironment        = "GXB_CACHE_RETENTION_DAYS"
	RetentionRunBudgetEnvironment        = "GXB_RETENTION_RUN_BUDGET"
	ProfileMediaHistoryDaysEnvironment   = "GXB_PROFILE_MEDIA_HISTORY_DAYS"
)

type Policies struct {
	RetentionDays           int
	CacheRetentionDays      int
	RunBudget               time.Duration
	ProfileMediaHistoryDays int
}

func PoliciesFromEnvironment() (Policies, error) {
	retentionDays, err := environmentWithin(RetentionDaysEnvironment, DefaultRetentionDays, MinimumRetentionDays, MaximumRetentionDays)
	if err != nil {
		return Policies{}, err
	}
	cacheRetentionDays, err := environmentWithin(CacheRetentionDaysEnvironment, DefaultCacheRetentionDays, MinimumRetentionDays, retentionDays)
	if err != nil {
		return Policies{}, err
	}
	runBudget, err := environmentDuration(RetentionRunBudgetEnvironment, DefaultRetentionRunBudget, MinimumRetentionRunBudget, MaximumRetentionRunBudget)
	if err != nil {
		return Policies{}, err
	}
	profileMediaHistoryDays, err := environmentWithin(ProfileMediaHistoryDaysEnvironment, min(DefaultProfileMediaHistoryDays, retentionDays), MinimumRetentionDays, retentionDays)
	if err != nil {
		return Policies{}, err
	}
	policies := Policies{
		RetentionDays:           retentionDays,
		CacheRetentionDays:      cacheRetentionDays,
		RunBudget:               runBudget,
		ProfileMediaHistoryDays: profileMediaHistoryDays,
	}
	if err = policies.Validate(); err != nil {
		return Policies{}, err
	}
	return policies, nil
}

func (p Policies) Validate() error {
	if p.RetentionDays < MinimumRetentionDays || p.RetentionDays > MaximumRetentionDays {
		return fmt.Errorf("%s must be between %d and %d days", RetentionDaysPolicyID, MinimumRetentionDays, MaximumRetentionDays)
	}
	if p.CacheRetentionDays < MinimumRetentionDays || p.CacheRetentionDays > p.RetentionDays {
		return fmt.Errorf("%s must be between %d and %s days", CacheRetentionDaysPolicyID, MinimumRetentionDays, RetentionDaysPolicyID)
	}
	if p.RunBudget < MinimumRetentionRunBudget || p.RunBudget > MaximumRetentionRunBudget {
		return fmt.Errorf("%s must be between %s and %s", RetentionRunBudgetPolicyID, MinimumRetentionRunBudget, MaximumRetentionRunBudget)
	}
	if p.ProfileMediaHistoryDays < MinimumRetentionDays || p.ProfileMediaHistoryDays > p.RetentionDays {
		return fmt.Errorf("%s must be between %d and %s days", ProfileMediaHistoryRetentionPolicyID, MinimumRetentionDays, RetentionDaysPolicyID)
	}
	return nil
}

func environmentDuration(name string, fallback, minimum, maximum time.Duration) (time.Duration, error) {
	raw := os.Getenv(name)
	if raw == "" {
		return fallback, nil
	}
	value, err := time.ParseDuration(raw)
	if err != nil {
		return 0, fmt.Errorf("%s=%q is not a duration", name, raw)
	}
	if value < minimum || value > maximum {
		return 0, fmt.Errorf("%s=%s is outside %s..%s", name, value, minimum, maximum)
	}
	return value, nil
}

func environmentWithin(name string, fallback, minimum, maximum int) (int, error) {
	raw := os.Getenv(name)
	if raw == "" {
		return fallback, nil
	}
	value, err := strconv.Atoi(raw)
	if err != nil {
		return 0, fmt.Errorf("%s=%q is not a whole number", name, raw)
	}
	if value < minimum || value > maximum {
		return 0, fmt.Errorf("%s=%d is outside %d..%d", name, value, minimum, maximum)
	}
	return value, nil
}
