package worldboss

import (
	"context"

	"gxb.local/backend/v2/internal/application/activitydirectory"
	"gxb.local/backend/v2/internal/domain/activity"
	d "gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ActivityProvider exposes activity 1026 open from level 48.
type ActivityProvider struct {
	Queryer   tx.Queryer
	Directory Directory
}

func (p ActivityProvider) Project(c context.Context, pc activitydirectory.ProjectionContext) (activity.Projection, bool, error) {
	level, found, err := p.level(c, pc)
	if err != nil {
		return activity.Projection{}, false, err
	}
	projection := activity.Projection{TableID: d.ActivityID, StartTime: 0, EndTime: 0, Days: -1, Details: map[string]any{"level": d.OpenLevel}}
	if !found {
		return projection, true, nil
	}
	if level >= d.OpenLevel {
		projection.IsOpen = 1
	}
	return projection, true, nil
}

// level prefers the caller's transaction-scoped reader so a MID1 transaction
// never asks the pool for a second connection.
func (p ActivityProvider) level(c context.Context, pc activitydirectory.ProjectionContext) (int64, bool, error) {
	if pc.PlayerLevel != nil {
		return pc.PlayerLevel(c, pc.Actor.PlayerID)
	}
	if p.Queryer == nil || p.Directory == nil {
		return 0, false, d.ErrUnavailable
	}
	profile, found, err := p.Directory.ProfileTx(c, p.Queryer, pc.Actor.PlayerID)
	return profile.Level, found, err
}
