package eventcentre

import (
	"context"
	"errors"
	"fmt"
	"math"
	"reflect"
	"sort"
	"time"

	appbook "gxb.local/backend/v2/internal/application/bookskill"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	ec "gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Service) boardReady() bool {
	return s.Timed.Binder.Time != nil && s.Timed.Runner.DB != nil && s.Reads.DB != nil && s.Owner != nil && s.Content != nil && s.Book != nil && s.Players != nil && s.Fence != nil && s.Costs != nil && s.Grants != nil && s.Heroes != nil && s.Levels != nil && s.Stats != nil && s.Combat != nil && s.Facts != nil
}

func (s Service) boardPin(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	revision, active, err := s.Content.WorkshopInputsActive(ctx)
	if err != nil {
		return op, "", err
	}
	if !active {
		return op, "", ErrUnavailable
	}
	if v, ok := op.Policies.Get("content"); ok {
		revision = v
	}
	refs := op.Policies.Refs()
	if _, ok := op.Policies.Get("content"); !ok {
		refs = append(refs, policy.Ref{Name: "content", Version: revision})
	}
	if v, ok := op.Policies.Get("event-centre"); ok {
		if v != PolicyVersion {
			return op, "", ErrProof
		}
	} else {
		refs = append(refs, policy.Ref{Name: "event-centre", Version: PolicyVersion})
	}
	if op.Policies, err = policy.NewSet(refs...); err != nil {
		return op, "", err
	}
	return op, revision, nil
}

// boardFactsTx locks the player root and returns the notice board state with
// its catalog and building inputs.
func (s Service) boardFactsTx(ctx context.Context, t tx.Tx, a identity.ActorContext, revision string, at time.Time) (Root, Catalog, appbook.Inputs, error) {
	root, exists, err := s.Owner.LockRootTx(ctx, t, a.PlayerID)
	if err != nil {
		return Root{}, Catalog{}, appbook.Inputs{}, err
	}
	if !exists {
		if err = s.Owner.EnsureRootTx(ctx, t, a.PlayerID, revision, at); err != nil {
			return Root{}, Catalog{}, appbook.Inputs{}, err
		}
		root, exists, err = s.Owner.LockRootTx(ctx, t, a.PlayerID)
		if err != nil {
			return Root{}, Catalog{}, appbook.Inputs{}, err
		}
		if !exists {
			return Root{}, Catalog{}, appbook.Inputs{}, ErrUnavailable
		}
	}
	if at.Before(root.UpdatedAt) {
		return Root{}, Catalog{}, appbook.Inputs{}, ErrStale
	}
	catalog, err := s.Content.WorkshopInputsTx(ctx, t, revision)
	if err != nil {
		return Root{}, Catalog{}, appbook.Inputs{}, err
	}
	inputs, err := s.Book.BookInputsTx(ctx, t, appbook.InputScope{Player: a.PlayerID, ContentRevision: revision, ObservedAt: at})
	if err != nil {
		return Root{}, Catalog{}, appbook.Inputs{}, err
	}
	if err = root.Facts.Validate(); err != nil {
		return Root{}, Catalog{}, appbook.Inputs{}, err
	}
	return root, catalog, inputs, nil
}

func (s Service) refreshBoard(ctx context.Context, q tx.Queryer, a identity.ActorContext, board *ec.BoardState, catalog Catalog, inputs appbook.Inputs, at time.Time) error {
	day := modesDay(at)
	progression, err := s.Levels.ReadProgressionTx(ctx, q, a.PlayerID)
	if err != nil {
		return err
	}
	heroes, err := s.Heroes.ListHeroesTx(ctx, q, a.PlayerID)
	if err != nil {
		return err
	}
	offers := catalog.BoardOffers(buildingLevel(inputs, ec.BoardBuilding), progression.Level, ownedTables(heroes), day, a.PlayerID)
	doing := map[int64]bool{}
	for _, mission := range board.Doing {
		doing[mission.MissionID] = true
	}
	kept := offers[:0]
	for _, offer := range offers {
		if !doing[offer.MissionID] {
			kept = append(kept, offer)
		}
	}
	board.Offers = kept
	board.RefreshDay = day
	return nil
}

