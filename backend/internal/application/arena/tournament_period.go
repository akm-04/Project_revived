package arena

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"slices"
	"strconv"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (service Service) tournamentPeriodWork(requestContext context.Context, season int64, operationContext operation.Context, name string, apply func(context.Context, gen.TimedScope, d.TournamentCatalog, *d.TournamentPeriod) error) (d.TournamentPeriod, error) {
	var result d.TournamentPeriod
	if !service.ready() || season < 1 {
		return result, d.ErrUnavailable
	}
	pinned, err := service.pin(requestContext, operationContext)
	if err != nil {
		return result, err
	}
	identity := receipt.Identity{OwnerKind: "arena-tournament", OwnerKey: strconv.FormatInt(season, 10), Domain: "arena-tournament", Operation: name, SemanticKey: operationContext.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(map[string]any{"season": season, "operation": name})
	if err != nil {
		return result, err
	}
	_, outcome, err := service.Timed.Run(requestContext, pinned, settlementProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), timedReceipt{receipt.Resolver{Reader: service.ReceiptRead, Identity: identity, Fingerprint: fingerprint}}, func(requestContext context.Context, scope gen.TimedScope) error {
		stored, found, err := service.Receipts.FindTx(requestContext, scope.Tx, identity)
		if err != nil {
			return err
		}
		if found {
			if stored.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: identity}
			}
			return json.Unmarshal(stored.ResultPayload, &result)
		}
		root, found, err := service.Store.ReadCompetitionTx(requestContext, scope.Tx, true)
		if err != nil || !found || root.SettledThrough < season {
			return errors.Join(err, d.ErrRefused)
		}
		period, found, err := service.Store.ReadTournamentTx(requestContext, scope.Tx, season, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrRefused)
		}
		catalog, err := service.Content.ArenaCatalogTx(requestContext, scope.Tx, period.ContentRevision)
		if err != nil || catalog.Tournament == nil {
			return errors.Join(err, d.ErrUnavailable)
		}
		previousVersion := period.StateVersion
		if err := apply(requestContext, scope, *catalog.Tournament, &period); err != nil {
			return err
		}
		if period.StateVersion != previousVersion {
			if err := service.Store.SaveTournamentTx(requestContext, scope.Tx, period, previousVersion); err != nil {
				return err
			}
			rootVersion := root.StateVersion
			root.StateVersion++
			root.UpdatedAt = scope.Operation.DecisionAt()
			if err := service.Store.SaveCompetitionTx(requestContext, scope.Tx, root, rootVersion); err != nil {
				return err
			}
		}
		result = period
		payload, err := json.Marshal(period)
		if err != nil {
			return err
		}
		record, err := receipt.New(scope.Operation.Operation(), identity, "I9_7B_ARENA", "gxb.arena.tournament-work.v1", payload, fingerprint)
		if err != nil {
			return err
		}
		record.PolicyVersion = d.TournamentContractIdentifier
		_, err = service.Receipts.PutTx(requestContext, scope.Tx, record)
		return err
	})
	if err != nil || !outcome.Reconciled {
		return result, err
	}
	record, found, err := service.ReceiptRead.Find(requestContext, identity)
	if err != nil || !found {
		return result, errors.Join(err, d.ErrConflict)
	}
	err = json.Unmarshal(record.ResultPayload, &result)
	return result, err
}

