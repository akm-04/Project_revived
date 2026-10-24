// Package characterbirth is the production MID1 character-birth persistence chain. gxb-api and native test fixtures birth
// players through this one list, so a fixture player has every owner row a real player has (I8.5-6 D-DRIFT debt).
package characterbirth

import (
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/conquerstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/elementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/inscriptionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/rankingstore"
	"gxb.local/backend/v2/internal/adapters/postgres/spiritstore"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
)

// Contributors is the ordered owner chain a fresh character is persisted through; revision is the builtin content revision.
func Contributors(content contentstore.Store, privileges commerceprivilege.Provider, revision string) []appboot.CharacterBootstrapPersistenceContributor {
	return []appboot.CharacterBootstrapPersistenceContributor{
		i5store.PlayerCoreBootstrapContributor{},
		i5store.EconomyOwnerBootstrapContributor{Content: content, Privileges: privileges},
		i5store.FunctionBirthContributor{Content: content},
		characterstore.BootstrapContributor{},
		characterstore.PetBootstrapContributor{},
		characterstore.SavedPresetBootstrapContributor{},
		characterstore.PracticeBootstrapContributor{},
		librarystore.BootstrapContributor{},
		achievementstore.BootstrapContributor{Revision: revision},
		rankingstore.BootstrapContributor{},
		dormstore.BootstrapContributor{Revision: revision},
		bookstore.BootstrapContributor{Revision: revision},
		coursestore.BootstrapContributor{Revision: revision},
		inscriptionstore.BootstrapContributor{Revision: revision},
		i5store.InscriptionCertificateBootstrap{},
		elementstore.BootstrapContributor{Revision: revision},
		spiritstore.BootstrapContributor{Revision: revision},
		conquerstore.BootstrapContributor{Revision: revision},
	}
}

// FreshHeroFacets is the production chain that gives a newly acquired Hero its local facet rows in every owner.
func FreshHeroFacets() characterhero.FreshFacetChain {
	return characterhero.FreshFacetChain{librarystore.Store{}, dormstore.Store{}, coursestore.Store{}, inscriptionstore.Store{}, elementstore.Store{}, spiritstore.Store{}, characterstore.EvolutionStore{}, characterstore.RawAwakeningStore{}}
}
