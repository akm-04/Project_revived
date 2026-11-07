package contentstore

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/socialexchange"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const socialContentCapability = "SOCIAL_CONTENT_I9_10E"

// ErrSocialContentUnavailable reports an explicit Social content read against a
// revision that predates the Social content capability.
var ErrSocialContentUnavailable = errors.New("contentstore: Social content unavailable for revision")

// SocialInputCatalogTx reads the caller-pinned immutable Social source DTO. It
// exposes recall milestones and the raw unknown invitation graph for later
// owners without interpreting either.
func (Store) SocialInputCatalogTx(ctx context.Context, q tx.Queryer, revision string) (builtin.SocialInputCatalog, error) {
	var out builtin.SocialInputCatalog
	if q == nil || len(revision) != 64 {
		return out, ErrSocialContentUnavailable
	}
	if e := readModeCatalog(ctx, q, revision, socialContentCapability, "content_social_input_catalogs", "social_input_catalog.json", &out); e != nil {
		if errors.Is(e, errModeCatalog) {
			return builtin.SocialInputCatalog{}, ErrSocialContentUnavailable
		}
		return builtin.SocialInputCatalog{}, e
	}
	if e := out.Validate(); e != nil {
		return builtin.SocialInputCatalog{}, e
	}
	return out, nil
}

// SocialExchangeCatalogTx binds the installed Social source DTO to the pure
// exchange domain. Cost stays friendship_coin; rewards stay dropbox item stacks.
func (s Store) SocialExchangeCatalogTx(ctx context.Context, q tx.Queryer, revision string) (socialexchange.Catalog, error) {
	catalog, e := s.SocialInputCatalogTx(ctx, q, revision)
	if e != nil {
		return socialexchange.Catalog{}, e
	}
	return socialExchangeCatalog(catalog)
}

func socialExchangeCatalog(catalog builtin.SocialInputCatalog) (socialexchange.Catalog, error) {
	products := make([]socialexchange.Product, 0, len(catalog.ExchangeProducts))
	for _, product := range catalog.ExchangeProducts {
		products = append(products, socialexchange.Product{ID: product.ID, GiftID: product.GiftID, SellPrice: product.SellPrice})
	}
	gifts := make([]socialexchange.ExchangeGift, 0, len(catalog.ExchangeProducts))
	for _, gift := range catalog.Gifts {
		if len(gift.Drops) != 1 {
			continue
		}
		gifts = append(gifts, socialexchange.ExchangeGift{ID: gift.ID, DropboxID: gift.Drops[0]})
	}
	dropboxes := make([]socialexchange.Dropbox, 0, len(catalog.Dropboxes))
	for _, dropbox := range catalog.Dropboxes {
		rolls := make([]socialexchange.Drop, 0, len(dropbox.Rolls))
		for _, roll := range dropbox.Rolls {
			rolls = append(rolls, socialexchange.Drop{ID: roll.ID, ItemID: roll.ItemID, ItemNum: roll.ItemNum, Rate: roll.DropRate})
		}
		dropboxes = append(dropboxes, socialexchange.Dropbox{ID: dropbox.ID, Rolls: rolls})
	}
	out := socialexchange.Catalog{ExchangeLimit: catalog.ExchangeLimit, Products: products, Gifts: gifts, Dropboxes: dropboxes}
	if e := out.Validate(); e != nil {
		return socialexchange.Catalog{}, e
	}
	return out, nil
}
