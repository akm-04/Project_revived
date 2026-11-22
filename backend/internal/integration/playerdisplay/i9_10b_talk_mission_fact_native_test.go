//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/adventurestore"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	i5 "gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/application/missioninputs"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func libraryDispatchService(t *testing.T, actor identity.ActorContext, service stockruntime.LibraryPort, mid uint16, params map[string]any, opCtx operation.Context) httpedge.Response {
	t.Helper()
	dispatcher := stockruntime.LibraryDispatcher{Authority: fixedLibraryAuthority{actor: actor}, Service: service}
	return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: mid, Operation: opCtx, ReceivedAt: time.Now().UTC(),
		Claims: wire.CredentialClaims{Token: "fixture", Region: int64(actor.LogicalServerID)}, Params: params}})
}

func missionOwner(p *pg.Pool) i5.Service {
	values, content := i5store.Store{Queryer: p}, contentstore.Store{Queryer: p}
	owner := compositeI5(p)
	owner.MissionFresh = p
	owner.MissionTime = pg.AuthoritativeTime{Queryer: p}
	owner.Missions = &i5.MissionMaterializer{Store: values, Catalog: content, Activity: content, Observations: missioninputs.Reader{Spending: values, Heroes: characterstore.Store{Queryer: p}, Progression: values, Campaigns: campaignstore.Store{}, Privileges: privilegeProvider(p), Books: bookService(p, p)}}
	return owner
}

func libraryFactService(p *pg.Pool) app.Service {
	owner := missionOwner(p)
	service := libraryService(p, p)
	service.Grants = owner
	service.Facts = i5.ObjectiveFacts{Owner: owner, Open: i5store.Store{Queryer: p}, Observer: appadventure.Observer{Store: adventurestore.Store{}, Favor: librarystore.Store{}}}
	return service
}

func libraryGrantService(p *pg.Pool) app.Service {
	service := libraryService(p, p)
	service.Grants = compositeI5(p)
	return service
}

// triggeringIntimacyOperation returns an operation whose deterministic
// Adventure roll fires event 10002 for a Library intimacy fact.
func triggeringIntimacyOperation(t *testing.T, player identity.PlayerID) operation.Context {
	t.Helper()
	event, ok := d.EventForFactKind(objective.IntimacyImprovedKind)
	if !ok || event.ID != d.EventFavor {
		t.Fatalf("fact kind does not map to Adventure 10002: %+v", event)
	}
	for attempt := 0; attempt < 5000; attempt++ {
		candidate := op()
		fact := objective.Fact{PlayerID: player, SourceDomain: "library", SourceBusinessKey: candidate.ID.String(), Kind: objective.IntimacyImprovedKind, Delta: 1}
		key, e := fact.Key()
		if e != nil {
			t.Fatal(e)
		}
		hit, e := d.Roll(event, key, candidate)
		if e != nil {
			t.Fatal(e)
		}
		if hit {
			return candidate
		}
	}
	t.Fatal("no triggering operation found")
	return operation.Context{}
}

func missionProgress(t *testing.T, p *pg.Pool, player identity.PlayerID, objectiveID int64) int64 {
	t.Helper()
	instances, e := (i5store.Store{}).ListMissionInstancesTx(ctx, p, player)
	if e != nil {
		t.Fatal(e)
	}
	for _, instance := range instances {
		if instance.ObjectiveID == objectiveID && instance.GenerationID != "" {
			return instance.Progress
		}
	}
	return 0
}

func adventureOccurrences(t *testing.T, p *pg.Pool, actor identity.ActorContext, eventType int64) int {
	t.Helper()
	rows, e := (adventurestore.Store{}).ListOccurrencesTx(ctx, p, actor.LogicalServerID, actor.PlayerID, time.Now().UTC().Add(time.Hour), 32)
	if e != nil {
		t.Fatal(e)
	}
	count := 0
	for _, row := range rows {
		if row.EventType == eventType {
			count++
		}
	}
	return count
}

