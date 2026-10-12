//go:build postgres

package main

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

func registerPlayerDisplay(c context.Context, p *postgres.Pool, content contentstore.Store, r *httpedge.Router, d stockruntime.PlayerDisplayDispatcher) error {
	rev, e := content.ActiveRevision(c, p)
	if e != nil {
		return e
	}
	if _, e = content.ReadPlayerDisplayCatalogTx(c, p, rev); e != nil {
		return e
	}
	for _, mid := range []uint16{23, 98, 100, 119, 656, 2490, 2492, 2493, 2494} {
		if e = r.Register(mid, d); e != nil {
			return e
		}
	}
	return nil
}
