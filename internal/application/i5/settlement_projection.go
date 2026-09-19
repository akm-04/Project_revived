package i5

import (
	"context"
	"errors"
	"sort"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// SettlementProjection is transient stock response state reconstructed from
// canonical owners after settlement/replay. It is deliberately not persisted in
// semantic receipts: replay must not resend historical absolute economy values.
type SettlementProjection struct {
	Economy        map[string]int64
	NewFunctionIDs []int64
	ExtraDrops     []Award
}

func (p SettlementProjection) Empty() bool {
	return len(p.Economy) == 0 && len(p.NewFunctionIDs) == 0 && len(p.ExtraDrops) == 0
}

func (s Service) projectSettlement(ctx context.Context, actor identity.ActorContext, grants []GrantResult, op operation.Context, recognizedReplay bool) (SettlementProjection, error) {
	if s.Store == nil || s.Content == nil || !actor.PlayerID.Valid() || op.StartedAt.IsZero() {
		return SettlementProjection{}, errors.New("settlement projection unavailable")
	}
	scalarKeys := map[string]struct{}{}
	temporalKeys := map[string]struct{}{}
	needProgression := false
	newFuncs := map[int64]struct{}{}
	extraDrops := []Award{}
	for _, g := range grants {
		if g.Effects != nil {
			if len(g.Effects.Progression) > 0 {
				needProgression = true
				temporalKeys["energy"] = struct{}{}
			}
			for _, e := range g.Effects.Temporal {
				if e.ResourceKey != "" {
					temporalKeys[e.ResourceKey] = struct{}{}
				}
			}
			if !recognizedReplay {
				for _, id := range g.Effects.NewFunctionIDs {
					if id > 0 {
						newFuncs[id] = struct{}{}
					}
				}
				extraDrops = append(extraDrops, g.Effects.ExtraDrops...)
			}
		}
		for _, a := range g.Awards {
			if a.ResourceKey == "" {
				continue
			}
			switch a.ResourceKey {
			case "exp":
				// Historical gxb.i5.grant.v1 PlayerExp receipts encoded EXP as
				// a named Award. That receipt is terminal historical truth: do
				// not synthesize R5 Energy/function effects, but do project the
				// current canonical progression owner rather than misclassifying
				// EXP as a scalar wallet.
				needProgression = true
				delete(scalarKeys, a.ResourceKey)
			case "energy", "spirit_energy", "skill_point", "invitation":
				temporalKeys[a.ResourceKey] = struct{}{}
				delete(scalarKeys, a.ResourceKey)
			default:
				if _, ok := temporalKeys[a.ResourceKey]; !ok {
					scalarKeys[a.ResourceKey] = struct{}{}
				}
			}
		}
	}
	if len(scalarKeys) == 0 && len(temporalKeys) == 0 && !needProgression && len(newFuncs) == 0 && len(extraDrops) == 0 {
		return SettlementProjection{}, nil
	}
	out := SettlementProjection{Economy: map[string]int64{}, ExtraDrops: append([]Award(nil), extraDrops...)}
	now := op.StartedAt.UTC()
	profile := s.profile()
	profile.Name = "I5_RESPONSE_PROJECTION"
	_, err := s.Runner.Run(ctx, op, profile, tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(txctx context.Context, scope tx.Scope) error {
		var prog player.Progression
		progLoaded := false
		loadProg := func() (player.Progression, error) {
			if progLoaded {
				return prog, nil
			}
			var err error
			prog, err = s.Store.ReadProgressionTx(txctx, scope.Tx, actor.PlayerID)
			if err != nil {
				return player.Progression{}, err
			}
			progLoaded = true
			return prog, nil
		}
		if needProgression {
			p, err := loadProg()
			if err != nil {
				return err
			}
			out.Economy["exp"], out.Economy["lev"] = p.Exp, p.Level
		}
		for key := range scalarKeys {
			b, exists, err := s.Store.ReadScalarTx(txctx, scope.Tx, actor.PlayerID, key)
			if err != nil {
				return err
			}
			if !exists {
				out.Economy[key] = 0
			} else {
				out.Economy[key] = b.Amount
			}
		}
		for key := range temporalKeys {
			st, exists, err := s.Store.ReadTemporalTx(txctx, scope.Tx, actor.PlayerID, key)
			if err != nil {
				return err
			}
			if !exists {
				return economy.ErrUnknownResource
			}
			var pol economy.TemporalPolicy
			if st.ContentRevision == "" {
				rp, err := s.Store.ResolveLegacyTemporalPolicyTx(txctx, scope.Tx, key, st.PolicyVersion)
				if err != nil || rp.Temporal == nil {
					if err == nil {
						err = economy.ErrUnknownResource
					}
					return err
				}
				pol = *rp.Temporal
			} else {
				line := grant.Line{Kind: grant.Temporal, ResourceKey: key, Amount: 1}
				rp, err := s.Content.ResolveResourceTx(txctx, scope.Tx, st.ContentRevision, line)
				if err != nil || rp.Descriptor == nil {
					if err == nil {
						err = economy.ErrUnknownResource
					}
					return err
				}
				pp, err := s.Content.ResolveProgressionPolicyTx(txctx, scope.Tx, st.ContentRevision)
				if err != nil {
					return err
				}
				level := int64(1)
				if rp.Descriptor.CapRule == "PLAYER_LEVEL_ENERGY" {
					p, err := loadProg()
					if err != nil {
						return err
					}
					level = p.Level
				}
				pol, _, err = ResolveTemporalPolicyTx(txctx, scope.Tx, actor.PlayerID, *rp.Descriptor, pp, level, now, s.Privileges)
				if err != nil {
					return err
				}
			}
			m, err := st.Materialize(now, pol)
			if err != nil {
				return err
			}
			out.Economy[key] = m.Amount
		}
		return nil
	})
	if err != nil {
		return SettlementProjection{}, err
	}
	if len(out.Economy) == 0 {
		out.Economy = nil
	}
	for id := range newFuncs {
		out.NewFunctionIDs = append(out.NewFunctionIDs, id)
	}
	sort.Slice(out.NewFunctionIDs, func(i, j int) bool { return out.NewFunctionIDs[i] < out.NewFunctionIDs[j] })
	return out, nil
}
