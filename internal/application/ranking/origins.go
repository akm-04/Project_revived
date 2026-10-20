package ranking

import (
	"context"

	app "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func sameOrigin(a, b app.Origin) bool {
	sameStart := a.StartsAt == nil && b.StartsAt == nil || a.StartsAt != nil && b.StartsAt != nil && a.StartsAt.Equal(*b.StartsAt)
	return a.PlayerID == b.PlayerID && a.Key == b.Key && a.Owner == b.Owner && a.Family == b.Family && a.CatalogID == b.CatalogID && a.UniqueID == b.UniqueID && sameStart && a.EndTime == b.EndTime && a.Revision == b.Revision && a.StateVersion == b.StateVersion
}

// ReadCatalogDisplayOriginsTx proves only the requested board's own title rows.
// Missing legacy history cannot become a complete empty family observation.
func (s Service) ReadCatalogDisplayOriginsTx(c context.Context, q tx.Queryer, r app.CatalogOriginRequest) (app.CatalogOriginObservation, error) {
	out := app.CatalogOriginObservation{Request: r, Origins: []app.Origin{}}
	board, known := d.BoardOfTitle(r.CatalogID)
	if !known || q == nil || s.Store == nil || s.Cohort == nil || s.Ledger == nil || s.Content == nil || !r.PlayerID.Valid() || r.Family != "title" || r.ObservedAt.Unix() <= 0 || len(r.Revision) != 64 {
		return out, app.ErrUnavailable
	}
	catalog, e := s.Content.ReadPlayerDisplayCatalogTx(c, q, r.Revision)
	if e != nil {
		return out, e
	}
	v, ok := catalog.Find(r.Family, r.CatalogID)
	if !ok || v.Type != board.TitleType || v.Days != d.BoardTitleDuration {
		return out, app.ErrConflict
	}
	roots, e := s.Cohort.ListPlayerRootsTx(c, q)
	if e != nil {
		return out, e
	}
	server := identity.LogicalServerID(0)
	seen := map[identity.PlayerID]bool{}
	for _, x := range roots {
		if x.Validate() != nil || seen[x.PlayerID] {
			return out, app.ErrConflict
		}
		seen[x.PlayerID] = true
		if x.PlayerID == r.PlayerID {
			server = x.LogicalServerID
		}
	}
	if !server.Valid() {
		return out, app.ErrUnavailable
	}
	tracked, e := s.Store.BoardTrackingTx(c, q, board, r.PlayerID, server, r.ObservedAt)
	if e != nil {
		return out, e
	}
	evidence, e := s.Store.BoardAwardEvidenceTx(c, q, board, r.PlayerID)
	if e != nil {
		return out, e
	}
	canonical := map[string]app.Origin{}
	for _, x := range evidence {
		if x.Validate() != nil || x.Snapshot.Server != server || x.Snapshot.ObservedAt.After(r.ObservedAt) || x.SettledAt.After(r.ObservedAt) {
			return out, app.ErrConflict
		}
		o := awardOrigin(x.Snapshot, x.Award)
		if _, dup := canonical[o.Key]; dup {
			return out, app.ErrConflict
		}
		canonical[o.Key] = o
	}
	mirror, e := s.Ledger.ReadDisplayEntitlementsTx(c, q, r.PlayerID, "title")
	if e != nil {
		return out, e
	}
	matched := map[string]bool{}
	complete := tracked
	for _, m := range mirror {
		if m.Validate() != nil || m.PlayerID != r.PlayerID || m.Family != "title" {
			return out, app.ErrConflict
		}
		if !board.HasTitle(m.CatalogID) {
			continue
		}
		own, ok := canonical[m.Key]
		if !ok {
			if m.Owner == "Ranking" {
				return out, app.ErrConflict
			}
			if m.CatalogID == r.CatalogID {
				complete = false
			}
			continue
		}
		if !sameOrigin(own, m) || matched[m.Key] {
			return out, app.ErrConflict
		}
		matched[m.Key] = true
	}
	for key := range canonical {
		if !matched[key] {
			return out, app.ErrConflict
		}
	}
	// Preserve the canonical chronological order rather than map iteration order.
	out.Origins = []app.Origin{}
	for _, x := range evidence {
		if x.Award.TitleID == r.CatalogID {
			out.Origins = append(out.Origins, canonical[x.Award.OriginKey])
		}
	}
	out.Qualified = true
	out.CompleteHistory = complete
	return out, nil
}

var _ app.CatalogExternalOrigins = Service{}
