package i5

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// These ranks are the frozen Wave-A child-resource suffix. R5 extends the
// previously sealed 610/700..722 order with typed function-state and I4-owned
// directory projection locks. Same-rank identities are still canonicalized by
// lockkey.Compare/CanonicalDedup.
const (
	grantLockRankMailNamespace uint16 = 610
	grantLockRankEconomyOwner  uint16 = 700
	grantLockRankProgression   uint16 = 710
	grantLockRankScalar        uint16 = 720
	grantLockRankTemporal      uint16 = 721
	grantLockRankStack         uint16 = 722
	grantLockRankFunctionState uint16 = 730
	grantLockRankDirectory     uint16 = 740
)

type grantPreparedLine struct {
	Line    grant.Line
	Policy  ResourcePolicy
	Ordinal int
}

type grantLockKind uint8

const (
	grantLockPartnerEntity grantLockKind = iota + 1
	grantLockMailNamespace
	grantLockEconomyOwner
	grantLockProgression
	grantLockScalar
	grantLockTemporal
	grantLockStack
	grantLockFunctionState
	grantLockDirectory
	grantLockSpirit
)

type grantLockRequirement struct {
	Key         lockkey.Key
	Kind        grantLockKind
	ResourceKey string
	ItemID      int64
	Namespace   mail.Namespace
}

type grantPreflight struct {
	Lines             []grantPreparedLine
	Locks             []grantLockRequirement
	ProgressionPolicy *player.ProgressionPolicy
	FunctionPolicy    *FunctionGatePolicy
	EnergyDescriptor  *TemporalDescriptor
	PetStarterPolicy  *PetStarterPolicy
	Partner           *partnerEntityPrepared
	Spirit            *spiritPrepared
}

type grantPreflightOptions struct {
	AllowOverflowMail bool
	ForceProgression  bool
}

func makeGrantKey(rank uint16, owner string, id lockkey.Identity) (lockkey.Key, error) {
	return lockkey.New(rank, owner, id)
}

func grantChildIdentity(pid identity.PlayerID, suffix string) lockkey.Identity {
	return lockkey.String(fmt.Sprintf("%d:%s", int64(pid), suffix))
}

func appendGrantLock(reqs *[]grantLockRequirement, rank uint16, owner string, id lockkey.Identity, kind grantLockKind, resource string, item int64, ns mail.Namespace) error {
	k, err := makeGrantKey(rank, owner, id)
	if err != nil {
		return err
	}
	*reqs = append(*reqs, grantLockRequirement{Key: k, Kind: kind, ResourceKey: resource, ItemID: item, Namespace: ns})
	return nil
}
func canonicalGrantLockRequirements(reqs []grantLockRequirement) ([]grantLockRequirement, error) {
	keys := make([]lockkey.Key, 0, len(reqs))
	for _, r := range reqs {
		keys = append(keys, r.Key)
	}
	canonical, err := lockkey.CanonicalDedup(keys)
	if err != nil {
		return nil, err
	}
	out := make([]grantLockRequirement, 0, len(canonical))
	for _, key := range canonical {
		found := false
		for _, r := range reqs {
			if lockkey.Compare(key, r.Key) == 0 {
				out = append(out, r)
				found = true
				break
			}
		}
		if !found {
			return nil, errors.New("canonical grant lock lost requirement")
		}
	}
	return out, nil
}

