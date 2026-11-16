package mentor

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// GraduatedCountTx is 100022's owner fact: the mentor's CategoryGraduated
// high-water across the stored graduated missions.
func (service Service) GraduatedCountTx(c context.Context, q tx.Queryer, p identity.PlayerID) (int64, error) {
	if service.Store == nil || service.Content == nil {
		return 0, ErrUnavailable
	}
	catalog, e := service.catalog()
	if e != nil {
		return 0, e
	}
	progress, e := service.Store.ReadMissionProgressTx(c, q, p)
	if e != nil {
		return 0, e
	}
	missions := missionsFromCatalog(catalog)
	graduated := int64(0)
	for _, row := range progress {
		mission, ok := missionByID(missions, row.MissionID)
		if ok && mission.Category == domain.CategoryGraduated {
			graduated = domain.AdvanceHighWater(graduated, row.Progress)
		}
	}
	return graduated, nil
}
