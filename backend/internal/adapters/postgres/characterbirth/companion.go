package characterbirth

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// BirthCompanion gives a fresh character the Vending tutorial companion
// (I9_GACHA_PRIVATE_POLICY_V1 tutorial.birth_companion, Aquaris, partner 1) so
// strong guide 100102 opens Vending with a hero owned (D139). It runs after
// every owner whose fresh-hero facet rows it creates.
type BirthCompanion struct {
	Content contentstore.Store
}

func (BirthCompanion) Name() string   { return "i9-3e.summon-birth-companion" }
func (BirthCompanion) Required() bool { return true }

func (s BirthCompanion) PersistCharacterBootstrap(c context.Context, t tx.Tx, b logicalserver.BootstrapContext) error {
	revision, bound := b.Operation.Policies.Get("content")
	if !bound {
		return errors.New("summon birth companion: unbound content revision")
	}
	catalog, err := s.Content.SummonCatalogTx(c, t, revision)
	if err != nil {
		return err
	}
	heroes := characterhero.Service{AcquisitionStore: characterstore.Store{}, Acquisition: s.Content, CollectionAdmission: characterhero.CatalogCollectionAdmission{Content: s.Content}, FreshFacets: FreshHeroFacets()}
	_, _, err = heroes.AwardStoryPartnerTx(c, t, b.PlayerID, catalog.Policy.Tutorial.BirthCompanion, revision, b.Operation)
	return err
}
