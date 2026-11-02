package arena

import (
	"context"
	"encoding/json"
	"errors"
	"slices"
	"strconv"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (service Service) SettleCasualSession(requestContext context.Context, weekDay int64, operationContext operation.Context) error {
	if !service.ready() {
		return d.ErrUnavailable
	}
	receiptIdentity := receipt.Identity{OwnerKind: "arena-casual", OwnerKey: strconv.FormatInt(weekDay, 10), Domain: "arena-tournament", Operation: "settle-week", SemanticKey: strconv.FormatInt(weekDay, 10)}
	fingerprint, err := receipt.FingerprintRequest(map[string]any{"week_day": weekDay})
	if err != nil {
		return err
	}
	_, _, err = service.Timed.Run(requestContext, operationContext, settlementProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), timedReceipt{receipt.Resolver{Reader: service.ReceiptRead, Identity: receiptIdentity, Fingerprint: fingerprint}}, func(requestContext context.Context, scope gen.TimedScope) error {
		_, found, err := service.Receipts.FindTx(requestContext, scope.Tx, receiptIdentity)
		if err != nil || found {
			return err
		}
		root, found, err := service.Store.ReadCompetitionTx(requestContext, scope.Tx, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrConflict)
		}
		session, found, err := service.Store.ReadCasualSessionTx(requestContext, scope.Tx, weekDay, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrRefused)
		}
		if scope.Operation.DecisionAt().Before(session.Period.ClosesAt) {
			return d.ErrClosed
		}
		if session.Settled {
			return nil
		}
		entries, err := service.Store.WaitingCasualEntriesTx(requestContext, scope.Tx, weekDay)
		if err != nil {
			return err
		}
		for _, entry := range entries {
			previous := entry.StateVersion
			entry.Status = d.QueueExpired
			entry.StateVersion++
			if err := service.Store.SaveCasualEntryTx(requestContext, scope.Tx, entry, previous); err != nil {
				return err
			}
		}
		rooms, err := service.Store.TournamentRoomsTx(requestContext, scope.Tx, weekDay, 0, true)
		if err != nil {
			return err
		}
		for _, room := range rooms {
			if room.Status != d.RoomSettled {
				return ErrUnresolved
			}
		}
		catalog, err := service.Content.ArenaCatalogTx(requestContext, scope.Tx, session.ContentRevision)
		if err != nil || catalog.Tournament == nil {
			return errors.Join(err, d.ErrUnavailable)
		}
		standings, err := service.Store.CasualStandingsTx(requestContext, scope.Tx, weekDay)
		if err != nil {
			return err
		}
		ordered := d.OrderCasualStandings(standings)
		type prize struct {
			player int64
			reward d.TournamentReward
		}
		prizes := []prize{}
		for index, standing := range ordered {
			reward, found := catalog.Tournament.RewardFor(int64(index+1), true)
			if found {
				prizes = append(prizes, prize{player: int64(standing.PlayerID), reward: reward})
			}
		}
		slices.SortFunc(prizes, func(first, second prize) int {
			if first.player < second.player {
				return -1
			}
			if first.player > second.player {
				return 1
			}
			return 0
		})
		for _, prize := range prizes {
			if _, _, err := service.Mail.DeliverTx(requestContext, scope.Tx, i5.SettlementMailRequest{Recipient: identity.PlayerID(prize.player), SourceKind: "ARENA_CASUAL_REWARD", SourceKey: strconv.FormatInt(weekDay, 10), Title: "Casual Arena", Sender: "Arena", Body: "Session ranking reward", PolicyVersion: d.TournamentPolicyIdentifier, Lines: tournamentRewardLines(prize.reward), At: scope.Operation.DecisionAt()}); err != nil {
				return err
			}
		}
		previous := session.StateVersion
		session.Settled = true
		session.StateVersion++
		if err := service.Store.SaveCasualSessionTx(requestContext, scope.Tx, session, previous); err != nil {
			return err
		}
		previous = root.StateVersion
		root.StateVersion++
		root.UpdatedAt = scope.Operation.DecisionAt()
		if err := service.Store.SaveCompetitionTx(requestContext, scope.Tx, root, previous); err != nil {
			return err
		}
		record, err := receipt.New(scope.Operation.Operation(), receiptIdentity, "I9_7B_ARENA", "gxb.arena.casual-settlement.v1", json.RawMessage(`{"settled":true}`), fingerprint)
		if err != nil {
			return err
		}
		record.PolicyVersion = d.TournamentContractIdentifier
		_, err = service.Receipts.PutTx(requestContext, scope.Tx, record)
		return err
	})
	return err
}
