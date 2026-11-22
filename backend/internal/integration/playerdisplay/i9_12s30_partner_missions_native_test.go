//go:build postgres

package playerdisplay_test

import (
	"context"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	applibrary "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

type missionWakeupListener struct {
	messages chan realtimewakeup.Envelope
	failure  chan error
}

func startMissionWakeupListener(t *testing.T, p *pg.Pool) *missionWakeupListener {
	t.Helper()
	connection, err := p.Raw().Acquire(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if _, err = connection.Exec(context.Background(), `LISTEN `+pg.RealtimeWakeupChannel); err != nil {
		connection.Release()
		t.Fatal(err)
	}
	listener := &missionWakeupListener{messages: make(chan realtimewakeup.Envelope, 8), failure: make(chan error, 1)}
	listenContext, cancel := context.WithCancel(context.Background())
	finished := make(chan struct{})
	t.Cleanup(func() {
		cancel()
		<-finished
		connection.Release()
	})
	go func() {
		defer close(finished)
		for {
			notification, err := connection.Conn().WaitForNotification(listenContext)
			if err != nil {
				select {
				case listener.failure <- err:
				default:
				}
				return
			}
			envelope, err := realtimewakeup.Decode([]byte(notification.Payload))
			if err != nil {
				listener.failure <- err
				return
			}
			select {
			case listener.messages <- envelope:
			case <-listenContext.Done():
				return
			}
		}
	}()
	return listener
}

func (l *missionWakeupListener) expect(t *testing.T, player identity.PlayerID, partnerID, missionID int64) {
	t.Helper()
	deadline := time.After(3 * time.Second)
	for {
		select {
		case envelope := <-l.messages:
			if envelope.Route != applibrary.MissionNoticeRoute || envelope.Ref != applibrary.MissionNoticeRef(player, partnerID, missionID) {
				continue
			}
			return
		case err := <-l.failure:
			t.Fatalf("wakeup listener: %v", err)
		case <-deadline:
			t.Fatalf("no partner mission wakeup for player %d partner %d mission %d", player, partnerID, missionID)
		}
	}
}

// A-204/A-205 S30: a new girl's 836 carries the unlocked stage's missions as
// PROCEED rows, and the gift that completes 1001 emits the notice-20 wakeup
// whose post-commit read carries AWARDED and the raised favor.
func TestI9_12S30PartnerMissionsDefaultAndNotice(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)

	service := libraryService(p, p)
	body, e := service.Read(ctx, a, op(), 836, 0)
	if e != nil {
		t.Fatal(e)
	}
	replyconformance.Check(t, 836, body)
	missions := partnerMissions(t, body, 1)
	assertMissionRow(t, missions, 0, 1001, 0, lib.MissionProceed)
	assertMissionRow(t, missions, 1, 1002, 0, lib.MissionProceed)
	assertMissionRow(t, missions, 2, 1003, 0, lib.MissionProceed)
	if len(missions) != 3 {
		t.Fatalf("fresh 836 missions %+v", missions)
	}

	listener := startMissionWakeupListener(t, p)
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,50005011,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, int64(a.PlayerID))
	giftOperation := triggeringIntimacyOperation(t, a.PlayerID)
	response := libraryDispatchService(t, a, libraryFactService(p), 840, map[string]any{"partner_id": int64(1), "gift_id": int64(50005011), "gift_num": int64(1)}, giftOperation)
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(18) {
		t.Fatalf("gift status %d body %+v", response.HTTPStatus, response.Body)
	}
	listener.expect(t, a.PlayerID, 1, 1001)

	notice, e := (applibrary.MissionNoticeReader{Queryer: p, Library: librarystore.Store{}}).ReadMissionNotice(ctx, a.PlayerID, 1, 1001)
	if e != nil {
		t.Fatal(e)
	}
	if notice.MissionState != lib.MissionAwarded || notice.Process != 1 || notice.Favor != 18 {
		t.Fatalf("notice %+v", notice)
	}

	body, e = service.Read(ctx, a, op(), 836, 0)
	if e != nil {
		t.Fatal(e)
	}
	missions = partnerMissions(t, body, 1)
	assertMissionRow(t, missions, 0, 1001, 1, lib.MissionAwarded)
}

func partnerMissions(t *testing.T, body map[string]any, partner int64) []any {
	t.Helper()
	infos, ok := body["library_infos"].(map[string]any)
	if !ok {
		t.Fatalf("library_infos %T", body["library_infos"])
	}
	row, ok := infos[strconv.FormatInt(partner, 10)].(map[string]any)
	if !ok {
		t.Fatalf("partner %d row %T", partner, infos[strconv.FormatInt(partner, 10)])
	}
	missions, ok := row["partner_missions"].([]any)
	if !ok {
		t.Fatalf("partner %d missions %T", partner, row["partner_missions"])
	}
	return missions
}

func assertMissionRow(t *testing.T, missions []any, index int, missionID, process, state int64) {
	t.Helper()
	if index >= len(missions) {
		t.Fatalf("mission index %d beyond %+v", index, missions)
	}
	row := missions[index].(map[string]any)
	if row["mission_id"] != missionID || row["process"] != process || row["mission_state"] != state {
		t.Fatalf("mission %d row %+v want {%d %d %d}", index, row, missionID, process, state)
	}
}