func ownedTables(heroes []character.Hero) map[int64]bool {
	owned := map[int64]bool{}
	for _, hero := range heroes {
		if hero.TableID > 0 {
			owned[hero.TableID] = true
		}
	}
	return owned
}

func heroOwnership(heroes []character.Hero) (map[int64]character.Hero, map[int64]bool) {
	byPartner := map[int64]character.Hero{}
	tables := map[int64]bool{}
	for _, hero := range heroes {
		byPartner[hero.PartnerID] = hero
		tables[hero.TableID] = true
	}
	return byPartner, tables
}

func (s Service) applyBoard(ctx context.Context, sc tx.Scope, a identity.ActorContext, d Admission, catalog Catalog, inputs appbook.Inputs, state *State, valueop operation.Context) (map[string]any, error) {
	at := d.DecisionAt
	if err := s.refreshBoard(ctx, sc.Tx, a, &state.Board, catalog, inputs, at); err != nil {
		return nil, err
	}
	switch d.Command.Family {
	case BoardReceive:
		return s.applyBoardReceive(ctx, sc, a, d, catalog, state, valueop)
	case BoardGiveUp:
		return s.applyBoardGiveUp(ctx, sc.Tx, a, d, catalog, state, valueop)
	case BoardConfirm:
		state.Board.AwardLog = nil
		return map[string]any{"award_log": []any{}}, nil
	}
	return nil, ErrUnqualified
}

func (s Service) applyBoardReceive(ctx context.Context, sc tx.Scope, a identity.ActorContext, d Admission, catalog Catalog, state *State, valueop operation.Context) (map[string]any, error) {
	offer, offered := state.Board.Offer(d.Command.MissionID)
	if !offered || state.Board.IsDoing(d.Command.MissionID) {
		return nil, ErrInvalid
	}
	mission, known := catalog.Mission(d.Command.MissionID)
	if !known {
		return nil, ErrInvalid
	}
	_, _, tiered := catalog.MissionTier(mission.ID)
	cap, capped := catalog.CapFor(mission.ID)
	if !tiered || !capped {
		return nil, ErrInvalid
	}
	heroes, err := s.Heroes.ListHeroesTx(ctx, sc.Tx, a.PlayerID)
	if err != nil {
		return nil, err
	}
	byPartner, _ := heroOwnership(heroes)
	team := append([]int64{d.Command.Leader}, d.Command.Partners...)
	if len(team) > ec.BoardMaxPartners+1 || !distinct(team) {
		return nil, ErrInvalid
	}
	for _, partner := range team {
		if _, owned := byPartner[partner]; !owned {
			return nil, ErrInvalid
		}
	}
	busy := state.Board.BusyHeroes()
	for _, partner := range team {
		if busy[partner] {
			return nil, ErrInvalid
		}
	}
	power, err := s.boardPower(ctx, sc, a, d, team)
	if err != nil {
		return nil, err
	}
	if power > cap {
		return nil, ErrInvalid
	}
	if err = s.boardCost(ctx, sc.Tx, a, d, mission, offer, valueop); err != nil {
		return nil, err
	}
	state.Board.Doing = append(state.Board.Doing, ec.BoardMission{MissionID: mission.ID, Leader: d.Command.Leader, Partners: append([]int64(nil), d.Command.Partners...), StartAt: d.DecisionAt.Unix(), Type: offer.Type, AwardID: offer.AwardID, WishCrystal: d.Command.WishCrystal == 1})
	return map[string]any{"mission_id": mission.ID, "start_time": d.DecisionAt.Unix(), "leader": d.Command.Leader, "partners": d.Command.Partners, "type": offer.Type}, nil
}

func distinct(values []int64) bool {
	seen := map[int64]bool{}
	for _, value := range values {
		if seen[value] {
			return false
		}
		seen[value] = true
	}
	return true
}

