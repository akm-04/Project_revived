package arena

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"slices"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/arena"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const tournamentTransform = "REGION_ARENA_PLAYOFFS_AWAKE_V1"

func tournamentLocator(room ids.UUID, round int) cd.Locator {
	return cd.Locator{DomainKind: "ARENA_PLAYOFFS", AuthorityScope: d.CompetitionID, DomainLocator: fmt.Sprintf("%s:%d", room.String(), round)}
}

func tournamentParticipants(player identity.PlayerID, formation d.SelectedFormation, origin cd.Origin) ([]combat.Participant, []combat.Participant) {
	heroes := make([]combat.Participant, 0, len(formation.Heroes))
	for _, identifier := range formation.Heroes {
		heroes = append(heroes, combat.Participant{Origin: origin, Kind: cd.HeroActor, Player: player, Identity: identifier})
	}
	pets := []combat.Participant{}
	if formation.Pet != 0 {
		pets = append(pets, combat.Participant{Origin: origin, Kind: cd.PetActor, Player: player, Identity: formation.Pet})
	}
	return heroes, pets
}

func (service Service) StartTournamentCombat(requestContext context.Context, identifier ids.UUID, operationContext operation.Context) (d.TournamentRoom, error) {
	return service.roomWork(requestContext, identifier, operationContext, "start-combat", func(requestContext context.Context, scope gen.TimedScope, room *d.TournamentRoom) error {
		if room.Status != d.RoomFighting || !room.Selection.Complete() || len(room.Attempts) != 0 {
			return nil
		}
		actor, err := room.Actors[0].Actor()
		if err != nil {
			return err
		}
		revision, found := scope.Operation.Operation().Policies.Get("content")
		if !found {
			return d.ErrUnavailable
		}
		coherent, err := ca.NewCoherentReadScope(tx.Scope{Tx: scope.Tx, Operation: scope.Operation.Operation(), Attempt: scope.Attempt, Options: scope.Options}, revision, scope.Operation.DecisionAt())
		if err != nil {
			return err
		}
		for side, player := range room.Selection.Players {
			face, err := service.face(requestContext, scope.Tx, player)
			if err != nil {
				return err
			}
			room.Faces[side] = face
		}
		requests := []combat.StartRequest{}
		requestRounds := []int{}
		rosters := [2]d.SelectionRoster{}
		for side, player := range room.Selection.Players {
			rosters[side], err = service.selectionRoster(requestContext, scope.Tx, scope, player)
			if err != nil {
				return err
			}
		}
		for round := range d.SelectionTeamCount {
			formations := [2]d.SelectedFormation{room.Selection.Teams[0][round], room.Selection.Teams[1][round]}
			for side, formation := range formations {
				if validateRoomFormation(formation, rosters[side]) != nil {
					formations[side] = d.SelectedFormation{}
				}
			}
			if len(formations[0].Heroes) == 0 || len(formations[1].Heroes) == 0 {
				room.RoundResults[round] = d.RoundBothEmpty
				if len(formations[0].Heroes) != 0 {
					room.RoundResults[round] = d.RoundFirstWin
				}
				if len(formations[1].Heroes) != 0 {
					room.RoundResults[round] = d.RoundSecondWin
				}
				continue
			}
			first, firstPets := tournamentParticipants(actor.PlayerID, formations[0], cd.OwnedSelf)
			second, secondPets := tournamentParticipants(room.Selection.Players[1], formations[1], cd.OwnedForeign)
			battle := combat.BattleRequest{CampaignType: d.CampaignType, BattleID: d.BattleID, TeamA: first, PetsA: firstPets, WavesB: [][]combat.Participant{second}, PetsB: secondPets, Context: &cd.BattleContext{Transform: tournamentTransform}}
			payload, err := cd.CanonicalJSON(map[string]any{"room": room.Identifier, "round": round + 1, "teams": formations, "revision": revision})
			if err != nil {
				return err
			}
			digest := sha256.Sum256(payload)
			requests = append(requests, combat.StartRequest{Actor: actor, Locator: tournamentLocator(room.Identifier, round+1), GenerationRef: d.TournamentContractIdentifier, StartFingerprint: hex.EncodeToString(digest[:]), ResultDeadline: scope.Operation.DecisionAt().Add(resultWindow), Battle: battle})
			requestRounds = append(requestRounds, round)
		}
		room.Attempts = make([]ids.UUID, d.SelectionTeamCount)
		if len(requests) != 0 {
			started, err := service.Combat.StartManyTx(requestContext, scope.Tx, coherent, requests)
			if err != nil {
				return err
			}
			for index, attempt := range started {
				if attempt.Replayed {
					return d.ErrConflict
				}
				room.Attempts[requestRounds[index]] = attempt.Attempt.ID
			}
		}
		room.StateVersion++
		room.NoticeVersion++
		return nil
	})
}

