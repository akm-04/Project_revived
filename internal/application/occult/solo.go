package occult

import (
	"context"
	"errors"
	"fmt"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const roomChangeFunction = 1

// combatCampaignType is the stock CampaignType.OCCULT the solo fight runs under.
const combatCampaignType = 59

var summaryPolicy = cd.SummaryPolicy{ID: "I9_OCCULT_SUMMARY_V1", Version: 1, MaxStar: d.MaxStar, WinFromStar: true}

// SettleRequest is the stock 2372 client summary.
type SettleRequest struct {
	CampaignID int64
	SubID      int64
	Star       int64
	PetID      int64
	Formation  []int64
	Heroes     map[int64]d.HeroStatus
}

type snapshot struct {
	catalog d.Catalog
	scores  d.Scores
	tickets i5.OccultTickets
	view    *roomView
	at      time.Time
}

// read gates function 67 and loads the player's held room without writing.
func (s Mode) read(c context.Context, a identity.ActorContext, op operation.Context) (snapshot, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return snapshot{}, err
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return snapshot{}, err
	}
	catalog, err := s.readCatalog(c, s.Fresh, op)
	if err != nil {
		return snapshot{}, err
	}
	if err = s.admit(c, s.Fresh, a, catalog, at); err != nil {
		return snapshot{}, err
	}
	scores, err := s.Store.ReadScoresTx(c, s.Fresh, a.PlayerID)
	if err != nil {
		return snapshot{}, err
	}
	tickets, err := s.Tickets.OccultTicketsTx(c, s.Fresh, a.PlayerID)
	if err != nil {
		return snapshot{}, err
	}
	loaded := snapshot{catalog: catalog, scores: scores, tickets: tickets, at: at}
	room, found, err := s.RoomStore.ReadPlayerRoomTx(c, s.Fresh, a.PlayerID, RoomFamily, RoomSlot)
	if err != nil || !found {
		return loaded, err
	}
	state, err := d.LoadRunState(room.Payload)
	if err != nil {
		return snapshot{}, err
	}
	if state.RoomExpired(at.Unix()) {
		return loaded, nil
	}
	loaded.view = &roomView{room: room, state: state, catalog: catalog, scores: scores, at: at}
	return loaded, nil
}

func (s Mode) body(c context.Context, a identity.ActorContext, loaded snapshot) (map[string]any, error) {
	return s.stateBody(c, s.Fresh, a, loaded.catalog, loaded.scores, loaded.tickets, loaded.view)
}

// Info answers 2362 with the full state the client's common reader consumes.
func (s Mode) Info(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	loaded, err := s.read(c, a, op)
	if err != nil {
		return nil, err
	}
	return s.body(c, a, loaded)
}

// CampaignInfo answers 2364 with the monsters of every stage of a reachable campaign.
func (s Mode) CampaignInfo(c context.Context, a identity.ActorContext, campaignID int64, op operation.Context) (map[string]any, error) {
	loaded, err := s.read(c, a, op)
	if err != nil {
		return nil, err
	}
	campaign, err := reachableCampaign(loaded.view, campaignID)
	if err != nil {
		return nil, err
	}
	stages := loaded.view.state.StagesOf(campaign.ID)
	monsterInfos := make([][]map[string]any, 0, len(campaign.FightIDs))
	for index, fightID := range campaign.FightIDs {
		waves, err := s.Combat.MonsterWaves(fightID)
		if err != nil {
			return nil, err
		}
		monsters := []map[string]any{}
		for _, wave := range waves {
			for _, monster := range wave {
				monsters = append(monsters, map[string]any{"monster_id": monster.Identity, "partner_id": monster.Identity, "hp": stages[index].HP, "total_hp": stages[index].TotalHP})
			}
		}
		monsterInfos = append(monsterInfos, monsters)
	}
	return map[string]any{"monster_infos": monsterInfos}, nil
}

