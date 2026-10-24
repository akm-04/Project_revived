package playerdisplay

import (
	"context"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ReceiveOriginTx is a typed trusted-owner recipient, not a client-facing grant.
// Caller supplies its locked canonical root and one qualified semantic origin.
// Grant-time content is pinned permanently; later reads cannot reset its expiry.
func (s Service) ReceiveOriginTx(c context.Context, t tx.Tx, root playerroot.Root, o Origin) error {
	if t == nil || root.Validate() != nil || root.PlayerID != o.PlayerID || o.Validate() != nil || s.Store == nil || s.Content == nil {
		return ErrRequest
	}
	p, e := s.Content.ReadPlayerDisplayCatalogTx(c, t, o.Revision)
	if e != nil {
		return e
	}
	v, ok := p.Find(o.Family, o.CatalogID)
	if !ok {
		return ErrRequest
	}
	end, e := v.EndTime(o.StartsAt, o.EndTime)
	if e != nil {
		return e
	}
	o.EndTime = end
	return s.Store.PutDisplayEntitlementTx(c, t, o)
}
