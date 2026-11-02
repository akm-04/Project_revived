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
	if p.Queryer == nil || p.Directory == nil {
		return activity.Projection{}, false, d.ErrUnavailable
	}
	projection := activity.Projection{TableID: d.ActivityID, StartTime: 0, EndTime: 0, Days: -1, Details: map[string]any{"level": d.OpenLevel}}
	profile, found, err := p.Directory.ProfileTx(c, p.Queryer, pc.Actor.PlayerID)
	if err != nil {
		return activity.Projection{}, false, err
	}
	if !found {
		return projection, true, nil
	}
	if profile.Level >= d.OpenLevel {
		projection.IsOpen = 1
	}
	return projection, true, nil
}