// MemberStat answers 2365 for a seated member: dispatched heroes with their
// remaining status and the rest of the roster.
func (s Mode) MemberStat(c context.Context, a identity.ActorContext, memberID identity.PlayerID, op operation.Context) (map[string]any, error) {
	loaded, err := s.read(c, a, op)
	if err != nil {
		return nil, err
	}
	if loaded.view == nil || !seated(loaded.view, memberID) {
		return nil, d.ErrRefused
	}
	detail := map[string]any{}
	if err = s.Heroes.OverlayMID1(c, s.Fresh, identity.ActorContext{PlayerID: memberID}, false, loaded.at, detail); err != nil {
		return nil, err
	}
	roster, _ := detail["49"].(map[string]any)
	rows, _ := roster["heros"].(map[string]any)
	statuses := loaded.view.state.HeroStatus[numberKey(int64(memberID))]
	dispatched, undispatched := []any{}, []any{}
	status := map[string]any{}
	for heroKey, row := range rows {
		recorded, dispatchedHero := statuses[heroKey]
		if !dispatchedHero {
			undispatched = append(undispatched, row)
			continue
		}
		dispatched = append(dispatched, row)
		status[heroKey] = map[string]any{"hp": recorded.HP, "total_hp": int64(d.FullStatus), "mp": recorded.MP}
	}
	return map[string]any{"player_id": int64(memberID), "dispatch_heroes": dispatched, "undispatch_heroes": undispatched, "dispatch_status": status}, nil
}

// Logs answers 2380 with the player's newest battle and affair entries.
func (s Mode) Logs(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	if _, err := s.read(c, a, op); err != nil {
		return nil, err
	}
	logs, err := s.Store.ReadLogsTx(c, s.Fresh, int64(a.LogicalServerID), a.PlayerID, logLimit)
	if err != nil {
		return nil, err
	}
	return map[string]any{"log_list": logs}, nil
}

func seated(view *roomView, playerID identity.PlayerID) bool {
	for _, member := range view.room.Members() {
		if member == playerID {
			return true
		}
	}
	return false
}

func reachableCampaign(view *roomView, campaignID int64) (d.Campaign, error) {
	if view == nil || !view.state.Started() {
		return d.Campaign{}, d.ErrRefused
	}
	for _, campaign := range view.catalog.RoomCampaigns(view.state.ChapterID, view.state.CampaignType) {
		if campaign.ID == campaignID && view.state.Reachable(view.catalog, campaign) {
			return campaign, nil
		}
	}
	return d.Campaign{}, d.ErrRefused
}

// stageOf resolves a client sub_id (1-based) to a fight campaign's stage index.
func stageOf(campaign d.Campaign, subID int64) (int, error) {
	index := subIndex(subID)
	if index < 0 || index >= len(campaign.FightIDs) {
		return 0, d.ErrInvalid
	}
	return index, nil
}

// CreateSolo answers 2366 with campaign_type 2: it spends one ticket, starts a
// one-seat room at once and freezes the awakening occurrence. A repeated create
// of the same chapter answers the room already held.
func (s Mode) CreateSolo(c context.Context, a identity.ActorContext, chapterID int64, op operation.Context) (map[string]any, error) {
	loaded, err := s.read(c, a, op)
	if err != nil {
		return nil, err
	}
	if _, known := loaded.catalog.Chapter(chapterID); !known {
		return nil, d.ErrInvalid
	}
	if loaded.view != nil {
		return s.heldRoom(c, a, loaded, chapterID, d.SingleCampaignType)
	}
	if loaded.tickets.Tickets < 1 {
		return nil, economy.ErrInsufficientBalance
	}
	op, err = s.pin(c, op)
	if err != nil {
		return nil, err
	}
	payload, err := d.NewRun(chapterID, d.SingleCampaignType).Encode()
	if err != nil {
		return nil, err
	}
	if _, err = s.Rooms.Leave(c, a, RoomFamilyRef(), op); err != nil {
		return nil, err
	}
	if _, err = s.Rooms.Open(c, a, sr.OpenRequest{Family: RoomFamilyRef(), Capacity: 1, Lease: d.RoomSeconds * time.Second, Payload: payload}, op); err != nil {
		return nil, err
	}
	body, err := s.update(c, a, op, func(c context.Context, sc gen.TimedScope, view *roomView) (map[string]any, error) {
		return s.startRun(c, sc, a, view)
	})
	if err != nil {
		_, _ = s.Rooms.Leave(c, a, RoomFamilyRef(), op)
		return nil, err
	}
	return body, nil
}

