package worldboss

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var summaryPolicy = cd.SummaryPolicy{ID: "I9_WORLD_BOSS_SUMMARY_V1", Version: 1, MaxDamage: d.DamageCap}

const defeatMailKind = "WORLD_BOSS_DEFEAT"

func locator(a identity.ActorContext) cd.Locator {
	return cd.Locator{DomainKind: "WORLD_BOSS", AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID), DomainLocator: fmt.Sprintf("player:%d", a.PlayerID)}
}

// generationRef binds the Combat attempt to the occurrence generation and boss,
// so a result after the boss advanced drains instead of touching the successor.
func generationRef(a identity.ActorContext, occurrence d.Occurrence) string {
	return fmt.Sprintf("WORLD_BOSS/%d/%d/%d", a.LogicalServerID, occurrence.Generation, occurrence.CurrentBoss)
}

func startFingerprint(a identity.ActorContext, request StartRequest, op operation.Context) string {
	raw, _ := json.Marshal(struct {
		Player    int64
		Campaign  int64
		Formation []int64
		Operation string
	}{int64(a.PlayerID), request.CampaignID, request.Formation, op.ID.String()})
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}

// Buy answers 625: one purchase costs the next refresh_cost ladder entry, is
// capped by vip.num_boss and adds five attempts.
func (s Mode) Buy(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	response, err := s.run(c, a, "buy", struct{}{}, op, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (Response, error) {
		at := sc.Operation.DecisionAt()
		st, err := s.open(c, sc, a, catalog)
		if err != nil {
			return Response{}, err
		}
		if st.player.Attempts > 0 {
			return Response{}, fmt.Errorf("%w: attempts remain", d.ErrRefused)
		}
		privilege, err := s.Privileges.SnapshotTx(c, sc.Tx, a.PlayerID, at)
		if err != nil {
			return Response{}, err
		}
		if st.player.Bought >= catalog.BuyCap(privilege.VIPLevel) {
			return Response{}, fmt.Errorf("%w: purchase cap reached", d.ErrRefused)
		}
		cost, ok := catalog.BuyCost(st.player.Bought + 1)
		if !ok {
			return Response{}, fmt.Errorf("%w: purchase ladder exhausted", d.ErrRefused)
		}
		st.player.Bought++
		st.player.Attempts += d.AttemptsPerBuy
		if err = s.Store.SavePlayerTx(c, sc.Tx, st.player, at); err != nil {
			return Response{}, err
		}
		if _, err = s.Costs.DebitMaterialCostTx(c, sc.Tx, a.PlayerID, i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: cost}}}, sc.Operation.Operation()); err != nil {
			return Response{}, err
		}
		rank, hurt, err := s.rankAndHurt(c, sc.Tx, st.occurrence, a.PlayerID)
		if err != nil {
			return Response{}, err
		}
		return Response{Body: infoBody(st.occurrence, st.player, rank, hurt)}, nil
	})
	return response.Body, err
}

// Start answers 626: the attempt is frozen to the current occurrence and the
// selected heroes must be owned at purple or above.
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
		boss, ok := catalog.Boss(request.CampaignID)
		if !ok {
			return Response{}, d.ErrInvalid
		}
		if !d.StartAllowed(d.SecondOfDay(at)) {
			return Response{}, fmt.Errorf("%w: world boss window closed", d.ErrRefused)
		}
		if st.player.Attempts <= 0 {
			return Response{}, fmt.Errorf("%w: no attempts left", d.ErrRefused)
		}
		if request.CampaignID != st.occurrence.CurrentBoss {
			return Response{}, fmt.Errorf("%w: campaign is not the current boss", d.ErrRefused)
		}
		if err = s.purpleHeroes(c, sc.Tx, a, at, request.Formation); err != nil {
			return Response{}, err
		}
		started, err := s.bind(c, sc, a, st.occurrence, boss, request.Formation)
		if err != nil {
			return Response{}, err
		}
		attempt := d.Attempt{ID: started.Attempt.ID.String(), PlayerID: int64(a.PlayerID), LogicalServerID: int64(a.LogicalServerID), Generation: st.occurrence.Generation,
			CampaignID: request.CampaignID, Formation: formationText(request.Formation), FrozenAt: at.Unix()}
		if err = s.Store.InsertAttemptTx(c, sc.Tx, attempt); err != nil {
			return Response{}, err
		}
		st.player.Attempts--
		if err = s.Store.SavePlayerTx(c, sc.Tx, st.player, at); err != nil {
			return Response{}, err
		}
		return Response{Body: map[string]any{}}, nil
	})
	return response.Body, err
}

