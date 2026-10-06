package playerpresentation

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/socialpresence"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

var ErrMissingPresentation = errors.New("required minimal player presentation missing")

// Projected is ephemeral response composition, never canonical copied state.
type Projected struct {
	Minimal  Minimal
	Presence socialpresence.Observation
}

func (p Projected) Validate(pid identity.PlayerID) error {
	if p.Minimal.PlayerID != pid || p.Presence.PlayerID != pid {
		return ErrMissingPresentation
	}
	if err := p.Minimal.Validate(); err != nil {
		return err
	}
	return p.Presence.Validate()
}

type Batch struct {
	ObservedAt time.Time
	Players    map[identity.PlayerID]Projected
}

// TxReader never begins/commits and must use the exact caller transaction.
// ObservedAt is response-only; it cannot replace gameplay DecisionAt.
type TxReader interface {
	ReadManyTx(context.Context, tx.Tx, []identity.PlayerID) (Batch, error)
}
