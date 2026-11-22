package events

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ClaimPolicyVersion is the grant policy identity of a MID 231 claim; the
// business key is occurrence + player + tier (I11A-2 E3).
const ClaimPolicyVersion = "I11A_EVENTS_CLAIM_V1"

// ClaimPeriodPermanent is the one claim-ledger period of every event tier
// claim, permanent or timed; settlement writes the same period (E4b decision 1).
const ClaimPeriodPermanent = "permanent"

// ErrClaimRejected is every permanent MID 231 refusal (EA-7). The dispatcher
// answers it 409 with the D5 unproven code, never a 200 body.
var ErrClaimRejected = errors.New("events: claim rejected")

func claimRejected(reason string) error {
	return fmt.Errorf("%w: %s", ErrClaimRejected, reason)
}

// ActorFence is the i5 actor fence (rank before the player root).
type ActorFence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

// LevelReader reads the actor's level through the caller's transaction.
type LevelReader interface {
	PlayerLevelTx(context.Context, tx.Queryer, identity.PlayerID) (int64, bool, error)
}

// GrantSettler is the i5 caller-transaction settlement seam.
type GrantSettler interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, appi5.GrantTxOptions) (appi5.GrantResult, error)
}

// ContentRevision pins the content policy version the claim grants under.
type ContentRevision interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
}

// HeroContent resolves a hero item to its acquisition template. The hero item
// id is the content's hero table id; the same read AwardStoryPartnerTx uses.
type HeroContent interface {
	HeroNormalSummonTx(context.Context, tx.Queryer, string, int64) (character.HeroNormalSummonPolicy, error)
}

// HeroOwner is the character owner's story-award seam (used by sign-in and the
// item box for exactly this award).
type HeroOwner interface {
	LockStoryRosterTx(context.Context, tx.Tx, identity.PlayerID) error
	OwnsOriginTx(context.Context, tx.Tx, identity.PlayerID, int64) (bool, error)
	AwardStoryPartnerTx(context.Context, tx.Tx, identity.PlayerID, int64, string, operation.Context) (character.Hero, *character.CollectionAdmissionProof, error)
}

// HeroFragments is the summon owner's duplicate conversion of an owned hero.
type HeroFragments interface {
	HeroFragmentsTx(context.Context, tx.Queryer, string, int64) ([2]int64, error)
}

// HeroWire projects a granted hero into the stock award entry.
type HeroWire func(character.Hero) (map[string]any, error)

// ClaimService serves MID 231: one generic TIERED_CLAIM path dispatching by
// archetype (I11A_EVENTS_V1 ruling 12, EA-3, EA-7).
type ClaimService struct {
	Runner      tx.Runner
	Store       Store
	Fence       ActorFence
	Players     playerroot.TxLocker
	Levels      LevelReader
	Grants      GrantSettler
	Content     ContentRevision
	HeroContent HeroContent
	Heroes      HeroOwner
	Fragments   HeroFragments
	HeroWire    HeroWire
}

// ClaimResult is the stock MID 231 reply. The client indexes only awards and
// each entry's table_id/item_num, plus is_partner/to_stone for hero entries
// (Activity1071.lua:190-193, SelectHeroGiftBagWindow.lua:203-207,
// SelfPlayer.lua:4366-4381).
type ClaimResult struct {
	Awards []map[string]any `json:"awards"`
}

func (s ClaimService) ready() bool {
	return s.Runner.DB != nil && s.Store != nil && s.Fence != nil && s.Players != nil &&
		s.Levels != nil && s.Grants != nil && s.Content != nil && s.HeroContent != nil &&
		s.Heroes != nil && s.Fragments != nil && s.HeroWire != nil
}

func claimProfile() tx.Profile {
	return tx.Profile{Name: "events-claim", AcquireTimeout: time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 10 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: 2 * time.Second, OperationTimeout: 20 * time.Second}
}

func claimRetry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 120 * time.Millisecond}
}

