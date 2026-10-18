package characterstore

import (
	"context"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type RosterMetricContent interface {
	ReadPlayerDisplayCatalogTx(context.Context, tx.Queryer, string) (player.DisplayCatalog, error)
}
type RosterMetricReader struct {
	Store   Store
	Content RosterMetricContent
}

// Read-only Character-owned port; both the owner root and population are read
// through the caller's CA8 snapshot. Missing roots are errors, never empty bags.
func (r RosterMetricReader) ReadRosterMetricsTx(c context.Context, sc ca.CoherentReadScope, pid identity.PlayerID, family string) (ca.RosterMetricPopulation, error) {
	out := ca.RosterMetricPopulation{PlayerID: pid, Family: family, Revision: sc.ContentRevision, ObservedAt: sc.ObservedAt, Rows: []ca.RosterMetricRow{}}
	pin, ok := sc.Operation.Policies.Get("content")
	if sc.Validate() != nil || !ok || pin != sc.ContentRevision || !pid.Valid() {
		return out, ca.ErrInvalidCoherentReadScope
	}
	q := sc.Queryer()
	switch family {
	case "Hero":
		root, e := r.Store.ReadRootTx(c, q, pid)
		if e != nil {
			return out, e
		}
		if root.Validate() != nil || root.PlayerID != pid || root.UpdatedAt.After(sc.ObservedAt) {
			return out, ca.ErrInvalidCoherentReadScope
		}
		out.RootVersion = root.StateVersion
		if r.Content == nil {
			return out, ca.ErrInvalidCoherentReadScope
		}
		catalog, e := r.Content.ReadPlayerDisplayCatalogTx(c, q, sc.ContentRevision)
		if e != nil {
			return out, e
		}
		templates := map[int64]int64{}
		for _, t := range catalog.HeroTemplates {
			if _, exists := templates[t.TableID]; exists {
				return out, ca.ErrInvalidCoherentReadScope
			}
			templates[t.TableID] = t.BeforeAwaken
		}
		heroes, e := r.Store.ListHeroesTx(c, q, pid)
		if e != nil {
			return out, e
		}
		for _, h := range heroes {
			before, found := templates[h.TableID]
			if h.ValidatePersistent() != nil || h.PlayerID != pid || h.CreatedAt.After(h.UpdatedAt) || h.UpdatedAt.After(sc.ObservedAt) || !found || before < 0 {
				return out, ca.ErrInvalidCoherentReadScope
			}
			out.Rows = append(out.Rows, ca.RosterMetricRow{InstanceID: h.PartnerID, OriginTableID: h.OriginTableID, TableID: h.TableID, Star: h.Star, Version: h.StateVersion, BeforeAwaken: before})
		}
	case "Pet":
		root, e := r.Store.ReadPetRootTx(c, q, pid)
		if e != nil {
			return out, e
		}
		if root.Validate() != nil || root.PlayerID != pid || root.UpdatedAt.After(sc.ObservedAt) {
			return out, ca.ErrInvalidCoherentReadScope
		}
		out.RootVersion = root.StateVersion
		pets, e := r.Store.ListPetsTx(c, q, pid)
		if e != nil {
			return out, e
		}
		for _, p := range pets {
			if p.ValidatePersistent() != nil || p.PlayerID != pid || p.CreatedAt.After(p.UpdatedAt) || p.UpdatedAt.After(sc.ObservedAt) {
				return out, ca.ErrInvalidCoherentReadScope
			}
			out.Rows = append(out.Rows, ca.RosterMetricRow{InstanceID: p.PetID, OriginTableID: p.OriginTableID, TableID: p.TableID, Star: p.Star, Version: p.StateVersion})
		}
	default:
		return out, ca.ErrInvalidCoherentReadScope
	}
	return out, nil
}

var _ ca.RosterMetricReader = RosterMetricReader{}
