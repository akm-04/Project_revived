package i5

import (
	"context"
	"errors"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const ProvisionalPrivilegeProviderRevision = "PROVISIONAL_REPLACE_ON_COMMERCE_OWNER/v1"

type BaselinePrivilegeProvider struct{}

func (BaselinePrivilegeProvider) SnapshotTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (PrivilegeSnapshot, error) {
	return PrivilegeSnapshot{
		ProviderRevision:       ProvisionalPrivilegeProviderRevision,
		VIPLevel:               0,
		MonthlyPrivilegeActive: false,
		SkillPointNaturalCap:   10,
	}, nil
}

type NoFunctionAnnouncements struct{}

func (NoFunctionAnnouncements) ProviderRevision() string { return "r5.function-announcement.none.v1" }
func (NoFunctionAnnouncements) Announce(context.Context, identity.PlayerID, FunctionGatePolicy, []player.FunctionEligibility) ([]int64, error) {
	return nil, nil
}

type PetStarterFunctionAnnouncements struct{}

func (PetStarterFunctionAnnouncements) ProviderRevision() string {
	return "ca3.pet-starter.function-announcement.v1"
}
func (PetStarterFunctionAnnouncements) Announce(_ context.Context, _ identity.PlayerID, policy FunctionGatePolicy, eligible []player.FunctionEligibility) ([]int64, error) {
	capByID := make(map[int64]string, len(policy.Gates))
	for _, g := range policy.Gates {
		capByID[g.FunctionID] = g.AnnouncementCapability
	}
	out := make([]int64, 0, 1)
	for _, e := range eligible {
		switch capByID[e.FunctionID] {
		case "PET_STARTER_CA3":
			if e.FunctionID != 38 {
				return nil, errors.New("Pet starter capability attached to unexpected function")
			}
			out = append(out, e.FunctionID)
		case "NONE", "":
		default:
			return nil, errors.New("unsupported function announcement capability")
		}
	}
	return out, nil
}

func ResolveTemporalPolicyTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, d TemporalDescriptor, progression player.ProgressionPolicy, level int64, now time.Time, privileges PrivilegeSnapshotProvider) (economy.TemporalPolicy, string, error) {
	if d.Revision == "" || d.ResourceKey == "" || d.RegenEvery <= 0 || d.RegenAmount <= 0 {
		return economy.TemporalPolicy{}, "", economy.ErrInvalidTemporalPolicy
	}
	var cap int64
	providerRevision := d.Revision
	switch d.CapRule {
	case "STATIC":
		cap = d.StaticCap
	case "PLAYER_LEVEL_ENERGY":
		var err error
		cap, err = progression.EnergyCap(level)
		if err != nil {
			return economy.TemporalPolicy{}, "", err
		}
	case "VIP_PLUS_MONTHLY_PRIVILEGE":
		if privileges == nil {
			return economy.TemporalPolicy{}, "", errors.New("privilege snapshot provider unavailable")
		}
		snap, err := privileges.SnapshotTx(ctx, q, pid, now)
		if err != nil {
			return economy.TemporalPolicy{}, "", err
		}
		if snap.ProviderRevision == "" || snap.SkillPointNaturalCap < 0 {
			return economy.TemporalPolicy{}, "", errors.New("invalid privilege snapshot")
		}
		// The provisional R5 provider is deliberately baseline-only. Future
		// Commerce/VIP activation must replace it rather than silently teaching
		// this compatibility provider non-baseline entitlement truth.
		if snap.ProviderRevision == ProvisionalPrivilegeProviderRevision && (snap.VIPLevel != 0 || snap.MonthlyPrivilegeActive || snap.SkillPointNaturalCap != 10) {
			return economy.TemporalPolicy{}, "", errors.New("provisional privilege provider cannot represent non-baseline state")
		}
		cap = snap.SkillPointNaturalCap
		providerRevision = snap.ProviderRevision
	default:
		return economy.TemporalPolicy{}, "", economy.ErrInvalidTemporalPolicy
	}
	if cap < 0 {
		return economy.TemporalPolicy{}, "", economy.ErrInvalidTemporalPolicy
	}
	p := d.FixedPolicy(cap)
	if err := p.Validate(); err != nil {
		return economy.TemporalPolicy{}, "", err
	}
	return p, providerRevision, nil
}

func (s Service) resolveTemporalPolicyTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, d TemporalDescriptor, progression player.ProgressionPolicy, level int64, now time.Time) (economy.TemporalPolicy, string, error) {
	return ResolveTemporalPolicyTx(ctx, q, pid, d, progression, level, now, s.Privileges)
}

func pureLevelEligibility(policy FunctionGatePolicy, pid identity.PlayerID, level int64, now time.Time) ([]player.FunctionEligibility, error) {
	if policy.Revision == "" || !pid.Valid() || level < 1 || now.IsZero() {
		return nil, errors.New("invalid function eligibility input")
	}
	out := make([]player.FunctionEligibility, 0)
	for _, gate := range policy.Gates {
		if gate.FunctionID <= 0 || gate.SourceFactKey == "" || gate.RawOpenValue == "" {
			return nil, errors.New("invalid function gate")
		}
		if gate.GateKind != "PURE_LEVEL" {
			continue
		}
		if gate.RequiredLevel <= 0 {
			return nil, errors.New("invalid pure-level function gate")
		}
		if gate.RequiredLevel <= level {
			out = append(out, player.FunctionEligibility{
				PlayerID: pid, FunctionID: gate.FunctionID, ContentRevision: policy.Revision,
				SourceFactKey: gate.SourceFactKey, EligibleAt: now.UTC(),
			})
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].FunctionID < out[j].FunctionID })
	return out, nil
}

func temporalEffect(key string, before, after economy.TemporalState) GrantTemporalEffect {
	var anchor int64
	if after.RegenAnchorAt != nil {
		anchor = after.RegenAnchorAt.UTC().Unix()
	}
	return GrantTemporalEffect{ResourceKey: key, BeforeAmount: before.StoredAmount, AfterAmount: after.StoredAmount, AnchorUnix: anchor, PolicyVersion: after.PolicyVersion}
}
