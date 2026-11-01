package illusion

import (
	"context"
	"fmt"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var summaryPolicy = cd.SummaryPolicy{ID: "I9_ILLUSION_SUMMARY_V1", Version: 1, MaxStar: 1, MaxDamage: d.DamageCap}

// Info answers 1344 from canonical state; paradise_id is a real campaign row and
// count is zero only while the window is open.
// It answers below the unlock because the stock main scene sends it at every
// lobby load and indexes paradise_info on any 200.
func (s Mode) Info(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	occurrence, found, err := s.Store.ReadOccurrenceTx(c, s.Fresh, int64(a.LogicalServerID))
	if err != nil {
		return nil, err
	}
	if !found {
		occurrence = d.NewOccurrence(int64(a.LogicalServerID), d.FirstCampaignID, modes.Day(at))
	}
	player, found, err := s.Store.ReadPlayerTx(c, s.Fresh, a.PlayerID)
	if err != nil {
		return nil, err
	}
	if !found {
		player = d.Player{PlayerID: int64(a.PlayerID)}
	}
	player.Reset(modes.Day(at))
	hurt, rank, err := s.personalPlace(c, s.Fresh, occurrence, a.PlayerID)
	if err != nil {
		return nil, err
	}
	revision, _ := op.Policies.Get("content")
	catalog, err := s.Content.IllusionCatalogTx(c, s.Fresh, revision)
	if err != nil {
		return nil, err
	}
	return infoBody(catalog, occurrence, player, hurt, rank, at), nil
}

// Buy answers 1345: the next refresh_cost ladder entry, capped by
// vip.paradise_buy_num, adds chances_per_buy chances through the I5 debiter.
func (s Mode) Buy(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	response, err := s.run(c, a, "buy", struct{}{}, op, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (Response, error) {
		at := sc.Operation.DecisionAt()
		st, err := s.open(c, sc, a, catalog)
		if err != nil {
			return Response{}, err
		}
		if !st.occurrence.CanStart(at) {
			return Response{}, fmt.Errorf("%w: illusion window closed", d.ErrRefused)
		}
		privilege, err := s.Privileges.SnapshotTx(c, sc.Tx, a.PlayerID, at)
		if err != nil {
			return Response{}, err
		}
		cost, err := st.player.Buy(catalog, privilege.VIPLevel)
		if err != nil {
			return Response{}, err
		}
		if err = s.Store.SavePlayerTx(c, sc.Tx, st.player, at); err != nil {
			return Response{}, err
		}
		if _, err = s.Costs.DebitMaterialCostTx(c, sc.Tx, a.PlayerID, i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: cost}}}, sc.Operation.Operation()); err != nil {
			return Response{}, err
		}
		return Response{Body: map[string]any{"challenge_times": st.player.Chances, "buy_times": st.player.Bought}}, nil
	})
	return response.Body, err
}

// Start answers 1346: one chance is consumed and the attempt is frozen to the
// current occurrence. A new start supersedes the player's abandoned attempt.
func (s Mode) Start(c context.Context, a identity.ActorContext, request StartRequest, op operation.Context) (map[string]any, error) {
	if err := validateFormation(request.Formation); err != nil {
		return nil, err
	}
	response, err := s.run(c, a, "start", request, op, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (Response, error) {
		at := sc.Operation.DecisionAt()
		st, err := s.open(c, sc, a, catalog)
		if err != nil {
			return Response{}, err
		}
		if !st.occurrence.CanStart(at) {
			return Response{}, fmt.Errorf("%w: illusion window closed", d.ErrRefused)
		}
		campaign, ok := catalog.Campaign(st.occurrence.CampaignID)
		if !ok {
			return Response{}, d.ErrUnavailable
		}
		if err = s.ownedHeroes(c, sc.Tx, a, at, request.Formation); err != nil {
			return Response{}, err
		}
		if err = st.player.ConsumeChance(); err != nil {
			return Response{}, err
		}
		started, err := s.bind(c, sc, a, st.occurrence, campaign, request)
		if err != nil {
			return Response{}, err
		}
		attempt := d.Attempt{ID: started.Attempt.ID.String(), PlayerID: int64(a.PlayerID), LogicalServerID: int64(a.LogicalServerID),
			OpenDay: st.occurrence.OpenDay, CampaignID: st.occurrence.CampaignID, Formation: formationText(request.Formation), FrozenAt: at.Unix()}
		if err = s.Store.InsertAttemptTx(c, sc.Tx, attempt); err != nil {
			return Response{}, err
		}
		if err = s.Store.SavePlayerTx(c, sc.Tx, st.player, at); err != nil {
			return Response{}, err
		}
		return Response{Body: map[string]any{}}, nil
	})
	return response.Body, err
}