// Claim grants one tier of the server's active TIERED_CLAIM occurrence. The
// order is actor fence, player root 315, occurrence FOR SHARE 355, the
// character roster (only when the choice names a hero) and the i5 grant ranks
// 610+ (EA-9, EA-10). A repeat of the same command re-reads the stored reply.
func (s ClaimService) Claim(ctx context.Context, actor identity.ActorContext, op operation.Context, activityID, tierID int64, choiceIndex int) (ClaimResult, error) {
	if !s.ready() || !actor.PlayerID.Valid() || op.ID.IsZero() || op.StartedAt.IsZero() || activityID <= 0 || tierID <= 0 {
		return ClaimResult{}, ErrUnavailable
	}
	var out ClaimResult
	_, err := s.Runner.Run(ctx, op, claimProfile(), tx.Options{Isolation: tx.Serializable}, claimRetry(), nil, func(c context.Context, scope tx.Scope) error {
		if err := s.Fence.FenceActorTx(c, scope.Tx, actor, op.StartedAt); err != nil {
			return err
		}
		roots, err := s.Players.LockPlayerRootsTx(c, scope.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID})
		if err != nil {
			return err
		}
		if len(roots) != 1 {
			return claimRejected("the canonical player root is unavailable")
		}
		occurrence, err := s.Store.ClaimOccurrenceTx(c, scope.Tx, int64(actor.LogicalServerID), activityID, op.StartedAt)
		if err != nil {
			return err
		}
		if occurrence == nil {
			return claimRejected("the activity is not running on this server")
		}
		locked, err := s.Store.LockOccurrenceSharedTx(c, scope.Tx, occurrence.ID)
		if err != nil {
			return err
		}
		if locked == nil {
			return claimRejected("the activity is not running on this server")
		}
		occurrence = locked
		definition, err := s.Store.DefinitionTx(c, scope.Tx, occurrence.ActivityID, occurrence.DefinitionRevision)
		if err != nil {
			return err
		}
		if definition == nil {
			return ErrUnavailable
		}
		if definition.Body.Archetype != events.ArchetypeTieredClaim {
			return claimRejected("this event archetype has no claim")
		}
		tier, found := findTier(definition.Body, tierID)
		if !found {
			return claimRejected("the tier does not exist")
		}
		resolvedChoice, err := resolveChoice(tier, choiceIndex)
		if err != nil {
			return err
		}
		claim := Claim{
			PlayerID: int64(actor.PlayerID), OccurrenceID: occurrence.ID, Tier: tierID,
			Period: ClaimPeriodPermanent, Choice: resolvedChoice, ClaimedAt: op.StartedAt.UTC(),
			GrantReceipt: claimBusinessKey(occurrence.ID, int64(actor.PlayerID), tierID),
		}
		stored, inserted, err := s.Store.InsertClaimTx(c, scope.Tx, claim)
		if err != nil {
			return err
		}
		if !inserted {
			return replayStoredClaim(stored, resolvedChoice, &out)
		}
		if !locked.Active(op.StartedAt) {
			return claimRejected("the activity is not open for claims")
		}
		level, foundLevel, err := s.Levels.PlayerLevelTx(c, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		if !foundLevel || level < tier.Requirement.Value {
			return claimRejected("the player level requirement is not met")
		}
		revision, pinned := op.Policies.Get("content")
		if !pinned {
			revision, err = s.Content.ActiveRevision(c, scope.Tx)
			if err != nil {
				return err
			}
			op.Policies, err = policy.NewSet(append(op.Policies.Refs(), policy.Ref{Name: "content", Version: revision})...)
			if err != nil {
				return err
			}
		}
		awards, err := s.grantChoice(c, scope.Tx, actor, op, occurrence, tier, resolvedChoice, revision)
		if err != nil {
			return err
		}
		out = ClaimResult{Awards: awards}
		body, version, err := payload.Encode(out)
		if err != nil {
			return err
		}
		claim.PayloadVersion = version
		return s.Store.UpdateClaimReplyTx(c, scope.Tx, claim, body)
	})
	if err != nil {
		return ClaimResult{}, err
	}
	return out, nil
}

func replayStoredClaim(stored Claim, choiceIndex int, out *ClaimResult) error {
	if stored.Choice != choiceIndex {
		return claimRejected("the tier is already claimed with another choice")
	}
	if len(stored.AwardBody) == 0 {
		return claimRejected("the tier is already claimed")
	}
	return payload.Decode("player_event_claims", stored.PayloadVersion, stored.AwardBody, out)
}

// resolveChoice maps the stock sub_award_id to a choice: absent or zero means
// the only choice of a one-choice tier (Activities.lua:132-150; the 1071 window
// calls getActivityReward2, Activity1071.lua:190).
func resolveChoice(tier events.Tier, requested int) (int, error) {
	if requested == 0 {
		if len(tier.Choices) == 1 {
			return 1, nil
		}
		return 0, claimRejected("the choice is required")
	}
	if requested < 0 || requested > len(tier.Choices) {
		return 0, claimRejected("the choice does not exist")
	}
	return requested, nil
}

func findTier(definition events.Definition, tierID int64) (events.Tier, bool) {
	for _, tier := range definition.Tiers {
		if tier.ID == tierID {
			return tier, true
		}
	}
	return events.Tier{}, false
}

func claimBusinessKey(occurrenceID, playerID, tierID int64) string {
	return "event:" + strconv.FormatInt(occurrenceID, 10) + ":" + strconv.FormatInt(playerID, 10) + ":" + strconv.FormatInt(tierID, 10)
}