func (s Mode) bind(c context.Context, sc gen.TimedScope, a identity.ActorContext, occurrence d.Occurrence, boss d.Boss, formation []int64) (cb.Started, error) {
	op := sc.Operation.Operation()
	revision, _ := op.Policies.Get("content")
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: op, Attempt: sc.Attempt, Options: sc.Options}, revision, sc.Operation.DecisionAt())
	if err != nil {
		return cb.Started{}, err
	}
	battle := cb.BattleRequest{CampaignType: boss.CampaignType, BattleID: boss.FightID, Formation: formation}
	for _, id := range formation {
		battle.TeamA = append(battle.TeamA, cb.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: a.PlayerID, Identity: id})
	}
	return s.Combat.StartTx(c, sc.Tx, scope, cb.StartRequest{Actor: a, Locator: locator(a), GenerationRef: generationRef(a, occurrence),
		StartFingerprint: startFingerprint(a, StartRequest{CampaignID: boss.ID, Formation: formation}, op), ResultDeadline: sc.Operation.DecisionAt().Add(attemptLimit),
		Battle: battle, TrustProfile: cd.ClientSummaryAttested, Replay: cd.ReplaySpec{Response: cd.ReplayOK}})
}

// Settle answers 627: the attested damage is clamped, applied once to the
// frozen occurrence and settled exactly once.
func (s Mode) Settle(c context.Context, a identity.ActorContext, request ResultRequest, op operation.Context) (Response, error) {
	if request.CampaignID < d.FirstBossID || request.CampaignID > d.LastBossID || request.Damage < 0 {
		return Response{}, d.ErrInvalid
	}
	if request.Damage > d.DamageCap {
		request.Damage = d.DamageCap
	}
	return s.run(c, a, "settle", request, op, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (Response, error) {
		at := sc.Operation.DecisionAt()
		st, err := s.open(c, sc, a, catalog)
		if err != nil {
			return Response{}, err
		}
		attempt, found, err := s.Store.FindAttemptTx(c, sc.Tx, a.PlayerID, int64(a.LogicalServerID), request.CampaignID)
		if err != nil {
			return Response{}, err
		}
		// shortcut: 627 carries no attempt token, so a result delayed across a full
		// five-boss cycle cannot be told from a fresh START of the same campaign;
		// add a client attempt id if the stock wire ever gains one.
		if found && attempt.Resolved {
			body, err := s.duplicateSettle(c, sc, st, request)
			return Response{Body: body, Duplicate: err == nil}, err
		}
		if request.CampaignID != st.occurrence.CurrentBoss {
			return Response{}, fmt.Errorf("%w: occurrence advanced", d.ErrRefused)
		}
		if !found || !attempt.Matches(st.occurrence) {
			return Response{}, fmt.Errorf("%w: no open attempt", d.ErrRefused)
		}
		attested, err := s.Combat.AttestSummaryTx(c, sc.Tx, cb.SummaryRequest{Locator: locator(a), GenerationRef: generationRef(a, st.occurrence), TerminalKind: resultKind, At: at, Policy: summaryPolicy,
			Summary: cd.Summary{Win: request.Damage > 0, Damage: request.Damage, Formation: request.Formation}})
		if err != nil {
			return Response{}, err
		}
		if attested.Drained || attested.Attestation.Verdict == cd.VerdictRejected {
			return Response{}, fmt.Errorf("%w: summary drained or rejected", d.ErrRefused)
		}
		accepted, err := st.occurrence.Accept(catalog, request.Damage)
		if err != nil {
			return Response{}, err
		}
		total, err := s.Store.LockTotalTx(c, sc.Tx, st.occurrence.LogicalServerID, st.occurrence.Generation, a.PlayerID, at)
		if err != nil {
			return Response{}, err
		}
		total.AddHurt(accepted, at.Unix())
		if err = s.Store.SaveTotalTx(c, sc.Tx, total, at); err != nil {
			return Response{}, err
		}
		attempt.Resolved = true
		if err = s.Store.SaveAttemptTx(c, sc.Tx, attempt); err != nil {
			return Response{}, err
		}
		st.player.RecordHit(accepted, at.Unix())
		if err = s.Store.SavePlayerTx(c, sc.Tx, st.player, at); err != nil {
			return Response{}, err
		}
		body, err := s.settleOccurrence(c, sc, st, catalog, at)
		if err != nil {
			return Response{}, err
		}
		body["damage"] = accepted
		return Response{Body: body}, nil
	})
}