func (s Service) boardPower(ctx context.Context, sc tx.Scope, a identity.ActorContext, d Admission, team []int64) (int64, error) {
	scope, err := ca.NewCoherentReadScope(sc, d.ContentRevision, d.DecisionAt)
	if err != nil {
		return 0, err
	}
	total := int64(0)
	for _, partner := range team {
		result, err := s.Stats.HeroTx(ctx, scope, character.HeroRef{PlayerID: a.PlayerID, PartnerID: partner}, publicstats.View{Kind: publicstats.Self, Viewer: a.PlayerID})
		if err != nil {
			return 0, err
		}
		total += int64(math.Round(result.Stats.Force))
	}
	return total, nil
}

func (s Service) boardCost(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, mission ec.MissionRule, offer ec.BoardOffer, valueop operation.Context) error {
	cost := i5.MaterialCost{}
	if offer.Type == ec.BoardTaskTypeDeposit && mission.Deposit > 0 {
		cost.Scalars = append(cost.Scalars, i5.ScalarMaterialCost{ResourceKey: ec.BoardDepositResourceKey, Amount: mission.Deposit})
	}
	if d.Command.WishCrystal == 1 {
		cost.Stacks = append(cost.Stacks, i5.StackMaterialCost{ItemID: ec.BlessingCrystalItemID, Amount: 1})
	}
	if len(cost.Scalars) == 0 && len(cost.Stacks) == 0 {
		return nil
	}
	prepared, err := s.Costs.PrepareMaterialDebitTx(ctx, t, a.PlayerID, cost, valueop)
	if err != nil {
		return err
	}
	_, err = s.Costs.ApplyMaterialDebitTx(ctx, t, prepared)
	return err
}

func (s Service) applyBoardGiveUp(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, catalog Catalog, state *State, valueop operation.Context) (map[string]any, error) {
	var found *ec.BoardMission
	for index := range state.Board.Doing {
		if state.Board.Doing[index].MissionID == d.Command.MissionID {
			found = &state.Board.Doing[index]
			break
		}
	}
	if found == nil {
		return nil, ErrInvalid
	}
	if found.Type == ec.BoardTaskTypeDeposit {
		mission, known := catalog.Mission(found.MissionID)
		if !known {
			return nil, ErrInvalid
		}
		if mission.Deposit > 0 {
			if err := s.boardGrant(ctx, t, a, d, "board-deposit-refund", []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: ec.BoardDepositResourceKey, Amount: mission.Deposit}}, valueop); err != nil {
				return nil, err
			}
		}
	}
	state.Board.RemoveDoing(d.Command.MissionID)
	return map[string]any{"mission_id": d.Command.MissionID}, nil
}

func (s Service) boardGrant(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, tag string, lines []grant.Line, valueop operation.Context) error {
	if len(lines) == 0 {
		return nil
	}
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "event-centre", Operation: tag, BusinessKey: fmt.Sprintf("%d/%d", int64(a.PlayerID), d.Command.MissionID), Occurrence: d.Operation.ID.String(), PolicyVersion: PolicyVersion}, Lines: lines}
	_, err := s.Grants.SettleGrantTx(ctx, t, a, plan, valueop, i5.GrantTxOptions{AllowOverflowMail: true})
	return err
}

