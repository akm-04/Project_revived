package characterhero

import (
	"context"
	"encoding/binary"
	"encoding/json"
	"errors"
	"sort"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	HeroMaterializerProviderID       = "character.hero"
	HeroMaterializerProviderRevision = "ca2-3.v1"
	HeroMaterializationSchema        = "gxb.ca2.hero-materialization.v1"
)

type HeroMaterializer struct {
	FreshFacets HeroLocalFacetInitializer
	Store       AcquisitionStore
	Content     AcquisitionContent
	Capacity    CapacityAuthorizer
}

func (HeroMaterializer) ProviderID() string       { return HeroMaterializerProviderID }
func (HeroMaterializer) ProviderRevision() string { return HeroMaterializerProviderRevision }

func heroRootKey(pid identity.PlayerID) (lockkey.Key, error) {
	if !pid.Valid() {
		return lockkey.Key{}, errors.New("character hero materializer: invalid player")
	}
	return lockkey.New(character.HeroRootLockRank, "character.hero-root", lockkey.Int64(int64(pid)))
}

func playerIDFromHeroRootKey(k lockkey.Key) (identity.PlayerID, error) {
	if k.DomainRank != character.HeroRootLockRank || k.OwnerKind != "character.hero-root" || k.Identity.Kind != lockkey.IdentityInt64 {
		return 0, errors.New("character hero materializer: unexpected lock key")
	}
	raw := k.Identity.Raw()
	if len(raw) != 8 {
		return 0, errors.New("character hero materializer: invalid root identity")
	}
	v := int64(binary.BigEndian.Uint64(raw) ^ (uint64(1) << 63))
	pid := identity.PlayerID(v)
	if !pid.Valid() {
		return 0, errors.New("character hero materializer: invalid decoded player")
	}
	return pid, nil
}

func (m HeroMaterializer) PreflightPartnerEntityBatchTx(ctx context.Context, q tx.Queryer, batch appi5.PartnerEntityBatch) (appi5.PartnerEntityPreflight, error) {
	if m.Store == nil || m.Content == nil || q == nil || !batch.PlayerID.Valid() || len(batch.ContentRevision) != 64 || len(batch.Lines) == 0 {
		return appi5.PartnerEntityPreflight{}, errors.New("character hero materializer: invalid preflight")
	}
	seen := map[int64]struct{}{}
	for _, line := range batch.Lines {
		if line.Amount != 1 || line.ItemID <= 0 || line.Identity.Validate() != nil {
			return appi5.PartnerEntityPreflight{}, ErrHeroAcquisitionInvalid
		}
		t, err := m.Content.HeroAcquisitionByItemTx(ctx, q, batch.ContentRevision, line.ItemID)
		if err != nil {
			return appi5.PartnerEntityPreflight{}, err
		}
		if _, dup := seen[t.OriginTableID]; dup {
			return appi5.PartnerEntityPreflight{}, ErrHeroDuplicateOrigin
		}
		seen[t.OriginTableID] = struct{}{}
	}
	k, err := heroRootKey(batch.PlayerID)
	if err != nil {
		return appi5.PartnerEntityPreflight{}, err
	}
	return appi5.PartnerEntityPreflight{Locks: []lockkey.Key{k}}, nil
}

func (m HeroMaterializer) LockPartnerEntityKeyTx(ctx context.Context, t tx.Tx, k lockkey.Key) error {
	if m.Store == nil || t == nil {
		return errors.New("character hero materializer: incomplete lock")
	}
	pid, err := playerIDFromHeroRootKey(k)
	if err != nil {
		return err
	}
	_, err = m.Store.LockRootTx(ctx, t, pid)
	return err
}

