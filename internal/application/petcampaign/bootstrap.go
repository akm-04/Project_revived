package petcampaign

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	d "gxb.local/backend/v2/internal/domain/petcampaign"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (Mode) Name() string     { return "PetCampaign" }
func (Mode) Claims() []string { return []string{"822"} }
func (s Mode) OverlayMID1(c context.Context, q tx.Queryer, a identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	r, found, e := s.Store.ReadTx(c, q, a.PlayerID)
	if e != nil {
		return e
	}
	if !found {
		r = d.New(modes.Day(at), at.Unix())
	} else {
		r.Normalize(modes.Day(at), at.Unix())
	}
	detail["822"] = r.Normal()
	return nil
}
