package librarystore

import (
	"context"
	app "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// BootstrapProjection replaces only selected relationship facts in key836;
// unrelated frozen Library shell fields keep their inherited baseline meanings.
type BootstrapProjection struct{ Service app.Service }

func (BootstrapProjection) Name() string     { return "i7c2b.library-input-bootstrap" }
func (BootstrapProjection) Claims() []string { return []string{"836.library_infos"} }
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
	existing["library_infos"] = body["library_infos"]
	return nil
}
