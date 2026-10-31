package worldboss

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	d "gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Mode) Name() string     { return "WorldBoss" }
func (Mode) Claims() []string { return []string{"624"} }

// OverlayMID1 projects the same 624 shape as Info without writing counters.
func (s Mode) OverlayMID1(c context.Context, q tx.Queryer, a identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	if q == nil || detail == nil || s.Store == nil {
		return d.ErrUnavailable
	}
	occurrence, found, err := s.Store.ReadOccurrenceTx(c, q, int64(a.LogicalServerID))
	if err != nil {
		return err
	}
	if !found {
		occurrence = d.Occurrence{LogicalServerID: int64(a.LogicalServerID), Generation: 1, CurrentBoss: d.FirstBossID}
	}
	player, found, err := s.Store.ReadPlayerTx(c, q, a.PlayerID)
	if err != nil {
		return err
	}
	if !found {
		player = d.Player{PlayerID: int64(a.PlayerID)}
	}
	player.Reset(modes.Day(at))
	rank, hurt, err := s.rankAndHurt(c, q, occurrence, a.PlayerID)
	if err != nil {
		return err
	}
	detail["624"] = infoBody(occurrence, player, rank, hurt)
	return nil
}
