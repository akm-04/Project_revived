package topfloor

import (
	"context"
	"errors"
	"fmt"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ErrSettlementDue makes a ladder mutation yield to the owed daily settlement.
var ErrSettlementDue = errors.New("topfloor: daily settlement due first")

const (
	dailyMailKind = "TOP_FLOOR_DAILY"
	// Private policy: the rank-1 frame (stack cap 1) travels in its own mail, once per player and server.
	dailyFrameMailKind = "TOP_FLOOR_DAILY_FRAME"
	bestRankMailKind   = "TOP_FLOOR_BEST_RANK"
	// Private policy: source names no title for the best-rank reward mail.
	bestRankMailTitle = "Top Floor Best Rank Reward"
	bestRankMailText  = "You reached a new best Top Floor rank %d."
)

func Profile() tx.Profile {
	return tx.Profile{Name: "top-floor", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

// child is a separate system operation; settlements never reuse a player's operation id.
func child(parent operation.Context, label string) (operation.Context, error) {
	id, err := ids.NewUUID()
	if err != nil {
		return operation.Context{}, err
	}
	return operation.Context{ID: id, StartedAt: parent.StartedAt, EntropySeed: parent.Derive("top-floor:"+label, 0), Policies: parent.Policies}, nil
}

type settledEvidence struct {
	store  Store
	reader tx.Queryer
	server identity.LogicalServerID
	day    int64
}

func (e settledEvidence) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	l, found, err := e.store.ReadLadderTx(c, e.reader, e.server, false)
	if err != nil || !found || l.SettledDay < e.day {
		return tx.Resolution{State: tx.ResolutionUnknown}, err
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: l.SettledDay}, nil
}

// SettleDue settles every owed cutoff day of the server, oldest first.
func (s Service) SettleDue(c context.Context, server identity.LogicalServerID, parent operation.Context) (int, error) {
	if !s.ready() {
		return 0, d.ErrUnavailable
	}
	l, found, err := s.Store.ReadLadderTx(c, s.Fresh, server, false)
	if err != nil || !found {
		return 0, err
	}
	now, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return 0, err
	}
	revision, err := s.Content.ActiveRevision(c, s.Fresh)
	if err != nil {
		return 0, err
	}
	catalog, err := s.Content.TopFloorCatalogTx(c, s.Fresh, revision)
	if err != nil {
		return 0, err
	}
	settled := 0
	for _, day := range catalog.Unsettled(l, now) {
		if err = s.settleDay(c, server, day, parent); err != nil {
			return settled, err
		}
		settled++
	}
	return settled, nil
}

func (s Service) settleDay(c context.Context, server identity.LogicalServerID, day int64, parent operation.Context) error {
	op, err := child(parent, fmt.Sprintf("day:%d:%d", server, day))
	if err != nil {
		return err
	}
	// Read Committed lets the frame check see claims completed while it waits on mail namespace locks.
	_, _, err = s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.ReadCommitted}, retry(), settledEvidence{store: s.Store, reader: s.Fresh, server: server, day: day}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		l, found, err := s.Store.ReadLadderTx(c, sc.Tx, server, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrConflict)
		}
		if l.SettledDay >= day {
			return nil
		}
		revision, err := s.Content.ActiveRevision(c, sc.Tx)
		if err != nil {
			return err
		}
		catalog, err := s.Content.TopFloorCatalogTx(c, sc.Tx, revision)
		if err != nil {
			return err
		}
		cutoff := catalog.CutoffInstant(day)
		if l.SettledDay != day-1 || at.Before(cutoff) {
			return d.ErrConflict
		}
		players, err := s.Store.RankedPlayersTx(c, sc.Tx, server)
		if err != nil {
			return err
		}
		settlement := d.DaySettlement{Server: server, Day: day, CutoffAt: cutoff, SettledAt: at, LadderVersion: l.StateVersion, ContentRevision: revision}
		mailRecipients := []identity.PlayerID{}
		frameRequests := []i5.FrameStackRequest{}
		for _, rankedPlayer := range players {
			rewardAttachments := dailyLines(catalog, rankedPlayer.Rank)
			reward, hasReward := catalog.RewardFor(rankedPlayer.Rank)
			hasFrameReward := hasReward && reward.FrameID > 0
			if len(rewardAttachments) > 0 || hasFrameReward {
				mailRecipients = append(mailRecipients, rankedPlayer.Occupant.Player)
			}
			if hasFrameReward {
				frameRequests = append(frameRequests, i5.FrameStackRequest{Player: rankedPlayer.Occupant.Player, ItemID: reward.FrameID})
			}
		}
		if len(frameRequests) > 0 && s.FrameStacks == nil {
			return d.ErrUnavailable
		}
		if err := s.Mail.LockRecipientsTx(c, sc.Tx, mailRecipients); err != nil {
			return err
		}
		frameOwnership := map[i5.FrameStackRequest]bool{}
		if len(frameRequests) > 0 {
			frameOwnership, err = i5.LockFrameStackOwnershipTx(c, sc.Tx, s.FrameStacks, frameRequests, at)
			if err != nil {
				return err
			}
		}
		topPlayers := []identity.PlayerID{}
		for _, rankedPlayer := range players {
			entry := d.DayRank{Player: rankedPlayer.Occupant.Player, Rank: rankedPlayer.Rank}
			rewardAttachments := dailyLines(catalog, rankedPlayer.Rank)
			if len(rewardAttachments) > 0 {
				record, _, deliveryError := s.Mail.DeliverTx(c, sc.Tx, i5.SettlementMailRequest{Recipient: rankedPlayer.Occupant.Player, SourceKind: dailyMailKind, SourceKey: fmt.Sprintf("%d:%s", server, d.DayDate(day)),
					Title: catalog.MailTitle, Sender: catalog.MailSender, Body: fmt.Sprintf(catalog.MailText, rankedPlayer.Rank), PolicyVersion: d.ContractID, Lines: rewardAttachments, At: at})
				if deliveryError != nil {
					return deliveryError
				}
				entry.Mail = &record.MailUUID
			}
			reward, hasReward := catalog.RewardFor(rankedPlayer.Rank)
			if hasReward && reward.FrameID > 0 && !frameOwnership[i5.FrameStackRequest{Player: rankedPlayer.Occupant.Player, ItemID: reward.FrameID}] {
				if _, _, deliveryError := s.Mail.DeliverTx(c, sc.Tx, i5.SettlementMailRequest{Recipient: rankedPlayer.Occupant.Player, SourceKind: dailyFrameMailKind, SourceKey: fmt.Sprintf("%d:%d", server, rankedPlayer.Occupant.Player),
					Title: catalog.MailTitle, Sender: catalog.MailSender, Body: fmt.Sprintf(catalog.MailText, rankedPlayer.Rank), PolicyVersion: d.ContractID, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: reward.FrameID, Amount: 1}}, At: at}); deliveryError != nil {
					return deliveryError
				}
			}
			settlement.Ranks = append(settlement.Ranks, entry)
			if rankedPlayer.Rank <= 3 {
				topPlayers = append(topPlayers, rankedPlayer.Occupant.Player)
			}
		}
		if err = s.Store.InsertDaySettlementTx(c, sc.Tx, settlement); err != nil {
			return err
		}
		if err = s.Achievements.ObserveTopFloorDayTx(c, sc.Tx, server, day, revision, topPlayers, at); err != nil {
			return err
		}
		next := l
		next.SettledDay, next.StateVersion, next.UpdatedAt = day, l.StateVersion+1, at
		return s.Store.SaveLadderTx(c, sc.Tx, next, l.StateVersion)
	})
	return err
}

// dailyLines is the arena_reward row of the rank as mail attachments.
func dailyLines(c d.Catalog, rank int64) []grant.Line {
	reward, ok := c.RewardFor(rank)
	if !ok {
		return nil
	}
	lines := []grant.Line{}
	for _, scalar := range []struct {
		key    string
		amount int64
	}{{"crystal", reward.DailyCrystal}, {"mana", reward.DailyMana}, {"arena_coin", reward.DailyArenaCoin}} {
		if scalar.amount > 0 {
			lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: scalar.key, Amount: scalar.amount})
		}
	}
	for _, item := range reward.Items {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: item[0], Amount: item[1]})
	}
	return lines
}
