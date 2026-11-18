package achievementstore

import (
	"context"
	"time"

	app "gxb.local/backend/v2/internal/application/achievement"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// NoticeLoginReconciler consumes pending achievement notices inside the MID1
// transaction (C17), so the login reply is the last chance to show them once.
// The MID1 detail projection reads back exactly this delivery instant.
// shortcut: the login instant correlates the claim with the read-only detail
// projection; two logins in the same microsecond could show one popup twice.
// Add a delivery operation column if that ever matters.
type NoticeLoginReconciler struct{ Store Store }

func (NoticeLoginReconciler) Name() string { return "i9-11e.achievement-notices" }

func (r NoticeLoginReconciler) ReconcileCharacterLogin(c context.Context, t tx.Tx, a identity.ActorContext, _ operation.Context, at time.Time) error {
	if t == nil || !a.PlayerID.Valid() || at.IsZero() {
		return d.ErrUnavailable
	}
	return r.Store.MarkNoticesDeliveredTx(c, t, a.PlayerID, at)
}

// BootstrapProjection contributes MID1 detail "1304", the achievement ids of
// the notices this login consumed. It reads, never writes, the hydration
// snapshot; the claim already happened in the login transaction.
type BootstrapProjection struct {
	Store   Store
	Content app.Content
	Active  app.ActiveContent
}

func (BootstrapProjection) Name() string     { return "i9-11e.achievement-offline" }
func (BootstrapProjection) Claims() []string { return []string{"1304"} }

func (b BootstrapProjection) OverlayMID1(c context.Context, q tx.Queryer, a identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	if q == nil || detail == nil || !a.PlayerID.Valid() || b.Content == nil || b.Active == nil || at.IsZero() {
		return d.ErrUnavailable
	}
	ids, e := b.Store.NoticeIDsDeliveredAtTx(c, q, a.PlayerID, at)
	if e != nil || len(ids) == 0 {
		detail["1304"] = ids
		return e
	}
	revision, e := b.Active.ActiveRevision(c, q)
	if e != nil {
		return e
	}
	catalog, e := b.Content.AchievementCatalogTx(c, q, revision)
	if e != nil {
		return e
	}
	known := map[int64]d.Definition{}
	for _, row := range catalog.Rows {
		known[row.ID] = row
	}
	visible := make([]int64, 0, len(ids))
	for _, id := range ids {
		row, found := known[id]
		if found && row.Hidden == 0 {
			visible = append(visible, id)
		}
	}
	detail["1304"] = visible
	return nil
}

var (
	_ appboot.CharacterLoginReconciler = NoticeLoginReconciler{}
	_ appboot.MID1DetailContributor    = BootstrapProjection{}
)
