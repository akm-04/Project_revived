package adventure

import (
	"context"

	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/adventure"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
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
		placeholder, err := ids.NewUUID()
		if err != nil {
			return nil, err
		}
		attempt := d.SingleAttempt{ID: placeholder.String(), PlayerID: a.PlayerID, EventType: d.EventIllusion, OccurredAt: occurrence.OccurredAt, CreatedAt: at}
		if err = s.Store.InsertAttemptTx(c, sc.Tx, attempt); err != nil {
			return nil, err
		}
		started, err := s.Combat.StartTx(c, sc.Tx, scope, cb.StartRequest{Actor: a, Locator: locator(a, occurrence, "ADVENTURE_ILLUSION"),
			GenerationRef:    "ADVENTURE_ILLUSION/" + occurrence.SourceKey,
			StartFingerprint: startFingerprint(a, sc.Operation.Operation().ID.String(), request.Formation),
			ResultDeadline:   at.Add(attemptLimit), TrustProfile: cd.ClientSummaryAttested, Replay: cd.ReplaySpec{Response: cd.ReplayOK},
			Battle: cb.BattleRequest{CampaignType: campaign.CampaignType, BattleID: campaign.FightID,
				TeamA: ownedTeam(a.PlayerID, request.Formation), Formation: request.Formation}})
		if err != nil {
			return nil, err
		}
		if started.Replayed {
			return map[string]any{}, s.Store.DeleteAttemptTx(c, sc.Tx, placeholder.String(), a.PlayerID)
		}
		return map[string]any{}, s.Store.RenameAttemptTx(c, sc.Tx, placeholder.String(), started.Attempt.ID.String(), a.PlayerID)
	})
}

// SettleSingle answers 2422: the attested summary is clamped and credited once
// to the frozen 10006 occurrence, with the single gift in the reply.
func (s Mode) SettleSingle(c context.Context, a identity.ActorContext, request ResultRequest, op operation.Context) (Response, error) {
	if request.Star < 0 || request.Star > d.MaxSoloStar || request.Damage < 0 || request.PetID < 0 || validateFormation(request.Formation) != nil {
		return Response{}, d.ErrInvalid
	}
	var response Response
	body, err := s.run(c, a, op, func(c context.Context, sc gen.TimedScope, catalog d.Catalog, _ illusion.Catalog) (map[string]any, error) {
		at := sc.Operation.DecisionAt()
		occurrence, err := s.activeOccurrence(c, sc.Tx, a.PlayerID, d.EventIllusion, at)
		if err != nil {
			if existing, found, readErr := s.Store.ReadOccurrenceTx(c, sc.Tx, a.PlayerID, d.EventIllusion); readErr != nil {
				return nil, readErr
			} else if found && existing.Finished() {
				response.Duplicate = true
				return map[string]any{}, nil
			}
			return nil, err
		}
		attempt, found, err := s.Store.FindLatestAttemptTx(c, sc.Tx, a.PlayerID, d.EventIllusion)
		if err != nil {
			return nil, err
		}
		if !found {
			return nil, d.ErrRefused
		}
		if attempt.Resolved {
			response.Duplicate = true
			return map[string]any{}, nil
		}
		if !attempt.OccurredAt.Equal(occurrence.OccurredAt) {
			return nil, d.ErrExpired
		}
		attested, err := s.Combat.AttestSummaryTx(c, sc.Tx, cb.SummaryRequest{Locator: locator(a, occurrence, "ADVENTURE_ILLUSION"),
			GenerationRef: "ADVENTURE_ILLUSION/" + occurrence.SourceKey, TerminalKind: fantasyTerminalKind, At: at, Policy: singleSummaryPolicy,
			Summary: cd.Summary{Star: request.Star, Win: d.IsWin(request.Star) || request.Damage > 0, Damage: request.Damage, Formation: request.Formation}})
		if err != nil {
			return nil, err
		}
		if attested.Drained || attested.Attestation.Verdict == cd.VerdictRejected {
			response.Duplicate = true
			return map[string]any{}, nil
		}
		star, damage := d.ClampSolo(request.Star, request.Damage, illusion.DamageCap, 0)
		attempt.Resolved, attempt.Damage = true, damage
		if err = s.Store.SaveAttemptTx(c, sc.Tx, attempt); err != nil {
			return nil, err
		}
		awards := []any{}
		if d.IsWin(star) {
			reward, lines := giftAwards(catalog, catalog.Limits.IllusionGiftSingle)
			awards = reward
			if err = s.settleGrant(c, sc, a, "illusion_single", occurrence, lines); err != nil {
				return nil, err
			}
		}
		if _, err = s.finish(c, sc.Tx, a, occurrence, at); err != nil {
			return nil, err
		}
		return map[string]any{"awards": awards}, nil
	})
	return Response{Body: body, Duplicate: response.Duplicate}, err
}

func ownedTeam(player identity.PlayerID, formation []int64) []cb.Participant {
	team := make([]cb.Participant, 0, len(formation))
	for _, id := range formation {
		team = append(team, cb.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: player, Identity: id})
	}
	return team
}
