package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const campaignCapability = "CAMPAIGN_MODE_I9_3A"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var campaignCatalogs sync.Map

// CampaignCatalogTx reads only the caller-pinned immutable revision.
func (s Store) CampaignCatalogTx(ctx context.Context, q tx.Queryer, revision string) (campaign.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return campaign.Catalog{}, campaign.ErrUnavailable
	}
	if cached, ok := campaignCatalogs.Load(revision); ok {
		return cached.(campaign.Catalog), nil
	}
	var out campaign.Catalog
	e := readModeCatalog(ctx, q, revision, campaignCapability, "content_campaign_catalogs", "campaign_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return campaign.Catalog{}, campaign.ErrUnavailable
	}
	if e != nil {
		return campaign.Catalog{}, e
	}
	if e = out.Validate(); e != nil {
		return campaign.Catalog{}, e
	}
	campaignCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertCampaign(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_campaign_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.CampaignJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyCampaignSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_campaign_catalogs WHERE revision_id=$1`
