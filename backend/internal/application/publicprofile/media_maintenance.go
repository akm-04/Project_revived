package publicprofile

import (
	"context"
	"gxb.local/backend/v2/internal/application/i5"
	blob "gxb.local/backend/v2/internal/application/profileasset"
	asset "gxb.local/backend/v2/internal/domain/profileasset"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// The inventory reader remains a KernelReceipt port, not PublicProfile SQL.
type MediaReceiptInventory interface {
	ListIdentitiesTx(context.Context, tx.Queryer, string, string, string) ([]receipt.Identity, error)
}
type JointMediaSnapshot struct {
	Format   string             `json:"format"`
	Media    MediaInventory     `json:"media"`
	Receipts []receipt.Receipt  `json:"receipts"`
	Blobs    []asset.Descriptor `json:"blobs"`
	Pins     []asset.Pin        `json:"pins"`
}
type MediaMaintenance struct {
	Service  MediaService
	Receipts MediaReceiptInventory
}

func (m MediaMaintenance) databaseSnapshot(c context.Context) (JointMediaSnapshot, error) {
	out := JointMediaSnapshot{Format: "I7B_JOINT_MEDIA_V1", Receipts: []receipt.Receipt{}, Blobs: []asset.Descriptor{}, Pins: []asset.Pin{}}
	s := m.Service
	if m.Receipts == nil || s.Media == nil || s.Commands.Reads.DB == nil || s.Commands.Roots.Store == nil || s.Commands.Receipts == nil || s.Commands.Content == nil {
		return out, ErrInvalidState
	}
	o, e := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if e != nil {
		return out, e
	}
	res, e := s.Commands.Reads.Run(c, o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		out.Media, e = s.Media.InventoryMediaTx(c, sc.Tx)
		if e != nil {
			return e
		}
		seen := map[string]bool{}
		after := ""
		for {
			ids, e := m.Receipts.ListIdentitiesTx(c, sc.Tx, "public-profile", MediaCommand, after)
			if e != nil {
				return e
			}
			if len(ids) == 0 {
				break
			}
			for _, id := range ids {
				if seen[id.SemanticKey] {
					return ErrConflict
				}
				r, ok, e := s.Commands.Receipts.FindTx(c, sc.Tx, id)
				if e != nil {
					return e
				}
				if !ok {
					return ErrConflict
				}
				if _, e = s.historyProof(c, sc.Tx, r); e != nil {
					return e
				}
				seen[id.SemanticKey] = true
				out.Receipts = append(out.Receipts, r)
			}
			after = ids[len(ids)-1].SemanticKey
		}
		history := map[string]MediaHistory{}
		for _, h := range out.Media.History {
			if h.Validate() != nil || history[h.Operation.String()].RootVersion != 0 || !seen[h.Operation.String()] {
				return ErrConflict
			}
			history[h.Operation.String()] = h
		}
		players := map[int64]bool{}
		for _, r := range out.Media.Current {
			h, ok := history[r.Operation.String()]
			if !ok || !r.PlayerID.Valid() || h.PlayerID != r.PlayerID || h.Reference.Operation != h.Operation || players[int64(r.PlayerID)] {
				return ErrConflict
			}
			players[int64(r.PlayerID)] = true
		}
		for _, h := range out.Media.History {
			if !players[int64(h.PlayerID)] {
				return ErrConflict
			}
		}
		return nil
	})
	if e != nil {
		return out, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return out, ErrConflict
	}
	return out, nil
}

// EX excludes every cooperating publication and GET permit. Canonical reads
// finish before any blob I/O. No receipt absence is treated as abort, even while
// a publisher process is gone: its DB transaction might still become visible.
func (m MediaMaintenance) WithSnapshot(c context.Context, fn func(JointMediaSnapshot, blob.Maintenance) error) error {
	if m.Service.Blobs == nil || fn == nil {
		return ErrInvalidState
	}
	return m.Service.Blobs.WithMaintenance(c, func(p blob.Maintenance) error {
		snap, e := m.databaseSnapshot(c)
		if e != nil {
			return e
		}
		if e = p.Inventory(func(d asset.Descriptor) error { snap.Blobs = append(snap.Blobs, d); return nil }, func(pin asset.Pin) error { snap.Pins = append(snap.Pins, pin); return nil }); e != nil {
			return e
		}
		byHash := map[string]asset.Descriptor{}
		for _, d := range snap.Blobs {
			if prior, ok := byHash[d.SHA256]; ok && prior != d {
				return asset.ErrIntegrity
			}
			byHash[d.SHA256] = d
		}
		for _, h := range snap.Media.History {
			if byHash[h.Reference.Asset.SHA256] != h.Reference.Asset {
				return asset.ErrIntegrity
			}
		}
		for _, pin := range snap.Pins {
			if byHash[pin.Asset.SHA256] != pin.Asset {
				return asset.ErrIntegrity
			}
		}
		return fn(snap, p)
	})
}
func (m MediaMaintenance) Validate(c context.Context) error {
	return m.WithSnapshot(c, func(JointMediaSnapshot, blob.Maintenance) error { return nil })
}

type MediaGCResult struct{ Deleted, ResolvedPins, UnknownPins int }

func (m MediaMaintenance) Collect(c context.Context) (out MediaGCResult, err error) {
	err = m.WithSnapshot(c, func(s JointMediaSnapshot, p blob.Maintenance) error {
		retained := map[string]bool{}
		terminal := map[string]MediaResult{}
		for _, h := range s.Media.History {
			retained[h.Reference.Asset.SHA256] = true
		}
		for _, r := range s.Receipts {
			v, e := decodeMediaResult(r)
			if e != nil {
				return e
			}
			terminal[v.History.Operation.String()] = v
			retained[v.History.Reference.Asset.SHA256] = true
		}
		for _, pin := range s.Pins {
			if v, ok := terminal[pin.Reservation.Operation.String()]; ok {
				if v.History.PlayerID != pin.Reservation.Actor || v.History.Server != pin.Reservation.Server || v.History.Reference.Asset != pin.Asset {
					return asset.ErrIntegrity
				}
				if e := p.ResolvePin(pin, asset.VerifiedCommit); e != nil {
					return e
				}
				out.ResolvedPins++
			} else {
				retained[pin.Asset.SHA256] = true
				out.UnknownPins++
			}
		}
		for _, d := range s.Blobs {
			if !retained[d.SHA256] {
				if e := p.Delete(d); e != nil {
					return e
				}
				out.Deleted++
			}
		}
		return p.CleanStaging()
	})
	return out, err
}

// SnapshotDatabase is the typed, read-only side of offline export validation.
// It returns only after its coherent caller scope has ended; it performs no I/O
// against ProfileAssetStore and never claims a live joint snapshot.
func (m MediaMaintenance) SnapshotDatabase(c context.Context) (JointMediaSnapshot, error) {
	return m.databaseSnapshot(c)
}
