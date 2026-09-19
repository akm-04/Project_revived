package i5

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const PreservationMaxHeroColorPolicyRevision = "GXB1_PRESERVATION_MAX_HERO_COLOR_V1"
const PreservationMaxHeroColor int64 = 5

// MaxHeroColorPolicyProvider is PlayerProgression-owned preservation policy.
// The current provider is deliberately immutable and nonlocking. A future
// mutable/Open-Level implementation is a CA4-3B contract reopen trigger.
type MaxHeroColorPolicyProvider interface {
	MaxHeroColor() int64
	MaxHeroColorTx(context.Context, tx.Queryer, identity.PlayerID, operation.Context) (int64, error)
	MaxHeroColorPolicyRevision() string
}

// PreservationMaxHeroColorProvider is an explicitly versioned compatibility
// policy. Value 5 is not claimed as recovered original-server truth.
type PreservationMaxHeroColorProvider struct{}

func (PreservationMaxHeroColorProvider) MaxHeroColor() int64 { return PreservationMaxHeroColor }

func (PreservationMaxHeroColorProvider) MaxHeroColorPolicyRevision() string {
	return PreservationMaxHeroColorPolicyRevision
}

func (PreservationMaxHeroColorProvider) MaxHeroColorTx(_ context.Context, _ tx.Queryer, pid identity.PlayerID, op operation.Context) (int64, error) {
	if !pid.Valid() || op.ID.IsZero() || op.StartedAt.IsZero() {
		return 0, errors.New("i5 max Hero color policy: invalid operation context")
	}
	return PreservationMaxHeroColor, nil
}

var _ MaxHeroColorPolicyProvider = PreservationMaxHeroColorProvider{}
