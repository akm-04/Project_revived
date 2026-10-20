package arena

import (
	"context"
	"fmt"

	app "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ReadCatalogDisplayOriginsTx proves the season champion avatar: each champion
// settlement starts the catalog's timed avatar at its settlement time
// (C6_SELECTED_COSMETIC_ORIGINS_V1). Settlements exist since the mode started,
// so the history is complete; the champion mail item is a separate stack.
func (s Service) ReadCatalogDisplayOriginsTx(c context.Context, q tx.Queryer, r app.CatalogOriginRequest) (app.CatalogOriginObservation, error) {
	out := app.CatalogOriginObservation{Request: r, Origins: []app.Origin{}}
	if q == nil || s.Store == nil || s.Content == nil || !r.PlayerID.Valid() || r.Family != "avatar" || len(r.Revision) != 64 {
		return out, app.ErrUnavailable
	}
	catalog, e := s.Content.ArenaCatalogTx(c, q, r.Revision)
	if e != nil {
		return out, e
	}
	display, e := s.Content.ReadPlayerDisplayCatalogTx(c, q, r.Revision)
	if e != nil {
		return out, e
	}
	if row, ok := display.Find(r.Family, r.CatalogID); !ok || r.CatalogID != catalog.ChampionItem || row.Days <= 0 {
		return out, app.ErrConflict
	}
	settlements, e := s.Store.ChampionSettlementsTx(c, q, r.PlayerID)
	if e != nil {
		return out, e
	}
	for _, settled := range settlements {
		if settled.SettledAt.After(r.ObservedAt) {
			continue
		}
		starts := settled.SettledAt.UTC()
		out.Origins = append(out.Origins, app.Origin{PlayerID: r.PlayerID, Key: fmt.Sprintf("arena:%d:champion", settled.Season), Owner: "Arena", Family: r.Family, CatalogID: r.CatalogID, StartsAt: &starts, Revision: r.Revision, StateVersion: 1})
	}
	out.Qualified, out.CompleteHistory = true, true
	return out, nil
}

var _ app.CatalogExternalOrigins = Service{}