func TestI9_10B841MissionReadAndGiftAdvance(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)

	service := libraryService(p, p)
	response := libraryDispatchService(t, a, service, 841, map[string]any{"partner_id": int64(1)}, op())
	if response.HTTPStatus != 200 {
		t.Fatalf("841 status %d body %+v", response.HTTPStatus, response.Body)
	}
	replyconformance.Check(t, 841, response.Body)
	missions, ok := response.Body["mission_list"].([]any)
	if !ok || len(missions) != 3 {
		t.Fatalf("zero-favor mission_list %T %+v", response.Body["mission_list"], response.Body["mission_list"])
	}
	for index, wantID := range []int64{1001, 1002, 1003} {
		row := missions[index].(map[string]any)
		if row["mission_id"] != wantID || row["process"] != int64(0) || row["mission_state"] != int64(2) {
			t.Fatalf("zero-favor mission %d row %+v", index, row)
		}
	}

	setLibraryFavor(t, p, a, 1, 100)
	response = libraryDispatchService(t, a, service, 841, map[string]any{"partner_id": int64(1)}, op())
	missions = response.Body["mission_list"].([]any)
	if len(missions) != 3 {
		t.Fatalf("favor-100 missions %+v", missions)
	}
	for index, wantID := range []int64{1001, 1002, 1003} {
		row := missions[index].(map[string]any)
		if row["mission_id"] != wantID || row["process"] != int64(0) || row["mission_state"] != int64(2) {
			t.Fatalf("mission %d row %+v", index, row)
		}
	}

	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,50005011,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour') ON CONFLICT(player_id,item_id) DO UPDATE SET quantity=1,updated_at=clock_timestamp()-interval '1 hour'`, int64(a.PlayerID))
	factService := libraryFactService(p)
	giftOperation := triggeringIntimacyOperation(t, a.PlayerID)
	response = libraryDispatchService(t, a, factService, 840, map[string]any{"partner_id": int64(1), "gift_id": int64(50005011), "gift_num": int64(1)}, giftOperation)
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(118) {
		t.Fatalf("gift status %d body %+v", response.HTTPStatus, response.Body)
	}

	response = libraryDispatchService(t, a, service, 841, map[string]any{"partner_id": int64(1)}, op())
	missions = response.Body["mission_list"].([]any)
	if len(missions) != 4 {
		t.Fatalf("post-gift missions %+v", missions)
	}
	first := missions[0].(map[string]any)
	if first["mission_id"] != int64(1001) || first["process"] != int64(1) || first["mission_state"] != int64(4) {
		t.Fatalf("gift mission row %+v", first)
	}
	if progress := missionProgress(t, p, a.PlayerID, 10029); progress != 1 {
		t.Fatalf("mission 10029 progress %d", progress)
	}
	if count := adventureOccurrences(t, p, a, d.EventFavor); count != 1 {
		t.Fatalf("adventure 10002 occurrences %d", count)
	}

	// The same operation replays its saved receipt: no second fact or occurrence.
	replay := libraryDispatchService(t, a, factService, 840, map[string]any{"partner_id": int64(1), "gift_id": int64(50005011), "gift_num": int64(1)}, giftOperation)
	if replay.HTTPStatus != 200 || replay.Body["favor_degree"] != int64(118) {
		t.Fatalf("gift replay status %d body %+v", replay.HTTPStatus, replay.Body)
	}
	if progress := missionProgress(t, p, a.PlayerID, 10029); progress != 1 {
		t.Fatalf("replay mission 10029 progress %d", progress)
	}
	if count := adventureOccurrences(t, p, a, d.EventFavor); count != 1 {
		t.Fatalf("replay adventure 10002 occurrences %d", count)
	}

	// A gift that crosses the 100-favor boundary materializes and advances 1001
	// in the same transaction, before any 841 read.
	bornHero(t, p, a, rev, 10001002, 2)
	setLibraryFavor(t, p, a, 2, 99)
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,50005011,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour') ON CONFLICT(player_id,item_id) DO UPDATE SET quantity=1,updated_at=clock_timestamp()-interval '1 hour'`, int64(a.PlayerID))
	response = libraryDispatchService(t, a, factService, 840, map[string]any{"partner_id": int64(2), "gift_id": int64(50005011), "gift_num": int64(1)}, op())
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(112) {
		t.Fatalf("boundary gift status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 841, map[string]any{"partner_id": int64(2)}, op())
	missions = response.Body["mission_list"].([]any)
	if len(missions) != 4 || missions[0].(map[string]any)["mission_id"] != int64(1001) || missions[0].(map[string]any)["process"] != int64(1) || missions[0].(map[string]any)["mission_state"] != int64(4) {
		t.Fatalf("boundary missions %+v", missions)
	}
}

func TestI9_10B844EmitsIntimacyFact(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	setLibraryFavor(t, p, a, 1, 100)

	service := libraryFactService(p)
	awardOperation := triggeringIntimacyOperation(t, a.PlayerID)
	response := libraryDispatchService(t, a, service, 844, map[string]any{"partner_id": int64(1), "act_id": int64(1)}, awardOperation)
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(105) {
		t.Fatalf("act award status %d body %+v", response.HTTPStatus, response.Body)
	}
	if progress := missionProgress(t, p, a.PlayerID, 10029); progress != 1 {
		t.Fatalf("mission 10029 progress %d", progress)
	}
	if count := adventureOccurrences(t, p, a, d.EventFavor); count != 1 {
		t.Fatalf("adventure 10002 occurrences %d", count)
	}
}

func TestI9_10B843TalkAwardChoiceAndEnd(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	// 203001 is a type-2 choice in the source dialogue rows: is_reward 1 for
	// table 10001013 and is_reward 0 for table 10001001.
	bornHero(t, p, a, rev, 10001013, 1)
	bornHero(t, p, a, rev, 10001001, 2)
	setLibraryFavor(t, p, a, 1, 100)
	service := libraryService(p, p)

	choiceOperation := op()
	response := libraryDispatchService(t, a, service, 843, map[string]any{"partner_id": int64(1), "dialog_id": int64(2), "select_info": "1|203001"}, choiceOperation)
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(102) {
		t.Fatalf("choice status %d body %+v", response.HTTPStatus, response.Body)
	}
	info := response.Body["dialog_info"].(map[string]any)
	if info["is_awarded"] != int64(1) || info["select_id"] != int64(203001) {
		t.Fatalf("choice dialog_info %+v", info)
	}
	if awards, ok := response.Body["awards"].([]any); !ok || len(awards) != 0 {
		t.Fatalf("choice awards %T %+v", response.Body["awards"], response.Body["awards"])
	}

	response = libraryDispatchService(t, a, service, 843, map[string]any{"partner_id": int64(1), "dialog_id": int64(2), "select_info": "1|203001"}, choiceOperation)
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(102) {
		t.Fatalf("choice replay status %d body %+v", response.HTTPStatus, response.Body)
	}

	setLibraryFavor(t, p, a, 2, 200)
	response = libraryDispatchService(t, a, service, 843, map[string]any{"partner_id": int64(2), "dialog_id": int64(2), "select_info": "0|203001"}, op())
	info = response.Body["dialog_info"].(map[string]any)
	if response.HTTPStatus != 200 || info["is_awarded"] != int64(0) || info["select_id"] != int64(203001) || response.Body["favor_degree"] != int64(200) {
		t.Fatalf("select status %d body %+v", response.HTTPStatus, response.Body)
	}

	endOperation := op()
	response = libraryDispatchService(t, a, service, 843, map[string]any{"partner_id": int64(2), "dialog_id": int64(2)}, endOperation)
	info = response.Body["dialog_info"].(map[string]any)
	if response.HTTPStatus != 200 || info["is_awarded"] != int64(0) || info["select_id"] != int64(203001) || response.Body["favor_degree"] != int64(200) {
		t.Fatalf("end status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 843, map[string]any{"partner_id": int64(2), "dialog_id": int64(2)}, endOperation)
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(200) {
		t.Fatalf("end replay status %d body %+v", response.HTTPStatus, response.Body)
	}

	response = libraryDispatchService(t, a, service, 843, map[string]any{"partner_id": int64(1), "dialog_id": int64(2), "select_info": "bad"}, op())
	if response.HTTPStatus != 400 {
		t.Fatalf("bad select_info status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 843, map[string]any{"partner_id": int64(1), "dialog_id": int64(9), "select_info": "1|1"}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(35028) {
		t.Fatalf("closed dialog status %d body %+v", response.HTTPStatus, response.Body)
	}
}

// Source: data/tables/10001006.lua dialog 2, 201004.turn_id = 202001|203001,
// 202001.is_reward = 3, 203001.is_reward = 2; library_dialog_config id 2
// amour_reward = 2. Each raw choice raises favor through the objective port, so
// mission 10029 advances exactly once even across receipt retry and a fresh op.
func TestI9_10B843RawChoiceAdvanceMission10029(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	const wantAmourReward = int64(2)
	for _, tc := range []struct {
		name       string
		selectInfo string
		option     int64
	}{
		{"raw3-202001", "3|202001", 202001},
		{"raw2-203001", "2|203001", 203001},
	} {
		t.Run(tc.name, func(t *testing.T) {
			a := bornActor(t, p)
			bornHero(t, p, a, rev, 10001006, 1)
			setLibraryFavor(t, p, a, 1, 100)
			service := libraryFactService(p)
			params := map[string]any{"partner_id": int64(1), "dialog_id": int64(2), "select_info": tc.selectInfo}
			request := op()

			before := d491StoredFavor(t, p, a, 1)
			response := libraryDispatchService(t, a, service, 843, params, request)
			t.Logf("first select_info=%q status=%d body=%+v before=%d", tc.selectInfo, response.HTTPStatus, response.Body, before)
			if response.HTTPStatus != 200 || response.Body["favor_degree"] != before+wantAmourReward {
				t.Fatalf("select_info %q status %d body %+v", tc.selectInfo, response.HTTPStatus, response.Body)
			}
			info, ok := response.Body["dialog_info"].(map[string]any)
			if !ok || info["is_awarded"] != int64(1) || info["select_id"] != tc.option {
				t.Fatalf("select_info %q dialog_info %T %+v", tc.selectInfo, response.Body["dialog_info"], response.Body["dialog_info"])
			}
			if progress := missionProgress(t, p, a.PlayerID, 10029); progress != 1 {
				t.Fatalf("select_info %q mission 10029 progress %d want 1", tc.selectInfo, progress)
			}

			response = libraryDispatchService(t, a, service, 843, params, request)
			t.Logf("exact retry select_info=%q status=%d body=%+v", tc.selectInfo, response.HTTPStatus, response.Body)
			if response.HTTPStatus != 200 || response.Body["favor_degree"] != before+wantAmourReward {
				t.Fatalf("select_info %q exact retry status %d body %+v", tc.selectInfo, response.HTTPStatus, response.Body)
			}
			if progress := missionProgress(t, p, a.PlayerID, 10029); progress != 1 {
				t.Fatalf("select_info %q retry mission 10029 progress %d want 1", tc.selectInfo, progress)
			}

			response = libraryDispatchService(t, a, service, 843, params, op())
			t.Logf("fresh operation select_info=%q status=%d body=%+v", tc.selectInfo, response.HTTPStatus, response.Body)
			if response.HTTPStatus != 200 || response.Body["favor_degree"] != before+wantAmourReward {
				t.Fatalf("select_info %q fresh operation status %d body %+v", tc.selectInfo, response.HTTPStatus, response.Body)
			}
			if progress := missionProgress(t, p, a.PlayerID, 10029); progress != 1 {
				t.Fatalf("select_info %q fresh operation mission 10029 progress %d want 1", tc.selectInfo, progress)
			}
		})
	}
}

func TestI9_10B851SchoolStoryClaimOnce(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	service := libraryGrantService(p)

	claimOperation := op()
	response := libraryDispatchService(t, a, service, 851, map[string]any{"talk_id": int64(1001)}, claimOperation)
	if response.HTTPStatus != 200 {
		t.Fatalf("851 status %d body %+v", response.HTTPStatus, response.Body)
	}
	awards, ok := response.Body["awards"].([]any)
	if !ok || len(awards) != 1 {
		t.Fatalf("awards %T %+v", response.Body["awards"], response.Body["awards"])
	}
	row := awards[0].(map[string]any)
	if row["table_id"] != int64(50001002) || row["item_num"] != int64(5) {
		t.Fatalf("story award row %+v", row)
	}
	var quantity int64
	if e := p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=50001002`, int64(a.PlayerID)).Scan(&quantity); e != nil || quantity != 5 {
		t.Fatalf("story stack %d %v", quantity, e)
	}

	response = libraryDispatchService(t, a, service, 851, map[string]any{"talk_id": int64(1001)}, claimOperation)
	if response.HTTPStatus != 200 {
		t.Fatalf("851 replay status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 851, map[string]any{"talk_id": int64(1001)}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(35028) {
		t.Fatalf("851 second claim status %d body %+v", response.HTTPStatus, response.Body)
	}
	if e := p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=50001002`, int64(a.PlayerID)).Scan(&quantity); e != nil || quantity != 5 {
		t.Fatalf("story stack after replay %d %v", quantity, e)
	}

	response = libraryDispatchService(t, a, service, 851, map[string]any{"talk_id": int64(2001)}, op())
	if response.HTTPStatus != 200 {
		t.Fatalf("851 diamond status %d body %+v", response.HTTPStatus, response.Body)
	}
	diamond := response.Body["awards"].([]any)[0].(map[string]any)
	if diamond["table_id"] != int64(-1) || diamond["crystal"] != int64(200) || diamond["item_num"] != int64(200) {
		t.Fatalf("diamond award row %+v", diamond)
	}
	var crystal int64
	if e := p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&crystal); e != nil || crystal != 1200 {
		t.Fatalf("crystal balance %d %v", crystal, e)
	}
}

func TestI9_10B845To847Refuse(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	service := libraryService(p, p)
	for _, mid := range []uint16{845, 846, 847} {
		response := libraryDispatchService(t, a, service, mid, map[string]any{"partner_id": int64(1), "mission_id": int64(1001)}, op())
		if response.HTTPStatus != 409 || response.Body["error_code"] != int64(35028) {
			t.Fatalf("MID %d status %d body %+v", mid, response.HTTPStatus, response.Body)
		}
	}
}