func (s Service) preflightGrantTx(ctx context.Context, t tx.Tx, plan grant.Plan, contentRevision string, opts grantPreflightOptions, nowTime time.Time) (grantPreflight, error) {
	if nowTime.IsZero() {
		return grantPreflight{}, errors.New("grant preflight requires operation time")
	}
	if err := plan.Validate(); err != nil {
		return grantPreflight{}, err
	}

	out := grantPreflight{Lines: make([]grantPreparedLine, 0, len(plan.Lines))}
	reqs := make([]grantLockRequirement, 0, 4+len(plan.Lines)*3)
	needsEconomyOwner := false
	needsMailCounter := false
	needsProgression := opts.ForceProgression
	needsFunctionState := false
	needsDirectory := false

	requireContent := func() error {
		if s.Content == nil {
			return errors.New("I5 content runtime unavailable")
		}
		return nil
	}
	loadProgression := func() (*player.ProgressionPolicy, error) {
		if out.ProgressionPolicy != nil {
			return out.ProgressionPolicy, nil
		}
		if err := requireContent(); err != nil {
			return nil, err
		}
		p, err := s.Content.ResolveProgressionPolicyTx(ctx, t, contentRevision)
		if err != nil {
			return nil, err
		}
		out.ProgressionPolicy = &p
		return &p, nil
	}

	for ordinal, line := range plan.Lines {
		if line.Kind == grant.PartnerEntity {
			// Partner/entity content and ownership belong to the typed Character
			// provider. Do not force the line through the fungible I5 resource
			// catalog: the accepted catalog intentionally has no PARTNER_ENTITY
			// resource class.
			out.Lines = append(out.Lines, grantPreparedLine{Line: line, Ordinal: ordinal})
			continue
		}
		if line.Kind == grant.SpecializedDomain {
			if line.Domain != "spirit" || line.ResourceKey != "" || line.ItemID <= 0 {
				return grantPreflight{}, ErrUnsupportedGrantDestination
			}
			out.Lines = append(out.Lines, grantPreparedLine{Line: line, Ordinal: ordinal})
			continue
		}
		if err := requireContent(); err != nil {
			return grantPreflight{}, err
		}

		var policy ResourcePolicy
		var err error
		switch line.Kind {
		case grant.Temporal:
			state, exists, readErr := s.Store.ReadTemporalTx(ctx, t, plan.PlayerID, line.ResourceKey)
			if readErr != nil {
				return grantPreflight{}, readErr
			}
			if !exists {
				return grantPreflight{}, economy.ErrUnknownResource
			}
			if state.ContentRevision == "" {
				policy, err = s.Store.ResolveLegacyTemporalPolicyTx(ctx, t, line.ResourceKey, state.PolicyVersion)
			} else {
				if state.ContentRevision != contentRevision {
					return grantPreflight{}, ErrContentRevisionConflict
				}
				policy, err = s.Content.ResolveResourceTx(ctx, t, state.ContentRevision, line)
			}
		default:
			policy, err = s.Content.ResolveResourceTx(ctx, t, contentRevision, line)
		}
		if err != nil {
			return grantPreflight{}, err
		}
		if policy.Kind != line.Kind {
			return grantPreflight{}, economy.ErrUnknownResource
		}

		switch line.Kind {
		case grant.ScalarCurrency:
			needsEconomyOwner = true
			if err := appendGrantLock(&reqs, grantLockRankScalar, "i5.scalar", grantChildIdentity(plan.PlayerID, line.ResourceKey), grantLockScalar, line.ResourceKey, 0, 0); err != nil {
				return grantPreflight{}, err
			}
		case grant.Temporal:
			needsEconomyOwner = true
			if policy.Temporal == nil && policy.Descriptor == nil {
				return grantPreflight{}, economy.ErrInvalidTemporalPolicy
			}
			if policy.Descriptor != nil && policy.Descriptor.CapRule == "PLAYER_LEVEL_ENERGY" {
				if _, err := loadProgression(); err != nil {
					return grantPreflight{}, err
				}
				needsProgression = true
			}
			if err := appendGrantLock(&reqs, grantLockRankTemporal, "i5.temporal", grantChildIdentity(plan.PlayerID, line.ResourceKey), grantLockTemporal, line.ResourceKey, 0, 0); err != nil {
				return grantPreflight{}, err
			}
		case grant.StackItem:
			needsEconomyOwner = true
			if policy.Stack == nil {
				return grantPreflight{}, economy.ErrUnknownResource
			}
			if err := appendGrantLock(&reqs, grantLockRankStack, "i5.stack", grantChildIdentity(plan.PlayerID, fmt.Sprintf("%d", line.ItemID)), grantLockStack, "", line.ItemID, 0); err != nil {
				return grantPreflight{}, err
			}
			if opts.AllowOverflowMail && policy.Stack.OverflowToMail {
				needsMailCounter = true
			}
		case grant.PlayerExp:
			needsEconomyOwner = true
			needsProgression = true
			needsFunctionState = true
			needsDirectory = true
			progressionPolicy, err := loadProgression()
			if err != nil {
				return grantPreflight{}, err
			}
			_ = progressionPolicy
			if out.FunctionPolicy == nil {
				fp, err := s.Content.ResolveFunctionGatePolicyTx(ctx, t, contentRevision)
				if err != nil {
					return grantPreflight{}, err
				}
				out.FunctionPolicy = &fp
			}
			if out.PetStarterPolicy == nil {
				needsStarter := false
				for _, gate := range out.FunctionPolicy.Gates {
					if gate.AnnouncementCapability == "PET_STARTER_CA3" {
						needsStarter = true
						break
					}
				}
				if needsStarter {
					sp, err := s.Content.ResolvePetStarterPolicyTx(ctx, t, contentRevision)
					if err != nil {
						return grantPreflight{}, err
					}
					if sp.StarterEggItemID <= 0 {
						return grantPreflight{}, errors.New("invalid Pet starter policy")
					}
					line := grant.Line{Kind: grant.StackItem, ItemID: sp.StarterEggItemID, Amount: 1}
					rp, err := s.Content.ResolveResourceTx(ctx, t, contentRevision, line)
					if err != nil || rp.Stack == nil {
						if err == nil {
							err = economy.ErrUnknownResource
						}
						return grantPreflight{}, err
					}
					out.PetStarterPolicy = &sp
					needsEconomyOwner = true
					if err := appendGrantLock(&reqs, grantLockRankStack, "i5.stack", grantChildIdentity(plan.PlayerID, fmt.Sprintf("%d", sp.StarterEggItemID)), grantLockStack, "", sp.StarterEggItemID, 0); err != nil {
						return grantPreflight{}, err
					}
				}
			}
			if s.Functions == nil || s.Directory == nil {
				return grantPreflight{}, errors.New("R5 progression owner ports unavailable")
			}
			energyLine := grant.Line{Kind: grant.Temporal, ResourceKey: "energy", Amount: 1}
			energyPolicy, err := s.Content.ResolveResourceTx(ctx, t, contentRevision, energyLine)
			if err != nil {
				return grantPreflight{}, err
			}
			if energyPolicy.Descriptor == nil || energyPolicy.Descriptor.CapRule != "PLAYER_LEVEL_ENERGY" {
				return grantPreflight{}, economy.ErrInvalidTemporalPolicy
			}
			out.EnergyDescriptor = energyPolicy.Descriptor
			energyState, exists, err := s.Store.ReadTemporalTx(ctx, t, plan.PlayerID, "energy")
			if err != nil {
				return grantPreflight{}, err
			}
			if !exists {
				return grantPreflight{}, economy.ErrUnknownResource
			}
			if energyState.ContentRevision == "" || energyState.ContentRevision != contentRevision {
				return grantPreflight{}, ErrContentRevisionConflict
			}
			if err := appendGrantLock(&reqs, grantLockRankTemporal, "i5.temporal", grantChildIdentity(plan.PlayerID, "energy"), grantLockTemporal, "energy", 0, 0); err != nil {
				return grantPreflight{}, err
			}
		default:
			return grantPreflight{}, economy.ErrUnknownResource
		}
		out.Lines = append(out.Lines, grantPreparedLine{Line: line, Policy: policy, Ordinal: ordinal})
	}

	batch, err := partnerEntityBatchForPlan(plan, contentRevision)
	if err != nil {
		return grantPreflight{}, err
	}
	if len(batch.Lines) > 0 {
		if s.PartnerEntities == nil {
			return grantPreflight{}, ErrUnsupportedGrantDestination
		}
		providerID, providerRevision := s.PartnerEntities.ProviderID(), s.PartnerEntities.ProviderRevision()
		if err := validatePartnerProviderIdentity(providerID, providerRevision); err != nil {
			return grantPreflight{}, err
		}
		prepared, err := s.PartnerEntities.PreflightPartnerEntityBatchTx(ctx, t, batch)
		if err != nil {
			return grantPreflight{}, err
		}
		prepared.Locks, err = canonicalPartnerLocks(prepared.Locks)
		if err != nil {
			return grantPreflight{}, err
		}
		out.Partner = &partnerEntityPrepared{Batch: batch, Preflight: prepared, ProviderID: providerID, ProviderRevision: providerRevision}
		for _, k := range prepared.Locks {
			reqs = append(reqs, grantLockRequirement{Key: k, Kind: grantLockPartnerEntity})
		}
	}

	sb, err := spiritBatchForPlan(plan, contentRevision)
	if err != nil {
		return grantPreflight{}, err
	}
	if len(sb.Lines) > 0 {
		if s.Spirits == nil {
			return grantPreflight{}, ErrUnsupportedGrantDestination
		}
		id, rev := s.Spirits.ProviderID(), s.Spirits.ProviderRevision()
		if err := validatePartnerProviderIdentity(id, rev); err != nil {
			return grantPreflight{}, err
		}
		prepared, err := s.Spirits.PreflightSpiritBatchTx(ctx, t, sb)
		if err != nil {
			return grantPreflight{}, err
		}
		prepared.Locks, err = canonicalPartnerLocks(prepared.Locks)
		if err != nil {
			return grantPreflight{}, err
		}
		out.Spirit = &spiritPrepared{Batch: sb, Preflight: prepared, ProviderID: id, ProviderRevision: rev}
		for _, k := range prepared.Locks {
			reqs = append(reqs, grantLockRequirement{Key: k, Kind: grantLockSpirit})
		}
	}

	if needsMailCounter {
		if err := appendGrantLock(&reqs, grantLockRankMailNamespace, "i5.mail-namespace", grantChildIdentity(plan.PlayerID, mail.Normal.String()), grantLockMailNamespace, "", 0, mail.Normal); err != nil {
			return grantPreflight{}, err
		}
	}
	if needsEconomyOwner {
		if err := appendGrantLock(&reqs, grantLockRankEconomyOwner, "i5.economy-owner", lockkey.Int64(int64(plan.PlayerID)), grantLockEconomyOwner, "", 0, 0); err != nil {
			return grantPreflight{}, err
		}
	}
	if needsProgression {
		if err := appendGrantLock(&reqs, grantLockRankProgression, "i5.progression", lockkey.Int64(int64(plan.PlayerID)), grantLockProgression, "", 0, 0); err != nil {
			return grantPreflight{}, err
		}
	}
	if needsFunctionState {
		if err := appendGrantLock(&reqs, grantLockRankFunctionState, "i5.function-state", lockkey.Int64(int64(plan.PlayerID)), grantLockFunctionState, "", 0, 0); err != nil {
			return grantPreflight{}, err
		}
	}
	if needsDirectory {
		if err := appendGrantLock(&reqs, grantLockRankDirectory, "i4.directory-level", lockkey.Int64(int64(plan.PlayerID)), grantLockDirectory, "", 0, 0); err != nil {
			return grantPreflight{}, err
		}
	}

	out.Locks, err = canonicalGrantLockRequirements(reqs)
	if err != nil {
		return grantPreflight{}, err
	}
	return out, nil
}

