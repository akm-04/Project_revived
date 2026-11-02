//go:build postgres

package playerdisplay_test

import (
	"context"
	"sync"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// pvpFights counts the PVP_FIGHT facts a PK mode hands to the objective fact port, per attacker (I9-4-PVP-106).
// A fact recorded in a transaction that later rolls back is still counted, so an exact count also catches that.
type pvpFights struct {
	i5.ObjectiveFacts
	mutex sync.Mutex
	count map[identity.PlayerID]int64
}

func countPVPFights(port i5.ObjectiveFacts) *pvpFights {
	return &pvpFights{ObjectiveFacts: port, count: map[identity.PlayerID]int64{}}
}

func (p *pvpFights) RecordTx(c context.Context, t tx.Tx, o operation.Context, facts ...objective.Fact) error {
	if err := p.ObjectiveFacts.RecordTx(c, t, o, facts...); err != nil {
		return err
	}
	p.mutex.Lock()
	defer p.mutex.Unlock()
	for _, fact := range facts {
		if fact.Kind == objective.PVPFightKind {
			p.count[fact.PlayerID] += fact.Delta
		}
	}
	return nil
}

func (p *pvpFights) of(player identity.PlayerID) int64 {
	p.mutex.Lock()
	defer p.mutex.Unlock()
	return p.count[player]
}