func (m HeroMaterializer) ValidatePartnerEntityBatchLockedTx(ctx context.Context, t tx.Tx, batch appi5.PartnerEntityBatch, pf appi5.PartnerEntityPreflight) error {
	if m.Store == nil || m.Content == nil || m.Capacity == nil || t == nil || len(pf.Locks) != 1 {
		if m.Capacity == nil {
			return ErrHeroCapacityUnavailable
		}
		return errors.New("character hero materializer: invalid locked validation")
	}
	want, err := heroRootKey(batch.PlayerID)
	if err != nil || lockkey.Compare(want, pf.Locks[0]) != 0 {
		return errors.New("character hero materializer: preflight lock mismatch")
	}
	if _, err := m.Store.ReadRootTx(ctx, t, batch.PlayerID); err != nil {
		return err
	}
	heroes, err := m.Store.ListHeroesTx(ctx, t, batch.PlayerID)
	if err != nil {
		return err
	}
	owned := make(map[int64]struct{}, len(heroes))
	for _, h := range heroes {
		owned[h.OriginTableID] = struct{}{}
	}
	seen := map[int64]struct{}{}
	for _, line := range batch.Lines {
		if line.Amount != 1 {
			return ErrHeroAcquisitionInvalid
		}
		tmpl, err := m.Content.HeroAcquisitionByItemTx(ctx, t, batch.ContentRevision, line.ItemID)
		if err != nil {
			return err
		}
		if _, ok := owned[tmpl.OriginTableID]; ok {
			return ErrHeroDuplicateOrigin
		}
		if _, dup := seen[tmpl.OriginTableID]; dup {
			return ErrHeroDuplicateOrigin
		}
		seen[tmpl.OriginTableID] = struct{}{}
	}
	return m.Capacity.AuthorizeHeroAddition(batch.PlayerID, len(heroes), len(batch.Lines))
}

type heroMaterializationPayload struct {
	PartnerID     int64 `json:"partner_id"`
	TableID       int64 `json:"table_id"`
	OriginTableID int64 `json:"origin_table_id"`
}

func (m HeroMaterializer) MaterializePartnerEntityBatchTx(ctx context.Context, t tx.Tx, batch appi5.PartnerEntityBatch, pf appi5.PartnerEntityPreflight, op operation.Context) ([]appi5.PartnerEntityMaterialization, error) {
	if m.Store == nil || m.Content == nil || m.Capacity == nil || t == nil || op.StartedAt.IsZero() {
		if m.Capacity == nil {
			return nil, ErrHeroCapacityUnavailable
		}
		return nil, errors.New("character hero materializer: invalid apply")
	}
	if err := m.ValidatePartnerEntityBatchLockedTx(ctx, t, batch, pf); err != nil {
		return nil, err
	}
	root, err := m.Store.ReadRootTx(ctx, t, batch.PlayerID)
	if err != nil {
		return nil, err
	}
	lines := append([]appi5.PartnerEntityLine(nil), batch.Lines...)
	sort.Slice(lines, func(i, j int) bool { return lines[i].Identity.LineOrdinal < lines[j].Identity.LineOrdinal })
	out := make([]appi5.PartnerEntityMaterialization, 0, len(lines))
	for i, line := range lines {
		tmpl, err := m.Content.HeroAcquisitionByItemTx(ctx, t, batch.ContentRevision, line.ItemID)
		if err != nil {
			return nil, err
		}
		h, err := newHero(batch.PlayerID, root.NextPartnerID+int64(i), tmpl, tmpl.InitialStar, batch.ContentRevision, op)
		if err != nil {
			return nil, err
		}
		if err := insertFreshHero(ctx, t, m.Store, m.FreshFacets, h); err != nil {
			return nil, err
		}
		payload, err := json.Marshal(heroMaterializationPayload{PartnerID: h.PartnerID, TableID: h.TableID, OriginTableID: h.OriginTableID})
		if err != nil {
			return nil, err
		}
		out = append(out, appi5.PartnerEntityMaterialization{LineOrdinal: line.Identity.LineOrdinal, ResultSchema: HeroMaterializationSchema, ResultPayload: payload})
	}
	next, err := advanceRoot(root, len(lines), op)
	if err != nil {
		return nil, err
	}
	if err := m.Store.SaveRootAllocatorTx(ctx, t, next, root.StateVersion); err != nil {
		return nil, err
	}
	return out, nil
}

var _ appi5.PartnerEntityMaterializer = HeroMaterializer{}
