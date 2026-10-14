package builtin

import "errors"

type CourseInputCatalog struct {
	SchemaVersion                                         int                            `json:"schema_version"`
	PolicyID                                              string                         `json:"policy_id"`
	OverflowPolicyID                                      string                         `json:"overflow_policy_id"`
	Tables                                                map[string][]map[string]string `json:"tables"`
	Duration, ForgetCost, SpeedHalfHour, MaxEXP, LogLimit int64
	Tickets                                               map[int64]int64
	BookEXP                                               map[int64]int64
	Capacity                                              map[int64]int64
	Thresholds                                            []int64
	Refunds                                               map[int64]map[int64]int64
	Slots                                                 [6]bool
}

func (c CourseInputCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != "C2E_V1_COURSE_PROGRESS_AND_SEEDS_V1" || c.OverflowPolicyID != "C2E_V1_WHOLE_BOOK_PROFICIENCY_V1" || len(c.Tables["book"]) != 48 || len(c.Tickets) != 48 || len(c.Thresholds) != 6 || c.Duration != 28800 || c.MaxEXP != 1680 {
		return errors.New("course content: unqualified payload")
	}
	return nil
}