func (s Mode) heldRoom(c context.Context, a identity.ActorContext, loaded snapshot, chapterID, campaignType int64) (map[string]any, error) {
	if loaded.view.state.ChapterID != chapterID || loaded.view.state.CampaignType != campaignType {
		return nil, d.ErrRefused
	}
	body, err := s.body(c, a, loaded)
	if err != nil {
		return nil, err
	}
	body["function_type"] = int64(roomChangeFunction)
	return body, nil
}

func (s Mode) startRun(c context.Context, sc gen.TimedScope, a identity.ActorContext, view *roomView) (map[string]any, error) {
	op := sc.Operation.Operation()
	tickets, err := s.Tickets.DebitOccultTicketTx(c, sc.Tx, a.PlayerID, op)
	if err != nil {
		return nil, err
	}
	if err = view.state.Start(view.at.Unix()); err != nil {
		return nil, err
	}
	if err = view.state.BindRoom(view.catalog); err != nil {
		return nil, err
	}
	if err = view.state.Seat(view.catalog, int64(a.PlayerID)); err != nil {
		return nil, err
	}
	if err = s.freezeFragment(c, sc, a, view); err != nil {
		return nil, err
	}
	if err = s.Store.InsertRunTx(c, sc.Tx, view.room.ID, int64(a.LogicalServerID), view.state.ChapterID, view.state.CampaignType, view.at); err != nil {
		return nil, err
	}
	body, err := s.stateBody(c, sc.Tx, a, view.catalog, view.scores, tickets, view)
	if err != nil {
		return nil, err
	}
	body["function_type"] = int64(roomChangeFunction)
	piggyback(c, body)
	return body, nil
}

// ExitRoom answers 2368: the run ends, the player's stage is released and the
// solo room closes.
func (s Mode) ExitRoom(c context.Context, a identity.ActorContext, roomID int64, op operation.Context) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	_, err = s.updateRoom(c, a, op, true, func(c context.Context, sc gen.TimedScope, view *roomView) (map[string]any, error) {
		if view.room.ID != roomID {
			return nil, d.ErrRefused
		}
		view.state.Release(int64(a.PlayerID))
		return nil, s.Store.FinishRunTx(c, sc.Tx, view.room.ID, view.at)
	})
	if err != nil && !errors.Is(err, sr.ErrNotInRoom) {
		return nil, err
	}
	if _, err = s.Rooms.Leave(c, a, RoomFamilyRef(), op); err != nil {
		return nil, err
	}
	return s.roomChange(c, a, op)
}

// roomChange answers a room command with the caller's state as a ROOM_CHANGE.
func (s Mode) roomChange(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	loaded, err := s.read(c, a, op)
	if err != nil {
		return nil, err
	}
	body, err := s.body(c, a, loaded)
	if err != nil {
		return nil, err
	}
	body["function_type"] = int64(roomChangeFunction)
	return body, nil
}

// Prepare answers 2371: the campaign's event fires once, and an auto pass
// clears the campaign without a fight.
func (s Mode) Prepare(c context.Context, a identity.ActorContext, campaignID, subID int64, op operation.Context) (map[string]any, error) {
	return s.update(c, a, op, func(c context.Context, sc gen.TimedScope, view *roomView) (map[string]any, error) {
		campaign, err := reachableCampaign(view, campaignID)
		if err != nil {
			return nil, err
		}
		if _, err = stageOf(campaign, subID); err != nil {
			return nil, err
		}
		autoPass, err := s.fireCampaignEvent(c, sc, a, view, campaign)
		if err != nil {
			return nil, err
		}
		body := map[string]any{"is_auto_pass": autoPass}
		if !autoPass {
			return body, nil
		}
		return body, s.settleIfCleared(c, sc, a, view, body)
	})
}

