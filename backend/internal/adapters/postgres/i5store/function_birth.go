package i5store

import (
	"context"
	"errors"
	"fmt"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// FunctionBirthContributor opens the level-1 function gates of a fresh character; level-ups open the rest (D59).
type FunctionBirthContributor struct {
	Content appi5.ContentRuntime
}

func (FunctionBirthContributor) Name() string   { return "i5.function-birth" }
func (FunctionBirthContributor) Required() bool { return true }

func (c FunctionBirthContributor) PersistCharacterBootstrap(ctx context.Context, t tx.Tx, b logicalserver.BootstrapContext) error {
	if t == nil || !b.PlayerID.Valid() || b.Operation.StartedAt.IsZero() || c.Content == nil {
		return errors.New("invalid function birth context")
	}
	revision, ok := b.Operation.Policies.Get("content")
	if !ok || revision == "" {
		return errors.New("function birth requires bound content revision")
	}
	policy, err := c.Content.ResolveFunctionGatePolicyTx(ctx, t, revision)
	if err != nil {
		return fmt.Errorf("function birth gate policy: %w", err)
	}
	eligible, unlocks, err := appi5.LevelFunctionOpenings(policy, b.PlayerID, 1, b.Operation.StartedAt)
	if err != nil {
		return err
	}
	for _, e := range eligible {
		if _, err := (Store{}).InsertFunctionEligibilityTx(ctx, t, e); err != nil {
			return err
		}
	}
	for _, u := range unlocks {
		if _, err := (Store{}).InsertFunctionUnlockTx(ctx, t, u); err != nil {
			return err
		}
	}
	return nil
}

var _ appboot.CharacterBootstrapPersistenceContributor = FunctionBirthContributor{}
