package contentstore

import (
	"context"

	application "gxb.local/backend/v2/internal/application/socialinvite"
	"gxb.local/backend/v2/internal/content/builtin"
	domain "gxb.local/backend/v2/internal/domain/socialinvite"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// SocialInvitationMissionsTx binds the installed invitation_mission rows to the
// socialinvite application catalog. PRIVATE_POLICY (D493 item 5): type 3 reads
// the invited player's highest currently owned battle girl level.
func (store Store) SocialInvitationMissionsTx(ctx context.Context, query tx.Queryer, revision string) (application.MissionCatalog, error) {
	catalog, err := store.SocialInputCatalogTx(ctx, query, revision)
	if err != nil {
		return nil, err
	}
	return socialInvitationMissions(catalog)
}

func socialInvitationMissions(catalog builtin.SocialInputCatalog) (application.MissionCatalog, error) {
	if catalog.Validate() != nil {
		return nil, ErrSocialContentUnavailable
	}
	out := make(application.MissionCatalog, 0, len(catalog.InvitationMissions))
	for _, mission := range catalog.InvitationMissions {
		out = append(out, application.Mission{ID: mission.ID, Type: domain.MissionType(mission.Type), RequiredCount: mission.RequiredCount, Threshold: mission.Threshold, Diamond: mission.Diamond})
	}
	if out.Validate() != nil {
		return nil, ErrSocialContentUnavailable
	}
	return out, nil
}
