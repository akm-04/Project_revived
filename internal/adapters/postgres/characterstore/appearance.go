package characterstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterqueries"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Store) ListHeroSkinEntitlements(ctx context.Context, pid identity.PlayerID, partnerID int64) ([]character.HeroSkinEntitlement, error) {
	if s.Queryer == nil {
		return nil, errors.New("character store: nil Hero skin entitlement queryer")
	}
	return (Store{}).ListHeroSkinEntitlementsTx(ctx, s.Queryer, pid, partnerID)
}

func (s Store) ListHeroLIVEEntitlements(ctx context.Context, pid identity.PlayerID, partnerID int64) ([]character.HeroLIVEEntitlement, error) {
	if s.Queryer == nil {
		return nil, errors.New("character store: nil Hero LIVE entitlement queryer")
	}
	return (Store{}).ListHeroLIVEEntitlementsTx(ctx, s.Queryer, pid, partnerID)
}

func (s Store) ListPetStyleEntitlements(ctx context.Context, pid identity.PlayerID, petID int64) ([]character.PetStyleEntitlement, error) {
	if s.Queryer == nil {
		return nil, errors.New("character store: nil Pet style entitlement queryer")
	}
	return (Store{}).ListPetStyleEntitlementsTx(ctx, s.Queryer, pid, petID)
}

func (Store) ListHeroSkinEntitlementsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, partnerID int64) ([]character.HeroSkinEntitlement, error) {
	if q == nil || !pid.Valid() || partnerID <= 0 {
		return nil, errors.New("character store: invalid Hero skin entitlement list")
	}
	var raw string
	if err := q.QueryRow(ctx, characterqueries.ListHeroSkinEntitlements, int64(pid), partnerID).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []struct {
		ModelID   int64      `json:"model_id"`
		ExpiresAt *time.Time `json:"expires_at"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]character.HeroSkinEntitlement, 0, len(rows))
	for _, row := range rows {
		if row.ExpiresAt != nil {
			t := row.ExpiresAt.UTC()
			row.ExpiresAt = &t
		}
		e := character.HeroSkinEntitlement{PlayerID: pid, PartnerID: partnerID, ModelID: row.ModelID, ExpiresAt: row.ExpiresAt}
		if err := e.Validate(); err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, nil
}

func (Store) ListHeroLIVEEntitlementsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, partnerID int64) ([]character.HeroLIVEEntitlement, error) {
	if q == nil || !pid.Valid() || partnerID <= 0 {
		return nil, errors.New("character store: invalid Hero LIVE entitlement list")
	}
	var raw string
	if err := q.QueryRow(ctx, characterqueries.ListHeroLIVEEntitlements, int64(pid), partnerID).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []struct {
		ModelID int64 `json:"model_id"`
		IsShow  bool  `json:"is_show"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]character.HeroLIVEEntitlement, 0, len(rows))
	for _, row := range rows {
		e := character.HeroLIVEEntitlement{PlayerID: pid, PartnerID: partnerID, ModelID: row.ModelID, IsShow: row.IsShow}
		if err := e.Validate(); err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, nil
}

func (Store) ListPetStyleEntitlementsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, petID int64) ([]character.PetStyleEntitlement, error) {
	if q == nil || !pid.Valid() || petID <= 0 {
		return nil, errors.New("character store: invalid Pet style entitlement list")
	}
	var raw string
	if err := q.QueryRow(ctx, characterqueries.ListPetStyleEntitlements, int64(pid), petID).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []struct {
		StyleItemID int64 `json:"style_item_id"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]character.PetStyleEntitlement, 0, len(rows))
	for _, row := range rows {
		e := character.PetStyleEntitlement{PlayerID: pid, PetID: petID, StyleItemID: row.StyleItemID}
		if err := e.Validate(); err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, nil
}

func (Store) SaveHeroAppearanceSelectorsTx(ctx context.Context, t tx.Tx, h character.Hero, oldVersion int64) error {
	if t == nil || h.ValidatePersistent() != nil || oldVersion <= 0 || h.StateVersion != oldVersion+1 {
		return errors.New("character store: invalid Hero appearance selector update")
	}
	tag, err := t.Exec(ctx, characterqueries.SaveHeroAppearanceSelectors, int64(h.PlayerID), h.PartnerID, h.CurrentSkinID, h.IllusionSkinID, h.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Hero appearance selector update lost race")
	}
	return nil
}

func (Store) SaveHeroSkinEntitlementTx(ctx context.Context, t tx.Tx, h character.Hero, e character.HeroSkinEntitlement, oldVersion int64) error {
	if t == nil || h.ValidatePersistent() != nil || e.Validate() != nil || h.PlayerID != e.PlayerID || h.PartnerID != e.PartnerID || oldVersion <= 0 || h.StateVersion != oldVersion+1 {
		return errors.New("character store: invalid Hero skin entitlement update")
	}
	var expires any
	if e.ExpiresAt != nil {
		expires = e.ExpiresAt.UTC()
	}
	if _, err := t.Exec(ctx, characterqueries.UpsertHeroSkinEntitlement, int64(e.PlayerID), e.PartnerID, e.ModelID, expires); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, characterqueries.TouchHeroAppearanceVersion, int64(h.PlayerID), h.PartnerID, h.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Hero skin entitlement owner update lost race")
	}
	return nil
}

func (Store) SaveHeroLIVEEntitlementTx(ctx context.Context, t tx.Tx, h character.Hero, e character.HeroLIVEEntitlement, oldVersion int64) error {
	if t == nil || h.ValidatePersistent() != nil || e.Validate() != nil || h.PlayerID != e.PlayerID || h.PartnerID != e.PartnerID || oldVersion <= 0 || h.StateVersion != oldVersion+1 {
		return errors.New("character store: invalid Hero LIVE entitlement update")
	}
	if _, err := t.Exec(ctx, characterqueries.UpsertHeroLIVEEntitlement, int64(e.PlayerID), e.PartnerID, e.ModelID, e.IsShow); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, characterqueries.TouchHeroAppearanceVersion, int64(h.PlayerID), h.PartnerID, h.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Hero LIVE entitlement owner update lost race")
	}
	return nil
}

func (Store) SavePetActiveStyleTx(ctx context.Context, t tx.Tx, p character.Pet, oldVersion int64) error {
	if t == nil || p.ValidatePersistent() != nil || oldVersion <= 0 || p.StateVersion != oldVersion+1 {
		return errors.New("character store: invalid Pet active-style update")
	}
	tag, err := t.Exec(ctx, characterqueries.SavePetActiveStyle, int64(p.PlayerID), p.PetID, p.ActiveStyle, p.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Pet active-style update lost race")
	}
	return nil
}

func (Store) SavePetStyleEntitlementTx(ctx context.Context, t tx.Tx, p character.Pet, e character.PetStyleEntitlement, oldVersion int64) error {
	if t == nil || p.ValidatePersistent() != nil || e.Validate() != nil || p.PlayerID != e.PlayerID || p.PetID != e.PetID || oldVersion <= 0 || p.StateVersion != oldVersion+1 {
		return errors.New("character store: invalid Pet style entitlement update")
	}
	if _, err := t.Exec(ctx, characterqueries.InsertPetStyleEntitlement, int64(e.PlayerID), e.PetID, e.StyleItemID); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, characterqueries.TouchPetAppearanceVersion, int64(p.PlayerID), p.PetID, p.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Pet style entitlement owner update lost race")
	}
	return nil
}
