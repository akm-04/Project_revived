package events

import (
	"context"
	"errors"
	"fmt"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	otadomain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Bounds of one maintenance step (EA-9: bounded batches).
const (
	DefaultServerPageSize        = 100
	DefaultSettlementOccurrences = 50
	DefaultSettlementPlayers     = 200
)

// SettlementMailSourceKind is the i5 source kind of an unclaimed tier mail.
// The source key is occurrence:player:tier, which is also the claim receipt.
const SettlementMailSourceKind = "EVENT_SETTLEMENT"

// SettlementPolicyVersion records which contract settles a tier.
const SettlementPolicyVersion = "I11A_EVENTS_V1"

const (
	settlementMailTitle   = "Event reward"
	settlementMailSender  = "Event"
	settlementMailBody    = "An event reward you did not claim is attached."
	cycleOccurrenceSource = "CYCLE"
)

// PlayerRef is one player of a server with the directory level settlement reads.
type PlayerRef struct {
	PlayerID identity.PlayerID
	Level    int64
}

// ServerSource enumerates logical servers with players (the I4 owner adapter).
type ServerSource interface {
	ListLogicalServersAfterTx(context.Context, tx.Queryer, identity.LogicalServerID, int) ([]identity.LogicalServerID, error)
}

// PlayerSource enumerates one server's players in bounded pages (I4 owner adapter).
type PlayerSource interface {
	PlayersOfServerAfterTx(context.Context, tx.Queryer, identity.LogicalServerID, identity.PlayerID, int) ([]PlayerRef, error)
}

// Mailer is the i5 settlement mail seam.
type Mailer interface {
	DeliverTx(context.Context, tx.Tx, appi5.SettlementMailRequest) (mail.Record, bool, error)
}

// Jobs runs the two events maintenance steps (E4). It owns no state: every
// write goes through the events store inside an owner transaction.
type Jobs struct {
	Runner       tx.Runner
	Operations   operation.Factory
	Store        Store
	Coverage     Coverage
	Hooks        HookRegistry
	Clock        clock.Clock
	DefaultCycle events.Cycle
	Servers      ServerSource
	Players      PlayerSource
	Mail         Mailer
	Content      ContentRevision
	ClaimGrant   ChoiceGrant

	OccurrenceBatch int
	PlayerPage      int
}

func (jobs Jobs) serverPageSize() int { return DefaultServerPageSize }

func (jobs Jobs) occurrenceBatch() int {
	if jobs.OccurrenceBatch > 0 {
		return jobs.OccurrenceBatch
	}
	return DefaultSettlementOccurrences
}

func (jobs Jobs) playerPage() int {
	if jobs.PlayerPage > 0 {
		return jobs.PlayerPage
	}
	return DefaultSettlementPlayers
}

func (jobs Jobs) cycleReady() error {
	if jobs.Runner.DB == nil || jobs.Store == nil || jobs.Coverage == nil || jobs.Clock == nil || jobs.Servers == nil || jobs.DefaultCycle.Anchor.IsZero() {
		return ErrUnavailable
	}
	return nil
}

func (jobs Jobs) settleReady() error {
	if jobs.Runner.DB == nil || jobs.Store == nil || jobs.Clock == nil || jobs.Players == nil || jobs.Mail == nil {
		return ErrUnavailable
	}
	return nil
}

func jobReadProfile(name string) tx.Profile {
	return tx.Profile{Name: name, AcquireTimeout: 500 * time.Millisecond, LockTimeout: 500 * time.Millisecond, StatementTimeout: 1500 * time.Millisecond, TransactionTimeout: 2 * time.Second, CleanupTimeout: 500 * time.Millisecond, ReconcileTimeout: 500 * time.Millisecond, OperationTimeout: 3 * time.Second}
}

func jobWriteProfile(name string) tx.Profile {
	return tx.Profile{Name: name, AcquireTimeout: 500 * time.Millisecond, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 10 * time.Second, CleanupTimeout: 500 * time.Millisecond, ReconcileTimeout: 500 * time.Millisecond, OperationTimeout: 15 * time.Second}
}

func (jobs Jobs) read(ctx context.Context, op operation.Context, name string, body tx.Body) error {
	_, err := jobs.Runner.Run(ctx, op, jobReadProfile(name), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, body)
	return err
}

func (jobs Jobs) write(ctx context.Context, op operation.Context, name string, body tx.Body) error {
	_, err := jobs.Runner.Run(ctx, op, jobWriteProfile(name), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, body)
	return err
}

func (jobs Jobs) newOperation() (operation.Context, error) {
	if jobs.Operations.Clock == nil {
		return operation.Context{}, ErrUnavailable
	}
	return jobs.Operations.New(policy.Set{})
}

// MaterialiseCycle walks every server with players in bounded pages and keeps
// its next look-ahead cycle slots materialised (ruling 8).
func (jobs Jobs) MaterialiseCycle(ctx context.Context) error {
	if err := jobs.cycleReady(); err != nil {
		return err
	}
	op, err := jobs.newOperation()
	if err != nil {
		return err
	}
	after := identity.LogicalServerID(0)
	for {
		page, err := jobs.serversAfter(ctx, op, after)
		if err != nil {
			return err
		}
		if len(page) == 0 {
			return nil
		}
		for _, server := range page {
			if err := jobs.MaterialiseServer(ctx, op, server); err != nil {
				return err
			}
		}
		if len(page) < jobs.serverPageSize() {
			return nil
		}
		after = page[len(page)-1]
	}
}

func (jobs Jobs) serversAfter(ctx context.Context, op operation.Context, after identity.LogicalServerID) ([]identity.LogicalServerID, error) {
	var page []identity.LogicalServerID
	err := jobs.read(ctx, op, "events-cycle-servers", func(ctx context.Context, scope tx.Scope) error {
		loaded, err := jobs.Servers.ListLogicalServersAfterTx(ctx, scope.Tx, after, jobs.serverPageSize())
		if err == nil {
			page = loaded
		}
		return err
	})
	return page, err
}

// MaterialiseServer materialises one server's next cycle slots. Existing rows
// (a cancelled slot included), overlaps and gate failures are skipped, never
// shifted (ruling 8, E4 plan).
func (jobs Jobs) MaterialiseServer(ctx context.Context, op operation.Context, server identity.LogicalServerID) error {
	if jobs.Store == nil || jobs.Clock == nil || jobs.Coverage == nil || server <= 0 {
		return ErrUnavailable
	}
	at := jobs.Clock.Now().UTC()
	return jobs.write(ctx, op, "events-cycle-materialise", func(ctx context.Context, scope tx.Scope) error {
		settings, err := jobs.Store.EnsureSettingsTx(ctx, scope.Tx, int64(server), at)
		if err != nil {
			if errors.Is(err, ErrServerUnknown) {
				return nil
			}
			return err
		}
		if settings.Mode != CycleModeAuto || settings.Lookahead <= 0 {
			return nil
		}
		cycle := jobs.DefaultCycle
		if settings.CycleRevision > 0 && len(settings.CycleBody) > 0 {
			parsed, err := events.ParseCycle(settings.CycleBody)
			if err != nil {
				return err
			}
			cycle = parsed
		}
		for _, slot := range cycle.NextSlots(at, settings.Lookahead, settings.ClaimWindow) {
			if err := jobs.materialiseSlot(ctx, scope.Tx, int64(server), slot, at); err != nil {
				return err
			}
		}
		return nil
	})
}

func (jobs Jobs) materialiseSlot(ctx context.Context, transaction tx.Tx, server int64, slot events.Slot, at time.Time) error {
	definition, err := jobs.Store.LatestDefinitionTx(ctx, transaction, slot.ActivityID)
	if err != nil {
		return err
	}
	if definition == nil {
		return nil
	}
	if hookGate(definition.Body, jobs.Hooks) != nil {
		return nil
	}
	coverage, err := jobs.Coverage.Covers(ctx, definition.Body.ClientRequirements.CoversRequest())
	if err != nil {
		return err
	}
	if coverage.Status != otadomain.CoversCovered {
		return nil
	}
	taken, err := jobs.Store.CycleSlotTakenTx(ctx, transaction, server, slot.StartsAt)
	if err != nil {
		return err
	}
	if taken {
		return nil
	}
	overlaps, err := jobs.Store.OverlapsTx(ctx, transaction, server, slot.ActivityID, slot.StartsAt, &slot.ClaimUntil, 0)
	if err != nil {
		return err
	}
	if overlaps {
		return nil
	}
	occurrence := events.Occurrence{
		LogicalServerID: server, ActivityID: slot.ActivityID, DefinitionRevision: definition.Revision,
		StartsAt: slot.StartsAt, EndsAt: &slot.EndsAt, ClaimUntil: &slot.ClaimUntil,
		Source: cycleOccurrenceSource, Revision: 1, CreatedAt: at,
	}
	_, err = jobs.Store.InsertCycleOccurrenceTx(ctx, transaction, occurrence, at)
	return err
}

// SettleDue archives occurrences whose claim window closed: a TIERED_CLAIM
// delivers every eligible unclaimed tier once (mail, or the MID 231 grant when
// the tier holds a hero), then the occurrence is marked settled (EA-9, E4c). A
// permanent occurrence has no claim window and never settles.
func (jobs Jobs) SettleDue(ctx context.Context) error {
	if err := jobs.settleReady(); err != nil {
		return err
	}
	op, err := jobs.newOperation()
	if err != nil {
		return err
	}
	at := jobs.Clock.Now().UTC()
	after, settled := int64(0), 0
	batch := jobs.occurrenceBatch()
	for settled < batch {
		remaining := batch - settled
		page, err := jobs.dueAfter(ctx, op, at, after, remaining)
		if err != nil {
			return err
		}
		if len(page) == 0 {
			return nil
		}
		for _, occurrence := range page {
			if err := jobs.SettleOccurrence(ctx, op, occurrence, at); err != nil {
				return err
			}
			after = occurrence.ID
			settled++
			if settled == batch {
				return nil
			}
		}
		if len(page) < remaining {
			return nil
		}
	}
	return nil
}

func (jobs Jobs) dueAfter(ctx context.Context, op operation.Context, at time.Time, after int64, limit int) ([]events.Occurrence, error) {
	var page []events.Occurrence
	err := jobs.read(ctx, op, "events-settlement-due", func(ctx context.Context, scope tx.Scope) error {
		loaded, err := jobs.Store.DueOccurrencesAfterTx(ctx, scope.Tx, at, after, limit)
		if err == nil {
			page = loaded
		}
		return err
	})
	return page, err
}

// SettleOccurrence settles one already-due occurrence. It is idempotent: the
// claim ledger and the i5 mail source key make a re-run mail nothing.
func (jobs Jobs) SettleOccurrence(ctx context.Context, op operation.Context, occurrence events.Occurrence, at time.Time) error {
	if occurrence.Permanent() || occurrence.CancelledAt != nil || occurrence.SettledAt != nil || occurrence.ClaimUntil == nil || occurrence.ClaimUntil.After(at) {
		return nil
	}
	var definition *DefinitionRecord
	err := jobs.read(ctx, op, "events-settlement-definition", func(ctx context.Context, scope tx.Scope) error {
		loaded, err := jobs.Store.DefinitionTx(ctx, scope.Tx, occurrence.ActivityID, occurrence.DefinitionRevision)
		if err == nil {
			definition = loaded
		}
		return err
	})
	if err != nil {
		return err
	}
	if definition == nil {
		return fmt.Errorf("events: settlement occurrence %d has no definition %d/%d", occurrence.ID, occurrence.ActivityID, occurrence.DefinitionRevision)
	}
	if definition.Body.Archetype == events.ArchetypeTieredClaim {
		op, revision, err := jobs.settlementRevision(ctx, op, definition.Body)
		if err != nil {
			return err
		}
		if err := jobs.settleTiers(ctx, op, occurrence, definition.Body, revision, at); err != nil {
			return err
		}
	}
	return jobs.settleMark(ctx, op, occurrence.ID, at)
}

// settlementRevision pins the active content revision once for the occurrence
// when a tier holds a hero, the same rule MID 231 follows (D02).
func (jobs Jobs) settlementRevision(ctx context.Context, op operation.Context, definition events.Definition) (operation.Context, string, error) {
	if !definitionHasHeroTier(definition) {
		return op, "", nil
	}
	if jobs.Content == nil || !jobs.ClaimGrant.ready() {
		return op, "", ErrUnavailable
	}
	revision := ""
	err := jobs.read(ctx, op, "events-settlement-content", func(txCtx context.Context, scope tx.Scope) error {
		var err error
		op, revision, err = pinContentRevision(txCtx, op, jobs.Content, scope.Tx)
		return err
	})
	return op, revision, err
}

func (jobs Jobs) settleTiers(ctx context.Context, op operation.Context, occurrence events.Occurrence, definition events.Definition, revision string, at time.Time) error {
	server := identity.LogicalServerID(occurrence.LogicalServerID)
	after := identity.PlayerID(0)
	pageSize := jobs.playerPage()
	for {
		players, err := jobs.playersAfter(ctx, op, server, after, pageSize)
		if err != nil {
			return err
		}
		if len(players) == 0 {
			return nil
		}
		if err := jobs.deliverTierPage(ctx, op, occurrence, definition, players, revision, at); err != nil {
			var refusal *tierRefusal
			if !errors.As(err, &refusal) {
				return err
			}
			// The abort rolled the page back; record the refused tier so the
			// retried page skips it and the occurrence still settles (E4c).
			if err := jobs.recordRefusal(ctx, op, refusal, at); err != nil {
				return err
			}
			continue
		}
		after = players[len(players)-1].PlayerID
		if len(players) < pageSize {
			return nil
		}
	}
}

func (jobs Jobs) playersAfter(ctx context.Context, op operation.Context, server identity.LogicalServerID, after identity.PlayerID, limit int) ([]PlayerRef, error) {
	var page []PlayerRef
	err := jobs.read(ctx, op, "events-settlement-players", func(ctx context.Context, scope tx.Scope) error {
		loaded, err := jobs.Players.PlayersOfServerAfterTx(ctx, scope.Tx, server, after, limit)
		if err == nil {
			page = loaded
		}
		return err
	})
	return page, err
}

func (jobs Jobs) deliverTierPage(ctx context.Context, op operation.Context, occurrence events.Occurrence, definition events.Definition, players []PlayerRef, revision string, at time.Time) error {
	return jobs.write(ctx, op, "events-settlement-mail", func(txCtx context.Context, scope tx.Scope) error {
		for _, player := range players {
			for _, tier := range definition.Tiers {
				if player.Level < tier.Requirement.Value {
					continue
				}
				if err := jobs.deliverTier(txCtx, scope.Tx, occurrence, player, tier, op, revision, at); err != nil {
					return err
				}
			}
		}
		return nil
	})
}

func (jobs Jobs) deliverTier(ctx context.Context, transaction tx.Tx, occurrence events.Occurrence, player PlayerRef, tier events.Tier, op operation.Context, revision string, at time.Time) error {
	claimed, err := jobs.Store.HasClaimTx(ctx, transaction, int64(player.PlayerID), occurrence.ID, tier.ID)
	if err != nil {
		return err
	}
	if claimed {
		return nil
	}
	if tierHasHero(tier) {
		return jobs.deliverHeroTier(ctx, transaction, occurrence, player, tier, op, revision, at)
	}
	lines, err := choiceGrantLines(tier)
	if err != nil {
		return tierRefused(occurrence.ID, player.PlayerID, tier.ID, err)
	}
	key := settlementSourceKey(occurrence.ID, player.PlayerID, tier.ID)
	claim := Claim{PlayerID: int64(player.PlayerID), OccurrenceID: occurrence.ID, Tier: tier.ID, Period: ClaimPeriodPermanent, Choice: 1, ClaimedAt: at.UTC(), GrantReceipt: key}
	if _, inserted, err := jobs.Store.InsertClaimTx(ctx, transaction, claim); err != nil {
		return err
	} else if !inserted {
		return nil
	}
	_, _, err = jobs.Mail.DeliverTx(ctx, transaction, appi5.SettlementMailRequest{
		Recipient: player.PlayerID, SourceKind: SettlementMailSourceKind, SourceKey: key,
		Title: settlementMailTitle, Sender: settlementMailSender, Body: settlementMailBody,
		PolicyVersion: SettlementPolicyVersion, Lines: lines, At: at.UTC(),
	})
	return err
}

// deliverHeroTier settles a tier whose choice holds a hero by the MID 231 grant,
// because system mail cannot carry one (E4c). The claim row is the guard and
// the grant's business key makes the tier at-most-once.
func (jobs Jobs) deliverHeroTier(ctx context.Context, transaction tx.Tx, occurrence events.Occurrence, player PlayerRef, tier events.Tier, op operation.Context, revision string, at time.Time) error {
	claim := Claim{
		PlayerID: int64(player.PlayerID), OccurrenceID: occurrence.ID, Tier: tier.ID,
		Period: ClaimPeriodPermanent, Choice: 1, ClaimedAt: at.UTC(),
		GrantReceipt: claimBusinessKey(occurrence.ID, int64(player.PlayerID), tier.ID),
	}
	if _, inserted, err := jobs.Store.InsertClaimTx(ctx, transaction, claim); err != nil {
		return err
	} else if !inserted {
		return nil
	}
	actor := identity.ActorContext{LogicalServerID: identity.LogicalServerID(occurrence.LogicalServerID), PlayerID: player.PlayerID}
	if _, err := jobs.ClaimGrant.Grant(ctx, transaction, actor, op, &occurrence, tier, 1, revision); err != nil {
		if errors.Is(err, ErrClaimRejected) {
			return tierRefused(occurrence.ID, player.PlayerID, tier.ID, err)
		}
		return err
	}
	return nil
}

// tierRefusal is a permanently ungrantable (player, tier) of one occurrence.
// The page transaction is aborted; settleTiers records the refusal and retries.
type tierRefusal struct {
	occurrenceID int64
	playerID     identity.PlayerID
	tierID       int64
	reason       error
}

func (r *tierRefusal) Error() string {
	return fmt.Sprintf("events: settlement refused occurrence %d player %d tier %d: %v", r.occurrenceID, int64(r.playerID), r.tierID, r.reason)
}

func tierRefused(occurrenceID int64, playerID identity.PlayerID, tierID int64, reason error) error {
	return &tierRefusal{occurrenceID: occurrenceID, playerID: playerID, tierID: tierID, reason: reason}
}

// settlementRefusedReceipt marks a claim row whose tier was refused; it keeps
// the any-period guard and the occurrence settles (E4c).
const settlementRefusedReceipt = "refused"

func (jobs Jobs) recordRefusal(ctx context.Context, op operation.Context, refusal *tierRefusal, at time.Time) error {
	return jobs.write(ctx, op, "events-settlement-refused", func(txCtx context.Context, scope tx.Scope) error {
		_, _, err := jobs.Store.InsertClaimTx(txCtx, scope.Tx, Claim{
			PlayerID: int64(refusal.playerID), OccurrenceID: refusal.occurrenceID, Tier: refusal.tierID,
			Period: ClaimPeriodPermanent, Choice: 1, ClaimedAt: at.UTC(), GrantReceipt: settlementRefusedReceipt,
		})
		return err
	})
}

func tierHasHero(tier events.Tier) bool {
	return len(tier.Choices) > 0 && hasHeroLine(tier.Choices[0].Lines)
}

func definitionHasHeroTier(definition events.Definition) bool {
	for _, tier := range definition.Tiers {
		if tierHasHero(tier) {
			return true
		}
	}
	return false
}

func choiceGrantLines(tier events.Tier) ([]grant.Line, error) {
	if len(tier.Choices) == 0 {
		return nil, fmt.Errorf("events: tier %d has no choice", tier.ID)
	}
	choice := tier.Choices[0]
	if choice.GiftID != 0 || len(choice.Lines) == 0 {
		return nil, fmt.Errorf("events: tier %d choice was not expanded at deploy", tier.ID)
	}
	lines := make([]grant.Line, 0, len(choice.Lines))
	for _, line := range choice.Lines {
		switch line.Kind {
		case "item":
			lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: line.ItemID, Amount: line.Amount})
		case "currency":
			lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: line.ResourceKey, Amount: line.Amount})
		default:
			return nil, fmt.Errorf("events: tier %d has unknown reward kind %q", tier.ID, line.Kind)
		}
	}
	return lines, nil
}

func settlementSourceKey(occurrenceID int64, playerID identity.PlayerID, tier int64) string {
	return fmt.Sprintf("%d:%d:%d", occurrenceID, int64(playerID), tier)
}

func (jobs Jobs) settleMark(ctx context.Context, op operation.Context, occurrenceID int64, at time.Time) error {
	return jobs.write(ctx, op, "events-settlement-mark", func(ctx context.Context, scope tx.Scope) error {
		if _, err := jobs.Store.MarkSettledTx(ctx, scope.Tx, occurrenceID, at); err != nil {
			return err
		}
		return nil
	})
}