// BoardInfo answers 1083. It materializes the day's offers and settles every
// mission whose stored start plus table duration has elapsed: each due mission
// starts a server-report combat attempt in the first transaction, resolves
// outside it, then settles through TerminalTx and grants its award in a second
// transaction. The stock client only observes completion through this MID
// (BoardAttackTaskItem.lua:38-66), so this projection is the settlement point.
func (s Service) BoardInfo(ctx context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	if !s.boardReady() {
		return nil, ErrUnavailable
	}
	op, revision, err := s.boardPin(ctx, op)
	if err != nil {
		return nil, err
	}
	timed, err := s.Timed.Binder.Bind(ctx, op)
	if err != nil {
		return nil, err
	}
	at := timed.DecisionAt()
	valueop := op
	valueop.StartedAt = at
	var body map[string]any
	var due []ec.BoardMission
	first, err := s.Timed.Runner.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(ctx context.Context, sc tx.Scope) error {
		if err := s.lockPlan(ctx, sc.Tx, a, at); err != nil {
			return err
		}
		root, catalog, inputs, err := s.boardFactsTx(ctx, sc.Tx, a, revision, at)
		if err != nil {
			return err
		}
		state := root.Facts.Clone()
		if err = s.refreshBoard(ctx, sc.Tx, a, &state.Board, catalog, inputs, at); err != nil {
			return err
		}
		due = state.Board.DueMissions(at.Unix(), catalog)
		for index := range due {
			if due[index].Attempt != "" {
				continue
			}
			attempt, err := s.startBoardAttempt(ctx, sc, a, revision, catalog, at, due[index])
			if err != nil {
				return err
			}
			due[index].Attempt = attempt
			for position := range state.Board.Doing {
				if state.Board.Doing[position].MissionID == due[index].MissionID {
					state.Board.Doing[position].Attempt = attempt
					break
				}
			}
		}
		if !reflect.DeepEqual(root.Facts, state) {
			if err = state.Validate(); err != nil {
				return err
			}
			root.Facts = state
			previous := root.Version
			root.Version++
			root.UpdatedAt = at
			if err = s.Owner.SaveRootTx(ctx, sc.Tx, root, previous); err != nil {
				return err
			}
		}
		if len(due) == 0 {
			body = ec.BoardWire(state.Board)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	if first.Outcome != tx.DefiniteCommit {
		return nil, ErrUnavailable
	}
	if len(due) == 0 {
		return body, nil
	}
	unresolvable := map[string]bool{}
	for _, mission := range due {
		attempt, err := ids.ParseUUID(mission.Attempt)
		if err != nil {
			return nil, ErrUnavailable
		}
		_, err = s.Combat.Resolve(ctx, valueop, attempt)
		if errors.Is(err, cd.ErrResolverPermanent) {
			unresolvable[mission.Attempt] = true
			continue
		}
		if err != nil {
			return nil, ErrUnavailable
		}
	}
	second, err := s.Timed.Runner.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(ctx context.Context, sc tx.Scope) error {
		if err := s.lockPlan(ctx, sc.Tx, a, at); err != nil {
			return err
		}
		root, catalog, inputs, err := s.boardFactsTx(ctx, sc.Tx, a, revision, at)
		if err != nil {
			return err
		}
		state := root.Facts.Clone()
		if err = s.refreshBoard(ctx, sc.Tx, a, &state.Board, catalog, inputs, at); err != nil {
			return err
		}
		prepared, err := s.Facts.PrepareTx(ctx, sc.Tx, a.PlayerID, timed)
		if err != nil {
			return err
		}
		for _, mission := range state.Board.DueMissions(at.Unix(), catalog) {
			if err = s.settleBoardMission(prepared, sc.Tx, a, valueop, catalog, &state.Board, mission, unresolvable[mission.Attempt]); err != nil {
				return err
			}
		}
		keep := make([]int64, 0, len(state.Board.History))
		for _, run := range state.Board.History {
			if run.ReportID > 0 {
				keep = append(keep, run.ReportID)
			}
		}
		if err = s.Owner.DeleteBoardReportsExceptTx(ctx, sc.Tx, a.PlayerID, keep); err != nil {
			return err
		}
		if err = state.Validate(); err != nil {
			return err
		}
		root.Facts = state
		previous := root.Version
		root.Version++
		root.UpdatedAt = at
		if err = s.Owner.SaveRootTx(ctx, sc.Tx, root, previous); err != nil {
			return err
		}
		body = ec.BoardWire(state.Board)
		return nil
	})
	if err != nil {
		return nil, err
	}
	if second.Outcome != tx.DefiniteCommit {
		return nil, ErrUnavailable
	}
	return body, nil
}

func (s Service) startBoardAttempt(ctx context.Context, sc tx.Scope, a identity.ActorContext, revision string, catalog Catalog, at time.Time, mission ec.BoardMission) (string, error) {
	rule, known := catalog.Mission(mission.MissionID)
	if !known {
		return "", ErrInvalid
	}
	// The mission row owns the enemy lineup. Every event fight_id in the pinned
	// corpus resolves to one unrelated level-90 wave, so the fight_id is a scene
	// id, not the mission battle row. The resolver's table-shaped TEMPLATE actor
	// cannot carry the mission's display star/quality/level columns.
	waves := make([][]appcombat.Participant, 1)
	for _, enemy := range rule.EnemyIDs {
		if enemy <= 0 {
			continue
		}
		waves[0] = append(waves[0], appcombat.Participant{Origin: cd.Template, Kind: cd.HeroActor, Identity: enemy, TemplateParams: map[string]any{"table_id": enemy}})
	}
	if len(waves[0]) == 0 {
		return "", ErrInvalid
	}
	battle := appcombat.BattleRequest{CampaignType: ec.BoardCampaignType, BattleID: rule.FightID, WavesB: waves}
	battle.TeamA = append(battle.TeamA, appcombat.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: a.PlayerID, Identity: mission.Leader})
	for _, partner := range mission.Partners {
		battle.TeamA = append(battle.TeamA, appcombat.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: a.PlayerID, Identity: partner})
	}
	scope, err := ca.NewCoherentReadScope(sc, revision, at)
	if err != nil {
		return "", err
	}
	fingerprint, err := receipt.FingerprintRequest(struct {
		MissionID     int64
		Leader        int64
		Partners      []int64
		StartAt, Wish int64
	}{mission.MissionID, mission.Leader, mission.Partners, mission.StartAt, boolInt(mission.WishCrystal)})
	if err != nil {
		return "", err
	}
	started, err := s.Combat.StartTx(ctx, sc.Tx, scope, appcombat.StartRequest{Mode: cd.ModeEventCentreBoard, Actor: a, Locator: boardLocator(a, mission), GenerationRef: boardGeneration(mission),
		StartFingerprint: fmt.Sprintf("%x", fingerprint), ResultDeadline: at.Add(time.Duration(rule.Duration) * time.Second), Battle: battle})
	if err != nil {
		return "", err
	}
	return started.Attempt.ID.String(), nil
}