// Sweep answers 628 with the player's best single hit, consuming one attempt
// once per day without a combat attempt.
func (s Mode) Sweep(c context.Context, a identity.ActorContext, campaign int64, op operation.Context) (Response, error) {
	if campaign < d.FirstBossID || campaign > d.LastBossID {
		return Response{}, d.ErrInvalid
	}
	return s.run(c, a, "sweep", struct{ CampaignID int64 }{campaign}, op, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (Response, error) {
		at := sc.Operation.DecisionAt()
		st, err := s.open(c, sc, a, catalog)
		if err != nil {
			return Response{}, err
		}
		if st.player.SweptDay == st.day {
			body, err := s.duplicateSweep(c, sc, st, campaign)
			return Response{Body: body, Duplicate: err == nil}, err
		}
		if campaign != st.occurrence.CurrentBoss {
			return Response{}, fmt.Errorf("%w: campaign is not the current boss", d.ErrRefused)
		}
		if !st.player.CanSweep() {
			return Response{}, fmt.Errorf("%w: sweep unavailable", d.ErrRefused)
		}
		boss, ok := catalog.Boss(campaign)
		if !ok {
			return Response{}, d.ErrInvalid
		}
		accepted := d.ClampDamage(st.occurrence.Courage, boss.NeedBrave, st.player.BestHit)
		if accepted <= 0 {
			return Response{}, fmt.Errorf("%w: no damage room", d.ErrRefused)
		}
		st.occurrence.Courage += accepted
		total, err := s.Store.LockTotalTx(c, sc.Tx, st.occurrence.LogicalServerID, st.occurrence.Generation, a.PlayerID, at)
		if err != nil {
			return Response{}, err
		}
		total.AddHurt(accepted, at.Unix())
		if err = s.Store.SaveTotalTx(c, sc.Tx, total, at); err != nil {
			return Response{}, err
		}
		st.player.SweptDay = st.day
		st.player.Attempts--
		if err = s.Store.SavePlayerTx(c, sc.Tx, st.player, at); err != nil {
			return Response{}, err
		}
		body, err := s.settleOccurrence(c, sc, st, catalog, at)
		if err != nil {
			return Response{}, err
		}
		body["damage"] = accepted
		return Response{Body: body}, nil
	})
}

