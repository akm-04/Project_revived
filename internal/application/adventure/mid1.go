package adventure

import (
	"context"
	"errors"
	"time"

	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Name and Claims register 2416 as the login piggyback detail (C1).
func (s Mode) Name() string { return "adventure" }

func (s Mode) Claims() []string { return []string{"2416"} }

func (s Mode) OverlayMID1(c context.Context, q tx.Queryer, a identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	revision, err := s.Content.ActiveRevision(c, q)
	if err != nil {
		return err
	}
	catalog, err := s.Content.AdventureCatalogTx(c, q, revision)
	if err != nil {
		return err
	}
	if err = s.admit(c, q, a, catalog, at); err != nil {
		if errors.Is(err, d.ErrRefused) {
			detail["2416"] = map[string]any{"adventure_list": map[string]any{"list": map[string]any{}}}
			return nil
		}
		return err
	}
	body, err := s.listBody(c, q, a.PlayerID, at)
	if err != nil {
		return err
	}
	detail["2416"] = body
	return nil
}
