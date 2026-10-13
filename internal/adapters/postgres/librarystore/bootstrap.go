package librarystore

import (
	"context"
	"encoding/json"
	"errors"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type BootstrapContributor struct{}

func (BootstrapContributor) Name() string   { return "i7c2b.library-local" }
func (BootstrapContributor) Required() bool { return true }
func (BootstrapContributor) PersistCharacterBootstrap(ctx context.Context, t tx.Tx, b logicalserver.BootstrapContext) error {
	if t == nil {
		return library.ErrInvalidFacts
	}
	f, e := library.NewPlayerFacts(b.PlayerID, b.Operation.StartedAt.UTC())
	if e != nil {
		return e
	}
	bits, e := json.Marshal(f.SpecialClaims)
	if e != nil {
		return e
	}
	tag, e := t.Exec(ctx, `INSERT INTO player_library_roots(player_id,state_version,special_claims,seed_policy_id,created_at,updated_at)VALUES($1,1,$2::jsonb,$3,$4,$4)`, int64(f.PlayerID), string(bits), f.SeedPolicy, f.CreatedAt)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("library: bootstrap root not inserted")
	}
	return nil
}

var _ appboot.CharacterBootstrapPersistenceContributor = BootstrapContributor{}
