package i5

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// AwakeningEquipmentPermit binds the prelocked mission occurrence to one source special item.
type AwakeningEquipmentPermit struct {
	player   identity.PlayerID
	root     objective.AwakeRoot
	instance objective.AwakeInstance
	item     int64
}

func (p *AwakeningEquipmentPermit) ItemID() int64  { return p.item }
func (p *AwakeningEquipmentPermit) Blood() bool    { return p.instance.Type == 2 }
func (p *AwakeningEquipmentPermit) Complete() bool { return p.instance.Complete }

type AwakeningEquipmentPort interface {
	PrepareAwakeningEquipmentTx(context.Context, tx.Tx, identity.PlayerID, int64, int64, int64, int64, string) (*AwakeningEquipmentPermit, error)
	CommitAwakeningEquipmentTx(context.Context, tx.Tx, *AwakeningEquipmentPermit) (map[string]any, error)
}

func (s Service) PrepareAwakeningEquipmentTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, owner, table, kind, baseItem int64, revision string) (*AwakeningEquipmentPermit, error) {
	if s.awakeningAvailable() != nil || t == nil || !pid.Valid() || owner <= 0 || table <= 0 || baseItem <= 0 || kind != 1 && kind != 3 {
		return nil, objective.ErrAwakeningRefused
	}
	root, e := s.Awakening.Store.LockAwakeningTx(ctx, t, pid)
	if e != nil {
		return nil, e
	}
	for _, a := range root.Active {
		if a.Mission == 0 || a.OwnerID != owner || kind == 3 && a.Type != 3 || kind == 1 && a.Type == 3 {
			continue
		}
		// Equipment is a new operation and must use the same content mapping as its active occurrence.
		if a.Revision != revision {
			return nil, objective.ErrAwakeningRefused
		}
		c, e := s.Awakening.Content.AwakeningCatalogTx(ctx, t, a.Revision)
		if e != nil {
			return nil, e
		}
		d, ok := c.Definition(a.Mission)
		if !ok || d.Stage != 1 || d.Before != table {
			continue
		}
		matches := d.Item == baseItem
		if a.Type == 2 {
			matches = false
			for _, ordinary := range c.Definitions {
				if ordinary.Type == 1 && ordinary.Stage == 1 && ordinary.After == d.Before && ordinary.Item == baseItem {
					matches = true
					break
				}
			}
		}
		if !matches {
			return nil, objective.ErrAwakeningRefused
		}
		return &AwakeningEquipmentPermit{player: pid, root: root, instance: a, item: d.Item}, nil
	}
	return nil, objective.ErrAwakeningRefused
}
func (s Service) CommitAwakeningEquipmentTx(ctx context.Context, t tx.Tx, p *AwakeningEquipmentPermit) (map[string]any, error) {
	if p == nil || t == nil || p.instance.Validate() != nil || !p.player.Valid() || p.item <= 0 || p.instance.Complete {
		return nil, objective.ErrAwakeningRefused
	}
	root := p.root
	old := root.Version
	if e := root.Complete(p.instance.Type, p.instance.Mission, p.instance.Generation, 1); e != nil {
		return nil, e
	}
	root.Version++
	if e := s.Awakening.Store.SaveAwakeningTx(ctx, t, p.player, root, old); e != nil {
		return nil, e
	}
	body := map[string]any{objective.AwakeChannel(p.instance.Type): []map[string]any{root.Active[p.instance.Type-1].Wire(true)}}
	if err := s.awakeningRedmarksTx(ctx, t, p.player, p.instance.Revision, body); err != nil {
		return nil, err
	}
	return body, nil
}
