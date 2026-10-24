package playerdisplay

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// CatalogOriginRequest is narrower than a whole-family eligibility claim.
// Qualified positive origins and complete negative history are separate facts.
type CatalogOriginRequest struct {
	PlayerID   identity.PlayerID
	Family     string
	CatalogID  int64
	Revision   string
	ObservedAt time.Time
}
type CatalogOriginObservation struct {
	Request         CatalogOriginRequest
	Qualified       bool
	CompleteHistory bool
	Origins         []Origin
}
type CatalogExternalOrigins interface {
	ReadCatalogDisplayOriginsTx(context.Context, tx.Queryer, CatalogOriginRequest) (CatalogOriginObservation, error)
}

func (s Service) catalogOrigins(c context.Context, q tx.Queryer, pid identity.PlayerID, family string, id int64, rev string, at time.Time) ([]Origin, bool, error) {
	if s.CatalogExternal != nil {
		request := CatalogOriginRequest{PlayerID: pid, Family: family, CatalogID: id, Revision: rev, ObservedAt: at}
		o, e := s.CatalogExternal.ReadCatalogDisplayOriginsTx(c, q, request)
		if e == nil {
			if !o.Qualified || o.Request.PlayerID != pid || o.Request.Family != family || o.Request.CatalogID != id || o.Request.Revision != rev || !o.Request.ObservedAt.Equal(at) {
				return nil, false, ErrUnavailable
			}
			for _, x := range o.Origins {
				if x.Validate() != nil || x.PlayerID != pid || x.Family != family || x.CatalogID != id || x.StartsAt != nil && x.StartsAt.After(at) {
					return nil, false, ErrConflict
				}
			}
			return o.Origins, o.CompleteHistory, nil
		}
		if !errors.Is(e, ErrUnavailable) || s.External == nil {
			return nil, false, e
		}
	}
	// The original interface continues to mean qualified complete family scope.
	// It is not silently satisfied by the new bounded provider.
	origins, e := s.origins(c, q, pid, family, rev, at)
	return origins, e == nil, e
}

// ErrUncovered: no owner produces the catalog id, so this server has no grant path for it (D62).
var ErrUncovered = fmt.Errorf("%w: no catalog origin owner covers the id", ErrUnavailable)

// familyOrigins answers every origin of a family. Without a whole-family External owner it is the union of the bounded
// catalog owners; an id no owner covers is absent, not unavailable (D62).
func (s Service) familyOrigins(c context.Context, q tx.Queryer, pid identity.PlayerID, family string, p player.DisplayCatalog, rev string, at time.Time) ([]Origin, error) {
	if s.External != nil || s.CatalogExternal == nil {
		return s.origins(c, q, pid, family, rev, at)
	}
	out := []Origin{}
	for _, v := range p.Cosmetics {
		if v.Family != family {
			continue
		}
		origins, _, e := s.catalogOrigins(c, q, pid, family, v.ID, rev, at)
		if errors.Is(e, ErrUncovered) {
			continue
		}
		if e != nil {
			return nil, e
		}
		out = append(out, origins...)
	}
	return out, nil
}

// CatalogOriginRoute names the owner of a contiguous range of catalog ids.
type CatalogOriginRoute struct {
	Family      string
	First, Last int64
	Owner       CatalogExternalOrigins
}

// CatalogOriginRoutes sends each bounded request to the owner whose range
// covers it; an id no owner produces stays unavailable.
type CatalogOriginRoutes []CatalogOriginRoute

func (routes CatalogOriginRoutes) ReadCatalogDisplayOriginsTx(c context.Context, q tx.Queryer, r CatalogOriginRequest) (CatalogOriginObservation, error) {
	for _, route := range routes {
		if (route.Family == "" || route.Family == r.Family) && r.CatalogID >= route.First && r.CatalogID <= route.Last {
			return route.Owner.ReadCatalogDisplayOriginsTx(c, q, r)
		}
	}
	return CatalogOriginObservation{Request: r, Origins: []Origin{}}, ErrUncovered
}