func validateRoomFormation(formation d.SelectedFormation, roster d.SelectionRoster) error {
	if len(formation.Heroes) == 0 || len(formation.Heroes) > d.TeamSize {
		return d.ErrRefused
	}
	seen := map[int64]bool{}
	for _, identifier := range formation.Heroes {
		position := slices.IndexFunc(roster.Heroes, func(hero d.SelectionHero) bool { return hero.Identifier == identifier })
		if position < 0 || seen[roster.Heroes[position].TableIdentifier] {
			return d.ErrRefused
		}
		seen[roster.Heroes[position].TableIdentifier] = true
	}
	if formation.Pet != 0 && !slices.Contains(roster.Pets, formation.Pet) {
		return d.ErrRefused
	}
	return nil
}

func (service Service) ResolveTournamentCombat(requestContext context.Context, identifier ids.UUID, operationContext operation.Context) (d.TournamentRoom, error) {
	if !service.ready() || identifier.IsZero() {
		return d.TournamentRoom{}, d.ErrUnavailable
	}
	room, found, err := service.Store.ReadTournamentRoomTx(requestContext, service.Fresh, identifier, false)
	if err != nil || !found {
		return room, d.ErrRefused
	}
	if room.Status != d.RoomFighting || len(room.Attempts) != d.SelectionTeamCount {
		return room, nil
	}
	wins := [2]int{}
	for index, attempt := range room.Attempts {
		if wins[0] >= 2 || wins[1] >= 2 {
			break
		}
		winner := room.RoundResults[index]
		if winner == 0 {
			if attempt.IsZero() {
				return room, d.ErrConflict
			}
			flight := service.Combat.ResolveDetached(requestContext, operationContext, attempt)
			select {
			case <-requestContext.Done():
				return room, requestContext.Err()
			case <-flight.Done:
			}
			if flight.Err != nil {
				return room, flight.Err
			}
			winner = 2
			if flight.Resolved.Resolution.Outcome.Star > 0 {
				winner = 1
			}
		}
		if winner == 1 || winner == 2 {
			wins[winner-1]++
		}
	}
	return service.roomWork(requestContext, identifier, operationContext, "settle-combat", func(requestContext context.Context, scope gen.TimedScope, current *d.TournamentRoom) error {
		if current.Status == d.RoomSettled {
			return nil
		}
		if current.Status != d.RoomFighting || len(current.Attempts) != d.SelectionTeamCount {
			return d.ErrConflict
		}
		current.Wins = [2]int{}
		for round, attempt := range current.Attempts {
			if current.Wins[0] >= 2 || current.Wins[1] >= 2 {
				break
			}
			winner := current.RoundResults[round]
			if winner == 0 {
				settled, err := service.Combat.TerminalTx(requestContext, scope.Tx, combat.TerminalRequest{Locator: tournamentLocator(current.Identifier, round+1), GenerationRef: d.TournamentContractIdentifier, TerminalKind: "ARENA_PLAYOFFS_SETTLED", SemanticReceiptID: fmt.Sprintf("arena-playoffs:%s:%d", current.Identifier.String(), round+1), At: scope.Operation.DecisionAt()})
				if err != nil {
					return err
				}
				if settled.Attempt.ID != attempt {
					return d.ErrConflict
				}
				winner = 2
				if settled.Resolution.Outcome.Star > 0 {
					winner = 1
				}
				current.RoundResults[round] = winner
				current.GenuineBattles++
			}
			if winner == 1 || winner == 2 {
				current.Wins[winner-1]++
			}
		}
		if current.Wins[0] > current.Wins[1] {
			current.Winner = current.Selection.Players[0]
		}
		if current.Wins[1] > current.Wins[0] {
			current.Winner = current.Selection.Players[1]
		}
		at := scope.Operation.DecisionAt()
		if current.GenuineBattles > 0 {
			for _, player := range sortedPlayers(current.Selection.Players[0], current.Selection.Players[1]) {
				if current.Casual {
					if err := service.Store.AddCasualResultTx(requestContext, scope.Tx, current.CasualWeekDay, player, current.Winner == player, at); err != nil {
						return err
					}
				}
				prepared, err := service.Facts.PrepareTx(requestContext, scope.Tx, player, scope.Operation)
				if err != nil {
					return err
				}
				fact := objective.Fact{PlayerID: player, SourceDomain: "arena-playoffs", SourceBusinessKey: current.Identifier.String(), Kind: objective.PVPFightKind, Delta: 1}
				if err := service.Facts.RecordTx(prepared, scope.Tx, scope.Operation.Operation(), fact); err != nil {
					return err
				}
			}
		}
		if current.Casual {
			for _, player := range current.Selection.Players {
				entry, found, err := service.Store.ActiveCasualEntryTx(requestContext, scope.Tx, player)
				if err != nil || !found || entry.Room != current.Identifier {
					return d.ErrConflict
				}
				previousVersion := entry.StateVersion
				entry.Status, entry.StateVersion = d.QueueFinished, previousVersion+1
				if err := service.Store.SaveCasualEntryTx(requestContext, scope.Tx, entry, previousVersion); err != nil {
					return err
				}
			}
		}
		current.Status, current.SettledAt = d.RoomSettled, at
		current.StateVersion++
		current.NoticeVersion++
		return nil
	})
}