// fireCampaignEvent applies the campaign's event once, logs it, and reports
// whether the campaign passes without a fight.
func (s Mode) fireCampaignEvent(c context.Context, sc gen.TimedScope, a identity.ActorContext, view *roomView, campaign d.Campaign) (bool, error) {
	outcomes := view.state.TriggerEvent(view.catalog, campaign)
	if len(outcomes) == 0 {
		return false, nil
	}
	view.state.RecordEvents(outcomes)
	if err := s.Store.InsertLogTx(c, sc.Tx, int64(view.room.LogicalServerID), view.room.ID, eventLogType, a.PlayerID, mustJSON(logEntry(view.at, eventLogType, campaign.ID, a.PlayerID)), view.at); err != nil {
		return false, err
	}
	autoPass := false
	for _, outcome := range outcomes {
		autoPass = autoPass || outcome.Type == d.EventAutoPass
	}
	return autoPass, nil
}

// StartFight answers 2379: the stage is held by the player. A player holds one
// stage, so starting again replaces an abandoned hold.
func (s Mode) StartFight(c context.Context, a identity.ActorContext, campaignID, subID int64, op operation.Context) (map[string]any, error) {
	return s.update(c, a, op, func(c context.Context, sc gen.TimedScope, view *roomView) (map[string]any, error) {
		campaign, err := reachableCampaign(view, campaignID)
		if err != nil {
			return nil, err
		}
		index, err := stageOf(campaign, subID)
		if err != nil {
			return nil, err
		}
		view.state.ExpireTeam(view.at.Unix())
		view.state.Release(int64(a.PlayerID))
		if err = view.state.Enter(campaign.ID, index, int64(a.PlayerID)); err != nil {
			return nil, err
		}
		view.state.BeginFight(view.at.Unix())
		view.state.AddNotice(d.NoticeRecord{Function: d.NoticeFightStatus, Actor: int64(a.PlayerID), CampaignID: campaign.ID})
		return map[string]any{}, nil
	})
}

// QuitFight answers 2373 and frees the player's stage.
func (s Mode) QuitFight(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.update(c, a, op, func(_ context.Context, _ gen.TimedScope, view *roomView) (map[string]any, error) {
		view.state.Release(int64(a.PlayerID))
		view.state.AddNotice(d.NoticeRecord{Function: d.NoticeFightStatus, Actor: int64(a.PlayerID)})
		return map[string]any{}, nil
	})
}

// ChangePosition answers 2384 for a start point of the room.
func (s Mode) ChangePosition(c context.Context, a identity.ActorContext, stayPos int64, op operation.Context) (map[string]any, error) {
	return s.update(c, a, op, func(_ context.Context, _ gen.TimedScope, view *roomView) (map[string]any, error) {
		return map[string]any{}, view.state.ChangePosition(view.catalog, int64(a.PlayerID), stayPos)
	})
}

