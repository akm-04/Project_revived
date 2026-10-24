package spirit

import (
	"context"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/spirit"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Service) ProviderID() string { return "spirit-generated-instance" }
func (s Service) ProviderRevision() string {
	if s.Mint == nil {
		return ""
	}
	return s.Mint.Revision()
}
func rootKey(p identity.PlayerID) (lockkey.Key, error) {
	return lockkey.New(d.RootLockRank, "spirit.root", lockkey.Int64(int64(p)))
}
func (s Service) PreflightSpiritBatchTx(c context.Context, q tx.Queryer, b i5.SpiritBatch) (i5.SpiritPreflight, error) {
	if s.Mint == nil || s.Mint.Revision() != d.ReconstructionPolicy {
		return i5.SpiritPreflight{}, ErrUnavailable
	}
	if !b.PlayerID.Valid() || len(b.ContentRevision) != 64 || len(b.Lines) == 0 {
		return i5.SpiritPreflight{}, d.ErrInvalid
	}
	cat, e := s.Content.SpiritCatalogTx(c, q, b.ContentRevision)
	if e != nil {
		return i5.SpiritPreflight{}, e
	}
	for _, l := range b.Lines {
		if l.Identity.Validate() != nil || l.Amount < 1 || l.Amount > d.MaxID {
			return i5.SpiritPreflight{}, d.ErrInvalid
		}
		if _, _, e = cat.ModelFor(l.ItemID); e != nil {
			return i5.SpiritPreflight{}, e
		}
	}
	k, e := rootKey(b.PlayerID)
	return i5.SpiritPreflight{Locks: []lockkey.Key{k}}, e
}
func (s Service) LockSpiritKeyTx(c context.Context, t tx.Tx, k lockkey.Key) error {
	if k.DomainRank != d.RootLockRank || k.OwnerKind != "spirit.root" || k.Identity.Kind != lockkey.IdentityInt64 || len(k.Identity.Raw()) != 8 {
		return d.ErrInvalid
	}
	p := identity.PlayerID(int64(binary.BigEndian.Uint64(k.Identity.Raw()) ^ (uint64(1) << 63)))
	_, e := s.Owner.LockRootTx(c, t, p)
	return e
}
func (s Service) ValidateSpiritBatchLockedTx(c context.Context, t tx.Tx, b i5.SpiritBatch, pf i5.SpiritPreflight) error {
	got, e := s.PreflightSpiritBatchTx(c, t, b)
	if e != nil {
		return e
	}
	if len(pf.Locks) != 1 || lockkey.Compare(got.Locks[0], pf.Locks[0]) != 0 {
		return d.ErrInvalid
	}
	r, e := s.Owner.ReadRootTx(c, t, b.PlayerID)
	if e != nil {
		return e
	}
	cat, e := s.Content.SpiritCatalogTx(c, t, b.ContentRevision)
	if e != nil {
		return e
	}
	if e = r.Facts.Validate(cat); e != nil {
		return e
	}
	remaining := d.MaxID - r.Facts.NextID
	for _, l := range b.Lines {
		if l.Amount > remaining {
			return d.ErrInvalid
		}
		remaining -= l.Amount
	}
	return nil
}
func (s Service) MaterializeSpiritBatchTx(c context.Context, t tx.Tx, b i5.SpiritBatch, pf i5.SpiritPreflight, op operation.Context) ([]i5.SpiritMaterialization, error) {
	if e := s.ValidateSpiritBatchLockedTx(c, t, b, pf); e != nil {
		return nil, e
	}
	r, e := s.Owner.ReadRootTx(c, t, b.PlayerID)
	if e != nil {
		return nil, e
	}
	if op.StartedAt.Before(r.UpdatedAt) {
		return nil, ErrStale
	}
	cat, e := s.Content.SpiritCatalogTx(c, t, b.ContentRevision)
	if e != nil {
		return nil, e
	}
	out := []i5.SpiritMaterialization{}
	for _, l := range b.Lines {
		rows := []map[string]any{}
		for i := int64(0); i < l.Amount; i++ {
			x, e := s.Mint.Generate(cat, l.ItemID, op, fmt.Sprintf("%s/%d/%d", l.Identity.GrantSemanticKey, l.Identity.LineOrdinal, i))
			if e != nil {
				return nil, e
			}
			x.ID = r.Facts.NextID
			r.Facts.NextID++
			if e = x.Validate(cat); e != nil {
				return nil, e
			}
			r.Facts.Instances[x.ID] = x
			wire, e := x.Wire(cat, 0, 0)
			if e != nil {
				return nil, e
			}
			rows = append(rows, wire)
		}
		raw, e := json.Marshal(map[string]any{"spirit_awards": rows, "policy": s.Mint.Revision()})
		if e != nil {
			return nil, e
		}
		out = append(out, i5.SpiritMaterialization{LineOrdinal: l.Identity.LineOrdinal, ResultSchema: "gxb.spirit.generated.v1", ResultPayload: raw})
	}
	if e = r.Facts.Validate(cat); e != nil {
		return nil, e
	}
	old := r.Version
	r.Version++
	r.UpdatedAt = op.StartedAt
	if e = s.Owner.SaveRootTx(c, t, r, old); e != nil {
		return nil, e
	}
	return out, nil
}

var _ i5.SpiritMaterializer = Service{}
