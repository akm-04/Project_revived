package topfloor

import (
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

const taskModeCutoffSeconds = 20*3600 + 30*60

type TaskModePeriod struct {
	Ladder   Ladder           `json:"ladder"`
	Rotation TaskModeRotation `json:"rotation"`
}

// validateTaskLadder accepts the humans-only D512 ladder, which starts at size 0
// instead of the source robot population.
func (l Ladder) validateTaskLadder() error {
	if !l.Server.Valid() || len(l.ContentRevision) != 64 || l.Size < 0 || l.StateVersion < 1 || l.CreatedAt.IsZero() || l.UpdatedAt.Before(l.CreatedAt) {
		return ErrConflict
	}
	return nil
}

func (period TaskModePeriod) Validate() error {
	rotation := period.Rotation
	if period.Ladder.validateTaskLadder() != nil || rotation.Number < 1 || rotation.Mode < TaskModeSingle || rotation.Mode > TaskModeCamp || rotation.StartsAt.IsZero() || rotation.EndsAt.Sub(rotation.StartsAt) != taskModeDays*24*time.Hour {
		return ErrConflict
	}
	_, validCamp := taskModeSelectedCamp(rotation.Submode)
	if !validCamp || rotation.Mode != TaskModeCamp && rotation.Submode != 0 || period.Ladder.CreatedAt.Before(rotation.StartsAt) || !period.Ladder.CreatedAt.Before(rotation.EndsAt) {
		return ErrConflict
	}
	return nil
}

func (catalog TaskModeCatalog) NewPeriod(server identity.LogicalServerID, revision string, at time.Time) (TaskModePeriod, error) {
	rotation, err := catalog.Rotation(at)
	if err != nil {
		return TaskModePeriod{}, err
	}
	calendar := Catalog{CutoffSeconds: taskModeCutoffSeconds}
	// PRIVATE_POLICY D512: no robot seeding; the first human entrant is rank 1.
	period := TaskModePeriod{Rotation: rotation, Ladder: Ladder{Server: server, ContentRevision: revision,
		Size: 0, SettledDay: calendar.LatestCutoffDay(at), StateVersion: 1, CreatedAt: at.UTC(), UpdatedAt: at.UTC()}}
	return period, period.Validate()
}

func (period TaskModePeriod) Unsettled(at time.Time) []int64 {
	calendar := Catalog{CutoffSeconds: taskModeCutoffSeconds}
	last := min(calendar.LatestCutoffDay(at), calendar.LatestCutoffDay(period.Rotation.EndsAt.Add(-time.Nanosecond)))
	days := []int64{}
	for day := period.Ladder.SettledDay + 1; day <= last; day++ {
		days = append(days, day)
	}
	return days
}
