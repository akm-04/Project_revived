package adventure

import (
	"context"
	"fmt"

	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/adventure"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const fantasyTerminalKind = "ADVENTURE_ILLUSION_RESULT"

// StartSingle answers 2421: one client-run Fantasy attempt frozen to the
// active 10006 occurrence. A replayed start reuses the frozen attempt.
func (s Mode) StartSingle(c context.Context, a identity.ActorContext, request FightRequest, op operation.Context) (map[string]any, error) {
	if err := validateFormation(request.Formation); err != nil || request.PetID < 0 {
		return nil, d.ErrInvalid
	}
	return s.run(c, a, op, func(c context.Context, sc gen.TimedScope, catalog d.Catalog, fantasy illusion.Catalog) (map[string]any, error) {
		at := sc.Operation.DecisionAt()
		occurrence, err := s.activeOccurrence(c, sc.Tx, a.PlayerID, d.EventIllusion, at)
		if err != nil {
			return nil, err
		}
		campaign, found := fantasy.Campaign(occurrence.SpecialData)
		if !found {
			return nil, d.ErrUnavailable
		}
		if err = s.ownedHeroes(c, sc.Tx, a, at, request.Formation); err != nil {
			return nil, err
		}
		scope, err := s.coherentScope(sc, at)
		if err != nil {
			return nil, err
		}
		_, err = s.startAttempt(c, sc, scope, cb.StartRequest{Mode: cd.ModeAdventureIllusion, Actor: a, Locator: singleLocator(a),
			GenerationRef:    d.FantasyGeneration(occurrence),
			StartFingerprint: startFingerprint(a, request.Formation),
			ResultDeadline:   at.Add(attemptLimit), TrustProfile: cd.ClientSummaryAttested, Replay: cd.ReplaySpec{Response: cd.ReplayOK},
			Battle: cb.BattleRequest{CampaignType: campaign.CampaignType, RentalMode: d.IllusionSingleRentalMode, BattleID: campaign.FightID,
				TeamA: ownedTeam(a.PlayerID, request.Formation), Formation: request.Formation}})
		return map[string]any{}, err
	})
}

// SettleSingle answers 2422: the attested summary is clamped and credited once
// to the occurrence its Combat attempt froze, with the single gift in the reply.
func (s Mode) SettleSingle(c context.Context, a identity.ActorContext, request ResultRequest, op operation.Context) (Response, error) {
	if request.Star < 0 || request.Star > d.MaxSoloStar || request.Damage < 0 || request.PetID < 0 || validateFormation(request.Formation) != nil {
		return Response{}, d.ErrInvalid
	}
	var duplicate bool
	body, err := s.run(c, a, op, func(c context.Context, sc gen.TimedScope, catalog d.Catalog, _ illusion.Catalog) (map[string]any, error) {
		at := sc.Operation.DecisionAt()
		// shortcut: 2422 carries no attempt token, so a result delayed past a new
		// 2421 cannot be told from that fresh START; add a client attempt id if the
		// stock wire ever gains one.
		current, found, err := s.Combat.CurrentAttemptTx(c, sc.Tx, singleLocator(a))
		if err != nil {
			return nil, err
		}
		if !found {
			return nil, fmt.Errorf("%w: no open attempt", d.ErrRefused)
		}
		if current.Attempt.State == cd.Terminal {
			_, settled, err := s.Store.ReadSettlementTx(c, sc.Tx, current.Attempt.ID)
			if err != nil {
				return nil, err
			}
			if !settled {
				return nil, fmt.Errorf("%w: no open attempt", d.ErrRefused)
			}
			duplicate = true
			return map[string]any{}, nil
		}
		occurrence, err := s.frozenOccurrence(c, sc.Tx, a.PlayerID, current.Attempt.GenerationRef)
		if err != nil {
			return nil, err
		}
		attested, err := s.Combat.AttestSummaryTx(c, sc.Tx, cb.SummaryRequest{Locator: singleLocator(a),
			GenerationRef: current.Attempt.GenerationRef, TerminalKind: fantasyTerminalKind, At: at, Policy: singleSummaryPolicy,
			Summary: cd.Summary{Star: request.Star, Win: d.IsWin(request.Star) || request.Damage > 0, Damage: request.Damage, Formation: request.Formation}})
		if err != nil {
			return nil, err
		}
		if attested.Drained {
			_, settled, err := s.Store.ReadSettlementTx(c, sc.Tx, current.Attempt.ID)
			if err != nil {
				return nil, err
			}
			if !settled {
				return nil, fmt.Errorf("%w: summary drained or rejected", d.ErrRefused)
			}
			duplicate = true
			return map[string]any{}, nil
		}
		if attested.Attestation.Verdict == cd.VerdictRejected {
			return nil, fmt.Errorf("%w: summary drained or rejected", d.ErrRefused)
		}
		star, damage := d.ClampSolo(request.Star, request.Damage, catalog.Limits.IllusionTotalDamage, 0)
		if err = s.Store.InsertSettlementTx(c, sc.Tx, current.Attempt.ID, a.PlayerID, damage, at); err != nil {
			return nil, err
		}
		body := map[string]any{}
		if d.IsWin(star) {
			reward, lines := giftAwards(catalog, catalog.Limits.IllusionGiftSingle)
			// The client closes the single battle only on a nil awards key.
			if len(reward) > 0 {
				body["awards"] = reward
			}
			if err = s.settleGrant(c, sc, a, "illusion_single", occurrence, lines); err != nil {
				return nil, err
			}
		}
		if _, err = s.finish(c, sc.Tx, a, occurrence, at); err != nil {
			return nil, err
		}
		return body, nil
	})
	return Response{Body: body, Duplicate: duplicate}, err
}

// frozenOccurrence reads the occurrence the attempt's generation names, never
// the occurrence that has moved on since START.
func (s Mode) frozenOccurrence(c context.Context, q tx.Queryer, playerID identity.PlayerID, reference string) (d.Occurrence, error) {
	sourceKey, ok := d.ParseFantasyGeneration(reference)
	if !ok {
		return d.Occurrence{}, fmt.Errorf("adventure: malformed attempt generation %q", reference)
	}
	occurrence, found, err := s.Store.ReadOccurrenceBySourceKeyTx(c, q, playerID, d.EventIllusion, sourceKey)
	if err != nil {
		return d.Occurrence{}, err
	}
	if !found {
		return d.Occurrence{}, d.ErrExpired
	}
	return occurrence, nil
}

// singleLocator is stable across occurrences: 2422 carries no generation, so
// the attempt must be found from the player alone.
func singleLocator(a identity.ActorContext) cd.Locator {
	return cd.Locator{DomainKind: "ADVENTURE_ILLUSION", AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID),
		DomainLocator: fmt.Sprintf("player:%d", a.PlayerID)}
}

func ownedTeam(player identity.PlayerID, formation []int64) []cb.Participant {
	team := make([]cb.Participant, 0, len(formation))
	for _, id := range formation {
		team = append(team, cb.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: player, Identity: id})
	}
	return team
}
