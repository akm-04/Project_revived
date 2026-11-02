package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/petcampaign"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const petcampaignCapability = "PET_CAMPAIGN_I9_5C"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var petcampaignCatalogs sync.Map

// PetCampaignCatalogTx reads only the caller-pinned immutable revision.
func (s Store) PetCampaignCatalogTx(ctx context.Context, q tx.Queryer, revision string) (petcampaign.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return petcampaign.Catalog{}, petcampaign.ErrUnavailable
	}
	if cached, ok := petcampaignCatalogs.Load(revision); ok {
		return cached.(petcampaign.Catalog), nil
	}
	var out petcampaign.Catalog
	e := readModeCatalog(ctx, q, revision, petcampaignCapability, "content_pet_campaign_catalogs", "pet_campaign_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return petcampaign.Catalog{}, petcampaign.ErrUnavailable
	}
	if e != nil {
		return petcampaign.Catalog{}, e
	}
	if e = out.Validate(); e != nil {
		return petcampaign.Catalog{}, e
	}
	petcampaignCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertPetCampaign(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_pet_campaign_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.PetCampaignJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyPetCampaignSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_pet_campaign_catalogs WHERE revision_id=$1`
