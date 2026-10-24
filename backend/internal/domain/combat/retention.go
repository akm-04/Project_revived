package combat

import "time"

// RetentionCeiling bounds every mode's report retention (D9 Q6 private
// policy; the original server's retention is UNKNOWN).
const RetentionCeiling = 7 * 24 * time.Hour

// Retention is a replaying mode's versioned report retention
// (I8_REPORT_LIFECYCLE_V1, D25). A changed window is a new version.
// Availability is computed from the immutable terminal time, so a version
// change never rewrites a stored attempt or report (H-58).
type Retention struct {
	ID      string
	Version int
	Window  time.Duration
}

func (r Retention) Valid() bool {
	return versionedID.MatchString(r.ID) && r.Version > 0 && r.Window > 0 && r.Window <= RetentionCeiling
}

// Retains reports whether the attempt's report is still served at now.
func (r Retention) Retains(a Attempt, now time.Time) bool {
	return a.State == Terminal && a.ResolutionHash != "" && a.TerminalAt != nil && now.Before(a.TerminalAt.Add(r.Window))
}
