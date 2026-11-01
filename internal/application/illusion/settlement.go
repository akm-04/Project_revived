package illusion

import (
	"context"
	"fmt"
	"slices"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	settlementMailKind = "ILLUSION_SETTLEMENT"
	settlementTitle    = "Fantasy Settlement"
	settlementSender   = "Fantasy"
)

type Reconciler struct{ Service Mode }

func (Reconciler) Name() string { return "illusion" }

// Reconcile settles the 22:00 GMT+8 occurrence rewards once per occurrence day
// and advances the campaign after its rest day.
func (r Reconciler) Reconcile(c context.Context, timed gen.TimedOperation, limit int) (gen.ReconcileResult, error) {
	out := gen.ReconcileResult{Provider: r.Name()}
	s := r.Service
	if !s.ready() || limit < 1 || limit > gen.MaxReconcileBatch {
		return out, d.ErrUnavailable
	}
	parent, err := s.pin(c, timed.Operation())
	if err != nil {
		return out, err
	}
	occurrences, err := s.Store.ListOccurrencesTx(c, s.Fresh, int64(limit))
	if err != nil {
		return out, err
	}
	for _, occurrence := range occurrences {
		child, err := settlementOperation(parent, occurrence.LogicalServerID)
		if err != nil {
			return out, err
		}
		applied := false
		_, _, err = s.Timed.Run(c, child, profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
			at := sc.Operation.DecisionAt()
			current, err := s.Store.LockOccurrenceTx(c, sc.Tx, occurrence.LogicalServerID, at)
			if err != nil {
				return err
			}
			if !current.SettlementDue(at) {
				return nil
			}
			catalog, err := s.catalog(c, sc)
			if err != nil {
				return err
			}
			if err = s.settle(c, sc, current, catalog, at); err != nil {
				return err
			}
			if !current.Advance(catalog) {
				return d.ErrUnavailable
			}
			if err = s.Store.SaveOccurrenceTx(c, sc.Tx, current, at); err != nil {
				return err
			}
			applied = true
			return nil
		})
		if err != nil {
			return out, err
		}
		out.Scanned++
		if applied {
			out.Settled++
		} else {
			out.Noops++
		}
	}
	_, _, err = s.Timed.Run(c, timed.Operation(), profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		_, err := s.Store.PurgeExpiredReportsTx(c, sc.Tx, sc.Operation.DecisionAt(), int64(limit))
		return err
	})
	return out, err
}

// shortcut: one occurrence's participants and guild members all settle inside
// its 30 s shared-row transaction (rankLimit rows plus that many guild mails);
// split into a settlement outbox if one server grows beyond this batch.
func (s Mode) settle(c context.Context, sc gen.TimedScope, occurrence d.Occurrence, catalog d.Catalog, at time.Time) error {
	ranks, err := s.Store.ReadRankTx(c, sc.Tx, occurrence.LogicalServerID, occurrence.OpenDay, rankLimit)
	if err != nil {
		return err
	}
	rewards := map[identity.PlayerID][]grant.Line{}
	for index, entry := range ranks {
		recipient := identity.PlayerID(entry.PlayerID)
		reward := catalog.PersonReward(int64(index + 1))
		if reward.Coin > 0 {
			rewards[recipient] = append(rewards[recipient], grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "paradise_coin", Amount: reward.Coin})
		}
		// The person band's item rows are the boss kill bonus; the shared pool
		// must be depleted by settlement for it to be paid.
		if occurrence.Done() {
			for itemIndex, itemID := range reward.ItemIDs {
				if itemID > 0 && reward.ItemNums[itemIndex] > 0 {
					rewards[recipient] = append(rewards[recipient], grant.Line{Kind: grant.StackItem, ItemID: itemID, Amount: reward.ItemNums[itemIndex]})
				}
			}
		}
		gold := entry.Hurt * catalog.RewardPercentHundredths / 100
		if gold > 0 {
			rewards[recipient] = append(rewards[recipient], grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: gold})
		}
	}
	guilds, err := s.Guilds.GuildSummaries(c, identity.LogicalServerID(occurrence.LogicalServerID))
	if err != nil {
		return err
	}
	occurrenceKey := fmt.Sprintf("%d:%d:%d", occurrence.LogicalServerID, occurrence.OpenDay, occurrence.CampaignID)
	// The guild-level community band is guild active points (I9_GUILD_ACTIVITY_V1
	// C9); source_key makes one occurrence credit each guild once.
	for index, score := range guildScores(guilds, ranks) {
		band := catalog.CommunityReward(int64(index + 1))
		if band.Coin <= 0 {
			continue
		}
		key := fmt.Sprintf("%s:guild:%d", occurrenceKey, score.Guild.ID)
		if err := s.GuildActivity.CreditActivityAwardTx(c, sc.Tx, score.Guild.ID, key, band.Coin); err != nil {
			return err
		}
	}
	recipients := make([]identity.PlayerID, 0, len(rewards))
	for recipient, lines := range rewards {
		if len(lines) > 0 {
			recipients = append(recipients, recipient)
		}
	}
	slices.Sort(recipients)
	sourceKey := occurrenceKey
	for _, recipient := range recipients {
		request := i5.SettlementMailRequest{Recipient: recipient, SourceKind: settlementMailKind, SourceKey: sourceKey,
			Title: settlementTitle, Sender: settlementSender,
			Body:          fmt.Sprintf("Fantasy boss %d on day %d", occurrence.CampaignID, occurrence.OpenDay),
			PolicyVersion: d.PolicyID, Lines: rewards[recipient], At: at}
		if _, _, err = s.Mail.DeliverTx(c, sc.Tx, request); err != nil {
			return err
		}
	}
	return nil
}

func (s Mode) catalog(c context.Context, sc gen.TimedScope) (d.Catalog, error) {
	revision, _ := sc.Operation.Operation().Policies.Get("content")
	return s.Content.IllusionCatalogTx(c, sc.Tx, revision)
}

func settlementOperation(parent operation.Context, server int64) (operation.Context, error) {
	id, err := ids.NewUUID()
	if err != nil {
		return operation.Context{}, err
	}
	return operation.Context{ID: id, StartedAt: parent.StartedAt, EntropySeed: parent.Derive(fmt.Sprintf("illusion:settle:%d", server), 0), Policies: parent.Policies}, nil
}
