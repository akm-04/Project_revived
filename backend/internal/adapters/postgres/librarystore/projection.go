package librarystore

import (
	"context"
	app "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// BootstrapProjection replaces the source-consumed relationship/collection facts in key836;
// the whole 836 body comes from the same read the explicit refresh serves.
type BootstrapProjection struct{ Service app.Service }

// libraryOverlayFields are the 836 fields this contributor owns; Claims and the
// overlay iterate the same list so declared ownership cannot drift from writes.
var libraryOverlayFields = []string{"library_infos", "library_talk_infos", "library_cg_infos", "library_bg_infos"}

func (BootstrapProjection) Name() string { return "i7c2b.library-input-bootstrap" }
func (BootstrapProjection) Claims() []string {
	claims := make([]string, len(libraryOverlayFields))
	for i, field := range libraryOverlayFields {
		claims[i] = "836." + field
	}
	return claims
}
func (p BootstrapProjection) OverlayMID1(ctx context.Context, q tx.Queryer, a identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	rev, active, e := p.Service.Content.HeroCoreActiveTx(ctx, q)
	if e != nil {
		return e
	}
	if !active {
		return nil
	}
	active, e = p.Service.Content.LibraryInputsRevisionTx(ctx, q, rev)
	if e != nil {
		return e
	}
	if !active {
		return nil
	}
	var body map[string]any
	if e = p.Service.ReadBodyTx(ctx, q, a, rev, at, 836, 0, &body); e != nil {
		return e
	}
	existing, ok := detail["836"].(map[string]any)
	if !ok {
		return app.ErrProof
	}
	for _, field := range libraryOverlayFields {
		existing[field] = body[field]
	}
	return nil
}
