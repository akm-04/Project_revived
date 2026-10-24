package i5store

import (
	"context"
	"errors"
	"fmt"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const insertBootstrapEconomyOwner = `
INSERT INTO player_economy_owners(player_id,state_version,created_at)
VALUES($1,1,$2)`

const insertBootstrapTemporal = `
INSERT INTO player_temporal_resources(
  player_id,resource_key,stored_amount,regen_anchor_at,policy_version,content_revision,state_version,updated_at)
VALUES($1,$2,$3,$4,$5,$6,1,$7)`

// EconomyOwnerBootstrapContributor owns the canonical I5 synchronization root
// and the R5-supported fresh temporal rows. The balances are the explicit
// r5.bootstrap.v1 compatibility policy, not recovered original-server truth.
type EconomyOwnerBootstrapContributor struct {
	Content    appi5.ContentRuntime
	Privileges appi5.PrivilegeSnapshotProvider
}

func (EconomyOwnerBootstrapContributor) Name() string   { return "i5.typed-economy-r5-bootstrap" }
func (EconomyOwnerBootstrapContributor) Required() bool { return true }

func (c EconomyOwnerBootstrapContributor) PersistCharacterBootstrap(ctx context.Context, t tx.Tx, b logicalserver.BootstrapContext) error {
	if t == nil || !b.PlayerID.Valid() || b.Operation.StartedAt.IsZero() || c.Content == nil || c.Privileges == nil {
		return errors.New("invalid typed-economy R5 bootstrap context")
	}
	revision, ok := b.Operation.Policies.Get("content")
	if !ok || revision == "" {
		return errors.New("R5 bootstrap requires bound content revision")
	}
	now := b.Operation.StartedAt.UTC()
	progression, err := c.Content.ResolveProgressionPolicyTx(ctx, t, revision)
	if err != nil {
		return fmt.Errorf("bootstrap progression policy: %w", err)
	}
	if _, err := progression.EnergyCap(1); err != nil {
		return err
	}

	if _, err := t.Exec(ctx, insertBootstrapEconomyOwner, int64(b.PlayerID), now); err != nil {
		return err
	}

	type seed struct {
		key    string
		amount int64
		paused bool
	}
	seeds := []seed{{"energy", 100, true}, {"spirit_energy", 100, false}, {"skill_point", 0, false}}
	for _, seed := range seeds {
		line := grant.Line{Kind: grant.Temporal, ResourceKey: seed.key, Amount: 1}
		rp, err := c.Content.ResolveResourceTx(ctx, t, revision, line)
		if err != nil {
			return fmt.Errorf("bootstrap %s descriptor: %w", seed.key, err)
		}
		if rp.Descriptor == nil || rp.Descriptor.Revision != revision {
			return fmt.Errorf("bootstrap %s lacks exact R5 temporal descriptor", seed.key)
		}
		pol, _, err := appi5.ResolveTemporalPolicyTx(ctx, t, b.PlayerID, *rp.Descriptor, progression, 1, now, c.Privileges)
		if err != nil {
			return fmt.Errorf("bootstrap %s policy: %w", seed.key, err)
		}
		if err := pol.Validate(); err != nil {
			return err
		}
		var anchor any
		if !seed.paused {
			anchor = now
		}
		if _, err := t.Exec(ctx, insertBootstrapTemporal, int64(b.PlayerID), seed.key, seed.amount, anchor, revision, revision, now); err != nil {
			return fmt.Errorf("bootstrap %s persist: %w", seed.key, err)
		}
	}
	return nil
}

var _ appboot.CharacterBootstrapPersistenceContributor = EconomyOwnerBootstrapContributor{}