func (s Mode) bind(c context.Context, sc gen.TimedScope, a identity.ActorContext, occurrence d.Occurrence, campaign d.Campaign, request StartRequest) (cb.Started, error) {
	formation, petID := request.Formation, request.PetID
	op := sc.Operation.Operation()
	revision, _ := op.Policies.Get("content")
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: op, Attempt: sc.Attempt, Options: sc.Options}, revision, sc.Operation.DecisionAt())
	if err != nil {
		return cb.Started{}, err
	}
	battle := cb.BattleRequest{CampaignType: campaign.CampaignType, BattleID: campaign.FightID, Formation: formation}
	for _, id := range formation {
		battle.TeamA = append(battle.TeamA, cb.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: a.PlayerID, Identity: id})
	}
	if petID > 0 {
		battle.PetsA = append(battle.PetsA, cb.Participant{Origin: cd.OwnedSelf, Kind: cd.PetActor, Player: a.PlayerID, Identity: petID})
	}
	if request.RentUnit > 0 && request.RentPlayer > 0 {
		battle.TeamA = append(battle.TeamA, cb.Participant{Origin: cd.Borrowed, Kind: cd.HeroActor, Player: identity.PlayerID(request.RentPlayer), Identity: request.RentUnit})
	}
	if request.RentPetUnit > 0 && request.RentPetPlayer > 0 {
		battle.PetsA = append(battle.PetsA, cb.Participant{Origin: cd.Borrowed, Kind: cd.PetActor, Player: identity.PlayerID(request.RentPetPlayer), Identity: request.RentPetUnit})
	}
	return s.Combat.StartTx(c, sc.Tx, scope, cb.StartRequest{Actor: a, Locator: locator(a), GenerationRef: generationRef(occurrence),
		StartFingerprint: startFingerprint(a, request, op), ResultDeadline: sc.Operation.DecisionAt().Add(attemptLimit),
		Battle: battle, TrustProfile: cd.ClientSummaryAttested, Replay: cd.ReplaySpec{Response: cd.ReplayOK}})
}