func (service Service) AdvanceTournament(requestContext context.Context, season int64, operationContext operation.Context) (d.TournamentPeriod, error) {
	return service.tournamentPeriodWork(requestContext, season, operationContext, "advance", func(requestContext context.Context, scope gen.TimedScope, catalog d.TournamentCatalog, period *d.TournamentPeriod) error {
		stage := period.Calendar.StageAt(scope.Operation.DecisionAt())
		if stage < 2 || period.Settled {
			return nil
		}
		if err := period.LockRoster(scope.Operation.Operation()); err != nil {
			return err
		}
		for index, contest := range period.Contests {
			if contest.Complete || contest.Room.IsZero() {
				continue
			}
			room, found, err := service.Store.ReadTournamentRoomTx(requestContext, scope.Tx, contest.Room, false)
			if err != nil || !found {
				return errors.Join(err, d.ErrConflict)
			}
			if room.Status == d.RoomSettled {
				if err := period.CompleteContest(index, room.Winner); err != nil {
					return err
				}
			}
		}
		previousContests := len(period.Contests)
		prizeOwed := period.ChampionPrizeOwed
		if err := period.AdvanceBracket(stage); err != nil {
			return err
		}
		for _, contest := range period.Contests[previousContests:] {
			for _, player := range contest.Players {
				if player == 0 {
					continue
				}
				for index := range period.Supporters {
					if period.Supporters[index].Target == player && contest.Stage >= 4 && contest.Substage <= 1 {
						period.Supporters[index].Advancements++
					}
				}
			}
		}
		if !prizeOwed && period.ChampionPrizeOwed {
			for _, entrant := range period.Entrants {
				if entrant.Placement != 1 {
					continue
				}
				for index := range period.Supporters {
					if period.Supporters[index].Target == entrant.PlayerID {
						period.Supporters[index].Advancements++
					}
				}
			}
		}
		for index := range period.Contests {
			contest := &period.Contests[index]
			if contest.Complete || !contest.Room.IsZero() {
				continue
			}
			room, err := newTournamentRoom(*period, *contest)
			if err != nil {
				return err
			}
			if err := service.describeSelection(requestContext, scope, &room); err != nil {
				return err
			}
			if err := service.Store.SaveTournamentRoomTx(requestContext, scope.Tx, room, 0); err != nil {
				return err
			}
			contest.Room = room.Identifier
		}
		if stage == 8 && period.ChampionPrizeOwed {
			if err := service.awardTournamentTx(requestContext, scope, catalog, *period); err != nil {
				return err
			}
			period.Settled = true
			period.SettledAt = scope.Operation.DecisionAt()
		}
		period.StateVersion++
		return nil
	})
}

func newTournamentRoom(period d.TournamentPeriod, contest d.TournamentContest) (d.TournamentRoom, error) {
	identifier, err := ids.NewUUID()
	if err != nil {
		return d.TournamentRoom{}, err
	}
	first, firstFound := period.Entrant(contest.Players[0])
	second, secondFound := period.Entrant(contest.Players[1])
	if !firstFound || !secondFound || contest.Stage < 3 || contest.Stage > 7 {
		return d.TournamentRoom{}, d.ErrConflict
	}
	startsAt := period.Calendar.Stages[contest.Stage-1]
	if contest.Substage > 1 {
		startsAt = startsAt.Add(time.Duration(contest.Substage-1) * 20 * time.Minute)
	}
	selection, err := d.NewSelectionRoom(first.PlayerID, second.PlayerID, startsAt)
	if err != nil {
		return d.TournamentRoom{}, err
	}
	return d.TournamentRoom{Identifier: identifier, Season: period.Season, Stage: contest.Stage, Substage: contest.Substage, Contest: max(1, contest.Substage),
		Actors: [2]d.AdmissionContext{first.Actor, second.Actor}, Selection: selection, NoticeVersion: 1, Status: d.RoomPreparing, StartsAt: startsAt, ContentRevision: period.ContentRevision, StateVersion: 1}, nil
}

func tournamentRewardLines(reward d.TournamentReward) []grant.Line {
	lines := []grant.Line{}
	if reward.Crystal > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: reward.Crystal})
	}
	if reward.Mana > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "gold", Amount: reward.Mana})
	}
	return lines
}

func (service Service) awardTournamentTx(requestContext context.Context, scope gen.TimedScope, catalog d.TournamentCatalog, period d.TournamentPeriod) error {
	players := map[identity.PlayerID][]grant.Line{}
	for _, entrant := range period.Entrants {
		reward, found := catalog.RewardFor(entrant.Placement, false)
		if !found || entrant.Group == 0 {
			continue
		}
		players[entrant.PlayerID] = tournamentRewardLines(reward)
	}
	for _, supporter := range period.Supporters {
		current, err := catalog.Rules.SupportReward(supporter.Level, supporter.Advancements)
		if err != nil || supporter.EarnedMana > math.MaxInt64-current {
			return d.ErrConflict
		}
		amount := supporter.EarnedMana + current
		if amount > 0 {
			players[supporter.Player] = append(players[supporter.Player], grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "gold", Amount: amount})
		}
	}
	ordered := make([]identity.PlayerID, 0, len(players))
	for player := range players {
		ordered = append(ordered, player)
	}
	slices.Sort(ordered)
	for _, player := range ordered {
		if _, _, err := service.Mail.DeliverTx(requestContext, scope.Tx, i5.SettlementMailRequest{Recipient: player, SourceKind: "ARENA_PLAYOFFS_REWARD", SourceKey: strconv.FormatInt(period.Season, 10), Title: "Arena Playoffs", Sender: "Arena", Body: fmt.Sprintf("Season %d results and support rewards", period.Season), PolicyVersion: d.TournamentPolicyIdentifier, Lines: players[player], At: scope.Operation.DecisionAt()}); err != nil {
			return err
		}
	}
	return nil
}
