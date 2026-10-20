package playerdisplay

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TitleProgress is an owner's never-decreasing progress value and the owner
// state version it was read at.
type TitleProgress interface {
	TitleProgressTx(context.Context, tx.Queryer, identity.PlayerID, string, time.Time) (int64, int64, error)
}

// ProgressTitleOrigins proves the permanent condition titles of one
// title_system type from its owner's progress (C6_SELECTED_COSMETIC_ORIGINS_V1).
// Progress never decreases, so below the condition is a complete negative.
type ProgressTitleOrigins struct {
	Owner     string
	TitleType int64
	Content   Content
	Progress  TitleProgress
}

func (o ProgressTitleOrigins) ReadCatalogDisplayOriginsTx(c context.Context, q tx.Queryer, r CatalogOriginRequest) (CatalogOriginObservation, error) {
	out := CatalogOriginObservation{Request: r, Origins: []Origin{}}
	if q == nil || o.Content == nil || o.Progress == nil || !r.PlayerID.Valid() || r.Family != "title" || len(r.Revision) != 64 {
		return out, ErrUnavailable
	}
	catalog, e := o.Content.ReadPlayerDisplayCatalogTx(c, q, r.Revision)
	if e != nil {
		return out, e
	}
	row, ok := catalog.Find(r.Family, r.CatalogID)
	if !ok || row.Type != o.TitleType || row.Days != -1 || len(row.Condition) != 1 || row.Condition[0] <= 0 {
		return out, ErrConflict
	}
	progress, version, e := o.Progress.TitleProgressTx(c, q, r.PlayerID, r.Revision, r.ObservedAt)
	if e != nil {
		// An owner without facts for this player leaves the title unavailable, never ineligible.
		return out, errors.Join(ErrUnavailable, e)
	}
	if version < 1 {
		return out, ErrConflict
	}
	if progress >= row.Condition[0] {
		out.Origins = append(out.Origins, Origin{PlayerID: r.PlayerID, Key: fmt.Sprintf("%s:title:%d", o.Owner, r.CatalogID), Owner: o.Owner, Family: r.Family, CatalogID: r.CatalogID, Revision: r.Revision, StateVersion: version})
	}
	out.Qualified, out.CompleteHistory = true, true
	return out, nil
}

var _ CatalogExternalOrigins = ProgressTitleOrigins{}
