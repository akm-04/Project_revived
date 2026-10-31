package adventure

import (
	"context"

	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/adventure"
	darena "gxb.local/backend/v2/internal/domain/arena"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const pvpTerminalKind = "ADVENTURE_PVP_RESULT"

// Fight answers 2419: an Arena-section opponent (robot fallback), one server
// report, is_win beside the report and the win gift in the reply.
func (s Mode) Fight(c context.Context, a identity.ActorContext, request FightRequest, op operation.Context) (Response, error) {
	if err := validateFormation(request.Formation); err != nil || request.PetID < 0 {
		return Response{}, d.ErrInvalid
	}
	op, err := s.pin(c, op)
	if err != nil {
		return Response{}, err
	}
	var occurrence d.Occurrence
	var started cb.Started
	_, _, err = s.Timed.Run(c, op, profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		catalog, _, err := s.readCatalogs(c, sc.Tx, sc.Operation.Operation())
		if err != nil {
			return err
		}
		if err = s.admit(c, sc.Tx, a, catalog, at); err != nil {
			return err
		}
		if occurrence, err = s.activeOccurrence(c, sc.Tx, a.PlayerID, d.EventBattle, at); err != nil {
			return err
		}
		if err = s.ownedHeroes(c, sc.Tx, a, at, request.Formation); err != nil {
			return err
		}
		enemy, err := s.opponent(c, sc.Tx, a, catalog, eventOrdinal(sc.Operation.Operation(), "adventure.pvp.fight/v1", occurrence.SourceKey))
		if err != nil {
			return err
		}
		scope, err := s.coherentScope(sc, at)
		if err != nil {
			return err
		}
		started, err = s.Combat.StartTx(c, sc.Tx, scope, cb.StartRequest{Actor: a, Locator: locator(a, occurrence, "ADVENTURE_PVP"),
			GenerationRef: "ADVENTURE_PVP/" + occurrence.SourceKey, StartFingerprint: startFingerprint(a, sc.Operation.Operation().ID.String(), request.Formation),
			ResultDeadline: at.Add(attemptLimit), Battle: pvpBattle(a, request, enemy)})
		return err
	})
	if err != nil {
		return Response{}, err
	}
	if _, err = s.Combat.Resolve(c, op, started.Attempt.ID); err != nil {
		return Response{}, err
	}
	var response Response
	_, _, err = s.Timed.Run(c, op, profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		catalog, _, err := s.readCatalogs(c, sc.Tx, sc.Operation.Operation())
		if err != nil {
			return err
		}
		current, err := s.activeOccurrence(c, sc.Tx, a.PlayerID, d.EventBattle, at)
		if err != nil {
			if existing, found, readErr := s.Store.ReadOccurrenceTx(c, sc.Tx, a.PlayerID, d.EventBattle); readErr != nil {
				return readErr
			} else if found && existing.Finished() {
				response.Duplicate = true
				return nil
			}
			return err
		}
		terminal, err := s.Combat.TerminalTx(c, sc.Tx, cb.TerminalRequest{Locator: locator(a, current, "ADVENTURE_PVP"),
			GenerationRef: "ADVENTURE_PVP/" + current.SourceKey, TerminalKind: pvpTerminalKind,
			SemanticReceiptID: "adventure-pvp:" + started.Attempt.ID.String(), At: at})
		if err != nil {
			return err
		}
		star := terminal.Resolution.Outcome.Star
		awards := []any{}
		if d.IsWin(star) {
			reward, rewardLines := giftAwards(catalog, catalog.Limits.PVPGift)
			awards = reward
			if err = s.settleGrant(c, sc, a, "pvp_win", current, rewardLines); err != nil {
				return err
			}
		}
		if _, err = s.finish(c, sc.Tx, a, current, at); err != nil {
			return err
		}
		response.Body = map[string]any{"battle_report": string(terminal.Report), "is_win": boolNumber(d.IsWin(star)), "awards": awards}
		return nil
	})
	if err != nil {
		return Response{}, err
	}
	return response, nil
}

func pvpBattle(a identity.ActorContext, request FightRequest, enemy Opponent) cb.BattleRequest {
	teamA := make([]cb.Participant, 0, len(request.Formation))
	for _, id := range request.Formation {
		teamA = append(teamA, cb.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: a.PlayerID, Identity: id})
	}
	battle := cb.BattleRequest{CampaignType: darena.CampaignType, BattleID: darena.BattleID, TeamA: teamA}
	if request.PetID > 0 {
		battle.PetsA = []cb.Participant{{Origin: cd.OwnedSelf, Kind: cd.PetActor, Player: a.PlayerID, Identity: request.PetID}}
	}
	if len(enemy.TemplateHeroes) > 0 {
		battle.WavesB = [][]cb.Participant{enemy.TemplateHeroes}
		return battle
	}
	teamB := make([]cb.Participant, 0, len(enemy.Heroes))
	for _, id := range enemy.Heroes {
		teamB = append(teamB, cb.Participant{Origin: cd.OwnedForeign, Kind: cd.HeroActor, Player: enemy.PlayerID, Identity: id})
	}
	battle.WavesB = [][]cb.Participant{teamB}
	if enemy.PetID > 0 {
		battle.PetsB = []cb.Participant{{Origin: cd.OwnedForeign, Kind: cd.PetActor, Player: enemy.PlayerID, Identity: enemy.PetID}}
	}
	return battle
}

func boolNumber(value bool) int64 {
	if value {
		return 1
	}
	return 0
}