// Settle answers 2372. The held stage is checked first, so a repeated result
// finds no hold and is refused; the summary is attested and clamped.
func (s Mode) Settle(c context.Context, a identity.ActorContext, request SettleRequest, op operation.Context) (map[string]any, error) {
	if request.Star < 0 || request.Star > d.MaxStar || len(request.Formation) < 1 || request.PetID < 0 {
		return nil, d.ErrInvalid
	}
	return s.update(c, a, op, func(c context.Context, sc gen.TimedScope, view *roomView) (map[string]any, error) {
		campaign, err := reachableCampaign(view, request.CampaignID)
		if err != nil {
			return nil, err
		}
		index, err := stageOf(campaign, request.SubID)
		if err != nil {
			return nil, err
		}
		held := view.state.StagesOf(campaign.ID)[index].InBattle == int64(a.PlayerID)
		if !held || view.state.FightExpired(view.at.Unix()) {
			return nil, fmt.Errorf("%w: no open fight on this stage", d.ErrRefused)
		}
		if err = s.attest(c, sc, a, view, campaign, request, index); err != nil {
			return nil, err
		}
		result, err := view.state.ApplySolo(int64(a.PlayerID), campaign.ID, index, d.SoloReport{Star: request.Star, Score: request.Star, Heroes: request.Heroes})
		if err != nil {
			return nil, err
		}
		if err = s.Store.InsertLogTx(c, sc.Tx, int64(view.room.LogicalServerID), view.room.ID, battleLogType, a.PlayerID, mustJSON(logEntry(view.at, battleLogType, campaign.ID, a.PlayerID)), view.at); err != nil {
			return nil, err
		}
		view.state.AddNotice(d.NoticeRecord{Function: d.NoticeSingleFight, Actor: int64(a.PlayerID), CampaignID: campaign.ID})
		view.state.AddNotice(d.NoticeRecord{Function: d.NoticeFightStatus, Actor: int64(a.PlayerID), CampaignID: campaign.ID})
		body := map[string]any{"award_info": map[string]any{"awards": []map[string]any{}}}
		if !result.Won {
			return body, s.fillState(c, sc, a, view, body, result.Score)
		}
		if err = s.settleIfCleared(c, sc, a, view, body); err != nil {
			return nil, err
		}
		return body, s.fillState(c, sc, a, view, body, result.Score)
	})
}

func (s Mode) attest(c context.Context, sc gen.TimedScope, a identity.ActorContext, view *roomView, campaign d.Campaign, request SettleRequest, index int) error {
	op := sc.Operation.Operation()
	revision, _ := op.Policies.Get("content")
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: op, Attempt: sc.Attempt, Options: sc.Options}, revision, view.at)
	if err != nil {
		return err
	}
	reference := generationRef(view.room.ID, campaign.ID, index+1)
	battle := cb.BattleRequest{CampaignType: combatCampaignType, BattleID: campaign.FightIDs[index], Formation: request.Formation}
	for _, heroID := range request.Formation {
		battle.TeamA = append(battle.TeamA, cb.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: a.PlayerID, Identity: heroID})
	}
	if request.PetID > 0 {
		battle.PetsA = []cb.Participant{{Origin: cd.OwnedSelf, Kind: cd.PetActor, Player: a.PlayerID, Identity: request.PetID}}
	}
	// shortcut: stock 2379 carries no formation and ClientSummaryAttested needs a
	// frozen one, so Combat starts and attests inside 2372; the 150 s fight timer
	// is the room's own, checked above.
	if _, err = s.Combat.StartTx(c, sc.Tx, scope, cb.StartRequest{Actor: a, Locator: locator(a), GenerationRef: reference, StartFingerprint: startFingerprint(a, reference, op),
		ResultDeadline: view.at.Add(d.FightSeconds * time.Second), Battle: battle, TrustProfile: cd.ClientSummaryAttested, Replay: cd.ReplaySpec{Response: cd.ReplayOK}}); err != nil {
		return err
	}
	attested, err := s.Combat.AttestSummaryTx(c, sc.Tx, cb.SummaryRequest{Locator: locator(a), GenerationRef: reference, TerminalKind: "OCCULT_RESULT", At: view.at, Policy: summaryPolicy,
		Summary: cd.Summary{Star: request.Star, Win: request.Star > 0, Formation: request.Formation, Pet: request.PetID}})
	if err != nil {
		return err
	}
	if attested.Drained || attested.Attestation.Verdict == cd.VerdictRejected {
		return fmt.Errorf("%w: summary drained or rejected", d.ErrRefused)
	}
	return nil
}