// Settle answers 1347: the attested summary is clamped and credited once to the
// attempt's frozen occurrence. A duplicate terminal answers 30005 with the body.
func (s Mode) Settle(c context.Context, a identity.ActorContext, request ResultRequest, op operation.Context) (Response, error) {
	if request.Star < 0 || request.Star > 1 || request.Damage < 0 || request.CostTime < 0 || request.PetID < 0 || validateFormation(request.Formation) != nil {
		return Response{}, d.ErrInvalid
	}
	return s.run(c, a, "settle", request, op, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (Response, error) {
		at := sc.Operation.DecisionAt()
		st, err := s.open(c, sc, a, catalog)
		if err != nil {
			return Response{}, err
		}
		// shortcut: 1347 carries no attempt token, so a result delayed past a new
		// 1346 cannot be told from that fresh START; add a client attempt id if the
		// stock wire ever gains one.
		attempt, found, err := s.Store.FindLatestAttemptTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return Response{}, err
		}
		if found && attempt.Resolved {
			body, err := s.terminalBody(c, sc.Tx, attempt, identity.PlayerID(st.player.PlayerID), attempt.Damage)
			return Response{Body: body, Duplicate: err == nil}, err
		}
		if !found {
			return Response{}, fmt.Errorf("%w: no open attempt", d.ErrRefused)
		}
		attested, err := s.Combat.AttestSummaryTx(c, sc.Tx, cb.SummaryRequest{Locator: locator(a), GenerationRef: generationRefForAttempt(attempt), TerminalKind: "ILLUSION_RESULT", At: at, Policy: summaryPolicy,
			Summary: cd.Summary{Star: request.Star, Win: request.Star > 0 || request.Damage > 0, Damage: request.Damage, Formation: request.Formation, Pet: request.PetID}})
		if err != nil {
			return Response{}, err
		}
		if attested.Drained || attested.Attestation.Verdict == cd.VerdictRejected {
			return Response{}, fmt.Errorf("%w: summary drained or rejected", d.ErrRefused)
		}
		current := attempt.Matches(st.occurrence)
		accepted := request.Damage
		if current {
			accepted = st.occurrence.Accept(request.Damage)
		} else if accepted > d.DamageCap {
			accepted = d.DamageCap
		}
		if err = s.creditResult(c, sc, attempt, accepted, request.CostTime, at); err != nil {
			return Response{}, err
		}
		attempt.Resolved, attempt.Damage = true, accepted
		if err = s.Store.SaveAttemptTx(c, sc.Tx, attempt); err != nil {
			return Response{}, err
		}
		if current {
			if err = s.Store.SaveOccurrenceTx(c, sc.Tx, st.occurrence, at); err != nil {
				return Response{}, err
			}
			st.player.RecordHit(accepted, request.CostTime)
			if err = s.Store.SavePlayerTx(c, sc.Tx, st.player, at); err != nil {
				return Response{}, err
			}
		}
		if err = s.recordFantasy(c, sc, a, attempt.ID); err != nil {
			return Response{}, err
		}
		body, err := s.terminalBody(c, sc.Tx, attempt, a.PlayerID, accepted)
		if err != nil {
			return Response{}, err
		}
		return Response{Body: body}, nil
	})
}

func generationRefForAttempt(attempt d.Attempt) string {
	return fmt.Sprintf("ILLUSION/%d/%d/%d", attempt.LogicalServerID, attempt.OpenDay, attempt.CampaignID)
}

func (s Mode) creditResult(c context.Context, sc gen.TimedScope, attempt d.Attempt, accepted, costTime int64, at time.Time) error {
	result, err := s.Store.LockResultTx(c, sc.Tx, attempt.LogicalServerID, attempt.OpenDay, attempt.CampaignID, identity.PlayerID(attempt.PlayerID), at)
	if err != nil {
		return err
	}
	if accepted > result.Hurt || accepted == result.Hurt && costTime < result.CostTime {
		result.Hurt, result.CostTime = accepted, costTime
	}
	return s.Store.SaveResultTx(c, sc.Tx, attempt.LogicalServerID, attempt.OpenDay, attempt.CampaignID, result, at)
}

func (s Mode) recordFantasy(c context.Context, sc gen.TimedScope, a identity.ActorContext, attemptID string) error {
	prepared, err := s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
	if err != nil {
		return err
	}
	fact := objective.Fact{PlayerID: a.PlayerID, SourceDomain: "illusion", SourceBusinessKey: attemptID, Kind: fantasyFactKind, Delta: 1}
	return s.Facts.RecordTx(prepared, sc.Tx, sc.Operation.Operation(), fact)
}

// terminalBody is the 1347 reply for the occurrence the attempt was frozen to.
func (s Mode) terminalBody(c context.Context, q tx.Queryer, attempt d.Attempt, playerID identity.PlayerID, damage int64) (map[string]any, error) {
	ranks, err := s.Store.ReadRankTx(c, q, attempt.LogicalServerID, attempt.OpenDay, rankLimit)
	if err != nil {
		return nil, err
	}
	rank, _ := d.RankOf(ranks, int64(playerID))
	best, found, err := s.Store.ReadResultTx(c, q, attempt.LogicalServerID, attempt.OpenDay, attempt.CampaignID, playerID)
	if err != nil {
		return nil, err
	}
	highest := int64(0)
	if found {
		highest = best.Hurt
	}
	pre, err := s.preInfo(c, q, ranks, playerID)
	if err != nil {
		return nil, err
	}
	body := map[string]any{"rank": rank, "now_hurt": damage, "highest_hurt": highest}
	if pre != nil {
		body["pre_info"] = pre
	}
	return body, nil
}