func boolInt(value bool) int64 {
	if value {
		return 1
	}
	return 0
}

func (s Service) settleBoardMission(ctx context.Context, t tx.Tx, a identity.ActorContext, op operation.Context, catalog Catalog, board *ec.BoardState, mission ec.BoardMission, unresolvable bool) error {
	if _, err := ids.ParseUUID(mission.Attempt); err != nil {
		return ErrUnavailable
	}
	at := op.StartedAt
	terminal := appcombat.TerminalRequest{Locator: boardLocator(a, mission), GenerationRef: boardGeneration(mission), TerminalKind: ec.BoardTerminalKind,
		SemanticReceiptID: "event-centre-board:" + mission.Attempt, At: at}
	d := Admission{Operation: op, Command: Command{MissionID: mission.MissionID}}
	// A fight the resolver can never finish would otherwise hold the board on every
	// 1083; close it, free the heroes and refund as for a loss, with no report.
	if unresolvable {
		terminal.TerminalKind = ec.BoardClosedKind
		if _, err := s.Combat.CloseTx(ctx, t, terminal); err != nil {
			return err
		}
		if err := s.refundBoardDeposit(ctx, t, a, d, catalog, mission, op); err != nil {
			return err
		}
		board.RemoveDoing(mission.MissionID)
		return nil
	}
	settled, err := s.Combat.TerminalTx(ctx, t, terminal)
	if err != nil {
		return err
	}
	if len(settled.Report) == 0 {
		return ErrUnavailable
	}
	reportID := board.NextReportID
	board.NextReportID++
	if err = s.Owner.InsertBoardReportTx(ctx, t, a.PlayerID, reportID, string(settled.Report), at); err != nil {
		return err
	}
	win := settled.Resolution.Outcome.Star > 0
	if win {
		award, known := catalog.Award(mission.AwardID)
		if !known {
			return ErrInvalid
		}
		if err = s.boardGrant(ctx, t, a, d, "board-award", awardLines(catalog, award, mission.WishCrystal), op); err != nil {
			return err
		}
		board.AppendAward(ec.BoardAward{MissionID: mission.MissionID, Type: mission.Type, AwardID: mission.AwardID, WishCrystal: boolInt(mission.WishCrystal)})
	} else if err = s.refundBoardDeposit(ctx, t, a, d, catalog, mission, op); err != nil {
		return err
	}
	board.AppendHistory(ec.BoardRun{MissionID: mission.MissionID, Win: win, ReportID: reportID})
	board.RemoveDoing(mission.MissionID)
	return s.Facts.RecordTx(ctx, t, op, objective.Fact{PlayerID: a.PlayerID, SourceDomain: "event-centre", SourceBusinessKey: mission.Attempt, Kind: objective.VoyageFinishedKind, Delta: 1})
}

