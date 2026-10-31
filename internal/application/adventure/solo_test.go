package adventure

import (
	"context"
	"testing"
	"time"

	cb "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/adventure"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type noticeStore struct {
	rows []d.Occurrence
}

func (s *noticeStore) ListOccurrencesTx(context.Context, tx.Queryer, identity.LogicalServerID, identity.PlayerID, time.Time, int64) ([]d.Occurrence, error) {
	return s.rows, nil
}
func (s *noticeStore) ReadOccurrenceTx(context.Context, tx.Queryer, identity.PlayerID, int64) (d.Occurrence, bool, error) {
	return d.Occurrence{}, false, nil
}
func (s *noticeStore) FinishOccurrenceTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time, time.Time) (bool, error) {
	return false, nil
}
func (s *noticeStore) InsertAttemptTx(context.Context, tx.Tx, d.SingleAttempt) error { return nil }
func (s *noticeStore) FindLatestAttemptTx(context.Context, tx.Queryer, identity.PlayerID, int64) (d.SingleAttempt, bool, error) {
	return d.SingleAttempt{}, false, nil
}
func (s *noticeStore) SaveAttemptTx(context.Context, tx.Tx, d.SingleAttempt) error { return nil }
func (s *noticeStore) RenameAttemptTx(context.Context, tx.Tx, string, string, identity.PlayerID) error {
	return nil
}
func (s *noticeStore) DeleteAttemptTx(context.Context, tx.Tx, string, identity.PlayerID) error {
	return nil
}
func (s *noticeStore) InsertReportTx(context.Context, tx.Tx, string, int64, int64, []int64, string, time.Time) error {
	return nil
}
func (s *noticeStore) ReadReportTx(context.Context, tx.Queryer, string, int64, identity.PlayerID, time.Time) (string, bool, error) {
	return "", false, nil
}
func (s *noticeStore) PurgeExpiredReportsTx(context.Context, tx.Tx, time.Time, int64) (int64, error) {
	return 0, nil
}
func (s *noticeStore) PurgeOccurrencesTx(context.Context, tx.Tx, time.Time, int64) (int64, error) {
	return 0, nil
}

type fixedTime struct{ at time.Time }

func (f fixedTime) Now(context.Context) (time.Time, error) { return f.at, nil }

type queryerStub struct{}

func (queryerStub) QueryRow(context.Context, string, ...any) tx.Row { return nil }

func testOccurrence(eventType int64, at time.Time, finished bool) d.Occurrence {
	event, _ := d.Profile(eventType)
	occurrence, _ := d.NewOccurrence("fact/"+time.Unix(int64(eventType), 0).String(), identity.PlayerID(7001), event, at)
	if finished {
		occurrence.Finish(at.Add(time.Minute))
	}
	return occurrence
}

func TestNoticeReaderSeparatesOccurAndFinish(t *testing.T) {
	at := time.Unix(1700000000, 0).UTC()
	reader := NoticeReader{Store: &noticeStore{rows: []d.Occurrence{
		testOccurrence(d.EventDefense, at, false),
		testOccurrence(d.EventBattle, at, true),
	}}, Queryer: queryerStub{}, Time: fixedTime{at: at.Add(10 * time.Second)}}
	notices, err := reader.ReadNotices(context.Background(), identity.PlayerID(7001), operation.Context{})
	if err != nil {
		t.Fatal(err)
	}
	if len(notices) != 2 {
		t.Fatalf("notices %+v", notices)
	}
	occur, finish := notices[0], notices[1]
	if occur.Type != NoticeOccur || occur.TableID != d.EventDefense || occur.SpecialData != 0 {
		t.Fatalf("occur %+v", occur)
	}
	if finish.Type != NoticeFinish || finish.TableID != d.EventBattle {
		t.Fatalf("finish %+v", finish)
	}
}

func TestGiftAwardsAndFormationRules(t *testing.T) {
	catalog := d.Catalog{Gifts: []d.Gift{{ID: 90030021, Items: []int64{50001002, 50001003}, ItemNums: []int64{10, 4}}}}
	awards, lines := giftAwards(catalog, 90030021)
	if len(awards) != 2 || len(lines) != 2 || lines[0].Kind != grant.StackItem || lines[0].ItemID != 50001002 || lines[0].Amount != 10 {
		t.Fatalf("awards %+v lines %+v", awards, lines)
	}
	if awards, lines = giftAwards(catalog, 1); awards != nil || lines != nil {
		t.Fatal("unknown gift must pay nothing")
	}
	if validateFormation(nil) == nil || validateFormation([]int64{1, 1}) == nil || validateFormation([]int64{0}) == nil {
		t.Fatal("invalid formations must refuse")
	}
	if validateFormation([]int64{1, 2, 3, 4, 5, 6}) != nil || validateFormation([]int64{1, 2, 3, 4, 5, 6, 7}) == nil {
		t.Fatal("six heroes are the maximum")
	}
}

func TestRoomPushesRespectAllAndActor(t *testing.T) {
	state := d.RoomState{}
	state.AddPush(2, 7001, true, map[string]any{"room_id": int64(5)})
	state.AddPush(3, 7001, false, map[string]any{"player_id": int64(7001)})
	seated := []PlayerBody{{Player: 7001}, {Player: 7002}}
	pushes := roomPushes(state, seated)
	if len(pushes) != 2 || len(pushes[0].Bodies) != 2 || len(pushes[1].Bodies) != 1 || pushes[1].Bodies[0].Player != 7002 {
		t.Fatalf("pushes %+v", pushes)
	}
}

func TestPVPBattleUsesOpponentDefenseOrRobotTeam(t *testing.T) {
	actor := identity.ActorContext{PlayerID: identity.PlayerID(7001)}
	request := FightRequest{Formation: []int64{11, 12}, PetID: 21}
	player := pvpBattle(actor, request, Opponent{PlayerID: identity.PlayerID(7002), Heroes: []int64{31, 32}, PetID: 41})
	if len(player.TeamA) != 2 || player.TeamA[0].Origin != cd.OwnedSelf || len(player.WavesB) != 1 || player.WavesB[0][0].Origin != cd.OwnedForeign || player.WavesB[0][0].Player != identity.PlayerID(7002) || len(player.PetsB) != 1 {
		t.Fatalf("player battle %+v", player)
	}
	robot := pvpBattle(actor, request, Opponent{TemplateHeroes: []cb.Participant{{Origin: cd.Template, Kind: cd.HeroActor, Identity: 51}}})
	if len(robot.WavesB) != 1 || robot.WavesB[0][0].Origin != cd.Template || len(robot.PetsB) != 0 {
		t.Fatalf("robot battle %+v", robot)
	}
}
