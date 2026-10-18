package playerdisplay

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
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