// settleOccurrence ranks the occurrence after a hit, advances every defeated
// boss and mails each rank reward once in the same transaction.
func (s Mode) settleOccurrence(c context.Context, sc gen.TimedScope, st session, catalog d.Catalog, at time.Time) (map[string]any, error) {
	ranks, err := s.rankEntries(c, sc.Tx, st.occurrence, rankLimit)
	if err != nil {
		return nil, err
	}
	rank, _ := d.RankOf(ranks, int64(st.player.PlayerID))
	hurt, err := s.personalHurt(c, sc.Tx, st.occurrence, st.player.PlayerID)
	if err != nil {
		return nil, err
	}
	pre, err := s.preInfo(c, sc.Tx, ranks, identity.PlayerID(st.player.PlayerID))
	if err != nil {
		return nil, err
	}
	everyRank, err := s.rankEntries(c, sc.Tx, st.occurrence, mailRanks)
	if err != nil {
		return nil, err
	}
	generation := st.occurrence.Generation
	defeated, _ := st.occurrence.Defeat(catalog)
	if err = s.deliverDefeats(c, sc, st.occurrence.LogicalServerID, catalog, everyRank, generation, defeated, at); err != nil {
		return nil, err
	}
	if err = s.Store.SaveOccurrenceTx(c, sc.Tx, st.occurrence, at); err != nil {
		return nil, err
	}
	body := map[string]any{"total_hurt": hurt, "total_rank": rank}
	if pre != nil {
		body["pre_info"] = pre
	}
	return body, nil
}

func (s Mode) deliverDefeats(c context.Context, sc gen.TimedScope, server int64, catalog d.Catalog, ranks []d.RankEntry, generation int64, defeated []int64, at time.Time) error {
	ordered := d.OrderRank(ranks)
	for _, bossID := range defeated {
		boss, ok := catalog.Boss(bossID)
		if !ok {
			return d.ErrUnavailable
		}
		for index, entry := range ordered {
			reward := catalog.Reward(int64(index + 1))
			lines := rewardLines(reward, boss)
			if len(lines) == 0 {
				continue
			}
			request := i5.SettlementMailRequest{Recipient: identity.PlayerID(entry.PlayerID), SourceKind: defeatMailKind,
				SourceKey: fmt.Sprintf("%d:%d:%d", server, generation, bossID), Title: catalog.Mail.Title, Sender: catalog.Mail.Sender,
				Body: fmt.Sprintf(catalog.Mail.Text, boss.Name, boss.Title, strconv.FormatInt(entry.TotalHurt, 10)), PolicyVersion: d.PolicyID, Lines: lines, At: at}
			if _, _, err := s.Mail.DeliverTx(c, sc.Tx, request); err != nil {
				return err
			}
		}
	}
	return nil
}

func rewardLines(reward d.RankReward, boss d.Boss) []grant.Line {
	lines := []grant.Line{}
	if reward.Diamond > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: reward.Diamond})
	}
	if reward.Mana > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: reward.Mana})
	}
	if reward.Stone > 0 {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: boss.DefeatStone, Amount: reward.Stone})
	}
	return lines
}

func (s Mode) duplicateSettle(c context.Context, sc gen.TimedScope, st session, request ResultRequest) (map[string]any, error) {
	ranks, err := s.rankEntries(c, sc.Tx, st.occurrence, rankLimit)
	if err != nil {
		return nil, err
	}
	rank, _ := d.RankOf(ranks, int64(st.player.PlayerID))
	hurt, err := s.personalHurt(c, sc.Tx, st.occurrence, st.player.PlayerID)
	if err != nil {
		return nil, err
	}
	pre, err := s.preInfo(c, sc.Tx, ranks, identity.PlayerID(st.player.PlayerID))
	if err != nil {
		return nil, err
	}
	body := map[string]any{"damage": request.Damage, "total_hurt": hurt, "total_rank": rank}
	if pre != nil {
		body["pre_info"] = pre
	}
	return body, nil
}

func (s Mode) duplicateSweep(c context.Context, sc gen.TimedScope, st session, campaign int64) (map[string]any, error) {
	damage := st.player.BestHit
	if damage > d.DamageCap {
		damage = d.DamageCap
	}
	return s.duplicateSettle(c, sc, st, ResultRequest{CampaignID: campaign, Damage: damage})
}

func formationText(formation []int64) string {
	parts := make([]string, 0, len(formation))
	for _, id := range formation {
		parts = append(parts, strconv.FormatInt(id, 10))
	}
	return strings.Join(parts, "|")
}