func (s Service) acquireGrantLocksTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, pf grantPreflight, now time.Time) error {
	if pf.Partner != nil {
		if s.PartnerEntities == nil {
			return errors.New("partner entity materializer disappeared after preflight")
		}
		if s.PartnerEntities.ProviderID() != pf.Partner.ProviderID || s.PartnerEntities.ProviderRevision() != pf.Partner.ProviderRevision {
			return errors.New("partner entity provider identity/revision changed after preflight")
		}
	}
	if pf.Spirit != nil && (s.Spirits == nil || s.Spirits.ProviderID() != pf.Spirit.ProviderID || s.Spirits.ProviderRevision() != pf.Spirit.ProviderRevision) {
		return errors.New("Spirit provider changed after preflight")
	}
	for _, r := range pf.Locks {
		switch r.Kind {
		case grantLockSpirit:
			if pf.Spirit == nil || s.Spirits == nil {
				return ErrUnsupportedGrantDestination
			}
			if err := s.Spirits.LockSpiritKeyTx(ctx, t, r.Key); err != nil {
				return err
			}
		case grantLockPartnerEntity:
			if pf.Partner == nil || s.PartnerEntities == nil {
				return errors.New("partner entity lock without prepared provider")
			}
			if err := s.PartnerEntities.LockPartnerEntityKeyTx(ctx, t, r.Key); err != nil {
				return err
			}
		case grantLockMailNamespace:
			if err := s.Store.LockMailNamespaceCounterTx(ctx, t, pid, r.Namespace); err != nil {
				return err
			}
		case grantLockEconomyOwner:
			if err := s.Store.LockEconomyOwnerTx(ctx, t, pid); err != nil {
				return err
			}
		case grantLockProgression:
			if _, err := s.Store.LockProgressionTx(ctx, t, pid); err != nil {
				return err
			}
		case grantLockScalar:
			if _, _, err := s.Store.LockScalarTx(ctx, t, pid, r.ResourceKey, now); err != nil {
				return err
			}
		case grantLockTemporal:
			if _, exists, err := s.Store.LockTemporalTx(ctx, t, pid, r.ResourceKey); err != nil {
				return err
			} else if !exists {
				return economy.ErrUnknownResource
			}
		case grantLockStack:
			if _, _, err := s.Store.LockStackTx(ctx, t, pid, r.ItemID, now); err != nil {
				return err
			}
		case grantLockFunctionState:
			if _, err := s.Store.LockFunctionStateTx(ctx, t, pid); err != nil {
				return err
			}
		case grantLockDirectory:
			if s.Directory == nil {
				return errors.New("directory level projection unavailable")
			}
			if _, err := s.Directory.LockTx(ctx, t, pid); err != nil {
				return err
			}
		default:
			return errors.New("unknown grant lock requirement")
		}
	}
	return nil
}
