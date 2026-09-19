package i5store

import (
	"context"
	"errors"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	insertBootstrapPlayerCoreProfile = `
INSERT INTO player_profiles(
  player_id,display_name,avatar_id,avatar_frame_id,player_type,state_version,created_at,updated_at)
VALUES($1,$2,$3,$4,$5,$6,$7,$7)`
	insertBootstrapPlayerCoreProgression = `
INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)
VALUES($1,$2,$3,$4,$5)`
	insertBootstrapPlayerCoreStory = `
INSERT INTO player_story_cursors(player_id,story_id,story_state,guide_id,state_version,updated_at)
VALUES($1,$2,$3,$4,$5,$6)`
	insertBootstrapPlayerCoreGuideReturn = `
INSERT INTO player_guide_return_state(player_id,guide_return_id,guide_function_ids,state_version,updated_at)
VALUES($1,$2,'{}'::bigint[],$3,$4)`
	insertBootstrapFunctionStateOwner = `
INSERT INTO player_function_state_owners(player_id,state_version,updated_at)
VALUES($1,1,$2)`
)

// PlayerCoreBootstrapContributor owns the required I5 Player Core rows for a
// fresh character. The caller owns the surrounding MID1 transaction; this
// adapter writes only Player Core-owned tables.
type PlayerCoreBootstrapContributor struct{}

func (PlayerCoreBootstrapContributor) Name() string   { return "i5.player-core" }
func (PlayerCoreBootstrapContributor) Required() bool { return true }
func (PlayerCoreBootstrapContributor) PersistCharacterBootstrap(ctx context.Context, t tx.Tx, b logicalserver.BootstrapContext) error {
	if t == nil || !b.PlayerID.Valid() || b.AccountID.UUID().IsZero() || b.SessionID.UUID().IsZero() || !b.LogicalServerID.Valid() || b.Operation.StartedAt.IsZero() || b.BootstrapProfileVersion == "" {
		return errors.New("invalid player-core bootstrap context")
	}
	core := player.CompatibilityBootstrap(b.PlayerID, b.Operation.StartedAt.UTC())
	if err := core.Validate(); err != nil {
		return err
	}
	if _, err := t.Exec(ctx, insertBootstrapPlayerCoreProfile,
		int64(b.PlayerID), core.Profile.DisplayName, core.Profile.AvatarID, core.Profile.AvatarFrameID,
		core.Profile.PlayerType, core.Profile.StateVersion, core.Profile.CreatedAt.UTC()); err != nil {
		return err
	}
	if _, err := t.Exec(ctx, insertBootstrapPlayerCoreProgression,
		int64(b.PlayerID), core.Progression.Level, core.Progression.Exp, core.Progression.StateVersion, core.Progression.UpdatedAt.UTC()); err != nil {
		return err
	}
	if _, err := t.Exec(ctx, insertBootstrapPlayerCoreStory,
		int64(b.PlayerID), core.Story.StoryID, core.Story.StoryState, core.Story.GuideID, core.Story.StateVersion, core.Story.UpdatedAt.UTC()); err != nil {
		return err
	}
	if _, err := t.Exec(ctx, insertBootstrapPlayerCoreGuideReturn,
		int64(b.PlayerID), core.GuideReturn.GuideReturnID, core.GuideReturn.StateVersion, core.GuideReturn.UpdatedAt.UTC()); err != nil {
		return err
	}
	if _, err := t.Exec(ctx, insertBootstrapFunctionStateOwner, int64(b.PlayerID), b.Operation.StartedAt.UTC()); err != nil {
		return err
	}
	return nil
}

var _ appboot.CharacterBootstrapPersistenceContributor = PlayerCoreBootstrapContributor{}
