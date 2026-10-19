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
	_, _, err = s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), settledEvidence{store: s.Store, reader: s.Fresh, server: server, day: day}, func(c context.Context, sc gen.TimedScope) error {
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
		top := []identity.PlayerID{}
		for _, r := range players {
			entry := d.DayRank{Player: r.Occupant.Player, Rank: r.Rank}
			if lines := dailyLines(catalog, r.Rank); len(lines) > 0 {
				m, _, err := s.Mail.DeliverTx(c, sc.Tx, i5.SettlementMailRequest{Recipient: r.Occupant.Player, SourceKind: dailyMailKind, SourceKey: fmt.Sprintf("%d:%s", server, d.DayDate(day)),
					Title: catalog.MailTitle, Sender: catalog.MailSender, Body: fmt.Sprintf(catalog.MailText, r.Rank), PolicyVersion: d.ContractID, Lines: lines, At: at})
				if err != nil {
					return err
				}
				entry.Mail = &m.MailUUID
			}
			if reward, ok := catalog.RewardFor(r.Rank); ok && reward.FrameID > 0 {
				_, _, err = s.Mail.DeliverTx(c, sc.Tx, i5.SettlementMailRequest{Recipient: r.Occupant.Player, SourceKind: dailyFrameMailKind, SourceKey: fmt.Sprintf("%d:%d", server, r.Occupant.Player),
					Title: catalog.MailTitle, Sender: catalog.MailSender, Body: fmt.Sprintf(catalog.MailText, r.Rank), PolicyVersion: d.ContractID, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: reward.FrameID, Amount: 1}}, At: at})
				if err != nil {
					return err
				}
			}
			settlement.Ranks = append(settlement.Ranks, entry)
			if r.Rank <= 3 {
				top = append(top, r.Occupant.Player)
			}
		}
		if err = s.Store.InsertDaySettlementTx(c, sc.Tx, settlement); err != nil {
			return err
		}
		if err = s.Achievements.ObserveTopFloorDayTx(c, sc.Tx, server, day, revision, top, at); err != nil {
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