func (s Service) refundBoardDeposit(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, catalog Catalog, mission ec.BoardMission, op operation.Context) error {
	if mission.Type != ec.BoardTaskTypeDeposit {
		return nil
	}
	rule, known := catalog.Mission(mission.MissionID)
	if !known {
		return ErrInvalid
	}
	if rule.Deposit <= 0 {
		return nil
	}
	return s.boardGrant(ctx, t, a, d, "board-deposit-refund", []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: ec.BoardDepositResourceKey, Amount: rule.Deposit}}, op)
}

func awardLines(catalog Catalog, award ec.AwardRule, wish bool) []grant.Line {
	settlement, ok := catalog.WinAward(award.ID, wish)
	if !ok {
		return nil
	}
	lines := make([]grant.Line, 0, 3+len(settlement.Materials))
	if settlement.ItemID > 0 && settlement.ItemCount > 0 {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: settlement.ItemID, Amount: settlement.ItemCount})
	}
	for _, material := range settlement.Materials {
		key, scalar := ec.ScalarResourceKey(material.ID)
		if !scalar || material.Amount <= 0 {
			continue
		}
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: key, Amount: material.Amount})
	}
	if settlement.Gold > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: ec.BoardDepositResourceKey, Amount: settlement.Gold})
	}
	sort.Slice(lines, func(left, right int) bool {
		if lines[left].Kind != lines[right].Kind {
			return lines[left].Kind < lines[right].Kind
		}
		return lines[left].ItemID < lines[right].ItemID || lines[left].ItemID == lines[right].ItemID && lines[left].ResourceKey < lines[right].ResourceKey
	})
	return lines
}

func boardLocator(a identity.ActorContext, mission ec.BoardMission) cd.Locator {
	return cd.Locator{DomainKind: "EVENT_CENTRE_BOARD", AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID), DomainLocator: fmt.Sprintf("%d/%d/%d", int64(a.PlayerID), mission.MissionID, mission.StartAt)}
}

func boardGeneration(mission ec.BoardMission) string {
	return fmt.Sprintf("EVENT_CENTRE_BOARD/%d/%d", mission.MissionID, mission.StartAt)
}

// BoardReport answers 1087 from the stored server report. The client reads
// reply.report[1].content as a JSON string (BoardHistoryItem.lua:82-84).
func (s Service) BoardReport(ctx context.Context, a identity.ActorContext, boardID int64, op operation.Context) (map[string]any, error) {
	if boardID <= 0 || !s.boardReady() {
		return nil, ErrInvalid
	}
	timed, err := s.Timed.Binder.Bind(ctx, op)
	if err != nil {
		return nil, err
	}
	at := timed.DecisionAt()
	var body map[string]any
	result, err := s.Reads.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		if err := s.Fence.FenceActorTx(ctx, sc.Tx, a, at); err != nil {
			return err
		}
		content, found, err := s.Owner.ReadBoardReportTx(ctx, sc.Tx, a.PlayerID, boardID)
		if err != nil {
			return err
		}
		if !found {
			return ErrInvalid
		}
		body = map[string]any{"report": []any{map[string]any{"content": content}}}
		return nil
	})
	if err != nil {
		return nil, err
	}
	if result.Outcome != tx.DefiniteCommit {
		return nil, ErrUnavailable
	}
	return body, nil
}
