// Package commerceprivilege owns narrow canonical manual privilege facts. I11
// owns authenticated operator transport. No public payment/admin route is added.
package commerceprivilege

import (
	"context"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store interface {
	ReadPrivilegeTx(context.Context, tx.Queryer, identity.PlayerID, bool) (d.State, bool, error)
	SavePrivilegeTx(context.Context, tx.Tx, int64, d.State) error
}
type Content interface {
	PrivilegeCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}

// Provider is shared by display and all existing VIP consumers. The old baseline
// is only a named compatibility result for untouched legacy state; it does not
// qualify cosmetic VIP. Known canonical facts always supersede that baseline.
type Provider struct {
	Store   Store
	Content Content
}

func (p Provider) snapshot(c context.Context, q tx.Queryer, pid identity.PlayerID, revision string, at time.Time) (d.Snapshot, bool, error) {
	var out d.Snapshot
	if p.Store == nil || p.Content == nil || q == nil || !pid.Valid() || at.IsZero() {
		return out, false, d.ErrUnavailable
	}
	s, ok, e := p.Store.ReadPrivilegeTx(c, q, pid, false)
	if e != nil || !ok {
		return out, ok, e
	}
	if s.Validate() != nil || s.PlayerID != pid || s.UpdatedAt.After(at) {
		return out, true, d.ErrConflict
	}
	catalog, e := p.Content.PrivilegeCatalogTx(c, q, s.ContentRevision)
	if e != nil {
		return out, true, e
	}
	if s.ValidateCatalog(catalog) != nil {
		return out, true, d.ErrConflict
	}
	cap, e := catalog.SkillCap(s.VIPLevel)
	if e != nil {
		return out, true, e
	}
	if revision == "" {
		revision = s.ContentRevision
	}
	out = d.Snapshot{State: s, ObservationRevision: revision, ObservedAt: at.UTC(), SkillPointCap: cap, ProviderRevision: d.ManualPolicy + "/" + s.ContentRevision}
	return out, true, out.Validate(pid, revision, at)
}
func (p Provider) ReadCosmeticPrivilegeTx(c context.Context, q tx.Queryer, pid identity.PlayerID, revision string, at time.Time) (d.Snapshot, error) {
	if p.Store == nil || p.Content == nil || q == nil || !pid.Valid() || at.IsZero() || !d.RevisionValid(revision) {
		return d.Snapshot{}, d.ErrUnavailable
	}
	if _, e := p.Content.PrivilegeCatalogTx(c, q, revision); e != nil {
		return d.Snapshot{}, e
	}
	out, ok, e := p.snapshot(c, q, pid, revision, at)
	if e != nil {
		return out, e
	}
	if !ok {
		return out, d.ErrUnavailable
	}
	return out, nil
}
func (p Provider) SnapshotTx(c context.Context, q tx.Queryer, pid identity.PlayerID, at time.Time) (i5.PrivilegeSnapshot, error) {
	out, ok, e := p.snapshot(c, q, pid, "", at)
	if e != nil {
		return i5.PrivilegeSnapshot{}, e
	}
	if !ok {
		return (i5.BaselinePrivilegeProvider{}).SnapshotTx(c, q, pid, at)
	}
	return i5.PrivilegeSnapshot{ProviderRevision: out.ProviderRevision, VIPLevel: out.State.VIPLevel, MonthlyPrivilegeActive: false, SkillPointNaturalCap: out.SkillPointCap}, nil
}

var _ i5.PrivilegeSnapshotProvider = Provider{}
