package topfloor

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type TaskModeEligibility struct {
	Rank               int64
	WeeklyChallenges   int64
	ServerMaximumLevel int64
	Eligible           bool
}

func (service Service) TaskModeEligibilityTx(requestContext context.Context, query tx.Queryer, catalog domain.TaskModeCatalog, actor identity.ActorContext, at time.Time) (TaskModeEligibility, error) {
	if query == nil || !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || int64(actor.PlayerID)/domain.RegionStride != int64(actor.LogicalServerID) || at.IsZero() {
		return TaskModeEligibility{}, domain.ErrInvalid
	}
	if service.Store == nil || service.Directory == nil {
		return TaskModeEligibility{}, domain.ErrUnavailable
	}
	rank, found, err := service.Store.RankOfTx(requestContext, query, actor.LogicalServerID, domain.Occupant{Player: actor.PlayerID})
	if err != nil {
		return TaskModeEligibility{}, err
	}
	if !found {
		return TaskModeEligibility{}, nil
	}
	challenges, err := service.Store.WeeklyChallengesTx(requestContext, query, actor.PlayerID, at)
	if err != nil {
		return TaskModeEligibility{}, err
	}
	maximumLevel, err := service.Directory.ServerMaximumLevelTx(requestContext, query, actor.LogicalServerID)
	if err != nil {
		return TaskModeEligibility{}, err
	}
	return TaskModeEligibility{Rank: rank, WeeklyChallenges: challenges, ServerMaximumLevel: maximumLevel,
		Eligible: catalog.Admit(rank, challenges, maximumLevel) == nil}, nil
}