func (s Mode) personalPlace(c context.Context, q tx.Queryer, occurrence d.Occurrence, playerID identity.PlayerID) (int64, int64, error) {
	ranks, err := s.Store.ReadRankTx(c, q, occurrence.LogicalServerID, occurrence.OpenDay, rankLimit)
	if err != nil {
		return 0, 0, err
	}
	rank, hurt := d.RankOf(ranks, int64(playerID))
	return hurt, rank, nil
}

// MemberTeam answers 1364 with the member's frozen formation and current roster
// rows, which the stock rank window populates as heroes. The target must belong
// to the actor's logical server, and the formation is the attempt of the current
// ranked occurrence.
func (s Mode) MemberTeam(c context.Context, a identity.ActorContext, memberID identity.PlayerID, _ operation.Context) (map[string]any, error) {
	if !s.ready() {
		return nil, d.ErrUnavailable
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	if err = s.eligible(c, s.Fresh, a, at); err != nil {
		return nil, err
	}
	if logicalserver.PlayerRegion(memberID) != a.LogicalServerID {
		return nil, fmt.Errorf("%w: target is on another logical server", d.ErrRefused)
	}
	profile, found, err := s.Directory.ProfileTx(c, s.Fresh, memberID)
	if err != nil {
		return nil, err
	}
	if !found {
		return nil, d.ErrRefused
	}
	out := map[string]any{"heros": []map[string]any{}, "book_shelf_lev": int64(0), "is_robot": false,
		"conquer_lev": profile.ConquerLevel, "conquer_loop_id": profile.ConquerLoopID}
	occurrence, found, err := s.Store.ReadOccurrenceTx(c, s.Fresh, int64(a.LogicalServerID))
	if err != nil || !found {
		return out, err
	}
	attempt, found, err := s.Store.FindAttemptTx(c, s.Fresh, memberID, int64(a.LogicalServerID), occurrence.OpenDay, occurrence.CampaignID)
	if err != nil || !found {
		return out, err
	}
	formation := parseFormationText(attempt.Formation)
	if len(formation) == 0 {
		return out, nil
	}
	detail := map[string]any{}
	if err = s.Heroes.OverlayMID1(c, s.Fresh, identity.ActorContext{PlayerID: memberID}, false, at, detail); err != nil {
		return nil, err
	}
	body, _ := detail["49"].(map[string]any)
	roster, _ := body["heros"].(map[string]any)
	heroes := make([]map[string]any, 0, len(formation))
	for _, id := range formation {
		row, owned := roster[fmt.Sprint(id)].(map[string]any)
		if !owned {
			continue
		}
		heroes = append(heroes, row)
		if shelf, ok := numeric(row["book_shelf_lev"]); ok && shelf > 0 {
			out["book_shelf_lev"] = shelf
		}
	}
	out["heros"] = heroes
	pet, err := s.frozenPet(c, attempt, memberID, at)
	if err != nil {
		return nil, err
	}
	if pet != nil {
		out["pet"] = pet
	}
	return out, nil
}

// frozenPet re-projects the pet the attempt froze into its combat snapshot.
// shortcut: an unreadable snapshot omits the pet; the rank detail still renders.
func (s Mode) frozenPet(c context.Context, attempt d.Attempt, memberID identity.PlayerID, at time.Time) (map[string]any, error) {
	if s.Pets == nil {
		return nil, nil
	}
	attemptID, err := ids.ParseUUID(attempt.ID)
	if err != nil {
		return nil, nil
	}
	snapshot, err := s.Combat.SnapshotTx(c, s.Fresh, attemptID)
	if err != nil {
		return nil, nil
	}
	petID := int64(0)
	for _, actor := range snapshot.Battle.PetsA {
		if int64(memberID) == actor.Player && actor.Kind == cd.PetActor && actor.Origin == cd.OwnedSelf {
			petID = actor.Identity
			break
		}
	}
	if petID <= 0 {
		return nil, nil
	}
	pets, err := s.petRows(c, s.Fresh, memberID, at)
	if err != nil {
		return nil, err
	}
	return pets[fmt.Sprint(petID)], nil
}
